param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]] $RemainingArgs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-ScriptPath {
  param([string] $ScriptPath)

  if (-not $ScriptPath) {
    throw "Unable to resolve launcher path."
  }

  $scriptPath = $ScriptPath
  $item = Get-Item -LiteralPath $scriptPath
  while ($item.LinkType) {
    $target = $item.Target
    if ($target -is [array]) {
      $target = $target[0]
    }

    if (-not [System.IO.Path]::IsPathRooted($target)) {
      $target = Join-Path $item.DirectoryName $target
    }

    $item = Get-Item -LiteralPath $target
  }

  $item.FullName
}

function Quote-LaunchArg {
  param([string] $Value)

  if ($Value -match '^[A-Za-z0-9_./:=@+\-\\]+$') {
    return $Value
  }

  return '"' + ($Value -replace '"', '\"') + '"'
}

function Show-Usage {
  @"
Usage: compass.ps1 [advanced] [--print-launch] [claude args...]

Start a Claude Code Compass session from this plugin checkout.

Commands:
  advanced        Start with compass-advanced-orchestrator.
  --print-launch Print the Claude command instead of executing it.
"@
}

$scriptFile = Resolve-ScriptPath -ScriptPath $PSCommandPath
$compassDir = Split-Path -Parent (Split-Path -Parent $scriptFile)
$agent = "compass-orchestrator"
$compassLabel = "Compass"
$argsList = [System.Collections.Generic.List[string]]::new()
foreach ($arg in @($RemainingArgs)) {
  $argsList.Add($arg)
}

if ($argsList.Count -gt 0 -and $argsList[0] -eq "advanced") {
  $agent = "compass-advanced-orchestrator"
  $compassLabel = "Compass advanced"
  $argsList.RemoveAt(0)
}

$powerShellCommand = if ($PSVersionTable.PSEdition -eq "Core") { "pwsh" } else { "powershell" }
$statusLinePath = (Join-Path $compassDir "scripts/compass-statusline.ps1") -replace '\\', '/'
$statusLineSettings = @{
  statusLine = @{
    type = "command"
    command = "$powerShellCommand -NoProfile -File `"$statusLinePath`""
    refreshInterval = 5
  }
} | ConvertTo-Json -Compress

if ($argsList.Count -gt 0 -and ($argsList[0] -eq "-h" -or $argsList[0] -eq "--help")) {
  Show-Usage
  exit 0
}

if ($argsList.Count -gt 0 -and $argsList[0] -eq "--print-launch") {
  $argsList.RemoveAt(0)
  $parts = @(
    "claude",
    "--plugin-dir",
    (Quote-LaunchArg $compassDir),
    "--agent",
    (Quote-LaunchArg "compass:$agent"),
    "--settings",
    (Quote-LaunchArg $statusLineSettings)
  )

  foreach ($arg in $argsList) {
    $parts += Quote-LaunchArg $arg
  }

  $parts -join " "
  exit 0
}

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
  Write-Error "Claude Code CLI not found on PATH: claude"
  exit 127
}

$extraArgs = $argsList.ToArray()
$env:COMPASS_CLAUDE_LABEL = $compassLabel
& claude --plugin-dir $compassDir --agent "compass:$agent" --settings $statusLineSettings @extraArgs
exit $LASTEXITCODE
