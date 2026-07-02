#!/usr/bin/env python3
"""
Generate a muted OKLCH palette whose colours stay legible in BOTH light and
dark mode from a SINGLE stored value (no per-mode variant).

Why this exists: tools like Supacode store one tint per project and paint it on
both a light and a dark sidebar without flipping. So each colour must clear an
APCA contrast floor against BOTH backgrounds at once, which pins lightness to a
narrow band and leaves mainly hue + chroma to separate colours. This script
packs N colours to maximise the minimum perceptual distance (OKLab dE) under
that constraint, and reports where the set goes soft.

Outputs (next to this script):
  - muted-<N>-dual.json   source of truth (name, hex, oklch, APCA on both bg)
  - Muted <N> dual.clr     macOS NSColorList for the system colour picker
                           (also install to ~/Library/Colors/ to auto-appear)

Requires: pyobjc (system python3 on macOS has it) for the .clr writer.
Run:  python3 generate-palette.py [N] [APCA_FLOOR]
Defaults: N=32, floor=29. Reproducible — fixed RNG seed.

Ceiling, measured: with one value across two modes, min dE is ~0.061 at 12,
~0.053 at 32, ~0.039 at 40. Below ~0.03 colour is a mnemonic, not an ID.
"""
import math, random, json, os, sys

# --- Sidebar backgrounds the tint must survive. Re-measure per app if needed. ---
LIGHT = "#CFCFD1"
DARK  = "#1D1D1F"
# --- Muted constraint + legibility floor ---
CHROMA_MIN, CHROMA_MAX = 0.05, 0.11   # >0.11 stops reading as muted
L_MIN, L_MAX           = 0.54, 0.70   # band that clears both backgrounds
SEED                   = 7            # fixed => same palette every run

# ---------- OKLCH -> sRGB ----------
def _lin(L, a, b):
    l_ = L + .3963377774*a + .2158037573*b
    m_ = L - .1055613458*a - .0638541728*b
    s_ = L - .0894841775*a - 1.291485548*b
    l, m, s = l_**3, m_**3, s_**3
    return (4.0767416621*l - 3.3077115913*m + .2309699292*s,
            -1.2684380046*l + 2.6097574011*m - .3413193965*s,
            -.0041960863*l - .7034186147*m + 1.707614701*s)

def in_gamut(L, C, H):
    a, b = C*math.cos(math.radians(H)), C*math.sin(math.radians(H))
    return all(-1e-4 <= v <= 1.0001 for v in _lin(L, a, b))

def _enc(x):
    x = max(0., min(1., x))
    return 1.055*x**(1/2.4) - .055 if x > .0031308 else 12.92*x

def _srgb(L, C, H):
    a, b = C*math.cos(math.radians(H)), C*math.sin(math.radians(H))
    r, g, bl = _lin(L, a, b)
    return _enc(r), _enc(g), _enc(bl)

def hexof(L, C, H):
    r, g, b = _srgb(L, C, H)
    return '#{:02X}{:02X}{:02X}'.format(round(r*255), round(g*255), round(b*255))

# ---------- APCA (SAPC-8 / 0.1.9) ----------
def _Y(r, g, b):
    return .2126*r**2.4 + .7152*g**2.4 + .0722*b**2.4

def _Yhex(hx):
    r, g, b = [int(hx[i:i+2], 16)/255 for i in (1, 3, 5)]
    return _Y(r, g, b)

def apca(Yt, Yb):
    if Yt <= .022: Yt += (.022 - Yt)**1.414
    if Yb <= .022: Yb += (.022 - Yb)**1.414
    if abs(Yb - Yt) < .0005: return 0.
    if Yb > Yt:
        S = (Yb**.56 - Yt**.57)*1.14; C = 0. if S < .1 else S - .027
    else:
        S = (Yb**.65 - Yt**.62)*1.14; C = 0. if S > -.1 else S + .027
    return abs(C*100)

YL, YD = _Yhex(LIGHT), _Yhex(DARK)

def _ok(L, C, H, floor):
    if not in_gamut(L, C, H): return False
    Yt = _Y(*_srgb(L, C, H))
    return apca(Yt, YL) >= floor and apca(Yt, YD) >= floor

# ---------- max-min packing ----------
def _lab(L, C, H):
    return (L*0.9, C*math.cos(math.radians(H)), C*math.sin(math.radians(H)))  # down-weight L

def _dE(p, q):
    return math.dist(_lab(*p), _lab(*q))

