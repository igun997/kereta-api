"""Model 3D Kelompok C (satu model per tokoh, dirender dari beberapa sudut). Satuan: 1 unit = 160 px.

Konvensi: depan benda di +X (menghadap kanan pada sudut samping), sisi kamera samping di -Y,
titik kontak tanah di (0, 0, 0). Roda dan batang roda dikembalikan sebagai grup `roda`: disembunyikan
pada sudut samping (kontrak), tampil pada sudut belakang.
Dipanggil oleh scenes/toon_game.py.
"""
import math

import bpy
from mathutils import Vector

from toon_lib import PPU, elips, kerucut, kotak, prisma, silinder, skala_akar

MERAH = "#FC1422"
KUNING = "#FEDE0A"
BIRU = "#058AFD"
HIJAU = "#4ADE13"
ORANYE = "#FF9500"
PINK = "#FF7AA8"
COKLAT = "#A9713F"
TAN = "#D9A066"
BAJA = "#8A98A8"
PUTIH = "#FFFFFF"
NAVY = "#14213D"
MERAH_TUA = "#9E0F18"
WARNA_GERBONG = {"merah": MERAH, "kuning": KUNING, "biru": BIRU, "hijau": HIJAU}


# ---------- Tuut (lokomotif) ----------

RW = 0.42                            # jari-jari roda Tuut
RODA_X = (-0.85, 0.0, 0.85)

# bagian wajah dan penyapu depan: disembunyikan dari sudut belakang
MUKA = ("cakram", "mata_", "pupil", "kilau", "alis", "pipi", "mulut", "lidah", "penyapu")


def tuut():
    roda = []
    # rangka dan kabin
    kotak("rangka", (2.9, 0.8, 0.5), (0.05, 0.0, 0.72), BIRU, bevel=0.16)
    kotak("kabin", (1.0, 1.24, 1.1), (-1.05, 0.0, 1.45), MERAH, bevel=0.14)
    silinder("atap", 0.5, 0.98, (-1.05, 0.0, 1.86), KUNING, sumbu="X", bevel=0.04)
    kotak("jendela_samping", (0.56, 0.12, 0.56), (-1.1, -0.66, 1.5), BIRU, bevel=0.12)
    elips("jendela_belakang", (-1.58, 0.0, 1.5), (0.1, 0.32, 0.32), BIRU)
    # ketel, garis kuning, kubah
    silinder("ketel", 0.55, 1.6, (0.2, 0.0, 1.5), MERAH, sumbu="X", bevel=0.03)
    silinder("garis_1", 0.58, 0.12, (-0.42, 0.0, 1.5), KUNING, sumbu="X", bevel=0.02)
    silinder("garis_2", 0.58, 0.12, (-0.2, 0.0, 1.5), KUNING, sumbu="X", bevel=0.02)
    elips("kubah", (-0.1, 0.0, 2.08), (0.26, 0.26, 0.26), HIJAU)
    # cerobong dengan topi lebar
    silinder("cerobong", 0.17, 0.5, (0.55, 0.0, 2.2), MERAH, bevel=0.02)
    silinder("topi_cerobong", 0.36, 0.22, (0.55, 0.0, 2.46), KUNING, bevel=0.06)
    # cakram depan berwajah: merah di luar, kuning di depan
    silinder("cakram_merah", 0.74, 0.5, (0.85, -0.7, 1.5), MERAH, sumbu="Y", bevel=0.05)
    silinder("cakram_kuning", 0.56, 0.14, (0.85, -1.03, 1.5), KUNING, sumbu="Y", bevel=0.04)
    for s in (-1, 1):
        ex = 0.85 + s * 0.22
        ez = 1.66
        elips("mata_putih", (ex, -1.1, ez), (0.23, 0.16, 0.23), PUTIH)
        elips("pupil", (ex + 0.06, -1.24, ez - 0.01), (0.1, 0.08, 0.1), NAVY)
        elips("kilau", (ex + 0.1, -1.31, ez + 0.05), (0.035, 0.03, 0.035), PUTIH)
        elips("alis", (ex, -1.1, 2.02), (0.2, 0.05, 0.05), NAVY)
        elips("pipi", (0.85 + s * 0.4, -1.04, 1.4), (0.09, 0.03, 0.06), PINK)
    elips("mulut", (0.85, -1.08, 1.3), (0.2, 0.1, 0.12), MERAH_TUA)
    elips("lidah", (0.85, -1.14, 1.2), (0.11, 0.05, 0.05), PINK)
    # penyapu rel (cowcatcher) merah dengan garis kuning, di bawah cakram
    prisma("penyapu", [(0.3, 0.42), (1.7, 0.42), (1.5, 0.9), (0.45, 0.9)],
           tebal=1.0, sumbu="Y", offset=0.0, hexs=MERAH, bevel=0.04)
    for x0 in (0.6, 0.95, 1.3):
        prisma("penyapu_garis", [(x0, 0.45), (x0 + 0.12, 0.45), (x0 + 0.22, 0.88), (x0 + 0.1, 0.88)],
               tebal=0.08, sumbu="Y", offset=-0.54, hexs=KUNING, bevel=0.02)
    # roda dan batang roda (hanya sudut belakang)
    for x in RODA_X:
        for y in (-0.5, 0.5):
            roda.append(kotak("roda", (0.5, 0.44, 0.6), (x, y, 0.3), BIRU, bevel=0.08))
            roda.append(kotak("naf", (0.04, 0.22, 0.22), (x - 0.27, y, 0.3), KUNING, bevel=0.02))
    for y in (-0.6, 0.6):
        roda.append(kotak("batang", (1.7, 0.1, 0.1), (0.0, y, RW), HIJAU, bevel=0.03))
    muka = [o for o in bpy.data.objects if o.name.startswith(MUKA)]
    return {"roda": roda, "muka": muka, "anchor": _anchor_tuut}


