# zshrc

My zsh configuration. Built to be fast, modular, and auto-adapt to available tools and language environments.

## Features

- **Built-In Plugin Management:** Lightweight custom plugin functions (`zplugin-load`, `zplugin-update`, `zplugin-clean`) with `zsh-defer` support for instant shell startup.
- **Language Toolchains Out-of-the-Box:** Automatically sets up binary PATHs for Go (`GOPATH`), Rust (`cargo`), `mise`, and Neovim (`mason`) with automatic array deduplication (`typeset -U PATH`).
- **Tool Fallbacks:** Prefers modern CLI tools (`eza`/`exa`, `nvim`, `doas`, `nala`) when installed, falling back to standard defaults.
- **Integrations & Completion:** Configured for `fzf-tab`, rich `fzf` file previews (`bat`/`fd`), and `zoxide` directory navigation (`cd`).
- **Dynamic Prompting:** Themeable prompt layout with Git branch status and Go project version detection.
- **Utilities:** Included helper functions for fuzzy file searching (`vf`), process killing (`fkill`), system stats, and colorized diffs.

## Installation

Copy the file to your home directory:

```sh
cp zshrc ~/.zshrc
```
