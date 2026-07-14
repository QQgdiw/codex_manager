import { randomUUID } from 'node:crypto';
import { readFile, rename, rm, writeFile } from 'node:fs/promises';
import { dirname, isAbsolute, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { collectPluginCatalog, renderPluginsMarket } from './plugin-catalog.mjs';

function usageError(message) {
  const error = new Error(message);
  error.exitCode = 2;
  return error;
}

function parseArguments(argv) {
  const options = {};
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (!['--cwd', '--output', '--check', '--codex-command'].includes(argument)) {
      throw usageError(`unknown argument: ${argument}`);
    }
    const value = argv[index + 1];
    if (value == null || value.startsWith('--')) {
      throw usageError(`missing value for ${argument}`);
    }
    index += 1;
    options[argument.slice(2).replace(/-([a-z])/g, (_, letter) => letter.toUpperCase())] = value;
  }
  if (!options.cwd || !isAbsolute(options.cwd)) {
    throw usageError('--cwd must be an absolute path');
  }
  if (!options.output && !options.check) {
    throw usageError('--output is required unless --check is supplied');
  }
  return options;
}

function extractDocumentRecordKeys(document) {
  return [...document.matchAll(/<!-- plugin-record:([a-f0-9]{64}) -->/g)].map((match) => match[1]);
}

function verifyDocument(catalog, document) {
  const expectedKeys = new Set(catalog.records.map((record) => record.recordKey));
  const actualKeys = extractDocumentRecordKeys(document);
  const actualKeySet = new Set(actualKeys);
  const sameKeys = actualKeySet.size === expectedKeys.size
    && [...expectedKeys].every((key) => actualKeySet.has(key));
  if (actualKeys.length !== catalog.records.length || !sameKeys) {
    const error = new Error('plugin_catalog_integrity_mismatch');
    error.exitCode = 4;
    throw error;
  }
}

async function writeAtomically(outputPath, document) {
  const absoluteOutputPath = resolve(outputPath);
  const temporaryPath = `${absoluteOutputPath}.${process.pid}.${randomUUID()}.tmp`;
  try {
    await writeFile(temporaryPath, document, 'utf8');
    await rename(temporaryPath, absoluteOutputPath);
  }
  catch (error) {
    await rm(temporaryPath, { force: true }).catch(() => {});
    error.exitCode = 5;
    throw error;
  }
}

export async function runCli(argv = process.argv.slice(2)) {
  const options = parseArguments(argv);
  let catalog;
  let document;
  try {
    catalog = await collectPluginCatalog({
      codexCommand: options.codexCommand,
      cwd: options.cwd,
    });
    document = renderPluginsMarket(catalog, {
      collectedAt: new Date().toISOString(),
    });
  }
  catch (error) {
    if (error.exitCode) {
      throw error;
    }
    error.exitCode = 3;
    throw error;
  }

  if (options.check) {
    try {
      verifyDocument(catalog, await readFile(options.check, 'utf8'));
    }
    catch (error) {
      if (!error.exitCode) {
        error.exitCode = 4;
      }
      throw error;
    }
    return;
  }
  await writeAtomically(options.output, document);
}

const isMain = process.argv[1] && resolve(fileURLToPath(import.meta.url)) === resolve(process.argv[1]);
if (isMain) {
  runCli().catch((error) => {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = error.exitCode ?? 3;
  });
}
