# Fonts

Font binaries live in `fonts/` (private repo, so they're committed directly).

## Installed on this machine

| Family | Weights used | Config | Source |
|---|---|---|---|
| MonoLisa Nerd Font | Medium (450) | Zed, Ghostty, Sublime Text | `fonts/MonoLisa-Nerd/` |
| Atkinson Hyperlegible | Regular | Zed UI font | `fonts/Atkinson-Hyperlegible/` |

## On a new machine

```bash
cp fonts/MonoLisa-Nerd/*.ttf ~/Library/Fonts/
cp fonts/Atkinson-Hyperlegible/*.ttf ~/Library/Fonts/
```

macOS picks them up automatically — open Font Book to verify, or run `fc-cache -f` if you have it.
