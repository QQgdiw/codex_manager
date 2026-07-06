import { readFile, readdir, rm, writeFile } from "node:fs/promises";
import path from "node:path";

function option(name) {
  const index = process.argv.indexOf(name);
  if (index < 0 || index + 1 >= process.argv.length) throw new Error(`Missing ${name}`);
  return process.argv[index + 1];
}

const action = option("--action");
const tempRoot = path.resolve(option("--temp-root"));
const resultPath = path.resolve(option("--result-path"));
if (path.dirname(resultPath) !== tempRoot) throw new Error("Result path escaped temp root");
const markerPath = path.join(tempRoot, "lifecycle-marker.json");

if (action === "prepare") {
  const entries = await readdir(tempRoot);
  if (entries.length !== 0) throw new Error("Smoke temp root was not empty");
  await writeFile(markerPath, JSON.stringify({ prepared: true }), "utf8");
} else if (action === "validate") {
  const result = JSON.parse(await readFile(resultPath, "utf8"));
  if (result.status !== "smoke_verified" || result.isError === true) {
    throw new Error("Sequential-thinking smoke call did not succeed");
  }
  if (!Array.isArray(result.contentTypes) || !result.contentTypes.includes("text")) {
    throw new Error("Sequential-thinking smoke result did not contain text");
  }
} else if (action === "cleanup") {
  await rm(markerPath, { force: true });
  await rm(resultPath, { force: true });
} else {
  throw new Error("Unsupported lifecycle action");
}

process.stdout.write(JSON.stringify({ status: "ok", action }));
