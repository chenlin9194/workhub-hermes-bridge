param(
  [string]$ConfigPath = (Join-Path $PSScriptRoot "..\config\bridge.env")
)

. (Join-Path $PSScriptRoot "bridge-config.ps1")

$config = Get-BridgeConfig -ConfigPath $ConfigPath
$health = Test-WorkHubHealth -Config $config
$bridgePath = ConvertTo-WslPath -WindowsPath (Split-Path -Parent $PSScriptRoot)
$serverPath = "$bridgePath/scripts/hermes-workhub-mcp.mjs"
$baseUrl = Get-RequiredConfigValue -Config $config -Name "WORKHUB_BASE_URL"
$token = Get-RequiredConfigValue -Config $config -Name "HERMES_WORKHUB_TOKEN"

Invoke-HermesWsl -Config $config -Command "hermes mcp remove workhub 2>/dev/null || true"

$registerCommand = "printf 'Y\\n' | hermes mcp add workhub --command node --args $(ConvertTo-BashSingleQuoted $serverPath) --env WORKHUB_BASE_URL=$(ConvertTo-BashSingleQuoted $baseUrl) HERMES_WORKHUB_TOKEN=$(ConvertTo-BashSingleQuoted $token)"
Invoke-HermesWsl -Config $config -Command $registerCommand
Invoke-HermesWsl -Config $config -Command "hermes mcp test workhub"

Write-Host "Installed WorkHub MCP V1.0. WorkHub service: $($health.service); tools: $($health.tools.Count)."
Write-Host "Start a new Hermes session before testing Feishu."
