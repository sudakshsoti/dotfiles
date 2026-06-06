#!/usr/bin/env bash
#
# Bootstrap a brand-new Mac from these dotfiles.
#
# Usage — open Terminal and paste this one line:
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/sudakshsoti/dotfiles/main/install.sh)
#
# What it does, in order:
#   1. Installs Homebrew              (if it's missing)
#   2. Installs chezmoi, age, bitwarden-cli
#   3. Restores your age secret key from Bitwarden -> ~/.config/chezmoi/key.txt
#   4. Pulls these dotfiles and applies them (secrets are decrypted automatically)
#   5. Clones the private fonts repo and installs the fonts
#
# Safe to re-run: it skips anything that's already done.

set -euo pipefail

GH_USER="sudakshsoti"
KEY_PATH="$HOME/.config/chezmoi/key.txt"
BW_ITEM="chezmoi age key"
PRIVATE_REPO="git@github.com:${GH_USER}/dotfiles-private.git"
PRIVATE_DIR="$HOME/dev/dotfiles-private"

bold() { printf "\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n" "$1"; }
ok()   { printf "    \033[32m✓\033[0m %s\n" "$1"; }
warn() { printf "    \033[33m!\033[0m %s\n" "$1"; }

# --- 1. Homebrew -----------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  bold "Installing Homebrew (you may be asked for your Mac login password)"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# Make brew available in this shell session
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -x /usr/local/bin/brew ]    && eval "$(/usr/local/bin/brew shellenv)"
ok "Homebrew ready"

# --- 2. Tools --------------------------------------------------------------
bold "Installing chezmoi, age, and the Bitwarden CLI"
brew install chezmoi age bitwarden-cli >/dev/null
ok "Tools installed"

# Neovim + tree-sitter CLI (kickstart.nvim compiles treesitter parsers with it;
# the plain `tree-sitter` formula is only the library, so install the CLI).
bold "Installing Neovim and the tree-sitter CLI"
brew install neovim tree-sitter-cli >/dev/null
ok "Neovim ready (run \`nvim\` once to let vim.pack install plugins + LSP servers)"

# --- 3. Restore the age key from Bitwarden --------------------------------
if [ -f "$KEY_PATH" ]; then
  ok "Age key already present at $KEY_PATH — skipping Bitwarden restore"
else
  bold "Restoring your age key from Bitwarden"
  if ! bw login --check >/dev/null 2>&1; then
    warn "Log in to Bitwarden (enter your email, then your master password):"
    bw login < /dev/tty
  fi
  warn "Unlock Bitwarden (enter your master password):"
  BW_SESSION="$(bw unlock --raw < /dev/tty)"
  export BW_SESSION
  mkdir -p "$(dirname "$KEY_PATH")"
  bw get notes "$BW_ITEM" --session "$BW_SESSION" > "$KEY_PATH"
  chmod 600 "$KEY_PATH"
  if ! grep -q 'AGE-SECRET-KEY' "$KEY_PATH"; then
    warn "That note doesn't look like a valid age key. Check the Bitwarden note named '$BW_ITEM'."
    exit 1
  fi
  ok "Age key restored to $KEY_PATH"
fi

# --- 4. Pull + apply dotfiles ---------------------------------------------
bold "Pulling dotfiles and applying them (this decrypts your secrets)"
chezmoi init --apply "$GH_USER"
ok "Dotfiles applied"

# --- 5. Fonts (private repo) ----------------------------------------------
bold "Installing licensed fonts (MonoLisa + Berkeley Mono) from the private repo"
if [ ! -d "$PRIVATE_DIR/.git" ]; then
  mkdir -p "$(dirname "$PRIVATE_DIR")"
  if ! git clone "$PRIVATE_REPO" "$PRIVATE_DIR" 2>/dev/null; then
    warn "Couldn't clone the private fonts repo (needs GitHub SSH access)."
    warn "Set up SSH, then run these three lines by hand:"
    warn "  git clone $PRIVATE_REPO $PRIVATE_DIR"
    warn "  cp $PRIVATE_DIR/fonts/**/*.ttf ~/Library/Fonts/"
    warn "  fc-cache -f 2>/dev/null || true"
    PRIVATE_DIR=""
  fi
fi
if [ -n "$PRIVATE_DIR" ] && [ -d "$PRIVATE_DIR" ]; then
  mkdir -p "$HOME/Library/Fonts"
  find "$PRIVATE_DIR/fonts" -name '*.ttf' -exec cp {} "$HOME/Library/Fonts/" \;
  command -v fc-cache >/dev/null && fc-cache -f >/dev/null 2>&1 || true
  ok "Fonts installed into ~/Library/Fonts"
fi

bold "All done! 🎉"
echo "    Restart your terminal and editors to pick up fonts and settings."
