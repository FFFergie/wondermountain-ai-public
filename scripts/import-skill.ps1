$ErrorActionPreference = "Stop"

$RootDir = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

if ($args.Count -gt 0) {
    $OriginalCommand = $args -join " "
} else {
    Write-Host "Paste the original skills.sh command, then press Enter:"
    Write-Host "Examples:"
    Write-Host "  npx skills add https://github.com/vercel-labs/skills --skill find-skills"
    Write-Host "  npx skills add bs779517/story-skills"
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

if (-not [string]::IsNullOrWhiteSpace($SkillName) -and ($SkillName.Contains("/") -or $SkillName.Contains("\"))) {
    Write-Error "Skill name must not contain path separators: $SkillName"
    exit 1
}

Set-Location $RootDir

function Get-SkillNames {
    if (-not (Test-Path -Path "skills" -PathType Container)) {
        return @()
    }

    return @(Get-ChildItem -Path "skills" -Directory | Where-Object {
        Test-Path -Path (Join-Path $_.FullName "SKILL.md") -PathType Leaf
    } | ForEach-Object {
        $_.Name
    } | Sort-Object)
}

$BeforeSkills = @(Get-SkillNames)

$ImportArgs = @("skills", "add", $Source)
if (-not [string]::IsNullOrWhiteSpace($SkillName)) {
    $ImportArgs += @("--skill", $SkillName)
}
$ImportArgs += @("-a", "openclaw", "--copy", "-y")

Write-Host "Importing skill into repository skills directory..."
Write-Host "Source: $Source"
if (-not [string]::IsNullOrWhiteSpace($SkillName)) {
    Write-Host "Skill: $SkillName"
} else {
    Write-Host "Skill: all skills from source"
}
Write-Host "Command: `$env:DISABLE_TELEMETRY=1; npx $($ImportArgs -join ' ')"

$PreviousTelemetry = $env:DISABLE_TELEMETRY
$env:DISABLE_TELEMETRY = "1"
try {
    & npx @ImportArgs
} finally {
    $env:DISABLE_TELEMETRY = $PreviousTelemetry
}

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$AfterSkills = @(Get-SkillNames)

if (-not [string]::IsNullOrWhiteSpace($SkillName)) {
    $SkillFile = Join-Path $RootDir (Join-Path "skills" (Join-Path $SkillName "SKILL.md"))
    if (-not (Test-Path -Path $SkillFile -PathType Leaf)) {
        Write-Error "Import finished, but skills/$SkillName/SKILL.md was not found. Review the generated skills directory manually."
        exit 1
    }
} elseif ($AfterSkills.Count -eq 0) {
    Write-Error "Import finished, but no skills/*/SKILL.md files were found. Review the generated skills directory manually."
    exit 1
}

$NewSkills = @($AfterSkills | Where-Object { $BeforeSkills -notcontains $_ })

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
if (-not [string]::IsNullOrWhiteSpace($SkillName)) {
    Write-Host "- skills/$SkillName/SKILL.md"
} elseif ($NewSkills.Count -gt 0) {
    foreach ($ImportedSkill in $NewSkills) {
        Write-Host "- skills/$ImportedSkill/SKILL.md"
    }
} else {
    Write-Host "- skills/ (review git status for updated skill directories)"
}
Write-Host "- skills-lock.json"
Write-Host ""
Write-Host "Suggested review commands:"
Write-Host "git status --short"
if (-not [string]::IsNullOrWhiteSpace($SkillName)) {
    Write-Host "git diff -- skills/$SkillName skills-lock.json"
} else {
    Write-Host "git diff -- skills skills-lock.json"
}
