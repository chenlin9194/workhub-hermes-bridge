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

## Quick Start on Windows + WSL

1. Deploy and start WorkHub first.
2. Run `npm.cmd ci` in this repository.
3. Copy the local configuration template:

```powershell
Copy-Item .\config\bridge.env.example .\config\bridge.env
```

4. Edit `config\bridge.env` with the WorkHub address, the same token used by WorkHub, and the WSL Hermes user.
5. Register and validate Hermes:

```powershell
.\scripts\install.ps1
.\scripts\doctor.ps1
```

6. Start a new Hermes session, then validate the Feishu bot using the raw `health` prompt in [acceptance-prompts.md](docs/acceptance-prompts.md).

## Repository Layout

```text
scripts/hermes-workhub-mcp.mjs  Hermes stdio MCP server
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
