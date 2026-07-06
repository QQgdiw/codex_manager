import { readFile, writeFile, realpath } from "node:fs/promises";
import { pathToFileURL } from "node:url";

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
  } catch {
    return false;
  }
}

const [requestPath, resultPath] = process.argv.slice(2);
if (!requestPath || !resultPath) process.exit(2);

let client;
let transport;
let serverPid = null;
let output;
try {
  const request = JSON.parse(await readFile(requestPath, "utf8"));
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
    stderr: "pipe",
  });
  await withTimeout(client.connect(transport), request.timeoutSeconds, "connect");
  serverPid = transport.pid;
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
  output = {
    status: "failed",
    errorCode: error.code ?? "mcp_smoke_start_failed",
    message: error.message,
    advertisedTools: [],
    contentTypes: [],
    isError: true,
    serverPid,
  };
} finally {
  if (client) await client.close().catch(() => {});
  else if (transport) await transport.close().catch(() => {});
  await new Promise((resolve) => setTimeout(resolve, 50));
  output.residualProcess = processExists(serverPid);
  if (output.residualProcess) {
    output.status = "failed";
    output.errorCode = "mcp_smoke_residual_process";
  }
  await writeFile(resultPath, JSON.stringify(output), "utf8");
}
process.exit(output.status === "smoke_verified" ? 0 : 1);
