#!/usr/bin/env python3
"""Sprite kelompok A Kontrak Aset V3: roda (PIL), buah, paket, rumah.

Tuut, gerbong, dan hewan dipindah ke kelompok C (model 3D), jadi tidak dibuat di sini.

Pemakaian (dari root proyek):
  python3 tools/aset_kelompok_a.py gen [NAMA ...] [--varian 3] [--jobs 6]
      Varian AI mentah -> /tmp/kereta_v2_a/NAMA_vK.png (yang sudah ada dilewati).
  python3 tools/aset_kelompok_a.py lembar NAMA ...
      Lembar kontak varian mentah -> /tmp/kereta_v2_lembar_NAMA.png
  python3 tools/aset_kelompok_a.py rakit [NAMA=K ...]
      Proses sprite kelompok A ke assets/sprites/*.png dan manifest_a.json.
      K = nomor varian AI terpilih (default 1). Lalu jalankan tools/gabung_manifest.py.
  python3 tools/aset_kelompok_a.py lembar_akhir
      Lembar kontak sprite final -> docs/pratinjau/sprite_v2_a.png

Roda dan lencana digambar dengan kode (PIL, supersampling 4x). Untuk roda, nilai
roda_radius di manifest C harus sama dengan setengah diameter yang tercantum di sini.
"""
import argparse
import concurrent.futures as cf
import json
import math
import pathlib
import subprocess
import sys
import time

import numpy as np
from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
SPRITES = ROOT / "assets" / "sprites"
PRATINJAU = ROOT / "docs" / "pratinjau"
sys.path.insert(0, str(TOOLS))
from hapus_latar import hapus_latar  # noqa: E402

MENTAH = pathlib.Path("/tmp/kereta_v2_a")
PPU = 160
NAVY = (0x14, 0x21, 0x3D)
RED = (0xFF, 0x3B, 0x30)
YELLOW = (0xFF, 0xD6, 0x0A)
BLUE = (0x1E, 0x88, 0xFF)
WHITE = (255, 255, 255)
K = 4  # supersampling untuk gambar kode

GAYA_SAMPING = (
    "Children's game asset matching the reference logo style: flat vector cartoon, chunky rounded "
    "shapes, thick uniform dark navy (#14213D) outline, bright saturated colors (red #FF3B30, yellow "
    "#FFD60A, blue #1E88FF, green #34C759, orange #FF9500), one soft highlight, no gradients, no text, "
    "no shadow, plain pure white background, one single object centered with generous margin, full "
    "object visible, SIDE VIEW facing RIGHT"
)
GAYA_DEPAN = GAYA_SAMPING.replace("SIDE VIEW facing RIGHT", "FRONT VIEW facing the viewer")

# nama mentah AI -> (subjek, gaya)
AI_SPEK = {
    "paket_merah": (
        "A chubby red gift box with a thick white ribbon crossing it vertically and a white bow on top, "
        "square, plain",
        GAYA_DEPAN),
    "rumah_merah": (
        "A cute chubby small house with cream white walls, a big orange pointed roof, two round light-blue "
        "windows side by side, and one big bright red front door in the center, no chimney, no people",
        GAYA_DEPAN),
    "buah_apel": (
        "One big shiny red apple with a small green leaf on top, cute face with two small eyes and a smile",
        GAYA_DEPAN),
    "buah_pisang": (
        "One yellow banana, curved, cute face with two small eyes and a smile",
        GAYA_DEPAN),
    "buah_jeruk": (
        "One round orange fruit with a small green leaf on top, cute face with two small eyes and a smile",
        GAYA_DEPAN),
    "buah_blueberry": (
        "A pile of three round blueberries in a triangle (two at the bottom, one on top), blue fill, small "
        "white shine on each, cute small eyes",
        GAYA_DEPAN),
}

GESER = {"merah": 0, "kuning": 47, "biru": 208, "hijau": 132}  # derajat dari merah #FF3B30
BENTUK = {"merah": "lingkaran", "kuning": "bintang", "biru": "kotak", "hijau": "segitiga"}
BUAH = {"apel": 72, "pisang": 72, "jeruk": 72, "blueberry": 72}  # tinggi px
R_RODA_TUUT = 48     # tuut_roda diameter 96 px
R_RODA_GERBONG = 40  # gerbong_roda diameter 80 px


def ri(v):
    return int(round(float(v)))


# ---------- generate AI ----------

