import assert from 'node:assert/strict';
import { link, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import test from 'node:test';

import {
  atomicWrite,
  renderEventMarket,
  runCli,
  validateCurationRecords,
  validateEventDocument,
} from '../../scripts/markets/event-market.mjs';

function runProcess(command, args) {
  return new Promise((resolveProcess, reject) => {
    const child = spawn(command, args, { stdio: 'ignore' });
    child.once('error', reject);
    child.once('close', (code) => resolveProcess(code));
  });
}

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
  assert.match(result.errors.join('\n'), /http-source: officialSources\[0\]\.url must be a valid HTTPS URL/);
  assert.match(result.errors.join('\n'), /bad-topic: unknown topic: unknown/);
  assert.match(result.errors.join('\n'), /bad-source-type: officialSources\[0\]\.type is invalid/);
  assert.match(result.errors.join('\n'), /future: keep records must have occurred: true/);
});

test('allows official source verification after coverage while rejecting invalid calendar dates', () => {
  const afterCoverage = validateCurationRecords([
    validRecord({ officialSources: [{ ...validRecord().officialSources[0], verifiedAt: '2026-07-19' }] }),
  ], coverage);
  assert.deepEqual(afterCoverage.errors, []);

  const invalidCalendarDate = validateCurationRecords([
    validRecord({ officialSources: [{ ...validRecord().officialSources[0], verifiedAt: '2026-02-30' }] }),
  ], coverage);
  assert.match(invalidCalendarDate.errors.join('\n'), /officialSources\[0\]: invalid verifiedAt/);
});

test('allows lightweight exclusions only when they explain the decision', () => {
  const result = validateCurationRecords([
    { id: 'excluded', date: '2026-01-02', organization: 'OpenAI', decision: 'exclude', decisionReason: 'Superseded by a larger release.' },
    { id: 'unexplained', date: '2026-01-03', organization: 'OpenAI', decision: 'exclude', decisionReason: '' },
  ], coverage);

  assert.equal(result.excluded.length, 1);
  assert.match(result.errors.join('\n'), /unexplained: decisionReason is required/);
});

test('rejects duplicate topics and unpaired UTF-16 surrogates in curation records', () => {
  const result = validateCurationRecords([
    validRecord({ id: 'duplicate-topics', mergeKey: 'duplicate-topics', topics: ['coding-agent', 'coding-agent'] }),
    validRecord({ id: 'unsafe-organization', mergeKey: 'unsafe-organization', organization: `Unsafe\uD800` }),
    validRecord({ id: 'replacement-organization', mergeKey: 'replacement-organization', organization: `Unsafe\uFFFD` }),
  ], coverage);

  const errors = result.errors.join('\n');
  assert.match(errors, /duplicate-topics: duplicate topic: coding-agent/);
  assert.match(errors, /unsafe-organization: organization contains an unpaired UTF-16 surrogate/);
  assert.ok(result.kept.some((record) => record.id === 'replacement-organization'));
});

