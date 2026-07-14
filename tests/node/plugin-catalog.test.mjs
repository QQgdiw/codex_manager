import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { spawn } from 'node:child_process';
import { EventEmitter } from 'node:events';
import { PassThrough } from 'node:stream';
import test from 'node:test';

import {
  collectPluginCatalog,
  pluginRecordKey,
  renderPluginsMarket,
  validatePluginListResult,
} from '../../scripts/markets/plugin-catalog.mjs';

const metadata = {
  collectedAt: '2026-07-14T00:00:00.000Z',
  codexVersion: 'test',
};

const fixtureResult = {
  marketplaces: [
    {
      name: 'openai-curated-remote',
      plugins: [
        {
          id: 'metabase',
          remotePluginId: 'metabase-v1',
          version: '1.0.0',
          interface: 'mcp',
          availability: 'available',
          installPolicy: 'allowed',
          authPolicy: 'required',
          keywords: ['analytics', 'sql'],
          displayName: 'Metabase',
          developer: 'Metabase',
          category: 'data',
          description: 'Business intelligence',
          capabilities: ['query'],
          website: 'https://www.metabase.com/',
        },
        {
          id: 'metabase',
          remotePluginId: 'metabase-v2',
          version: '2.0.0',
          interface: 'mcp',
          availability: 'unavailable',
          installPolicy: 'approval_required',
          authPolicy: 'none',
          keywords: ['analytics'],
          displayName: 'Metabase Preview',
          developer: 'Metabase',
          category: 'data',
          description: 'Preview integration',
          capabilities: ['query'],
          website: 'https://www.metabase.com/',
        },
      ],
    },
    {
      name: 'local-marketplace',
      plugins: [
        {
          id: 'local-tool',
          remotePluginId: null,
          version: '0.1.0',
          interface: 'skill',
          availability: 'installed',
          installPolicy: 'allowed',
          authPolicy: 'none',
          keywords: ['local'],
          displayName: 'Local Tool',
          developer: 'Example',
          category: 'development',
          description: 'Local development helper',
          capabilities: ['format'],
          website: 'https://example.test/local-tool',
        },
      ],
    },
  ],
  marketplaceLoadErrors: [],
};

function cloneFixture(overrides = {}) {
  return {
    ...structuredClone(fixtureResult),
    ...overrides,
  };
}

async function run(command, args, options = {}) {
  return new Promise((resolve) => {
    const child = spawn(command, args, { windowsHide: true, ...options });
    let stdout = '';
    let stderr = '';
    child.stdout.on('data', (chunk) => { stdout += chunk; });
    child.stderr.on('data', (chunk) => { stderr += chunk; });
    child.on('close', (code) => resolve({ code, stdout, stderr }));
  });
}

async function writeFakeCodex(directory, result) {
  const serverPath = join(directory, 'app-server');
  const server = [
    "let input = '';",
    "process.stdin.setEncoding('utf8');",
    "process.stdin.on('data', (chunk) => {",
    "  input += chunk;",
    "  const lines = input.split('\\n');",
    "  input = lines.pop();",
    "  for (const line of lines) {",
    "    if (!line.trim()) continue;",
    "    const message = JSON.parse(line);",
    "    if (message.method === 'initialize') console.log(JSON.stringify({ jsonrpc: '2.0', id: 1, result: { serverInfo: { name: 'fake' } } }));",
    "    if (message.method === 'plugin/list') console.log(JSON.stringify({ jsonrpc: '2.0', id: 2, result: " + JSON.stringify(result) + " }));",
    "  }",
    "});",
  ].join('\n');

  await writeFile(serverPath, server, 'utf8');
  return process.execPath;
}

function createFakeChild() {
  return Object.assign(new EventEmitter(), {
    stdin: { write() {}, end() {} },
    stdout: new PassThrough(),
    stderr: new PassThrough(),
    killed: false,
    kill() { this.killed = true; },
  });
}

