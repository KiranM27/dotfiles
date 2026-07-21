# Dotfiles

Personal macOS dev-environment setup, managed with [GNU Stow](https://www.gnu.org/software/stow/).
One command (`./index.sh`) installs the tooling and symlinks the configs into
your home directory. Companion repo [`agents-cockpit`](https://github.com/KiranM27/agents-cockpit)
adds the Claude Code cockpit + ctx-monitor.

## Prerequisites

- **macOS** (Apple Silicon assumed; the Homebrew PATH wiring targets `/opt/homebrew`).
- **Xcode Command Line Tools** (provides `git`): `xcode-select --install`.
- **Homebrew** — installed automatically by `index.sh` if missing.

## Quick start

Clone to **`~/Desktop/lexi_code.nosync/dotfiles`** (recommended — Stow creates
*relative* symlinks, so cloning here makes `~/.zshrc → Desktop/lexi_code.nosync/dotfiles/zsh/.zshrc`,
matching the reference setup), then run the installer:

```sh
mkdir -p ~/Desktop/lexi_code.nosync
git clone https://github.com/KiranM27/dotfiles.git ~/Desktop/lexi_code.nosync/dotfiles
cd ~/Desktop/lexi_code.nosync/dotfiles
./index.sh
```

## What `index.sh` does

Runs the scripts in `scripts/` in order:

1. **`homebrew_check.sh`** — installs Homebrew if absent and wires it onto PATH
   (`/opt/homebrew`) for Apple Silicon.
2. **`brew_packages.sh`** — installs: `tree`, `zoxide`, `stow`, `fzf`, `autojump`.
3. **`zsh_setup.sh`** — installs Oh My Zsh, Starship (via brew), and the
   `zsh-autosuggestions` + `zsh-syntax-highlighting` plugins (git-cloned into
   `$ZSH_CUSTOM/plugins`).
4. **`nodejs_setup.sh`** — installs `nvm` (v0.39.7) and `bun`.
5. **`stow_management.sh stow`** — symlinks the config packages into `$HOME`.
   It **simulates first and prompts for confirmation** (`y/N`) before creating
   any symlink.
6. **`load_launchagents.sh`** — registers the stowed LaunchAgents with `launchd`.
   Stowing only *places* a plist; it does not load it. Safe to re-run.

### Stow packages

| Package     | Links to                        | What it is                                              |
|-------------|---------------------------------|---------------------------------------------------------|
| `zsh`       | `~/.zshrc`                       | Zsh config (aliases, env, Oh My Zsh, Starship, plugins) |
| `aerospace` | `~/.aerospace.toml`             | AeroSpace tiling-WM config (keybindings, workspaces)    |
| `tmux`      | `~/.tmux.conf`                   | tmux config (Ctrl+a prefix, Claude Code compatibility)  |
| `bin`       | `~/.local/bin/ghostty-window`   | Helper: open a window in the running Ghostty instance   |
| `claude`    | `~/.claude/`                    | Claude Code statusline + ctx tap + attention hook       |
| `launchagents` | `~/Library/LaunchAgents/`    | ctx-monitor LaunchAgent (stowed *and* registered by `index.sh`) |

`README`, `LICENSE`, `scripts/`, `index.sh`, `CLAUDE.md`, and logs are excluded
from stowing via `.stow-local-ignore`. (Note: `.claude/` is **not** excluded — it
is the `claude` package's mapping dir; ignoring it would stop that package linking
into `~/.claude`.)

> The `aerospace` and `bin` packages ship **configs** for
> [AeroSpace](https://github.com/nikitabobko/AeroSpace) (tiling WM) and
> [Ghostty](https://ghostty.org) (terminal). Install those two apps separately —
> this repo does not.

Re-run any time: `./scripts/stow_management.sh status` (show links),
`./scripts/stow_management.sh unstow` (remove them).

## Companion tooling: agent cockpit + ctx-monitor

The [`agents-cockpit`](https://github.com/KiranM27/agents-cockpit) repo is a
Textual/fzf cockpit over your Claude Code tmux sessions, and bundles
**ctx-monitor** (unattended context checkpointing). The tmux config in *this*
repo already wires in the cockpit's `client-attached` hook
(`stamp-aerospace-wid.sh`), so set the cockpit up too:

```sh
# Clone anywhere (the `agents` launcher self-locates)
git clone https://github.com/KiranM27/agents-cockpit
cd agents-cockpit

# Follow its README "Install (fresh machine)" section:
/opt/homebrew/bin/python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
ln -s "$PWD/agents"         ~/.local/bin/agents
ln -s "$PWD/agents-classic" ~/.local/bin/agents-classic
mkdir -p ~/.claude/tools && ln -s "$PWD/ctx-monitor" ~/.claude/tools/ctx-monitor
```

### Enable always-on ctx-monitor

`index.sh` handles this end-to-end: `stow` symlinks the plist into
`~/Library/LaunchAgents/sg.lexi.ctx-monitor.plist`, then `load_launchagents.sh`
registers it with `launchd`. **Stowing alone is not enough** — a plist sitting in
`~/Library/LaunchAgents` that was never bootstrapped is invisible to launchd and
will never start, at login or otherwise.

The job runs `/opt/homebrew/bin/python3` against
`~/.claude/tools/ctx-monitor/ctx-monitor.py`, so it **depends on the
`agents-cockpit` clone existing**. On a fresh machine that symlink does not
resolve until you do the cockpit setup above, so `load_launchagents.sh` detects
this, warns, and skips rather than registering a crash-looping job. Once the
cockpit is cloned, arm it:

```sh
./scripts/load_launchagents.sh
```

With `RunAtLoad` + `KeepAlive` set, it starts immediately and relaunches at every
login (and if it ever dies). Re-run the script any time — it boots out and
re-bootstraps, which is also how you make launchd pick up an **edited** plist
(launchd caches the old one otherwise).

To turn it off:

```sh
launchctl bootout gui/$(id -u)/sg.lexi.ctx-monitor
```

#### Troubleshooting: "stowed but not registered" vs "registered but crashing"

These fail identically from the outside (no monitor running) but need opposite
fixes. `launchctl list` tells them apart:

```sh
launchctl list | grep ctx-monitor
```

- **No output** → launchd has never heard of the job. It is *stowed but not
  registered*. Fix: `./scripts/load_launchagents.sh`. This is the trap — the
  plist symlink exists and looks perfectly healthy, which is misleading.
- **A PID and `0`** (e.g. `65823  0  sg.lexi.ctx-monitor`) → healthy and running.
- **`-` instead of a PID, or a non-zero exit code** → *registered but crashing*.
  launchd is trying and failing. Read the error log:
  `cat ~/Library/Logs/ctx-monitor.err`. Usual cause is the
  `~/.claude/tools/ctx-monitor` symlink not resolving.
- Note `launchctl print-disabled gui/$(id -u)` reporting `enabled` proves
  **nothing** about registration — that is only the disabled-override database.

## Now shipped in the `claude` package (was manual)

Two pieces the cockpit relies on under `~/.claude` are now version-controlled here
and linked by the `claude` stow package:

- **Statusline tap** — `~/.claude/statusline.sh` renders the Claude Code status
  line and publishes `/tmp/claude-ctx/<session_id>.json`, feeding both the
  cockpit's context-% column and ctx-monitor.
- **Attention hook** — `~/.claude/hooks/tmux-attention.sh` tints a pane when
  Claude Code wants your attention (drives the cockpit's ❗ sort).

## Still manual / not-in-repo

- **`/tag` command (legacy — not needed)** — `/tag` (expected at
  `~/.claude/commands/tag.md`) stamps `@cc_name`/`@cc_color` and is read **only
  by `agents-classic`**, the old fzf picker. The current `agents` TUI derives
  identity from the Claude session title (`/rename`) + `/color` instead, so its
  absence doesn't affect the TUI. Recreate `tag.md` only if you still use
  `agents-classic`.
