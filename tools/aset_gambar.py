#!/usr/bin/env python3
"""Pipeline aset gambar 2D Kereta Api: generate varian AI, pilih, hapus latar, potong, susun.

Pemakaian (dari root proyek):
  python3 tools/aset_gambar.py gen [NAMA ...] [--varian 3] [--jobs 6]
      Membuat varian mentah ke /tmp/kereta_mentah/NAMA_vK.png (lewati yang sudah ada).
  python3 tools/aset_gambar.py lembar NAMA ...
      Lembar kontak semua varian mentah NAMA -> /tmp/kereta_lembar_NAMA.png
  python3 tools/aset_gambar.py proses NAMA=VARIAN ...
      Proses varian terpilih ke assets/<folder>/NAMA.png. VARIAN = angka (v1, v2, ...)
      atau 'asli' untuk tombol lama (latar putih) yang diproses ulang.
  python3 tools/aset_gambar.py cek NAMA ...
      Tempel hasil di latar biru malam dan kuning -> /tmp/kereta_cek.png (periksa halo).
"""
import argparse
import concurrent.futures as cf
import pathlib
import subprocess
import sys
import time

from PIL import Image, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from hapus_latar import hapus_latar  # noqa: E402

MENTAH = pathlib.Path("/tmp/kereta_mentah")

GAYA_IKON = (
    "Flat vector children's toy illustration, chunky rounded shapes, very thick dark navy (#14213D) "
    "outline around the whole subject, flat saturated colors only (red #FF3B30, yellow #FFD60A, "
    "blue #1E88FF, green #34C759, orange #FF9500, white), no gradients, no shading, no drop shadow, "
    "no text, no letters, no numbers, no tiny details, subject centered and large, "
    "plain solid pure white background filling the whole image, no border around the subject"
)
GAYA_LATAR = (
    "Flat vector illustration, soft pastel colors, clean simple shapes, no outlines, "
    "no text, no letters, no numbers, no people, no characters, no animals"
)
GAYA = {"putih": GAYA_IKON, "latar": GAYA_LATAR}

