$ErrorActionPreference = "SilentlyContinue"

try {
  $statusInput = ($input | Out-String) | ConvertFrom-Json
} catch {
  Write-Output "Compass"
  exit 0
}

$label = $env:COMPASS_CLAUDE_LABEL
if (-not $label) {
  $label = "Compass"
}

$model = $statusInput.model.display_name
if (-not $model) {
  $model = "Claude"
}

$effort = $statusInput.effort.level
if ($effort) {
  $modelSegment = "$model/$effort"
} else {
  $modelSegment = $model
}

$remaining = $statusInput.context_window.remaining_percentage
if ($null -ne $remaining) {
  $remaining = [Math]::Floor([double] $remaining)
  $remaining = [Math]::Max(0, [Math]::Min(100, $remaining))
  $filled = [Math]::Floor($remaining * 10 / 100)
  $bar = ("=" * $filled) + ("-" * (10 - $filled))
  $contextSegment = "ctx [$bar] $remaining% left"
} else {
  $contextSegment = "ctx [----------] --"
}

$branch = $null
if (Get-Command git -ErrorAction SilentlyContinue) {
  $branch = (& git symbolic-ref --quiet --short HEAD 2>$null)
  if (-not $branch) {
    $branch = (& git rev-parse --short HEAD 2>$null)
  }
}

$segments = @($label, $modelSegment, $contextSegment)
if ($branch) {
  $segments += $branch
}

Write-Output ($segments -join " · ")
