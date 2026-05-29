#!/usr/bin/env python3
"""Generate the Audiobooks launcher icon (full-bleed + adaptive foreground).

A cream play-triangle on an amber book with a darker spine, over an espresso
field with a soft amber glow. Rendered at 4x supersampling for crisp edges.
"""
import os
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                   "..", "assets", "icon")
os.makedirs(OUT, exist_ok=True)

SS = 4
SZ = 1024 * SS

ESPRESSO = (20, 17, 14)
AMBER = (232, 163, 61)
AMBER_DARK = (176, 116, 32)
CREAM = (248, 238, 214)


def book_motif(img, cx, cy, h):
    """Draw an amber book (portrait, left spine) with a cream play triangle."""
    d = ImageDraw.Draw(img)
    bw = h * 0.80
    bh = h
    left = cx - bw / 2
    top = cy - bh / 2
    right = cx + bw / 2
    bottom = cy + bh / 2
    radius = h * 0.14

    # book body
    d.rounded_rectangle([left, top, right, bottom], radius=radius, fill=AMBER)

    # spine strip on the left (darker), clipped to the book's rounded shape
    spine_w = bw * 0.20
    spine = Image.new("RGBA", img.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(spine)
    sd.rectangle([left, top, left + spine_w, bottom], fill=AMBER_DARK)
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [left, top, right, bottom], radius=radius, fill=255)
    img.alpha_composite(Image.composite(
        spine, Image.new("RGBA", img.size, (0, 0, 0, 0)), mask))

    # thin page-edge line just right of the spine
    d.line([left + spine_w, top + bh * 0.06, left + spine_w, bottom - bh * 0.06],
           fill=(255, 255, 255, 60), width=int(h * 0.012))

    # soft top-left highlight on the cover
    hi = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(hi).ellipse(
        [left + bw * 0.2, top - bh * 0.1, right + bw * 0.1, cy],
        fill=(255, 255, 255, 38))
    hi = hi.filter(ImageFilter.GaussianBlur(h * 0.06))
    img.alpha_composite(Image.composite(
        hi, Image.new("RGBA", img.size, (0, 0, 0, 0)), mask))

    # cream play triangle, centred on the cover (right of the spine)
    tcx = left + spine_w + (right - (left + spine_w)) / 2
    tr = h * 0.26
    tri = [
        (tcx - tr * 0.62, cy - tr),
        (tcx - tr * 0.62, cy + tr),
        (tcx + tr * 0.86, cy),
    ]
    d.polygon(tri, fill=CREAM)


def background(img):
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, SZ, SZ], fill=ESPRESSO + (255,))
    # amber radial glow, upper area
    glow = Image.new("L", img.size, 0)
    ImageDraw.Draw(glow).ellipse(
        [SZ * 0.04, -SZ * 0.22, SZ * 0.96, SZ * 0.72], fill=110)
    glow = glow.filter(ImageFilter.GaussianBlur(SZ * 0.10))
    amber = Image.new("RGBA", img.size, AMBER + (255,))
    img.alpha_composite(Image.composite(
        amber, Image.new("RGBA", img.size, (0, 0, 0, 0)), glow))


# Full-bleed icon (iOS + legacy Android) — motif ~60% of canvas
full = Image.new("RGBA", (SZ, SZ), (0, 0, 0, 0))
background(full)
book_motif(full, SZ / 2, SZ / 2, SZ * 0.56)
full = full.resize((1024, 1024), Image.LANCZOS).convert("RGB")
full.save(os.path.join(OUT, "icon.png"))

# Adaptive foreground (transparent; Android crops to ~66%, so keep motif small)
fg = Image.new("RGBA", (SZ, SZ), (0, 0, 0, 0))
book_motif(fg, SZ / 2, SZ / 2, SZ * 0.42)
fg = fg.resize((1024, 1024), Image.LANCZOS)
fg.save(os.path.join(OUT, "icon_foreground.png"))

print("wrote", os.path.join(OUT, "icon.png"))
print("wrote", os.path.join(OUT, "icon_foreground.png"))
