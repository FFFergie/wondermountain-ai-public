#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$HOME/.config/opencode"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$CONFIG_DIR/backups/wonder-mountain-$TIMESTAMP"
PACKAGE_DIR="$CONFIG_DIR/wonder-mountain"
TARGET_SKILLS_DIR="$CONFIG_DIR/skills"

if [[ ! -d "$CONFIG_DIR" ]]; then
  printf '未找到默认 OpenCode 配置目录 ~/.config/opencode。请在飞书联系维护者处理。\n' >&2
  exit 1
fi

mkdir -p "$BACKUP_DIR" "$PACKAGE_DIR" "$TARGET_SKILLS_DIR"

if [[ -f "$CONFIG_DIR/opencode.json" ]]; then
  cp "$CONFIG_DIR/opencode.json" "$BACKUP_DIR/opencode.json"
fi

if [[ -f "$CONFIG_DIR/config.json" ]]; then
  cp "$CONFIG_DIR/config.json" "$BACKUP_DIR/config.json"
fi

cp "$ROOT_DIR/configs/opencode.example.json" "$PACKAGE_DIR/opencode.example.json"

for skill_dir in "$ROOT_DIR"/skills/*; do
  if [[ -d "$skill_dir" ]]; then
    cp -R "$skill_dir" "$TARGET_SKILLS_DIR/"
  fi
done

printf 'Wonder Mountain OpenCode files installed.\n'
printf 'Config template: %s\n' "$PACKAGE_DIR/opencode.example.json"
printf 'Skills directory: %s\n' "$TARGET_SKILLS_DIR"
printf 'Backup directory: %s\n' "$BACKUP_DIR"
