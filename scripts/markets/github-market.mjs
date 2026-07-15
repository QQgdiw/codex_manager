import { randomUUID } from 'node:crypto';
import { readFile, rename, rm, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const GITHUB_SEARCH_URL = 'https://api.github.com/search/repositories';
const USER_AGENT = 'codex-github-market/1.0';
const ISO_WEEK_PATTERN = /^(\d{4})-W(0[1-9]|[1-4]\d|5[0-3])$/;
const ISO_TIMESTAMP_PATTERN = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$/;

function usageError(message) {
  const error = new Error(message);
  error.exitCode = 2;
  return error;
}

function isObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function isIsoWeek(value) {
  const match = ISO_WEEK_PATTERN.exec(value);
  if (!match) {
    return false;
  }
  const year = Number(match[1]);
  const week = Number(match[2]);
  const decemberTwentyEighth = new Date(Date.UTC(year, 11, 28));
  const day = decemberTwentyEighth.getUTCDay() || 7;
  const thursday = new Date(decemberTwentyEighth);
  thursday.setUTCDate(decemberTwentyEighth.getUTCDate() + 4 - day);
  const yearStart = new Date(Date.UTC(thursday.getUTCFullYear(), 0, 1));
  const maximumWeek = Math.ceil((((thursday - yearStart) / 86_400_000) + 1) / 7);
  return week <= maximumWeek;
}

function isCalendarDate(value) {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value ?? '');
  if (!match) {
    return false;
  }
  const [year, month, day] = match.slice(1).map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  return date.getUTCFullYear() === year
    && date.getUTCMonth() === month - 1
    && date.getUTCDate() === day;
}

function isIsoTimestamp(value) {
  return typeof value === 'string'
    && ISO_TIMESTAMP_PATTERN.test(value)
    && isCalendarDate(value.slice(0, 10))
    && !Number.isNaN(Date.parse(value));
}

function repositoryKey(repository) {
  return typeof repository === 'string' ? repository.toLowerCase() : '';
}

function recordLocation(path, line) {
  return `${path}:${line}`;
}

function projectRepository(repository) {
  return {
    full_name: repository.full_name ?? null,
    html_url: repository.html_url ?? null,
    stargazers_count: repository.stargazers_count ?? null,
    description: repository.description ?? null,
    created_at: repository.created_at ?? null,
    updated_at: repository.updated_at ?? null,
    language: repository.language ?? null,
    topics: Array.isArray(repository.topics) ? repository.topics : [],
    license: { spdx_id: repository.license?.spdx_id ?? null },
  };
}

function requestHeaders(token) {
  const headers = {
    Accept: 'application/vnd.github+json',
    'User-Agent': USER_AGENT,
  };
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }
  return headers;
}

function nextPageUrl(linkHeader, initialUrl) {
  if (typeof linkHeader !== 'string') {
    return null;
  }
  const match = /<([^>]+)>;\s*rel="next"/.exec(linkHeader);
  if (!match) {
    return null;
  }
  let url;
  try {
    url = new URL(match[1]);
  }
  catch {
    throw new Error('github_api_invalid_pagination');
  }
  if (url.origin !== 'https://api.github.com' || url.pathname !== '/search/repositories') {
    throw new Error('github_api_invalid_pagination');
  }
  const page = url.searchParams.get('page');
  if (!/^[1-9]\d*$/.test(page ?? '')) {
    throw new Error('github_api_invalid_pagination');
  }
  const next = new URL(initialUrl);
  next.searchParams.set('page', page);
  return next.toString();
}

function githubApiError(response) {
  if (response.status === 429
    || (response.status === 403 && response.headers?.get('x-ratelimit-remaining') === '0')) {
    return new Error('github_api_rate_limited');
  }
  return new Error(`github_api_http_${response.status}`);
}

