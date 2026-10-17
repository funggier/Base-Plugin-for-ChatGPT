import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

export const PLUGIN_NAME = "PluginName";
export const PLUGIN_VERSION = "0.1.0";

export function createServer() {
  const server = new McpServer({
    name: PLUGIN_NAME,
    version: PLUGIN_VERSION,
  });

  server.tool(
    "plugin_status",
    "Return basic runtime identity for this plugin.",
    {},
    async () => ({
      content: [{
        type: "text",
        text: JSON.stringify({
          name: PLUGIN_NAME,
          version: PLUGIN_VERSION,
          pid: process.pid,
          cwd: process.cwd(),
        }, null, 2),
      }],
    })
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
