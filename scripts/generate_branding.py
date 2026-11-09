"""Generate the C Around icon set from one drawing.

Run from the repository root:

    python scripts/generate_branding.py

The script is the source of truth for every raster icon: the Windows .ico, the
Android launcher mipmaps, the Linux icon, the landing-page favicon and the
store artwork. Redrawing the mark means running this again, never editing the
PNGs by hand.

The mark is a bold "C" (the product initial) with three awareness arcs leaving
it and an amber origin dot. It is drawn at 4x and downsampled with Lanczos so
the 16 px favicon still reads as a C rather than a smudge.
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "branding"

INK = (7, 16, 24, 255)
INK_DEEP = (4, 10, 16, 255)
CYAN = (47, 227, 200, 255)
CYAN_DIM = (26, 150, 136, 255)
AMBER = (255, 183, 77, 255)
WHITE = (244, 250, 252, 255)

SCALE = 4
SIZE = 1024
S = SIZE * SCALE


def rounded_background() -> Image.Image:
    """Ink tile with a soft cyan glow in the lower right."""
    base = Image.new("RGBA", (S, S), INK_DEEP)
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    cx, cy = int(S * 0.78), int(S * 0.76)
    max_r = int(S * 0.72)
    for i in range(max_r, 0, -2):
        t = i / max_r
        alpha = int(46 * (1 - t) ** 2)
        if alpha <= 0:
            continue
        gd.ellipse(
            (cx - i, cy - i, cx + i, cy + i),
            fill=(47, 227, 200, alpha),
        )
    base = Image.alpha_composite(base, glow)

    mask = Image.new("L", (S, S), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((0, 0, S - 1, S - 1), radius=int(S * 0.22), fill=255)
    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    out.paste(base, (0, 0), mask)
    return out


def draw_mark(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)

    # The C: a thick ring open on the right.
    cx, cy = S * 0.445, S * 0.5
    r = S * 0.245
    width = S * 0.092
    # PIL angles run clockwise from 3 o'clock. Leave a 66 degree mouth.
    d.arc(
        (cx - r, cy - r, cx + r, cy + r),
        start=33,
        end=327,
        fill=CYAN,
        width=int(width),
    )
    # Awareness arcs leaving the C toward the right.
    ox, oy = S * 0.735, S * 0.5
    for radius, width_f, alpha in (
        (S * 0.085, 0.026, 255),
        (S * 0.155, 0.022, 210),
        (S * 0.225, 0.018, 150),
    ):
        layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        ld = ImageDraw.Draw(layer)
        ld.arc(
            (ox - radius, oy - radius, ox + radius, oy + radius),
            start=-46,
            end=46,
            fill=(47, 227, 200, alpha),
            width=int(S * width_f),
        )
        img.alpha_composite(layer)

    # Origin dot.
    dot = S * 0.032
    d.ellipse((ox - dot, oy - dot, ox + dot, oy + dot), fill=AMBER)


def render_icon() -> Image.Image:
    img = rounded_background()
    draw_mark(img)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def render_transparent() -> Image.Image:
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    draw_mark(img)
    return img.resize((SIZE, SIZE), Image.LANCZOS)


def save_png(img: Image.Image, path: Path, size: int) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.resize((size, size), Image.LANCZOS).save(path, "PNG", optimize=True)


def main() -> None:
    icon = render_icon()
    transparent = render_transparent()
    ASSETS.mkdir(parents=True, exist_ok=True)

    save_png(icon, ASSETS / "icon-1024.png", 1024)
    save_png(icon, ASSETS / "icon-512.png", 512)
    save_png(icon, ASSETS / "icon-256.png", 256)
    save_png(icon, ASSETS / "icon-128.png", 128)
    save_png(icon, ASSETS / "icon-64.png", 64)
    save_png(transparent, ASSETS / "mark-transparent-1024.png", 1024)

    # Windows .ico, multi-resolution. 16 and 20 are what Explorer and the
    # taskbar actually use, so they are included explicitly.
    ico_sizes = [16, 20, 24, 32, 40, 48, 64, 128, 256]
    icon.save(
        ASSETS / "c-around.ico",
        format="ICO",
        sizes=[(s, s) for s in ico_sizes],
    )

    # Android launcher mipmaps. Legacy square icons are used because the app
    # ships outside Play Store; adaptive icons would need a separate foreground
    # layer and add nothing for sideloaded builds.
    android = ROOT / "app" / "android" / "app" / "src" / "main" / "res"
    for folder, px in (
        ("mipmap-mdpi", 48),
        ("mipmap-hdpi", 72),
        ("mipmap-xhdpi", 96),
        ("mipmap-xxhdpi", 144),
        ("mipmap-xxxhdpi", 192),
    ):
        save_png(icon, android / folder / "ic_launcher.png", px)

    # Windows runner icon.
    win_icon = ROOT / "app" / "windows" / "runner" / "resources" / "app_icon.ico"
    win_icon.parent.mkdir(parents=True, exist_ok=True)
    icon.save(win_icon, format="ICO", sizes=[(s, s) for s in ico_sizes])

    # Linux icon.
    save_png(icon, ROOT / "app" / "linux" / "icon.png", 512)

    # Landing page.
    landing = ROOT / "app" / "landing"
    save_png(icon, landing / "icon-512.png", 512)
    save_png(icon, landing / "favicon-32.png", 32)
    save_png(icon, landing / "favicon-16.png", 16)
    save_png(icon, landing / "apple-touch-icon.png", 180)

    print("Branding written to", ASSETS)


if __name__ == "__main__":
    main()
