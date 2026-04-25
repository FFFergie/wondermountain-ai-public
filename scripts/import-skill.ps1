$ErrorActionPreference = "Stop"

$RootDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

if ($args.Count -gt 0) {
    $OriginalCommand = $args -join " "
} else {
    Write-Host "Paste the original skills.sh command, then press Enter:"
    Write-Host "Example: npx skills add https://github.com/vercel-labs/skills --skill find-skills"
    $OriginalCommand = Read-Host ">"
}

if ([string]::IsNullOrWhiteSpace($OriginalCommand)) {
    Write-Error "No command provided."
    exit 1
}

$Parts = $OriginalCommand.Trim() -split "\s+"

if ($Parts.Count -lt 3 -or $Parts[0] -ne "npx" -or $Parts[1] -ne "skills" -or $Parts[2] -ne "add") {
    Write-Error "Command must start with: npx skills add"
    exit 1
}

$Source = ""
$SkillName = ""

for ($i = 3; $i -lt $Parts.Count; $i++) {
    $Part = $Parts[$i]
    if ($Part -in @("-a", "--agent", "-g", "--global")) {
        Write-Error "Do not include $Part. This script always imports into ./skills with -a openclaw."
        exit 1
    } elseif ($Part -in @("--skill", "-s")) {
        if (($i + 1) -ge $Parts.Count) {
            Write-Error "$Part requires a skill name."
            exit 1
        }
        $SkillName = $Parts[$i + 1]
        $i++
    } elseif ($Part.StartsWith("--skill=")) {
        $SkillName = $Part.Substring("--skill=".Length)
    } elseif ($Part.StartsWith("-s=")) {
        $SkillName = $Part.Substring("-s=".Length)
    } elseif ($Part.StartsWith("--")) {
        Write-Error "Unsupported option: $Part"
        exit 1
    } elseif ([string]::IsNullOrEmpty($Source)) {
        $Source = $Part
    }
}

if ([string]::IsNullOrWhiteSpace($Source)) {
    Write-Error "Missing skill source after: npx skills add"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($SkillName)) {
    Write-Error "Missing --skill <name> or -s <name>."
    exit 1
}

if ($SkillName.Contains("/") -or $SkillName.Contains("\")) {
    Write-Error "Skill name must not contain path separators: $SkillName"
    exit 1
}

Set-Location $RootDir

Write-Host "Importing skill into repository skills directory..."
Write-Host "Source: $Source"
Write-Host "Skill: $SkillName"
Write-Host "Command: `$env:DISABLE_TELEMETRY=1; npx skills add $Source --skill $SkillName -a openclaw --copy -y"

$PreviousTelemetry = $env:DISABLE_TELEMETRY
$env:DISABLE_TELEMETRY = "1"
try {
    & npx skills add $Source --skill $SkillName -a openclaw --copy -y
} finally {
    $env:DISABLE_TELEMETRY = $PreviousTelemetry
}

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$SkillFile = Join-Path $RootDir (Join-Path "skills" (Join-Path $SkillName "SKILL.md"))
if (-not (Test-Path -Path $SkillFile -PathType Leaf)) {
    Write-Error "Import finished, but skills/$SkillName/SKILL.md was not found. Review the generated skills directory manually."
    exit 1
}

if (Get-Command bash -ErrorAction SilentlyContinue) {
    & bash tests/validate-project.sh
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
} else {
    Write-Host "bash not found; skipping tests/validate-project.sh on this machine."
}

Write-Host ""
Write-Host "Skill imported. Review these files before committing:"
Write-Host "- skills/$SkillName/SKILL.md"
Write-Host "- skills-lock.json"
Write-Host ""
Write-Host "Suggested review commands:"
Write-Host "git status --short"
Write-Host "git diff -- skills/$SkillName skills-lock.json"
