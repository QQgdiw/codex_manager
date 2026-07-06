import { execFile } from "node:child_process";
import { readdir, readFile, writeFile, realpath } from "node:fs/promises";
import { resolve } from "node:path";
import process from "node:process";
import { promisify } from "node:util";
import { pathToFileURL } from "node:url";

const execFileAsync = promisify(execFile);
const CLEANUP_TIMEOUT_MS = 5000;
const POLL_INTERVAL_MS = 25;
const MAX_TIMEOUT_SECONDS = Math.floor(2_147_483_647 / 1000);

class SmokeFailure extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

function withTimeout(promise, seconds, label) {
  let timer;
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(
      () => reject(new SmokeFailure("mcp_smoke_timeout", `${label} timed out`)),
      seconds * 1000,
    );
  });
  return Promise.race([promise, timeout]).finally(() => clearTimeout(timer));
}

function processExists(pid) {
  if (!pid) return false;
  try {
    process.kill(pid, 0);
    return true;
  } catch (error) {
    return error.code !== "ESRCH";
  }
}

function delay(milliseconds) {
  return new Promise((resolveDelay) => setTimeout(resolveDelay, milliseconds));
}

function validateRequest(request) {
  const requiredStrings = ["sdkClientPath", "sdkStdioPath", "command", "toolName"];
  const valid =
    request !== null &&
    typeof request === "object" &&
    !Array.isArray(request) &&
    requiredStrings.every(
      (field) => typeof request[field] === "string" && request[field].trim().length > 0,
    ) &&
    Array.isArray(request.args) &&
    request.args.every((argument) => typeof argument === "string") &&
    (request.cwd === undefined ||
      (typeof request.cwd === "string" && request.cwd.trim().length > 0)) &&
    request.arguments !== null &&
    typeof request.arguments === "object" &&
    !Array.isArray(request.arguments) &&
    Number.isInteger(request.timeoutSeconds) &&
    request.timeoutSeconds > 0 &&
    request.timeoutSeconds <= MAX_TIMEOUT_SECONDS;
  if (!valid) {
    throw new SmokeFailure("mcp_smoke_invalid_request", "Invalid MCP smoke request.");
  }
}

export async function waitForProcessesToExit(pids, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  let residual = pids.filter(processExists);
  while (residual.length > 0 && Date.now() < deadline) {
    await delay(Math.min(POLL_INTERVAL_MS, Math.max(1, deadline - Date.now())));
    residual = pids.filter(processExists);
  }
  return residual;
}

const WINDOWS_PROCESS_SNAPSHOT = [
  "-NoProfile",
  "-NonInteractive",
  "-Command",
  "$ErrorActionPreference='Stop'; Get-CimInstance Win32_Process | Select-Object ProcessId,ParentProcessId,@{Name='CreationDate';Expression={$_.CreationDate.ToUniversalTime().ToString('o')}} | ConvertTo-Json -Compress",
];

export function nativeProcessCommands(platform, pid) {
  if (platform === "win32") {
    return {
      snapshot: { command: "powershell.exe", args: WINDOWS_PROCESS_SNAPSHOT },
      terminate: {
        command: "taskkill.exe",
        args: ["/PID", String(pid), "/F"],
      },
    };
  }
  return {
    snapshot: { command: "ps", args: ["-eo", "pid=,ppid="] },
    terminate: null,
  };
}

async function runNativeCommand(spec) {
  try {
    return await execFileAsync(spec.command, spec.args, {
      encoding: "utf8",
      maxBuffer: 1024 * 1024,
      timeout: CLEANUP_TIMEOUT_MS,
      windowsHide: true,
    });
  } catch {
    throw new SmokeFailure(
      "mcp_smoke_cleanup_failed",
      "MCP server process cleanup could not be verified.",
    );
  }
}

function parseProcessRows(platform, stdout) {
  if (platform === "win32") {
    const parsed = JSON.parse(stdout || "[]");
    return (Array.isArray(parsed) ? parsed : [parsed]).map((row) => ({
      pid: Number(row.ProcessId),
      parentPid: Number(row.ParentProcessId),
      startedAt: String(row.CreationDate ?? ""),
    }));
  }
  return stdout
    .split(/\r?\n/u)
    .map((line) => line.trim().match(/^(\d+)\s+(\d+)(?:\s+(.+))?$/u))
    .filter(Boolean)
    .map((match) => ({
      pid: Number(match[1]),
      parentPid: Number(match[2]),
      startedAt: match[3]?.trim() ?? null,
      startTick: null,
    }));
}

