"""Render Kelompok C Kontrak V3: Tuut, gerbong, dan hewan dari model 3D yang sama (rblender).

Jalankan dari root proyek (hasil ke out/, pakai --keep):
  rblender run --keep scenes/toon_game.py                 (semua)
  rblender run --keep scenes/toon_game.py tuut            (grup: tuut | gerbong | hewan)
  rblender run --keep scenes/toon_game.py tuut_badan      (nama sprite tunggal)
Hasil mentah: out/<nama>.png + out/<nama>.json (pivot dan anchor dalam piksel kanvas).
Lalu (lokal, bukan Blender): python3 scenes/toon_pak.py
"""
import os
import sys

sys.path.insert(0, os.path.join(os.getcwd(), "scenes"))

import rb  # noqa: E402
import toon_lib as T  # noqa: E402
import toon_model as M  # noqa: E402

WARNA = ["merah", "kuning", "biru", "hijau"]
HEWAN = list(M.HEWAN)

# (nama model, pembangun, [(nama sprite, sudut)])
JOB = [("tuut", M.tuut, [("tuut_badan", "samping"), ("tuut_belakang", "belakang")])]
for w in WARNA:
    JOB.append((f"gerbong_{w}", lambda w=w: M.gerbong(w),
                [(f"gerbong_{w}_badan", "samping"), (f"gerbong_{w}_belakang", "belakang")]))
for h in HEWAN:
    JOB.append((f"hewan_{h}", lambda h=h: M.hewan(h),
                [(f"hewan_{h}", "samping"), (f"hewan_{h}_depan", "depan")]))


def _cocok(pilih, model, sprite):
    if not pilih:
        return True
    return any(a == sprite or a == model or (a in ("tuut", "gerbong", "hewan") and model.startswith(a))
               for a in pilih)


pilih = rb.args()
hasil = []
for model, bangun, daftar in JOB:
    terpilih = [(n, s) for n, s in daftar if _cocok(pilih, model, n)]
    if not terpilih:
        continue
    T.mulai()
    info = bangun()
    target = T.pusat()
    for nama, sudut in terpilih:
        for ob in info["roda"]:
            ob.hide_render = sudut != "belakang"       # samping: tanpa roda; belakang: roda ikut
        for ob in info.get("muka", []):
            ob.hide_render = sudut == "belakang"       # wajah dan penyapu tidak tampak dari belakang
        T.render(nama, sudut, target, lambda proj, s=sudut: info["anchor"](proj, s))
        hasil.append(nama)

rb.report(sprite=hasil)
