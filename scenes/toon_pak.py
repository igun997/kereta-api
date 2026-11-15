"""Pemotong dan penulis manifest Kelompok C (jalankan LOKAL dengan python3, bukan Blender).

  python3 scenes/toon_pak.py

Membaca out/<nama>.png + out/<nama>.json (hasil scenes/toon_game.py, rblender run --keep), lalu:
- potong ke bbox alfa + pivot + anchor, ditambah margin 4 px; pivot dan anchor dibuat relatif ke sprite;
- tulis assets/sprites/<nama>.png dan assets/sprites/manifest_c.json (hanya kelompok C);
- lembar kontak docs/pratinjau/toon_{samping,belakang,depan}.png;
- uji roda docs/pratinjau/uji_roda_v3.png (overlay roda di tuut_badan dan gerbong_merah_badan).
"""
import json
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "out")
ASET = os.path.join(ROOT, "assets", "sprites")
PRA = os.path.join(ROOT, "docs", "pratinjau")
MARGIN = 4
PPU = 160
BATAS_BYTE = 5 * 1024 * 1024
LATAR_BIRU = (207, 239, 255, 255)
WARNA = ["merah", "kuning", "biru", "hijau"]
HEWAN = ["ayam", "kucing", "bebek", "kelinci", "monyet", "kerbau"]

SAMPING = ["tuut_badan"] + [f"gerbong_{w}_badan" for w in WARNA] + [f"hewan_{h}" for h in HEWAN]
BELAKANG = ["tuut_belakang"] + [f"gerbong_{w}_belakang" for w in WARNA]
DEPAN = [f"hewan_{h}_depan" for h in HEWAN]
SEMUA = SAMPING + BELAKANG + DEPAN


def titik_anchor(anc):
    """Semua titik piksel dalam anchor (untuk bbox potong)."""
    pts = []
    for k, v in anc.items():
        if k == "isi":
            pts += [(v[0], v[2]), (v[1], v[2])]
        elif isinstance(v, (int, float)):
            continue
        elif v and isinstance(v[0], list):
            pts += [tuple(p) for p in v]
        else:
            pts.append(tuple(v))
    return pts


def geser_anchor(anc, x0, y0):
    hasil = {}
    for k, v in anc.items():
        if k == "isi":
            hasil[k] = [round(v[0] - x0, 2), round(v[1] - x0, 2), round(v[2] - y0, 2)]
        elif isinstance(v, (int, float)):
            hasil[k] = v
        elif v and isinstance(v[0], list):
            hasil[k] = [[round(p[0] - x0, 2), round(p[1] - y0, 2)] for p in v]
        else:
            hasil[k] = [round(v[0] - x0, 2), round(v[1] - y0, 2)]
    return hasil


def muat(nama):
    jalur_png = os.path.join(OUT, nama + ".png")
    jalur_json = os.path.join(OUT, nama + ".json")
    if not (os.path.exists(jalur_png) and os.path.exists(jalur_json)):
        raise SystemExit(f"{nama}: out/{nama}.png/json belum ada, jalankan toon_game.py dulu")
    with open(jalur_json) as fh:
        meta = json.load(fh)
    try:
        return Image.open(jalur_png).convert("RGBA"), meta
    except OSError:
        return None, meta


def potong(nama, img, meta):
    a = img.getchannel("A").getbbox()
    if a is None:
        raise SystemExit(f"{nama}: render kosong")
    pts = [tuple(meta["pivot"])] + titik_anchor(meta["anchors"])
    xs = [a[0], a[2]] + [p[0] for p in pts]
    ys = [a[1], a[3]] + [p[1] for p in pts]
    x0 = math.floor(min(xs)) - MARGIN
    y0 = math.floor(min(ys)) - MARGIN
    x1 = math.ceil(max(xs)) + MARGIN
    y1 = math.ceil(max(ys)) + MARGIN
    if x0 < 0 or y0 < 0 or x1 > img.width or y1 > img.height:
        raise SystemExit(f"{nama}: bbox keluar kanvas {img.width}px, perbesar KANVAS")
    crop = img.crop((x0, y0, x1, y1))
    entri = {
        "file": nama + ".png",
        "w": x1 - x0,
        "h": y1 - y0,
        "pivot": [round(meta["pivot"][0] - x0, 2), round(meta["pivot"][1] - y0, 2)],
        "anchors": geser_anchor(meta["anchors"], x0, y0),
    }
    return crop, entri


def tulis(semua):
    os.makedirs(ASET, exist_ok=True)
    manifest = {"ppu": PPU, "sprites": {}}
    lama_jalur = os.path.join(ASET, "manifest_c.json")
    lama = json.load(open(lama_jalur))["sprites"] if os.path.exists(lama_jalur) else {}
    gambar = {}
    for nama in SEMUA:
        img, meta = muat(nama)
        if img is None:
            print(f"peringatan: out/{nama}.png rusak (penarikan rblender); pakai assets/sprites/{nama}.png dan entri manifest sebelumnya")
            manifest["sprites"][nama] = lama[nama]
            gambar[nama] = Image.open(os.path.join(ASET, nama + ".png")).convert("RGBA")
            continue
        crop, entri = potong(nama, img, meta)
        gambar[nama] = crop
        manifest["sprites"][nama] = entri
    total = 0
    for nama, crop in gambar.items():
        jalur = os.path.join(ASET, nama + ".png")
        crop.save(jalur, optimize=True)
    total = sum(os.path.getsize(os.path.join(ASET, n + ".png")) for n in SEMUA)
    if total > BATAS_BYTE:
        for nama in SEMUA:
            jalur = os.path.join(ASET, nama + ".png")
            gambar[nama].quantize(colors=128, method=Image.Quantize.FASTOCTREE).save(jalur, optimize=True)
        total = sum(os.path.getsize(os.path.join(ASET, n + ".png")) for n in SEMUA)
    print(f"total PNG kelompok C: {total / 1024 / 1024:.2f} MB")
    manifest["sprites"] = dict(sorted(manifest["sprites"].items()))
    with open(os.path.join(ASET, "manifest_c.json"), "w") as fh:
        json.dump(manifest, fh, indent=1, ensure_ascii=False)
    return manifest, gambar


