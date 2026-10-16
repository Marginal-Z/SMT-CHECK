# PowerShell 7. Run after flutter pub get has created .flutter-plugins-dependencies.
$ErrorActionPreference = 'Stop'
$taskRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$metadata = Get-Content -LiteralPath (Join-Path $taskRoot '.flutter-plugins-dependencies') -Raw | ConvertFrom-Json
foreach ($platform in @('windows', 'linux')) {
    $linkRoot = Join-Path $taskRoot "$platform/flutter/ephemeral/.plugin_symlinks"
    New-Item -ItemType Directory -Path $linkRoot -Force | Out-Null
    foreach ($plugin in $metadata.plugins.$platform) {
        $linkPath = Join-Path $linkRoot $plugin.name
        if (-not (Test-Path -LiteralPath $linkPath)) {
            New-Item -ItemType Junction -Path $linkPath -Target $plugin.path | Out-Null
        }
    }
}
