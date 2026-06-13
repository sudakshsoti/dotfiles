# Fonts

This repo is **public** and carries **no font binaries**. Every family — free
and paid alike — lives in the private `dotfiles-private` repo, so there is one
place to manage them.

| Family | License | Where it lives | Config |
|---|---|---|---|
| Atkinson Hyperlegible | OFL (free to redistribute) | `dotfiles-private` repo (`fonts/Atkinson-Hyperlegible/`) | Zed UI font |
| MonoLisa Nerd Font | **Paid / proprietary** — not redistributable | `dotfiles-private` repo (`fonts/MonoLisa-Nerd/`) | Zed, Ghostty, Sublime Text |
| Berkeley Mono (NFM + v2 family) | **Paid / proprietary** — not redistributable | `dotfiles-private` repo (`fonts/BerkeleyMono/`) | Zed buffer/terminal (`BerkeleyMonoNFM`), `Retina` UI weight |

## On a new machine

```bash
git clone git@github.com:sudakshsoti/dotfiles-private.git ~/dev/dotfiles-private
find ~/dev/dotfiles-private/fonts -name '*.ttf' -exec cp {} ~/Library/Fonts/ \;
fc-cache -f 2>/dev/null || true
```

`install.sh` does this automatically. macOS picks the fonts up — open Font Book
to verify, or run `fc-cache -f` if you have it.
