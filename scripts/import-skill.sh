#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -gt 0 ]]; then
  ORIGINAL_COMMAND="$*"
else
  printf 'Paste the original skills.sh command, then press Enter:\n'
  printf 'Example: npx skills add https://github.com/vercel-labs/skills --skill find-skills\n> '
  read -r ORIGINAL_COMMAND
fi

if [[ -z "${ORIGINAL_COMMAND// }" ]]; then
  printf 'No command provided.\n' >&2
  exit 1
fi

read -r -a PARTS <<< "$ORIGINAL_COMMAND"

if [[ "${PARTS[0]:-}" != "npx" || "${PARTS[1]:-}" != "skills" || "${PARTS[2]:-}" != "add" ]]; then
  printf 'Command must start with: npx skills add\n' >&2
  exit 1
fi

SOURCE=""
SKILL_NAME=""

for ((i = 3; i < ${#PARTS[@]}; i++)); do
  part="${PARTS[$i]}"
  case "$part" in
    -a|--agent|-g|--global)
      printf 'Do not include %s. This script always imports into ./skills with -a openclaw.\n' "$part" >&2
      exit 1
      ;;
    --skill|-s)
      if [[ $((i + 1)) -ge ${#PARTS[@]} ]]; then
        printf '%s requires a skill name.\n' "$part" >&2
        exit 1
      fi
      SKILL_NAME="${PARTS[$((i + 1))]}"
      i=$((i + 1))
      ;;
    --skill=*)
      SKILL_NAME="${part#--skill=}"
      ;;
    -s=*)
      SKILL_NAME="${part#-s=}"
      ;;
    --*)
      printf 'Unsupported option: %s\n' "$part" >&2
      exit 1
      ;;
    *)
      if [[ -z "$SOURCE" ]]; then
        SOURCE="$part"
      fi
      ;;
  esac
done

if [[ -z "$SOURCE" ]]; then
  printf 'Missing skill source after: npx skills add\n' >&2
  exit 1
fi

if [[ -z "$SKILL_NAME" ]]; then
  printf 'Missing --skill <name> or -s <name>.\n' >&2
  exit 1
fi

if [[ "$SKILL_NAME" == */* || "$SKILL_NAME" == *\\* ]]; then
  printf 'Skill name must not contain path separators: %s\n' "$SKILL_NAME" >&2
  exit 1
fi

cd "$ROOT_DIR"

printf 'Importing skill into repository skills directory...\n'
printf 'Source: %s\n' "$SOURCE"
printf 'Skill: %s\n' "$SKILL_NAME"
printf 'Command: DISABLE_TELEMETRY=1 npx skills add %s --skill %s -a openclaw --copy -y\n' "$SOURCE" "$SKILL_NAME"

DISABLE_TELEMETRY=1 npx skills add "$SOURCE" --skill "$SKILL_NAME" -a openclaw --copy -y

if [[ ! -f "skills/$SKILL_NAME/SKILL.md" ]]; then
  printf 'Import finished, but skills/%s/SKILL.md was not found. Review the generated skills directory manually.\n' "$SKILL_NAME" >&2
  exit 1
fi

bash tests/validate-project.sh

printf '\nSkill imported. Review these files before committing:\n'
printf '%s\n' "- skills/$SKILL_NAME/SKILL.md"
printf '%s\n' '- skills-lock.json'
printf '\nSuggested review commands:\n'
printf 'git status --short\n'
printf 'git diff -- skills/%s skills-lock.json\n' "$SKILL_NAME"