def _font():
    try:
        return ImageFont.truetype("DejaVuSans.ttf", 14)
    except OSError:
        return ImageFont.load_default()


def lembar(nama_berkas, daftar, manifest, lebar_maks=1500, skala=0.6):
    """Lembar kontak: sprite diletakkan berjajar di atas latar biru muda, pivot = titik merah."""
    font = _font()
    kotak_ = []
    for nama in daftar:
        img = Image.open(os.path.join(ASET, nama + ".png")).convert("RGBA")
        w, h = round(img.width * skala), round(img.height * skala)
        kotak_.append((nama, img.resize((w, h), Image.LANCZOS), manifest["sprites"][nama]["pivot"], skala))
    x = y = 10
    baris_h = 0
    posisi = []
    tf = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    lebar_sel = [max(img.width, int(tf.textlength(nama, font=font))) for nama, img, _, _ in kotak_]
    for sel in lebar_sel:
        if x + sel + 10 > lebar_maks:
            x = 10
            y += baris_h + 34
            baris_h = 0
        posisi.append((x, y))
        x += sel + 16
        baris_h = max(baris_h, kotak_[len(posisi) - 1][1].height)
    tinggi = y + baris_h + 40
    lebar = min(lebar_maks, max(px + sel for sel, (px, _) in zip(lebar_sel, posisi)) + 10)
    lembar_ = Image.new("RGBA", (lebar, tinggi), LATAR_BIRU)
    dr = ImageDraw.Draw(lembar_)
    for (nama, img, piv, sk), (px, py) in zip(kotak_, posisi):
        lembar_.alpha_composite(img, (px, py))
        cx, cy = px + piv[0] * sk, py + piv[1] * sk
        dr.line((cx - 5, cy, cx + 5, cy), fill=(255, 0, 0, 255), width=2)
        dr.line((cx, cy - 5, cx, cy + 5), fill=(255, 0, 0, 255), width=2)
        dr.text((px, py + img.height + 4), nama, fill=(20, 33, 61, 255), font=font)
    lembar_.convert("RGB").save(os.path.join(PRA, nama_berkas))
    print("lembar", nama_berkas, lembar_.size)


def uji_roda(manifest):
    """Overlay roda di anchor. Pakai tuut_roda.png/gerbong_roda.png (milik A) bila ada, jika tidak lingkaran biru."""
    font = _font()
    panel = []
    for nama, roda_nama in (("tuut_badan", "tuut_roda"), ("gerbong_merah_badan", "gerbong_roda")):
        img = Image.open(os.path.join(ASET, nama + ".png")).convert("RGBA")
        lapis = Image.new("RGBA", img.size, (0, 0, 0, 0))
        m = manifest["sprites"][nama]
        r = m["anchors"]["roda_radius"]
        jalur_roda = os.path.join(ASET, roda_nama + ".png")
        roda_img = Image.open(jalur_roda).convert("RGBA") if os.path.exists(jalur_roda) else None
        for px, py in m["anchors"]["roda"]:
            if roda_img is not None:
                d = round(2 * r)
                lapis.alpha_composite(roda_img.resize((d, d), Image.LANCZOS), (round(px - r), round(py - r)))
            else:
                dr = ImageDraw.Draw(lapis)
                dr.ellipse((px - r, py - r, px + r, py + r), outline=(30, 136, 255, 255), width=4)
        dr = ImageDraw.Draw(lapis)
        cx, cy = m["pivot"]
        dr.line((cx - 8, cy, cx + 8, cy), fill=(255, 0, 0, 255), width=3)
        dr.line((cx, cy - 8, cx, cy + 8), fill=(255, 0, 0, 255), width=3)
        for k, v in m["anchors"].items():
            if k in ("cerobong",):
                dr.ellipse((v[0] - 4, v[1] - 4, v[0] + 4, v[1] + 4), fill=(255, 0, 255, 255))
        gabung = Image.alpha_composite(img, lapis)
        panel.append((nama, gabung))
    lebar = sum(p.width for _, p in panel) + 30
    tinggi = max(p.height for _, p in panel) + 30
    kanvas = Image.new("RGBA", (lebar, tinggi), LATAR_BIRU)
    x = 10
    dr = ImageDraw.Draw(kanvas)
    for nama, p in panel:
        kanvas.alpha_composite(p, (x, 10))
        dr.text((x, tinggi - 18), nama, fill=(20, 33, 61, 255), font=font)
        x += p.width + 10
    kanvas.convert("RGB").save(os.path.join(PRA, "uji_roda_v3.png"))
    print("uji roda", kanvas.size)


def main():
    manifest, _ = tulis(SEMUA)
    lembar("toon_samping.png", SAMPING, manifest)
    lembar("toon_belakang.png", BELAKANG, manifest)
    lembar("toon_depan.png", DEPAN, manifest)
    uji_roda(manifest)
    print(f"{len(manifest['sprites'])} sprite kelompok C di manifest_c.json")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        raise SystemExit("pakai: python3 scenes/toon_pak.py (tanpa argumen)")
    os.makedirs(PRA, exist_ok=True)
    main()
