# Kereta Api

Game anak (3 tahun ke atas) berbahasa Indonesia: jalankan kereta **Tuut**, bunyikan peluit, selesaikan 6 misi di 2 dunia. Flutter + Flame, berjalan di HP dan tablet (landscape). Tanpa iklan, tanpa internet, tanpa izin.

- Konsep, prinsip desain untuk balita, palet: [`docs/KONSEP_GAME.md`](docs/KONSEP_GAME.md)
- Kontrak aset: sprite [`V3`](docs/ASET_KONTRAK_V3.md) (tokoh 3D tiga sudut) dan [`V2`](docs/ASET_KONTRAK_V2.md) (dunia, rumah, buah), UI/suara/musik di [`ASET_KONTRAK.md`](docs/ASET_KONTRAK.md) bagian 2
- Materi Google Play: [`docs/PLAY_STORE.md`](docs/PLAY_STORE.md) · Kebijakan privasi: [`docs/PRIVASI.md`](docs/PRIVASI.md)

## Satu sandbox untuk semuanya
Semua build, tes, dan render berjalan di **satu** kotak instabox (paket Anda mengizinkan satu mesin). Flutter lewat `rflutter` (instance `main`), Blender lewat `rblender` (instance `default`); keduanya menunjuk kotak `rcargo` yang sama. Jangan jalankan build Flutter/Blender di komputer ini.

```
rflutter test                          # tes
rflutter analyze
rflutter build apk --debug             # build uji
rflutter --install build apk --release # build rilis + pasang ke HP yang terhubung (adb)
rflutter build appbundle --release     # .aab untuk Play Console
rflutter run                           # hot reload di HP (jalankan sendiri di terminal)
rblender run scenes/toon_game.py       # render ulang Tuut, gerbong, hewan (3D toon, 3 sudut)
rflutter remote down                   # jeda sandbox (hemat biaya; bangun sendiri saat dipakai)
```
Hanya satu pekerjaan berat (Gradle atau Blender) pada satu waktu: RAM sandbox 8 GB.

## Struktur
```
lib/core      konstanta, palet, penyimpanan (stiker, pengaturan), audio
lib/game      KeretaGame (Flame), fisika kereta (murni, teruji), dunia, kereta, komponen
lib/game/misi 6 misi + kelas dasar
lib/ui        splash, beranda, pilih dunia/misi, buku stiker, pengaturan orang tua
assets/       sprites (render Blender), ui, stickers, brand, backgrounds, textures, audio
scenes/       skrip Blender (rb) untuk semua sprite 3D
tools/        genimg.py (gambar AI), hapus_latar.py, aset_gambar.py, buat_audio.py, buat_ikon.py
test/         tes fisika, perspektif, penyimpanan, gerbang orang tua, pengaturan (lokalisasi), kontrak manifest dan audio, e2e game
```

## Alur aset
- **Tokoh 3D → sprite (Blender):** `scenes/toon_game.py` merender Tuut, gerbong, dan hewan dari satu model per tokoh, dari tiga sudut (samping, belakang, depan) dengan material toon dan garis tepi navy. `scenes/toon_pak.py` memotong dan menulis `manifest_c.json`.
- **Dunia, rumah, buah:** gambar AI bergaya logo (`tools/buat_aset_b.py`, `tools/aset_kelompok_a.py`); `python3 tools/gabung_manifest.py` menggabung `manifest_a/b/c.json` menjadi `assets/sprites/manifest.json` (pivot dan anchor dalam piksel). Kode game membaca manifest, bukan angka ajaib.
- **Kamera:** tampak samping (stasiun) dan orang ketiga (perspektif sungguhan, `lib/game/perspektif.dart`) untuk misi hewan di rel, terowongan, dan jalan-jalan bebas.
- **Tangkap bingkai untuk ditinjau:** buat `test/foto_aktif.txt` lalu `rflutter test test/foto_test.dart`; PNG ada di `build/foto/` di sandbox. Hapus berkas penanda setelahnya.
- **Gambar 2D:** `tools/genimg.py` memakai endpoint kompatibel OpenAI dari `.env` (`URL`, `KEY`; jangan di-commit).
- **Ikon:** `python3 tools/buat_ikon.py` menghasilkan ikon Android/iOS/web dari `assets/brand/`.
- **Suara:** `tools/buat_audio.py` (TTS id-ID-GadisNeural + sintesis efek dan musik). Daftar: `assets/audio/daftar.md`.

## Rilis Android
Kunci unggah ada di `android/app/upload-keystore.jks` dan `android/key.properties` (diabaikan git; ikut disinkronkan ke sandbox lewat `rflutter.toml`). **Cadangkan keduanya di tempat aman.** Versi: `pubspec.yaml` (`version: 1.0.0+1`; naikkan angka setelah `+` untuk tiap unggahan).

Flutter dikunci ke 3.50.0 (`rflutter.toml`) agar build bisa direproduksi.
