[CmdletBinding()]
param([switch]$TestOnly)
$ErrorActionPreference = 'Stop'
$solutionDirectory = Split-Path $PSScriptRoot -Parent
$project = Join-Path $solutionDirectory 'Companion\ThreadlineCompanion\ThreadlineCompanion.csproj'
dotnet run --project $project -- --self-test
if ($LASTEXITCODE -ne 0) { throw 'Companion tests failed.' }
dotnet run --project $project -- --ui-self-test
if ($LASTEXITCODE -ne 0) { throw 'Companion UI tests failed.' }
dotnet run --project $project -- --pool-self-test
if ($LASTEXITCODE -ne 0) { throw 'Character Pool tests failed.' }
dotnet run --project $project -- --event-self-test
if ($LASTEXITCODE -ne 0) { throw 'Companion event tests failed.' }
if (-not $TestOnly) {
    dotnet publish $project -p:PublishProfile=Win64 -o (Join-Path $solutionDirectory 'Artifacts\Companion')
    if ($LASTEXITCODE -ne 0) { throw 'Companion publication failed.' }
}
