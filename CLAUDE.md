# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repo purpose

Personal dotfiles managed by **chezmoi**. The repo is the source of truth; chezmoi materialises files into the live macOS locations.

Path mapping conventions (chezmoi):
- `dot_config/...` → `~/.config/...`
- `private_Library/...` → `~/Library/...` (the `private_` prefix marks the file's permissions, not a content distinction)
- `*.tmpl` files → templated; chezmoi expands `{{ .var }}` placeholders from chezmoi's data store at apply time

## Common commands

```bash
chezmoi managed               # list every file chezmoi tracks
chezmoi status                # short status of source vs target divergence
chezmoi diff [path]           # full diff (target → what apply would change)
chezmoi apply                 # push source repo → live config locations
chezmoi apply <path>          # apply a single file (use when other entries have intentional drift)
chezmoi cd                    # drop into the source repo (this directory)
```

When `chezmoi diff` shows divergence on a file you didn't touch, **investigate before applying** — the live file may have intentional in-progress experimentation (e.g. an alternate Ghostty palette). Apply individual paths instead of running a blanket `chezmoi apply`.

## Theme architecture: Vesper Dimmed

Vesper Dimmed is a custom dark theme that ships across **four editors/terminals**. Any colour change must be mirrored across all four files where the conceptual token exists:

| File | Tool | Format |
|---|---|---|
| `dot_config/zed/themes/vesper-dimmed.json` | Zed | Zed v0.2.0 theme schema (full UI + syntax) |
| `private_Library/.../Sublime Text/.../Vesper Dimmed.sublime-color-scheme` | Sublime | `.sublime-color-scheme` JSON; uses named `variables` (`fg`, `muted`, `subtle`, `punct`, `orange`, `aqua`, etc.) referenced by scope rules |
| `private_Library/.../Warp/themes/vesper-dimmed.yaml` | Warp | YAML; terminal palette + accent only |
| `dot_config/ghostty/themes/vesper-dimmed` | Ghostty | `key = value` text; terminal palette + selection |

Sublime's `variables` block is the propagation point — changing `fg` updates both the global foreground and every `variable`-scoped syntax rule. The Zed file is the only one that carries non-terminal UI tokens (element backgrounds, search match, document highlights, hint background, etc.); Sublime/Warp/Ghostty have no equivalents for those.

**Hue discipline:** the palette's neutrals have been progressively rotated to a warm hue ~40°. When adding or adjusting a grey, derive it from that ramp rather than picking a pure grey (`#1A1A1A`, `#101010`, etc. are no longer in use). Recent commits document the migration (`refine(vesper-dimmed): ...`).

**Live Zed reload:** Zed watches the live theme file for changes. After editing `dot_config/zed/themes/vesper-dimmed.json` and copying to `~/.config/zed/themes/`, `touch` the live file to nudge the watcher.

## Sync workflow for theme edits

1. Edit the file(s) in this repo.
2. Sync to live:
   - For chezmoi-managed files (`chezmoi managed | grep <name>`), use `chezmoi apply <path>` for the specific file.
   - For unmanaged files (currently the Zed and Warp themes), `cp` from repo to the live location directly.
3. `touch ~/.config/zed/themes/vesper-dimmed.json` if Zed is the target.
4. Commit and push.

## Zed settings template

`dot_config/zed/private_settings.json.tmpl` is templated; the only template variable currently in use is `{{ .zedGoogleApiKey }}` (Google API key for Zed's language model integration). When adding new secrets, prefer chezmoi template variables over committing literals.