def _anchor_tuut(proj, sudut):
    if sudut != "samping":
        return {}
    r_px = proj((RODA_X[0] + RW, 0.0, RW))[0] - proj((RODA_X[0], 0.0, RW))[0]
    return {
        "roda": [proj((x, 0.0, RW)) for x in RODA_X],
        "roda_radius": round(r_px, 2),
        "cerobong": proj((0.55, 0.0, 2.57)),
    }


# ---------- gerbong (datar terbuka, pagar rendah, lencana timbul) ----------

RG = 0.25
RODA_G_X = (-0.7, 0.7)


def _bintang(cu, cv, r_luar, r_dalam, n=5):
    pts = []
    for i in range(2 * n):
        r = r_luar if i % 2 == 0 else r_dalam
        a = math.pi / 2 + i * math.pi / n
        pts.append((cu + r * math.cos(a), cv + r * math.sin(a)))
    return pts


def _lencana(sisi, offset, cu, cv, bentuk):
    """Lencana timbul putih satu bentuk: lingkaran, bintang, kotak, atau segitiga.
    sisi 'Y' (u=X, v=Z) di sisi samping; 'X' (u=Y, v=Z) di belakang."""
    if sisi == "Y":
        pos = lambda a, b: (a, offset, b)
    else:
        pos = lambda a, b: (offset, a, b)
    if bentuk == "lingkaran":
        silinder("lencana", 0.27, 0.12, pos(cu, cv), PUTIH, sumbu=sisi, bevel=0.05)
    elif bentuk == "bintang":
        prisma("lencana", _bintang(cu, cv, 0.32, 0.14), 0.12, sisi, offset, PUTIH, bevel=0.03)
    elif bentuk == "kotak":
        ukuran = (0.46, 0.12, 0.46) if sisi == "Y" else (0.12, 0.46, 0.46)
        kotak("lencana", ukuran, pos(cu, cv), PUTIH, bevel=0.07)
    else:
        prisma("lencana", [(cu, cv + 0.34), (cu - 0.3, cv - 0.2), (cu + 0.3, cv - 0.2)],
               0.12, sisi, offset, PUTIH, bevel=0.03)


BENTUK_LENCANA = {"merah": "lingkaran", "kuning": "bintang", "biru": "kotak", "hijau": "segitiga"}

