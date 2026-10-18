[CmdletBinding()]
param(
    [string]$Version = '2.1.0',
    [string]$RustRoot = 'D:\Rust'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$releaseDirectory = Join-Path $projectRoot 'build\windows\x64\runner\Release'
$stageDirectory = Join-Path $projectRoot 'build\portable-stage'
$zipPath = Join-Path $projectRoot "build\JANUS-v$Version-windows-x64.zip"
$portablePath = Join-Path $projectRoot "build\JANUS-v$Version-portable.exe"
$launcherProject = Join-Path $projectRoot 'launcher\Cargo.toml'
$launcherStub = Join-Path $projectRoot 'launcher\target\release\janus-launcher.exe'

$required = @(
    (Join-Path $releaseDirectory 'JANUS.exe'),
    (Join-Path $releaseDirectory 'janus-core.exe'),
    (Join-Path $releaseDirectory 'data\app.so')
)
foreach ($path in $required) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Release artifact missing: $path. Build the Windows app first."
    }
}

$cargo = Join-Path $RustRoot 'cargo\bin\cargo.exe'
if (-not (Test-Path -LiteralPath $cargo)) {
    $cargoCommand = Get-Command cargo -ErrorAction SilentlyContinue
    if ($null -eq $cargoCommand) {
        throw 'Cargo was not found. Pass -RustRoot or add cargo to PATH.'
    }
    $cargo = $cargoCommand.Source
}

# Stage only runtime files. Linker artifacts (.lib/.exp) and Flutter metadata
# are deliberately excluded from both the ZIP and the single-file payload.
if (Test-Path -LiteralPath $stageDirectory) {
    Remove-Item -LiteralPath $stageDirectory -Recurse -Force
}
New-Item -ItemType Directory -Path $stageDirectory | Out-Null
foreach ($name in @(
    'JANUS.exe',
    'janus-core.exe',
    'flutter_windows.dll',
    'file_selector_windows_plugin.dll'
)) {
    Copy-Item -LiteralPath (Join-Path $releaseDirectory $name) -Destination $stageDirectory
}
Copy-Item -LiteralPath (Join-Path $releaseDirectory 'data') -Destination $stageDirectory -Recurse

Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}
[System.IO.Compression.ZipFile]::CreateFromDirectory(
    $stageDirectory,
    $zipPath,
    [System.IO.Compression.CompressionLevel]::Optimal,
    $false
)

$cargoArguments = @('build', '--release', '--manifest-path', $launcherProject)
& $cargo @cargoArguments
if ($LASTEXITCODE -ne 0) {
    throw "Launcher build failed with exit code $LASTEXITCODE."
}
if (-not (Test-Path -LiteralPath $launcherStub)) {
    throw "Launcher executable missing: $launcherStub"
}

Copy-Item -LiteralPath $launcherStub -Destination $portablePath -Force
$zipBytes = [System.IO.File]::ReadAllBytes($zipPath)
$stream = [System.IO.File]::Open(
    $portablePath,
    [System.IO.FileMode]::Append,
    [System.IO.FileAccess]::Write
)
try {
    $stream.Write($zipBytes, 0, $zipBytes.Length)
    $magic = [System.Text.Encoding]::ASCII.GetBytes('JANUSPAK')
    $stream.Write($magic, 0, $magic.Length)
    $lengthBytes = [System.BitConverter]::GetBytes([uint64]$zipBytes.Length)
    $stream.Write($lengthBytes, 0, $lengthBytes.Length)
}
finally {
    $stream.Dispose()
}

$zipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
$portableHash = (Get-FileHash -LiteralPath $portablePath -Algorithm SHA256).Hash.ToLowerInvariant()
$checksumPath = Join-Path $projectRoot 'build\SHA256SUMS.txt'
@(
    "$zipHash  $([IO.Path]::GetFileName($zipPath))",
    "$portableHash  $([IO.Path]::GetFileName($portablePath))"
) | Set-Content -LiteralPath $checksumPath -Encoding ascii

$zip = Get-Item -LiteralPath $zipPath
$portable = Get-Item -LiteralPath $portablePath
Write-Host "Payload ZIP: $zipPath ($([math]::Round($zip.Length / 1MB, 2)) MiB)" -ForegroundColor Green
Write-Host "Single EXE:  $portablePath ($([math]::Round($portable.Length / 1MB, 2)) MiB)" -ForegroundColor Green
Write-Host "Checksums:   $checksumPath"
Write-Host "SHA256 ZIP:  $zipHash"
Write-Host "SHA256 EXE:  $portableHash"
