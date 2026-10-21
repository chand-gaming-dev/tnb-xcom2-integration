[CmdletBinding()]
param([switch]$Development, [switch]$CheckOnly, [string]$DevelopmentConfig)
$ErrorActionPreference = 'Stop'
$solutionDirectory = Split-Path $PSScriptRoot -Parent
$executable = Join-Path $solutionDirectory 'Artifacts\Companion\ThreadlineCompanion.exe'
if (-not (Test-Path -LiteralPath $executable)) { throw 'Build the companion first with .scripts\Build-Companion.ps1.' }
$launchArguments = @()
if ($Development) {
    # Use an explicit private file or the ignored local example copy. Never print it.
    if (-not $DevelopmentConfig) { $DevelopmentConfig = Join-Path $solutionDirectory '.env.local' }
    if (-not (Test-Path -LiteralPath $DevelopmentConfig -PathType Leaf)) { throw 'Private development configuration missing. Copy .env.example to .env.local, or pass -DevelopmentConfig.' }
    $launchArguments += @('--dev-config', (Resolve-Path -LiteralPath $DevelopmentConfig).Path)
} elseif ($DevelopmentConfig) {
    throw '-DevelopmentConfig requires -Development.'
}
if ($CheckOnly) {
    if (-not $Development) { throw '-CheckOnly requires -Development for the read-only connection check.' }
    $launchArguments += '--check-development-connection'
}
# Piping waits for the Windows GUI executable and preserves redacted diagnostic output.
# Close the companion window to stop it. No Windows service is installed.
& $executable @launchArguments | Out-Host
if ($LASTEXITCODE -ne 0) { throw 'Companion exited with an error; see its redacted status above.' }
