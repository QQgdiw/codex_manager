import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

import {
  collectGitHubRepositories,
  collectToFile,
  runCli,
  validateMarketDocuments,
} from '../../scripts/markets/github-market.mjs';

function githubRecord(record) {
  return `<!-- github-record:${JSON.stringify(record)} -->`;
}

function derivedRecord(record) {
  return `<!-- derived-record:${JSON.stringify(record)} -->`;
}

function validGitHubRecord(overrides = {}) {
  return {
    week: '2026-W01',
    repository: 'OpenAI/Example',
    stars: 1000,
    capturedAt: '2026-01-05T00:00:00.000Z',
    sourceLevel: 'A',
    ...overrides,
  };
}

function response(status, body, headers = {}) {
  return {
    ok: status >= 200 && status < 300,
    status,
    headers: new Headers(headers),
    json: async () => body,
  };
}

test('rejects low stars, invalid ISO week, invalid source level, and cross-week case-insensitive duplicates with locations', () => {
  const github = [
    githubRecord(validGitHubRecord({ repository: 'owner/low-stars', stars: 999 })),
    githubRecord(validGitHubRecord({ repository: 'owner/bad-week', week: '2026-W54' })),
    githubRecord(validGitHubRecord({ repository: 'owner/bad-level', sourceLevel: 'D' })),
    githubRecord(validGitHubRecord({ repository: 'owner/bad-date', capturedAt: '2026-02-30T00:00:00.000Z' })),
    githubRecord(validGitHubRecord({ repository: 'Owner/Duplicate', week: '2026-W01' })),
    githubRecord(validGitHubRecord({ repository: 'owner/duplicate', week: '2026-W02' })),
  ].join('\n');

  const result = validateMarketDocuments({
    github: { path: 'github.md', content: github },
  });

  assert.equal(result.summary.records, 6);
  assert.equal(result.summary.weeks, 3);
  assert.equal(result.summary.duplicates, 1);
  assert.equal(result.errors.length, 5);
  assert.match(result.errors.join('\n'), /github\.md:1: stars must be at least 1000/);
  assert.match(result.errors.join('\n'), /github\.md:2: invalid ISO week/);
  assert.match(result.errors.join('\n'), /github\.md:3: sourceLevel must be A, B, or C/);
  assert.match(result.errors.join('\n'), /github\.md:4: capturedAt must be an ISO-8601 timestamp/);
  assert.match(result.errors.join('\n'), /github\.md:6: repository duplicates a different week/);
});

test('rejects derived records missing GitHub origins and records duplicated between MCP and tool documents', () => {
  const github = githubRecord(validGitHubRecord());
  const derived = derivedRecord({ repository: 'openai/missing', week: '2026-W01', kind: 'mcp' });
  const mcpConflict = derivedRecord({ repository: 'OPENAI/EXAMPLE', week: '2026-W01', kind: 'mcp' });
  const toolConflict = derivedRecord({ repository: 'openai/example', week: '2026-W01', kind: 'tool' });
  const result = validateMarketDocuments({
    github: { path: 'github.md', content: github },
    mcp: { path: 'mcp.md', content: `${derived}\n${mcpConflict}` },
    tool: { path: 'tool.md', content: toolConflict },
  });

  assert.equal(result.summary.derivedMissing, 1);
  assert.match(result.errors.join('\n'), /mcp\.md:1: derived record has no GitHub origin/);
  assert.match(result.errors.join('\n'), /tool\.md:1: derived record also appears in mcp\.md:2/);
});

test('rejects a GitHub repository heading without its record marker', () => {
  const result = validateMarketDocuments({
    github: {
      path: 'github.md',
      content: [
        '### owner/missing',
        'Repository details.',
        '### 2026-W01',
      ].join('\n'),
    },
  });

  assert.equal(result.summary.unmarkedEntries, 1);
  assert.match(result.errors.join('\n'), /github\.md:1: repository heading owner\/missing requires exactly one github-record marker \(found 0\)/);
});

test('rejects duplicate GitHub record markers under one repository heading', () => {
  const record = githubRecord(validGitHubRecord({ repository: 'owner/duplicate' }));
  const result = validateMarketDocuments({
    github: {
      path: 'github.md',
      content: [
        '### owner/duplicate',
        record,
        record,
        '### 2026-W01',
      ].join('\n'),
    },
  });

  assert.equal(result.summary.unmarkedEntries, 1);
  assert.match(result.errors.join('\n'), /github\.md:1: repository heading owner\/duplicate requires exactly one github-record marker \(found 2\)/);
});

