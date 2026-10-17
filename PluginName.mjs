import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { createConditionalReadCache } from "./lib/conditional-read-cache.mjs";

export const PLUGIN_NAME = "PluginName";
export const PLUGIN_VERSION = "0.1.0";

const statusCache = createConditionalReadCache();

export function createServer() {
  const server = new McpServer({
    name: PLUGIN_NAME,
    version: PLUGIN_VERSION,
  });

  server.tool(
    "plugin_status",
    "Return basic runtime identity. Supports SHA-256 conditional reads so unchanged payloads can be suppressed, and optional short TTL reuse can skip safe read execution.",
    {
      known_digest: z.string().regex(/^[a-f0-9]{64}$/i).optional(),
      cache_max_age_ms: z.number().int().min(0).max(300000).optional(),
    },
    async ({ known_digest, cache_max_age_ms }) => {
      const result = await statusCache.run({
        cacheKey: "plugin_status:v1",
        knownDigest: known_digest,
        cacheMaxAgeMs: cache_max_age_ms ?? 0,
        execute: async () => JSON.stringify({
          name: PLUGIN_NAME,
          version: PLUGIN_VERSION,
          pid: process.pid,
          cwd: process.cwd(),
        }, null, 2),
      });

      return {
        content: [{
          type: "text",
          text: JSON.stringify({
            result_digest_sha256: result.resultDigestSha256,
            result_bytes: result.resultBytes,
            result_chars: result.resultChars,
            returned_chars: result.returnedChars,
            not_modified: result.notModified,
            result_suppressed: result.resultSuppressed,
            cache_hit: result.cacheHit,
            execution_skipped: result.executionSkipped,
            cache_age_ms: result.cacheAgeMs,
            content_retained: result.contentRetained,
            result_text: result.resultText,
          }, null, 2),
        }],
      };
    }
  );

  server.tool(
    "plugin_echo",
    "Minimal example tool. Replace or remove this when implementing the real plugin.",
    { text: z.string().max(10000) },
    async ({ text }) => ({
      content: [{ type: "text", text }],
    })
  );

  return server;
}

if (import.meta.url === new URL(process.argv[1], "file:///").href) {
  const server = createServer();
  console.error(PLUGIN_NAME + " " + PLUGIN_VERSION + " starting");
  await server.connect(new StdioServerTransport());
}
