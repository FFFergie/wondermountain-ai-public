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

require_file "README.md"
require_file "configs/opencode.example.json"
require_dir "skills"
require_file "skills/README.md"
require_file "scripts/install.sh"
require_file "scripts/install.ps1"
require_file "scripts/import-skill.sh"
require_file "scripts/import-skill.ps1"
require_file "tests/test-import-skill.sh"
require_file ".github/workflows/mirror-to-gitee.yml"
require_file "docs/maintainer-guide.md"

require_text "README.md" "~/.config/opencode"
require_text "README.md" "Gitee"
require_text "README.md" "AI agent"
require_text "scripts/install.sh" 'CONFIG_DIR="$HOME/.config/opencode"'
require_text "scripts/install.ps1" 'Join-Path $HOME ".config/opencode"'
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
require_text ".github/workflows/mirror-to-gitee.yml" "git push --mirror gitee"
require_text "configs/opencode.example.json" "wonder-mountain"

bash "$ROOT_DIR/tests/test-import-skill.sh"

printf 'Project structure validation passed.\n'
