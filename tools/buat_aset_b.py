#!/usr/bin/env python3
"""Sprite kelompok B (dunia, stasiun, terowongan, jembatan, efek) sesuai ASET_KONTRAK_V2.

Pemakaian (dari root proyek):
  python3 tools/buat_aset_b.py gen [NAMA ...] [--varian 3] [--jobs 6]
      Membuat varian mentah ke /tmp/kereta_mentah_b/NAMA_vK.png (lewati yang sudah ada).
  python3 tools/buat_aset_b.py lembar [NAMA ...]
      Lembar kontak varian mentah -> /tmp/kereta_b_lembar_N.png (6 nama per lembar).
  python3 tools/buat_aset_b.py proses NAMA=VARIAN ...
      Proses varian terpilih ke assets/sprites/NAMA.png. VARIAN = angka (v1, v2, ...)
      atau 'kode' untuk sprite yang digambar dengan PIL (bintang_kecil).
  python3 tools/buat_aset_b.py manifest
      Tulis assets/sprites/manifest_b.json dari PNG kelompok B (gagal bila ada yang hilang).
  python3 tools/buat_aset_b.py cek
      Lembar kontak akhir -> docs/pratinjau/sprite_v2_b.png (navy dan kuning bergantian).
"""
import argparse
import concurrent.futures as cf
import json
import pathlib
import subprocess
import sys
import time

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from hapus_latar import hapus_latar  # noqa: E402

MENTAH = pathlib.Path("/tmp/kereta_mentah_b")
SPRITES = ROOT / "assets" / "sprites"
PRATINJAU = ROOT / "docs" / "pratinjau" / "sprite_v2_b.png"
MARGIN = 4  # piksel transparan di sekeliling objek

PREFIX = (
    "Children's game asset matching the reference logo style: flat vector cartoon, chunky rounded shapes, "
    "thick uniform dark navy (#14213D) outline, bright saturated colors (red #FF3B30, yellow #FFD60A, "
    "blue #1E88FF, green #34C759, orange #FF9500), one soft highlight, no gradients, no text, no shadow, "
    "plain pure white background, one single object centered with generous margin, full object visible, "
    "SIDE VIEW facing RIGHT. "
)

