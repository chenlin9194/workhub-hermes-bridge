param(
  [string]$ConfigPath = (Join-Path $PSScriptRoot "..\config\bridge.env")
)

. (Join-Path $PSScriptRoot "bridge-config.ps1")

$config = Get-BridgeConfig -ConfigPath $ConfigPath
$health = Test-WorkHubHealth -Config $config
Write-Host "WorkHub health: $($health.service), $($health.tools.Count) tools."
Invoke-HermesWsl -Config $config -Command "hermes mcp test workhub"
Write-Host "Doctor completed successfully. Verify the Feishu bot with the raw health prompt next."
