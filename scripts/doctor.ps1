$ErrorActionPreference = "Stop"

$RootDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ConfigDir = Join-Path $HOME ".config/opencode"
$Status = "READY"

function Report($Level, $Message) {
    Write-Host "[$Level] $Message"
}

function Block($Message) {
    $script:Status = "BLOCKED"
    Report "BLOCKED" $Message
}

function Warn($Message) {
    if ($script:Status -ne "BLOCKED") {
        $script:Status = "WARN"
    }
    Report "WARN" $Message
}

function Ok($Message) {
    Report "OK" $Message
}

Write-Host "Wonder Mountain OpenCode environment check"
Write-Host "Repository: $RootDir"
Write-Host "OpenCode directory: $ConfigDir"
Write-Host ""

if (Test-Path -Path $ConfigDir -PathType Container) {
    Ok "Default OpenCode directory exists."
} else {
    Block "Missing ~/.config/opencode. Contact the maintainer on Feishu; do not guess another path."
}

$OpenCodeJson = Join-Path $ConfigDir "opencode.json"
if (Test-Path -Path $OpenCodeJson -PathType Leaf) {
    Ok "Existing opencode.json found; install will back it up and will not merge it automatically."
} else {
    Warn "No opencode.json found under ~/.config/opencode."
}

$SkillsDir = Join-Path $ConfigDir "skills"
if (Test-Path -Path $SkillsDir -PathType Container) {
    Ok "OpenCode skills directory exists."
} else {
    Warn "OpenCode skills directory is missing; install script will create it if the config directory exists."
}

$PackageDir = Join-Path $ConfigDir "wonder-mountain"
if (Test-Path -Path $PackageDir -PathType Container) {
    Warn "Wonder Mountain package directory already exists and may be overwritten by install."
} else {
    Ok "Wonder Mountain package directory is not installed yet."
}

$TemplatePath = Join-Path $RootDir "configs/opencode.example.json"
if (Test-Path -Path $TemplatePath -PathType Leaf) {
    Ok "Repository config template exists."
} else {
    Block "Missing configs/opencode.example.json in this repository."
}

$RepoSkillsDir = Join-Path $RootDir "skills"
if (Test-Path -Path $RepoSkillsDir -PathType Container) {
    $SkillDirs = Get-ChildItem -Path $RepoSkillsDir -Directory
    if ($SkillDirs.Count -eq 0) {
        Warn "No vendored skill directories found under repository skills/."
    }
    foreach ($SkillDir in $SkillDirs) {
        $SkillFile = Join-Path $SkillDir.FullName "SKILL.md"
        if (Test-Path -Path $SkillFile -PathType Leaf) {
            Ok "Skill package present: skills/$($SkillDir.Name)/SKILL.md"
        } else {
            Block "Skill directory missing SKILL.md: skills/$($SkillDir.Name)"
        }
    }
} else {
    Block "Missing repository skills directory."
}

Write-Host ""
Write-Host "Result: $Status"

if ($Status -eq "BLOCKED") {
    exit 1
}
