import { execFile } from "node:child_process";
import { readFile, writeFile, realpath } from "node:fs/promises";
import { resolve } from "node:path";
import process from "node:process";
import { promisify } from "node:util";
import { pathToFileURL } from "node:url";

const execFileAsync = promisify(execFile);
const CLEANUP_TIMEOUT_MS = 5000;
const POLL_INTERVAL_MS = 25;

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
    Number.isFinite(request.timeoutSeconds) &&
    request.timeoutSeconds > 0;
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
  "$ErrorActionPreference='Stop'; Get-CimInstance Win32_Process | Select-Object ProcessId,ParentProcessId | ConvertTo-Json -Compress",
];

export function nativeProcessCommands(platform, pid) {
  if (platform === "win32") {
    return {
      snapshot: { command: "powershell.exe", args: WINDOWS_PROCESS_SNAPSHOT },
      terminate: {
        command: "taskkill.exe",
        args: ["/PID", String(pid), "/T", "/F"],
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
    }));
  }
  return stdout
    .split(/\r?\n/u)
    .map((line) => line.trim().match(/^(\d+)\s+(\d+)$/u))
    .filter(Boolean)
    .map((match) => ({ pid: Number(match[1]), parentPid: Number(match[2]) }));
}

function collectProcessTree(rootPid, rows) {
  const childrenByParent = new Map();
  for (const row of rows) {
    const children = childrenByParent.get(row.parentPid) ?? [];
    children.push(row.pid);
    childrenByParent.set(row.parentPid, children);
  }
  const tree = [];
  const pending = [rootPid];
  while (pending.length > 0) {
    const pid = pending.shift();
    if (tree.includes(pid)) continue;
    tree.push(pid);
    pending.push(...(childrenByParent.get(pid) ?? []));
  }
  return tree;
}

async function snapshotProcessTree(rootPid, platform = process.platform) {
  const commands = nativeProcessCommands(platform, rootPid);
  let stdout;
  try {
    ({ stdout } = await runNativeCommand(commands.snapshot));
    return collectProcessTree(rootPid, parseProcessRows(platform, stdout));
  } catch (error) {
    if (error instanceof SmokeFailure) throw error;
    throw new SmokeFailure(
      "mcp_smoke_cleanup_failed",
      "MCP server process cleanup could not be verified.",
    );
  }
}

async function terminateProcess(pid, platform = process.platform) {
  if (!processExists(pid)) return;
  if (platform === "win32") {
    const command = nativeProcessCommands(platform, pid).terminate;
    try {
      await runNativeCommand(command);
    } catch (error) {
      if (processExists(pid)) throw error;
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

async function cleanupProcessTree(pids, platform = process.platform) {
  const uniquePids = [...new Set(pids)].filter(Boolean);
  const leafFirst = [...uniquePids].reverse();
  for (const pid of leafFirst) await terminateProcess(pid, platform);
  let residual = await waitForProcessesToExit(uniquePids, CLEANUP_TIMEOUT_MS);
  if (platform !== "win32" && residual.length > 0) {
    for (const pid of [...residual].reverse()) {
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
    residual = await waitForProcessesToExit(residual, CLEANUP_TIMEOUT_MS);
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
    if (serverPid && processExists(serverPid)) {
      try {
        processTree = [...new Set([...processTree, ...(await snapshotProcessTree(serverPid))])];
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
      residual = processTree.filter(processExists);
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