# (nama, folder, jenis, gaya, subjek, ukuran)
# jenis: ikon (512 persegi, transparan) | stiker (512, garis putih) | figur (1024, aman adaptif)
#        latar (sampul ke ukuran, opaque) | ulang (tombol lama, latar putih -> transparan)
SPEK = [
    ("tombol_gas", "ui", "ulang", None, None, 512),
    ("tombol_rem", "ui", "ulang", None, None, 512),
    ("tombol_peluit", "ui", "ulang", None, None, 512),
    ("tombol_mulai", "ui", "ikon", "putih",
     "One big round button filled with green #34C759, thick navy outline ring, "
     "a big simple white right-pointing triangle (play symbol) in the middle", 512),
    ("tombol_stiker", "ui", "ikon", "putih",
     "One big round button filled with blue #1E88FF, thick navy outline ring, "
     "a simple white sticker-album book icon with a yellow star on its cover in the middle", 512),
    ("tombol_pengaturan", "ui", "ikon", "putih",
     "One big round button filled with orange #FF9500, thick navy outline ring, "
     "a big simple white gear (cog wheel) icon in the middle", 512),
    ("tombol_beranda", "ui", "ikon", "putih",
     "One big round button filled with blue #1E88FF, thick navy outline ring, "
     "a big simple white house icon with a red door in the middle", 512),
    ("tombol_ulang", "ui", "ikon", "putih",
     "One big round button filled with yellow #FFD60A, thick navy outline ring, "
     "a big simple navy circular arrow (restart symbol) in the middle", 512),
    ("tombol_lanjut", "ui", "ikon", "putih",
     "One big round button filled with sky blue #6FD3FF, thick navy outline ring, "
     "a big simple navy right arrow in the middle", 512),
    ("tombol_otomatis", "ui", "ikon", "putih",
     "One big round button filled with orange #FF9500, thick navy outline ring, "
     "a big simple white steering wheel in the middle", 512),
    ("tombol_suara_on", "ui", "ikon", "putih",
     "One big round button filled with blue #1E88FF, thick navy outline ring, "
     "a big simple white speaker icon with two sound-wave arcs in the middle", 512),
    ("tombol_suara_off", "ui", "ikon", "putih",
     "One big round button filled with blue #1E88FF, thick navy outline ring, "
     "a big simple white speaker icon with a big red X mark (crossed out) in the middle", 512),
    ("ikon_gembok", "ui", "ikon", "putih",
     "One big simple golden-yellow padlock icon with a thick navy outline, "
     "no circle, no background shape", 512),
    ("lampu_nyala", "ui", "ikon", "putih",
     "One big round glowing light bulb, bright yellow #FFD60A fill, thick navy outline, "
     "a few simple white shine lines around it, no circle, no background shape", 512),
    ("lampu_mati", "ui", "ikon", "putih",
     "One big round light bulb switched off, grey-blue #8FA3BF fill, thick navy outline, "
     "no shine lines, no circle, no background shape", 512),
    ("stiker_01", "stickers", "stiker", "putih",
     "A cute happy red steam locomotive engine head, big round white eyes with navy pupils, "
     "huge smile, yellow chimney on top, yellow roof", 512),
    ("stiker_02", "stickers", "stiker", "putih",
     "One chubby yellow star with a cute smiling face, orange inner shade", 512),
    ("stiker_03", "stickers", "stiker", "putih",
     "A round yellow medal with a big star in the middle, hanging from a red and blue ribbon", 512),
    ("stiker_04", "stickers", "stiker", "putih",
     "A chubby rainbow arc with red, orange, yellow, green and blue bands, "
     "white fluffy clouds at both ends", 512),
    ("stiker_05", "stickers", "stiker", "putih",
     "One big round red balloon with a small white shine, thick navy string", 512),
    ("stiker_06", "stickers", "stiker", "putih",
     "A chubby yellow king's crown with three round gems: red, blue and green", 512),
    ("stiker_07", "stickers", "stiker", "putih",
     "A cute chubby cartoon chicken with yellow body, orange beak, red comb, big round eyes, happy", 512),
    ("stiker_08", "stickers", "stiker", "putih",
     "A cute chubby orange cat face with big round eyes, smiling", 512),
    ("stiker_09", "stickers", "stiker", "putih",
     "A cute chubby yellow duck with orange beak, big round eyes, happy", 512),
    ("stiker_10", "stickers", "stiker", "putih",
     "A cute chubby brown water buffalo with small horns, big round eyes, smiling", 512),
    ("stiker_11", "stickers", "stiker", "putih",
     "A cute chubby white bunny rabbit with long ears, big round eyes, smiling", 512),
    ("stiker_12", "stickers", "stiker", "putih",
     "A cute chubby brown monkey face with big round ears, smiling", 512),
    ("app_icon_foreground", "brand", "figur", "putih",
     "A friendly red cartoon steam locomotive face: round red engine head, big round white eyes "
     "with navy pupils, huge smile, yellow chimney on top", 1024),
    ("app_icon_1024", "brand", "latar", "biru",
     "App icon artwork: a big friendly red cartoon steam locomotive face (round red engine head, "
     "big round white eyes with navy pupils, huge smile, yellow chimney on top) filling most of a "
     "square, thick navy outline, flat colors, on a solid sky blue #6FD3FF background, no text",
     (1024, 1024)),
    ("feature_graphic", "brand", "latar", "biru",
     "Wide panoramic banner illustration, centered composition: a complete cheerful red cartoon steam "
     "locomotive with a yellow chimney, pulling three colorful open wagons (yellow, blue, green), the whole "
     "train fully visible inside the frame with empty sky margin on both left and right, brown railway track, "
     "green hills, yellow sun and white clouds, sky blue background, flat vector, thick navy outlines, "
     "no text, no letters", (1024, 500)),
    ("menu_latar", "backgrounds", "latar", "latar",
     "Wide landscape background: pale sky blue with fluffy white clouds, rolling soft green hills, "
     "a brown wooden railway track curving across the bottom, calm and cheerful", (1920, 1080)),
    ("dunia_desa", "backgrounds", "latar", "latar",
     "Flat vector card illustration of an Indonesian village in rice fields: bright green rice paddies, "
     "a traditional joglo house with a big roof, a coconut palm tree, a cone-shaped green mountain "
     "behind, blue sky", (800, 600)),
    ("dunia_kota", "backgrounds", "latar", "latar",
     "Flat vector card illustration of a small colorful town: bright red, yellow and blue cartoon "
     "buildings with big round windows, round trees, a small train station, blue sky", (800, 600)),
    ("logo_transparan", "brand", "logo", None, None, None),
    ("splash_logo", "brand", "logo_splash", None, None, 1024),
]
SPEK_MAP = {s[0]: s for s in SPEK}
# Jenis yang tidak dibuat AI (diproses dari berkas yang sudah ada).
JENIS_KHUSUS = ("ulang", "logo", "logo_splash")
# Ukuran tepi: transparan tanpa margin tambahan (ikon), margin untuk stiker dan figur.
MARGIN = {"ikon": 24, "stiker": 14, "figur": 174, "logo": 60}
LEBAR_STIKER = 18  # tebal garis putih stiker pada ukuran 512


