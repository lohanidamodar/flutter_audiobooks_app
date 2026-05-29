#!/usr/bin/env python3
"""Wrap raw app screenshots in branded marketing frames for the Play Store."""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "marketing")
os.makedirs(OUT, exist_ok=True)

# Brand palette (matches the app's amber / espresso theme)
ACCENT = (232, 163, 61)        # #E8A33D
ACCENT_SOFT = (245, 222, 179)  # warm cream
INK_TOP = (38, 28, 16)         # warm dark top
INK_BOTTOM = (8, 7, 6)         # near-black espresso

CANVAS = (1320, 2600)  # 1.97:1 — under Play Store's 2:1 max
SHADOW = (0, 0, 0)

SERIF = "/tmp/Fraunces.ttf"
SANS = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def font(path, size, weight=None):
    f = ImageFont.truetype(path, size)
    if weight is not None:
        try:
            # Fraunces axes order: SOFT, WONK, opsz, wght
            f.set_variation_by_axes([0.0, 0.0, 144.0, weight])
        except Exception:
            pass
    return f


SHOTS = [
    ("01_home.png", "Thousands of free\nclassic audiobooks", "Browse the LibriVox library"),
    ("02_book_detail.png", "Pick up right\nwhere you left off", "Every chapter, one tap away"),
    ("03_now_playing.png", "Immersive,\ndistraction-free", "A player made for listening"),
    ("04_library.png", "Your shelf —\nonline or offline", "Download once, listen anywhere"),
    ("05_search.png", "Find any classic\nin seconds", "Search the whole catalogue"),
]


def gradient(size):
    w, h = size
    base = Image.new("RGB", size)
    px = base.load()
    for y in range(h):
        t = y / (h - 1)
        # ease toward the dark bottom
        te = t ** 0.85
        r = int(INK_TOP[0] + (INK_BOTTOM[0] - INK_TOP[0]) * te)
        g = int(INK_TOP[1] + (INK_BOTTOM[1] - INK_TOP[1]) * te)
        b = int(INK_TOP[2] + (INK_BOTTOM[2] - INK_TOP[2]) * te)
        for x in range(w):
            px[x, y] = (r, g, b)
    # soft amber glow behind the headline
    glow = Image.new("L", size, 0)
    gd = ImageDraw.Draw(glow)
    gd.ellipse([w * 0.1, -h * 0.18, w * 0.9, h * 0.34], fill=120)
    glow = glow.filter(ImageFilter.GaussianBlur(160))
    amber = Image.new("RGB", size, ACCENT)
    base = Image.composite(amber, base, glow.point(lambda v: int(v * 0.55)))
    return base


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, img.size[0], img.size[1]], radius=radius, fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def draw_centered(draw, cx, y, text, fnt, fill, spacing=10):
    bbox = draw.textbbox((0, 0), text, font=fnt, spacing=spacing, align="center")
    w = bbox[2] - bbox[0]
    draw.multiline_text((cx - w / 2 - bbox[0], y), text, font=fnt, fill=fill,
                        spacing=spacing, align="center")
    return bbox[3] - bbox[1]


def tracked(draw, cx, y, text, fnt, fill, tracking=8):
    widths = [draw.textlength(ch, font=fnt) + tracking for ch in text]
    total = sum(widths) - tracking
    x = cx - total / 2
    for ch, wch in zip(text, widths):
        draw.text((x, y), ch, font=fnt, fill=fill)
        x += wch


head_font = font(SERIF, 104, weight=600)
kicker_font = ImageFont.truetype(SANS, 30)
sub_font = ImageFont.truetype(SANS, 38)

cw, ch = CANVAS
for name, headline, sub in SHOTS:
    canvas = gradient(CANVAS)
    d = ImageDraw.Draw(canvas)

    # kicker (app name, tracked small caps)
    tracked(d, cw / 2, 150, "A U D I O B O O K S", kicker_font, ACCENT, tracking=6)

    # headline
    draw_centered(d, cw / 2, 215, headline, head_font, ACCENT_SOFT, spacing=12)

    # subheading
    sb = d.textbbox((0, 0), sub, font=sub_font)
    d.text((cw / 2 - (sb[2] - sb[0]) / 2, 470), sub, font=sub_font,
           fill=(210, 198, 180))

    # device-framed screenshot
    shot = Image.open(os.path.join(HERE, name)).convert("RGB")
    target_w = int(cw * 0.70)
    scale = target_w / shot.width
    target_h = int(shot.height * scale)
    shot = shot.resize((target_w, target_h), Image.LANCZOS)
    radius = 56
    framed = rounded(shot, radius)

    # bezel (slightly larger rounded dark rect behind)
    bez_pad = 12
    bez = Image.new("RGBA", (target_w + bez_pad * 2, target_h + bez_pad * 2),
                    (0, 0, 0, 0))
    ImageDraw.Draw(bez).rounded_rectangle(
        [0, 0, bez.size[0], bez.size[1]], radius=radius + bez_pad,
        fill=(20, 17, 14, 255))

    px = (cw - bez.size[0]) // 2
    py = 560

    # drop shadow
    shadow = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle(
        [px, py + 26, px + bez.size[0], py + 26 + bez.size[1]],
        radius=radius + bez_pad, fill=(0, 0, 0, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(40))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow)

    canvas.alpha_composite(bez, (px, py))
    canvas.alpha_composite(framed, (px + bez_pad, py + bez_pad))

    out_path = os.path.join(OUT, name)
    canvas.convert("RGB").save(out_path, "PNG")
    print("wrote", out_path, canvas.size)
