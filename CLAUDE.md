# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repo purpose

Personal macOS dotfiles managed by **chezmoi**. The repo is the source of truth; chezmoi materialises files into the live locations. This repo is **public**, so it contains no plaintext secrets and no paid fonts.

`README.md` is the human-facing setup guide (new-machine bootstrap, the secrets model in plain English). `FONTS.md` covers the font license split. This file is the contributor/architecture reference — read it when *editing* configs or themes.

Path mapping conventions (chezmoi):
- `dot_config/...` → `~/.config/...`
- `private_Library/...` → `~/Library/...` (the `private_` prefix marks the file's permissions `600`, not a content distinction)
- `executable_*` → target gets the executable bit
- `*.tmpl` files → templated; chezmoi expands `{{ .var }}` placeholders at apply time

`.chezmoiignore` keeps repo-only files (`README.md`, `install.sh`, `FONTS.md`, `CLAUDE.md`, `fonts/`) out of the home directory.

## Common commands

```bash
chezmoi managed               # list every file chezmoi tracks
chezmoi managed | grep <name> # check whether a given file is managed
chezmoi status                # short status of source vs target divergence
chezmoi diff [path]           # full diff (target → what apply would change)
chezmoi apply                 # push source repo → live config locations
chezmoi apply <path>          # apply a single file (use when other entries have intentional drift)
chezmoi cd                    # drop into the source repo (this directory)
chezmoi update                # pull latest from GitHub and apply
```

When `chezmoi diff` shows divergence on a file you didn't touch, **investigate before applying** — the live file may have intentional in-progress experimentation (e.g. an alternate Ghostty palette). Apply individual paths instead of running a blanket `chezmoi apply`.

## New-machine bootstrap

`install.sh` is the one-command entry point (run via `curl | bash` — see README). In order it: installs Homebrew → installs `chezmoi age bitwarden-cli` → restores the age key from Bitwarden → `chezmoi init --apply` → clones the private fonts repo and installs fonts. It is idempotent (safe to re-run).

Config lives in **three places**: this public repo (configs, themes, encrypted secrets, the free Atkinson font), the private `dotfiles-private` repo (paid fonts: MonoLisa, Berkeley Mono), and Bitwarden (the one secret that decrypts everything — the `chezmoi age key` note).

## Terminal stack

The current stack is **Ghostty** (outer terminal) → **Starship** (prompt), with **no multiplexer**. This has churned repeatedly — earlier iterations used WezTerm as the terminal and, as multiplexers, herdr (https://herdr.dev) and then Zellij. **Both herdr and Zellij are fully removed** (Zellij uninstalled 2026-06-13: brew formula, `~/.config/zellij/`, the `zcd` alias, and the zellaude hooks in `~/.claude/settings.json`) — treat any `dot_config/herdr/` or `dot_config/zellij/` reference as dead. **WezTerm is not removed:** it stays brew-installed and its config is chezmoi-managed (see below) as a kept-around alternate, even though Ghostty is the daily driver. **Verify the live stack before acting on it** — `which ghostty wezterm`, `chezmoi managed | grep -E 'ghostty|wezterm'`.

- Ghostty config: `dot_config/ghostty/config`; palettes under `dot_config/ghostty/themes/` (one per custom theme — see Theme architecture).
- Starship prompt: `dot_config/starship.toml`.
- WezTerm config (alternate terminal, not the daily driver): `dot_config/wezterm/wezterm.lua` — self-contained, Kohra theme inline, MonoLisa NF, leader `CTRL+a`, resurrect plugin for session save/restore. herdr-specific keybindings were stripped when it was restored (CMD+k does a native `ClearScrollback`). Mirrors the Ghostty look; if the Kohra palette changes, the hexes embedded here must be updated by hand.

## Theme architecture

Three custom themes each ship across **multiple** apps. Any colour change must be mirrored in every file where the conceptual token exists.

| Theme | Apps it spans |
|---|---|
| **Vesper Dimmed** | Zed, Sublime Text, Ghostty |
| **Kohra** | Zed, Ghostty, Cursor (extension) |
| **Editorial Code** | Zed, Sublime Text, Ghostty, Cursor (extension) |

Per-format locations:

| File / pattern | Tool | Format |
|---|---|---|
| `dot_config/zed/themes/*.json` | Zed | Zed v0.2.0 theme schema (full UI + syntax) |
| `private_Library/.../Sublime Text/.../*.sublime-color-scheme` | Sublime | JSON; named `variables` referenced by scope rules |
| `dot_config/ghostty/themes/*` | Ghostty | `key = value`; terminal palette + selection |
| `dot_cursor/extensions/*/themes/*.json` | Cursor | VS Code theme JSON (packaged as an extension) |

Notes specific to Vesper Dimmed (the most worked-on theme):
- Sublime's `variables` block (`fg`, `muted`, `subtle`, `punct`, `orange`, `aqua`, …) is the propagation point — changing `fg` updates the global foreground and every `variable`-scoped syntax rule.
- The Zed file is the only one carrying non-terminal UI tokens (element backgrounds, search match, document highlights, hint background, etc.); the terminal formats have no equivalents.
- **Hue discipline:** neutrals are warm (hue ~40°). Derive new greys from that ramp; pure greys (`#1A1A1A`, `#101010`) are no longer in use.

## Sync workflow for theme/config edits

1. Edit the file(s) in this repo.
2. Sync to live — **everything is now chezmoi-managed** (Zed themes included; there are no longer any manually-`cp`'d targets): `chezmoi apply <path>` for the specific file.
3. Zed watches its live theme files but sometimes needs a nudge: `touch ~/.config/zed/themes/<name>.json` after applying.
4. Commit and push (`chezmoi cd` first).

## Zed settings template

`dot_config/zed/private_settings.json.tmpl` → `~/.config/zed/settings.json` (templated). The Google API key for Zed's language-model integration is injected at apply time by **decrypting** an age-encrypted file in the source dir:

```
"api_key": "{{ joinPath .chezmoi.sourceDir ".zedGoogleApiKey.age" | include | decrypt | trim }}"
```

`dot_config/zed/executable_new-worktree-branch.sh` auto-creates a branch off `origin/main` when Zed opens a new worktree.

## Secrets (age encryption)

Secrets are encrypted with [age](https://github.com/FiloSottile/age) so the public repo never holds plaintext. README has the full plain-English model; the essentials:

- `~/.config/chezmoi/chezmoi.toml` (generated from `.chezmoi.toml.tmpl`, local) sets `encryption = "age"` with the identity at `~/.config/chezmoi/key.txt` and the recipient public key.
- The age **identity** (`key.txt`) is the only secret carried between machines — backed up in Bitwarden (note "chezmoi age key"). Restore it (chmod 600) before `chezmoi apply` on a new machine.
- Encrypted blobs live in the source dir with a leading `.` (e.g. `.zedGoogleApiKey.age`) so chezmoi treats them as data, not target files. They are ASCII-armored and safe to publish.

To add a new secret:
```bash
printf '%s' "THE_SECRET" | age --armor -r <recipient> > .newsecret.age
# then in a .tmpl: {{ joinPath .chezmoi.sourceDir ".newsecret.age" | include | decrypt | trim }}
```