def prompt_untuk(spek):
    _, _, jenis, gaya, subjek, _ = spek
    g = GAYA[gaya] if gaya in GAYA else ""
    if gaya == "biru":
        g = GAYA_IKON.replace("plain solid pure white background filling the whole image", "")
    return f"{subjek}. {g}".strip()


def gen_satu(nama, k, prompt, coba=3):
    keluar = MENTAH / f"{nama}_v{k}.png"
    if keluar.exists():
        return f"skip {keluar.name}"
    MENTAH.mkdir(parents=True, exist_ok=True)
    for i in range(coba):
        r = subprocess.run(
            [sys.executable, str(ROOT / "tools" / "genimg.py"), str(keluar), prompt, "--size", "1024x1024"],
            capture_output=True, text=True, timeout=600,
        )
        if r.returncode == 0 and keluar.exists():
            return f"ok {keluar.name}"
        time.sleep(3 * (i + 1))
    return f"GAGAL {keluar.name}: {r.stderr.strip()[-200:]}"


def cmd_gen(nama_list, varian, jobs):
    pilih = [SPEK_MAP[n] for n in nama_list] if nama_list else [s for s in SPEK if s[2] not in JENIS_KHUSUS]
    tugas = [(s[0], k, prompt_untuk(s)) for s in pilih if s[2] not in JENIS_KHUSUS for k in range(1, varian + 1)]
    with cf.ThreadPoolExecutor(max_workers=jobs) as ex:
        futs = {ex.submit(gen_satu, n, k, p): (n, k) for n, k, p in tugas}
        for f in cf.as_completed(futs):
            print(f.result(), flush=True)


def sampul(img, W, H):
    """Potong tengah (cover) ke W x H tanpa distorsi, lalu ubah ukuran."""
    iw, ih = img.size
    skala = max(W / iw, H / ih)
    nw, nh = max(W, round(iw * skala)), max(H, round(ih * skala))
    img = img.convert("RGB").resize((nw, nh), Image.LANCZOS)
    x, y = (nw - W) // 2, (nh - H) // 2
    return img.crop((x, y, x + W, y + H))


def potong_isi(rgba):
    a = rgba.getchannel("A").point(lambda v: 255 if v > 8 else 0)
    kotak = a.getbbox()
    return rgba.crop(kotak) if kotak else rgba


