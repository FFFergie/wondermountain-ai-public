# Wonder Mountain OpenCode Distribution

This repository distributes Wonder Mountain OpenCode setup materials for everyday users. It is designed to be read and executed by an AI agent, not by a human installer.

中文说明：这是万象蒙泰（Wonder Mountain）OpenCode 配置与 skills 分发仓库。使用者只需要把这个仓库的 Gitee 地址交给 OpenCode，让 AI agent 按本 README 完成安装。

## User Prompt For OpenCode

Users can give OpenCode this repository URL with the following prompt:

```text
请读取这个 Gitee 仓库，按照 README 的 Agent Installation Policy，把 OpenCode 配置模板和 skills 安装到我的 ~/.config/opencode。安装前请先运行诊断检查并备份现有配置，不要覆盖我的 opencode.json，不要猜测其他路径。
```

## What This Repository Contains

- `configs/opencode.example.json`: OpenCode 配置模板，用于记录第三方 AI API、模型名称和模型参数。
- `skills/`: 常用 skills 的离线分发目录，保持 `skills/<skill-name>/` 平铺结构，方便直接复制到 OpenCode。
- `bundles/`: skill bundle manifests for maintainers, such as `bundles/superpowers.json` and `bundles/standard.json`.
- `scripts/doctor.sh`: macOS/Linux read-only environment check before installation.
- `scripts/doctor.ps1`: Windows PowerShell read-only environment check before installation.
- `scripts/install.sh`: macOS 可选安装脚本。
- `scripts/install.ps1`: Windows PowerShell 可选安装脚本。
- `docs/maintainer-guide.md`: 维护者说明，记录如何新增模型配置和 skills。
- `.github/workflows/mirror-to-gitee.yml`: GitHub push 后自动 mirror 到 Gitee。

## Agent Installation Policy

AI agent must follow these rules:

1. Treat GitHub as the source repository and Gitee as the distribution mirror.
2. Use only the default OpenCode directory: `~/.config/opencode`.
3. Do not guess alternative paths.
4. Run the read-only doctor check before installation.
5. If `~/.config/opencode` does not exist, stop and tell the user to contact the maintainer on Feishu.
6. Do not overwrite existing user configuration without first creating a timestamped backup.
7. Never write API keys, access tokens, endpoint secrets, or personal credentials into this repository.

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
2. Run the read-only doctor check for the current platform.
3. Check whether `~/.config/opencode` exists.
4. If the directory does not exist, stop and ask the user to contact the maintainer on Feishu.
5. Back up existing OpenCode files into `~/.config/opencode/backups/wonder-mountain-<timestamp>/`.
6. Copy `configs/opencode.example.json` into `~/.config/opencode/wonder-mountain/opencode.example.json`.
7. Copy skill folders from `skills/` into `~/.config/opencode/skills/`.
8. If the user already has an OpenCode config file, merge model/provider settings manually after reviewing both files.
9. Tell the user what changed and where the backup is stored.

## Skill Bundles

OpenCode installation expects a flat directory layout:

```text
skills/<skill-name>/SKILL.md
```

For that reason, this repository keeps every vendored skill directly under `skills/`. Bundle files under `bundles/` are maintainer metadata only; they group related flat skill directories without changing the install layout.

Current bundle manifests:

- `bundles/superpowers.json`: all skills imported from `obra/superpowers` as one source bundle.
- `bundles/standard.json`: the complete Wonder Mountain public skill set distributed by this repository.

Agents should still copy skill folders from `skills/` into `~/.config/opencode/skills/`. Do not copy `bundles/` into the OpenCode skills directory.

## Optional Script Usage

The scripts perform safe file distribution only. They do not merge JSON automatically because OpenCode config files may differ across user machines.

### macOS Diagnosis

```bash
bash scripts/doctor.sh
```

### Windows PowerShell Diagnosis

```powershell
powershell -ExecutionPolicy Bypass -File scripts/doctor.ps1
```

### macOS Install

```bash
bash scripts/install.sh
```

### Windows PowerShell Install

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install.ps1
```

## OpenCode Config Template

The template at `configs/opencode.example.json` is intentionally an example. Maintainers should update it with real model names and model parameters, but must not commit personal secrets, endpoint secrets, account tokens, or employee-specific credentials.

If API keys are required, users or administrators should keep them in the user's local environment, local OpenCode config, or another approved private channel outside version control.

## Gitee Mirror

This project should be developed on GitHub and mirrored to Gitee by GitHub Actions. Configure these GitHub repository settings before enabling mirror sync:

- Secret: `GITEE_TOKEN`
- Variable: `GITEE_REPOSITORY`, for example `wondermountain/wondermountain-ai-public`

The workflow pushes branches and tags to Gitee while avoiding hidden remote-tracking refs, so Gitee should remain a distribution mirror only.