def pack(N, floor, pool=9000, iters=16000):
    rng = random.Random(SEED)
    def rp():
        for _ in range(500):
            L, C, H = rng.uniform(L_MIN, L_MAX), rng.uniform(CHROMA_MIN, CHROMA_MAX), rng.uniform(0, 360)
            if _ok(L, C, H, floor): return [L, C, H]
        return None
    cand = [p for p in (rp() for _ in range(pool)) if p]
    pts = [cand[0]]
    while len(pts) < N:                       # greedy farthest-first
        best, bd = None, -1
        for c in cand:
            d = min(_dE(c, p) for p in pts)
            if d > bd: bd, best = d, c
        pts.append(best)
    def mp(P):
        m = 9
        for i in range(len(P)):
            for j in range(i+1, len(P)): m = min(m, _dE(P[i], P[j]))
        return m
    cur = mp(pts)
    for _ in range(iters):                    # relax the worst-placed point
        wi, wd = 0, 9
        for i in range(len(pts)):
            d = min(_dE(pts[i], pts[j]) for j in range(len(pts)) if j != i)
            if d < wd: wd, wi = d, i
        old = pts[wi][:]
        c2 = [min(L_MAX, max(L_MIN, old[0] + rng.uniform(-.03, .03))),
              min(CHROMA_MAX, max(CHROMA_MIN, old[1] + rng.uniform(-.02, .02))),
              (old[2] + rng.uniform(-22, 22)) % 360]
        if not _ok(*c2, floor): continue
        pts[wi] = c2
        if mp(pts) >= cur - 1e-9: cur = mp(pts)
        else: pts[wi] = old
    return pts, mp(pts)

_WORDS = [(0,"red"),(18,"coral"),(36,"rust"),(52,"amber"),(70,"gold"),(88,"citron"),
(105,"lime"),(120,"moss"),(140,"green"),(158,"emerald"),(178,"teal"),(196,"aqua"),
(212,"cyan"),(228,"sky"),(244,"azure"),(258,"blue"),(272,"indigo"),(288,"violet"),
(302,"purple"),(318,"plum"),(334,"magenta"),(350,"rose")]
def _huename(H):
    return min(_WORDS, key=lambda w: min(abs(H-w[0]), 360-abs(H-w[0])))[1]

def main():
    N     = int(sys.argv[1]) if len(sys.argv) > 1 else 32
    floor = float(sys.argv[2]) if len(sys.argv) > 2 else 29.0
    here  = os.path.dirname(os.path.abspath(__file__))

    pts, mindE = pack(N, floor)
    pts.sort(key=lambda p: p[2])
    lib, used = [], {}
    for L, C, H in pts:
        tone = "soft " if L > .655 else "deep " if L < .585 else ""
        nm = (tone + _huename(H)).strip()
        used[nm] = used.get(nm, 0) + 1
        if used[nm] > 1: nm = f"{nm} {used[nm]}"
        Yt = _Y(*_srgb(L, C, H))
        lib.append({"name": nm, "hex": hexof(L, C, H),
                    "oklch": [round(L, 3), round(C, 3), round(H, 1)],
                    "Lc_light": round(apca(Yt, YL)), "Lc_dark": round(apca(Yt, YD))})

    jpath = os.path.join(here, f"muted-{N}-dual.json")
    json.dump({"count": N, "min_deltaE": round(mindE, 3), "apca_floor": floor,
               "backgrounds": {"light": LIGHT, "dark": DARK}, "colors": lib},
              open(jpath, "w"), indent=2)

    try:
        from AppKit import NSColorList, NSColor
        from Foundation import NSURL
        cl = NSColorList.alloc().initWithName_(f"Muted {N} dual")
        for c in lib:
            r, g, b = [int(c["hex"][i:i+2], 16)/255 for i in (1, 3, 5)]
            cl.setColor_forKey_(NSColor.colorWithSRGBRed_green_blue_alpha_(r, g, b, 1.), c["name"])
        cpath = os.path.join(here, f"Muted {N} dual.clr")
        cl.writeToURL_error_(NSURL.fileURLWithPath_(cpath), None)
        print(f"wrote {cpath}")
    except ImportError:
        print("pyobjc missing — wrote JSON only, skipped .clr")

    print(f"wrote {jpath}")
    print(f"{N} colours | min OKLab dE = {mindE:.3f} | APCA floor {floor:.0f} on both backgrounds")

if __name__ == "__main__":
    main()
