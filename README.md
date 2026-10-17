# Base Plugin for ChatGPT

A minimal reusable foundation for building local ChatGPT plugins through an MCP tunnel.

The template intentionally uses the literal placeholder **`PluginName`**. Copy or fork the repository, then replace `PluginName` with the identity of the new plugin.

## Core design

- MCP SDK server over stdio
- one `main` MCP channel
- two explicit example tools:
  - `plugin_status` — read-only/runtime identity pattern
  - `plugin_echo` — parameter schema + handler + response pattern
- first-run connection setup without manually editing YAML
- saved connection reuse on normal starts
- explicit selective/all settings reset
- Windows DPAPI protection for the Runtime API key
- health-port availability validation
- tests
- MIT License

The base intentionally does **not** inherit LConnect's filesystem, shell, process, Git, GitHub, network, hardware, browser, or desktop-control tool catalog. Add only the capabilities required by the new plugin.

## Main files

- `PluginName.mjs` — MCP entry point and the two example tools
- `Setup-PluginName.cmd/.ps1` — first-run/reconfiguration wizard
- `Start-PluginName.cmd/.ps1` — starts immediately with saved settings
- `Status-PluginName.cmd/.ps1` — status/readiness display
- `Stop-PluginName.cmd/.ps1` — deterministic local stop
- `Clear-PluginNameSettings.cmd/.ps1` — clear API key, connection values, or everything
- `scripts/PluginNameSettings.ps1` — settings, DPAPI credential and generated-profile helpers
- `mcp-conf.example.yaml` — reference only; normal operation generates `mcp-conf.yaml` automatically
- `tests/` — baseline tests
- `runtime/.gitkeep` — local runtime-state directory placeholder

## First connection

Place the supported `tunnel-client.exe` in the project root, install dependencies, then run:

```powershell
npm install
Setup-PluginName.cmd
```

The wizard asks one value at a time:

1. Tunnel ID
2. Runtime API key (hidden input, stored with Windows DPAPI)
3. Organization ID
4. Local health port

The selected health port is checked before it is saved. The wizard then generates `mcp-conf.yaml` automatically.

## Normal use

After setup, run:

```powershell
Start-PluginName.cmd
```

Saved values are reused immediately. The wizard is not shown again unless a required value was intentionally cleared or is missing.

If only the API key was cleared, the next start asks only for the API key. If only connection settings were cleared, the saved API key is reused while Tunnel ID, Organization ID and port are collected again. Clearing everything returns the template to first-run behavior.

## Creating a new plugin

1. Copy/fork this repository.
2. Rename the repository.
3. Replace `PluginName` in filenames/source/config with the new plugin name.
4. Add only the MCP tools required by the new plugin.
5. Keep the existing tunnel/plugin binding when adapting an already-connected ChatGPT plugin; change only the `main` MCP command when possible.
6. Run `npm test` before deployment.

## Security baseline

Never commit Runtime API keys, `mcp-conf.yaml`, `local-secrets/`, runtime state, browser profiles, or logs. The template's `.gitignore` excludes these local artifacts.

## License

MIT
