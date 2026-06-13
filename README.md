# dotfiles

My personal macOS configuration — editor, terminal, shell, themes — managed with
[chezmoi](https://chezmoi.io). This repo is **public**, so it contains **no secrets
and no fonts**. Those live elsewhere (explained below) and get pulled in
automatically during setup.

---

## TL;DR — set up a new Mac in one command

Open **Terminal** and paste this:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/sudakshsoti/dotfiles/main/install.sh)
```

It will:
1. Install Homebrew, chezmoi, age, and the Bitwarden CLI
2. Ask you to **log in to Bitwarden** (so it can fetch your secret decryption key)
3. Download these dotfiles and apply them — decrypting your API keys automatically
4. Clone the private fonts repo and install all fonts (Atkinson + MonoLisa + Berkeley Mono)

That's it. Restart your terminal and editors afterward.

> The only thing you need to remember is your **Bitwarden master password**.
> Everything else is automated.

---

## How this is organised

There are **three** places your config lives. Only the first is public.

| Place | What's in it | Visibility |
|---|---|---|
| **This repo** (`dotfiles`) | All configs, themes, and *encrypted* secrets | 🌍 Public |
| **`dotfiles-private` repo** | All fonts: Atkinson + MonoLisa + Berkeley Mono | 🔒 Private |
| **Bitwarden** | One secret note, `chezmoi age key` — the key that decrypts everything | 🔑 Your vault |

Think of it like a locked box: the **locked box** (encrypted secrets) is safe to leave
in public; the **key to the box** is the only thing kept private (in Bitwarden).

---

## How secrets work (plain English)

API keys must never appear in a public repo. So instead of storing the key as text,
this repo stores an **encrypted** version of it, and decrypts it only on your machine.

- The encryption tool is [**age**](https://github.com/FiloSottile/age).
- There are two halves to age: a **public key** (safe to share) and a **private key**
  (must stay secret).
- The **public key** is committed here in `.chezmoi.toml.tmpl` — anyone can use it to
  *encrypt*, but not to decrypt.
- The **private key** is stored only in Bitwarden (note: `chezmoi age key`) and is
  restored to `~/.config/chezmoi/key.txt` during setup.
- When you run `chezmoi apply`, chezmoi reads the private key and decrypts secrets on
  the fly.

Currently the only secret is the Google API key for Zed's AI integration. It's stored
encrypted in `.zedGoogleApiKey.age` and injected into Zed's settings at apply time.

### Adding a new secret later

```bash
# 1. Encrypt the secret into a file (the recipient is the public key from .chezmoi.toml.tmpl):
printf '%s' "YOUR_SECRET_VALUE" | age --armor \
  -r age1d9yzax57uqsm9xwwsn8d6takv79d72x7yc4028kzp5y332dwhucqz9uznq \
  > ~/.local/share/chezmoi/.mynewsecret.age

# 2. Reference it in any *.tmpl file:
#    {{ joinPath .chezmoi.sourceDir ".mynewsecret.age" | include | decrypt | trim }}

# 3. Apply and commit:
chezmoi apply
chezmoi cd && git add -A && git commit -m "Add new secret" && git push
```

---

## Day-to-day use

You only ever need a handful of commands:

```bash
chezmoi edit ~/.config/zed/settings.json   # edit a config (opens the repo copy)
chezmoi apply                              # push your repo changes to the live files
chezmoi diff                               # preview what apply would change
chezmoi cd                                 # jump into the repo to git commit/push
chezmoi update                             # pull latest from GitHub and apply
```

Typical loop: `chezmoi edit <file>` → `chezmoi apply` → `chezmoi cd` → `git commit && git push`.

> Tip: this repo sometimes has intentional local drift (e.g. theme experiments).
> If `chezmoi diff` shows a change you didn't make, look before you `apply`.
> You can apply just one file with `chezmoi apply <path>`.

---

## Fonts

| Font | License | Where |
|---|---|---|
| Atkinson Hyperlegible | OFL (free) | `dotfiles-private` repo |
| MonoLisa Nerd Font | Paid | `dotfiles-private` repo |
| Berkeley Mono (NFM + v2) | Paid | `dotfiles-private` repo |

`install.sh` installs all of them. To do it by hand, see [`FONTS.md`](FONTS.md).

---

## Manual setup (if the one-liner fails)

```bash
# 1. Install tools
brew install chezmoi age bitwarden-cli

# 2. Restore your decryption key from Bitwarden
bw login            # first time only
export BW_SESSION="$(bw unlock --raw)"
mkdir -p ~/.config/chezmoi
bw get notes "chezmoi age key" > ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt

# 3. Pull and apply the dotfiles (generates the chezmoi config automatically,
#    then decrypts secrets)
chezmoi init --apply sudakshsoti

# 4. Fonts (all live in the private repo)
git clone git@github.com:sudakshsoti/dotfiles-private.git ~/dev/dotfiles-private
find ~/dev/dotfiles-private/fonts -name '*.ttf' -exec cp {} ~/Library/Fonts/ \;
fc-cache -f 2>/dev/null || true
```

---

## Backing up the decryption key (do this once)

If you ever rotate or regenerate the age key, re-save it to Bitwarden so future machines
can decrypt:

```bash
export BW_SESSION="$(bw unlock --raw)"
bw get template item \
  | jq --rawfile notes ~/.config/chezmoi/key.txt \
      '.type=2 | .secureNote={"type":0} | .name="chezmoi age key" | .notes=$notes | .folderId=null' \
  | bw encode | bw create item --session "$BW_SESSION"
```

> ⚠️ **Without the `chezmoi age key` note in Bitwarden, encrypted secrets cannot be
> recovered on a new machine.** It is the single most important thing to keep safe.

---

## What's where in this repo

| Path | Maps to | What |
|---|---|---|
| `dot_zshrc` | `~/.zshrc` | shell config |
| `dot_gitconfig` | `~/.gitconfig` | git config |
| `dot_config/zed/` | `~/.config/zed/` | Zed editor (settings template + themes) |
| `dot_config/ghostty/` | `~/.config/ghostty/` | Ghostty terminal + themes |
| `dot_config/starship.toml` | `~/.config/...` | **Starship** prompt, inside **Ghostty** by default |
| `dot_config/herdr/` | `~/.config/herdr/` | optional Herdr multiplexer config for Ghostty or WezTerm |
| `dot_cursor/` | `~/.cursor/` | Cursor editor extensions (theme packages) |
| `private_Library/` | `~/Library/` | Sublime Text settings & themes |
| `.zedGoogleApiKey.age` | — | encrypted secret (data, not a deployed file) |
| `.chezmoi.toml.tmpl` | — | generates `~/.config/chezmoi/chezmoi.toml` on init |

(`dot_` → `.`, `private_` → permission `600`. See [`CLAUDE.md`](CLAUDE.md) for the theme
architecture and contributor notes.)
