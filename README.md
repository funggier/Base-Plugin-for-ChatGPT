# Base Plugin for ChatGPT

A minimal reusable foundation for building local ChatGPT plugins through an MCP tunnel.

The repository is designed to be copied or forked for a new plugin. The uninitialized template uses a placeholder code identity in filenames, source code, configuration, tests, and package metadata. You do **not** need to rename those locations manually.

## Start here: rename the whole template in one step

Immediately after copying or forking the repository, double-click:

```text
Initialize-Plugin.cmd
```

The initializer asks for the plugin name once. For example, entering:

```text
Fictionlog Writer
```

produces:

```text
Display name : Fictionlog Writer
Code name    : FictionlogWriter
npm slug     : fictionlog-writer
```

It then renames template files and folders, updates source/config/docs/tests/package metadata, and writes `plugin-identity.json` as a record of the selected identity.

Typical path changes include:

```text
PluginName.mjs                    -> FictionlogWriter.mjs
Setup-PluginName.cmd              -> Setup-FictionlogWriter.cmd
Start-PluginName.cmd              -> Start-FictionlogWriter.cmd
PluginName-runtime/               -> FictionlogWriter-runtime/
scripts/PluginNameSettings.ps1    -> scripts/FictionlogWriterSettings.ps1
tests/PluginName.test.mjs         -> tests/FictionlogWriter.test.mjs
```

The same identity is also replaced inside the relevant text files. Lowercase package identity is converted to an npm-safe slug, so `pluginname-chatgpt-mcp` becomes `fictionlog-writer-chatgpt-mcp` in this example.

The easiest workflow is to run the initializer **before** connection setup or plugin development. It intentionally skips Git internals, `node_modules`, generated runtime/log content, secret contents, and plugin-owned persistent binary/cache contents.

### Preview or automate initialization

To see exactly what would change without modifying files:

```powershell
.\Initialize-Plugin.ps1 -Name "Fictionlog Writer" -Preview
```

For a scripted/non-interactive initialization:

```powershell
.\Initialize-Plugin.ps1 -Name "Fictionlog Writer" -Force
```

The initializer is one-shot by design. After the template entry point has been renamed, running it again stops with `TEMPLATE_ALREADY_INITIALIZED` instead of guessing what should be renamed.

## Core design

The base provides an MCP SDK server over stdio with one `main` channel, first-run connection setup, saved connection reuse, explicit reset/refresh workflows, Windows DPAPI protection for the Runtime API key, health-port validation, tests, and an MIT License.

Only two example MCP tools are included:

- `plugin_status` — read-only runtime identity pattern.
- `plugin_echo` — minimal parameter schema, handler, and response pattern.

The base intentionally does **not** inherit LConnect's filesystem, shell, process, Git, GitHub, network, hardware, browser, or desktop-control catalog. Add only the capabilities required by the new plugin.

## Main operator files

Before initialization the operator files use the template identity. After initialization their filenames automatically use your selected code name.

```text
Initialize-Plugin.cmd/.ps1
Setup-PluginName.cmd/.ps1
Start-PluginName.cmd/.ps1
Status-PluginName.cmd/.ps1
Stop-PluginName.cmd/.ps1
Refresh-PluginName.cmd/.ps1
Clear-PluginNameSettings.cmd/.ps1
```

`PluginName.mjs` is the MCP entry point. `scripts/PluginNameSettings.ps1` contains connection/profile helpers. `mcp-conf.example.yaml` is reference-only because normal operation generates `mcp-conf.yaml` automatically.

## First connection

After initialization, install dependencies and run the renamed setup command. Using the Fictionlog Writer example:

```powershell
npm install
.\Setup-FictionlogWriter.cmd
```

The setup wizard asks one value at a time: Tunnel ID, Runtime API key, Organization ID, and local health port. API-key input is hidden and the stored credential is protected with Windows DPAPI. The selected health port is checked before saving, and `mcp-conf.yaml` is generated automatically.

A supported `tunnel-client.exe` must exist in the project root before starting the tunnel.

## Normal use

After setup, use the renamed Start command. Saved values are reused immediately; the setup wizard is not shown again unless a required value was intentionally cleared or is missing.

If only the API key was cleared, the next start asks only for the API key. If connection settings were cleared, the saved API key can be reused while Tunnel ID, Organization ID, and port are collected again. Clearing everything returns the project to first-connection behavior.

## Runtime separation

Generated tunnel state and plugin-owned persistent assets are deliberately separated.

`runtime/` and `logs/` are disposable generated state. The renamed `PluginName-runtime/` directory is persistent plugin-owned storage for assets such as browser drivers, helper binaries, models, or caches that must survive a normal refresh.

`Refresh-PluginName.cmd` clears generated `runtime/` and `logs/` only. It preserves the persistent plugin runtime, `local-secrets/`, DPAPI credentials, connection settings, `mcp-conf.yaml`, source files, and dependencies.

Do not place required plugin binaries under the generated `runtime/` tree.

## Recommended development flow

Run the initializer first, then `npm install` and `npm test`. Add only the MCP tools required by the plugin. If adapting an already-connected ChatGPT plugin, preserve its existing tunnel/plugin binding when possible and change only the `main` MCP command. Re-run tests and perform a live runtime qualification before treating the plugin as complete.

## Security baseline

Never commit Runtime API keys, `mcp-conf.yaml`, `local-secrets/`, generated runtime state, browser profiles, or logs. The template's `.gitignore` excludes these local artifacts. Plugin-owned binaries or caches under the persistent runtime are ignored by default except for its `.gitkeep`.

## License

MIT
