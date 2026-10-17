import test from "node:test";
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { PLUGIN_NAME, PLUGIN_VERSION, createServer } from "../Plugin.mjs";

test("generic plugin identity is stable", () => {
  assert.equal(PLUGIN_NAME, "Plugin");
  assert.match(PLUGIN_VERSION, /^\d+\.\d+\.\d+$/);
});

test("server can be constructed without opening transport", () => {
  const server = createServer();
  assert.ok(server);
});

test("direct stdio entry point remains Windows-safe", () => {
  const probe = [
    "import { Client } from '@modelcontextprotocol/sdk/client/index.js';",
    "import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';",
    "const t=new StdioClientTransport({command:'node',args:['Plugin.mjs'],cwd:process.cwd()});",
    "const c=new Client({name:'test-probe',version:'1.0.0'});",
    "await c.connect(t);",
    "const r=await c.listTools();",
    "console.log(JSON.stringify(r.tools.map(x=>x.name).sort()));",
    "await c.close();"
  ].join(" ");
  const result = spawnSync(
    process.execPath,
    ["--input-type=module", "-e", probe],
    { cwd: new URL("..", import.meta.url), encoding: "utf8", timeout: 10000 }
  );
  assert.equal(result.status, 0, result.stderr || result.stdout);
  assert.deepEqual(JSON.parse(result.stdout.trim()), ["plugin_echo", "plugin_status"]);
});