export async function collectGitHubRepositories({ from, to, fetchImpl = fetch, token } = {}) {
  if (!isCalendarDate(from) || !isCalendarDate(to) || from > to) {
    throw usageError('--from and --to must be YYYY-MM-DD values with from not after to');
  }

  const initialUrl = new URL(GITHUB_SEARCH_URL);
  initialUrl.searchParams.set('q', `created:${from}..${to} stars:>=1000`);
  initialUrl.searchParams.set('sort', 'stars');
  initialUrl.searchParams.set('order', 'desc');
  initialUrl.searchParams.set('per_page', '100');
  initialUrl.searchParams.set('page', '1');

  const records = [];
  const seenUrls = new Set();
  let url = initialUrl.toString();
  while (url) {
    if (seenUrls.has(url)) {
      throw new Error('github_api_invalid_pagination');
    }
    seenUrls.add(url);

    let response;
    try {
      response = await fetchImpl(url, { headers: requestHeaders(token) });
    }
    catch {
      throw new Error('github_api_network_error');
    }
    if (!response?.ok) {
      throw githubApiError(response ?? { status: 'unknown' });
    }

    let body;
    try {
      body = await response.json();
    }
    catch {
      throw new Error('github_api_invalid_response');
    }
    if (!isObject(body) || !Array.isArray(body.items)) {
      throw new Error('github_api_invalid_response');
    }
    records.push(...body.items
      .filter((repository) => Number.isInteger(repository?.stargazers_count) && repository.stargazers_count >= 1000)
      .map(projectRepository));
    url = nextPageUrl(response.headers?.get('link'), initialUrl);
  }
  return records;
}

async function writeAtomically(output, document, {
  writeFileImpl = writeFile,
  renameImpl = rename,
  rmImpl = rm,
  randomUUIDImpl = randomUUID,
} = {}) {
  const outputPath = resolve(output);
  const temporaryPath = `${outputPath}.${process.pid}.${randomUUIDImpl()}.tmp`;
  try {
    await writeFileImpl(temporaryPath, document, 'utf8');
    await renameImpl(temporaryPath, outputPath);
  }
  catch {
    await rmImpl(temporaryPath, { force: true }).catch(() => {});
    throw new Error('github_output_write_failed');
  }
}

export async function collectToFile({ from, to, output, fetchImpl = fetch, token, ...writeDependencies } = {}) {
  if (typeof output !== 'string' || output.length === 0) {
    throw usageError('--output is required');
  }
  const records = await collectGitHubRepositories({ from, to, fetchImpl, token });
  await writeAtomically(output, `${JSON.stringify(records, null, 2)}\n`, writeDependencies);
  return records;
}

function markersFromDocument({ path, content }, markerName) {
  const records = [];
  const errors = [];
  const markerPattern = new RegExp(`<!--\\s*${markerName}:(.*?)\\s*-->`);
  for (const [index, line] of content.split(/\r?\n/).entries()) {
    const match = markerPattern.exec(line);
    if (!match) {
      continue;
    }
    const lineNumber = index + 1;
    try {
      const record = JSON.parse(match[1]);
      if (!isObject(record)) {
        throw new Error('record must be an object');
      }
      records.push({ record, path, line: lineNumber });
    }
    catch {
      errors.push(`${recordLocation(path, lineNumber)}: invalid ${markerName} JSON`);
    }
  }
  return { records, errors };
}

function validateGitHubDocumentStructure({ path, content }) {
  const lines = content.split(/\r?\n/);
  const repositoryHeadingPattern = /^###\s+([^\s/]+\/[^\s/]+)\s*$/;
  const headingPattern = /^#{1,3}\s/;
  const markerPattern = /<!--\s*github-record:.*?\s*-->/g;
  const errors = [];
  let unmarkedEntries = 0;

  for (let index = 0; index < lines.length; index += 1) {
    const heading = repositoryHeadingPattern.exec(lines[index]);
    if (!heading || isIsoWeek(heading[1])) {
      continue;
    }
    let markerCount = 0;
    for (let sectionIndex = index + 1; sectionIndex < lines.length; sectionIndex += 1) {
      if (headingPattern.test(lines[sectionIndex])) {
        break;
      }
      markerCount += lines[sectionIndex].match(markerPattern)?.length ?? 0;
    }
    if (markerCount !== 1) {
      unmarkedEntries += 1;
      errors.push(`${recordLocation(path, index + 1)}: repository heading ${heading[1]} requires exactly one github-record marker (found ${markerCount})`);
    }
  }

  return { errors, unmarkedEntries };
}

