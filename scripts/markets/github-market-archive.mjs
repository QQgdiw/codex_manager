import { randomUUID } from 'node:crypto';
import { readFile, rename, rm, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const REQUIRED_KEEP_FIELDS = ['link', 'projectType', 'weekBasis', 'coreFunction', 'workflow', 'input', 'output', 'deployment', 'risk', 'reason'];
const WEEK = /^(\d{4})-W(0[1-9]|[1-4]\d|5[0-3])$/;

function isWeek(value) { return typeof value === 'string' && WEEK.test(value); }
function key(record) { return String(record.repository ?? '').toLowerCase(); }
function splitRow(line) { return line.split(/(?<!\\)\|/).map((cell) => cell.trim()).filter((_, index, cells) => index > 0 && index < cells.length - 1); }
function error(message) { const result = new Error(message); result.exitCode = 2; return result; }

export function extractLegacyCandidates(markdown) {
  const candidates = [];
  let week = null;
  let starsColumn = -1;
  for (const [index, line] of markdown.split(/\r?\n/).entries()) {
    const heading = /^###\s+(\d{4}-W\d{2})\s*$/.exec(line);
    if (heading) { week = heading[1]; starsColumn = -1; continue; }
    if (!week || !line.startsWith('|') || /^\|\s*-/.test(line)) continue;
    const cells = splitRow(line);
    const headerIndex = cells.findIndex((cell) => cell.toLowerCase() === 'stars');
    if (headerIndex >= 0) { starsColumn = headerIndex; continue; }
    const match = /\[([^\]]+\/[^\]]+)\]\(https:\/\/github\.com\/[^)]+\)/.exec(line);
    if (!match) continue;
    const starCell = starsColumn >= 0 ? cells[starsColumn] : (cells.find((cell) => /^\d[\d,]*$/.test(cell)) ?? cells.find((cell) => /unknown/i.test(cell)));
    const stars = Number(String(starCell ?? '').replace(/,/g, ''));
    if (!Number.isInteger(stars)) throw new Error(`line ${index + 1}: invalid stars`);
    candidates.push({ week, repository: match[1].replace(/\/$/, ''), stars });
  }
  return candidates;
}

export function validateCurationRecords(records) {
  const errors = []; const kept = []; const excluded = []; const first = new Map();
  for (const [index, record] of records.entries()) {
    const label = `record ${index + 1}`;
    if (!record || typeof record !== 'object') { errors.push(`${label}: must be an object`); continue; }
    if (!isWeek(record.week)) errors.push(`${label}: invalid ISO week`);
    if (typeof record.repository !== 'string' || !/^[^/\s]+\/[^/\s]+$/.test(record.repository)) errors.push(`${label}: repository is required`);
    if (record.decision === 'exclude') {
      if (typeof record.exclusionReason !== 'string' || !record.exclusionReason.trim()) errors.push(`${label}: exclusionReason is required`);
      else if (isWeek(record.week) && key(record)) excluded.push(record);
      continue;
    }
    if (record.decision !== 'keep') { errors.push(`${label}: decision must be keep or exclude`); continue; }
    if (!Number.isInteger(record.stars) || record.stars < 1000) errors.push(`${label}: stars must be an integer of at least 1000`);
    if (!['A', 'B', 'C'].includes(record.sourceLevel)) errors.push(`${label}: sourceLevel must be A, B, or C`);
    for (const field of REQUIRED_KEEP_FIELDS) if (typeof record[field] !== 'string' || !record[field].trim()) errors.push(`${label}: ${field} is required`);
    const prior = first.get(key(record));
    if (prior && prior.week !== record.week) errors.push(`${label}: repository duplicates a kept record in ${prior.week}`);
    if (!prior) first.set(key(record), record);
    if (isWeek(record.week) && key(record) && Number.isInteger(record.stars) && record.stars >= 1000 && REQUIRED_KEEP_FIELDS.every((field) => typeof record[field] === 'string' && record[field].trim()) && ['A', 'B', 'C'].includes(record.sourceLevel) && !prior) kept.push(record);
  }
  return { kept, excluded, errors };
}