test('collects every GitHub search page and stores only public repository fields', async () => {
  const requests = [];
  const fetchImpl = async (url, options) => {
    requests.push({ url, options });
    const page = new URL(url).searchParams.get('page');
    if (page === '1') {
      return response(200, {
        total_count: 2,
        items: [{
          full_name: 'owner/first', html_url: 'https://github.com/owner/first', stargazers_count: 1200,
          description: 'first', created_at: '2026-01-01T00:00:00Z', updated_at: '2026-01-02T00:00:00Z',
          language: 'JavaScript', topics: ['cli'], license: { spdx_id: 'MIT' }, private: false,
        }],
      }, { link: '<https://api.github.com/search/repositories?page=2>; rel="next"' });
    }
    return response(200, {
      total_count: 3,
      items: [{
        full_name: 'owner/second', html_url: 'https://github.com/owner/second', stargazers_count: 1100,
        description: null, created_at: '2026-01-03T00:00:00Z', updated_at: '2026-01-04T00:00:00Z',
        language: null, topics: [], license: null, node_id: 'private-internal-id',
      }, {
        full_name: 'owner/low-stars', html_url: 'https://github.com/owner/low-stars', stargazers_count: 999,
        description: 'excluded', created_at: '2026-01-04T00:00:00Z', updated_at: '2026-01-04T00:00:00Z',
        language: 'JavaScript', topics: [], license: null,
      }],
    });
  };

  const collected = await collectGitHubRepositories({
    from: '2026-01-01',
    to: '2026-01-07',
    fetchImpl,
  });

  assert.equal(requests.length, 2);
  assert.match(new URL(requests[0].url).searchParams.get('q'), /stars:>=1000/);
  assert.match(new URL(requests[1].url).searchParams.get('q'), /stars:>=1000/);
  assert.equal(requests[0].options.headers.Accept, 'application/vnd.github+json');
  assert.match(requests[0].options.headers['User-Agent'], /codex/i);
  assert.deepEqual(collected, [
    {
      full_name: 'owner/first', html_url: 'https://github.com/owner/first', stargazers_count: 1200,
      description: 'first', created_at: '2026-01-01T00:00:00Z', updated_at: '2026-01-02T00:00:00Z',
      language: 'JavaScript', topics: ['cli'], license: { spdx_id: 'MIT' },
    },
    {
      full_name: 'owner/second', html_url: 'https://github.com/owner/second', stargazers_count: 1100,
      description: null, created_at: '2026-01-03T00:00:00Z', updated_at: '2026-01-04T00:00:00Z',
      language: null, topics: [], license: { spdx_id: null },
    },
  ]);
});

test('does not overwrite output when the GitHub API rate-limits a collection', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'github-market-'));
  try {
    const output = join(directory, 'github.json');
    await writeFile(output, 'sentinel', 'utf8');

    let requestCount = 0;
    await assert.rejects(
      () => collectToFile({
        from: '2026-01-01',
        to: '2026-01-07',
        output,
        fetchImpl: async () => {
          requestCount += 1;
          if (requestCount === 1) {
            return response(200, { items: [{ full_name: 'owner/first' }] }, {
              link: '<https://api.github.com/search/repositories?page=2>; rel="next"',
            });
          }
          return response(403, { message: 'API rate limit exceeded' }, {
            'x-ratelimit-remaining': '0',
          });
        },
      }),
      /github_api_rate_limited/,
    );
    assert.equal(requestCount, 2);
    assert.equal(await readFile(output, 'utf8'), 'sentinel');
  }
  finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test('returns exit code 4 after printing validation statistics for hard errors', async () => {
  let stdout = '';
  await assert.rejects(
    () => runCli(['validate', '--github', 'github.md'], {
      readFileImpl: async () => githubRecord(validGitHubRecord({ stars: 999 })),
      stdout: { write(value) { stdout += value; } },
    }),
    (error) => error.exitCode === 4 && /stars must be at least 1000/.test(error.message),
  );
  assert.match(stdout, /records: 1/);
  assert.match(stdout, /weeksUnder20: 2026-W01\(1\)/);
});
