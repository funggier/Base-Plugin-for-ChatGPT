# Base-Plugin-for-ChatGPT v0.1.0 Release

**Status:** RELEASE CANDIDATE

## Purpose

First immutable release of the generic local MCP plugin baseline for ChatGPT.

## Included

- fixed generic internal `Plugin` identity
- guided Setup/Start/Status/Stop/Refresh/Clear lifecycle
- separated local connection settings and DPAPI Runtime API key
- generated vs persistent runtime separation
- bounded digest-only conditional read cache example
- safe `plugin_status` conditional-read contract
- automated Node tests
- MIT license

## Release identity

- version: `0.1.0`
- tag: `v0.1.0`
- title: **Base-Plugin-for-ChatGPT v0.1.0 — Generic MCP Plugin Baseline**
- branch: `main`

## Qualification

Release requires local tests/audit, exact pushed-commit GitHub Actions GREEN, immutable tag, release/document ZIPs and SHA-256 manifest.
