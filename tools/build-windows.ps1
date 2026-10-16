# Run with PowerShell 7 from the repository root.
param([switch]$SkipChecks)
$ErrorActionPreference = 'Stop'
$taskRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location -LiteralPath $taskRoot
if (-not $SkipChecks) {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
    flutter analyze --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Static analysis failed.' }
    flutter test --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Tests failed.' }
}
flutter build windows --release --no-pub
if ($LASTEXITCODE -ne 0) { throw 'Windows build failed.' }
$source = Join-Path $taskRoot 'build/windows/x64/runner/Release'
$destination = Join-Path $taskRoot 'dist/SMT-CHECK-windows'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $source 'SMT-CHECK.exe') -Destination $destination -Force
Get-ChildItem -LiteralPath $source -Filter '*.dll' | Copy-Item -Destination $destination -Force
Copy-Item -LiteralPath (Join-Path $source 'data') -Destination $destination -Recurse -Force
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
if (Test-Path -LiteralPath $vswhere) {
    $installation = & $vswhere -latest -products '*' -property installationPath
    $redist = Get-ChildItem -Path (Join-Path $installation 'VC/Redist/MSVC/*/x64/Microsoft.VC*.CRT') -Directory -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1
    if ($redist) { Get-ChildItem -LiteralPath $redist.FullName -Filter '*.dll' | Copy-Item -Destination $destination -Force }
}
if (-not (Test-Path -LiteralPath (Join-Path $destination 'vcruntime140.dll')) -or
    -not (Test-Path -LiteralPath (Join-Path $destination 'msvcp140.dll'))) {
    throw 'MSVC runtime DLLs are missing from the package.'
}
Copy-Item -LiteralPath (Join-Path $taskRoot 'README.md') -Destination $destination -Force
$archive = Join-Path $taskRoot 'dist/SMT-CHECK-windows.zip'
Compress-Archive -Path $destination -DestinationPath $archive -Force
$checksum = Get-FileHash -LiteralPath $archive -Algorithm SHA256
"$($checksum.Hash.ToLowerInvariant())  $([IO.Path]::GetFileName($archive))" | Set-Content -LiteralPath "$archive.sha256" -Encoding utf8NoBOM
Write-Host "Desktop package: $archive"