function validateGitHubRecord(entry, errors) {
  const { record, path, line } = entry;
  const location = recordLocation(path, line);
  if (!isIsoWeek(record.week)) {
    errors.push(`${location}: invalid ISO week`);
  }
  if (typeof record.repository !== 'string' || record.repository.length === 0) {
    errors.push(`${location}: repository is required`);
  }
  if (!Number.isInteger(record.stars) || record.stars < 1000) {
    errors.push(`${location}: stars must be at least 1000`);
  }
  if (!isIsoTimestamp(record.capturedAt)) {
    errors.push(`${location}: capturedAt must be an ISO-8601 timestamp`);
  }
  if (!['A', 'B', 'C'].includes(record.sourceLevel)) {
    errors.push(`${location}: sourceLevel must be A, B, or C`);
  }
}

function validateDerivedRecord(entry, errors) {
  const { record, path, line } = entry;
  const location = recordLocation(path, line);
  if (typeof record.repository !== 'string' || record.repository.length === 0) {
    errors.push(`${location}: repository is required`);
  }
  if (!isIsoWeek(record.week)) {
    errors.push(`${location}: invalid ISO week`);
  }
  if (!['mcp', 'skill', 'tool'].includes(record.kind)) {
    errors.push(`${location}: kind must be mcp, skill, or tool`);
  }
}

function summarize(records, duplicates, derivedMissing, unmarkedEntries) {
  const weeklyCounts = new Map();
  for (const entry of records) {
    weeklyCounts.set(entry.record.week, (weeklyCounts.get(entry.record.week) ?? 0) + 1);
  }
  const weeksUnder20 = [...weeklyCounts.entries()]
    .filter(([, count]) => count < 20)
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([week, count]) => ({ week, count }));
  return {
    records: records.length,
    weeks: weeklyCounts.size,
    weeksUnder20,
    duplicates,
    derivedMissing,
    unmarkedEntries,
  };
}

export function validateMarketDocuments({ github, mcp, tool } = {}) {
  if (!github || typeof github.path !== 'string' || typeof github.content !== 'string') {
    throw usageError('--github document is required');
  }
  const githubMarkers = markersFromDocument(github, 'github-record');
  const githubStructure = validateGitHubDocumentStructure(github);
  const mcpMarkers = mcp ? markersFromDocument(mcp, 'derived-record') : { records: [], errors: [] };
  const toolMarkers = tool ? markersFromDocument(tool, 'derived-record') : { records: [], errors: [] };
  const errors = [
    ...githubMarkers.errors,
    ...githubStructure.errors,
    ...mcpMarkers.errors,
    ...toolMarkers.errors,
  ];

  for (const entry of githubMarkers.records) {
    validateGitHubRecord(entry, errors);
  }
  for (const entry of [...mcpMarkers.records, ...toolMarkers.records]) {
    validateDerivedRecord(entry, errors);
  }

  const firstGitHubByRepository = new Map();
  let duplicates = 0;
  for (const entry of githubMarkers.records) {
    const key = repositoryKey(entry.record.repository);
    if (!key) {
      continue;
    }
    const prior = firstGitHubByRepository.get(key);
    if (prior && prior.record.week !== entry.record.week) {
      duplicates += 1;
      errors.push(`${recordLocation(entry.path, entry.line)}: repository duplicates a different week (${recordLocation(prior.path, prior.line)})`);
      continue;
    }
    if (!prior) {
      firstGitHubByRepository.set(key, entry);
    }
  }

  const githubOrigins = new Set(githubMarkers.records.map((entry) => `${repositoryKey(entry.record.repository)}\u0000${entry.record.week}`));
  let derivedMissing = 0;
  for (const entry of [...mcpMarkers.records, ...toolMarkers.records]) {
    const origin = `${repositoryKey(entry.record.repository)}\u0000${entry.record.week}`;
    if (!githubOrigins.has(origin)) {
      derivedMissing += 1;
      errors.push(`${recordLocation(entry.path, entry.line)}: derived record has no GitHub origin`);
    }
  }

  const mcpByIdentity = new Map();
  for (const entry of mcpMarkers.records) {
    const identity = `${repositoryKey(entry.record.repository)}\u0000${entry.record.week}`;
    if (!mcpByIdentity.has(identity)) {
      mcpByIdentity.set(identity, entry);
    }
  }
  for (const entry of toolMarkers.records) {
    const identity = `${repositoryKey(entry.record.repository)}\u0000${entry.record.week}`;
    const mcpEntry = mcpByIdentity.get(identity);
    if (mcpEntry) {
      errors.push(`${recordLocation(entry.path, entry.line)}: derived record also appears in ${recordLocation(mcpEntry.path, mcpEntry.line)}`);
    }
  }

  return {
    summary: summarize(githubMarkers.records, duplicates, derivedMissing, githubStructure.unmarkedEntries),
    errors,
  };
}

