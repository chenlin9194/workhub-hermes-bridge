# WorkHub Hermes Bridge

WorkHub Hermes Bridge is the deployable integration layer between a Feishu/Hermes agent and a running WorkHub instance.

It is intentionally separate from the WorkHub application repository:

- WorkHub owns its data model, business rules, and the authenticated MCP HTTP endpoint.
- This repository owns Hermes MCP registration, local runtime configuration, diagnostics, deployment guidance, and Feishu acceptance.
- This repository never reads WorkHub's SQLite database directly and does not contain WorkHub secrets.

## Compatibility

This Bridge requires a WorkHub instance that reports the following through its authenticated `health` tool:

```text
service: workhub-hermes-v1
tools: 32 entries
```

Use a WorkHub revision that contains the Hermes MCP V1 endpoint. Do not deploy this Bridge against an older WorkHub MCP MVP service.

## Choose a Transport

The same Bridge release supports two local transports. Set `HERMES_MCP_TRANSPORT` in the private `config/bridge.env` on each computer:

| Transport | Use it when | What is registered in Hermes |
| --- | --- | --- |
| `stdio` (default) | Hermes MCP calls are already stable. This is the normal choice for a new or home computer. | A local Node process |
| `http` | A real Hermes or Feishu tool call fails with a stdio session-lifecycle error such as `ClosedResourceError`. | `http://127.0.0.1:3001/mcp` |

Changing this setting affects only that computer's private configuration. It does not modify WorkHub or another computer's Hermes registration.

## Quick Start on Windows + WSL (stdio)

1. Deploy and start WorkHub first.
2. Run `npm.cmd ci` in this repository.
3. Copy the local configuration template:

```powershell
Copy-Item .\config\bridge.env.example .\config\bridge.env
```

4. Edit `config\bridge.env` with the WorkHub address, the same token used by WorkHub, and the WSL Hermes user. Keep `HERMES_MCP_TRANSPORT=stdio`.
5. Register and validate Hermes:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\doctor.ps1
```

6. Start a new Hermes session, then validate the Feishu bot using the raw `health` prompt in [acceptance-prompts.md](docs/acceptance-prompts.md).

For HTTP mode, follow the dedicated steps in [company-deployment.md](docs/company-deployment.md#http-mode-for-stdio-lifecycle-issues). Do not switch a working stdio computer merely because another computer needs HTTP mode.

## Repository Layout

```text
scripts/hermes-workhub-mcp.mjs  Hermes stdio MCP server
scripts/hermes-workhub-mcp-http.mjs  Loopback-only Streamable HTTP MCP server
scripts/install.ps1             Register or update local Hermes MCP configuration
scripts/doctor.ps1              Verify authenticated WorkHub health and Hermes tool discovery
scripts/uninstall.ps1           Remove only the local Hermes MCP registration
config/bridge.env.example       Local configuration template, no secrets
docs/company-deployment.md      Full company runbook
docs/hermes-skill.md            Hermes agent rules
docs/acceptance-prompts.md      Feishu acceptance prompts
```

## Security

- Never commit `config/bridge.env`, `.env`, tokens, Feishu credentials, Hermes user configuration, or WorkHub database files.
- `HERMES_WORKHUB_TOKEN` must match exactly in WorkHub and this Bridge configuration.
- Deploy Hermes and WorkHub on the same internal host when possible. If they are on different hosts, use an internal HTTPS address instead of `127.0.0.1`.

## Operations

Read [company-deployment.md](docs/company-deployment.md) before a first deployment, upgrade, or recovery. It is written for a new operator or AI agent without the original implementation context.