test('renders topic indexes, grouped records, and deterministic organization ordering', () => {
  const markdown = renderEventMarket([
    validRecord({ id: 'z-low', organization: 'Zeta', date: '2026-01-02', priority: 'low', mergeKey: 'z-low', topics: ['embedded-edge'] }),
    validRecord({ id: 'a-medium', organization: 'Alpha', date: '2026-01-03', priority: 'medium', mergeKey: 'a-medium', topics: ['coding-agent', 'engineering-docs'] }),
    validRecord({ id: 'a-high-old', organization: 'Alpha', date: '2026-01-01', priority: 'high', mergeKey: 'a-high-old', topics: ['coding-agent'] }),
    validRecord({ id: 'b-high', organization: 'Beta', date: '2026-01-04', priority: 'high', mergeKey: 'b-high', topics: ['robotics-ros'] }),
  ], { ...coverage, verifiedAt: '2026-07-18' });

  assert.match(markdown, /## 主题索引/);
  assert.match(markdown, /同一事件可进入多个主题，计数为索引引用数，不等于唯一事件数/);
  assert.match(markdown, /\[编码智能体（2）\]\(#topic-coding-agent\)/);
  assert.match(markdown, /\*\*工程文档（1）\*\*/);
  assert.match(markdown, /本期工程文档方向仅有 1 项通过官方来源与工程价值复核，未用泛文档 AI 新闻补数。/);
  const topicOrder = ['机器人与 ROS', '嵌入式与边缘计算', 'EDA、FPGA 与芯片', '工程文档', '编码智能体', '扩展安全'];
  assert.deepEqual(
    [...markdown.matchAll(/^- \[(.+?)（\d+）\]\(#topic-[^)]+\)$/gm)].map((match) => match[1]),
    topicOrder,
  );
  assert.match(markdown, /## 组织导航\n\n- \[Beta\]\(#organization-[^)]+\)\n- \[Alpha\]\(#organization-[^)]+\)\n- \[Zeta\]\(#organization-[^)]+\)/);
  assert.match(markdown, /组织按最高优先级、最新事件日期、组织名排序；组内按日期倒序/);
  for (const organization of ['Beta', 'Alpha', 'Zeta']) {
    const target = new RegExp(`\\[${organization}\\]\\(#(organization-[^)]+)\\)`).exec(markdown)?.[1];
    assert.ok(target, `missing navigation target for ${organization}`);
    assert.match(markdown, new RegExp(`<a id="${target}"></a>\\n## ${organization}`));
  }
  assert.match(markdown, /<!-- event-record:\{"id":"a-medium","date":"2026-01-03","organization":"Alpha"\} -->/);
  assert.ok(markdown.indexOf('## Beta') < markdown.indexOf('## Alpha'));
  assert.ok(markdown.indexOf('## Alpha') < markdown.indexOf('## Zeta'));
  assert.equal((markdown.match(/\[2026-01-03｜Codex workflow update｜Alpha\]\(#event-a-medium\)/g) ?? []).length, 2);
  assert.ok(markdown.indexOf('### Codex workflow update') < markdown.indexOf('### Codex workflow update', markdown.indexOf('### Codex workflow update') + 1));
  assert.match(markdown, /#### 客观事实[\s\S]*#### 技术剖析[\s\S]*#### 工作流影响[\s\S]*#### 局限与风险[\s\S]*#### 后续关注/);
  assert.match(markdown, /https:\/\/example\.com\/official/);
});

test('rejects incorrect topic counts, forged organization navigation, and missing sparse coverage notice', () => {
  const valid = renderEventMarket([
    validRecord({ id: 'multi-topic', organization: 'Alpha', mergeKey: 'multi-topic', topics: ['robotics-ros', 'engineering-docs'] }),
    validRecord({ id: 'second-org', organization: 'Beta', mergeKey: 'second-org', topics: ['embedded-edge'] }),
  ], { ...coverage, verifiedAt: '2026-07-18' });
  assert.deepEqual(validateEventDocument(valid, coverage).errors, []);

  const badCount = valid.replace('**机器人与 ROS（1）**', '**机器人与 ROS（2）**');
  assert.match(validateEventDocument(badCount, coverage).errors.join('\n'), /topic robotics-ros count does not match index references/);

  const alphaTarget = /\[Alpha\]\(#(organization-[^)]+)\)/.exec(valid)[1];
  const betaEntry = /^- \[Beta\]\(#organization-[^)]+\)\n/m.exec(valid)?.[0];
  assert.ok(betaEntry);
  const forged = valid
    .replace(`](#${alphaTarget})`, '](#bogus)')
    .replace(`<a id="${alphaTarget}"></a>`, `<a id="bogus"></a>\n<a id="${alphaTarget}"></a>`);
  assert.match(validateEventDocument(forged, coverage).errors.join('\n'), /organization navigation link bogus does not target its body organization anchor/);

  const missing = valid.replace(betaEntry, '');
  assert.match(validateEventDocument(missing, coverage).errors.join('\n'), /organization navigation is missing Beta/);

  const duplicated = valid.replace(/(- \[Alpha\]\(#[^)]+\)\n)/, '$1$1');
  assert.match(validateEventDocument(duplicated, coverage).errors.join('\n'), /duplicate organization navigation entry: Alpha/);

  const noNotice = valid.replace('本期工程文档方向仅有 1 项通过官方来源与工程价值复核，未用泛文档 AI 新闻补数。\n', '');
  assert.match(validateEventDocument(noNotice, coverage).errors.join('\n'), /missing engineering-docs sparse coverage notice/);
  const wrongNoticeCount = valid.replace('本期工程文档方向仅有 1 项', '本期工程文档方向仅有 0 项');
  assert.match(validateEventDocument(wrongNoticeCount, coverage).errors.join('\n'), /engineering-docs sparse coverage notice count does not match index references/);

  const noMultiTopicNotice = valid.replace('同一事件可进入多个主题，计数为索引引用数，不等于唯一事件数。\n', '');
  assert.match(validateEventDocument(noMultiTopicNotice, coverage).errors.join('\n'), /missing multi-topic reference count notice/);
  const noSortRule = valid.replace('组织按最高优先级、最新事件日期、组织名排序；组内按日期倒序，再按事件 ID 排序。\n', '');
  assert.match(validateEventDocument(noSortRule, coverage).errors.join('\n'), /missing organization archive sorting rule/);

  const roboticsSection = /<a id="topic-robotics-ros"><\/a>[\s\S]*?(?=\n<a id="topic-embedded-edge")/.exec(valid)[0];
  const embeddedSection = /<a id="topic-embedded-edge"><\/a>[\s\S]*?(?=\n<a id="topic-eda-fpga-chip")/.exec(valid)[0];
  const wrongOrder = valid.replace(`${roboticsSection}\n${embeddedSection}`, `${embeddedSection}\n${roboticsSection}`);
  assert.match(validateEventDocument(wrongOrder, coverage).errors.join('\n'), /topics are not in the required user-role order/);
  const wrongTopicNavigationOrder = valid.replace(
    '- [机器人与 ROS（1）](#topic-robotics-ros)\n- [嵌入式与边缘计算（1）](#topic-embedded-edge)',
    '- [嵌入式与边缘计算（1）](#topic-embedded-edge)\n- [机器人与 ROS（1）](#topic-robotics-ros)',
  );
  assert.match(validateEventDocument(wrongTopicNavigationOrder, coverage).errors.join('\n'), /topic navigation entries are not in the required user-role order/);

  const organizationNavigation = /^- \[Alpha\]\(#[^)]+\)\n- \[Beta\]\(#[^)]+\)$/m.exec(valid)[0];
  const [alphaNavigation, betaNavigation] = organizationNavigation.split('\n');
  const wrongOrganizationNavigationOrder = valid.replace(organizationNavigation, `${betaNavigation}\n${alphaNavigation}`);
  assert.match(validateEventDocument(wrongOrganizationNavigationOrder, coverage).errors.join('\n'), /organization navigation order does not match the body/);

  const compressedOrganizationNavigation = valid.replace(organizationNavigation, `${alphaNavigation} · ${betaNavigation.slice(2)}`);
  assert.match(validateEventDocument(compressedOrganizationNavigation, coverage).errors.join('\n'), /organization navigation must use one bullet per organization/);

  const zeroEngineeringDocs = renderEventMarket([
    validRecord({ topics: ['coding-agent'] }),
  ], { ...coverage, verifiedAt: '2026-07-18' });
  assert.match(zeroEngineeringDocs, /本期工程文档方向仅有 0 项通过官方来源与工程价值复核/);
  assert.deepEqual(validateEventDocument(zeroEngineeringDocs, coverage).errors, []);
});

test('binds each body topic list exactly to its topic index memberships', () => {
  const valid = renderEventMarket([
    validRecord({ id: 'topic-contract', organization: 'Alpha', mergeKey: 'topic-contract', topics: ['robotics-ros', 'engineering-docs'] }),
  ], { ...coverage, verifiedAt: '2026-07-18' });
  const eventLink = '- [2026-01-01｜Codex workflow update｜Alpha](#event-topic-contract)';

  const extraIndexTopic = valid
    .replace('[编码智能体（0）](#topic-coding-agent)', '[编码智能体（1）](#topic-coding-agent)')
    .replace('**编码智能体（0）**\n- 暂无通过复核的事件。', `**编码智能体（1）**\n${eventLink}`);
  assert.match(validateEventDocument(extraIndexTopic, coverage).errors.join('\n'), /topic-contract: body topics do not match indexed topics/);

  const missingIndexTopic = valid
    .replace('[工程文档（1）](#topic-engineering-docs)', '[工程文档（0）](#topic-engineering-docs)')
    .replace(`**工程文档（1）**\n${eventLink}\n本期工程文档方向仅有 1 项`, '**工程文档（0）**\n- 暂无通过复核的事件。\n本期工程文档方向仅有 0 项');
  assert.match(validateEventDocument(missingIndexTopic, coverage).errors.join('\n'), /topic-contract: body topics do not match indexed topics/);

  const unknownBodyTopic = valid.replace('- 主题：机器人与 ROS、工程文档', '- 主题：机器人与 ROS、未知主题');
  assert.match(validateEventDocument(unknownBodyTopic, coverage).errors.join('\n'), /topic-contract: body topics do not match indexed topics/);

  const duplicateBodyTopic = valid.replace('- 主题：机器人与 ROS、工程文档', '- 主题：机器人与 ROS、机器人与 ROS');
  assert.match(validateEventDocument(duplicateBodyTopic, coverage).errors.join('\n'), /topic-contract: body topics do not match indexed topics/);
});

test('treats topic labels containing the Chinese list delimiter as atomic display names', () => {
  const single = renderEventMarket([
    validRecord({ id: 'eda-only', mergeKey: 'eda-only', topics: ['eda-fpga-chip'] }),
  ], { ...coverage, verifiedAt: '2026-07-18' });
  assert.match(single, /- 主题：EDA、FPGA 与芯片/);
  assert.deepEqual(validateEventDocument(single, coverage).errors, []);

  const combined = renderEventMarket([
    validRecord({ id: 'eda-combined', mergeKey: 'eda-combined', topics: ['coding-agent', 'eda-fpga-chip'] }),
  ], { ...coverage, verifiedAt: '2026-07-18' });
  assert.match(combined, /- 主题：EDA、FPGA 与芯片、编码智能体/);
  assert.deepEqual(validateEventDocument(combined, coverage).errors, []);
});

test('strictly binds organization anchors, headings, markers, and navigation order', () => {
  const valid = renderEventMarket([
    validRecord({ id: 'alpha-event', organization: 'Alpha', mergeKey: 'alpha-event' }),
    validRecord({ id: 'beta-event', organization: 'Beta', priority: 'medium', mergeKey: 'beta-event' }),
  ], { ...coverage, verifiedAt: '2026-07-18' });
  const firstOrganizationAnchor = valid.indexOf('<a id="organization-');

  const placeholder = `${valid.slice(0, firstOrganizationAnchor)}## Placeholder\n\n${valid.slice(firstOrganizationAnchor)}`;
  assert.match(validateEventDocument(placeholder, coverage).errors.join('\n'), /organization heading Placeholder is not bound to a unique navigation entry and anchor/);

  const duplicateHeading = `${valid.slice(0, firstOrganizationAnchor)}## Alpha\n\n${valid.slice(firstOrganizationAnchor)}`;
  assert.match(validateEventDocument(duplicateHeading, coverage).errors.join('\n'), /duplicate organization heading: Alpha/);

  const alphaStart = valid.indexOf('<a id="organization-', firstOrganizationAnchor);
  const betaStart = valid.indexOf('<a id="organization-', alphaStart + 1);
  const reorderedBlocks = `${valid.slice(0, alphaStart)}${valid.slice(betaStart)}${valid.slice(alphaStart, betaStart)}`;
  assert.match(validateEventDocument(reorderedBlocks, coverage).errors.join('\n'), /organization block order does not match navigation order/);

  const mismatchedMarker = valid.replace(
    '<!-- event-record:{"id":"alpha-event","date":"2026-01-01","organization":"Alpha"} -->',
    '<!-- event-record:{"id":"alpha-event","date":"2026-01-01","organization":"Beta"} -->',
  );
  assert.match(validateEventDocument(mismatchedMarker, coverage).errors.join('\n'), /alpha-event: marker organization does not match its organization block/);
});

test('rejects a sparse engineering-docs notice when the topic has more than one reference', () => {
  const valid = renderEventMarket([
    validRecord({ id: 'docs-one', mergeKey: 'docs-one', topics: ['engineering-docs'] }),
    validRecord({ id: 'docs-two', date: '2026-01-02', mergeKey: 'docs-two', topics: ['engineering-docs'] }),
  ], { ...coverage, verifiedAt: '2026-07-18' });
  assert.doesNotMatch(valid, /本期工程文档方向仅有/);

  const staleNotice = valid.replace('**工程文档（2）**', '**工程文档（2）**\n本期工程文档方向仅有 2 项通过官方来源与工程价值复核，未用泛文档 AI 新闻补数。');
  assert.match(validateEventDocument(staleNotice, coverage).errors.join('\n'), /engineering-docs sparse coverage notice is forbidden when count exceeds 1/);
});

test('validates document markers, ordering, and rejects unmarked human event headings', () => {
  const valid = renderEventMarket([
    validRecord({ id: 'newer', date: '2026-01-02', mergeKey: 'newer' }),
    validRecord({ id: 'older', date: '2026-01-01', mergeKey: 'older' }),
  ], { ...coverage, verifiedAt: '2026-07-18' });
  assert.deepEqual(validateEventDocument(valid, coverage).errors, []);

  const unordered = valid.replace(/<!-- event-record:\{"id":"newer","date":"2026-01-02","organization":"OpenAI"\} -->/, '<!-- event-record:{"id":"newer","date":"2026-01-00","organization":"OpenAI"} -->');
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

test('rejects unsafe JSONL fields and malformed official URLs before rendering', () => {
  const result = validateCurationRecords([
    validRecord({ id: 'Not-A-Slug', mergeKey: 'bad-id' }),
    validRecord({ id: 'marker-injection', organization: 'OpenAI --> <!-- injected', mergeKey: 'marker-injection' }),
    validRecord({ id: 'control-injection', title: 'line\nbreak', mergeKey: 'control-injection' }),
    validRecord({ id: 'url-no-host', officialSources: [{ ...validRecord().officialSources[0], url: 'https:' }], mergeKey: 'url-no-host' }),
    validRecord({ id: 'url-control', officialSources: [{ ...validRecord().officialSources[0], url: 'https://example.com/\nattack' }], mergeKey: 'url-control' }),
  ], coverage);

  const errors = result.errors.join('\n');
  assert.match(errors, /Not-A-Slug: id must be a stable lowercase slug/);
  assert.doesNotMatch(errors, /marker-injection: organization contains unsafe marker text/);
  assert.match(errors, /control-injection: title contains control characters/);
  assert.match(errors, /url-no-host: officialSources\[0\]\.url must be a valid HTTPS URL/);
  assert.match(errors, /url-control: officialSources\[0\]\.url must be a valid HTTPS URL/);
});

test('escapes Markdown text, uses non-colliding anchors, and renders normalized URL targets', () => {
  const markdown = renderEventMarket([
    validRecord({ id: 'event-one', title: 'Title [x] *bold*', organization: 'A & B', mergeKey: 'event-one', officialSources: [{ ...validRecord().officialSources[0], url: 'https://example.com/a(b)' }] }),
    validRecord({ id: 'event-two', title: 'Other', mergeKey: 'event-two' }),
  ], { ...coverage, verifiedAt: '2026-07-18' });

  assert.match(markdown, /<a id="event-event-one"><\/a>/);
  assert.match(markdown, /<a id="event-event-two"><\/a>/);
  assert.ok(markdown.includes('Title \\[x\\] \\*bold\\*'));
  assert.match(markdown, /\[Official announcement\]\(<https:\/\/example\.com\/a\(b\)>\)/);
  assert.deepEqual(validateEventDocument(markdown, coverage).errors, []);
});

test('keeps physical JSONL line numbers and rejects resolved identical paths', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'event-market-'));
  const input = join(directory, 'curation.jsonl');
  try {
    await writeFile(input, `\n${JSON.stringify(validRecord())}\n{invalid}\n`, 'utf8');
    await assert.rejects(
      () => runCli(['validate-curation', '--input', input, '--start', coverage.start, '--end', coverage.end]),
      /line 3: invalid JSON/,
    );
    await assert.rejects(
      () => runCli(['render', '--input', input, '--output', resolve(input), '--start', coverage.start, '--end', coverage.end, '--verified-at', '2026-07-18']),
      /input and output must resolve to different files/,
    );
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test('sorts unordered records with a locale-independent code-point comparator', () => {
  const markdown = renderEventMarket([
    validRecord({ id: 'z-event', organization: 'Zulu', date: '2026-01-01', mergeKey: 'z-event' }),
    validRecord({ id: 'a-event', organization: 'Alpha', date: '2026-01-01', mergeKey: 'a-event' }),
  ], { ...coverage, verifiedAt: '2026-07-18' });
  assert.ok(markdown.indexOf('## Alpha') < markdown.indexOf('## Zulu'));
});

test('validates header metadata, topic links, unique anchors, and every event block', () => {
  const valid = renderEventMarket([validRecord()], { ...coverage, verifiedAt: '2026-07-18' });
  assert.deepEqual(validateEventDocument(valid, coverage).errors, []);

  const invalid = valid
    .replace('> 收录数量：1', '> 收录数量：0')
    .replace('](#event-openai-codex-workflow-2026)', '](#event-missing)')
    .replace('<a id="event-openai-codex-workflow-2026"></a>', '<a id="event-openai-codex-workflow-2026"></a>\n<a id="event-openai-codex-workflow-2026"></a>')
    .replace(/#### 官方来源\n[^\n]+/, '#### 官方来源')
    .replace(/#### 技术剖析\n[^\n]+/, '#### 技术剖析');
  const errors = validateEventDocument(invalid, coverage).errors.join('\n');
  assert.match(errors, /header record count does not match event headings/);
  assert.match(errors, /duplicate anchor: event-openai-codex-workflow-2026/);
  assert.match(errors, /topic index link .* does not target exactly one body anchor/);
  assert.match(errors, /missing or empty 技术剖析 section/);
  assert.match(errors, /missing official source/);
});

test('requires unique ordered event metadata, content sections, and structured official sources', () => {
  const valid = renderEventMarket([validRecord()], { ...coverage, verifiedAt: '2026-07-18' });

  const missingPartners = valid.replace('- 协作方：无\n', '');
  assert.match(validateEventDocument(missingPartners, coverage).errors.join('\n'), /must contain exactly one 协作方 metadata line/);

  const wrongMetadataOrder = valid.replace('- 优先级：high\n- 主题：编码智能体', '- 主题：编码智能体\n- 优先级：high');
  assert.match(validateEventDocument(wrongMetadataOrder, coverage).errors.join('\n'), /event metadata lines are not in the required order/);

  const thirdPartyType = valid.replace('（official-announcement，复核：2026-07-18）', '（third-party-blog，复核：2026-07-18）');
  assert.match(validateEventDocument(thirdPartyType, coverage).errors.join('\n'), /invalid official source type: third-party-blog/);

  const invalidSourceDate = valid.replace('（official-announcement，复核：2026-07-18）', '（official-announcement，复核：2099-99-99）');
  assert.match(validateEventDocument(invalidSourceDate, coverage).errors.join('\n'), /invalid official source verifiedAt: 2099-99-99/);

  const duplicateFacts = valid.replace('#### 技术剖析', '#### 客观事实\n- Duplicate fact.\n\n#### 技术剖析');
  assert.match(validateEventDocument(duplicateFacts, coverage).errors.join('\n'), /must contain exactly one 客观事实 section/);

  const unstructuredSourceText = valid.replace('#### 官方来源\n', '#### 官方来源\nUnstructured source text\n');
  assert.match(validateEventDocument(unstructuredSourceText, coverage).errors.join('\n'), /official source section contains unstructured content/);
});

test('rejects actual unordered event blocks', () => {
  const valid = renderEventMarket([
    validRecord({ id: 'newer', date: '2026-01-02', mergeKey: 'newer' }),
    validRecord({ id: 'older', date: '2026-01-01', mergeKey: 'older' }),
  ], { ...coverage, verifiedAt: '2026-07-18' });
  const newerStart = valid.indexOf('<a id="event-newer"></a>');
  const olderStart = valid.indexOf('<a id="event-older"></a>');
  const newerBlock = valid.slice(newerStart, olderStart);
  const olderBlock = valid.slice(olderStart);
  const unordered = `${valid.slice(0, newerStart)}${olderBlock}${newerBlock}`;
  assert.match(validateEventDocument(unordered, coverage).errors.join('\n'), /records are not sorted by date descending and id/);
});

test('cleans temporary files and preserves the old document when injected writes or renames fail', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'event-market-'));
  const output = join(directory, 'event_market.md');
  const removed = [];
  try {
    await writeFile(output, 'previous document\n', 'utf8');
    await assert.rejects(() => atomicWrite(output, 'new', {
      writeFileImpl: async (temporary) => { throw new Error(`write failed: ${temporary}`); },
      rmImpl: async (temporary) => { removed.push(temporary); },
    }), /write failed/);
    await assert.rejects(() => atomicWrite(output, 'new', {
      writeFileImpl: writeFile,
      renameImpl: async () => { throw new Error('rename failed'); },
      rmImpl: async (temporary) => { removed.push(temporary); await rm(temporary, { force: true }); },
    }), /rename failed/);
    assert.equal(await readFile(output, 'utf8'), 'previous document\n');
    assert.equal(removed.length, 2);
    for (const temporary of removed) await assert.rejects(() => readFile(temporary, 'utf8'));
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test('CLI process returns exit code 2 for invalid JSONL', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'event-market-'));
  const input = join(directory, 'curation.jsonl');
  try {
    await writeFile(input, '{invalid}\n', 'utf8');
    const code = await runProcess(process.execPath, [
      resolve('scripts/markets/event-market.mjs'), 'validate-curation', '--input', input, '--start', coverage.start, '--end', coverage.end,
    ]);
    assert.equal(code, 2);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test('uses the fixed JSON marker contract and Unicode-escapes HTML comment boundaries', () => {
  const organization = 'OpenAI --!> --> <script>&';
  const markdown = renderEventMarket([validRecord({ organization, mergeKey: 'boundary-marker' })], { ...coverage, verifiedAt: '2026-07-18' });

  assert.match(markdown, /<!-- event-record:\{"id":"openai-codex-workflow-2026","date":"2026-01-01","organization":"OpenAI --!\\u003e --\\u003e \\u003cscript\\u003e\\u0026"\} -->/);
  assert.deepEqual(validateEventDocument(markdown, coverage).errors, []);
});

test('escapes standalone fence and block syntax in rendered Markdown fields', () => {
  const markdown = renderEventMarket([validRecord({
    id: 'fenced-content', mergeKey: 'fenced-content', analysis: '   ~~~', workflowImpact: '   ---', limitations: '   ```', followUp: '   - list item',
  })], { ...coverage, verifiedAt: '2026-07-18' });

  assert.match(markdown, /\n   \\~~~\n/);
  assert.match(markdown, /\n   \\---\n/);
  assert.ok(markdown.includes('   \\`\\`\\`'));
  assert.match(markdown, /\n   \\- list item\n/);
  assert.deepEqual(validateEventDocument(markdown, coverage).errors, []);
});

test('rejects malformed, expanded, and mismatched event markers instead of skipping them', () => {
  const valid = renderEventMarket([validRecord()], { ...coverage, verifiedAt: '2026-07-18' });
  const malformed = valid.replace(/<!-- event-record:.+ -->/, '<!-- event-record:{"id":"openai-codex-workflow-2026" --!>');
  const expanded = valid.replace(/<!-- event-record:.+ -->/, '<!-- event-record:{"id":"openai-codex-workflow-2026","date":"2026-01-01","organization":"OpenAI","title":"forbidden"} -->');
  const changedTitle = valid.replace('### Codex workflow update', '### Tampered title');
  const changedCount = valid.replace('> 收录数量：1', '> 收录数量：2');

  assert.match(validateEventDocument(malformed, coverage).errors.join('\n'), /invalid event-record marker[\s\S]*event headings and valid marker records mismatch/);
  assert.match(validateEventDocument(expanded, coverage).errors.join('\n'), /invalid event-record marker[\s\S]*valid marker records mismatch/);
  assert.match(validateEventDocument(changedTitle, coverage).errors.join('\n'), /body event title is not bound to its marker/);
  assert.match(validateEventDocument(changedCount, coverage).errors.join('\n'), /header record count does not match event headings/);
});

test('requires every event anchor exactly once in the topic index and binds body titles without it', () => {
  const valid = renderEventMarket([validRecord()], { ...coverage, verifiedAt: '2026-07-18' });
  const topicLink = '- [2026-01-01｜Codex workflow update｜OpenAI](#event-openai-codex-workflow-2026)';
  const missingAndTampered = valid
    .replace('### Codex workflow update', '### Tampered title')
    .replace(`${topicLink}\n`, '');
  const duplicate = valid.replace(topicLink, `${topicLink}\n${topicLink}`);

  const missingErrors = validateEventDocument(missingAndTampered, coverage).errors.join('\n');
  assert.match(missingErrors, /body event title is not bound to its marker/);
  assert.match(missingErrors, /event anchor must be referenced by at least one topic index/);
  assert.match(validateEventDocument(duplicate, coverage).errors.join('\n'), /duplicate event link in topic coding-agent/);
});

test('rejects input and output aliases by case, symlink, and hardlink identity', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'event-market-'));
  const input = join(directory, 'curation.jsonl');
  const hardlink = join(directory, 'hardlink.jsonl');
  const renderArgs = (source, output) => ['render', '--input', source, '--output', output, '--start', coverage.start, '--end', coverage.end, '--verified-at', '2026-07-18'];
  const aliases = (realpathImpl, statImpl) => ({ platform: 'win32', realpathImpl, statImpl, readFileImpl: async () => { throw new Error('read must not run'); } });
  try {
    await writeFile(input, `${JSON.stringify(validRecord())}\n`, 'utf8');
    await link(input, hardlink);
    await assert.rejects(() => runCli(renderArgs(input, hardlink)), /input and output must resolve to different files/);

    await assert.rejects(() => runCli(renderArgs(input, input.toUpperCase()), aliases(async (value) => value, async () => ({ dev: 1, ino: 1 }))), /input and output must resolve to different files/);
    await assert.rejects(() => runCli(renderArgs(join(directory, 'symlink-input'), join(directory, 'symlink-output')), aliases(async () => join(directory, 'target'), async () => ({ dev: 1, ino: 2 }))), /input and output must resolve to different files/);
    await assert.rejects(() => runCli(renderArgs(join(directory, 'hard-input'), join(directory, 'hard-output')), aliases(async (value) => value, async () => ({ dev: 3, ino: 4 }))), /input and output must resolve to different files/);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test('requires exact manual-update and verification-date headers plus complete topic index entries', () => {
  const valid = renderEventMarket([validRecord()], { ...coverage, verifiedAt: '2026-07-18' });
  assert.match(valid, /> 更新方式：按需手动触发/);
  assert.match(valid, /> 最后核验日期：2026-07-18/);
  assert.match(valid, /\[2026-01-01｜Codex workflow update｜OpenAI\]\(#event-openai-codex-workflow-2026\)/);

  const invalid = valid
    .replace('> 更新方式：按需手动触发，由受控 JSONL 记录经校验后生成。', '> 更新方式：完全自动定时更新。')
    .replace('> 最后核验日期：2026-07-18', '> 最后核验日期：2026-07-17')
    .replace('](#event-openai-codex-workflow-2026)', '](#bogus)');
  const errors = validateEventDocument(invalid, { ...coverage, verifiedAt: '2026-07-18' }).errors.join('\n');
  assert.match(errors, /invalid update method header/);
  assert.match(errors, /verification-date header does not match requested date/);
  assert.match(errors, /topic index link bogus does not target exactly one body anchor/);
});

test('validates official source links with labels containing escaped closing brackets', () => {
  const markdown = renderEventMarket([validRecord({
    id: 'source-label', mergeKey: 'source-label', officialSources: [{ ...validRecord().officialSources[0], label: 'Official ] release' }],
  })], { ...coverage, verifiedAt: '2026-07-18' });

  assert.match(markdown, /Official \\] release/);
  assert.deepEqual(validateEventDocument(markdown, coverage).errors, []);
});

test('cleans partial temporary files and reports cleanup failure with the original error', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'event-market-'));
  const output = join(directory, 'event_market.md');
  let partialTemporary = '';
  try {
    await assert.rejects(() => atomicWrite(output, 'new', {
      writeFileImpl: async (temporary) => { partialTemporary = temporary; await writeFile(temporary, 'partial', 'utf8'); throw new Error('write failed after partial file'); },
    }), /write failed after partial file/);
    await assert.rejects(() => readFile(partialTemporary, 'utf8'));
    await assert.rejects(() => atomicWrite(output, 'new', {
      writeFileImpl: async () => { throw new Error('primary write failure'); },
      rmImpl: async () => { throw new Error('cleanup failure'); },
    }), /primary write failure[\s\S]*cleanup failure/);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});
