# Maintainer Guide

This guide is for Wonder Mountain maintainers.

## Update OpenCode Model Configuration

1. Edit `configs/opencode.example.json`.
2. Add or update provider and model entries.
3. Keep model IDs, temperature, context limits, and other non-secret parameters in the file.
4. Do not commit API keys, personal tokens, or employee-specific credentials.
5. Ask one technical maintainer to test the template on macOS and Windows before announcing it.

## Add Skills

1. Add each skill as a folder under `skills/`.
2. Ensure every skill folder contains `SKILL.md`.
3. Keep skills self-contained so installation does not require `npx`, Node.js, GitHub, or skills.sh.
4. Run `bash tests/validate-project.sh` before publishing.

## Import Skills From skills.sh

Use this workflow only on a maintainer machine. Employees should still install from this repository, not from skills.sh.

1. Copy the original skills.sh command, such as `npx skills add https://github.com/vercel-labs/skills --skill find-skills`.
2. On macOS or Linux, run `bash scripts/import-skill.sh` from the repository root and paste the command when prompted.
3. On Windows, run `powershell -ExecutionPolicy Bypass -File scripts/import-skill.ps1` from the repository root and paste the command when prompted.
4. The importer sets `DISABLE_TELEMETRY=1` and rewrites the install target to `-a openclaw --copy -y`, which makes `npx skills` copy the selected skill into this repository's `skills/` directory.
5. Review the generated `skills/<skill-name>/SKILL.md` and `skills-lock.json` before committing.
6. Run `bash tests/validate-project.sh` before publishing.

Do not paste commands that already include `--agent`, `-a`, `--global`, or `-g`. The importer rejects those flags so maintainers do not accidentally install into a user-level OpenCode directory.

## Release Flow

1. Update files in this repository.
2. Commit changes locally.
3. Push to GitHub after confirming with the repository owner.
4. Configure GitHub secret `GITEE_TOKEN` with a Gitee token that can push to the target repository.
5. Configure GitHub variable `GITEE_REPOSITORY` with the Gitee path, such as `wondermountain/wondermountain-ai-public`.
6. GitHub Actions mirrors the repository to Gitee with `git push --mirror gitee`.
7. Give employees the Gitee repository URL.

## Support Policy

If a user's `~/.config/opencode` directory does not exist, do not ask the agent to guess a path. Ask the user to contact the maintainer on Feishu.
