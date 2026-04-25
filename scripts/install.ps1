$ErrorActionPreference = "Stop"

$RootDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ConfigDir = Join-Path $HOME ".config/opencode"
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupDir = Join-Path $ConfigDir "backups/wonder-mountain-$Timestamp"
$PackageDir = Join-Path $ConfigDir "wonder-mountain"
$TargetSkillsDir = Join-Path $ConfigDir "skills"

if (-not (Test-Path -Path $ConfigDir -PathType Container)) {
    Write-Error "未找到默认 OpenCode 配置目录 ~/.config/opencode。请在飞书联系维护者处理。"
    exit 1
}

New-Item -ItemType Directory -Force -Path $BackupDir, $PackageDir, $TargetSkillsDir | Out-Null

$OpenCodeJson = Join-Path $ConfigDir "opencode.json"
if (Test-Path -Path $OpenCodeJson -PathType Leaf) {
    Copy-Item -Path $OpenCodeJson -Destination (Join-Path $BackupDir "opencode.json") -Force
}

$ConfigJson = Join-Path $ConfigDir "config.json"
if (Test-Path -Path $ConfigJson -PathType Leaf) {
    Copy-Item -Path $ConfigJson -Destination (Join-Path $BackupDir "config.json") -Force
}

Copy-Item -Path (Join-Path $RootDir "configs/opencode.example.json") -Destination (Join-Path $PackageDir "opencode.example.json") -Force

Get-ChildItem -Path (Join-Path $RootDir "skills") -Directory | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $TargetSkillsDir -Recurse -Force
}

Write-Host "Wonder Mountain OpenCode files installed."
Write-Host "Config template: $(Join-Path $PackageDir 'opencode.example.json')"
Write-Host "Skills directory: $TargetSkillsDir"
Write-Host "Backup directory: $BackupDir"