# (nama, mode ukuran, nilai px, pivot, subjek)
# mode ukuran: lebar | tinggi | diameter (sisi terpanjang). pivot: bawah (tengah-bawah) | pusat.
SPEK = [
    ("gunung_1", "lebar", 760, "bawah",
     "A single tall rounded cone-shaped green mountain with a simple white snow cap on its peak, "
     "flat green, no ground, no trees, no face"),
    ("gunung_2", "lebar", 800, "bawah",
     "A single wide green mountain with a broad rounded peak and a simple white snow cap, slightly "
     "lopsided shape, flat green, no ground, no trees, no face"),
    ("bukit_1", "lebar", 680, "bawah",
     "A single chubby rounded green hill with gentle sloping sides and two tiny round green bushes on top, "
     "flat green, no ground, no face"),
    ("bukit_2", "lebar", 720, "bawah",
     "A single long low rounded green hill with gently sloping sides and one small round tree on its right "
     "side, flat green, no ground, no face"),
    ("awan_1", "lebar", 260, "pusat",
     "A single fluffy white cloud with three round puffs, thick navy outline, one small soft highlight, no face"),
    ("awan_2", "lebar", 240, "pusat",
     "A single chubby white cloud with two round puffs and a flat bottom, thick navy outline, no face"),
    ("awan_3", "lebar", 280, "pusat",
     "A single small white cloud shaped like a wide bean with one big puff on top, thick navy outline, no face"),
    ("matahari", "diameter", 200, "pusat",
     "A single friendly smiling yellow sun with a round face: big round eyes with navy pupils, a huge smile, "
     "and a ring of chunky yellow rays around it, thick navy outline, no text"),
    ("pohon_kelapa", "tinggi", 300, "bawah",
     "A single chubby curved coconut palm tree, brown trunk with ring marks leaning slightly, big green leaves "
     "at the top, a few brown coconuts, no ground, no face"),
    ("pohon_bulat", "tinggi", 230, "bawah",
     "A single round-crown tree: brown trunk and a big round green leafy crown made of bumps, no ground, no face"),
    ("pohon_kota", "tinggi", 220, "bawah",
     "A single small round bright green tree with a short brown trunk, no ground, no face"),
    ("semak", "lebar", 110, "bawah",
     "A single round chubby green bush with a bumpy outline, no flowers, no ground, no face"),
    ("bunga_1", "tinggi", 70, "bawah",
     "A single cute red flower with five round petals, a yellow center and a short green stem with one leaf, "
     "no ground, no face"),
    ("bunga_2", "tinggi", 70, "bawah",
     "A single cute yellow flower with five round petals, an orange center and a short green stem with one leaf, "
     "no ground, no face"),
    ("padi_rumpun", "tinggi", 110, "bawah",
     "A single bundle of rice plants: several chubby green-yellow rice stalks with drooping golden grain heads, "
     "no ground, no face"),
    ("rumah_joglo", "lebar", 380, "bawah",
     "A single chubby Javanese joglo house with a tiered brown roof and a tall pointed top, brown wooden pillars, "
     "cream walls, a brown wooden door, front view, no ground, no people"),
    ("gubuk_sawah", "lebar", 220, "bawah",
     "A single small chubby rice-field hut with a golden thatched straw roof, wooden poles, open sides, "
     "front view, no ground, no people"),
    ("kincir_air", "tinggi", 220, "bawah",
     "A single chubby wooden water wheel with brown wooden paddles and spokes, a round central hub, "
     "on a small wooden stand, no ground, no face"),
    ("gedung_1", "tinggi", 340, "bawah",
     "A single chubby 3-storey town building with bright red walls, big round windows in two columns with light "
     "blue glass, a flat roof, front view, no ground, no people"),
    ("gedung_2", "tinggi", 340, "bawah",
     "A single chubby 4-storey building painted bright yellow, big square windows with light blue glass, "
     "a small flat roof, front view, no ground, no people"),
    ("gedung_3", "tinggi", 340, "bawah",
     "A single chubby 2-storey building painted bright blue, two large square windows and one round window, "
     "a red roof, front view, no ground, no people"),
    ("lampu_jalan", "tinggi", 220, "bawah",
     "A single chubby street lamp: a round lamp head on a thick grey-blue pole with a small base, "
     "no ground, no face"),
    ("peron_stasiun", "lebar", 800, "bawah",
     "A single side-view train station platform: a thick tan concrete platform floor along the bottom, a red roof "
     "canopy held by wooden poles, one wooden bench, and a round white sign with a red border on a pole, "
     "no train, no people"),
    ("palang_rel_tutup", "lebar", 160, "bawah",
     "A single railway crossing barrier gate: a tall pole on the left with a small base, and a long horizontal "
     "arm extending to the right with alternating thick red and white stripes, no people"),
    ("palang_rel_depan", "lebar", 420, "bawah",
     "A single railway crossing barrier gate seen from the front: two tall vertical poles standing side by side "
     "with small bases, and one long horizontal arm spanning between the two poles with alternating thick red and "
     "white stripes, no people, no ground"),
    ("terowongan_belakang", "lebar", 1100, "bawah",
     "A large chubby green hill, front view, with a dark arched tunnel mouth at its base, the tunnel opening "
     "solid dark navy, two small railway tracks entering the tunnel at the bottom, no people, no ground outside "
     "the hill"),
    ("jembatan_kayu", "lebar", 960, "bawah",
     "A wooden bridge, side view: a long flat horizontal wooden deck made of planks, a railing of wooden posts "
     "and rails on top, two chunky wooden support pillars underneath, no people, no water"),
    ("bintang_kecil", "diameter", 48, "pusat", "kode"),
]
SPEK_MAP = {s[0]: s for s in SPEK}
NAMA_AI = [s[0] for s in SPEK if s[4] != "kode"]


def prompt_untuk(nama):
    return PREFIX + SPEK_MAP[nama][4]


