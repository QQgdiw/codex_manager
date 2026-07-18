import { randomUUID } from 'node:crypto';
import { readFile, rename, rm, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const TOPICS = ['coding-agent', 'extension-security', 'robotics-ros', 'embedded-edge', 'eda-fpga-chip', 'engineering-docs'];
const TOPIC_LABELS = {
  'coding-agent': 'Coding Agent',
  'extension-security': 'Extension Security',
  'robotics-ros': 'Robotics / ROS',
  'embedded-edge': 'Embedded / Edge',
  'eda-fpga-chip': 'EDA / FPGA / Chip',
  'engineering-docs': 'Engineering Docs',
};
const PRIORITIES = ['high', 'medium', 'low'];
const SOURCE_TYPES = ['official-announcement', 'official-docs', 'official-changelog', 'official-release', 'standards-body'];
const REQUIRED_KEEP_FIELDS = ['id', 'date', 'organization', 'title', 'mergeKey', 'decisionReason', 'analysis', 'workflowImpact', 'limitations', 'followUp'];
const PRIORITY_RANK = { high: 0, medium: 1, low: 2 };

function isObject(value) { return value !== null && typeof value === 'object' && !Array.isArray(value); }
function nonEmptyString(value) { return typeof value === 'string' && value.trim().length > 0; }
function validDate(value) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(String(value))) return false;
  const [year, month, day] = value.split('-').map(Number);
  const date = new Date(Date.UTC(year, month - 1, day));
  return date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day;
}
function inCoverage(date, { start, end }) { return (!start || date >= start) && (!end || date <= end); }
function pushRequired(errors, label, record, fields) {
  for (const field of fields) if (!nonEmptyString(record[field])) errors.push(`${label}: ${field} is required`);
}
function recordMarker(record) {
  return `<!-- event-record:${JSON.stringify({ id: record.id, date: record.date, organization: record.organization })} -->`;
}
function eventAnchor(id) { return `event-${encodeURIComponent(id).replace(/%/g, '-')}`; }
function escapeHtml(value) { return String(value).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
function error(message) { const result = new Error(message); result.exitCode = 2; return result; }

function checkDate(errors, label, value, options, field = 'date') {
  if (!validDate(value)) { errors.push(`${label}: invalid ${field}`); return false; }
  if ((field === 'date' || field === 'verifiedAt') && !inCoverage(value, options)) errors.push(`${label}: ${field} outside coverage`);
  return true;
}

function checkSources(errors, label, sources, options) {
  if (!Array.isArray(sources) || sources.length === 0) { errors.push(`${label}: officialSources must not be empty`); return; }
  sources.forEach((source, index) => {
    const prefix = `${label}: officialSources[${index}]`;
    if (!isObject(source)) { errors.push(`${prefix} must be an object`); return; }
    if (!nonEmptyString(source.label)) errors.push(`${prefix}.label is required`);
    if (!nonEmptyString(source.url) || !/^https:\/\//i.test(source.url)) errors.push(`${prefix}.url must be HTTPS`);
    if (!SOURCE_TYPES.includes(source.type)) errors.push(`${prefix}.type is invalid`);
    checkDate(errors, prefix, source.verifiedAt, options, 'verifiedAt');
  });
}

export function validateCurationRecords(records, options = {}) {
  const errors = [];
  const kept = [];
  const excluded = [];
  const ids = new Set();
  const mergeKeys = new Set();
  const organizationNames = new Set();
  const topics = Object.fromEntries(TOPICS.map((topic) => [topic, 0]));
  if (!Array.isArray(records)) return { kept, excluded, errors: ['records must be an array'], summary: { total: 0, kept: 0, excluded: 0, organizations: 0, topics } };

  records.forEach((record, index) => {
    const label = isObject(record) && nonEmptyString(record.id) ? record.id : `record ${index + 1}`;
    const localErrors = [];
    if (!isObject(record)) { errors.push(`${label}: must be an object`); return; }
    if (!nonEmptyString(record.id)) localErrors.push(`${label}: id is required`);
    else if (ids.has(record.id)) localErrors.push(`${label}: duplicate id: ${record.id}`);
    else ids.add(record.id);
    const dateValid = checkDate(localErrors, label, record.date, options);
    if (!nonEmptyString(record.organization)) localErrors.push(`${label}: organization is required`);
    if (record.decision === 'exclude') {
      if (!nonEmptyString(record.decisionReason)) localErrors.push(`${label}: decisionReason is required`);
      errors.push(...localErrors);
      if (!localErrors.length) { excluded.push(record); organizationNames.add(record.organization); }
      return;
    }
    if (record.decision !== 'keep') localErrors.push(`${label}: decision must be keep or exclude`);
    pushRequired(localErrors, label, record, REQUIRED_KEEP_FIELDS);
    if (record.occurred !== true) localErrors.push(`${label}: keep records must have occurred: true`);
    if (!Array.isArray(record.partners) || !record.partners.every(nonEmptyString)) localErrors.push(`${label}: partners must be an array of strings`);
    if (!Array.isArray(record.topics) || record.topics.length === 0) localErrors.push(`${label}: topics must not be empty`);
    else record.topics.forEach((topic) => { if (!TOPICS.includes(topic)) localErrors.push(`${label}: unknown topic: ${topic}`); });
    if (!PRIORITIES.includes(record.priority)) localErrors.push(`${label}: priority is invalid`);
    if (!Array.isArray(record.facts) || record.facts.length === 0 || !record.facts.every(nonEmptyString)) localErrors.push(`${label}: facts must be a non-empty array of strings`);
    checkSources(localErrors, label, record.officialSources, options);
    if (nonEmptyString(record.mergeKey)) {
      if (mergeKeys.has(record.mergeKey)) localErrors.push(`${label}: duplicate kept mergeKey: ${record.mergeKey}`);
      else mergeKeys.add(record.mergeKey);
    }
    errors.push(...localErrors);
    if (!localErrors.length && dateValid) {
      kept.push(record);
      organizationNames.add(record.organization);
      record.topics.forEach((topic) => { topics[topic] += 1; });
    }
  });
  return { kept, excluded, errors, summary: { total: records.length, kept: kept.length, excluded: excluded.length, organizations: organizationNames.size, topics } };
}

function sortRecords(records) {
  return [...records].sort((left, right) => right.date.localeCompare(left.date) || left.id.localeCompare(right.id));
}

function sortOrganizations(records) {
  const groups = new Map();
  for (const record of records) {
    const group = groups.get(record.organization) ?? [];
    group.push(record);
    groups.set(record.organization, group);
  }
  return [...groups.entries()].sort(([leftName, left], [rightName, right]) => {
    const leftPriority = Math.min(...left.map((record) => PRIORITY_RANK[record.priority]));
    const rightPriority = Math.min(...right.map((record) => PRIORITY_RANK[record.priority]));
    const leftLatest = left.reduce((latest, record) => latest > record.date ? latest : record.date, '');
    const rightLatest = right.reduce((latest, record) => latest > record.date ? latest : record.date, '');
    return leftPriority - rightPriority || rightLatest.localeCompare(leftLatest) || leftName.localeCompare(rightName);
  }).map(([name, group]) => [name, sortRecords(group)]);
}

export function renderEventMarket(records, metadata = {}) {
  const checked = validateCurationRecords(records, metadata);
  if (checked.errors.length) throw error(checked.errors.join('\n'));
  const lines = [
    '# 工程工作流事件市场',
    '',
    `> 覆盖范围：${metadata.start} 至 ${metadata.end}`,
    `> 复核日期：${metadata.verifiedAt ?? metadata.end ?? ''}`,
    '',
    '## 主题索引',
    '',
  ];
  for (const topic of TOPICS) lines.push(`- [${TOPIC_LABELS[topic]}](#topic-${topic})`);
  for (const topic of TOPICS) {
    const topicRecords = sortRecords(checked.kept.filter((record) => record.topics.includes(topic)));
    lines.push('', `<a id="topic-${topic}"></a>`, `**${TOPIC_LABELS[topic]}**`);
    if (!topicRecords.length) lines.push('- 暂无通过复核的事件。');
    for (const record of topicRecords) lines.push(`- [${record.date} ${escapeHtml(record.title)}](#${eventAnchor(record.id)})`);
  }
  for (const [organization, group] of sortOrganizations(checked.kept)) {
    lines.push('', `## ${escapeHtml(organization)}`);
    for (const record of group) {
      lines.push(
        '',
        `<a id="${eventAnchor(record.id)}"></a>`,
        `### ${escapeHtml(record.title)}`,
        recordMarker(record),
        '',
        `- 日期：${record.date}`,
        `- 优先级：${record.priority}`,
        `- 主题：${record.topics.map((topic) => TOPIC_LABELS[topic]).join('、')}`,
        `- 协作方：${record.partners.length ? record.partners.map(escapeHtml).join('、') : '无'}`,
        '',
        '#### 客观事实',
        ...record.facts.map((fact) => `- ${escapeHtml(fact)}`),
        '',
        '#### 技术剖析',
        escapeHtml(record.analysis),
        '',
        '#### 工作流影响',
        escapeHtml(record.workflowImpact),
        '',
        '#### 局限与风险',
        escapeHtml(record.limitations),
        '',
        '#### 后续关注',
        escapeHtml(record.followUp),
        '',
        '#### 官方来源',
        ...record.officialSources.map((source) => `- [${escapeHtml(source.label)}](${source.url})（${source.type}，复核：${source.verifiedAt}）`),
      );
    }
  }
  return `${lines.join('\n')}\n`;
}

export function validateEventDocument(markdown, options = {}) {
  const errors = [];
  if (!nonEmptyString(markdown)) return { errors: ['document must not be empty'] };
  const lines = markdown.split(/\r?\n/);
  const records = [];
  const ids = new Set();
  const organizationOrder = [];
  let organization = null;
  for (let index = 0; index < lines.length; index += 1) {
    const section = /^##\s+(.+?)\s*$/.exec(lines[index]);
    if (section && section[1] !== '主题索引') {
      organization = section[1];
      organizationOrder.push(organization);
    }
    if (/^###\s+/.test(lines[index])) {
      let markerIndex = index + 1;
      while (markerIndex < lines.length && !lines[markerIndex].trim()) markerIndex += 1;
      if (!lines[markerIndex]?.startsWith('<!-- event-record:')) errors.push(`line ${index + 1}: unmarked event heading`);
    }
    const marker = /^<!-- event-record:(.+) -->$/.exec(lines[index]);
    if (!marker) continue;
    try {
      const record = JSON.parse(marker[1]);
      if (!nonEmptyString(record.id) || !nonEmptyString(record.organization) || !checkDate(errors, record.id || `line ${index + 1}`, record.date, options)) {
        continue;
      }
      if (ids.has(record.id)) errors.push(`${record.id}: duplicate event-record marker`);
      ids.add(record.id);
      if (organization !== record.organization) errors.push(`${record.id}: marker organization does not match its section`);
      const nextHeading = lines.findIndex((line, lineIndex) => lineIndex > index && /^#{2,3}\s+/.test(line));
      const eventLines = lines.slice(index + 1, nextHeading < 0 ? undefined : nextHeading);
      const priority = /^- 优先级：(high|medium|low)$/.exec(eventLines.find((line) => line.startsWith('- 优先级：')) ?? '')?.[1];
      if (!priority) errors.push(`${record.id}: missing or invalid priority`);
      records.push({ ...record, organization, priority, line: index + 1 });
    } catch {
      errors.push(`line ${index + 1}: invalid event-record marker`);
    }
  }
  if (!records.length) errors.push('document contains no event-record markers');
  for (const topic of TOPICS) if (!markdown.includes(`id="topic-${topic}"`)) errors.push(`missing topic anchor: ${topic}`);
  for (const requiredHeading of ['#### 客观事实', '#### 技术剖析', '#### 工作流影响', '#### 局限与风险', '#### 后续关注', '#### 官方来源']) {
    if (!markdown.includes(requiredHeading)) errors.push(`missing document section: ${requiredHeading}`);
  }
  const byOrganization = new Map();
  for (const record of records) byOrganization.set(record.organization, [...(byOrganization.get(record.organization) ?? []), record]);
  for (const [name, group] of byOrganization) {
    const expected = sortRecords(group);
    if (group.some((record, index) => record.id !== expected[index].id)) errors.push(`organization ${name}: records are not sorted by date descending and id`);
  }
  const actualOrganizations = organizationOrder.filter((name, index, names) => names.indexOf(name) === index && byOrganization.has(name));
  const expectedOrganizations = sortOrganizations(records).map(([name]) => name);
  if (actualOrganizations.some((name, index) => name !== expectedOrganizations[index])) errors.push('organizations are not sorted by highest priority, latest date, and name');
  return { errors, records };
}

export async function atomicWrite(output, text, { writeFileImpl = writeFile, renameImpl = rename, rmImpl = rm } = {}) {
  const target = resolve(output);
  const temporary = `${target}.${process.pid}.${randomUUID()}.tmp`;
  try {
    await writeFileImpl(temporary, text, 'utf8');
    await renameImpl(temporary, target);
  } catch (cause) {
    await rmImpl(temporary, { force: true }).catch(() => {});
    throw cause;
  }
}

function parseArguments(argv) {
  const [command, ...args] = argv;
  if (!['validate-curation', 'render', 'validate-doc'].includes(command)) throw error('command must be validate-curation, render, or validate-doc');
  const options = { command };
  for (let index = 0; index < args.length; index += 2) {
    const name = args[index];
    const value = args[index + 1];
    if (!value || !['--input', '--output', '--start', '--end', '--verified-at'].includes(name)) throw error(`invalid argument: ${name ?? ''}`);
    options[name.slice(2).replace(/-([a-z])/g, (_, letter) => letter.toUpperCase())] = value;
  }
  if (!options.input || !options.start || !options.end || (command === 'render' && (!options.output || !options.verifiedAt))) throw error('required argument is missing');
  if (!validDate(options.start) || !validDate(options.end) || options.start > options.end) throw error('invalid coverage dates');
  if (options.verifiedAt && !validDate(options.verifiedAt)) throw error('invalid verified-at date');
  return options;
}

function parseJsonl(content) {
  return content.split(/\r?\n/).filter((line) => line.trim()).map((line, index) => {
    try { return JSON.parse(line); } catch { throw error(`line ${index + 1}: invalid JSON`); }
  });
}

export async function runCli(argv = process.argv.slice(2), dependencies = {}) {
  const options = parseArguments(argv);
  const content = await (dependencies.readFileImpl ?? readFile)(options.input, 'utf8');
  if (options.command === 'validate-doc') {
    const result = validateEventDocument(content, options);
    if (result.errors.length) throw error(result.errors.join('\n'));
    return result;
  }
  const records = parseJsonl(content);
  if (options.command === 'validate-curation') {
    const result = validateCurationRecords(records, options);
    if (result.errors.length) throw error(result.errors.join('\n'));
    return result;
  }
  const rendered = renderEventMarket(records, options);
  const documentResult = validateEventDocument(rendered, options);
  if (documentResult.errors.length) throw error(documentResult.errors.join('\n'));
  await atomicWrite(options.output, rendered, dependencies);
  return documentResult;
}

if (process.argv[1] && resolve(fileURLToPath(import.meta.url)) === resolve(process.argv[1])) {
  runCli().then((result) => process.stdout.write(`${JSON.stringify(result.summary ?? { records: result.records?.length ?? 0 })}\n`)).catch((cause) => {
    process.stderr.write(`${cause.message}\n`);
    process.exitCode = cause.exitCode ?? 3;
  });
}