function marker(record, capturedAt) { return `<!-- github-record:${JSON.stringify({ week: record.week, repository: record.repository, stars: record.stars, capturedAt, sourceLevel: record.sourceLevel })} -->`; }
export function renderGitHubMarketArchive({ records, capturedAt, partialWeeks = [] }) {
  const checked = validateCurationRecords(records); if (checked.errors.length) throw new Error(checked.errors.join('\n'));
  const weeks = [...new Set([...records.map((record) => record.week), ...partialWeeks])].sort().reverse();
  const lines = ['# GitHub 研发项目市场', '', `> 采集与审阅时间：${capturedAt}`, '> 历史候选为近似回溯，不代表对应周的精确 Trending 排名或历史 Star。', ''];
  for (const week of weeks) {
    const all = records.filter((record) => record.week === week); const keep = checked.kept.filter((record) => record.week === week);
    lines.push(`### ${week}`, '', `- 原始候选：${all.length}` , `- 保留：${keep.length}`, `- 排除：${all.filter((record) => record.decision === 'exclude').length}`);
    if (keep.length < 20) lines.push(`- 候选不足：保留 ${keep.length} 条，不降低 Star 门槛补足。`);
    if (partialWeeks.includes(week)) lines.push('- 周次状态：截至采集日的部分周数据。');
    lines.push('');
    for (const record of keep) lines.push(`### ${record.repository}`, marker(record, capturedAt), '', `- 链接：${record.link}`, `- 采集时可见 Star：${record.stars}`, `- 项目属性：${record.projectType}`, `- 周次依据：${record.weekBasis}`, `- 来源等级：${record.sourceLevel}`, `- 核心功能：${record.coreFunction}`, `- 适用工作流：${record.workflow}`, `- 输入：${record.input}`, `- 输出：${record.output}`, `- 部署条件：${record.deployment}`, `- 风险：${record.risk}`, `- 保留理由：${record.reason}`, '');
  }
  return `${lines.join('\n')}\n`;
}

async function atomic(output, text, { writeFileImpl = writeFile, renameImpl = rename, rmImpl = rm } = {}) { const target = resolve(output); const temp = `${target}.${process.pid}.${randomUUID()}.tmp`; try { await writeFileImpl(temp, text, 'utf8'); await renameImpl(temp, target); } catch (cause) { await rmImpl(temp, { force: true }).catch(() => {}); throw cause; } }
function parse(argv) { const [command, ...args] = argv; if (!['extract', 'validate-curation', 'render'].includes(command)) throw error('command must be extract, validate-curation, or render'); const options = { command, partialWeeks: [] }; for (let i = 0; i < args.length; i += 1) { const name = args[i]; const value = args[++i]; if (!value || !['--input', '--output', '--captured-at', '--partial-week'].includes(name)) throw error(`invalid argument: ${name}`); if (name === '--partial-week') options.partialWeeks.push(value); else options[name.slice(2).replace(/-([a-z])/g, (_, c) => c.toUpperCase())] = value; } if (!options.input || (command !== 'validate-curation' && !options.output) || (command === 'render' && !options.capturedAt)) throw error('required argument is missing'); return options; }
export async function runCli(argv = process.argv.slice(2), dependencies = {}) { const options = parse(argv); const content = await (dependencies.readFileImpl ?? readFile)(options.input, 'utf8'); if (options.command === 'extract') return atomic(options.output, `${JSON.stringify(extractLegacyCandidates(content), null, 2)}\n`, dependencies); const records = content.split(/\r?\n/).filter(Boolean).map((line) => JSON.parse(line)); if (options.command === 'validate-curation') { const result = validateCurationRecords(records); if (result.errors.length) throw new Error(result.errors.join('\n')); return result; } return atomic(options.output, renderGitHubMarketArchive({ records, capturedAt: options.capturedAt, partialWeeks: options.partialWeeks }), dependencies); }
if (process.argv[1] && resolve(fileURLToPath(import.meta.url)) === resolve(process.argv[1])) runCli().catch((cause) => { process.stderr.write(`${cause.message}\n`); process.exitCode = cause.exitCode ?? 3; });
