import { randomUUID } from 'node:crypto';
import { readFile, realpath, rename, rm, stat, writeFile } from 'node:fs/promises';
import { basename, dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const TOPICS = ['robotics-ros', 'embedded-edge', 'eda-fpga-chip', 'engineering-docs', 'coding-agent', 'extension-security'];
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
function hasUnpairedSurrogate(value) {
  const text = String(value);
  for (let index = 0; index < text.length; index += 1) {
    const code = text.charCodeAt(index);
    if (code >= 0xD800 && code <= 0xDBFF) {
      const next = text.charCodeAt(index + 1);
      if (!(next >= 0xDC00 && next <= 0xDFFF)) return true;
      index += 1;
    } else if (code >= 0xDC00 && code <= 0xDFFF) return true;
  }
  return false;
}
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
function markerPayload(record) {
  return JSON.stringify({ id: record.id, date: record.date, organization: record.organization })
    .replace(/[<>&]/g, (character) => ({ '<': '\\u003c', '>': '\\u003e', '&': '\\u0026' })[character]);
}
function recordMarker(record) {
  return `<!-- event-record:${markerPayload(record)} -->`;
}
function eventAnchor(id) { return `event-${id}`; }
function organizationAnchor(organization) { return `organization-${Buffer.from(organization, 'utf8').toString('base64url')}`; }
function escapeHtml(value) { return String(value).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
function escapeMarkdownText(value) {
  const escaped = escapeHtml(value).replace(/([\\`*_{}\[\]()#+.!|])/g, '\\$1');
  return escaped.replace(/^([ ]{0,3})(?=(?:~{3,}|-{3,}|`{3,}|[-+*]\s|\d+[.)]\s|>\s?|#{1,6}(?:\s|$)))/, '$1\\');
}
function error(message) { const result = new Error(message); result.exitCode = 2; return result; }

function topicIndexLabel(record) {
  return `${record.date}｜${escapeMarkdownText(record.title)}｜${escapeMarkdownText(record.organization)}`;
}

function parseMarkerPayload(payload) {
  const record = JSON.parse(payload);
  if (!isObject(record) || Object.keys(record).length !== 3 || !['id', 'date', 'organization'].every((field) => Object.hasOwn(record, field))) throw error('invalid event-record marker contract');
  if (markerPayload(record) !== payload) throw error('invalid event-record marker encoding');
  return record;
}

function findUnescaped(value, character, start = 0) {
  for (let index = start; index < value.length; index += 1) {
    if (value[index] !== character) continue;
    let backslashes = 0;
    for (let previous = index - 1; previous >= 0 && value[previous] === '\\'; previous -= 1) backslashes += 1;
    if (backslashes % 2 === 0) return index;
  }
  return -1;
}

function parseMarkdownLink(line) {
  if (!line.startsWith('- [')) return null;
  const labelEnd = findUnescaped(line, ']', 3);
  if (labelEnd < 0 || line[labelEnd + 1] !== '(') return null;
  const targetStart = labelEnd + 2;
  if (line[targetStart] === '<') {
    const targetEnd = line.indexOf('>', targetStart + 1);
    if (targetEnd < 0 || line[targetEnd + 1] !== ')') return null;
    return { label: line.slice(3, labelEnd), target: line.slice(targetStart + 1, targetEnd), end: targetEnd + 2 };
  }
  const targetEnd = findUnescaped(line, ')', targetStart);
  if (targetEnd < 0) return null;
  return { label: line.slice(3, labelEnd), target: line.slice(targetStart, targetEnd), end: targetEnd + 1 };
}

function parseMarkdownLinks(line) {
  const links = [];
  let cursor = 0;
  while ((cursor = line.indexOf('[', cursor)) >= 0) {
    const labelEnd = findUnescaped(line, ']', cursor + 1);
    if (labelEnd < 0 || line[labelEnd + 1] !== '(') { cursor += 1; continue; }
    const targetStart = labelEnd + 2;
    const targetEnd = findUnescaped(line, ')', targetStart);
    if (targetEnd < 0) break;
    links.push({ label: line.slice(cursor + 1, labelEnd), target: line.slice(targetStart, targetEnd) });
    cursor = targetEnd + 1;
  }
  return links;
}

function validOfficialUrl(value) {
  if (!nonEmptyString(value) || hasControlCharacters(value) || !/^https:\/\//i.test(value)) return null;
  try {
    const url = new URL(value);
    return url.protocol === 'https:' && url.hostname ? url : null;
  } catch {
    return null;
  }
}

function checkText(errors, label, field, value) {
  if (typeof value !== 'string') return;
  if (hasControlCharacters(value)) errors.push(`${label}: ${field} contains control characters`);
  if (hasUnpairedSurrogate(value)) errors.push(`${label}: ${field} contains an unpaired UTF-16 surrogate`);
}

function checkDate(errors, label, value, options, field = 'date') {
  if (!validDate(value)) { errors.push(`${label}: invalid ${field}`); return false; }
  if (field === 'date' && !inCoverage(value, options)) errors.push(`${label}: ${field} outside coverage`);
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
    else checkText(localErrors, label, 'organization', record.organization);
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
    else {
      const seenTopics = new Set();
      record.topics.forEach((topic) => {
        if (!TOPICS.includes(topic)) localErrors.push(`${label}: unknown topic: ${topic}`);
        if (seenTopics.has(topic)) localErrors.push(`${label}: duplicate topic: ${topic}`);
        seenTopics.add(topic);
      });
    }
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
  const organizations = sortOrganizations(checked.kept);
  const lines = [
    '# 工程工作流事件市场',
    '',
    `> 覆盖时间：${metadata.start} 至 ${metadata.end}`,
    `> 最后核验日期：${metadata.verifiedAt ?? metadata.end ?? ''}`,
    '> 更新方式：按需手动触发，由受控 JSONL 记录经校验后生成。',
    `> 收录数量：${checked.kept.length}`,
    '> 官方来源规则：每项必须提供经复核的 HTTPS 官方来源。',
    '> 事实与分析：客观事实仅陈述来源支持的信息，技术剖析明确标注分析判断。',
    '',
    '## 主题索引',
    '',
    '同一事件可进入多个主题，计数为索引引用数，不等于唯一事件数。',
    '',
  ];
  for (const topic of TOPICS) lines.push(`- [${escapeMarkdownText(TOPIC_LABELS[topic])}（${checked.summary.topics[topic]}）](#topic-${topic})`);
  for (const topic of TOPICS) {
    const topicRecords = sortRecords(checked.kept.filter((record) => record.topics.includes(topic)));
    lines.push('', `<a id="topic-${topic}"></a>`, `**${escapeMarkdownText(TOPIC_LABELS[topic])}（${topicRecords.length}）**`);
    if (!topicRecords.length) lines.push('- 暂无通过复核的事件。');
    for (const record of topicRecords) lines.push(`- [${topicIndexLabel(record)}](#${eventAnchor(record.id)})`);
    if (topic === 'engineering-docs' && topicRecords.length <= 1) {
      lines.push(`本期工程文档方向仅有 ${topicRecords.length} 项通过官方来源与工程价值复核，未用泛文档 AI 新闻补数。`);
    }
  }
  lines.push(
    '',
    '## 组织导航',
    '',
    ...organizations.map(([organization]) => `- [${escapeMarkdownText(organization)}](#${organizationAnchor(organization)})`),
    '',
    '## 组织归档',
    '',
    '组织按最高优先级、最新事件日期、组织名排序；组内按日期倒序，再按事件 ID 排序。',
  );
  for (const [organization, group] of organizations) {
    lines.push('', `<a id="${organizationAnchor(organization)}"></a>`, `## ${escapeMarkdownText(organization)}`);
    for (const record of group) {
      lines.push(
        '',
        `<a id="${eventAnchor(record.id)}"></a>`,
        `### ${escapeMarkdownText(record.title)}`,
        recordMarker(record),
        '',
        `- 日期：${record.date}`,
        `- 标题：${escapeMarkdownText(record.title)}`,
        `- 优先级：${record.priority}`,
        `- 主题：${TOPICS.filter((topic) => record.topics.includes(topic)).map((topic) => escapeMarkdownText(TOPIC_LABELS[topic])).join('、')}`,
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
  const archiveHeadingIndex = lines.indexOf('## 组织归档');
  const organizationHeadings = [];
  const eventHeadings = [];
  const markerLines = [];
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
    ['官方来源规则', /^> 官方来源规则：.+$/],
    ['事实与分析', /^> 事实与分析：.+$/],
  ];
  for (const [name, pattern] of requiredHeaders) if (!lines.some((line) => pattern.test(line))) errors.push(`missing document header: ${name}`);
  if (!lines.includes('> 更新方式：按需手动触发，由受控 JSONL 记录经校验后生成。')) errors.push('invalid update method header');
  const coverageHeader = lines.find((line) => /^> 覆盖时间：/.test(line));
  if (coverageHeader && options.start && options.end && coverageHeader !== `> 覆盖时间：${options.start} 至 ${options.end}`) errors.push('coverage header does not match requested range');
  const verificationHeader = /^> 最后核验日期：(\d{4}-\d{2}-\d{2})$/.exec(lines.find((line) => /^> 最后核验日期：/.test(line)) ?? '');
  if (!verificationHeader || !validDate(verificationHeader[1])) errors.push('missing or invalid verification-date header');
  else if (options.verifiedAt && verificationHeader[1] !== options.verifiedAt) errors.push('verification-date header does not match requested date');
  const countHeader = /^> 收录数量：(\d+)$/.exec(lines.find((line) => /^> 收录数量：/.test(line)) ?? '');
  if (!countHeader) errors.push('missing document header: 收录数量');
  for (let index = 0; index < lines.length; index += 1) {
    const section = /^##\s+(.+?)\s*$/.exec(lines[index]);
    if (section && index > archiveHeadingIndex && !['主题索引', '组织导航', '组织归档'].includes(section[1])) {
      organization = section[1];
      const precedingAnchor = /^<a id="(organization-[^"]+)"><\/a>$/.exec(lines[index - 1] ?? '')?.[1] ?? null;
      organizationHeadings.push({ label: organization, anchor: precedingAnchor, index });
    } else if (section) {
      organization = null;
    }
    if (/^###\s+/.test(lines[index])) {
      eventHeadings.push({ line: index + 1, title: lines[index].replace(/^###\s+/, '') });
      let markerIndex = index + 1;
      while (markerIndex < lines.length && !lines[markerIndex].trim()) markerIndex += 1;
      if (!lines[markerIndex]?.startsWith('<!-- event-record:')) errors.push(`line ${index + 1}: unmarked event heading`);
    }
    if (!lines[index].startsWith('<!-- event-record:')) continue;
    markerLines.push(index + 1);
    const marker = /^<!-- event-record:(.+) -->$/.exec(lines[index]);
    if (!marker) {
      errors.push(`line ${index + 1}: invalid event-record marker`);
      continue;
    }
    try {
      const record = parseMarkerPayload(marker[1]);
      const label = record.id || `line ${index + 1}`;
      if (!isStableSlug(record.id)) errors.push(`${label}: marker id must be a stable lowercase slug`);
      if (!nonEmptyString(record.organization) || hasControlCharacters(record.organization) || hasUnpairedSurrogate(record.organization)) errors.push(`${label}: marker organization is unsafe`);
      const heading = /^###\s+(.+)$/.exec(lines[index - 1] ?? '');
      if (!heading) errors.push(`${label}: marker must immediately follow an event heading`);
      if (!isStableSlug(record.id) || !nonEmptyString(record.organization) || !heading || !checkDate(errors, label, record.date, options)) {
        continue;
      }
      if (ids.has(record.id)) errors.push(`${record.id}: duplicate event-record marker`);
      ids.add(record.id);
      if (organization !== escapeMarkdownText(record.organization)) errors.push(`${record.id}: marker organization does not match its organization block`);
      if ((anchors.get(eventAnchor(record.id)) ?? []).length !== 1) errors.push(`${record.id}: event anchor must exist exactly once`);
      if (lines[index - 2] !== `<a id="${eventAnchor(record.id)}"></a>`) errors.push(`${record.id}: event anchor must immediately precede its heading`);
      const nextBoundary = lines.findIndex((line, lineIndex) => lineIndex > index && (/^#{2,3}\s+/.test(line) || /^<a id="(?:event-|organization-)/.test(line)));
      const eventLines = lines.slice(index + 1, nextBoundary < 0 ? undefined : nextBoundary);
      const metadataDefinitions = [
        ['日期', '- 日期：'],
        ['标题', '- 标题：'],
        ['优先级', '- 优先级：'],
        ['主题', '- 主题：'],
        ['协作方', '- 协作方：'],
      ];
      const metadataLines = new Map();
      for (const [name, prefix] of metadataDefinitions) {
        const matches = eventLines.filter((line) => line.startsWith(prefix));
        if (matches.length !== 1) errors.push(`${record.id}: must contain exactly one ${name} metadata line`);
        metadataLines.set(name, matches.length === 1 ? matches[0] : null);
      }
      const nonEmptyEventLines = eventLines.filter((line) => line.trim());
      if (metadataDefinitions.some(([, prefix], metadataIndex) => !nonEmptyEventLines[metadataIndex]?.startsWith(prefix))) errors.push(`${record.id}: event metadata lines are not in the required order`);
      if (metadataLines.get('日期') !== `- 日期：${record.date}`) errors.push(`${record.id}: body date does not match marker`);
      if (metadataLines.get('标题') !== `- 标题：${heading[1]}`) errors.push(`${record.id}: body event title is not bound to its marker`);
      const priority = /^- 优先级：(high|medium|low)$/.exec(metadataLines.get('优先级') ?? '')?.[1];
      if (!priority) errors.push(`${record.id}: missing or invalid priority`);
      const bodyTopicDisplay = metadataLines.get('主题')?.slice('- 主题：'.length) ?? null;
      const partnersDisplay = metadataLines.get('协作方')?.slice('- 协作方：'.length) ?? null;
      if (!nonEmptyString(partnersDisplay) || hasControlCharacters(partnersDisplay) || hasUnpairedSurrogate(partnersDisplay) || /[<>]/.test(partnersDisplay)) errors.push(`${record.id}: collaboration metadata is empty or unsafe`);

      const sectionNames = ['客观事实', '技术剖析', '工作流影响', '局限与风险', '后续关注', '官方来源'];
      const sectionHeadings = eventLines
        .map((line, lineIndex) => ({ match: /^####\s+(.+?)\s*$/.exec(line), lineIndex }))
        .filter(({ match }) => match)
        .map(({ match, lineIndex }) => ({ name: match[1], lineIndex }));
      for (const sectionName of sectionNames) {
        if (sectionHeadings.filter(({ name }) => name === sectionName).length !== 1) errors.push(`${record.id}: must contain exactly one ${sectionName} section`);
      }
      if (sectionHeadings.length !== sectionNames.length || sectionHeadings.some(({ name }, sectionIndex) => name !== sectionNames[sectionIndex])) errors.push(`${record.id}: event sections are not in the required order`);
      if (nonEmptyEventLines[metadataDefinitions.length] !== '#### 客观事实') errors.push(`${record.id}: event sections must follow metadata`);
      const sectionContent = (sectionName) => {
        const headingEntry = sectionHeadings.find(({ name }) => name === sectionName);
        if (!headingEntry) return [];
        const nextEntry = sectionHeadings.find(({ lineIndex }) => lineIndex > headingEntry.lineIndex);
        return eventLines.slice(headingEntry.lineIndex + 1, nextEntry?.lineIndex).filter((line) => line.trim());
      };
      for (const sectionName of sectionNames.slice(0, -1)) {
        const content = sectionContent(sectionName);
        if (!content.length || (sectionName === '客观事实' && !content.some((line) => /^-\s+/.test(line)))) errors.push(`${record.id}: missing or empty ${sectionName} section`);
      }
      const sources = sectionContent('官方来源');
      if (!sources.length) errors.push(`${record.id}: missing official source`);
      for (const source of sources) {
        const sourceLink = parseMarkdownLink(source);
        if (!sourceLink || !nonEmptyString(sourceLink.label)) {
          errors.push(`${record.id}: official source section contains unstructured content`);
          continue;
        }
        if (!validOfficialUrl(sourceLink.target)) errors.push(`${record.id}: invalid official source`);
        const sourceMetadata = /^（([^，]+)，复核：([^）]+)）$/.exec(source.slice(sourceLink.end));
        if (!sourceMetadata) {
          errors.push(`${record.id}: official source section contains unstructured content`);
          continue;
        }
        const [, sourceType, sourceVerifiedAt] = sourceMetadata;
        if (!SOURCE_TYPES.includes(sourceType)) errors.push(`${record.id}: invalid official source type: ${sourceType}`);
        if (!validDate(sourceVerifiedAt)) errors.push(`${record.id}: invalid official source verifiedAt: ${sourceVerifiedAt}`);
      }
      records.push({ ...record, bodyTitle: heading[1], bodyTopicDisplay, sectionOrganization: organization, priority, line: index + 1 });
    } catch {
      errors.push(`line ${index + 1}: invalid event-record marker`);
    }
  }
  if (!records.length) errors.push('document contains no event-record markers');
  if (eventHeadings.length !== markerLines.length) errors.push('event headings and marker lines mismatch');
  if (eventHeadings.length !== records.length) errors.push('event headings and valid marker records mismatch');
  if (countHeader && Number(countHeader[1]) !== eventHeadings.length) errors.push('header record count does not match event headings');
  const recordsByAnchor = new Map(records.map((record) => [eventAnchor(record.id), record]));
  for (const topic of TOPICS) {
    if ((anchors.get(`topic-${topic}`) ?? []).length !== 1) errors.push(`missing or duplicate topic anchor: ${topic}`);
  }
  const multiTopicNotice = '同一事件可进入多个主题，计数为索引引用数，不等于唯一事件数。';
  if (!lines.includes(multiTopicNotice)) errors.push('missing multi-topic reference count notice');
  const topicIndexStart = lines.findIndex((line) => line === '## 主题索引');
  const topicIndexEnd = lines.findIndex((line, index) => index > topicIndexStart && /^##\s+/.test(line));
  const topicIndexLines = lines.slice(topicIndexStart + 1, topicIndexEnd < 0 ? undefined : topicIndexEnd);
  const topicReferenceCounts = new Map(records.map((record) => [eventAnchor(record.id), 0]));
  const indexedTopicsByAnchor = new Map(records.map((record) => [eventAnchor(record.id), new Set()]));
  const topicCounts = new Map(TOPICS.map((topic) => [topic, 0]));
  const topicEventReferences = new Set();
  const topicAnchorOrder = [];
  const topicNavigationOrder = [];
  let currentTopic = null;
  for (const line of topicIndexLines) {
    const topicAnchor = /^<a id="topic-([a-z0-9-]+)"><\/a>$/.exec(line);
    if (topicAnchor) {
      currentTopic = TOPICS.includes(topicAnchor[1]) ? topicAnchor[1] : null;
      if (currentTopic) topicAnchorOrder.push(currentTopic);
      continue;
    }
    if (currentTopic && line.startsWith('**')) {
      const expectedPrefix = `**${escapeMarkdownText(TOPIC_LABELS[currentTopic])}（`;
      if (!line.startsWith(expectedPrefix) || !/^\*\*.+（\d+）\*\*$/.test(line)) errors.push(`topic ${currentTopic} is missing its reference count title`);
    }
    if (!line.startsWith('- [')) continue;
    const link = parseMarkdownLink(line);
    if (!link || !link.target.startsWith('#')) {
      errors.push('invalid topic index link');
      continue;
    }
    const anchor = link.target.slice(1);
    if (anchor.startsWith('topic-')) topicNavigationOrder.push(anchor.slice('topic-'.length));
    if ((anchors.get(anchor) ?? []).length !== 1) errors.push(`topic index link ${anchor} does not target exactly one body anchor`);
    const record = recordsByAnchor.get(anchor);
    if (record) {
      topicReferenceCounts.set(anchor, topicReferenceCounts.get(anchor) + 1);
      if (!currentTopic) errors.push(`${record.id}: event link is outside a topic index`);
      else {
        const reference = `${currentTopic}:${anchor}`;
        if (topicEventReferences.has(reference)) errors.push(`${record.id}: duplicate event link in topic ${currentTopic}`);
        topicEventReferences.add(reference);
        topicCounts.set(currentTopic, topicCounts.get(currentTopic) + 1);
        indexedTopicsByAnchor.get(anchor).add(currentTopic);
      }
      if (link.label !== `${record.date}｜${record.bodyTitle}｜${escapeMarkdownText(record.organization)}`) errors.push(`${record.id}: body event title is not bound to its marker`);
    }
  }
  if (topicAnchorOrder.length !== TOPICS.length || topicAnchorOrder.some((topic, index) => topic !== TOPICS[index])) errors.push('topics are not in the required user-role order');
  if (topicNavigationOrder.length !== TOPICS.length || topicNavigationOrder.some((topic, index) => topic !== TOPICS[index])) errors.push('topic navigation entries are not in the required user-role order');
  for (const topic of TOPICS) {
    const count = topicCounts.get(topic);
    const title = `**${escapeMarkdownText(TOPIC_LABELS[topic])}（${count}）**`;
    if (!topicIndexLines.includes(title)) errors.push(`topic ${topic} count does not match index references`);
    const navigation = `- [${escapeMarkdownText(TOPIC_LABELS[topic])}（${count}）](#topic-${topic})`;
    if (!topicIndexLines.includes(navigation)) errors.push(`missing or incorrect topic index entry: ${topic}`);
  }
  const engineeringCount = topicCounts.get('engineering-docs');
  const sparseNoticePattern = /^本期工程文档方向仅有 (\d+) 项通过官方来源与工程价值复核，未用泛文档 AI 新闻补数。$/;
  const sparseNotice = topicIndexLines.find((line) => sparseNoticePattern.test(line));
  if (engineeringCount <= 1 && !sparseNotice) errors.push('missing engineering-docs sparse coverage notice');
  if (sparseNotice && Number(sparseNoticePattern.exec(sparseNotice)[1]) !== engineeringCount) errors.push('engineering-docs sparse coverage notice count does not match index references');
  if (engineeringCount > 1 && sparseNotice) errors.push('engineering-docs sparse coverage notice is forbidden when count exceeds 1');
  for (const [anchor, count] of topicReferenceCounts) if (count < 1) errors.push(`${anchor}: event anchor must be referenced by at least one topic index`);
  for (const record of records) {
    const indexedTopics = indexedTopicsByAnchor.get(eventAnchor(record.id)) ?? new Set();
    const expectedTopicDisplay = TOPICS
      .filter((topic) => indexedTopics.has(topic))
      .map((topic) => escapeMarkdownText(TOPIC_LABELS[topic]))
      .join('、');
    if (record.bodyTopicDisplay !== expectedTopicDisplay) errors.push(`${record.id}: body topics do not match indexed topics`);
  }

  const archiveRule = '组织按最高优先级、最新事件日期、组织名排序；组内按日期倒序，再按事件 ID 排序。';
  if (!lines.includes(archiveRule)) errors.push('missing organization archive sorting rule');
  const navigationStart = lines.indexOf('## 组织导航');
  const archiveStart = lines.indexOf('## 组织归档');
  const navigationLines = navigationStart >= 0 && archiveStart > navigationStart ? lines.slice(navigationStart + 1, archiveStart) : [];
  if (navigationStart < 0 || archiveStart < 0) errors.push('missing organization navigation or archive section');
  const navigationContentLines = navigationLines.filter((line) => line.trim());
  if (navigationContentLines.some((line) => {
    const links = parseMarkdownLinks(line);
    const link = parseMarkdownLink(line);
    return links.length !== 1 || !link || link.end !== line.length;
  })) errors.push('organization navigation must use one bullet per organization');
  const navigationLinks = navigationLines.flatMap(parseMarkdownLinks).filter((link) => link.target.startsWith('#'));
  const navigationNames = new Map();
  for (const link of navigationLinks) {
    navigationNames.set(link.label, (navigationNames.get(link.label) ?? 0) + 1);
    if ((navigationNames.get(link.label) ?? 0) > 1) errors.push(`duplicate organization navigation entry: ${link.label}`);
  }
  const headingCounts = new Map();
  for (const heading of organizationHeadings) {
    headingCounts.set(heading.label, (headingCounts.get(heading.label) ?? 0) + 1);
    if (headingCounts.get(heading.label) > 1) errors.push(`duplicate organization heading: ${heading.label}`);
    const matchingLinks = navigationLinks.filter((link) => link.label === heading.label);
    if (matchingLinks.length !== 1 || !heading.anchor || matchingLinks[0].target !== `#${heading.anchor}`) {
      errors.push(`organization heading ${heading.label} is not bound to a unique navigation entry and anchor`);
    }
  }
  for (const [anchor, positions] of anchors) {
    if (!anchor.startsWith('organization-')) continue;
    for (const position of positions) {
      const heading = /^##\s+(.+?)\s*$/.exec(lines[position] ?? '')?.[1];
      if (!heading || !organizationHeadings.some((entry) => entry.index === position && entry.anchor === anchor)) errors.push(`organization anchor ${anchor} must immediately precede exactly one organization heading`);
    }
  }
  const byOrganization = new Map();
  for (const record of records) byOrganization.set(record.organization, [...(byOrganization.get(record.organization) ?? []), record]);
  for (const name of byOrganization.keys()) {
    const label = escapeMarkdownText(name);
    const expectedAnchor = organizationAnchor(name);
    const matchingLinks = navigationLinks.filter((link) => link.label === label);
    const matchingHeadings = organizationHeadings.filter((heading) => heading.label === label);
    if (!matchingLinks.length) errors.push(`organization navigation is missing ${label}`);
    for (const link of matchingLinks) if (link.target !== `#${expectedAnchor}`) errors.push(`organization navigation link ${link.target.slice(1)} does not target its body organization anchor`);
    if ((anchors.get(expectedAnchor) ?? []).length !== 1) errors.push(`organization ${label}: body anchor must exist exactly once`);
    if (matchingHeadings.length !== 1 || matchingHeadings[0].anchor !== expectedAnchor) errors.push(`organization ${label}: body anchor must immediately precede its unique heading`);
  }
  for (const link of navigationLinks) {
    if (![...byOrganization.keys()].some((name) => escapeMarkdownText(name) === link.label)) errors.push(`organization navigation has unknown entry: ${link.label}`);
  }
  if (navigationLinks.length !== byOrganization.size) errors.push('organization navigation has duplicate or omitted entries');
  for (const [name, group] of byOrganization) {
    const expected = sortRecords(group);
    if (group.some((record, index) => record.id !== expected[index].id)) errors.push(`organization ${name}: records are not sorted by date descending and id`);
  }
  const expectedOrganizations = sortOrganizations(records).map(([name]) => escapeMarkdownText(name));
  const navigationOrganizationOrder = navigationLinks.map((link) => link.label);
  const organizationBlockOrder = organizationHeadings.map((heading) => heading.label);
  if (navigationOrganizationOrder.length !== expectedOrganizations.length || navigationOrganizationOrder.some((name, index) => name !== expectedOrganizations[index])) errors.push('organization navigation order does not match the body');
  if (organizationBlockOrder.length !== navigationOrganizationOrder.length || organizationBlockOrder.some((name, index) => name !== navigationOrganizationOrder[index])) errors.push('organization block order does not match navigation order');
  if (organizationBlockOrder.length !== expectedOrganizations.length || organizationBlockOrder.some((name, index) => name !== expectedOrganizations[index])) errors.push('organizations are not sorted by highest priority, latest date, and name');
  return { errors, records };
}

export async function atomicWrite(output, text, { writeFileImpl = writeFile, renameImpl = rename, rmImpl = rm } = {}) {
  const target = resolve(output);
  const temporary = `${target}.${process.pid}.${randomUUID()}.tmp`;
  try {
    await writeFileImpl(temporary, text, 'utf8');
    await renameImpl(temporary, target);
  } catch (cause) {
    try {
      await rmImpl(temporary, { force: true });
    } catch (cleanupCause) {
      if (cause && typeof cause === 'object') {
        cause.cleanupError = cleanupCause;
        cause.message = `${cause.message}\nTemporary file cleanup failed: ${cleanupCause?.message ?? String(cleanupCause)}`;
      } else {
        throw new AggregateError([cause, cleanupCause], 'Temporary file cleanup failed after atomic write failure');
      }
    }
    throw cause;
  }
}

function isMissingPathError(cause) {
  return cause?.code === 'ENOENT' || cause?.code === 'ENOTDIR';
}

function comparisonPath(path, platform) {
  return platform === 'win32' ? path.toLowerCase() : path;
}

async function fileIdentity(path, { realpathImpl = realpath, statImpl = stat, platform = process.platform } = {}) {
  const absolute = resolve(path);
  try {
    const physical = await realpathImpl(absolute);
    const details = await statImpl(physical);
    return { exists: true, path: comparisonPath(physical, platform), device: details.dev, inode: details.ino };
  } catch (cause) {
    if (!isMissingPathError(cause)) throw cause;
    const physicalParent = await realpathImpl(dirname(absolute));
    return { exists: false, path: comparisonPath(join(physicalParent, basename(absolute)), platform) };
  }
}

async function sameFile(input, output, dependencies) {
  const [source, target] = await Promise.all([fileIdentity(input, dependencies), fileIdentity(output, dependencies)]);
  if (source.path === target.path) return true;
  return source.exists && target.exists && source.device === target.device && source.inode === target.inode;
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
  if (options.command === 'render' && await sameFile(options.input, options.output, dependencies)) throw error('input and output must resolve to different files');
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
