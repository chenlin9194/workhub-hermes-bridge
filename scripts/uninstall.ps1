param(
  [string]$ConfigPath = (Join-Path $PSScriptRoot "..\config\bridge.env")
)

. (Join-Path $PSScriptRoot "bridge-config.ps1")

$config = Get-BridgeConfig -ConfigPath $ConfigPath
Invoke-HermesWsl -Config $config -Command "hermes mcp remove workhub"
Write-Host "Removed the local Hermes workhub MCP registration. WorkHub data was not changed."
