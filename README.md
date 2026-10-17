# Base Plugin for ChatGPT

A minimal reusable foundation for building local ChatGPT plugins through an MCP tunnel.

The template intentionally uses the literal placeholder **`PluginName`**. Copy the repository, then rename `PluginName` only where your new plugin needs its own identity.

## What this base keeps

- MCP SDK server over stdio
- one `main` MCP channel
- local tunnel-compatible configuration example
- two explicit example tools
  - `plugin_status` — read-only/runtime identity pattern
  - `plugin_echo` — parameter schema + handler + response pattern
- tests
- MIT License

## What this base intentionally does not keep

It does not inherit LConnect's filesystem, shell, process, Git, GitHub, network, hardware, browser, or desktop-control catalog. Add only the capabilities required by the new plugin.

## Files

- `PluginName.mjs` — MCP entry point containing the two example tools
- `mcp-conf.example.yaml` — local tunnel profile template
- `tests/PluginName.test.mjs` — baseline tests
- `runtime/.gitkeep` — local runtime state directory

## Create a new plugin

1. Copy/fork this repository.
2. Rename the repository.
3. Replace `PluginName` in source/config with the new plugin name.
4. Add only the required MCP tools.
5. Copy `mcp-conf.example.yaml` to `mcp-conf.yaml`.
6. Keep the existing tunnel/plugin binding if adapting an already-connected ChatGPT plugin; change only the `main` command when possible.
7. Run:

```powershell
npm install
npm test
npm start
```

## Security baseline

Never commit:

- tunnel credentials
- API keys
- `mcp-conf.yaml`
- browser profiles
- local secrets
- runtime logs/state

## License

MIT
