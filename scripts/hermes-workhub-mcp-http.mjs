#!/usr/bin/env node

import { randomUUID } from "node:crypto";
import { createServer } from "node:http";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { createWorkHubMcpServer } from "./hermes-workhub-mcp.mjs";

const host = process.env.HERMES_WORKHUB_MCP_HOST || "127.0.0.1";
const port = Number.parseInt(process.env.HERMES_WORKHUB_MCP_PORT || "3001", 10);
const sessions = new Map();

if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error("Invalid MCP port.");
if (!["127.0.0.1", "::1", "localhost"].includes(host)) throw new Error("MCP must bind to loopback.");

function sessionId(request) {
  const value = request.headers["mcp-session-id"];
  return Array.isArray(value) ? value[0] : value;
}

function jsonError(response, status, message) {
  response.writeHead(status, { "content-type": "application/json" });
  response.end(JSON.stringify({ jsonrpc: "2.0", error: { code: -32000, message }, id: null }));
}

async function readJsonBody(request) {
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > 1024 * 1024) throw new Error("Request body is too large.");
    chunks.push(chunk);
  }
  return JSON.parse(Buffer.concat(chunks).toString("utf8"));
}

function createTransport() {
  return new StreamableHTTPServerTransport({
    sessionIdGenerator: randomUUID,
    enableJsonResponse: true,
    enableDnsRebindingProtection: true,
    allowedHosts: [`127.0.0.1:${port}`, `localhost:${port}`, `[::1]:${port}`],
    onsessionclosed: (id) => sessions.delete(id),
  });
}

const server = createServer(async (request, response) => {
  if (request.url !== "/mcp") return response.writeHead(404).end();

  try {
    const id = sessionId(request);
    if (request.method === "POST") {
      const payload = await readJsonBody(request);
      const active = id ? sessions.get(id) : undefined;
      if (id && !active) return jsonError(response, 404, "Unknown MCP session.");
      if (active) return active.transport.handleRequest(request, response, payload);
      if (payload?.method !== "initialize") return jsonError(response, 400, "Initialize the MCP session first.");

      const transport = createTransport();
      transport.onclose = () => sessions.delete(transport.sessionId);
      await createWorkHubMcpServer().connect(transport);
      await transport.handleRequest(request, response, payload);
      if (transport.sessionId) sessions.set(transport.sessionId, { transport });
      return;
    }

    if (request.method === "GET" || request.method === "DELETE") {
      const active = id ? sessions.get(id) : undefined;
      if (!active) return jsonError(response, 400, "Mcp-Session-Id is required.");
      return active.transport.handleRequest(request, response);
    }

    response.writeHead(405, { allow: "GET, POST, DELETE" }).end();
  } catch (error) {
    console.error("WorkHub HTTP MCP request failed:", error);
    if (!response.headersSent) jsonError(response, 400, error instanceof Error ? error.message : "Invalid MCP request.");
    else response.end();
  }
});

server.listen(port, host, () => console.error(`WorkHub HTTP MCP listening at http://${host}:${port}/mcp`));

async function stop() {
  await Promise.allSettled([...sessions.values()].map(({ transport }) => transport.close()));
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(1), 5000).unref();
}

process.once("SIGINT", stop);
process.once("SIGTERM", stop);
