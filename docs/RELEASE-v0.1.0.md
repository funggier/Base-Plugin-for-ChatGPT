# Base-Plugin-for-ChatGPT v0.1.0 Release

**Status:** COMPLETE / PUBLISHED

## Purpose

First immutable release of the generic local MCP plugin baseline for ChatGPT.

## Release identity

- version: `0.1.0`
- tag: `v0.1.0`
- title: **Base-Plugin-for-ChatGPT v0.1.0 — Generic MCP Plugin Baseline**
- release commit: `1ea31638749cbdde4d2234017ba0f36a2b4b1545`
- exact-commit CI: #1 / run `39033786726` / SUCCESS

## Included

- fixed generic internal `Plugin` identity
- guided Setup/Start/Status/Stop/Refresh/Clear lifecycle
- separated local connection settings and DPAPI Runtime API key
- generated vs persistent runtime separation
- bounded digest-only conditional read cache example
- safe `plugin_status` conditional-read contract
- automated Node tests
- Linux + Windows CI
- MIT license

## Qualification

- Node tests: 12/12 PASS
- dependency audit: 0 vulnerabilities
- PowerShell syntax: PASS
- exact release-commit GitHub Actions: SUCCESS
- immutable annotated tag: PASS
- release/document/checksum assets: PASS
- download-back verification: 3 files / 2 manifest entries / **0 SHA-256 mismatches**

Release: https://github.com/funggier/Base-Plugin-for-ChatGPT/releases/tag/v0.1.0