function collectFromResponses(initializeResponse, pluginListResponse) {
  const child = createFakeChild();
  return collectPluginCatalog({
    codexCommand: 'codex',
    cwd: 'E:/fixture',
    timeoutMs: 100,
    spawnImpl() {
      queueMicrotask(() => {
        child.stdout.write(`${JSON.stringify(initializeResponse)}\n`);
        child.stdout.write(`${JSON.stringify(pluginListResponse)}\n`);
      });
      return child;
    },
  });
}

test('preserves upstream duplicate ids as distinct records', () => {
  const catalog = validatePluginListResult(fixtureResult);
  assert.equal(catalog.records.length, 3);
  assert.equal(new Set(catalog.records.map((record) => record.recordKey)).size, 3);
  assert.match(renderPluginsMarket(catalog, metadata), /原始记录数：3/);
  assert.equal((renderPluginsMarket(catalog, metadata).match(/<!-- plugin-record:/g) ?? []).length, 3);
});

test('uses the complete upstream identity for each record key', () => {
  const [first, second] = fixtureResult.marketplaces[0].plugins;
  assert.notEqual(
    pluginRecordKey('openai-curated-remote', first),
    pluginRecordKey('openai-curated-remote', second),
  );
});

test('rejects invalid plugin list results', () => {
  assert.throws(() => validatePluginListResult(null), /plugin list result/i);
  assert.throws(() => validatePluginListResult({ marketplaceLoadErrors: [] }), /marketplaces/i);
  assert.throws(
    () => validatePluginListResult(cloneFixture({ marketplaceLoadErrors: [{ marketplace: 'broken' }] })),
    /marketplace load error/i,
  );
  assert.throws(
    () => validatePluginListResult({ marketplaces: [{ name: 'broken', plugins: {} }], marketplaceLoadErrors: [] }),
    /plugins/i,
  );
  assert.throws(
    () => validatePluginListResult({ marketplaces: [{ plugins: [] }], marketplaceLoadErrors: [] }),
    /marketplace name/i,
  );
  const duplicate = cloneFixture();
  duplicate.marketplaces[1].plugins[0] = structuredClone(duplicate.marketplaces[0].plugins[0]);
  duplicate.marketplaces[1].name = 'openai-curated-remote';
  assert.throws(() => validatePluginListResult(duplicate), /duplicate plugin record key/i);
});

test('renders escaped Markdown table cells', () => {
  const escaped = cloneFixture();
  escaped.marketplaces[1].plugins[0].description = 'first | second\n<third>';
  const document = renderPluginsMarket(validatePluginListResult(escaped), metadata);
  assert.match(document, /first \\| second<br>&lt;third&gt;/);
});

test('collects the response matching the plugin list request id', async () => {
  const writes = [];
  const fakeChild = Object.assign(new EventEmitter(), {
    stdin: {
      write(chunk) {
        writes.push(JSON.parse(chunk));
      },
      end() {},
    },
    stdout: new PassThrough(),
    stderr: new PassThrough(),
    killed: false,
    kill() {
      this.killed = true;
    },
  });
  const catalogPromise = collectPluginCatalog({
    codexCommand: 'codex',
    cwd: 'E:/fixture',
    timeoutMs: 200,
    spawnImpl() {
      queueMicrotask(() => {
        fakeChild.stdout.write(`${JSON.stringify({ jsonrpc: '2.0', id: 99, result: { ignored: true } })}\n`);
        fakeChild.stdout.write(`${JSON.stringify({ jsonrpc: '2.0', id: 1, result: { serverInfo: { name: 'fake' } } })}\n`);
        fakeChild.stdout.write(`${JSON.stringify({ jsonrpc: '2.0', id: 2, result: fixtureResult })}\n`);
      });
      return fakeChild;
    },
  });
  const catalog = await catalogPromise;
  assert.equal(catalog.records.length, 3);
  assert.deepEqual(writes.map((message) => message.method), ['initialize', 'initialized', 'plugin/list']);
  assert.deepEqual(writes[2].params, { cwds: ['E:/fixture'] });
});

