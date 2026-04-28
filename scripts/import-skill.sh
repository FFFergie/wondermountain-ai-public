#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -gt 0 ]]; then
  ORIGINAL_COMMAND="$*"
else
  printf 'Paste the original skills.sh command, then press Enter:\n'
  printf 'Examples:\n'
  printf '  npx skills add https://github.com/vercel-labs/skills --skill find-skills\n'
  printf '  npx skills add bs779517/story-skills\n> '
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

if [[ -n "$SKILL_NAME" && ("$SKILL_NAME" == */* || "$SKILL_NAME" == *\\*) ]]; then
  printf 'Skill name must not contain path separators: %s\n' "$SKILL_NAME" >&2
  exit 1
fi

cd "$ROOT_DIR"

list_skill_names() {
  local skill_file
  local skill_dir
  shopt -s nullglob
  for skill_file in skills/*/SKILL.md; do
    skill_dir="${skill_file%/SKILL.md}"
    printf '%s\n' "${skill_dir#skills/}"
  done | sort
  shopt -u nullglob
}

BEFORE_SKILLS="$(list_skill_names)"

IMPORT_COMMAND=(npx skills add "$SOURCE")
if [[ -n "$SKILL_NAME" ]]; then
  IMPORT_COMMAND+=(--skill "$SKILL_NAME")
fi
IMPORT_COMMAND+=(-a openclaw --copy -y)

printf 'Importing skill into repository skills directory...\n'
printf 'Source: %s\n' "$SOURCE"
if [[ -n "$SKILL_NAME" ]]; then
  printf 'Skill: %s\n' "$SKILL_NAME"
else
  printf 'Skill: all skills from source\n'
fi
printf 'Command: DISABLE_TELEMETRY=1'
printf ' %q' "${IMPORT_COMMAND[@]}"
printf '\n'

DISABLE_TELEMETRY=1 "${IMPORT_COMMAND[@]}"

AFTER_SKILLS="$(list_skill_names)"

if [[ -n "$SKILL_NAME" ]]; then
  if [[ ! -f "skills/$SKILL_NAME/SKILL.md" ]]; then
    printf 'Import finished, but skills/%s/SKILL.md was not found. Review the generated skills directory manually.\n' "$SKILL_NAME" >&2
    exit 1
  fi
else
  if [[ -z "$AFTER_SKILLS" ]]; then
    printf 'Import finished, but no skills/*/SKILL.md files were found. Review the generated skills directory manually.\n' >&2
    exit 1
  fi
fi

NEW_SKILLS="$(comm -13 <(printf '%s\n' "$BEFORE_SKILLS") <(printf '%s\n' "$AFTER_SKILLS") || true)"

bash tests/validate-project.sh

printf '\nSkill imported. Review these files before committing:\n'
if [[ -n "$SKILL_NAME" ]]; then
  printf '%s\n' "- skills/$SKILL_NAME/SKILL.md"
elif [[ -n "$NEW_SKILLS" ]]; then
  while IFS= read -r imported_skill; do
    [[ -z "$imported_skill" ]] && continue
    printf '%s\n' "- skills/$imported_skill/SKILL.md"
  done <<< "$NEW_SKILLS"
else
  printf '%s\n' '- skills/ (review git status for updated skill directories)'
fi
printf '%s\n' '- skills-lock.json'
printf '\nSuggested review commands:\n'
printf 'git status --short\n'
if [[ -n "$SKILL_NAME" ]]; then
  printf 'git diff -- skills/%s skills-lock.json\n' "$SKILL_NAME"
else
  printf 'git diff -- skills skills-lock.json\n'
fi
