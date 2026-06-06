# Fonts

This repo is **public**, so font binaries are split by license:

| Family | License | Where it lives | Config |
|---|---|---|---|
| Atkinson Hyperlegible | OFL (free to redistribute) | `fonts/Atkinson-Hyperlegible/` (this repo) | Zed UI font |
| MonoLisa Nerd Font | **Paid / proprietary** — not redistributable | `dotfiles-private` repo (`fonts/MonoLisa-Nerd/`) | Zed, Ghostty, Sublime Text |
| Berkeley Mono (NFM + v2 family) | **Paid / proprietary** — not redistributable | `dotfiles-private` repo (`fonts/BerkeleyMono/`) | Zed buffer/terminal (`BerkeleyMonoNFM`), `Retina` UI weight |

## On a new machine

```bash
# Atkinson (public, already here):
cp fonts/Atkinson-Hyperlegible/*.ttf ~/Library/Fonts/

# Licensed fonts (private repo):
git clone git@github.com:sudakshsoti/dotfiles-private.git ~/dev/dotfiles-private
cp ~/dev/dotfiles-private/fonts/MonoLisa-Nerd/*.ttf ~/Library/Fonts/
cp ~/dev/dotfiles-private/fonts/BerkeleyMono/nerd-font/*.ttf ~/Library/Fonts/
cp ~/dev/dotfiles-private/fonts/BerkeleyMono/v2/*.ttf ~/Library/Fonts/

fc-cache -f 2>/dev/null || true
```

macOS picks them up automatically — open Font Book to verify, or run `fc-cache -f` if you have it.
