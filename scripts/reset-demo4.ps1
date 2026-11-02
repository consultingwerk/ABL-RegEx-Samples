<#
    Live Demo 4 - "Turning Variables into Properties"

    Empties src/modern, the target folder of src/demo/refactor.p.
    src/classic (the input) is never touched.

    Usage (from anywhere):  powershell -ExecutionPolicy Bypass -File scripts\reset-demo4.ps1
#>
$ErrorActionPreference = 'Stop'
$root   = Split-Path -Parent $PSScriptRoot
$target = Join-Path $root 'src\modern'

New-Item -ItemType Directory -Force $target | Out-Null
Get-ChildItem $target -File | Where-Object { $_.Extension -in '.cls', '.r' } | Remove-Item -Force

Write-Host "Demo 4 reset: $target is empty"
