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