def tempatkan(rgba, W, H, margin):
    """Perkecil/besarkan objek agar muat di tengah kanvas W x H transparan dengan margin."""
    w, h = rgba.size
    skala = min((W - 2 * margin) / w, (H - 2 * margin) / h)
    nw, nh = max(1, round(w * skala)), max(1, round(h * skala))
    obj = rgba.resize((nw, nh), Image.LANCZOS)
    kanvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    kanvas.alpha_composite(obj, ((W - nw) // 2, (H - nh) // 2))
    return kanvas


def tambah_garis_putih(rgba, lebar):
    """Garis putih tebal di luar objek (gaya stiker), dibentuk dari alpha yang dikembangkan."""
    alpha = rgba.getchannel("A")
    kabur = alpha.filter(ImageFilter.GaussianBlur(lebar / 2.4))
    luar = kabur.point(lambda v: min(255, max(0, (v - 6) * 40)))
    kanvas = Image.new("RGBA", rgba.size, (255, 255, 255, 0))
    kanvas.putalpha(luar)
    kanvas.alpha_composite(rgba)
    return kanvas


def sumber_untuk(nama, varian):
    if varian == "asli":
        return MENTAH / f"{nama}_asli.png"
    return MENTAH / f"{nama}_v{varian}.png"


def proses_satu(nama, varian):
    _, folder, jenis, gaya, _, ukuran = SPEK_MAP[nama]
    src = sumber_untuk(nama, varian)
    img = Image.open(src)
    keluar = ROOT / "assets" / folder / f"{nama}.png"
    keluar.parent.mkdir(parents=True, exist_ok=True)

    if jenis in ("ikon", "ulang"):
        rgba = hapus_latar(img, bg=(255, 255, 255), tol=200 if jenis == "ulang" else 40)
        rgba = potong_isi(rgba)
        hasil = tempatkan(rgba, ukuran, ukuran, MARGIN["ikon"])
    elif jenis == "stiker":
        rgba = hapus_latar(img, bg=(255, 255, 255), tol=40)
        rgba = potong_isi(rgba)
        inti = tempatkan(rgba, ukuran, ukuran, MARGIN["stiker"] + LEBAR_STIKER)
        hasil = tambah_garis_putih(inti, LEBAR_STIKER)
    elif jenis == "figur":
        rgba = hapus_latar(img, bg=(255, 255, 255), tol=40)
        rgba = potong_isi(rgba)
        hasil = tempatkan(rgba, ukuran, ukuran, MARGIN["figur"])
    elif jenis == "logo":
        hasil = hapus_latar(img, bg=None, tol=60)
    elif jenis == "logo_splash":
        rgba = potong_isi(Image.open(ROOT / "assets" / "brand" / "logo_transparan.png").convert("RGBA"))
        hasil = tempatkan(rgba, ukuran, ukuran, MARGIN["logo"])
    elif jenis == "latar":
        W, H = ukuran
        hasil = sampul(img, W, H).convert("RGBA")
    else:
        raise SystemExit(f"jenis tidak dikenal: {jenis}")

    if jenis == "latar":
        hasil.convert("RGB").save(keluar, optimize=True)
    else:
        hasil.save(keluar, optimize=True)
    return keluar, hasil.size


def cmd_proses(pasangan):
    for p in pasangan:
        nama, varian = p.split("=", 1)
        if nama not in SPEK_MAP:
            raise SystemExit(f"nama tidak dikenal: {nama}")
        keluar, ukuran = proses_satu(nama, varian if varian == "asli" else int(varian))
        print("wrote", keluar.relative_to(ROOT), ukuran)


def cmd_lembar(nama_list):
    for nama in nama_list:
        berkas = sorted(MENTAH.glob(f"{nama}_v*.png"))
        if not berkas:
            print("tidak ada varian:", nama)
            continue
        sel = 256
        kol = min(3, len(berkas))
        baris = (len(berkas) + kol - 1) // kol
        lembar = Image.new("RGB", (sel * kol, sel * baris), (200, 200, 200))
        for i, f in enumerate(berkas):
            im = Image.open(f).convert("RGB")
            im.thumbnail((sel, sel))
            lembar.paste(im, ((i % kol) * sel, (i // kol) * sel))
        keluar = pathlib.Path(f"/tmp/kereta_lembar_{nama}.png")
        lembar.save(keluar)
        print("wrote", keluar)


def cmd_cek(nama_list):
    sel = 256
    baris = []
    for nama in nama_list:
        _, folder, _, _, _, _ = SPEK_MAP[nama]
        im = Image.open(ROOT / "assets" / folder / f"{nama}.png").convert("RGBA")
        im.thumbnail((sel, sel))
        tiles = []
        for warna in ((20, 33, 61, 255), (255, 214, 10, 255)):
            t = Image.new("RGBA", (sel, sel), warna)
            t.alpha_composite(im, ((sel - im.width) // 2, (sel - im.height) // 2))
            tiles.append(t.convert("RGB"))
        baris.append(tiles)
    lembar = Image.new("RGB", (sel * 2, sel * len(baris)), (255, 255, 255))
    for i, tiles in enumerate(baris):
        for j, t in enumerate(tiles):
            lembar.paste(t, (j * sel, i * sel))
    keluar = pathlib.Path("/tmp/kereta_cek.png")
    lembar.save(keluar)
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
    p = sub.add_parser("proses")
    p.add_argument("pasangan", nargs="+")
    c = sub.add_parser("cek")
    c.add_argument("nama", nargs="+")
    a = ap.parse_args()
    if a.cmd == "gen":
        cmd_gen(a.nama, a.varian, a.jobs)
    elif a.cmd == "lembar":
        cmd_lembar(a.nama)
    elif a.cmd == "proses":
        cmd_proses(a.pasangan)
    elif a.cmd == "cek":
        cmd_cek(a.nama)


if __name__ == "__main__":
    main()
