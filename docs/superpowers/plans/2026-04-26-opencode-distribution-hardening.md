# OpenCode Distribution Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the Wonder Mountain OpenCode distribution kit into a safer, smoke-tested package that non-technical users can hand to OpenCode with minimal risk.

**Architecture:** Keep the repository as a static distribution kit: shell/PowerShell scripts perform local checks and file copying, Markdown documents instruct agents and maintainers, and `tests/validate-project.sh` enforces repository structure and public-safety rules. User-specific OpenCode configuration remains outside version control; this repo only ships templates and vendored skills.

**Tech Stack:** Bash, PowerShell, Markdown, JSON, GitHub Actions, skills.sh CLI for maintainer-only skill vendoring.

---

## File Structure

- Create `scripts/doctor.sh`: read-only macOS/Linux environment checker for `~/.config/opencode` and repository assets.
- Create `scripts/doctor.ps1`: read-only Windows PowerShell equivalent of `scripts/doctor.sh`.
- Modify `tests/validate-project.sh`: require doctor scripts, validate public safety patterns, and keep existing structure checks.
- Modify `README.md`: put doctor before install and add the short user prompt.
- Modify `docs/maintainer-guide.md`: document smoke testing, skill bundle curation, and release checks.
- Modify `AGENTS.md`: add doctor and safety-check guidance for future agent sessions.
- Modify `.gitignore`: exclude maintainer-local private safety rules.
- Modify `configs/opencode.example.json`: tighten public template notes without adding real secrets.
- Modify `skills-lock.json` and `skills/`: only when importing the approved first skill bundle.

---

### Task 1: Add Validation Expectations For Doctor Scripts

**Files:**
- Modify: `tests/validate-project.sh`
- Test: `bash tests/validate-project.sh`

- [ ] **Step 1: Add failing structure checks**

Add these lines after the existing script file checks in `tests/validate-project.sh`:

```bash
require_file "scripts/doctor.sh"
require_file "scripts/doctor.ps1"
```

Add these text checks near the other script checks:

```bash
require_text "scripts/doctor.sh" 'CONFIG_DIR="$HOME/.config/opencode"'
require_text "scripts/doctor.sh" "READY"
require_text "scripts/doctor.sh" "BLOCKED"
require_text "scripts/doctor.sh" "wonder-mountain"
require_text "scripts/doctor.ps1" 'Join-Path $HOME ".config/opencode"'
require_text "scripts/doctor.ps1" "READY"
require_text "scripts/doctor.ps1" "BLOCKED"
require_text "README.md" "scripts/doctor.sh"
require_text "docs/maintainer-guide.md" "Installation Smoke Test"
```

- [ ] **Step 2: Run validation and verify it fails for the right reason**

Run:

```bash
bash tests/validate-project.sh
```

Expected: failure with `Missing file: scripts/doctor.sh`.

- [ ] **Step 3: Commit is not allowed yet**

Do not commit after this task. The repository is intentionally red until Task 2 and Task 3 add the scripts.

---

### Task 2: Implement macOS/Linux Doctor Script

**Files:**
- Create: `scripts/doctor.sh`
- Test: `bash -n scripts/doctor.sh`
- Test: `bash scripts/doctor.sh`

- [ ] **Step 1: Create `scripts/doctor.sh`**

Create the file with this exact content:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$HOME/.config/opencode"
STATUS="READY"

report() {
  local level="$1"
  local message="$2"
  printf '[%s] %s\n' "$level" "$message"
}

block() {
  STATUS="BLOCKED"
  report "BLOCKED" "$1"
}

warn() {
  if [[ "$STATUS" != "BLOCKED" ]]; then
    STATUS="WARN"
  fi
  report "WARN" "$1"
}

ok() {
  report "OK" "$1"
}

printf 'Wonder Mountain OpenCode environment check\n'
printf 'Repository: %s\n' "$ROOT_DIR"
printf 'OpenCode directory: %s\n\n' "$CONFIG_DIR"

if [[ -d "$CONFIG_DIR" ]]; then
  ok "Default OpenCode directory exists."
else
  block "Missing ~/.config/opencode. Contact the maintainer on Feishu; do not guess another path."
fi

if [[ -f "$CONFIG_DIR/opencode.json" ]]; then
  ok "Existing opencode.json found; install will back it up and will not merge it automatically."
else
  warn "No opencode.json found under ~/.config/opencode."