test('rejects invalid JSON and timeout from the app server', async () => {
  const createChild = () => Object.assign(new EventEmitter(), {
    stdin: { write() {}, end() {} },
    stdout: new PassThrough(),
    stderr: new PassThrough(),
    killed: false,
    kill() { this.killed = true; },
  });
  await assert.rejects(
    () => collectPluginCatalog({
      codexCommand: 'codex',
      cwd: 'E:/fixture',
      timeoutMs: 100,
      spawnImpl() {
        const child = createChild();
        queueMicrotask(() => child.stdout.write('{not json}\n'));
        return child;
      },
    }),
    /invalid json/i,
  );
  await assert.rejects(
    () => collectPluginCatalog({
      codexCommand: 'codex',
      cwd: 'E:/fixture',
      timeoutMs: 10,
      spawnImpl: createChild,
    }),
    /plugin_catalog_timeout/i,
  );
});

test('rejects matching responses that violate the JSON-RPC response contract', async () => {
  const initializeResponse = { jsonrpc: '2.0', id: 1, result: { serverInfo: { name: 'fake' } } };
  const emptyCatalog = { marketplaces: [], marketplaceLoadErrors: [] };
  await assert.rejects(
    () => collectFromResponses({ id: 1, result: { serverInfo: { name: 'fake' } } }, { jsonrpc: '2.0', id: 2, result: emptyCatalog }),
    /invalid JSON-RPC response/i,
  );
  await assert.rejects(
    () => collectFromResponses(initializeResponse, { id: 2, result: emptyCatalog }),
    /invalid JSON-RPC response/i,
  );
  await assert.rejects(
    () => collectFromResponses(initializeResponse, { jsonrpc: '2.0', id: 2 }),
    /invalid JSON-RPC response/i,
  );
  await assert.rejects(
    () => collectFromResponses(initializeResponse, {
      jsonrpc: '2.0', id: 2, result: emptyCatalog, error: { code: -32000, message: 'failed' },
    }),
    /invalid JSON-RPC response/i,
  );
  await assert.rejects(
    () => collectFromResponses(initializeResponse, { jsonrpc: '2.0', id: 2, error: { code: -32000, message: 'failed' } }),
    /plugin\/list failed/i,
  );
  await assert.rejects(
    () => collectFromResponses(initializeResponse, { jsonrpc: '2.0', id: 2, result: [] }),
    /plugin\/list result is invalid/i,
  );
});

test('CLI leaves a previous document untouched after collection failure', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'plugin-catalog-'));
  try {
    const outputPath = join(directory, 'plugins_market.md');
    const commandPath = await writeFakeCodex(directory, cloneFixture({ marketplaceLoadErrors: [{ marketplace: 'broken' }] }));
    await writeFile(outputPath, 'sentinel', 'utf8');
    const cliPath = join(process.cwd(), 'scripts', 'markets', 'export-plugins-market.mjs');
    const result = await run(process.execPath, [cliPath, '--cwd', directory, '--output', outputPath, '--codex-command', commandPath]);
    assert.equal(result.code, 3, result.stderr);
    assert.equal(await readFile(outputPath, 'utf8'), 'sentinel');
  }
  finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test('CLI check mode rejects an inconsistent document without modifying it', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'plugin-catalog-'));
  try {
    const checkPath = join(directory, 'plugins_market.md');
    const outputPath = join(directory, 'must-not-be-written.md');
    const commandPath = await writeFakeCodex(directory, fixtureResult);
    const firstKey = pluginRecordKey('openai-curated-remote', fixtureResult.marketplaces[0].plugins[0]);
    const sentinel = `<!-- plugin-record:${firstKey} -->\n`;
    await writeFile(checkPath, sentinel, 'utf8');
    const cliPath = join(process.cwd(), 'scripts', 'markets', 'export-plugins-market.mjs');
    const result = await run(process.execPath, [
      cliPath,
      '--cwd', directory,
      '--output', outputPath,
      '--check', checkPath,
      '--codex-command', commandPath,
    ]);
    assert.equal(result.code, 4, result.stderr);
    assert.equal(await readFile(checkPath, 'utf8'), sentinel);
  }
  finally {
    await rm(directory, { recursive: true, force: true });
  }
});
