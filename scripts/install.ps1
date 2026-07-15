param(
  [string]$ConfigPath = (Join-Path $PSScriptRoot "..\config\bridge.env")
)

. (Join-Path $PSScriptRoot "bridge-config.ps1")

$config = Get-BridgeConfig -ConfigPath $ConfigPath
$health = Test-WorkHubHealth -Config $config
$transport = (Get-ConfigValueOrDefault -Config $config -Name "HERMES_MCP_TRANSPORT" -DefaultValue "stdio").ToLowerInvariant()

Invoke-HermesWsl -Config $config -Command "hermes mcp remove workhub 2>/dev/null || true"

if ($transport -eq "stdio") {
  $bridgePath = ConvertTo-WslPath -WindowsPath (Split-Path -Parent $PSScriptRoot)
  $serverPath = "$bridgePath/scripts/hermes-workhub-mcp.mjs"
  $baseUrl = Get-RequiredConfigValue -Config $config -Name "WORKHUB_BASE_URL"
  $token = Get-RequiredConfigValue -Config $config -Name "HERMES_WORKHUB_TOKEN"
  $registerCommand = "printf 'Y\\n' | hermes mcp add workhub --command node --env WORKHUB_BASE_URL=$(ConvertTo-BashSingleQuoted $baseUrl) HERMES_WORKHUB_TOKEN=$(ConvertTo-BashSingleQuoted $token) --args $(ConvertTo-BashSingleQuoted $serverPath)"
} elseif ($transport -eq "http") {
  $url = Get-ConfigValueOrDefault -Config $config -Name "HERMES_WORKHUB_MCP_URL" -DefaultValue "http://127.0.0.1:3001/mcp"
  $registerCommand = "printf 'n\\nY\\n' | hermes mcp add workhub --url $(ConvertTo-BashSingleQuoted $url)"
} else {
  throw "HERMES_MCP_TRANSPORT must be stdio or http; received '$transport'."
}

Invoke-HermesWsl -Config $config -Command $registerCommand
Invoke-HermesWsl -Config $config -Command "hermes mcp test workhub"

Write-Host "Installed WorkHub MCP V1.0 with $transport transport. WorkHub service: $($health.service); tools: $($health.tools.Count)."
Write-Host "Start a new Hermes session before testing Feishu."