def gen_satu(nama, k, prompt, coba=3):
    keluar = MENTAH / f"{nama}_v{k}.png"
    if keluar.exists():
        return f"skip {keluar.name}"
    MENTAH.mkdir(parents=True, exist_ok=True)
    r = None
    for i in range(coba):
        r = subprocess.run(
            [sys.executable, str(TOOLS / "genimg.py"), str(keluar), prompt, "--size", "1024x1024"],
            capture_output=True, text=True, timeout=600,
        )
        if r.returncode == 0 and keluar.exists():
            return f"ok {keluar.name}"
        time.sleep(3 * (i + 1))
    return f"GAGAL {keluar.name}: {r.stderr.strip()[-200:]}"


def cmd_gen(nama_list, varian, jobs):
    nama_list = nama_list or list(AI_SPEK)
    tugas = []
    for n in nama_list:
        if n not in AI_SPEK:
            raise SystemExit(f"bukan nama AI kelompok A: {n}")
        subjek, gaya = AI_SPEK[n]
        for k in range(1, varian + 1):
            tugas.append((n, k, f"{subjek}. {gaya}"))
    with cf.ThreadPoolExecutor(max_workers=jobs) as ex:
        futs = [ex.submit(gen_satu, n, k, p) for n, k, p in tugas]
        for f in cf.as_completed(futs):
            print(f.result(), flush=True)


