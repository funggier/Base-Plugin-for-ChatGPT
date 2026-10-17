import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";

const root = path.resolve(import.meta.dirname, "..");
const initializer = path.join(root, "Initialize-Plugin.ps1");
const templateToken = ["Plugin", "Name"].join("");
const templateLower = ["plugin", "name"].join("");

test("initializer entry points exist", () => {
  assert.equal(fs.existsSync(path.join(root, "Initialize-Plugin.cmd")), true);
  assert.equal(fs.existsSync(initializer), true);
});

test("initializer remains generic instead of rewriting itself", () => {
  const source = fs.readFileSync(initializer, "utf8");
  assert.equal(source.includes(templateToken), false);
  assert.equal(source.includes(templateLower), false);
  assert.match(source, /TEMPLATE_ALREADY_INITIALIZED/);
  assert.match(source, /plugin-identity\.json/);
});

test("initializer preview works before initialization and guard works after it", () => {
  const templateEntry = path.join(root, templateToken + ".mjs");
  if (fs.existsSync(templateEntry)) {
    const result = spawnSync(
      "powershell.exe",
      ["-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", initializer, "-Name", "Example Writer", "-Preview"],
      { cwd: root, encoding: "utf8" }
    );
    assert.equal(result.status, 0, result.stderr || result.stdout);
    assert.match(result.stdout, /Code name\s+: ExampleWriter/);
    assert.match(result.stdout, /npm slug\s+: example-writer/);
    assert.match(result.stdout, /Preview only; no files were changed/);
  } else {
    assert.equal(fs.existsSync(path.join(root, "plugin-identity.json")), true);
    const result = spawnSync(
      "powershell.exe",
      ["-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", initializer, "-Name", "Other Plugin", "-Force"],
      { cwd: root, encoding: "utf8" }
    );
    assert.notEqual(result.status, 0);
    assert.match(result.stderr + result.stdout, /TEMPLATE_ALREADY_INITIALIZED/);
  }
});
