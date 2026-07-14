Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-BridgeConfig {
  param([Parameter(Mandatory)][string]$ConfigPath)

  if (-not (Test-Path -LiteralPath $ConfigPath)) {
    throw "Bridge config not found: $ConfigPath. Copy config/bridge.env.example to config/bridge.env first."
  }

  $config = @{}
  foreach ($line in Get-Content -LiteralPath $ConfigPath) {
    $trimmed = $line.Trim()
    if (-not $trimmed -or $trimmed.StartsWith("#")) { continue }
    if ($trimmed -notmatch "^([^=]+)=(.*)$") {
      throw "Invalid config line in ${ConfigPath}: $line"
    }

    $key = $matches[1].Trim()
    $value = $matches[2].Trim()
    if ($value.Length -ge 2 -and (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'")))) {
      $value = $value.Substring(1, $value.Length - 2)
    }
    $config[$key] = $value
  }

  return $config
}

function Get-RequiredConfigValue {
  param(
    [Parameter(Mandatory)][hashtable]$Config,
    [Parameter(Mandatory)][string]$Name
  )

  if (-not $Config.ContainsKey($Name) -or [string]::IsNullOrWhiteSpace($Config[$Name]) -or $Config[$Name] -like "replace-with-*") {
    throw "Set $Name in config/bridge.env before continuing."
  }

  return $Config[$Name]
}

function ConvertTo-BashSingleQuoted {
  param([Parameter(Mandatory)][string]$Value)
  $escapedQuote = "'`"'`"'"
  return "'" + $Value.Replace("'", $escapedQuote) + "'"
}

function ConvertTo-WslPath {
  param([Parameter(Mandatory)][string]$WindowsPath)

  $fullPath = [System.IO.Path]::GetFullPath($WindowsPath)
  if ($fullPath -notmatch "^([A-Za-z]):\\(.*)$") {
    throw "Cannot convert this path to a WSL path: $fullPath"
  }

  return "/mnt/" + $matches[1].ToLowerInvariant() + "/" + $matches[2].Replace("\", "/")
}

function Invoke-HermesWsl {
  param(
    [Parameter(Mandatory)][hashtable]$Config,
    [Parameter(Mandatory)][string]$Command
  )

  $distro = Get-RequiredConfigValue -Config $Config -Name "HERMES_WSL_DISTRO"
  $user = Get-RequiredConfigValue -Config $Config -Name "HERMES_WSL_USER"
  & wsl.exe -d $distro -u $user sh -lc $Command
  if ($LASTEXITCODE -ne 0) {
    throw "Hermes WSL command failed with exit code $LASTEXITCODE."
  }
}

function Test-WorkHubHealth {
  param([Parameter(Mandatory)][hashtable]$Config)

  $baseUrl = (Get-RequiredConfigValue -Config $Config -Name "WORKHUB_BASE_URL").TrimEnd("/")
  $token = Get-RequiredConfigValue -Config $Config -Name "HERMES_WORKHUB_TOKEN"
  $expectedCountText = Get-RequiredConfigValue -Config $Config -Name "WORKHUB_EXPECTED_TOOL_COUNT"
  $expectedCount = [int]$expectedCountText
  $headers = @{ Authorization = "Bearer $token" }

  $response = Invoke-RestMethod `
    -Uri "$baseUrl/api/integrations/hermes/workhub" `
    -Method Post `
    -Headers $headers `
    -ContentType "application/json" `
    -Body '{"tool":"health"}'

  if (-not $response.ok -or $response.service -ne "workhub-hermes-v1") {
    throw "WorkHub health check did not return workhub-hermes-v1. Check the WorkHub deployment and token."
  }
  if ($response.tools.Count -ne $expectedCount) {
    throw "WorkHub reported $($response.tools.Count) tools; expected $expectedCount. WorkHub and Bridge versions are not compatible."
  }

  return $response
}
