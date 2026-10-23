param(
    [string] $SdkPath = 'D:\Steam\steamapps\common\XCOM 2 War of the Chosen SDK',
    [string] $GamePath = 'D:\Steam\steamapps\common\XCOM 2\XCom2-WarOfTheChosen',
    [string[]] $Probes = @('TNB_MappingProbeCommandlet'),
    [switch] $All
)

# Offline compile/probes only. Deliberately never calls InvokeBuild/_FinalCopy.
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path $PSScriptRoot -Parent
if ($All) {
    $Probes = @(Get-ChildItem -LiteralPath (Join-Path $projectPath 'TheNameBeneath\Src\TheNameBeneath\Classes') -Filter '*ProbeCommandlet.uc' | Sort-Object Name | ForEach-Object { $_.BaseName })
}
. (Join-Path $PSScriptRoot 'X2ModBuildCommon\build_common.ps1')
$builder = [BuildProject]::new('TheNameBeneath', $projectPath, $SdkPath, $GamePath)
$builder._ConfirmPaths()
$builder._SetupUtils()
$expectedStage = [IO.Path]::GetFullPath((Join-Path $SdkPath 'XComGame\Mods\TheNameBeneath'))
if ([IO.Path]::GetFullPath($builder.stagingPath) -ne $expectedStage) { throw 'Unexpected SDK staging target.' }
if (-not (Test-Path -LiteralPath (Join-Path $SdkPath 'XComGame\Script\XComGame.u'))) { throw 'Precompiled Highlander SDK base packages are required.' }
$builder._LoadContentOptions()
$builder._CopyModToSdk()
$builder._ConvertLocalization()
# Make reads Development/Src, not the staged mod's Src. Do not mirror/delete
# base SDK sources or append global macros again for this incremental build.
Copy-Item -Path (Join-Path $projectPath 'TheNameBeneath\Src\TheNameBeneath\Classes\*.uc') -Destination (Join-Path $SdkPath 'Development\Src\TheNameBeneath\Classes') -Force
# Commandlets don't execute the game's DLC INI merge. Compile an SDK-only child
# fixture mechanically from the exact source rows, then exercise the production
# resolver against those rows. No player config and no test defaults in the mod.
$probeArtifactPath = Join-Path $projectPath 'Artifacts\Mod'
New-Item -ItemType Directory -Path $probeArtifactPath -Force | Out-Null
$fixtureClass = Join-Path $SdkPath 'Development\Src\TheNameBeneath\Classes\TNB_MappingProbeDefaults.uc'
if (Test-Path -LiteralPath $fixtureClass) { throw 'Refusing to overwrite an existing SDK mapping fixture.' }
$fixtureLines = @('class TNB_MappingProbeDefaults extends TNB_MappingProbeCommandlet;', 'defaultproperties', '{')
$rowIndex = 0
foreach ($line in Get-Content -LiteralPath (Join-Path $projectPath 'TheNameBeneath\Config\XComTheNameBeneath.ini')) {
    if ($line -match '^\+ShippedMappings=(.+)$') {
        $fixtureLines += "SourceRows($rowIndex)=$($Matches[1])"
        $rowIndex++
    }
}
if ($rowIndex -lt 25) { throw 'Source mapping fixture is unexpectedly incomplete.' }
$fixtureLines += '}'
[IO.File]::WriteAllLines($fixtureClass, $fixtureLines)

try {
$builder._RunMakeMod()
$builder._CopyScriptPackages()
foreach ($probeName in $Probes) {
    if ($probeName -notmatch '^TNB_[A-Za-z]+ProbeCommandlet$') { throw "Invalid offline probe name: $probeName" }
    $probeProcess = Start-Process -FilePath $builder.commandletHostPath -ArgumentList "run TheNameBeneath.$probeName -nopause -unattended" -WorkingDirectory (Split-Path $builder.commandletHostPath) -WindowStyle Hidden -Wait -PassThru
    $probeLog = Get-Content -LiteralPath (Join-Path $SdkPath 'XComGame\Logs\Launch.log') -Raw
    if ($probeProcess.ExitCode -ne 0 -or $probeLog -match 'Failed to find a commandlet|Crash Detected|Critical:|ScriptWarning:|Script Error:' -or $probeLog -notmatch ('Executing Class TheNameBeneath\.' + [regex]::Escape($probeName)) -or $probeLog -notmatch 'TNB_.*(PASS|CHECKS_PASSED)') {
        throw "$probeName did not pass. Inspect SDK XComGame\Logs\Launch.log (exit $($probeProcess.ExitCode))."
    }
    if ($probeName -eq 'TNB_MappingProbeCommandlet' -and $probeLog -notmatch 'TNB_MAPPING_ALL_CHECKS_PASSED') { throw 'Mapping probe did not reach its final success marker.' }
    Copy-Item -LiteralPath (Join-Path $SdkPath 'XComGame\Logs\Launch.log') -Destination (Join-Path $probeArtifactPath "$probeName.log") -Force
    Write-Host "$probeName passed."
}
} finally {
    # Exact generated SDK fixture only, never a player or retail source/config.
    Remove-Item -LiteralPath $fixtureClass
}
Write-Host 'Offline SDK compile/probes passed. Retail mod and companion were not installed or modified.'