def gen_satu(nama, k, prompt, coba=3):
    keluar = MENTAH / f"{nama}_v{k}.png"
    if keluar.exists():
        return f"skip {keluar.name}"
    MENTAH.mkdir(parents=True, exist_ok=True)
    r = None
    for i in range(coba):
        r = subprocess.run(
            [sys.executable, str(ROOT / "tools" / "genimg.py"), str(keluar), prompt, "--size", "1024x1024"],
            capture_output=True, text=True, timeout=900,
        )
        if r.returncode == 0 and keluar.exists():
            return f"ok {keluar.name}"
        time.sleep(3 * (i + 1))
    return f"GAGAL {keluar.name}: {(r.stderr if r else '').strip()[-200:]}"


def cmd_gen(nama_list, varian, jobs):
    nama_list = nama_list or NAMA_AI
    tugas = [(n, k, prompt_untuk(n)) for n in nama_list for k in range(1, varian + 1)]
    with cf.ThreadPoolExecutor(max_workers=jobs) as ex:
        futs = [ex.submit(gen_satu, n, k, p) for n, k, p in tugas]
        for f in cf.as_completed(futs):
            print(f.result(), flush=True)


def potong_objek(rgba):
    a = rgba.getchannel("A").point(lambda v: 255 if v > 8 else 0)
    kotak = a.getbbox()
    return rgba.crop(kotak) if kotak else rgba


def skalakan(rgba, mode, nilai):
    """Ubah ukuran objek (LANCZOS, premultiplied agar tidak ada halo) lalu beri margin transparan."""
    w, h = rgba.size
    if mode == "lebar":
        s = nilai / w
    elif mode == "tinggi":
        s = nilai / h
    else:
        s = nilai / max(w, h)
    nw, nh = max(1, round(w * s)), max(1, round(h * s))
    obj = rgba.convert("RGBa").resize((nw, nh), Image.LANCZOS).convert("RGBA")
    kanvas = Image.new("RGBA", (nw + 2 * MARGIN, nh + 2 * MARGIN), (0, 0, 0, 0))
    kanvas.alpha_composite(obj, (MARGIN, MARGIN))
    return kanvas


# Kantong putih besar di dalam objek (celah pagar jembatan, bawah kanopi peron) adalah latar yang
# tidak terhubung ke tepi gambar. Nilai: (luas minimum piksel, batas kiri relatif yang dikecualikan).
# Peron: papan tanda putih di sisi kanan tetap dipertahankan.
KANTONG_PUTIH = {"jembatan_kayu": (1000, None), "peron_stasiun": (3000, 0.80)}


def hapus_kantong_putih(rgba, min_luas, kecualikan_x=None):
    a = np.asarray(rgba).copy()
    h, w = a.shape[:2]
    putih = (a[..., 0] > 235) & (a[..., 1] > 235) & (a[..., 2] > 235) & (a[..., 3] > 128)
    lab = np.zeros((h, w), bool)
    for y in range(h):
        for x in range(w):
            if not putih[y, x] or lab[y, x]:
                continue
            komp = [(y, x)]
            lab[y, x] = True
            i = 0
            while i < len(komp):
                cy, cx = komp[i]
                i += 1
                for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                    if 0 <= ny < h and 0 <= nx < w and putih[ny, nx] and not lab[ny, nx]:
                        lab[ny, nx] = True
                        komp.append((ny, nx))
            if len(komp) < min_luas:
                continue
            xs = [p[1] for p in komp]
            if kecualikan_x is not None and min(xs) >= kecualikan_x * w:
                continue
            for cy, cx in komp:
                a[cy, cx, 3] = 0
    return Image.fromarray(a, "RGBA")


def proses_objek(raw, nama, mode, nilai):
    kanvas_putih = Image.new("RGBA", Image.open(raw).size, (255, 255, 255, 255))
    kanvas_putih.alpha_composite(Image.open(raw).convert("RGBA"))
    img = kanvas_putih.convert("RGB")
    rgba = potong_objek(hapus_latar(img, bg=(255, 255, 255), tol=40))
    hasil = skalakan(rgba, mode, nilai)
    if nama in KANTONG_PUTIH:
        hasil = hapus_kantong_putih(hasil, *KANTONG_PUTIH[nama])
    return hasil


