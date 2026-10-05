$ErrorActionPreference = 'Stop'

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,

        [Parameter(Mandatory = $true)]
        [string[]] $Arguments
    )

    Write-Host "> $Name $($Arguments -join ' ')"
    & $Name @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "'$Name' failed with exit code $LASTEXITCODE."
    }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

Invoke-CheckedCommand -Name 'flutter' -Arguments @('pub', 'get', '--enforce-lockfile')
Invoke-CheckedCommand -Name 'dart' -Arguments @('format', '--output=none', '--set-exit-if-changed', 'lib', 'test')
Invoke-CheckedCommand -Name 'flutter' -Arguments @('analyze')
Invoke-CheckedCommand -Name 'flutter' -Arguments @('test')

if ($env:PLANACT_SKIP_ANDROID_BUILD -ine 'true') {
    $buildName = if ([string]::IsNullOrEmpty($env:PLANACT_BUILD_NAME)) { 'ci' } else { $env:PLANACT_BUILD_NAME }
    $buildNumber = if ([string]::IsNullOrEmpty($env:PLANACT_BUILD_NUMBER)) { '1' } else { $env:PLANACT_BUILD_NUMBER }

    Invoke-CheckedCommand -Name 'flutter' -Arguments @(
        'build',
        'appbundle',
        '--release',
        "--build-name=$buildName",
        "--build-number=$buildNumber"
    )
}
