# Muted project colours

A 32-colour palette for per-project sidebar tints (Supacode and anything that
stores one colour per repo). Each colour is a **single value that stays legible
in both light and dark mode** — the tool does not flip, so one hex must clear an
APCA contrast floor against both a light-grey and a near-black sidebar.

## Files

| Path | What |
|------|------|
| `colors/generate-palette.py` | Generator. OKLCH max-min packing under a dual-mode APCA floor. |
| `colors/muted-32-dual.json` | Source of truth — name, hex, OKLCH, APCA on both backgrounds. |
| `colors/Muted 32 dual.clr` | Reference copy of the macOS colour list. |
| `private_Library/.../Muted 32 dual.clr` | The deployed copy (chezmoi puts it in `~/Library/Colors/`). |

## Install / use

`chezmoi apply` drops `Muted 32 dual.clr` into `~/Library/Colors/`, where the
macOS colour picker reads it automatically. In an app's colour picker, open the
**Color Palettes** tab (swatch-grid icon), choose **Muted 32 dual** from the
dropdown, click the swatch per project. First launch after apply may need the
picker (or the app) reopened to rescan the directory.

## Regenerate

    cd colors && python3 generate-palette.py [N] [APCA_FLOOR]   # defaults: 32, 29

Reproducible (fixed RNG seed). Backgrounds are constants at the top of the
script — re-measure and edit them if targeting a different app's sidebar.

## The constraint, and the ceiling

One value across two modes spends the lightness axis on cross-mode legibility,
leaving mainly hue + chroma to separate colours. Measured minimum OKLab dE:
~0.061 at 12 colours, **0.053 at 32**, ~0.039 at 40. Comfortable is 0.05+,
usable to ~0.03, below that colour is a mnemonic and the repo name carries it.
At 32 the softest pairs are gold~citron, deep moss~deep green, coral~gold 2,
soft emerald~aqua — keep those on repos rarely seen side by side.

Chroma is capped at 0.11 to stay muted; lightness roams 0.54–0.70 within the
band that clears the APCA floor on both backgrounds.
