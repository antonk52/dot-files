# Repository Guidelines

## Project Structure & Module Organization

This is a personal dotfiles repo. Top-level folders map to apps/configs: `nvim/`, `hammerspoon/`, `tmux/`, `git/`, `jj/`, `ghostty/`, `karabiner/`, and `fish/`. Root files like `.zshrc` and `shell-aliases` are shell entrypoints; automation lives in `scripts/` (mainly `scripts/setup.sh`).

`dependencies/` (zsh plugin submodules) and `nvim/plugged/` (Neovim plugins) are vendor code; avoid editing them except for explicit updates.

## Build, Test, and Development Commands

- `./scripts/setup.sh` - full bootstrap (links, macOS defaults, Brew, npm globals).
- `./scripts/setup.sh links` - create/update symlinks only.
- `./scripts/setup.sh mac brew npm` - run selected setup phases.
- `git submodule update --init --recursive` - sync vendor dependencies.
- `stylua nvim hammerspoon` - format Lua.
- `selene nvim hammerspoon` - static-check Lua.
- `luacheck --config neovim.yml nvim hammerspoon` - optional lint with Neovim/Hammerspoon globals.

## Version Control

Use `jj` (Jujutsu) for everyday version control in this repo (status, commit, diff, log, etc.). Avoid using Git commands except when required for submodules (for example, `git submodule update --init --recursive`).

## Coding Style & Naming Conventions

Lua is the primary language. Follow `.stylua.toml`: 4-space indentation, max width `100`, and normalized quotes (usually single). Use lowercase `snake_case` for Lua modules/files (for example, `nvim/lua/antonk52/format_on_save.lua`).

Shell scripts should be Bash with strict mode (`set -euo pipefail`) and small functions (see `scripts/setup.sh`).

## Testing Guidelines

There is no centralized automated test suite. Validate with linters/formatters plus a quick smoke test in the affected app:

- Neovim: launch `nvim` and reload config.
- Hammerspoon: reload from the Hammerspoon console/menu.
- Shell/Zsh: start a new shell and verify aliases/functions load.

## Commit & Pull Request Guidelines

Recent commits use scoped prefixes such as `[vim]`, `[zsh]`, and `[hammerspoon]` (example: `[vim] update plugins`). Keep messages imperative and focused on one area.

PRs should include what changed, impacted tools/apps, setup or migration steps (if any), and brief verification notes. Add screenshots only for visible UI changes (for example, Hammerspoon overlays).