function parseLinuxProcStat(stat) {
  const openParen = stat.indexOf("(");
  const closeParen = stat.lastIndexOf(")");
  if (openParen < 0 || closeParen < openParen) return null;
  const pid = Number(stat.slice(0, openParen).trim());
  const fields = stat.slice(closeParen + 1).trim().split(/\s+/u);
  const parentPid = Number(fields[1]);
  const startTick = fields[19];
  if (!Number.isInteger(pid) || !Number.isInteger(parentPid) || !startTick) return null;
  return { pid, parentPid, startedAt: null, startTick };
}

async function snapshotLinuxProcRows(procRoot = "/proc") {
  const entries = await readdir(procRoot, { withFileTypes: true });
  const rows = await Promise.all(
    entries
      .filter((entry) => entry.isDirectory() && /^\d+$/u.test(entry.name))
      .map(async (entry) => {
        try {
          return parseLinuxProcStat(await readFile(procRoot + "/" + entry.name + "/stat", "utf8"));
        } catch {
          return null;
        }
      }),
  );
  return rows.filter(Boolean);
}

function collectProcessTree(rootPid, rows) {
  const rowsByPid = new Map(rows.map((row) => [row.pid, row]));
  const root = rowsByPid.get(rootPid);
  if (!root) return [];
  const childrenByParent = new Map();
  for (const row of rows) {
    const children = childrenByParent.get(row.parentPid) ?? [];
    children.push(row);
    childrenByParent.set(row.parentPid, children);
  }
  const tree = [];
  const pending = [root];
  while (pending.length > 0) {
    const processInfo = pending.shift();
    if (tree.some((entry) => entry.pid === processInfo.pid)) continue;
    tree.push(processInfo);
    pending.push(...(childrenByParent.get(processInfo.pid) ?? []));
  }
  return tree;
}

async function snapshotProcessRows(platform = process.platform, dependencies = {}) {
  if (dependencies.snapshotProcessRows) return dependencies.snapshotProcessRows(platform);
  if (platform === "linux") {
    try {
      return await snapshotLinuxProcRows();
    } catch {
      // Fall through to the portable topology snapshot. Without startTick it is not killable.
    }
  }
  const commands = nativeProcessCommands(platform);
  const { stdout } = await runNativeCommand(commands.snapshot);
  return parseProcessRows(platform, stdout);
}

function normalizeProcessInfo(processInfo) {
  if (typeof processInfo === "number") {
    return { pid: processInfo, parentPid: null, startedAt: null };
  }
  return {
    pid: Number(processInfo?.pid),
    parentPid: Number(processInfo?.parentPid),
    startedAt:
      typeof processInfo?.startedAt === "string" && processInfo.startedAt.length > 0
        ? processInfo.startedAt
        : null,
    startTick:
      typeof processInfo?.startTick === "string" && processInfo.startTick.length > 0
        ? processInfo.startTick
        : null,
  };
}

function hasVerifiableIdentity(processInfo, platform) {
  if (!Number.isInteger(processInfo.pid) || processInfo.pid <= 0) return false;
  if (platform === "win32") return processInfo.startedAt !== null;
  return processInfo.startTick !== null;
}

function identityMatches(expected, actual, platform) {
  const normalizedActual = normalizeProcessInfo(actual);
  if (Number(expected.pid) !== Number(normalizedActual.pid)) return false;
  if (platform === "win32") return expected.startedAt === normalizedActual.startedAt;
  return expected.startTick === normalizedActual.startTick;
}

function processIdentityKey(processInfo) {
  return (
    String(processInfo.pid) +
    ":" +
    (processInfo.startedAt ?? "") +
    ":" +
    (processInfo.startTick ?? "")
  );
}

function uniqueProcessInfos(processInfos) {
  const byIdentity = new Map();
  for (const processInfo of processInfos.map(normalizeProcessInfo)) {
    if (!Number.isInteger(processInfo.pid) || processInfo.pid <= 0) continue;
    byIdentity.set(processIdentityKey(processInfo), processInfo);
  }
  return [...byIdentity.values()];
}

function mergeProcessTrees(...trees) {
  return uniqueProcessInfos(trees.flat());
}