fi

if [[ -d "$CONFIG_DIR/skills" ]]; then
  ok "OpenCode skills directory exists."
else
  warn "OpenCode skills directory is missing; install script will create it if the config directory exists."
fi

if [[ -d "$CONFIG_DIR/wonder-mountain" ]]; then
  warn "Wonder Mountain package directory already exists and may be overwritten by install."
else
  ok "Wonder Mountain package directory is not installed yet."
fi

if [[ -f "$ROOT_DIR/configs/opencode.example.json" ]]; then
  ok "Repository config template exists."
else
  block "Missing configs/opencode.example.json in this repository."
fi

if [[ -d "$ROOT_DIR/skills" ]]; then
  found_skill="false"
  for skill_dir in "$ROOT_DIR"/skills/*; do
    if [[ -d "$skill_dir" ]]; then
      found_skill="true"
      if [[ -f "$skill_dir/SKILL.md" ]]; then
        ok "Skill package present: skills/$(basename "$skill_dir")/SKILL.md"
      else
        block "Skill directory missing SKILL.md: skills/$(basename "$skill_dir")"
      fi
    fi
  done
  if [[ "$found_skill" == "false" ]]; then
    warn "No vendored skill directories found under repository skills/."
  fi
else
  block "Missing repository skills directory."
fi

printf '\nResult: %s\n' "$STATUS"

if [[ "$STATUS" == "BLOCKED" ]]; then
  exit 1
fi
```

- [ ] **Step 2: Make the script executable**

Run:

```bash
chmod +x scripts/doctor.sh
```

- [ ] **Step 3: Verify shell syntax**

Run:

```bash
bash -n scripts/doctor.sh
```

Expected: no output.

- [ ] **Step 4: Run the doctor on the maintainer machine**

Run:

```bash
bash scripts/doctor.sh
```

Expected on the current maintainer machine: output includes `Result: READY` or `Result: WARN`, not `Result: BLOCKED`, because `/Users/fergie/.config/opencode` exists.

---

### Task 3: Implement Windows Doctor Script

**Files:**
- Create: `scripts/doctor.ps1`
- Test: `pwsh -NoProfile -File scripts/doctor.ps1` when `pwsh` is available

- [ ] **Step 1: Create `scripts/doctor.ps1`**

Create the file with this exact content:

```powershell
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
```

- [ ] **Step 2: Verify PowerShell when available**

Run:

```bash
command -v pwsh
```

If it prints a path, run:

```bash
pwsh -NoProfile -File scripts/doctor.ps1
```

Expected: output includes `Result: READY` or `Result: WARN` on a configured machine. If `pwsh` is unavailable, record that it was skipped locally.

---

### Task 4: Update Documentation For Doctor-First Install Flow

**Files:**
- Modify: `README.md`
- Modify: `docs/maintainer-guide.md`
- Modify: `AGENTS.md`
- Test: `bash tests/validate-project.sh`

- [ ] **Step 1: Update README contents list**

In `README.md`, add these two bullets under `What This Repository Contains` near the install scripts:

```markdown
- `scripts/doctor.sh`: macOS/Linux read-only environment check before installation.
- `scripts/doctor.ps1`: Windows PowerShell read-only environment check before installation.
```

- [ ] **Step 2: Update README recommended flow**

Change the recommended flow so diagnosis happens before installation. The flow should include these lines:

```markdown
2. Run the read-only doctor check for the current platform.
3. Check whether `~/.config/opencode` exists.
4. If the directory does not exist, stop and ask the user to contact the maintainer on Feishu.
```

- [ ] **Step 3: Add README optional doctor commands**

Add this before optional install commands:

```markdown
### macOS Diagnosis

```bash
bash scripts/doctor.sh
```

### Windows PowerShell Diagnosis

```powershell
powershell -ExecutionPolicy Bypass -File scripts/doctor.ps1
```
```

- [ ] **Step 4: Add maintainer smoke-test section**

Add this section to `docs/maintainer-guide.md` before `Release Flow`:

```markdown
## Installation Smoke Test

Before publishing a release, run the read-only doctor and then perform one controlled install on a maintainer machine:

```bash
bash scripts/doctor.sh
bash scripts/install.sh
```

Confirm these paths exist after installation:

- `~/.config/opencode/backups/wonder-mountain-<timestamp>/`
- `~/.config/opencode/wonder-mountain/opencode.example.json`
- `~/.config/opencode/skills/find-skills/SKILL.md`

Do not commit any file copied from `~/.config/opencode` during this smoke test.
```

- [ ] **Step 5: Update AGENTS verification section**

Add this bullet to `AGENTS.md` under `Verification`:

```markdown
- Run `bash scripts/doctor.sh` before local install smoke tests; it is read-only and must not print secrets.
```

- [ ] **Step 6: Run validation**

Run:

```bash
bash tests/validate-project.sh
```

Expected: `Project structure validation passed.`

- [ ] **Step 7: Commit Task 1-4 together**

Run:

```bash
git add scripts/doctor.sh scripts/doctor.ps1 tests/validate-project.sh README.md docs/maintainer-guide.md AGENTS.md
git commit -m "feat: add opencode environment doctor"
```

---

### Task 5: Perform Local Installation Smoke Test

**Files:**
- No repository files should change unless docs need correction after observed behavior.
- Test: `bash scripts/doctor.sh`
- Test: `bash scripts/install.sh`

- [ ] **Step 1: Run doctor**

Run:

```bash
bash scripts/doctor.sh
```

Expected on the current maintainer machine: `Result: READY` or `Result: WARN`.

- [ ] **Step 2: Run install script**

Run:

```bash
bash scripts/install.sh
```

Expected output includes:

```text
Wonder Mountain OpenCode files installed.
Config template: /Users/fergie/.config/opencode/wonder-mountain/opencode.example.json
Skills directory: /Users/fergie/.config/opencode/skills
Backup directory: /Users/fergie/.config/opencode/backups/wonder-mountain-
```

- [ ] **Step 3: Verify installed files without printing secrets**

Run:

```bash
test -f "$HOME/.config/opencode/wonder-mountain/opencode.example.json"
test -f "$HOME/.config/opencode/skills/find-skills/SKILL.md"
test -d "$HOME/.config/opencode/backups"
```

Expected: no output.

- [ ] **Step 4: Verify repository is unchanged by smoke test**

Run:

```bash
git status --short
```

Expected: no output. If documentation must be corrected based on observed behavior, edit only repo docs and commit with:

```bash
git add README.md docs/maintainer-guide.md AGENTS.md
git commit -m "docs: clarify installation smoke test"
```

---

### Task 6: Strengthen Public Safety Checks

**Files:**
- Modify: `.gitignore`
- Modify: `tests/validate-project.sh`
- Modify: `AGENTS.md`
- Modify: `docs/maintainer-guide.md`
- Test: `bash tests/validate-project.sh`

- [ ] **Step 1: Ignore maintainer-local private safety rules**

Add this line to `.gitignore`:

```gitignore
tests/private-forbidden-patterns.txt
```

This file is intentionally not committed. Maintainers can create it locally with one private forbidden pattern per line.

- [ ] **Step 2: Add forbidden text helper**

Add this function to `tests/validate-project.sh` after `require_text()`:

```bash
forbid_text() {
  local text="$1"
  if grep -R -Fq --exclude-dir=.git --exclude-dir=node_modules -- "$text" "$ROOT_DIR"; then
    printf 'Forbidden text found: %s\n' "$text" >&2
    exit 1
  fi
}
```

- [ ] **Step 3: Add private pattern loading helper**

Add this function after `forbid_text()`:

```bash
forbid_patterns_from_stdin() {
  local source_name="$1"
  local pattern
  while IFS= read -r pattern; do
    [[ -z "$pattern" || "$pattern" == \#* ]] && continue
    if grep -R -Fq --exclude-dir=.git --exclude-dir=node_modules -- "$pattern" "$ROOT_DIR"; then
      printf 'Forbidden private pattern found from %s. Check private rule source.\n' "$source_name" >&2
      exit 1
    fi
  done
}
```

- [ ] **Step 4: Add public generic checks without full self-matching literals**

Add these checks before the final success message. Keep split string literals so the validation script does not match itself:

```bash
forbid_text "YOUR_""INTERNAL"
forbid_text "BEGIN PRIVATE ""KEY"
forbid_text "ghp""_"
forbid_text "gitee""_"
forbid_text "sk""-"
```

Do not forbid the field name `apiKey`; `configs/opencode.example.json` intentionally includes that field with a placeholder value.

- [ ] **Step 5: Load private rules from local file and CI secret**

Add this block after the public generic checks:

```bash
PRIVATE_PATTERNS_FILE="${PRIVATE_PATTERNS_FILE:-$ROOT_DIR/tests/private-forbidden-patterns.txt}"

if [[ -f "$PRIVATE_PATTERNS_FILE" ]]; then
  forbid_patterns_from_stdin "$PRIVATE_PATTERNS_FILE" < "$PRIVATE_PATTERNS_FILE"
fi

if [[ -n "${PRIVATE_FORBIDDEN_PATTERNS:-}" ]]; then
  forbid_patterns_from_stdin "PRIVATE_FORBIDDEN_PATTERNS" <<< "$PRIVATE_FORBIDDEN_PATTERNS"
fi
```

- [ ] **Step 6: Document the private safety check**

Add this bullet to `AGENTS.md` under `Public Copy Constraints`:

```markdown
- `tests/validate-project.sh` loads optional private forbidden patterns from `tests/private-forbidden-patterns.txt` or `PRIVATE_FORBIDDEN_PATTERNS`; do not commit the private pattern list.
```

Add this line to `docs/maintainer-guide.md` under `Release Flow`:

```markdown
Run `bash tests/validate-project.sh` immediately before publishing. Maintainers can add private checks through local `tests/private-forbidden-patterns.txt` or GitHub secret `PRIVATE_FORBIDDEN_PATTERNS` without exposing the pattern list in the repository.
```

- [ ] **Step 7: Create a local private pattern file on maintainer machines only**

On maintainer machines, create `tests/private-forbidden-patterns.txt` manually. Do not commit it. Put one private forbidden pattern per line. The file can include business-sensitive wording, token field names, private endpoint fragments, or other patterns that should never appear in the public repository.

- [ ] **Step 8: Run validation**

Run:

```bash
bash tests/validate-project.sh
```

Expected: `Project structure validation passed.`

- [ ] **Step 9: Confirm private pattern file is not tracked**

Run:

```bash
git status --short -- tests/private-forbidden-patterns.txt
```

Expected: no output, because `.gitignore` excludes the private file.

- [ ] **Step 10: Commit safety checks**

Run:

```bash
git add .gitignore tests/validate-project.sh AGENTS.md docs/maintainer-guide.md
git commit -m "test: add public safety checks"
```

---

### Task 7: Improve Public Config Template Guidance

**Files:**
- Modify: `configs/opencode.example.json`
- Modify: `README.md`
- Modify: `docs/maintainer-guide.md`
- Test: `bash tests/validate-project.sh`

- [ ] **Step 1: Update template notes**

In `configs/opencode.example.json`, make sure the `notes` array contains these strings:

```json
[
  "Wonder Mountain OpenCode configuration template.",
  "Do not commit API keys, endpoint secrets, account tokens, or personal credentials into this file.",
  "Agents should review and merge this template into the user's real OpenCode config manually.",
  "Keep real provider endpoints and API keys in local user configuration or another approved private channel."
]
```

- [ ] **Step 2: Keep placeholders public-safe**

Confirm these placeholder values remain in `configs/opencode.example.json`:

```json
"baseURL": "https://YOUR_AI_API_ENDPOINT/v1",
"apiKey": "READ_FROM_LOCAL_SECRET_OR_ENVIRONMENT",
"model": "YOUR_MODEL_ID"
```

- [ ] **Step 3: Update maintainer guide**

Under `Update OpenCode Model Configuration`, add:

```markdown
Keep real API endpoints and API keys out of this public repository. If a real provider configuration is needed, distribute it through an approved private channel and keep only sanitized examples here.
```

- [ ] **Step 4: Run validation**

Run:

```bash
bash tests/validate-project.sh
```

Expected: `Project structure validation passed.`

- [ ] **Step 5: Commit config guidance**

Run:

```bash
git add configs/opencode.example.json README.md docs/maintainer-guide.md
git commit -m "docs: clarify config template safety"
```

---

### Task 8: Import First Standard Skill Bundle

**Files:**
- Modify: `skills/`
- Modify: `skills-lock.json`
- Modify: `docs/maintainer-guide.md`
- Test: `bash tests/validate-project.sh`

- [ ] **Step 1: Confirm the first bundle scope with the repository owner**

Use this proposed first bundle:

```text
find-skills
omo-model-config
story-init
chapter-writing
claude-frontend-design
```

If the owner wants a smaller bundle, keep `find-skills` and `omo-model-config`, then add only the approved user-facing skills.

- [ ] **Step 2: Import each approved skill**

For each approved skill, run:

```bash
bash scripts/import-skill.sh
```

Paste the original skills.sh command when prompted. For `find-skills`, the command is:

```text
npx skills add https://github.com/vercel-labs/skills --skill find-skills
```

For skills that already exist under `~/.config/opencode/skills/` but do not have a known skills.sh source, do not copy from the user directory into this repository. Use `scripts/import-skill.sh` only with a source that can be reviewed and locked in `skills-lock.json`.

- [ ] **Step 3: Verify imported skill files**

Run this for each imported skill:

```bash
test -f "skills/<skill-name>/SKILL.md"
```

Replace `<skill-name>` with the exact imported folder name. Expected: no output.

- [ ] **Step 4: Run validation**

Run:

```bash
bash tests/validate-project.sh
```

Expected: `Project structure validation passed.`

- [ ] **Step 5: Review lockfile changes**

Run:

```bash
git diff -- skills-lock.json
git status --short
```

Expected: `skills-lock.json` includes only the newly approved skills and no user-local config files are present.

- [ ] **Step 6: Commit skill bundle**

Run:

```bash
git add skills skills-lock.json docs/maintainer-guide.md
git commit -m "feat: add standard skill bundle"
```

---

### Task 9: Add User Prompt For OpenCode Setup

**Files:**
- Modify: `README.md`
- Optionally create: `docs/user-prompt.md`
- Test: `bash tests/validate-project.sh`

- [ ] **Step 1: Add README section near the top**

Add this section after the Chinese introduction:

```markdown
## User Prompt For OpenCode

Users can give OpenCode this repository URL with the following prompt:

```text
请读取这个 Gitee 仓库，按照 README 的 Agent Installation Policy，把 OpenCode 配置模板和 skills 安装到我的 ~/.config/opencode。安装前请先运行诊断检查并备份现有配置，不要覆盖我的 opencode.json，不要猜测其他路径。
```
```

- [ ] **Step 2: Run validation**

Run:

```bash
bash tests/validate-project.sh
```

Expected: `Project structure validation passed.`

- [ ] **Step 3: Commit user prompt**

Run:

```bash
git add README.md docs/user-prompt.md
git commit -m "docs: add user prompt for opencode setup"
```

If `docs/user-prompt.md` was not created, omit it from `git add`.

---

### Task 10: Final Release And Mirror Verification

**Files:**
- No file changes expected.
- Test: `bash tests/validate-project.sh`
- Test: GitHub Actions mirror workflow

- [ ] **Step 1: Run final local verification**

Run:

```bash
bash tests/validate-project.sh
bash -n scripts/install.sh
bash -n scripts/import-skill.sh
bash -n scripts/doctor.sh
git status --short
```

Expected:

```text
Project structure validation passed.
```

The `bash -n` commands print no output. `git status --short` prints no output.

- [ ] **Step 2: Ask before pushing**

Ask the repository owner for confirmation before pushing to GitHub. Do not force push unless the owner explicitly requests history rewrite.

- [ ] **Step 3: Push after confirmation**

Run:

```bash
git push origin main
```

Expected: GitHub `main` advances to the latest local commit.

- [ ] **Step 4: Watch the mirror workflow**

Run:

```bash
gh run list --workflow mirror-to-gitee.yml --limit 1 --json databaseId,status,conclusion,headSha
```

Use the returned `databaseId`:

```bash
gh run watch <databaseId> --exit-status
```

Expected: workflow completes with `success`.

- [ ] **Step 5: Verify Gitee commit**

Run:

```bash
git ls-remote https://gitee.com/Fergie/wondermountain-ai-public.git refs/heads/main
```

Expected: the returned commit hash matches GitHub `main`.

---

## Self-Review

- Spec coverage: This plan covers doctor scripts, local install smoke test, config template hardening, standard skill bundle import, user prompt, public safety checks, and GitHub-to-Gitee release verification.
- Placeholder scan: The plan uses explicit filenames, commands, expected outputs, and script contents. The only angle-bracket tokens are command examples that explicitly say how to replace them.
- Type consistency: Script names, paths, status strings, and commit messages are consistent across tasks.
- Scope check: Tasks are independent enough to commit in small batches; the first safe implementation batch is Task 1 through Task 4.
