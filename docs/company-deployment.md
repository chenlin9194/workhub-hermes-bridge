# Company Deployment Runbook

## Architecture

```text
Feishu Bot -> Hermes Agent -> WorkHub Hermes Bridge -> WorkHub MCP HTTP endpoint -> WorkHub database
```

The Bridge uses the WorkHub HTTP endpoint. It does not access Prisma, SQLite, or the WorkHub repository directly.

## Before You Start

1. Deploy a compatible WorkHub version and start it.
2. Keep Hermes and WorkHub on the same internal host when possible.
3. Generate one strong token and put the same value into both configurations.
4. Confirm the Feishu bot actually uses this Hermes runtime; a separate cloud agent or WSL user does not share local MCP registration.

## WorkHub Configuration

In the WorkHub deployment host's `.env`:

```text
HERMES_WORKHUB_TOKEN="<strong-random-secret>"
```

Start WorkHub with its normal production process. The Bridge expects the WorkHub health endpoint to return `workhub-hermes-v1` and 32 tools.

## Bridge Configuration

Install dependencies:

```powershell
npm.cmd ci
```

Create the local configuration file:

```powershell
Copy-Item .\config\bridge.env.example .\config\bridge.env
```

Set these values:

```text
WORKHUB_BASE_URL=http://127.0.0.1:3000
HERMES_WORKHUB_TOKEN=<same-secret-as-workhub>
HERMES_WSL_DISTRO=<company-wsl-distro>
HERMES_WSL_USER=<company-wsl-user>
WORKHUB_EXPECTED_TOOL_COUNT=32
```

`WORKHUB_BASE_URL=http://127.0.0.1:3000` is valid only when WorkHub and Hermes run on the same host.

## Register Hermes

```powershell
.\scripts\install.ps1
```

The installer does all of the following:

1. Calls authenticated WorkHub `health`.
2. Verifies `workhub-hermes-v1` and exactly 32 tools.
3. Replaces the local `workhub` MCP registration in the configured WSL Hermes profile.
4. Runs `hermes mcp test workhub`.

Start a new Hermes session after the command completes.

## Diagnose Before Feishu Writes

```powershell
.\scripts\doctor.ps1
```

Do not allow write tests until Doctor passes. It verifies the WorkHub endpoint with the configured token and Hermes tool discovery.

## Feishu Acceptance

Use the prompts in [acceptance-prompts.md](acceptance-prompts.md). The first Feishu check must return raw JSON from the WorkHub health tool.

The Feishu bot is connected correctly only if it returns:

```text
service: workhub-hermes-v1
tools: 32 entries
```

## Upgrade

1. Back up WorkHub data.
2. Upgrade WorkHub to an approved revision and restart it.
3. Pull the approved Bridge revision.
4. Run `npm.cmd ci` if `package-lock.json` changed.
5. Run `.\scripts\doctor.ps1`.
6. Run the read-only Feishu acceptance prompt before enabling writes.

## Rollback

1. Stop the affected WorkHub or Bridge runtime.
2. Return to the previously approved Git revision.
3. Restart WorkHub.
4. Run `.\scripts\doctor.ps1`.
5. Restore a WorkHub database backup only when a data or schema rollback is required.

## AI Handover Instruction

```text
Read README.md, docs/company-deployment.md, docs/hermes-skill.md, and docs/acceptance-prompts.md before taking action.
Never commit or reveal tokens, config/bridge.env, Hermes config, Feishu credentials, or WorkHub data.
Do not modify WorkHub MCP semantics during deployment.
Do not claim Feishu is connected until the Feishu bot itself returns raw workhub-hermes-v1 health JSON with 32 tools.
```
