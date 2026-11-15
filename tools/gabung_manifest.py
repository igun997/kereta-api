#!/usr/bin/env python3
"""Gabung assets/sprites/manifest_{a,b,c}.json menjadi manifest.json (format V2/V3).

- Manifest yang belum ada dilewati; tidak gagal bila salah satu belum ada.
- PNG yatim (ada di assets/sprites tetapi tak ada di manifest mana pun) dihapus hanya bila
  ketiga manifest sudah ada, atau bila memakai --paksa. Ini mencegah sprite kelompok yang
  belum selesai ikut terhapus.

Pemakaian (dari root proyek):
  python3 tools/gabung_manifest.py [--paksa]
"""
import argparse
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SPRITES = ROOT / "assets" / "sprites"
KELOMPOK = ("a", "b", "c")


def baca(path):
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else None


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--paksa", action="store_true", help="hapus PNG yatim walau manifest belum lengkap")
    a = ap.parse_args()

    ada = []
    for k in KELOMPOK:
        m = baca(SPRITES / f"manifest_{k}.json")
        if m is None:
            print(f"manifest_{k}.json belum ada: dilewati")
        else:
            ada.append((k, m))
    if not ada:
        print("tidak ada manifest_a/b/c.json; tidak ada yang digabung")
        return 0

    ppu = {m.get("ppu", 160) for _, m in ada}
    if len(ppu) != 1:
        print(f"ppu tidak sama antar manifest: {sorted(ppu)}", file=sys.stderr)
        return 1

    sprites = {}
    for k, m in ada:
        for nama, entri in m.get("sprites", {}).items():
            if nama in sprites:
                print(f"nama ganda di dua manifest: {nama}", file=sys.stderr)
                return 1
            sprites[nama] = entri

    for nama, entri in sprites.items():
        if not (SPRITES / entri["file"]).exists():
            print(f"peringatan: berkas belum ada untuk {nama}: {entri['file']}")

    gabungan = {"ppu": ada[0][1].get("ppu", 160), "sprites": dict(sorted(sprites.items()))}
    (SPRITES / "manifest.json").write_text(
        json.dumps(gabungan, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"wrote manifest.json: {len(sprites)} sprite dari manifest {[k for k, _ in ada]}")

    lengkap = len(ada) == len(KELOMPOK)
    if not lengkap and not a.paksa:
        print("manifest belum lengkap: penghapusan sprite yatim dilewati (pakai --paksa untuk memaksa)")
        return 0

    yatim = sorted(p for p in SPRITES.glob("*.png") if p.stem not in sprites)
    for p in yatim:
        p.unlink()
        print("hapus yatim:", p.name)
    print(f"sprite yatim dihapus: {len(yatim)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
