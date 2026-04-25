# Wonder Mountain OpenCode Distribution

This repository distributes Wonder Mountain OpenCode setup materials for everyday users. It is designed to be read and executed by an AI agent, not by a human installer.

中文说明：这是万象蒙泰（Wonder Mountain）OpenCode 配置与 skills 分发仓库。使用者只需要把这个仓库的 Gitee 地址交给 OpenCode，让 AI agent 按本 README 完成安装。

## What This Repository Contains

- `configs/opencode.example.json`: OpenCode 配置模板，用于记录第三方 AI API、模型名称和模型参数。
- `skills/`: 常用 skills 的离线分发目录，避免依赖 `npx`、Node.js、GitHub 网络或 skills.sh。
- `scripts/install.sh`: macOS 可选安装脚本。
- `scripts/install.ps1`: Windows PowerShell 可选安装脚本。
- `docs/maintainer-guide.md`: 维护者说明，记录如何新增模型配置和 skills。
- `.github/workflows/mirror-to-gitee.yml`: GitHub push 后自动 mirror 到 Gitee。

## Agent Installation Policy

AI agent must follow these rules:

1. Treat GitHub as the source repository and Gitee as the distribution mirror.
2. Use only the default OpenCode directory: `~/.config/opencode`.
3. Do not guess alternative paths.
4. If `~/.config/opencode` does not exist, stop and tell the user to contact the maintainer on Feishu.
5. Do not overwrite existing user configuration without first creating a timestamped backup.
6. Never write API keys, access tokens, or personal credentials into this repository.

## Default Target Path

Both macOS and Windows should use:

```text
~/.config/opencode
```

On Windows, PowerShell expands this from `$HOME`, so the expected target is:

```text
$HOME/.config/opencode
```

If this directory does not exist, report this message to the user:

```text
未找到默认 OpenCode 配置目录 ~/.config/opencode。请在飞书联系维护者处理。
```

## Recommended Agent Flow

When a user gives this Gitee repository to OpenCode, the AI agent should:

1. Clone or download this repository from Gitee.
2. Check whether `~/.config/opencode` exists.
3. If the directory does not exist, stop and ask the user to contact the maintainer on Feishu.
4. Back up existing OpenCode files into `~/.config/opencode/backups/wonder-mountain-<timestamp>/`.
5. Copy `configs/opencode.example.json` into `~/.config/opencode/wonder-mountain/opencode.example.json`.
6. Copy skill folders from `skills/` into `~/.config/opencode/skills/`.
7. If the user already has an OpenCode config file, merge model/provider settings manually after reviewing both files.
8. Tell the user what changed and where the backup is stored.

## Optional Script Usage

The scripts perform safe file distribution only. They do not merge JSON automatically because OpenCode config files may differ across user machines.

### macOS

```bash
bash scripts/install.sh
```

### Windows PowerShell

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install.ps1
```

## OpenCode Config Template

The template at `configs/opencode.example.json` is intentionally an example. Maintainers should update it with real model names and model parameters, but must not commit personal secrets.

If API keys are required, users or administrators should keep them in the user's local environment or local OpenCode config outside version control.

## Gitee Mirror

This project should be developed on GitHub and mirrored to Gitee by GitHub Actions. Configure these GitHub repository settings before enabling mirror sync:

- Secret: `GITEE_TOKEN`
- Variable: `GITEE_REPOSITORY`, for example `wondermountain/wondermountain-ai-public`

The workflow uses `git push --mirror gitee`, so Gitee should remain a mirror only.
