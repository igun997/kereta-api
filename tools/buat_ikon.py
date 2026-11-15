#!/usr/bin/env python3
"""Membuat ikon peluncur Android (legacy + adaptive), iOS, web, dan logo splash dari assets/brand.

Sumber:  assets/brand/app_icon_1024.png (opaque), app_icon_foreground.png (transparan, objek di 66% tengah),
         assets/brand/splash_logo.png
Jalankan: python3 tools/buat_ikon.py
"""
import json
import pathlib

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
BRAND = ROOT / "assets" / "brand"
RES = ROOT / "android" / "app" / "src" / "main" / "res"
IOS = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
WEB = ROOT / "web"
LANGIT = "#6FD3FF"

icon = Image.open(BRAND / "app_icon_1024.png").convert("RGB")
fg = Image.open(BRAND / "app_icon_foreground.png").convert("RGBA")
splash = Image.open(BRAND / "splash_logo.png").convert("RGBA")


def simpan(im, path, size=None, mode=None):
    path.parent.mkdir(parents=True, exist_ok=True)
    if size:
        im = im.resize((size, size), Image.LANCZOS)
    if mode:
        im = im.convert(mode)
    im.save(path, optimize=True)


# ---- Android legacy + adaptive
for nama, px, px_fg in (("mdpi", 48, 108), ("hdpi", 72, 162), ("xhdpi", 96, 216),
                        ("xxhdpi", 144, 324), ("xxxhdpi", 192, 432)):
    simpan(icon, RES / f"mipmap-{nama}" / "ic_launcher.png", px)
    simpan(fg, RES / f"mipmap-{nama}" / "ic_launcher_foreground.png", px_fg)

(RES / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
(RES / "mipmap-anydpi-v26" / "ic_launcher.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@color/ic_launcher_background"/>\n'
    '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
    '    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>\n'
    '</adaptive-icon>\n')
(RES / "values" / "ic_launcher_background.xml").write_text(
    '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
    f'    <color name="ic_launcher_background">{LANGIT}</color>\n</resources>\n')

# ---- Splash Android (logo di tengah, latar langit)
simpan(splash, RES / "drawable-xxhdpi" / "splash_logo.png", 480)
simpan(splash, RES / "drawable-xhdpi" / "splash_logo.png", 320)
simpan(splash, RES / "drawable-hdpi" / "splash_logo.png", 240)
simpan(splash, RES / "drawable-mdpi" / "splash_logo.png", 160)
launch = (
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<layer-list xmlns:android="http://schemas.android.com/apk/res/android">\n'
    f'    <item><color android:color="{LANGIT}"/></item>\n'
    '    <item>\n'
    '        <bitmap android:gravity="center" android:src="@drawable/splash_logo"/>\n'
    '    </item>\n'
    '</layer-list>\n')
(RES / "drawable").mkdir(parents=True, exist_ok=True)
(RES / "drawable" / "launch_background.xml").write_text(launch)
(RES / "drawable-v21").mkdir(parents=True, exist_ok=True)
(RES / "drawable-v21" / "launch_background.xml").write_text(launch)

# ---- iOS (tanpa alfa, semua ukuran dari Contents.json)
contents = json.loads((IOS / "Contents.json").read_text())
for im in contents["images"]:
    w = float(im["size"].split("x")[0])
    scale = int(im["scale"].rstrip("x"))
    simpan(icon, IOS / im["filename"], int(round(w * scale)), mode="RGB")

# ---- Web
simpan(icon, WEB / "icons" / "Icon-192.png", 192)
simpan(icon, WEB / "icons" / "Icon-512.png", 512)
simpan(icon, WEB / "favicon.png", 64)
for px in (192, 512):
    kanvas = Image.new("RGBA", (px, px), LANGIT)
    f = fg.resize((px, px), Image.LANCZOS)
    kanvas.alpha_composite(f)
    simpan(kanvas, WEB / "icons" / f"Icon-maskable-{px}.png", mode="RGB")

print("ikon selesai")
