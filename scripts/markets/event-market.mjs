import { randomUUID } from 'node:crypto';
import { readFile, rename, rm, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const TOPICS = ['coding-agent', 'extension-security', 'robotics-ros', 'embedded-edge', 'eda-fpga-chip', 'engineering-docs'];
const TOPIC_LABELS = {
  'coding-agent': '编码智能体',
  'extension-security': '扩展安全',
  'robotics-ros': '机器人与 ROS',
  'embedded-edge': '嵌入式与边缘计算',
  'eda-fpga-chip': 'EDA、FPGA 与芯片',
  'engineering-docs': '工程文档',
};
const PRIORITIES = ['high', 'medium', 'low'];
const SOURCE_TYPES = ['official-announcement', 'official-docs', 'official-changelog', 'official-release', 'standards-body'];
const REQUIRED_KEEP_FIELDS = ['id', 'date', 'organization', 'title', 'mergeKey', 'decisionReason', 'analysis', 'workflowImpact', 'limitations', 'followUp'];
const PRIORITY_RANK = { high: 0, medium: 1, low: 2 };

function isObject(value) { return value !== null && typeof value === 'object' && !Array.isArray(value); }
function nonEmptyString(value) { return typeof value === 'string' && value.trim().length > 0; }
function hasControlCharacters(value) { return /[\u0000-\u001F\u007F]/.test(String(value)); }
function isStableSlug(value) { return typeof value === 'string' && /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(value); }
function compareText(left, right) { return left === right ? 0 : left < right ? -1 : 1; }
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
function eventAnchor(id) { return `event-${id}`; }
function escapeHtml(value) { return String(value).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
function escapeMarkdownText(value) {
  return escapeHtml(value).replace(/([\\`*_{}\[\]()#+.!|])/g, '\\$1');
}
function error(message) { const result = new Error(message); result.exitCode = 2; return result; }

function validOfficialUrl(value) {
  if (!nonEmptyString(value) || hasControlCharacters(value) || !/^https:\/\//i.test(value)) return null;
  try {
    const url = new URL(value);
    return url.protocol === 'https:' && url.hostname ? url : null;
  } catch {
    return null;
  }
}

function checkText(errors, label, field, value, { marker = false } = {}) {
  if (typeof value !== 'string') return;
  if (hasControlCharacters(value)) errors.push(`${label}: ${field} contains control characters`);
  if (marker && value.includes('-->')) errors.push(`${label}: ${field} contains unsafe marker text`);
}

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
    else checkText(errors, label, `officialSources[${index}].label`, source.label);
    if (!validOfficialUrl(source.url)) errors.push(`${prefix}.url must be a valid HTTPS URL`);
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
    else if (!isStableSlug(record.id)) localErrors.push(`${label}: id must be a stable lowercase slug`);
    else if (ids.has(record.id)) localErrors.push(`${label}: duplicate id: ${record.id}`);
    else ids.add(record.id);
    const dateValid = checkDate(localErrors, label, record.date, options);
    if (!nonEmptyString(record.organization)) localErrors.push(`${label}: organization is required`);
    else checkText(localErrors, label, 'organization', record.organization, { marker: true });
    if (record.decision === 'exclude') {
      if (!nonEmptyString(record.decisionReason)) localErrors.push(`${label}: decisionReason is required`);
      errors.push(...localErrors);
      if (!localErrors.length) { excluded.push(record); organizationNames.add(record.organization); }
      return;
    }
    if (record.decision !== 'keep') localErrors.push(`${label}: decision must be keep or exclude`);
    pushRequired(localErrors, label, record, REQUIRED_KEEP_FIELDS);
    for (const field of ['title', 'mergeKey', 'decisionReason', 'analysis', 'workflowImpact', 'limitations', 'followUp']) checkText(localErrors, label, field, record[field]);
    if (record.occurred !== true) localErrors.push(`${label}: keep records must have occurred: true`);
    if (!Array.isArray(record.partners) || !record.partners.every(nonEmptyString)) localErrors.push(`${label}: partners must be an array of strings`);
    else record.partners.forEach((partner, index) => checkText(localErrors, label, `partners[${index}]`, partner));
    if (!Array.isArray(record.topics) || record.topics.length === 0) localErrors.push(`${label}: topics must not be empty`);
    else record.topics.forEach((topic) => { if (!TOPICS.includes(topic)) localErrors.push(`${label}: unknown topic: ${topic}`); });
    if (!PRIORITIES.includes(record.priority)) localErrors.push(`${label}: priority is invalid`);
    if (!Array.isArray(record.facts) || record.facts.length === 0 || !record.facts.every(nonEmptyString)) localErrors.push(`${label}: facts must be a non-empty array of strings`);
    else record.facts.forEach((fact, index) => checkText(localErrors, label, `facts[${index}]`, fact));
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
  return [...records].sort((left, right) => compareText(right.date, left.date) || compareText(left.id, right.id));
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
    return leftPriority - rightPriority || compareText(rightLatest, leftLatest) || compareText(leftName, rightName);
  }).map(([name, group]) => [name, sortRecords(group)]);
}

export function renderEventMarket(records, metadata = {}) {
  const checked = validateCurationRecords(records, metadata);
  if (checked.errors.length) throw error(checked.errors.join('\n'));
  const lines = [
    '# 工程工作流事件市场',
    '',
    `> 覆盖时间：${metadata.start} 至 ${metadata.end}`,
    `> 复核日期：${metadata.verifiedAt ?? metadata.end ?? ''}`,
    '> 更新方式：由受控 JSONL 记录经校验后自动生成。',
    `> 收录数量：${checked.kept.length}`,
    '> 官方来源规则：每项必须提供经复核的 HTTPS 官方来源。',
    '> 事实与分析：客观事实仅陈述来源支持的信息，技术剖析明确标注分析判断。',
    '',
    '## 主题索引',
    '',
  ];
  for (const topic of TOPICS) lines.push(`- [${escapeMarkdownText(TOPIC_LABELS[topic])}](#topic-${topic})`);
  for (const topic of TOPICS) {
    const topicRecords = sortRecords(checked.kept.filter((record) => record.topics.includes(topic)));
    lines.push('', `<a id="topic-${topic}"></a>`, `**${escapeMarkdownText(TOPIC_LABELS[topic])}**`);
    if (!topicRecords.length) lines.push('- 暂无通过复核的事件。');
    for (const record of topicRecords) lines.push(`- [${record.date} ${escapeMarkdownText(record.title)}](#${eventAnchor(record.id)})`);
  }
  for (const [organization, group] of sortOrganizations(checked.kept)) {
    lines.push('', `## ${escapeMarkdownText(organization)}`);
    for (const record of group) {
      lines.push(
        '',
        `<a id="${eventAnchor(record.id)}"></a>`,
        `### ${escapeMarkdownText(record.title)}`,
        recordMarker(record),
        '',
        `- 日期：${record.date}`,
        `- 优先级：${record.priority}`,
        `- 主题：${record.topics.map((topic) => escapeMarkdownText(TOPIC_LABELS[topic])).join('、')}`,
        `- 协作方：${record.partners.length ? record.partners.map(escapeMarkdownText).join('、') : '无'}`,
        '',
        '#### 客观事实',
        ...record.facts.map((fact) => `- ${escapeMarkdownText(fact)}`),
        '',
        '#### 技术剖析',
        escapeMarkdownText(record.analysis),
        '',
        '#### 工作流影响',
        escapeMarkdownText(record.workflowImpact),
        '',
        '#### 局限与风险',
        escapeMarkdownText(record.limitations),
        '',
        '#### 后续关注',
        escapeMarkdownText(record.followUp),
        '',
        '#### 官方来源',
        ...record.officialSources.map((source) => `- [${escapeMarkdownText(source.label)}](<${validOfficialUrl(source.url).href}>)（${source.type}，复核：${source.verifiedAt}）`),
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
  const anchors = new Map();
  let organization = null;
  for (let index = 0; index < lines.length; index += 1) {
    const anchor = /^<a id="([^"]+)"><\/a>$/.exec(lines[index]);
    if (!anchor) continue;
    anchors.set(anchor[1], [...(anchors.get(anchor[1]) ?? []), index + 1]);
  }
  for (const [anchor, positions] of anchors) if (positions.length > 1) errors.push(`duplicate anchor: ${anchor}`);
  const requiredHeaders = [
    ['覆盖时间', /^> 覆盖时间：\d{4}-\d{2}-\d{2} 至 \d{4}-\d{2}-\d{2}$/],
    ['更新方式', /^> 更新方式：.+$/],
    ['官方来源规则', /^> 官方来源规则：.+$/],
    ['事实与分析', /^> 事实与分析：.+$/],
  ];
  for (const [name, pattern] of requiredHeaders) if (!lines.some((line) => pattern.test(line))) errors.push(`missing document header: ${name}`);
  const coverageHeader = lines.find((line) => /^> 覆盖时间：/.test(line));
  if (coverageHeader && options.start && options.end && coverageHeader !== `> 覆盖时间：${options.start} 至 ${options.end}`) errors.push('coverage header does not match requested range');
  const countHeader = /^> 收录数量：(\d+)$/.exec(lines.find((line) => /^> 收录数量：/.test(line)) ?? '');
  if (!countHeader) errors.push('missing document header: 收录数量');
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
      const label = record.id || `line ${index + 1}`;
      if (!isStableSlug(record.id)) errors.push(`${label}: marker id must be a stable lowercase slug`);
      if (!nonEmptyString(record.organization) || hasControlCharacters(record.organization) || record.organization.includes('-->')) errors.push(`${label}: marker organization is unsafe`);
      if (!isStableSlug(record.id) || !nonEmptyString(record.organization) || !checkDate(errors, label, record.date, options)) {
        continue;
      }
      if (ids.has(record.id)) errors.push(`${record.id}: duplicate event-record marker`);
      ids.add(record.id);
      if (organization !== escapeMarkdownText(record.organization)) errors.push(`${record.id}: marker organization does not match its section`);
      if ((anchors.get(eventAnchor(record.id)) ?? []).length !== 1) errors.push(`${record.id}: event anchor must exist exactly once`);
      const nextHeading = lines.findIndex((line, lineIndex) => lineIndex > index && /^#{2,3}\s+/.test(line));
      const eventLines = lines.slice(index + 1, nextHeading < 0 ? undefined : nextHeading);
      const priority = /^- 优先级：(high|medium|low)$/.exec(eventLines.find((line) => line.startsWith('- 优先级：')) ?? '')?.[1];
      if (!priority) errors.push(`${record.id}: missing or invalid priority`);
      const sectionContent = (heading) => {
        const headingIndex = eventLines.indexOf(heading);
        if (headingIndex < 0) return [];
        const nextIndex = eventLines.findIndex((line, lineIndex) => lineIndex > headingIndex && /^####\s+/.test(line));
        return eventLines.slice(headingIndex + 1, nextIndex < 0 ? undefined : nextIndex).filter((line) => line.trim());
      };
      for (const heading of ['客观事实', '技术剖析', '工作流影响', '局限与风险', '后续关注']) {
        const content = sectionContent(`#### ${heading}`);
        if (!content.length || (heading === '客观事实' && !content.some((line) => /^-\s+/.test(line)))) errors.push(`${record.id}: missing or empty ${heading} section`);
      }
      const sources = sectionContent('#### 官方来源');
      const sourceEntries = sources.filter((line) => line.startsWith('- '));
      if (!sourceEntries.length) errors.push(`${record.id}: missing official source`);
      for (const source of sourceEntries) {
        const sourceLink = /^- \[[^\]]+\]\(<([^>]+)>\)/.exec(source);
        if (!sourceLink || !validOfficialUrl(sourceLink?.[1])) errors.push(`${record.id}: invalid official source`);
      }
      records.push({ ...record, sectionOrganization: organization, priority, line: index + 1 });
    } catch {
      errors.push(`line ${index + 1}: invalid event-record marker`);
    }
  }
  if (!records.length) errors.push('document contains no event-record markers');
  if (countHeader && Number(countHeader[1]) !== records.length) errors.push('header record count does not match event markers');
  for (const topic of TOPICS) {
    if ((anchors.get(`topic-${topic}`) ?? []).length !== 1) errors.push(`missing or duplicate topic anchor: ${topic}`);
    if (!markdown.includes(`[${escapeMarkdownText(TOPIC_LABELS[topic])}](#topic-${topic})`)) errors.push(`missing topic index entry: ${topic}`);
  }
  const topicIndexStart = lines.findIndex((line) => line === '## 主题索引');
  const topicIndexEnd = lines.findIndex((line, index) => index > topicIndexStart && /^##\s+/.test(line));
  const topicIndexLines = lines.slice(topicIndexStart + 1, topicIndexEnd < 0 ? undefined : topicIndexEnd);
  for (const line of topicIndexLines) {
    const link = /\]\(#(event-[a-z0-9]+(?:-[a-z0-9]+)*)\)$/.exec(line);
    if (link && (anchors.get(link[1]) ?? []).length !== 1) errors.push(`topic index link ${link[1]} does not target exactly one event anchor`);
  }
  const byOrganization = new Map();
  for (const record of records) byOrganization.set(record.organization, [...(byOrganization.get(record.organization) ?? []), record]);
  for (const [name, group] of byOrganization) {
    const expected = sortRecords(group);
    if (group.some((record, index) => record.id !== expected[index].id)) errors.push(`organization ${name}: records are not sorted by date descending and id`);
  }
  const renderedOrganizations = new Set([...byOrganization.keys()].map(escapeMarkdownText));
  const actualOrganizations = organizationOrder.filter((name, index, names) => names.indexOf(name) === index && renderedOrganizations.has(name));
  const expectedOrganizations = sortOrganizations(records).map(([name]) => escapeMarkdownText(name));
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
  const records = [];
  content.split(/\r?\n/).forEach((line, index) => {
    if (!line.trim()) return;
    try { records.push(JSON.parse(line)); } catch { throw error(`line ${index + 1}: invalid JSON`); }
  });
  return records;
}

export async function runCli(argv = process.argv.slice(2), dependencies = {}) {
  const options = parseArguments(argv);
  if (options.command === 'render' && resolve(options.input) === resolve(options.output)) throw error('input and output must resolve to different paths');
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
