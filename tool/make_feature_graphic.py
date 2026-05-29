#!/usr/bin/env python3
"""Play Store feature graphic (1024x500): icon + wordmark + tagline on the
amber->espresso brand gradient. No third-party cover art."""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "playstore_screenshots", "feature_graphic.png")
ICON = os.path.join(ROOT, "assets", "icon", "icon.png")

W, H = 1024, 500
ACCENT = (232, 163, 61)
CREAM = (245, 233, 209)
INK_L = (44, 32, 18)
INK_R = (10, 8, 6)
SERIF = "/tmp/Fraunces.ttf"
SANS = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def font(path, size, weight=None):
    f = ImageFont.truetype(path, size)
    if weight is not None:
        try:
            f.set_variation_by_axes([0.0, 0.0, 144.0, weight])
        except Exception:
            pass
    return f


# diagonal gradient
img = Image.new("RGB", (W, H))
px = img.load()
for y in range(H):
    for x in range(W):
        t = (x / W) * 0.6 + (y / H) * 0.4
        r = int(INK_L[0] + (INK_R[0] - INK_L[0]) * t)
        g = int(INK_L[1] + (INK_R[1] - INK_L[1]) * t)
        b = int(INK_L[2] + (INK_R[2] - INK_L[2]) * t)
        px[x, y] = (r, g, b)

# amber glow behind the icon (left)
glow = Image.new("L", (W, H), 0)
ImageDraw.Draw(glow).ellipse([-120, 40, 460, 520], fill=120)
glow = glow.filter(ImageFilter.GaussianBlur(110))
img = Image.composite(Image.new("RGB", (W, H), ACCENT), img,
                      glow.point(lambda v: int(v * 0.5)))

img = img.convert("RGBA")

# icon (rounded), left side
icon = Image.open(ICON).convert("RGBA").resize((300, 300), Image.LANCZOS)
mask = Image.new("L", (300, 300), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, 300, 300], radius=66, fill=255)
# soft shadow
shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(shadow).rounded_rectangle(
    [70, 110, 370, 410], radius=66, fill=(0, 0, 0, 160))
shadow = shadow.filter(ImageFilter.GaussianBlur(26))
img = Image.alpha_composite(img, shadow)
img.paste(icon, (62, 100), mask)

d = ImageDraw.Draw(img)
tx = 410
# wordmark
d.text((tx, 150), "Audiobooks", font=font(SERIF, 96, weight=600), fill=CREAM)
# tagline
d.text((tx, 268), "Free classic audiobooks,", font=ImageFont.truetype(SANS, 40),
       fill=(214, 202, 184))
d.text((tx, 318), "beautifully read.", font=ImageFont.truetype(SANS, 40),
       fill=(214, 202, 184))
# accent rule
d.rounded_rectangle([tx, 240, tx + 110, 248], radius=4, fill=ACCENT)

img.convert("RGB").save(OUT, "PNG")
print("wrote", OUT, img.size)