def bintang_kode(ukuran):
    """Bintang kuning gemuk bergaris navy, digambar dengan PIL (supersampling 4x)."""
    import math
    S = 4
    n = ukuran * S
    navy = (20, 33, 61, 255)
    kuning = (255, 214, 10, 255)
    garis = 10 * S // 4  # ketebalan garis navy di resolusi asli ~2.5 px
    cx = cy = n / 2
    r_luar = n / 2 - garis - 6 * S // 4

    def bintang(r_out, r_in=None):
        r_in = r_in or r_out * 0.56
        pts = []
        for i in range(10):
            r = r_out if i % 2 == 0 else r_in
            ang = -math.pi / 2 + i * math.pi / 5
            pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
        return pts

    kanvas = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(kanvas)
    tebal = (r_luar + garis) / r_luar
    d.polygon(bintang(r_luar * tebal, r_luar * tebal * 0.56), fill=navy)
    d.polygon(bintang(r_luar), fill=kuning)
    d.ellipse((cx - r_luar * 0.55, cy - r_luar * 0.42, cx - r_luar * 0.18, cy - r_luar * 0.1),
              fill=(255, 255, 255, 170))
    return kanvas.resize((ukuran, ukuran), Image.LANCZOS)


def cmd_proses(pasangan):
    SPRITES.mkdir(parents=True, exist_ok=True)
    for p in pasangan:
        nama, varian = p.split("=", 1)
        if nama not in SPEK_MAP:
            raise SystemExit(f"nama tidak dikenal: {nama}")
        _, mode, nilai, _, _ = SPEK_MAP[nama]
        if varian == "kode":
            hasil = bintang_kode(nilai)
        else:
            hasil = proses_objek(MENTAH / f"{nama}_v{int(varian)}.png", nama, mode, nilai)
        keluar = SPRITES / f"{nama}.png"
        hasil.save(keluar, optimize=True)
        print("wrote", keluar.relative_to(ROOT), hasil.size)


def dek_dari_alpha(alpha):
    """Permukaan dek: awal baris terpanjang dengan lebar opak >= 85% lebar maksimum."""
    a = np.asarray(alpha) > 128
    cov = a.sum(axis=1)
    cukup = cov >= 0.85 * cov.max()
    terbaik = (0, 0)
    mulai = None
    for y in range(len(cukup) + 1):
        on = y < len(cukup) and bool(cukup[y])
        if on and mulai is None:
            mulai = y
        elif not on and mulai is not None:
            if y - mulai > terbaik[1]:
                terbaik = (mulai, y - mulai)
            mulai = None
    return terbaik[0]