async function currentMatchingProcess(processInfo, platform, dependencies) {
  const expected = normalizeProcessInfo(processInfo);
  const exists = dependencies.processExists ?? processExists;
  if (!exists(expected.pid)) return null;
  if (!hasVerifiableIdentity(expected, platform)) {
    throw new SmokeFailure(
      "mcp_smoke_cleanup_failed",
      "MCP server process cleanup could not be verified.",
    );
  }
  const rows = await snapshotProcessRows(platform, dependencies);
  const current = rows.find((row) => row.pid === expected.pid);
  if (!current) {
    if (exists(expected.pid)) {
      throw new SmokeFailure(
        "mcp_smoke_cleanup_failed",
        "MCP server process cleanup could not be verified.",
      );
    }
    return null;
  }
  if (!hasVerifiableIdentity(normalizeProcessInfo(current), platform)) {
    throw new SmokeFailure(
      "mcp_smoke_cleanup_failed",
      "MCP server process cleanup could not be verified.",
    );
  }
  return identityMatches(expected, current, platform) ? current : null;
}

async function matchingResidualProcesses(processInfos, platform, dependencies) {
  const residual = [];
  for (const processInfo of processInfos) {
    const current = await currentMatchingProcess(processInfo, platform, dependencies);
    if (current) residual.push(normalizeProcessInfo(processInfo));
  }
  return residual;
}

async function waitForProcessIdentitiesToExit(processInfos, timeoutMs, platform, dependencies) {
  const deadline = Date.now() + timeoutMs;
  let residual = await matchingResidualProcesses(processInfos, platform, dependencies);
  while (residual.length > 0 && Date.now() < deadline) {
    await delay(Math.min(POLL_INTERVAL_MS, Math.max(1, deadline - Date.now())));
    residual = await matchingResidualProcesses(processInfos, platform, dependencies);
  }
  return residual;
}

async function snapshotProcessTree(rootPid, platform = process.platform, dependencies = {}) {
  try {
    return collectProcessTree(rootPid, await snapshotProcessRows(platform, dependencies));
  } catch (error) {
    if (error instanceof SmokeFailure) throw error;
    throw new SmokeFailure(
      "mcp_smoke_cleanup_failed",
      "MCP server process cleanup could not be verified.",
    );
  }
}

async function terminateProcess(pid, platform = process.platform, dependencies = {}) {
  const exists = dependencies.processExists ?? processExists;
  if (!exists(pid)) return;
  if (dependencies.terminatePid) {
    await dependencies.terminatePid(pid, platform);
    return;
  }
  if (platform === "win32") {
    const command = nativeProcessCommands(platform, pid).terminate;
    try {
      await runNativeCommand(command);
    } catch (error) {
      if (exists(pid)) throw error;
    }
    return;
  }
  try {
    process.kill(pid, "SIGTERM");
  } catch (error) {
    if (error.code !== "ESRCH") {
      throw new SmokeFailure(
        "mcp_smoke_cleanup_failed",
        "MCP server process cleanup could not be verified.",
      );
    }
  }
}

async function forceTerminateProcess(pid, platform = process.platform, dependencies = {}) {
  if (dependencies.forceTerminatePid) {
    await dependencies.forceTerminatePid(pid, platform);
    return;
  }
  try {
    process.kill(pid, "SIGKILL");
  } catch (error) {
    if (error.code !== "ESRCH") {
      throw new SmokeFailure(
        "mcp_smoke_cleanup_failed",
        "MCP server process cleanup could not be verified.",
      );
    }
  }
}

export async function cleanupProcessTree(processInfos, platform = process.platform, dependencies = {}) {
  const uniqueProcesses = uniqueProcessInfos(processInfos);
  const leafFirst = [...uniqueProcesses].reverse();
  for (const processInfo of leafFirst) {
    if (await currentMatchingProcess(processInfo, platform, dependencies)) {
      await terminateProcess(processInfo.pid, platform, dependencies);
    }
  }
  let residual = await waitForProcessIdentitiesToExit(
    uniqueProcesses,
    CLEANUP_TIMEOUT_MS,
    platform,
    dependencies,
  );
  if (platform !== "win32" && residual.length > 0) {
    for (const processInfo of [...residual].reverse()) {
      if (await currentMatchingProcess(processInfo, platform, dependencies)) {
        await forceTerminateProcess(processInfo.pid, platform, dependencies);
      }
    }
    residual = await waitForProcessIdentitiesToExit(
      residual,
      CLEANUP_TIMEOUT_MS,
      platform,
      dependencies,
    );
  }
  return residual;
}

