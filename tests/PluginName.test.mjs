import test from "node:test";
import assert from "node:assert/strict";
import { PLUGIN_NAME, PLUGIN_VERSION, createServer } from "../PluginName.mjs";

test("template identity remains explicit", () => {
  assert.equal(PLUGIN_NAME, "PluginName");
  assert.match(PLUGIN_VERSION, /^\d+\.\d+\.\d+$/);
});

test("server can be constructed without opening transport", () => {
  const server = createServer();
  assert.ok(server);
});