def cmd_lembar(nama_list):
    for nama in nama_list:
        berkas = sorted(MENTAH.glob(f"{nama}_v*.png"))
        if not berkas:
            print("tidak ada varian:", nama)
            continue
        sel = 340
        kol = min(3, len(berkas))
        baris = (len(berkas) + kol - 1) // kol
        lembar = Image.new("RGB", (sel * kol, sel * baris), (200, 200, 200))
        for i, f in enumerate(berkas):
            im = Image.open(f).convert("RGBA")
            putih = Image.new("RGBA", im.size, WHITE + (255,))
            putih.alpha_composite(im)
            putih = putih.convert("RGB")
            putih.thumbnail((sel - 10, sel - 10))
            lembar.paste(putih, ((i % kol) * sel + 5, (i // kol) * sel + 5))
        keluar = pathlib.Path(f"/tmp/kereta_v2_lembar_{nama}.png")
        lembar.save(keluar)
        print("wrote", keluar, [f.name for f in berkas])


# ---------- util gambar ----------

def mask(rgba):
    return np.asarray(rgba.getchannel("A")) > 8


def kotak_kuat(m, frac=0.1):
    """Kotak pembatas dari baris dan kolom yang berisi cukup piksel (abaikan piksel tepi yang tersebar)."""
    baris = m.sum(axis=1)
    kolom = m.sum(axis=0)
    r = np.where(baris >= frac * baris.max())[0]
    c = np.where(kolom >= frac * kolom.max())[0]
    return int(c[0]), int(r[0]), int(c[-1]) + 1, int(r[-1]) + 1


def kotak(m):
    baris = np.where(m.any(axis=1))[0]
    kolom = np.where(m.any(axis=0))[0]
    return int(kolom[0]), int(baris[0]), int(kolom[-1]) + 1, int(baris[-1]) + 1


def potong(rgba, margin=4):
    x0, y0, x1, y1 = kotak(mask(rgba))
    return rgba.crop((max(0, x0 - margin), max(0, y0 - margin),
                      min(rgba.width, x1 + margin), min(rgba.height, y1 + margin)))


def bersih_ai(path):
    """PNG mentah AI -> RGBA tanpa latar, dipotong ke kotak pembatas + margin 4 px."""
    img = Image.open(path).convert("RGBA")
    putih = Image.new("RGBA", img.size, WHITE + (255,))
    putih.alpha_composite(img)
    return potong(hapus_latar(putih.convert("RGB"), bg=WHITE, tol=40), 4)


def ke_lebar(img, w):
    return img.resize((w, max(1, ri(img.height * w / img.width))), Image.LANCZOS)


def ke_tinggi(img, h):
    return img.resize((max(1, ri(img.width * h / img.height)), h), Image.LANCZOS)


def mask_merah(rgba):
    """Piksel jenuh bernuansa merah (hue dalam ±30 derajat dari merah)."""
    hsv = np.asarray(rgba.convert("RGB").convert("HSV")).astype(np.int32)
    h, s = hsv[..., 0], hsv[..., 1]
    tol = 30 * 255 / 360
    return ((h <= tol) | (h >= 255 - tol)) & (s > 90) & mask(rgba)


def geser_hue(rgba, derajat, extra=None):
    """Geser hue piksel merah sebesar derajat. Garis navy dan warna lain tetap."""
    if derajat == 0:
        return rgba.copy()
    rgb = rgba.convert("RGB")
    hsv = np.asarray(rgb.convert("HSV")).astype(np.int32)
    merah = mask_merah(rgba)
    if extra is not None:
        merah &= extra
    hsv[..., 0] = np.where(merah, (hsv[..., 0] + round(derajat * 255 / 360)) % 256, hsv[..., 0])
    out = Image.fromarray(hsv.astype(np.uint8), "HSV").convert("RGB")
    r, g, b = out.split()
    return Image.merge("RGBA", (r, g, b, rgba.getchannel("A")))


def bentuk_titik(bentuk, c, r):
    if bentuk == "bintang":
        pts = []
        for i in range(10):
            rr = r if i % 2 == 0 else r * 0.5
            ang = -math.pi / 2 + i * math.pi / 5
            pts.append((c + rr * math.cos(ang), c + rr * math.sin(ang)))
        return pts
    # segitiga
    return [(c, c - r), (c + r * 0.866, c + r * 0.5), (c - r * 0.866, c + r * 0.5)]


def gambar_bentuk(dr, bentuk, c, r, warna):
    if bentuk == "lingkaran":
        dr.ellipse((c - r, c - r, c + r, c + r), fill=warna)
    elif bentuk == "kotak":
        dr.rounded_rectangle((c - r, c - r, c + r, c + r), radius=0.25 * r, fill=warna)
    else:
        dr.polygon(bentuk_titik(bentuk, c, r), fill=warna)


def lencana(rgba, bentuk, cx, cy, d):
    """Lencana putih bergaris navy tebal (bulat/bintang/kotak/segitiga), digambar K x lalu diperkecil."""
    S = d * K
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dr = ImageDraw.Draw(layer)
    c = S / 2
    r = S / 2 - 2 * K
    t = 0.17 * r
    gambar_bentuk(dr, bentuk, c, r, NAVY + (255,))
    gambar_bentuk(dr, bentuk, c, r - t, WHITE + (255,))
    rgba.alpha_composite(layer.resize((d, d), Image.LANCZOS), (ri(cx - d / 2), ri(cy - d / 2)))


def garis_tebal(dr, p, q, w, warna):
    dr.line([p, q], fill=warna, width=ri(w))
    for x, y in (p, q):
        dr.ellipse((x - w / 2, y - w / 2, x + w / 2, y + w / 2), fill=warna)


def gambar_roda(D, disc, naf, jari):
    """Roda cakram dengan naf besar dan 4 jari-jari tebal. Digambar K x lalu diperkecil ke D px."""
    S = D * K
    c = S / 2
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    dr = ImageDraw.Draw(layer)
    R = S / 2 - 2 * K
    t = 0.09 * S
    dr.ellipse((c - R, c - R, c + R, c + R), fill=NAVY + (255,))
    Ri = R - t
    dr.ellipse((c - Ri, c - Ri, c + Ri, c + Ri), fill=disc + (255,))
    lebar = 0.17 * S
    o = 0.04 * S
    panjang = Ri - lebar / 2 - o
    for sudut in (0, 90, 180, 270):
        a = math.radians(sudut)
        ujung = (c + panjang * math.cos(a), c + panjang * math.sin(a))
        garis_tebal(dr, (c, c), ujung, lebar + 2 * o, NAVY + (255,))
        garis_tebal(dr, (c, c), ujung, lebar, jari + (255,))
    rn = 0.2 * S
    dr.ellipse((c - rn - o, c - rn - o, c + rn + o, c + rn + o), fill=NAVY + (255,))
    dr.ellipse((c - rn, c - rn, c + rn, c + rn), fill=naf + (255,))
    return layer.resize((D, D), Image.LANCZOS)


# ---------- proses per jenis ----------

def proses_paket(base, warna):
    img = geser_hue(ke_lebar(base, 100), GESER[warna])
    x0, y0, x1, y1 = kotak(mask(img))
    lencana(img, BENTUK[warna], img.width / 2, (y0 + y1) / 2, ri(0.4 * (y1 - y0)))
    return img, {}, [img.width // 2, y1]


def proses_rumah(base, warna):
    img = ke_lebar(base, 320)
    merah = mask_merah(img)
    merah[: int(0.3 * img.height)] = False  # pintu ada di bagian bawah rumah
    px0, py0, px1, py1 = kotak_kuat(merah)
    pintu = np.zeros_like(merah)
    pintu[py0:py1, px0:px1] = merah[py0:py1, px0:px1]
    anchors = {"pintu": [ri((px0 + px1) / 2), ri((py0 + py1) / 2)]}
    img = geser_hue(img, GESER[warna], extra=pintu)
    d = ri(0.6 * (px1 - px0))
    cy = max(d / 2 + 2, py0 - d / 2 - 6)
    lencana(img, BENTUK[warna], (px0 + px1) / 2, cy, d)
    _, _, _, y1 = kotak(mask(img))
    return img, anchors, [img.width // 2, y1]


def proses_tinggi(base, h):
    img = ke_tinggi(base, h)
    x0, _, x1, y1 = kotak(mask(img))
    return img, {}, [ri((x0 + x1) / 2), y1]


def bangun(pilih):
    ai = {}
    for n in AI_SPEK:
        berkas = MENTAH / f"{n}_v{pilih.get(n, 1)}.png"
        if not berkas.exists():
            raise SystemExit(f"belum ada varian mentah: {berkas}")
        ai[n] = bersih_ai(berkas)
    hasil = {}
    hasil["tuut_roda"] = (gambar_roda(2 * R_RODA_TUUT, BLUE, YELLOW, YELLOW), {},
                          [R_RODA_TUUT, R_RODA_TUUT])
    hasil["gerbong_roda"] = (gambar_roda(2 * R_RODA_GERBONG, RED, YELLOW, WHITE), {},
                             [R_RODA_GERBONG, R_RODA_GERBONG])
    for w in ("merah", "kuning", "biru"):
        hasil[f"paket_{w}"] = proses_paket(ai["paket_merah"], w)
    for w in ("merah", "kuning", "biru"):
        hasil[f"rumah_{w}"] = proses_rumah(ai["rumah_merah"], w)
    for b, t in BUAH.items():
        hasil[f"buah_{b}"] = proses_tinggi(ai[f"buah_{b}"], t)
    return hasil


def cmd_rakit(pasangan):
    pilih = {}
    for p in pasangan:
        nama, k = p.split("=", 1)
        pilih[nama] = int(k)
    hasil = bangun(pilih)
    SPRITES.mkdir(parents=True, exist_ok=True)
    sprites = {}
    for nama, (img, anchors, pivot) in hasil.items():
        img.save(SPRITES / f"{nama}.png", optimize=True)
        sprites[nama] = {"file": f"{nama}.png", "w": img.width, "h": img.height,
                         "pivot": pivot, "anchors": anchors}
        print("wrote", nama, img.size, "pivot", pivot, "anchors", anchors)
    data = {"ppu": PPU, "sprites": sprites}
    (SPRITES / "manifest_a.json").write_text(json.dumps(data, indent=1, ensure_ascii=False) + "\n")
    print("wrote manifest_a.json", len(sprites), "sprite")


def cmd_lembar_akhir():
    man = json.loads((SPRITES / "manifest_a.json").read_text())["sprites"]
    nama = list(man)
    cel = 220
    kol = 4
    baris = (len(nama) + kol - 1) // kol
    lembar = Image.new("RGB", (kol * (cel * 2 + 16), baris * (cel + 26)), (255, 255, 255))
    dr = ImageDraw.Draw(lembar)
    for i, n in enumerate(nama):
        im = Image.open(SPRITES / man[n]["file"]).convert("RGBA")
        im.thumbnail((cel - 10, cel - 10), Image.LANCZOS)
        x0 = (i % kol) * (cel * 2 + 16)
        y0 = (i // kol) * (cel + 26)
        dr.text((x0 + 4, y0 + 2), n, fill=(0, 0, 0))
        for j, warna in enumerate(((0x14, 0x21, 0x3D), (0xFF, 0xD6, 0x0A))):
            t = Image.new("RGBA", (cel, cel), warna + (255,))
            t.alpha_composite(im, ((cel - im.width) // 2, (cel - im.height) // 2))
            lembar.paste(t.convert("RGB"), (x0 + j * cel, y0 + 24))
    PRATINJAU.mkdir(parents=True, exist_ok=True)
    keluar = PRATINJAU / "sprite_v2_a.png"
    lembar.save(keluar, optimize=True)
    print("wrote", keluar)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("gen")
    g.add_argument("nama", nargs="*")
    g.add_argument("--varian", type=int, default=3)
    g.add_argument("--jobs", type=int, default=6)
    l = sub.add_parser("lembar")
    l.add_argument("nama", nargs="+")
    r = sub.add_parser("rakit")
    r.add_argument("pilih", nargs="*")
    sub.add_parser("lembar_akhir")
    a = ap.parse_args()
    if a.cmd == "gen":
        cmd_gen(a.nama, a.varian, a.jobs)
    elif a.cmd == "lembar":
        cmd_lembar(a.nama)
    elif a.cmd == "rakit":
        cmd_rakit(a.pilih)
    elif a.cmd == "lembar_akhir":
        cmd_lembar_akhir()


if __name__ == "__main__":
    main()
