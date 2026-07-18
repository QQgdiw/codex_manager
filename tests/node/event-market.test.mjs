import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

import {
  renderEventMarket,
  runCli,
  validateCurationRecords,
  validateEventDocument,
} from '../../scripts/markets/event-market.mjs';

function validRecord(overrides = {}) {
  return {
    id: 'openai-codex-workflow-2026',
    date: '2026-01-01',
    organization: 'OpenAI',
    partners: [],
    title: 'Codex workflow update',
    occurred: true,
    topics: ['coding-agent'],
    priority: 'high',
    officialSources: [{
      label: 'Official announcement',
      url: 'https://example.com/official',
      type: 'official-announcement',
      verifiedAt: '2026-07-18',
    }],
    facts: ['A source-supported fact.'],
    analysis: 'Technical analysis.',
    workflowImpact: 'Workflow impact.',
    limitations: 'Known limitations.',
    followUp: 'Follow-up action.',
    mergeKey: 'openai-codex-workflow',
    decision: 'keep',
    decisionReason: 'Independent engineering impact with official sources.',
    ...overrides,
  };
}

const coverage = { start: '2026-01-01', end: '2026-07-18' };

test('rejects duplicate kept merge keys and out-of-range dates', () => {
  const result = validateCurationRecords([
    validRecord({ id: 'event-a', date: '2026-01-10', mergeKey: 'same' }),
    validRecord({ id: 'event-b', date: '2025-12-31', mergeKey: 'same' }),
  ], coverage);

  assert.match(result.errors.join('\n'), /duplicate kept mergeKey: same/);
  assert.match(result.errors.join('\n'), /event-b: date outside coverage/);
});

test('rejects duplicate ids, invalid calendar dates, and malformed records', () => {
  const result = validateCurationRecords([
    validRecord({ id: 'duplicate' }),
    validRecord({ id: 'duplicate', mergeKey: 'second' }),
    validRecord({ id: 'invalid-date', date: '2026-02-29', mergeKey: 'third' }),
    validRecord({ id: 'missing-title', title: '', mergeKey: 'fourth' }),
  ], coverage);

  assert.match(result.errors.join('\n'), /duplicate id: duplicate/);
  assert.match(result.errors.join('\n'), /invalid-date: invalid date/);
  assert.match(result.errors.join('\n'), /missing-title: title is required/);
});

test('requires valid keep fields, enumerations, and official HTTPS sources', () => {
  const result = validateCurationRecords([
    validRecord({ id: 'empty-source', officialSources: [], mergeKey: 'empty-source' }),
    validRecord({ id: 'http-source', officialSources: [{ ...validRecord().officialSources[0], url: 'http://example.com' }], mergeKey: 'http-source' }),
    validRecord({ id: 'bad-topic', topics: ['unknown'], mergeKey: 'bad-topic' }),
    validRecord({ id: 'bad-source-type', officialSources: [{ ...validRecord().officialSources[0], type: 'blog' }], mergeKey: 'bad-source-type' }),
    validRecord({ id: 'future', occurred: false, mergeKey: 'future' }),
  ], coverage);

  assert.match(result.errors.join('\n'), /empty-source: officialSources must not be empty/);
  assert.match(result.errors.join('\n'), /http-source: officialSources\[0\]\.url must be HTTPS/);
  assert.match(result.errors.join('\n'), /bad-topic: unknown topic: unknown/);
  assert.match(result.errors.join('\n'), /bad-source-type: officialSources\[0\]\.type is invalid/);
  assert.match(result.errors.join('\n'), /future: keep records must have occurred: true/);
});

test('allows lightweight exclusions only when they explain the decision', () => {
  const result = validateCurationRecords([
    { id: 'excluded', date: '2026-01-02', organization: 'OpenAI', decision: 'exclude', decisionReason: 'Superseded by a larger release.' },
    { id: 'unexplained', date: '2026-01-03', organization: 'OpenAI', decision: 'exclude', decisionReason: '' },
  ], coverage);

  assert.equal(result.excluded.length, 1);
  assert.match(result.errors.join('\n'), /unexplained: decisionReason is required/);
});

test('renders topic indexes, grouped records, and deterministic organization ordering', () => {
  const markdown = renderEventMarket([
    validRecord({ id: 'z-low', organization: 'Zeta', date: '2026-01-02', priority: 'low', mergeKey: 'z-low', topics: ['embedded-edge'] }),
    validRecord({ id: 'a-medium', organization: 'Alpha', date: '2026-01-03', priority: 'medium', mergeKey: 'a-medium', topics: ['coding-agent', 'engineering-docs'] }),
    validRecord({ id: 'a-high-old', organization: 'Alpha', date: '2026-01-01', priority: 'high', mergeKey: 'a-high-old', topics: ['coding-agent'] }),
    validRecord({ id: 'b-high', organization: 'Beta', date: '2026-01-04', priority: 'high', mergeKey: 'b-high', topics: ['robotics-ros'] }),
  ], { ...coverage, verifiedAt: '2026-07-18' });

  assert.match(markdown, /## 主题索引/);
  assert.match(markdown, /\[Coding Agent\]\(#topic-coding-agent\)/);
  assert.match(markdown, /<!-- event-record:{"id":"a-medium","date":"2026-01-03","organization":"Alpha"} -->/);
  assert.ok(markdown.indexOf('## Beta') < markdown.indexOf('## Alpha'));
  assert.ok(markdown.indexOf('## Alpha') < markdown.indexOf('## Zeta'));
  assert.ok(markdown.indexOf('### Codex workflow update') < markdown.indexOf('### Codex workflow update', markdown.indexOf('### Codex workflow update') + 1));
  assert.match(markdown, /#### 客观事实[\s\S]*#### 技术剖析[\s\S]*#### 工作流影响[\s\S]*#### 局限与风险[\s\S]*#### 后续关注/);
  assert.match(markdown, /https:\/\/example\.com\/official/);
});

test('validates document markers, ordering, and rejects unmarked human event headings', () => {
  const valid = renderEventMarket([
    validRecord({ id: 'newer', date: '2026-01-02', mergeKey: 'newer' }),
    validRecord({ id: 'older', date: '2026-01-01', mergeKey: 'older' }),
  ], { ...coverage, verifiedAt: '2026-07-18' });
  assert.deepEqual(validateEventDocument(valid, coverage).errors, []);

  const unordered = valid.replace('"date":"2026-01-02"', '"date":"2026-01-00"');
  assert.match(validateEventDocument(unordered, coverage).errors.join('\n'), /invalid date/);
  assert.match(validateEventDocument(`${valid}\n### Human event\n`, coverage).errors.join('\n'), /unmarked event heading/);
});

test('does not replace an existing output when render validation fails', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'event-market-'));
  const input = join(directory, 'curation.jsonl');
  const output = join(directory, 'event_market.md');
  try {
    await writeFile(input, `${JSON.stringify(validRecord({ officialSources: [] }))}\n`, 'utf8');
    await writeFile(output, 'previous document\n', 'utf8');
    await assert.rejects(() => runCli(['render', '--input', input, '--output', output, '--start', coverage.start, '--end', coverage.end, '--verified-at', '2026-07-18']));
    assert.equal(await readFile(output, 'utf8'), 'previous document\n');
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});
