# Maintainer Guide

This guide is for Wonder Mountain maintainers.

## Update OpenCode Model Configuration

1. Edit `configs/opencode.example.json`.
2. Add or update provider and model entries.
3. Keep model IDs, temperature, context limits, and other non-secret parameters in the file.
4. Do not commit API keys, personal tokens, endpoint secrets, account tokens, employee-specific credentials, or real private provider endpoints.
5. Keep real API endpoints and API keys out of this public repository. If a real provider configuration is needed, distribute it through an approved private channel and keep only sanitized examples here.
6. Ask one technical maintainer to test the template on macOS and Windows before announcing it.

## Add Skills

1. Add each skill as a folder under `skills/`.
2. Ensure every skill folder contains `SKILL.md`.
3. Keep skills self-contained so installation does not require `npx`, Node.js, GitHub, or skills.sh.
4. Run `bash tests/validate-project.sh` before publishing.

## Import Skills From skills.sh

Use this workflow only on a maintainer machine. Employees should still install from this repository, not from skills.sh.

1. Copy the original skills.sh command. Single-skill commands can include `--skill`, such as `npx skills add https://github.com/vercel-labs/skills --skill find-skills`; package commands can omit it, such as `npx skills add bs779517/story-skills`.
2. On macOS or Linux, run `bash scripts/import-skill.sh` from the repository root and paste the command when prompted.
3. On Windows, run `powershell -ExecutionPolicy Bypass -File scripts/import-skill.ps1` from the repository root and paste the command when prompted.
4. The importer sets `DISABLE_TELEMETRY=1` and rewrites the install target to `-a openclaw --copy -y`, which makes `npx skills` copy the selected skill or package into this repository's `skills/` directory.
5. Review the generated `skills/<skill-name>/SKILL.md` files, any package-created skill directories, and `skills-lock.json` before committing.
6. Run `bash tests/validate-project.sh` before publishing.

Do not paste commands that already include `--agent`, `-a`, `--global`, or `-g`. The importer rejects those flags so maintainers do not accidentally install into a user-level OpenCode directory.

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

## Release Flow

1. Update files in this repository.
2. Run `bash tests/validate-project.sh` immediately before publishing. Maintainers can add private checks through local `tests/private-forbidden-patterns.txt` or GitHub secret `PRIVATE_FORBIDDEN_PATTERNS` without exposing the pattern list in the repository.
3. Commit changes locally.
4. Push to GitHub after confirming with the repository owner.
5. Configure GitHub secret `GITEE_TOKEN` with a Gitee token that can push to the target repository.
6. Configure GitHub variable `GITEE_REPOSITORY` with the Gitee path, such as `wondermountain/wondermountain-ai-public`.
7. GitHub Actions mirrors the repository to Gitee with `git push --mirror gitee`.
8. Give employees the Gitee repository URL.

## Support Policy

If a user's `~/.config/opencode` directory does not exist, do not ask the agent to guess a path. Ask the user to contact the maintainer on Feishu.