def gerbong(warna):
    hexs = WARNA_GERBONG[warna]
    roda = []
    kotak("alas", (2.2, 0.9, 0.12), (0.0, 0.0, 0.55), BAJA, bevel=0.05)
    kotak("badan", (2.2, 1.04, 0.4), (0.0, 0.0, 0.75), hexs, bevel=0.14)
    kotak("lantai", (1.96, 0.84, 0.1), (0.0, 0.0, 0.96), TAN, bevel=0.02)
    for s in (-0.52, 0.52):
        kotak("pagar_sisi", (2.2, 0.12, 0.3), (0.0, s, 1.15), hexs, bevel=0.05)
    for s in (-1.04, 1.04):
        kotak("pagar_ujung", (0.12, 0.92, 0.3), (s, 0.0, 1.15), hexs, bevel=0.05)
    bentuk = BENTUK_LENCANA[warna]
    for s in (-1, 1):
        _lencana("Y", s * 0.56, 0.0, 0.78, bentuk)
    _lencana("X", -1.16, 0.0, 0.78, bentuk)
    for x in RODA_G_X:
        for y in (-0.42, 0.42):
            roda.append(kotak("roda", (0.4, 0.44, 0.5), (x, y, 0.25), MERAH, bevel=0.08))
            roda.append(kotak("naf", (0.04, 0.2, 0.2), (x - 0.22, y, 0.25), KUNING, bevel=0.02))
    return {"roda": roda, "anchor": _anchor_gerbong}


def _anchor_gerbong(proj, sudut):
    if sudut != "samping":
        return {}
    r_px = proj((RODA_G_X[0] + RG, 0.0, RG))[0] - proj((RODA_G_X[0], 0.0, RG))[0]
    kiri = proj((-0.98, 0.0, 1.01))[0]
    kanan = proj((0.98, 0.0, 1.01))[0]
    atas = proj((0.0, 0.0, 1.01))[1]
    return {
        "roda": [proj((x, 0.0, RG)) for x in RODA_G_X],
        "roda_radius": round(r_px, 2),
        "isi": [round(kiri, 2), round(kanan, 2), round(atas, 2)],
    }


# ---------- hewan (gemuk, kepala besar, mata besar, senyum) ----------

HEWAN = {
    "ayam": dict(badan=KUNING, kepala=KUNING, kaki=ORANYE, tinggi=150),
    "kucing": dict(badan=ORANYE, kepala=ORANYE, kaki=ORANYE, tinggi=150),
    "bebek": dict(badan=KUNING, kepala=KUNING, kaki=ORANYE, tinggi=150),
    "kelinci": dict(badan=PUTIH, kepala=PUTIH, kaki=PUTIH, tinggi=150),
    "monyet": dict(badan=COKLAT, kepala=COKLAT, kaki=COKLAT, tinggi=150),
    "kerbau": dict(badan=BAJA, kepala=BAJA, kaki=BAJA, tinggi=190),
}


def _wajah(hx, hz, rh):
    """Mata besar di sisi depan kepala (terbaca dari samping dan dari depan), pipi, dan senyum."""
    for s in (-1, 1):
        d = Vector((0.56, s * 0.82, 0.12)).normalized()
        c = Vector((hx, 0.0, hz)) + d * rh * 0.95
        elips("mata_putih", c, (0.13, 0.13, 0.13), PUTIH, gelap=0.85)
        elips("pupil", c + d * 0.085, (0.075, 0.075, 0.075), NAVY)
        elips("kilau", c + d * 0.11 + Vector((0.02, 0.0, 0.035)), (0.03, 0.03, 0.03), PUTIH)
        pc = Vector((hx, s * 0.25, hz - 0.1))
        elips("pipi", pc + Vector((0.12, 0.0, 0.0)), (0.06, 0.04, 0.04), PINK)
    elips("mulut", (hx + 0.22, 0.0, hz - 0.14), (0.07, 0.13, 0.06), NAVY)
    elips("lidah", (hx + 0.24, 0.0, hz - 0.19), (0.05, 0.08, 0.035), PINK)