async function runSmoke(requestPath, resultPath) {
  let client;
  let transport;
  let serverPid = null;
  let processTree = [];
  let output;
  try {
    const request = JSON.parse(await readFile(requestPath, "utf8"));
    validateRequest(request);
    const clientPath = await realpath(request.sdkClientPath);
    const stdioPath = await realpath(request.sdkStdioPath);
    const { Client } = await import(pathToFileURL(clientPath).href);
    const { StdioClientTransport } = await import(pathToFileURL(stdioPath).href);
    client = new Client(
      { name: "codex-tool-manager-smoke", version: "1.0.0" },
      { capabilities: {} },
    );
    transport = new StdioClientTransport({
      command: request.command,
      args: request.args,
      cwd: request.cwd ?? undefined,
      stderr: "ignore",
    });
    const connectPromise = withTimeout(
      client.connect(transport),
      request.timeoutSeconds,
      "connect",
    );
    connectPromise.catch(() => {});
    serverPid = transport.pid;
    if (serverPid) {
      processTree = [serverPid];
      processTree = await snapshotProcessTree(serverPid);
    }
    await connectPromise;
    const listed = await withTimeout(client.listTools(), request.timeoutSeconds, "tools/list");
    const advertisedTools = listed.tools.map((tool) => tool.name);
    if (!advertisedTools.includes(request.toolName)) {
      throw new SmokeFailure("mcp_smoke_tool_missing", "Expected MCP tool was not advertised.");
    }
    const called = await withTimeout(
      client.callTool({ name: request.toolName, arguments: request.arguments }),
      request.timeoutSeconds,
      "tools/call",
    );
    if (called.isError === true) {
      throw new SmokeFailure("mcp_smoke_call_failed", "MCP tool returned an error result.");
    }
    output = {
      status: "smoke_verified",
      errorCode: null,
      advertisedTools,
      contentTypes: (called.content ?? []).map((item) => item.type),
      isError: false,
      serverPid,
    };
  } catch (error) {
    const knownFailure = error instanceof SmokeFailure;
    output = {
      status: "failed",
      errorCode: knownFailure ? error.code : "mcp_smoke_start_failed",
      message: knownFailure ? error.message : "MCP smoke runner could not complete.",
      advertisedTools: [],
      contentTypes: [],
      isError: true,
      serverPid,
    };
  } finally {
    let cleanupError;
    let residual = [];
    const recordCleanupError = (error) => {
      cleanupError ??=
        error instanceof SmokeFailure
          ? error
          : new SmokeFailure(
              "mcp_smoke_cleanup_failed",
              "MCP server process cleanup could not be verified.",
            );
    };
    if (serverPid) {
      try {
        const refreshedProcessTree = await snapshotProcessTree(serverPid);
        if (refreshedProcessTree.length > 0) {
          processTree = mergeProcessTrees(processTree, refreshedProcessTree);
        } else if (processTree.length > 0) {
          recordCleanupError(
            new SmokeFailure(
              "mcp_smoke_cleanup_failed",
              "MCP server process cleanup could not be verified.",
            ),
          );
        }
      } catch (error) {
        recordCleanupError(error);
      }
    }
    try {
      if (client) await client.close();
      else if (transport) await transport.close();
    } catch (error) {
      recordCleanupError(error);
    }
    try {
      residual = await cleanupProcessTree(processTree);
    } catch (error) {
      recordCleanupError(error);
      residual = processTree
        .map(normalizeProcessInfo)
        .filter((processInfo) => processExists(processInfo.pid));
    }
    output.residualProcess = residual.length > 0 || Boolean(cleanupError);
    if (cleanupError) {
      output.status = "failed";
      output.errorCode = "mcp_smoke_cleanup_failed";
      output.message = "MCP server process cleanup could not be verified.";
    } else if (residual.length > 0) {
      output.status = "failed";
      output.errorCode = "mcp_smoke_residual_process";
      output.message = "MCP server processes remained after cleanup.";
    }
    await writeFile(resultPath, JSON.stringify(output), "utf8");
  }
  return output.status === "smoke_verified" ? 0 : 1;
}

function isMainModule() {
  return Boolean(process.argv[1]) && import.meta.url === pathToFileURL(resolve(process.argv[1])).href;
}

if (isMainModule()) {
  const [requestPath, resultPath] = process.argv.slice(2);
  if (!requestPath || !resultPath) process.exit(2);
  process.exit(await runSmoke(requestPath, resultPath));
}
