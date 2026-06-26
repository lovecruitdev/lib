param(
    [switch]$KillRoblox
)

$ErrorActionPreference = "SilentlyContinue"

if ($KillRoblox) {
    Get-Process -Name "RobloxPlayerBeta", "RobloxStudioBeta" | Stop-Process -Force
}

$paths = @(
    Join-Path $env:LOCALAPPDATA "Roblox\logs",
    Join-Path $env:LOCALAPPDATA "Roblox\http",
    Join-Path $env:LOCALAPPDATA "Roblox\Downloads",
    Join-Path $env:TEMP "Roblox"
)

$freedBytes = 0

foreach ($path in $paths) {
    if (-not (Test-Path -LiteralPath $path)) {
        continue
    }

    Get-ChildItem -LiteralPath $path -Recurse -Force | ForEach-Object {
        if (-not $_.PSIsContainer) {
            $freedBytes += $_.Length
        }
    }

    Get-ChildItem -LiteralPath $path -Force | Remove-Item -Recurse -Force
}

[GC]::Collect()
[GC]::WaitForPendingFinalizers()

$freedMb = [Math]::Round($freedBytes / 1MB, 2)
Write-Host "Roblox cleanup finished. Approx freed: $freedMb MB"
Write-Host "If Roblox was open and not cleaned fully, run: powershell -ExecutionPolicy Bypass -File .\roblox_cleanup.ps1 -KillRoblox"
