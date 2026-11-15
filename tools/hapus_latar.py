#!/usr/bin/env python3
"""Hapus latar solid (putih atau warna lain) menjadi transparan dengan flood-fill dari tepi.

Pemakaian:
  python3 tools/hapus_latar.py MASUK.png KELUAR.png [--bg auto|#RRGGBB] [--tol 40] [--tepi 2]

- Piksel yang mirip warna latar DAN tersambung ke tepi gambar menjadi transparan.
- Garis tepi gelap (biru malam) menghentikan banjir, jadi bagian dalam yang putih
  (mata, awan, kilau) tetap utuh.
- Cincin tipis di sekeliling area transparan (--tepi piksel) diberi alpha sebagian dan
  warnanya dibersihkan dari campuran latar, sehingga tidak ada halo terang.
"""
import argparse
import pathlib

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

DENOM_FG = 250.0  # perkiraan jarak warna garis tepi gelap terhadap latar putih


def warna_latar(arr):
    sudut = np.stack([arr[0, 0], arr[0, -1], arr[-1, 0], arr[-1, -1]])
    return np.median(sudut, axis=0)


def hapus_latar(img, bg=None, tol=40.0, tepi=2):
    """Kembalikan RGBA dengan latar transparan. bg: tuple RGB atau None (otomatis dari sudut)."""
    arr = np.asarray(img.convert("RGB")).astype(np.float32)
    h, w = arr.shape[:2]
    bgv = warna_latar(arr) if bg is None else np.asarray(bg, np.float32)
    jarak = np.sqrt(((arr - bgv) ** 2).sum(axis=2))

    # .copy(): gambar dari numpy tidak bisa diisi banjir (flood fill) langsung
    kandidat = Image.fromarray(np.where(jarak <= tol, 255, 0).astype(np.uint8), "L").copy()
    tepi_xy = ([(x, 0) for x in range(w)] + [(x, h - 1) for x in range(w)]
               + [(0, y) for y in range(h)] + [(w - 1, y) for y in range(h)])
    for x, y in tepi_xy:
        if kandidat.getpixel((x, y)) == 255:
            ImageDraw.floodfill(kandidat, (x, y), 128, thresh=0)
    latar = np.asarray(kandidat) == 128

    ring = np.zeros_like(latar)
    if tepi > 0 and latar.any():
        dil = Image.fromarray((latar * 255).astype(np.uint8), "L")
        for _ in range(tepi):
            dil = dil.filter(ImageFilter.MaxFilter(3))
        ring = (np.asarray(dil) > 0) & ~latar

    a_ring = np.clip((jarak - tol) / max(DENOM_FG - tol, 1.0), 0.0, 1.0)
    alpha = np.full((h, w), 255.0, np.float32)
    out = arr.copy()
    alpha[latar] = 0.0
    alpha[ring] = a_ring[ring] * 255.0
    alpha[ring & (a_ring < 0.05)] = 0.0
    bersih = ring & (a_ring >= 0.15)
    a3 = a_ring[bersih][:, None]
    out[bersih] = np.clip((arr[bersih] - (1.0 - a3) * bgv) / a3, 0, 255)

    rgba = np.dstack([out, alpha]).clip(0, 255).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def _hex_ke_rgb(s):
    s = s.lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("masuk")
    ap.add_argument("keluar")
    ap.add_argument("--bg", default="auto", help="auto atau #RRGGBB")
    ap.add_argument("--tol", type=float, default=40.0)
    ap.add_argument("--tepi", type=int, default=2)
    a = ap.parse_args()

    img = Image.open(a.masuk)
    bg = None if a.bg == "auto" else _hex_ke_rgb(a.bg)
    hasil = hapus_latar(img, bg=bg, tol=a.tol, tepi=a.tepi)
    out = pathlib.Path(a.keluar)
    out.parent.mkdir(parents=True, exist_ok=True)
    hasil.save(out, optimize=True)
    print("wrote", out, hasil.size)


if __name__ == "__main__":
    main()
