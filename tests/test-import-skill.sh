#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/scripts" "$TMP_DIR/tests" "$TMP_DIR/bin" "$TMP_DIR/skills"
cp "$ROOT_DIR/scripts/import-skill.sh" "$TMP_DIR/scripts/import-skill.sh"

cat > "$TMP_DIR/tests/validate-project.sh" <<'TEST'
#!/usr/bin/env bash
set -euo pipefail
printf 'test validation passed\n'
TEST
chmod +x "$TMP_DIR/tests/validate-project.sh"

cat > "$TMP_DIR/bin/npx" <<'NPX'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> npx-args.log

source=""
skill=""
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  case "${args[$i]}" in
    add)
      source="${args[$((i + 1))]:-}"
      ;;
    --skill|-s)
      skill="${args[$((i + 1))]:-}"
      ;;
    --skill=*)
      skill="${args[$i]#--skill=}"
      ;;
    -s=*)
      skill="${args[$i]#-s=}"
      ;;
  esac
done

if [[ -n "$skill" ]]; then
  mkdir -p "skills/$skill"
  printf '# %s\n' "$skill" > "skills/$skill/SKILL.md"
  exit 0
fi

if [[ "$source" == "bs779517/story-skills" ]]; then
  for name in plot-structure worldbuilding character-management chapter-writing story-init; do
    mkdir -p "skills/$name"
    printf '# %s\n' "$name" > "skills/$name/SKILL.md"
  done
  exit 0
fi

printf 'fake npx did not understand source: %s\n' "$source" >&2
exit 1
NPX
chmod +x "$TMP_DIR/bin/npx"

(
  cd "$TMP_DIR"
  PATH="$TMP_DIR/bin:$PATH" bash scripts/import-skill.sh npx skills add https://github.com/vercel-labs/skills --skill find-skills
  test -f skills/find-skills/SKILL.md
  grep -Fq -- 'skills add https://github.com/vercel-labs/skills --skill find-skills -a openclaw --copy -y' npx-args.log
)

(
  cd "$TMP_DIR"
  rm -f npx-args.log
  PATH="$TMP_DIR/bin:$PATH" bash scripts/import-skill.sh npx skills add bs779517/story-skills
  for name in plot-structure worldbuilding character-management chapter-writing story-init; do
    test -f "skills/$name/SKILL.md"
  done
  grep -Fq -- 'skills add bs779517/story-skills -a openclaw --copy -y' npx-args.log
)

printf 'Import skill script tests passed.\n'