def hewan(nama):
    p = HEWAN[nama]
    hx, hz, rh = 0.2, 0.85, 0.28
    for x in (-0.16, 0.14):
        for y in (-0.12, 0.12):
            silinder("kaki", 0.07, 0.3, (x, y, 0.15), p["kaki"], bevel=0.02)
            elips("telapak", (x + 0.04, y, 0.03), (0.1, 0.085, 0.045), p["kaki"])
    elips("badan", (-0.04, 0.0, 0.42), (0.3, 0.26, 0.27), p["badan"])
    elips("kepala", (hx, 0.0, hz), (rh, rh, rh), p["kepala"])
    _wajah(hx, hz, rh)

    if nama == "ayam":
        for dx, dz in ((-0.02, 0.27), (0.07, 0.22), (-0.1, 0.2)):
            elips("jengger", (hx + dx, 0.0, hz + dz), (0.07, 0.07, 0.07), MERAH)
        kerucut("paruh", 0.09, 0.16, (hx + 0.3, 0.0, hz - 0.05), ORANYE, rot=(0.0, math.pi / 2, 0.0))
        elips("sayap", (-0.02, -0.22, 0.45), (0.18, 0.06, 0.14), "#FFC300")
        elips("ekor", (-0.36, 0.0, 0.55), (0.12, 0.08, 0.14), KUNING)
    elif nama == "kucing":
        for s in (-1, 1):
            kerucut("telinga", 0.11, 0.2, (hx - 0.05, s * 0.17, hz + 0.25), ORANYE)
            kerucut("telinga_dalam", 0.06, 0.12, (hx - 0.05, s * 0.17, hz + 0.23), PINK)
        elips("moncong", (hx + 0.2, 0.0, hz - 0.08), (0.15, 0.17, 0.12), PUTIH)
        elips("hidung", (hx + 0.33, 0.0, hz - 0.02), (0.04, 0.05, 0.035), PINK)
        for c in ((-0.36, 0.0, 0.42), (-0.48, 0.0, 0.56), (-0.44, 0.0, 0.72), (-0.3, 0.0, 0.76)):
            elips("ekor", c, (0.06, 0.06, 0.06), ORANYE)
    elif nama == "bebek":
        elips("paruh", (hx + 0.3, 0.0, hz - 0.07), (0.14, 0.08, 0.05), ORANYE)
        for s in (-1, 1):
            elips("sayap", (-0.02, s * 0.27, 0.42), (0.2, 0.05, 0.14), BIRU)
            elips("kaki_pipih", (0.08, s * 0.12, 0.02), (0.1, 0.05, 0.03), ORANYE)
        elips("ekor", (-0.34, 0.0, 0.5), (0.1, 0.1, 0.1), KUNING)
    elif nama == "kelinci":
        for s in (-1, 1):
            elips("telinga", (hx - 0.05, s * 0.12, hz + 0.42), (0.07, 0.05, 0.26), PUTIH)
            elips("telinga_dalam", (hx - 0.03, s * 0.14, hz + 0.4), (0.035, 0.03, 0.2), PINK)
        elips("ekor", (-0.34, 0.0, 0.42), (0.11, 0.11, 0.11), PUTIH)
        elips("hidung", (hx + 0.27, 0.0, hz - 0.06), (0.04, 0.04, 0.04), PINK)
    elif nama == "monyet":
        elips("muka", (hx + 0.16, 0.0, hz - 0.03), (0.14, 0.22, 0.2), TAN)
        for s in (-1, 1):
            silinder("telinga", 0.12, 0.06, (hx - 0.04, s * 0.27, hz + 0.04), COKLAT, sumbu="Y", bevel=0.02)
            silinder("telinga_dalam", 0.07, 0.07, (hx - 0.04, s * 0.28, hz + 0.04), TAN, sumbu="Y", bevel=0.02)
        for c in ((-0.33, 0.0, 0.42), (-0.46, 0.0, 0.55), (-0.44, 0.0, 0.7), (-0.3, 0.0, 0.72)):
            elips("ekor", c, (0.05, 0.05, 0.05), COKLAT)
    elif nama == "kerbau":
        elips("badan_besar", (-0.02, 0.0, 0.5), (0.36, 0.3, 0.3), p["badan"])
        elips("moncong", (hx + 0.2, 0.0, hz - 0.12), (0.12, 0.15, 0.11), "#6B7A8C")
        for s in (-1, 1):
            kerucut("tanduk", 0.07, 0.22, (hx - 0.02, s * 0.2, hz + 0.22), "#F5EBD0",
                    rot=(-s * math.radians(30), 0.0, 0.0))
            elips("telinga", (hx - 0.08, s * 0.22, hz + 0.1), (0.08, 0.04, 0.07), "#6B7A8C")
        silinder("ekor", 0.03, 0.4, (-0.38, 0.0, 0.35), BAJA, bevel=0.01)
        elips("ekor_ujung", (-0.4, 0.0, 0.12), (0.07, 0.07, 0.07), "#6B7A8C")
    skala_akar(p["tinggi"] / PPU)
    return {"roda": [], "anchor": lambda proj, sudut: {}}
