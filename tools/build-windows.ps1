# Run with PowerShell 7 from the repository root.
param([switch]$SkipChecks, [ValidateSet('x64','arm64')][string]$Architecture = 'x64')
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
$source = Join-Path $taskRoot "build/windows/$Architecture/runner/Release"
function Get-PeMachine([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    $offset = [BitConverter]::ToInt32($bytes, 0x3c)
    return [BitConverter]::ToUInt16($bytes, $offset + 4)
}
function Assert-PeArchitecture([string]$Path) {
    $machine = Get-PeMachine $Path
    $expected = if ($Architecture -eq 'arm64') { 0xaa64 } else { 0x8664 }
    if ($machine -ne $expected) { throw "Wrong PE architecture in $Path : $machine (expected $Architecture)" }
}
Assert-PeArchitecture (Join-Path $source 'SMT-CHECK.exe')
# A fresh staging directory prevents stale DLLs or cross-architecture mixtures.
$destination = Join-Path $taskRoot "dist/windows-$Architecture-$([Guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $source 'SMT-CHECK.exe') -Destination $destination -Force
Copy-Item -LiteralPath (Join-Path $source 'smt-fusion-20261017.ico') -Destination $destination -Force
# CMake can copy host CRT files even when compiling for ARM64. Select the
# target CRT exclusively from the architecture-specific Visual Studio redist.
Get-ChildItem -LiteralPath $source -Filter '*.dll' |
    Where-Object { $_.Name -notmatch '^(msvcp|vcruntime|concrt|vccorlib|vcamp)[0-9_].*\.dll$' } |
    Copy-Item -Destination $destination -Force
Copy-Item -LiteralPath (Join-Path $source 'data') -Destination $destination -Recurse -Force
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
if (Test-Path -LiteralPath $vswhere) {
    $installation = & $vswhere -latest -products '*' -property installationPath
    $redist = Get-ChildItem -Path (Join-Path $installation "VC/Redist/MSVC/*/$Architecture/Microsoft.VC*.CRT") -Directory -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1
    if ($redist) {
        $expectedMachine = if ($Architecture -eq 'arm64') { 0xaa64 } else { 0x8664 }
        Get-ChildItem -LiteralPath $redist.FullName -Filter '*.dll' | ForEach-Object {
            # Microsoft's ARM64 directory also contains an x64 compatibility
            # vcruntime140_1.dll. The native ARM64 app must not carry that file.
            if ((Get-PeMachine $_.FullName) -eq $expectedMachine) {
                Copy-Item -LiteralPath $_.FullName -Destination $destination -Force
            } else {
                Write-Host "Skipping non-$Architecture runtime: $($_.Name)"
            }
        }
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $destination 'vcruntime140.dll')) -or
    -not (Test-Path -LiteralPath (Join-Path $destination 'msvcp140.dll'))) {
    throw 'MSVC runtime DLLs are missing from the package.'
}
Copy-Item -LiteralPath (Join-Path $taskRoot 'README.md') -Destination $destination -Force
Get-ChildItem -LiteralPath $destination -Filter '*.dll' | ForEach-Object { Assert-PeArchitecture $_.FullName }
# Check actual imports so preinstalled CI runtimes cannot conceal a missing DLL.
$dumpbin = Get-ChildItem -Path (Join-Path $installation "VC/Tools/MSVC/*/bin/Host*/$Architecture/dumpbin.exe") -File |
    Sort-Object FullName -Descending | Select-Object -First 1
if (-not $dumpbin) { throw 'dumpbin is required to validate packaged runtime dependencies.' }
foreach ($binary in (Get-ChildItem -LiteralPath $destination -File | Where-Object Extension -In '.exe','.dll')) {
    $imports = & $dumpbin.FullName /DEPENDENTS $binary.FullName
    if ($LASTEXITCODE -ne 0) { throw "Cannot inspect imports: $($binary.Name)" }
    foreach ($line in $imports) {
        if ($line -match '^\s*((?:msvcp|vcruntime|concrt|vccorlib|vcamp)\w*\.dll)\s*$' -and
            -not (Test-Path -LiteralPath (Join-Path $destination $Matches[1]))) {
            throw "Missing runtime dependency $($Matches[1]) for $($binary.Name)"
        }
    }
}
Copy-Item -LiteralPath (Join-Path $taskRoot 'assets/fonts/OFL-NotoSansThai.txt') -Destination $destination -Force
$compilerCandidates=@(
    $env:ISCC_PATH,
    (Join-Path $taskRoot '.tools/innosetup/compiler643/ISCC.exe'),
    (Join-Path $taskRoot '.tools/innosetup/compiler/ISCC.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6/ISCC.exe'),
    (Join-Path $env:ProgramFiles 'Inno Setup 6/ISCC.exe')
)
$compiler=$compilerCandidates | Where-Object {$_ -and (Test-Path -LiteralPath $_)} | Select-Object -First 1
if(-not $compiler) { throw 'Inno Setup compiler not found. Set ISCC_PATH or install Inno Setup 6.' }
$versionLine=Get-Content -LiteralPath (Join-Path $taskRoot 'pubspec.yaml') | Where-Object {$_ -match '^version:'} | Select-Object -First 1
$version=(($versionLine -replace '^version:\s*','') -split '\+')[0].Trim()
& $compiler "/DAppVersion=$version" "/DAppArchitecture=$Architecture" "/DPayloadDir=$destination" (Join-Path $taskRoot 'installer/windows.iss')
if($LASTEXITCODE -ne 0) { throw 'Installer compilation failed.' }
$archive = Join-Path $taskRoot "dist/SMT-CHECK-Setup-$Architecture.exe"
$checksum = Get-FileHash -LiteralPath $archive -Algorithm SHA256
"$($checksum.Hash.ToLowerInvariant())  $([IO.Path]::GetFileName($archive))" | Set-Content -LiteralPath "$archive.sha256" -Encoding utf8NoBOM
Write-Host "Desktop package: $archive"
