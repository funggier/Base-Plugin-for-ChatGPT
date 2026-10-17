# Base Plugin for ChatGPT

A generic local MCP plugin base for ChatGPT.

- Current version: **0.1.0**
- Release target: **v0.1.0 — Generic MCP Plugin Baseline**

The internal plugin identity is intentionally fixed as `Plugin`. The repository, project folder, and product built from this base may use any external name. No source-file or operator-script renaming is required.

## Included

- MCP server over stdio with one `main` channel
- two example tools:
  - `plugin_status`
  - `plugin_echo`
- guided local connection setup
- saved connection reuse
- Windows DPAPI protection for the Runtime API key
- explicit status, stop, refresh, and reset commands
- separated generated and persistent runtime storage
- bounded conditional-read cache for safe read-only tools
- automated tests
- MIT License

The base does not include filesystem, shell, process, desktop, browser, Git, network, hardware, or other broad control tools. Add only the capabilities required by the plugin being developed.

## Quick start

Install dependencies and run the tests:

```powershell
npm install
npm test
```

Configure the local connection:

```text
Setup-Plugin.cmd
```

The setup wizard asks for:

1. Tunnel ID
2. Runtime API key
3. Organization ID
4. Local health port

The Runtime API key is entered using hidden input and stored locally with Windows DPAPI. The selected health port is validated before it is saved.

The setup process generates the real `mcp-conf.yaml` automatically. Manual YAML editing is not required for normal use.

Start the plugin:

```text
Start-Plugin.cmd
```

Check status:

```text
Status-Plugin.cmd
```

Stop the plugin:

```text
Stop-Plugin.cmd
```

## Generic identity

The base uses the following stable internal names:

```text
Plugin.mjs
Plugin-runtime/
scripts/PluginSettings.ps1
Setup-Plugin.cmd/.ps1
Start-Plugin.cmd/.ps1
Status-Plugin.cmd/.ps1
Stop-Plugin.cmd/.ps1
Refresh-Plugin.cmd/.ps1
Clear-PluginSettings.cmd/.ps1
```

`Plugin.mjs` reports the MCP server name as `Plugin`.

Keeping these names stable makes the base simple to use and makes future updates easier to compare and integrate.

## Connection lifecycle

### Setup

`Setup-Plugin.cmd` creates the local connection settings and generates `mcp-conf.yaml`.

Saved values are preserved until they are explicitly cleared. If only part of the configuration is missing, the setup flow reuses the remaining valid values.

### Start

`Start-Plugin.cmd`:

- loads the saved Tunnel ID, Organization ID, and health port;
- decrypts the locally stored Runtime API key;
- regenerates the local profile when needed;
- runs tunnel-client configuration checks;
- starts the tunnel.

When the configuration is complete, startup proceeds without asking setup questions.

### Status

`Status-Plugin.cmd` reports local configuration, process state, liveness/readiness, and local health/UI endpoints.

### Stop

`Stop-Plugin.cmd` stops the locally tracked plugin and tunnel processes.

### Refresh

`Refresh-Plugin.cmd` performs an offline refresh of generated local state.

It clears:

- `runtime/`
- `logs/`

It preserves:

- `Plugin-runtime/`
- `local-secrets/`
- DPAPI-protected credentials
- connection settings
- `mcp-conf.yaml`
- source files
- dependencies

Stop the plugin before running a refresh.

### Clear settings

`Clear-PluginSettings.cmd` provides explicit reset modes:

- Runtime API key only
- connection settings only
- all local connection/runtime state

Normal use never clears settings automatically.

## Runtime storage

Generated state and plugin-owned persistent assets are separated intentionally.

### Generated state

```text
runtime/
logs/
```

These directories may be cleared during refresh.

### Persistent plugin assets

```text
Plugin-runtime/
```

Use this directory for assets that must survive refresh, such as:

- browser drivers
- helper binaries
- local models
- persistent caches

Do not place required persistent assets under `runtime/`.

## MCP examples

### plugin_status

`plugin_status` returns basic runtime identity and demonstrates the conditional-read contract.

Optional request fields:

- `known_digest`
- `cache_max_age_ms`

The response includes SHA-256 digest metadata and can suppress an unchanged payload. A short positive TTL may also skip a safe repeated read when matching digest metadata is still fresh.

### plugin_echo

`plugin_echo` is a minimal example of:

- an input schema
- a tool handler
- a text response

Replace or remove the example tools as the real plugin is developed.

## Context efficiency

`lib/conditional-read-cache.mjs` provides a bounded metadata-only conditional-read cache for safe read-only operations.

It can:

- compute SHA-256 digests for returned text;
- suppress unchanged response bodies;
- optionally skip a safe read for a short explicit TTL;
- distinguish fresh revalidation from cache short-circuiting;
- retain only digest, size, and timestamp metadata;
- bound metadata entries to avoid unbounded memory growth.

Do not use this cache for write or action tools.

Detailed design, safety boundaries, cache-key guidance, tests, metrics, and schema-refresh qualification are documented in:

```text
docs/CONTEXT-EFFICIENCY.md
```

## Project structure

```text
Plugin.mjs
lib/
  conditional-read-cache.mjs
scripts/
  PluginSettings.ps1
docs/
  CONTEXT-EFFICIENCY.md
tests/
Plugin-runtime/
runtime/
mcp-conf.example.yaml
package.json
```

`mcp-conf.example.yaml` is a reference profile. `Setup-Plugin.cmd` generates the active ignored `mcp-conf.yaml`.

## Development

A practical development flow is:

1. Copy or fork the repository.
2. Keep the generic internal `Plugin` identity.
3. Add only the MCP tools required by the project.
4. Use conditional caching only for explicitly safe read-only tools.
5. Run `npm test`.
6. Configure the local tunnel with `Setup-Plugin.cmd`.
7. Start the runtime and perform live qualification.
8. Preserve an existing ChatGPT tunnel binding when adapting a connected plugin unless changing the binding is intentional.

## Security

Do not commit:

- Runtime API keys
- `mcp-conf.yaml`
- `local-secrets/`
- generated runtime state
- browser/login profiles
- runtime logs

`.gitignore` excludes these local artifacts. Contents of `Plugin-runtime/` are also ignored by default except for `.gitkeep`.

## Requirements

- Windows for the supplied DPAPI/operator workflow
- Node.js 20 or newer
- supported `tunnel-client.exe` in the repository root for tunnel operation

## License

MIT
