# AGENTS.md

## Repository Role

- This is a Wonder Mountain OpenCode distribution kit, not an application package; there is no build step or package manifest.
- Treat `README.md`, `docs/maintainer-guide.md`, scripts, and `.github/workflows/mirror-to-gitee.yml` as the source of truth.

## Installation Rules

- Use only `~/.config/opencode` as the OpenCode target path on macOS and Windows; do not guess alternatives.
- If `~/.config/opencode` is missing, stop and tell the user to contact the maintainer on Feishu.
- Installation scripts back up `opencode.json` and `config.json` to `~/.config/opencode/backups/wonder-mountain-<timestamp>/` before copying files.
- `configs/opencode.example.json` is a template only; never commit real API keys, access tokens, endpoint secrets, or personal credentials.
- The template is copied to `~/.config/opencode/wonder-mountain/opencode.example.json`; merge real user config manually after review.

## Skills

- Vendored skills live directly under `skills/<skill-name>/SKILL.md` and are copied to `~/.config/opencode/skills/`.
- User installation must not require `npx`, Node.js, GitHub, or skills.sh network access.
- Maintainers can import from skills.sh with `bash scripts/import-skill.sh` or `powershell -ExecutionPolicy Bypass -File scripts/import-skill.ps1`, then paste the original `npx skills add ... --skill ...` command.
- The importer intentionally rewrites the target to `DISABLE_TELEMETRY=1 npx skills add <source> --skill <name> -a openclaw --copy -y`, rejects `--agent`/`-a`/`--global`/`-g`, and updates `skills-lock.json`.

## Verification

- Run `bash tests/validate-project.sh` after any repo structure, docs, config, workflow, or script change.
- Run `bash scripts/doctor.sh` before local install smoke tests; it is read-only and must not print secrets.
- When editing shell scripts, also run `bash -n scripts/install.sh`, `bash -n scripts/import-skill.sh`, and `bash -n scripts/doctor.sh`.
- PowerShell scripts mirror the Bash scripts; verify with `pwsh` only when it is available locally.

## Release And Mirror

- GitHub is the source repository; Gitee is a mirror driven by `.github/workflows/mirror-to-gitee.yml`.
- The mirror workflow needs GitHub secret `GITEE_TOKEN` and variable `GITEE_REPOSITORY`; it uses `git push --mirror gitee`.
- Confirm with the repository owner before any push, force push, or history rewrite.

## Public Copy Constraints

- Keep Wonder Mountain / 万象蒙泰 as the brand name, but keep usage and procurement wording neutral.
- Do not add private operational details, access tokens, customer data, or credentials to tracked files.
- `tests/validate-project.sh` loads optional private forbidden patterns from `tests/private-forbidden-patterns.txt` or `PRIVATE_FORBIDDEN_PATTERNS`; do not commit the private pattern list.
