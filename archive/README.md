# archive/

Configs for tools no longer in active use, kept for reference and easy revival.
This whole folder is listed in `.chezmoiignore`, so `chezmoi apply` **never**
materialises anything here into the home directory.

| Path | Tool | Retired | Notes |
|---|---|---|---|
| `wezterm/wezterm.lua` | WezTerm | 2026-06-26 | App uninstalled. Self-contained config: Kohra theme inline, MonoLisa NF, leader `CTRL+a`, resurrect plugin for session save/restore. Mirrors the Ghostty look. |

## Reviving a config

1. Move the dir back under `dot_config/` (e.g. `git mv archive/wezterm dot_config/wezterm`).
2. Remove (or narrow) the `archive` line in `.chezmoiignore` if needed.
3. Reinstall the app, then `chezmoi apply dot_config/wezterm/wezterm.lua`.
