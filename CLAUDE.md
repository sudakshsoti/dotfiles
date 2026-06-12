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

The current stack is **Ghostty** (outer terminal) → **Zellij** (multiplexer) → **Starship** (prompt). This has churned repeatedly — earlier iterations used WezTerm as the terminal and herdr (https://herdr.dev) as the multiplexer; both are now removed. If something in this repo or in older git history references `dot_config/wezterm/` or `dot_config/herdr/`, treat it as dead. **Verify the live stack before acting on it** — `which ghostty zellij`, `chezmoi managed | grep -E 'ghostty|zellij'`.

- Ghostty config: `dot_config/ghostty/config`; palettes under `dot_config/ghostty/themes/` (one per custom theme — see Theme architecture).
- Zellij config: `dot_config/zellij/config.kdl` — stock compiled-in defaults with `theme "kohra"` plus two plugins. Three **custom** themes live in `dot_config/zellij/themes/`: `kohra` (active), `vesper-dim`, and `nord-dim`. The two `-dim` files each fork a built-in (vesper / nord) with one change — `ribbon_unselected.background` darkened so the status-bar keybind chips read dark, not bright (every built-in ships a *light* unselected-ribbon bg, so a dark bottom bar requires a fork). `kohra` is different: Zellij ships no Kohra base, so it is hand-authored from the Kohra cross-app palette (see `dot_config/ghostty/themes/kohra-ghostty`) — fog-grey monochrome with the signature blue `#78accf` on selected ribbon/active frame. Its base bg `#181b1d` is already the darkest tone, so `ribbon_unselected.background` uses it directly (no separate dim fork needed). `zellij setup --dump-config` prints the full default set; `zellij setup --check` validates config.kdl (but **not** layouts).
  - **Plugins are loaded from release URLs** (no `.wasm` binaries in the repo), so first launch prompts once per plugin to grant permissions (`y`). They are: `zellij-sessionizer` (fuzzy project→session switcher over `~/dev`, bound to the tmux prefix then `g`), and `zellij-newtab-plus` (enhanced new-tab with typed name + zoxide nav + name history, bound to the tmux prefix then `c` — overriding native new-tab; needs `zoxide`).
  - `dot_config/zellij/layouts/default.kdl` swaps the native tab bar for **zellaude** (`ishefi/zellaude`), a Claude-Code-aware bar: per-session activity, macOS notifications + pulse on permission prompts, click ⚠ to focus that pane. **Caveat:** on first load zellaude writes `~/.config/zellij/plugins/zellaude-hook.sh` and registers it in `~/.claude/settings.json` — that live edit diverges from `dot_claude/settings.json` and must be captured back into the chezmoi source. Needs `terminal-notifier` (brew) for click-to-focus.
  - Config/keybind changes only take effect in **new** sessions — Zellij does not hot-reload config into running sessions.
- Starship prompt: `dot_config/starship.toml`.

## Theme architecture

Three custom themes each ship across **multiple** apps. Any colour change must be mirrored in every file where the conceptual token exists.

| Theme | Apps it spans |
|---|---|
| **Vesper Dimmed** | Zed, Sublime Text, Ghostty |
| **Kohra** | Zed, Ghostty, Cursor (extension), Zellij |
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

The multiplexer (Zellij) now uses `kohra` (in `dot_config/zellij/themes/`). It derives from the Kohra cross-app palette but is a **separate, hand-authored** file — Zellij's theme format has no overlap with the Zed/Sublime/Ghostty/Cursor formats, so it is **not** an automatic theme-mirror target. A palette change to cross-app Kohra does not propagate here; mirror it into `dot_config/zellij/themes/kohra.kdl` by hand if you want them in sync. The `vesper-dim` and `nord-dim` forks remain available as inactive alts.

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
