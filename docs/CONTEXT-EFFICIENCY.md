# Context Efficiency and Conditional Read Cache

This template includes a small, reusable baseline for reducing repeated MCP payloads without caching unsafe actions.

The goal is to reduce duplicate context and optionally skip repeated **safe read-only** execution for a short, explicit TTL. This is not a general memoization layer for every tool, and it must never be treated as permission to cache mutations.

## Baseline contract

Use the following request fields on read-only tools where repeated results can be large or frequent:

- `known_digest` — SHA-256 digest returned by the previous successful read.
- `cache_max_age_ms` — optional TTL. `0` means freshness-first revalidation. A positive value permits a metadata cache hit to skip execution while the entry is still fresh.

Recommended response fields:

- `result_digest_sha256`
- `not_modified`
- `result_suppressed`
- `cache_hit`
- `execution_skipped`
- `cache_age_ms`
- `result_bytes` / `result_chars`
- `returned_chars`
- `content_retained`

When the digest is unchanged, return an empty result body and metadata that says the result was not modified. This prevents the same large payload from being injected into model context again.

## Security and correctness boundary

Only use conditional caching for operations that are explicitly classified as read-only and idempotent enough for the selected TTL.

Do **not** cache or suppress execution for:

- filesystem writes, edits, moves, deletes, or directory creation;
- shell or PowerShell execution;
- process start/stop/restart or stdin writes;
- service changes;
- scheduled-task changes;
- browser/UI clicks, typing, navigation, or other mutations;
- Git writes, commits, pushes, pulls, fetches, branch changes, or other state transitions;
- HTTP requests with side effects;
- authentication, secret rotation, or credential operations.

For sensitive reads, prefer digest-only metadata and do not persist the returned content in the cache.

The helper in `lib/conditional-read-cache.mjs` stores only digest, byte/character counts, and the timestamp needed to evaluate TTL. It does not retain the result body.

## Freshness modes

### Freshness-first

Use `cache_max_age_ms: 0`.

The tool executes the read again, computes a new digest, and suppresses the body only if the digest still matches `known_digest`.

Use this for rapidly changing state or when correctness is more important than avoiding the read itself.

### Short TTL

Use a small positive TTL, such as 5–60 seconds for status/configuration data that changes infrequently.

If the cache key and digest match a fresh metadata entry, execution can be skipped and the tool returns `not_modified: true`.

Do not choose a TTL merely to maximize hit rate. Choose it based on how stale the result is allowed to be.

## Cache-key design

A cache key must uniquely identify the logical read.

For tools with arguments, derive the key from:

1. tool/operation name;
2. canonicalized arguments that affect the result;
3. a schema/version suffix when result semantics change.

Do not put secrets directly into cache keys or logs. When arguments may contain sensitive values, hash a canonical representation first.

Example conceptual key:

`sha256("read_text_file:v1\n" + canonicalArgs)`

If object key order is not stable, canonicalize recursively before hashing.

## Bounded memory

Keep the metadata cache bounded.

The template defaults are:

- maximum entries: 256
- maximum accepted TTL: 300000 ms (5 minutes)
- content retention: false

Evict old metadata entries when the limit is exceeded. Do not create an unbounded in-memory cache.

## Recommended tool implementation pattern

1. Validate `known_digest` as a 64-character SHA-256 hex string.
2. Validate and cap `cache_max_age_ms`.
3. Build a stable cache key.
4. If a positive TTL is requested, try a digest-only metadata hit.
5. Otherwise execute the real read.
6. Hash the complete successful result.
7. Store only digest/size/timestamp metadata.
8. Suppress the result body when the digest equals `known_digest`.
9. Never cache errors.
10. Expose enough metadata to prove whether execution was skipped or freshly revalidated.

`plugin_status` in `PluginName.mjs` is the minimal working example.

## Tests required before adopting the pattern

At minimum verify:

- first read returns content and a valid digest;
- same digest + positive TTL returns `cache_hit: true` and `execution_skipped: true`;
- same digest + TTL 0 executes again but suppresses unchanged content;
- changed content returns a new digest and the new body;
- errors are not cached;
- the cache reports `content_retained: false`;
- cache bounds/eviction behave as intended;
- write/mutation tools cannot enter this cache path.

The template tests cover the core helper contract. Real plugins should add tool-specific end-to-end tests.

## Measuring benefit

Track actual serialized payload reduction rather than assuming a fixed quota saving.

Useful counters include:

- conditional requests;
- cache short circuits;
- fresh revalidations that were not modified;
- changed results;
- estimated or actual returned characters/bytes avoided;
- tool execution count avoided.

Prompt/context caching and ChatGPT/Codex plan quota accounting are external to the plugin. A high MCP cache-hit rate does **not** imply the same percentage reduction in plan quota.

## Broader context-efficiency roadmap

Conditional read caching is only one layer. For larger plugins, prioritize these techniques as appropriate:

1. deferred/lazy tool exposure so unused schemas are not repeatedly loaded;
2. compact and delta response modes instead of full snapshots;
3. digest-based conditional reads and short-TTL read cache;
4. bounded summaries for logs/search/list operations;
5. stable cursors and incremental polling for long-running streams;
6. telemetry for payload bytes/chars and cache effectiveness.

Always preserve explicit freshness controls. Optimization must not make state transitions invisible or turn stale data into authoritative truth.

## ChatGPT schema refresh

Changing a tool input schema requires the ChatGPT connector/plugin surface to refresh before the new fields can be sent from an existing chat session.

Runtime deployment and client-visible schema refresh are separate qualification steps:

1. deploy and restart the runtime;
2. prove the runtime accepts/returns the new contract locally or through an already compatible caller;
3. refresh/reload the ChatGPT plugin;
4. inspect the client-visible schema;
5. run an end-to-end conditional-read test from ChatGPT.

Do not diagnose a client-side schema rejection as a runtime failure until both sides have been checked.
