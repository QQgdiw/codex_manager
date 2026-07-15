import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

import {
  extractLegacyCandidates,
  renderGitHubMarketArchive,
  runCli,
  validateCurationRecords,
} from '../../scripts/markets/github-market-archive.mjs';
import { validateMarketDocuments } from '../../scripts/markets/github-market.mjs';

function keptRecord(overrides = {}) {
  return {
    decision: 'keep',
    week: '2026-W01',
    repository: 'owner/example',
    stars: 1234,
    sourceLevel: 'A',
    link: 'https://github.com/owner/example',
    projectType: '研发工具',
    weekBasis: '本周首次纳入候选清单。',
    coreFunction: '提供可复用的研发自动化能力。',
    workflow: '开发人员在本地或持续集成环境中执行。',
    input: '源代码与配置。',
    output: '可审阅的构建产物。',
    deployment: '可在开发环境部署。',
    risk: '需要审查第三方依赖与权限。',
    reason: '满足研发项目收录标准。',
    ...overrides,
  };
}

test('extracts GitHub candidates from weekly legacy tables and preserves escaped table cells', () => {
  const candidates = extractLegacyCandidates([
    '### 2026-W01',
    '| 项目 | Stars | 备注 |',
    '| --- | ---: | --- |',
    '| [owner/first](https://github.com/owner/first) | 1,234 | 支持 a \\| b |',
    '### 2026-W02',
    '| 项目 | Stars |',
    '| --- | ---: |',
    '| [owner/second](https://github.com/owner/second/) | 2000 |',
  ].join('\n'));

  assert.deepEqual(candidates, [
    { week: '2026-W01', repository: 'owner/first', stars: 1234 },
    { week: '2026-W02', repository: 'owner/second', stars: 2000 },
  ]);
});

test('uses the Stars column instead of a legacy table row number', () => {
  const candidates = extractLegacyCandidates([
    '### 2026-W01',
    '| # | Repository | Stars | Date field |',
    '| ---: | --- | ---: | --- |',
    '| 1 | [owner/first](https://github.com/owner/first) | 1,234 | created_at |',
  ].join('\n'));

  assert.deepEqual(candidates, [{ week: '2026-W01', repository: 'owner/first', stars: 1234 }]);
});

test('reports line numbers for invalid legacy GitHub table rows', () => {
  assert.throws(
    () => extractLegacyCandidates([
      '### 2026-W01',
      '| 项目 | Stars |',
      '| --- | ---: |',
      '| [owner/invalid](https://github.com/owner/invalid) | unknown |',
    ].join('\n')),
    /line 4: .*stars/i,
  );
});

test('validates low stars, invalid ISO weeks, and cross-week case-insensitive kept duplicates', () => {
  const result = validateCurationRecords([
    keptRecord({ stars: 999 }),
    keptRecord({ repository: 'owner/bad-week', week: '2026-W54' }),
    keptRecord({ repository: 'Owner/Duplicate', week: '2026-W01' }),
    keptRecord({ repository: 'owner/duplicate', week: '2026-W02' }),
  ]);

  assert.equal(result.kept.length, 1);
  assert.match(result.errors.join('\n'), /stars must be an integer of at least 1000/i);
  assert.match(result.errors.join('\n'), /invalid ISO week/i);
  assert.match(result.errors.join('\n'), /duplicates a kept record in 2026-W01/i);
});

test('requires risk for keeps and an exclusion reason for exclusions', () => {
  const result = validateCurationRecords([
    keptRecord({ risk: '' }),
    { decision: 'exclude', week: '2026-W01', repository: 'owner/excluded' },
  ]);

  assert.equal(result.kept.length, 0);
  assert.equal(result.excluded.length, 0);
  assert.match(result.errors.join('\n'), /risk is required/i);
  assert.match(result.errors.join('\n'), /exclusionReason is required/i);
});

test('renders W29 as a partial week with complete Chinese fields and a valid github record marker', () => {
  const document = renderGitHubMarketArchive({
    records: [
      keptRecord({ week: '2026-W29', repository: 'owner/w29' }),
      { decision: 'exclude', week: '2026-W29', repository: 'owner/duplicate', exclusionReason: '跨周重复，主条目在 2026-W01。' },
    ],
    capturedAt: '2026-07-15T10:30:00.000Z',
    partialWeeks: ['2026-W29'],
  });

  assert.match(document, /### 2026-W29/);
  assert.match(document, /截至采集日的部分周/);
  assert.match(document, /- 风险：需要审查第三方依赖与权限。/);
  assert.match(document, /### owner\/w29\n<!-- github-record:/);

  const validation = validateMarketDocuments({ github: { path: 'github.md', content: document } });
  assert.deepEqual(validation.errors, []);
});

test('renders a partial week even when it has no candidates', () => {
  const document = renderGitHubMarketArchive({
    records: [],
    capturedAt: '2026-07-15T10:30:00.000Z',
    partialWeeks: ['2026-W29'],
  });

  assert.match(document, /### 2026-W29/);
  assert.match(document, /- 原始候选：0/);
  assert.match(document, /截至采集日的部分周数据/);
});

test('does not overwrite an existing render target when atomic rename fails', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'github-market-archive-'));
  try {
    const input = join(directory, 'records.ndjson');
    const output = join(directory, 'github.md');
    await writeFile(input, `${JSON.stringify(keptRecord())}\n`, 'utf8');
    await writeFile(output, 'sentinel', 'utf8');

    await assert.rejects(
      () => runCli([
        'render', '--input', input, '--output', output,
        '--captured-at', '2026-07-15T10:30:00.000Z',
      ], {
        renameImpl: async () => { throw new Error('rename failed'); },
      }),
      /rename failed/,
    );
    assert.equal(await readFile(output, 'utf8'), 'sentinel');
  }
  finally {
    await rm(directory, { recursive: true, force: true });
  }
});