def cmd_manifest():
    sprites = {}
    hilang = []
    for nama, _, _, pivot, _ in SPEK:
        berkas = SPRITES / f"{nama}.png"
        if not berkas.exists():
            hilang.append(nama)
            continue
        im = Image.open(berkas)
        w, h = im.size
        if pivot == "pusat":
            p = [w // 2, h // 2]
        else:
            p = [w // 2, h - MARGIN]
        anchors = {}
        if nama == "jembatan_kayu":
            anchors["dek"] = [w // 2, dek_dari_alpha(im.getchannel("A"))]
        sprites[nama] = {"file": f"{nama}.png", "w": w, "h": h, "pivot": p, "anchors": anchors}
    if hilang:
        raise SystemExit(f"belum ada: {', '.join(hilang)}")
    keluar = SPRITES / "manifest_b.json"
    keluar.write_text(json.dumps({"ppu": 160, "sprites": sprites}, indent=1, ensure_ascii=False) + "\n")
    print("wrote", keluar.relative_to(ROOT), len(sprites), "sprite")


def cmd_lembar(nama_list):
    nama_list = nama_list or NAMA_AI
    sel = 256
    font = ImageFont.load_default()
    for no, awal in enumerate(range(0, len(nama_list), 6), start=1):
        bagian = nama_list[awal:awal + 6]
        lembar = Image.new("RGB", (sel * 3, (sel + 18) * len(bagian)), (200, 200, 200))
        d = ImageDraw.Draw(lembar)
        for i, nama in enumerate(bagian):
            for k in range(1, 4):
                f = MENTAH / f"{nama}_v{k}.png"
                y0 = i * (sel + 18)
                d.text(((k - 1) * sel + 4, y0 + 2), f"{nama} v{k}", fill=(0, 0, 0), font=font)
                if not f.exists():
                    continue
                im = Image.open(f).convert("RGB")
                im.thumbnail((sel, sel))
                lembar.paste(im, ((k - 1) * sel, y0 + 18))
        keluar = pathlib.Path(f"/tmp/kereta_b_lembar_{no}.png")
        lembar.save(keluar)
        print("wrote", keluar)


def cmd_cek():
    sel = 220
    kolom = 7
    nama_list = [s[0] for s in SPEK]
    baris = (len(nama_list) + kolom - 1) // kolom
    lembar = Image.new("RGB", (sel * kolom, sel * baris), (255, 255, 255))
    d = ImageDraw.Draw(lembar)
    font = ImageFont.load_default()
    for i, nama in enumerate(nama_list):
        x0, y0 = (i % kolom) * sel, (i // kolom) * sel
        warna = (20, 33, 61, 255) if (i // kolom + i % kolom) % 2 == 0 else (255, 214, 10, 255)
        tile = Image.new("RGBA", (sel, sel), warna)
        im = Image.open(SPRITES / f"{nama}.png").convert("RGBA")
        skala = min((sel - 40) / im.width, (sel - 40) / im.height, 2.0)
        im = im.resize((max(1, round(im.width * skala)), max(1, round(im.height * skala))), Image.LANCZOS)
        ox, oy = (sel - im.width) // 2, (sel - im.height) // 2 + 8
        tile.alpha_composite(im, (ox, oy))
        dt = ImageDraw.Draw(tile)
        pivot = None
        for nm, _, _, p, _ in SPEK:
            if nm == nama:
                pivot = p
        pw, ph = im.width, im.height
        px, py = ox + pw // 2, oy + ph - round(MARGIN * skala)
        if pivot == "pusat":
            py = oy + ph // 2
        dt.ellipse((px - 3, py - 3, px + 3, py + 3), fill=(255, 0, 0, 255))
        if nama == "jembatan_kayu":
            asli = Image.open(SPRITES / f"{nama}.png").getchannel("A")
            yd = dek_dari_alpha(asli)
            dx, dy = ox + im.width // 2, oy + round(yd * skala)
            dt.ellipse((dx - 3, dy - 3, dx + 3, dy + 3), fill=(0, 255, 255, 255))
        dt.text((4, 2), nama, fill=(20, 33, 61, 255) if warna[0] > 100 else (255, 255, 255, 255), font=font)
        lembar.paste(tile.convert("RGB"), (x0, y0))
    PRATINJAU.parent.mkdir(parents=True, exist_ok=True)
    lembar.save(PRATINJAU)
    print("wrote", PRATINJAU.relative_to(ROOT), lembar.size)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("gen")
    g.add_argument("nama", nargs="*")
    g.add_argument("--varian", type=int, default=3)
    g.add_argument("--jobs", type=int, default=6)
    l = sub.add_parser("lembar")
    l.add_argument("nama", nargs="*")
    p = sub.add_parser("proses")
    p.add_argument("pasangan", nargs="+")
    sub.add_parser("manifest")
    sub.add_parser("cek")
    a = ap.parse_args()
    if a.cmd == "gen":
        cmd_gen(a.nama, a.varian, a.jobs)
    elif a.cmd == "lembar":
        cmd_lembar(a.nama)
    elif a.cmd == "proses":
        cmd_proses(a.pasangan)
    elif a.cmd == "manifest":
        cmd_manifest()
    elif a.cmd == "cek":
        cmd_cek()


if __name__ == "__main__":
    main()
