#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

require_file() {
  local path="$1"
  if [[ ! -f "$ROOT_DIR/$path" ]]; then
    printf 'Missing file: %s\n' "$path" >&2
    exit 1
  fi
}

require_dir() {
  local path="$1"
  if [[ ! -d "$ROOT_DIR/$path" ]]; then
    printf 'Missing directory: %s\n' "$path" >&2
    exit 1
  fi
}

require_text() {
  local path="$1"
  local text="$2"
  if ! grep -Fq -- "$text" "$ROOT_DIR/$path"; then
    printf 'Missing text in %s: %s\n' "$path" "$text" >&2
    exit 1
  fi
}

forbid_text() {
  local text="$1"
  if grep -R -Fq --exclude-dir=.git --exclude-dir=node_modules --exclude=tests/private-forbidden-patterns.txt -- "$text" "$ROOT_DIR"; then
    printf 'Forbidden text found: %s\n' "$text" >&2
    exit 1
  fi
}

forbid_patterns_from_stdin() {
  local source_name="$1"
  local pattern
  while IFS= read -r pattern; do
    [[ -z "$pattern" || "$pattern" == \#* ]] && continue
    if grep -R -Fq --exclude-dir=.git --exclude-dir=node_modules --exclude=tests/private-forbidden-patterns.txt -- "$pattern" "$ROOT_DIR"; then
      printf 'Forbidden private pattern found from %s. Check private rule source.\n' "$source_name" >&2
      exit 1
    fi
  done
}

forbid_regex() {
  local pattern="$1"
  if grep -R -Eq --exclude-dir=.git --exclude-dir=node_modules --exclude=tests/private-forbidden-patterns.txt -- "$pattern" "$ROOT_DIR"; then
    printf 'Forbidden regex found: %s\n' "$pattern" >&2
    exit 1
  fi
}

require_file "README.md"
require_file ".gitignore"
require_file "configs/opencode.example.json"
require_dir "skills"
require_file "skills/README.md"
require_file "scripts/install.sh"
require_file "scripts/install.ps1"
require_file "scripts/doctor.sh"
require_file "scripts/doctor.ps1"
require_file "scripts/import-skill.sh"
require_file "scripts/import-skill.ps1"
require_file "tests/test-import-skill.sh"
require_file ".github/workflows/mirror-to-gitee.yml"
require_file "docs/maintainer-guide.md"

require_text "README.md" "~/.config/opencode"
require_text "README.md" "Gitee"
require_text "README.md" "AI agent"
require_text "README.md" "scripts/doctor.sh"
require_text "README.md" "User Prompt For OpenCode"
require_text "scripts/install.sh" 'CONFIG_DIR="$HOME/.config/opencode"'
require_text "scripts/install.ps1" 'Join-Path $HOME ".config/opencode"'
require_text "scripts/doctor.sh" 'CONFIG_DIR="$HOME/.config/opencode"'
require_text "scripts/doctor.sh" "READY"
require_text "scripts/doctor.sh" "BLOCKED"
require_text "scripts/doctor.sh" "wonder-mountain"
require_text "scripts/doctor.ps1" 'Join-Path $HOME ".config/opencode"'
require_text "scripts/doctor.ps1" "READY"
require_text "scripts/doctor.ps1" "BLOCKED"
require_text "scripts/import-skill.sh" "DISABLE_TELEMETRY=1"
require_text "scripts/import-skill.sh" "-a openclaw"
require_text "scripts/import-skill.sh" "--copy"
require_text "scripts/import-skill.sh" "--agent"
require_text "scripts/import-skill.sh" "--global"
require_text "scripts/import-skill.sh" "all skills from source"
require_text "scripts/import-skill.sh" 'printf '\''%s\n'\'' "- skills/$SKILL_NAME/SKILL.md"'
require_text "scripts/import-skill.ps1" "DISABLE_TELEMETRY"
require_text "scripts/import-skill.ps1" "openclaw"
require_text "scripts/import-skill.ps1" "--copy"
require_text "scripts/import-skill.ps1" "all skills from source"
require_text "docs/maintainer-guide.md" "scripts/import-skill.sh"
require_text "docs/maintainer-guide.md" "skills-lock.json"
require_text "docs/maintainer-guide.md" "bs779517/story-skills"
require_text "docs/maintainer-guide.md" "Installation Smoke Test"
require_text "docs/maintainer-guide.md" "PRIVATE_FORBIDDEN_PATTERNS"
require_text ".github/workflows/mirror-to-gitee.yml" "git push --mirror gitee"
require_text "configs/opencode.example.json" "wonder-mountain"
require_text "configs/opencode.example.json" "Do not commit API keys, endpoint secrets, account tokens, or personal credentials into this file."
require_text "configs/opencode.example.json" "Keep real provider endpoints and API keys in local user configuration or another approved private channel."
require_text ".gitignore" "tests/private-forbidden-patterns.txt"
require_text ".gitignore" ".DS_Store"
require_text "AGENTS.md" "bash scripts/doctor.sh"
require_text "AGENTS.md" "PRIVATE_FORBIDDEN_PATTERNS"

if find "$ROOT_DIR" -name .DS_Store -print -quit | grep -q .; then
  printf 'Forbidden macOS metadata file found: .DS_Store\n' >&2
  exit 1
fi

forbid_text "YOUR_""INTERNAL"
forbid_text "BEGIN PRIVATE ""KEY"
forbid_text "ghp""_"
forbid_text "gitee""_"
forbid_regex "sk-[A-Za-z0-9]{16,}"

PRIVATE_PATTERNS_FILE="${PRIVATE_PATTERNS_FILE:-$ROOT_DIR/tests/private-forbidden-patterns.txt}"

if [[ -f "$PRIVATE_PATTERNS_FILE" ]]; then
  forbid_patterns_from_stdin "$PRIVATE_PATTERNS_FILE" < "$PRIVATE_PATTERNS_FILE"
fi

if [[ -n "${PRIVATE_FORBIDDEN_PATTERNS:-}" ]]; then
  forbid_patterns_from_stdin "PRIVATE_FORBIDDEN_PATTERNS" <<< "$PRIVATE_FORBIDDEN_PATTERNS"
fi

python3 - <<'PY' "$ROOT_DIR"
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
lock_path = root / "skills-lock.json"
with lock_path.open("r", encoding="utf-8") as handle:
    lock = json.load(handle)

locked_paths = {item.get("skillPath") for item in lock.get("skills", {}).values()}
for name, item in sorted(lock.get("skills", {}).items()):
    skill_path = root / item["skillPath"]
    if not skill_path.is_file():
        raise SystemExit(f"Locked skill file is missing: {item['skillPath']}")
    for required in ("source", "sourceType", "computedHash"):
        if not item.get(required):
            raise SystemExit(f"Locked skill {name} is missing {required}")

for skill_file in sorted((root / "skills").glob("*/SKILL.md")):
    rel = str(skill_file.relative_to(root))
    if rel not in locked_paths:
        raise SystemExit(f"Skill missing from skills-lock.json: {rel}")
PY

bash "$ROOT_DIR/tests/test-import-skill.sh"

printf 'Project structure validation passed.\n'
