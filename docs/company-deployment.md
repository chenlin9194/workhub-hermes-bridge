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
HERMES_MCP_TRANSPORT=stdio
WORKHUB_EXPECTED_TOOL_COUNT=32
```

`WORKHUB_BASE_URL=http://127.0.0.1:3000` is valid only when WorkHub and Hermes run on the same host.

## stdio Mode (default)

Use this on any computer where Hermes can complete actual MCP tool calls through stdio. The Bridge is executed from the Windows checkout through WSL, so no long-running local service is required.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

## HTTP Mode for stdio Lifecycle Issues

Use HTTP only when a real Hermes or Feishu tool call fails through stdio with a session-lifecycle error such as `ClosedResourceError`. Tool discovery alone is not enough to make this decision.

HTTP mode keeps the Bridge local: it binds only to `127.0.0.1:3001`, while WorkHub continues to use `127.0.0.1:3000`.

1. In the Windows checkout, set the following private configuration values:

```text
HERMES_MCP_TRANSPORT=http
HERMES_WORKHUB_MCP_URL=http://127.0.0.1:3001/mcp
HERMES_WORKHUB_MCP_HOST=127.0.0.1
HERMES_WORKHUB_MCP_PORT=3001
```

2. Create a Linux-native WSL checkout. Do not run the HTTP service from `/mnt/<drive>` because Node module loading can be unreliable there:

```bash
mkdir -p ~/workhub-hermes-bridge
git clone <your-bridge-repository-url> ~/workhub-hermes-bridge
cd ~/workhub-hermes-bridge
npm ci
```

3. Copy `config/bridge.env` to that Linux-native checkout privately, preserving its contents and restrictive permissions. Do not commit this file.

4. Run the HTTP server with the Node runtime used by Hermes. For a first manual check:

```bash
cd ~/workhub-hermes-bridge
set -a && . ./config/bridge.env && set +a
npm run mcp:http
```

5. In a second terminal, register HTTP mode and test discovery:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\doctor.ps1
```

For a persistent deployment, run the command in step 4 with your WSL user service manager. The service must use the same Node runtime as Hermes, keep `WorkingDirectory` in the Linux-native checkout, load the private `bridge.env`, and restart on failure.

## Register Hermes

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

The installer reads `HERMES_MCP_TRANSPORT` and does all of the following:

1. Calls authenticated WorkHub `health`.
2. Verifies `workhub-hermes-v1` and exactly 32 tools.
3. Replaces the local `workhub` MCP registration in the configured WSL Hermes profile, using either stdio or the loopback HTTP URL.
4. Runs `hermes mcp test workhub`.

Start a new Hermes session after the command completes.

## Diagnose Before Feishu Writes

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\doctor.ps1
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
3. Pull the approved Bridge revision in the checkout used by that computer. For HTTP mode, pull both the Windows checkout and the Linux-native WSL checkout.
4. Run `npm.cmd ci` in Windows and `npm ci` in the Linux-native WSL checkout if `package-lock.json` changed.
5. Restart the HTTP service only on computers configured for HTTP mode.
6. Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\doctor.ps1`.
7. Run the read-only Feishu acceptance prompt before enabling writes.

## Rollback

1. Stop the affected WorkHub or Bridge runtime.
2. Return to the previously approved Git revision.
3. Restart WorkHub.
4. Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\doctor.ps1`.
5. Restore a WorkHub database backup only when a data or schema rollback is required.

## AI Handover Instruction

```text
Read README.md, docs/company-deployment.md, docs/hermes-skill.md, and docs/acceptance-prompts.md before taking action.
Never commit or reveal tokens, config/bridge.env, Hermes config, Feishu credentials, or WorkHub data.
Do not modify WorkHub MCP semantics during deployment.
Keep `HERMES_MCP_TRANSPORT=stdio` on a working stdio computer. Use HTTP only for a verified stdio lifecycle issue, and never expose the HTTP bridge beyond loopback.
Do not claim Feishu is connected until the Feishu bot itself returns raw workhub-hermes-v1 health JSON with 32 tools.
```