function formatSummary(summary) {
  const lowWeeks = summary.weeksUnder20.length === 0
    ? 'none'
    : summary.weeksUnder20.map(({ week, count }) => `${week}(${count})`).join(', ');
  return [
    `records: ${summary.records}`,
    `weeks: ${summary.weeks}`,
    `weeksUnder20: ${lowWeeks}`,
    `duplicates: ${summary.duplicates}`,
    `derivedMissing: ${summary.derivedMissing}`,
    `unmarkedEntries: ${summary.unmarkedEntries}`,
  ].join('\n');
}

function parseCliArguments(argv) {
  const [command, ...argumentsList] = argv;
  if (!['collect', 'validate'].includes(command)) {
    throw usageError('command must be collect or validate');
  }
  const options = { command };
  for (let index = 0; index < argumentsList.length; index += 1) {
    const argument = argumentsList[index];
    if (!['--from', '--to', '--output', '--github', '--mcp', '--tool'].includes(argument)) {
      throw usageError(`unknown argument: ${argument}`);
    }
    const value = argumentsList[index + 1];
    if (value == null || value.startsWith('--')) {
      throw usageError(`missing value for ${argument}`);
    }
    index += 1;
    options[argument.slice(2)] = value;
  }
  if (command === 'collect' && (!options.from || !options.to || !options.output)) {
    throw usageError('collect requires --from, --to, and --output');
  }
  if (command === 'validate' && !options.github) {
    throw usageError('validate requires --github');
  }
  return options;
}

export async function runCli(argv = process.argv.slice(2), {
  fetchImpl = fetch,
  readFileImpl = readFile,
  stdout = process.stdout,
} = {}) {
  const options = parseCliArguments(argv);
  if (options.command === 'collect') {
    await collectToFile({
      from: options.from,
      to: options.to,
      output: options.output,
      fetchImpl,
      token: process.env.GITHUB_TOKEN,
    });
    return;
  }

  let documents;
  try {
    documents = {
      github: { path: options.github, content: await readFileImpl(options.github, 'utf8') },
      ...(options.mcp ? { mcp: { path: options.mcp, content: await readFileImpl(options.mcp, 'utf8') } } : {}),
      ...(options.tool ? { tool: { path: options.tool, content: await readFileImpl(options.tool, 'utf8') } } : {}),
    };
  }
  catch {
    const error = new Error('github_market_document_read_failed');
    error.exitCode = 3;
    throw error;
  }
  const result = validateMarketDocuments(documents);
  stdout.write(`${formatSummary(result.summary)}\n`);
  if (result.errors.length > 0) {
    const error = new Error(result.errors.join('\n'));
    error.exitCode = 4;
    throw error;
  }
}

const isMain = process.argv[1] && resolve(fileURLToPath(import.meta.url)) === resolve(process.argv[1]);
if (isMain) {
  runCli().catch((error) => {
    process.stderr.write(`${error.message}\n`);
    process.exitCode = error.exitCode ?? 3;
  });
}
