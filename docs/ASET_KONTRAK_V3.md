# Kontrak Aset V3 — 3D multi-sudut + kamera orang ketiga

Menambah/mengubah `ASET_KONTRAK_V2.md`. Game ini **3D**: ada kamera samping (misi stasiun) dan **kamera orang ketiga**, yaitu kamera di atas dan di belakang kereta, lurus menghadap rel (misi hewan di rel, terowongan, dan mode jalan-jalan). Karena itu tokoh dinamis (Tuut, gerbong, hewan) dibuat dari **model 3D yang sama** dan dirender dari tiga sudut agar konsisten. Dunia dan benda diam tetap gambar AI (cukup tampak depan).

## Pembagian
| Kelompok | Isi | Cara |
|---|---|---|
| **C (baru, Blender toon)** | `tuut_*`, `gerbong_*`, `hewan_*` (tiga sudut) | model 3D → render cel-shade lewat `rblender` |
| A (diperkecil) | `tuut_roda`, `gerbong_roda`, `buah_*`, `paket_*`, `rumah_*` | AI + PIL, sesuai V2 |
| B | dunia, peron, palang, terowongan, jembatan, bintang | AI, sesuai V2, **tambah** `palang_rel_depan` |

Semua menulis ke `assets/sprites/` dan manifest sendiri (`manifest_a.json`, `manifest_b.json`, `manifest_c.json`); `tools/gabung_manifest.py` (milik A) menggabung ketiganya menjadi `manifest.json` dan membuang PNG yatim. Tiga agen paralel: jangan menyentuh berkas milik kelompok lain.

## KELOMPOK C — kereta dan hewan 3D bergaya referensi

**Gaya (WAJIB mirip referensi, LIHAT dulu):** `assets/brand/logo.png`, `assets/brand/app_icon_1024.png`, `assets/backgrounds/dunia_kota.png` (ada lokomotif kecil di stasiun), `assets/stickers/stiker_*.png`. Ciri: bentuk gemuk membulat, **warna datar jenuh** tanpa kilap realistis, **garis tepi biru malam `#14213D` TEBAL dan rata**, kilau berupa satu bentuk lembut, mata besar bulat berkilau, senyum lebar. Hindari tampilan 3D plastik realistis, garis tipis, dan gradien halus.

**Teknik render (boleh disesuaikan agar hasil mirip referensi):** EEVEE dengan material "toon": Principled/Emission → Shader to RGB → Color Ramp 2 pita (terang dan sedikit lebih gelap), pencahayaan matahari tunggal. Freestyle untuk garis tepi `#14213D` tebal ±7 px pada 160 ppu (kontur + lipatan tajam + batas material). Jika EEVEE tidak berjalan di rblender, boleh pakai Cycles dengan material Emission datar + Freestyle + bayangan palsu seperlunya, selama hasil akhirnya serupa. Latar transparan, view transform Standard. Gunakan ulang `scenes/sprite_lib.py` dan modul bantu yang sudah ada bila berguna (kamera ortografik, proyeksi pivot/anchor), dan tulis skrip baru `scenes/toon_*.py` + `scenes/toon_game.py` (bisa `rblender run scenes/toon_game.py [grup]`). Pengemasan (crop + manifest) boleh lokal dengan PIL seperti `scenes/sprite_pak.py`.

**Model:** buat ulang agar sekeluarga dengan logo:
- **Tuut:** lokomotif uap merah gemuk, **cakram depan kuning besar berwajah** (mata putih besar berpupil, pipi merah muda, senyum), badan merah, kabin dengan atap kuning dan jendela biru bulat, cerobong kuning gemuk dengan topi lebar, kubah hijau, penyapu rel kuning, rangka biru, roda besar. Wajah juga dipasang **di sisi ketel** (bentuk mata+senyum kecil di kedua sisi depan ketel) supaya terbaca dari samping.
- **Gerbong:** gerbong datar terbuka gemuk (dek rendah dengan pagar sisi rendah), warna merah/kuning/biru/hijau, **lencana bentuk timbul** pada sisi dan belakang: merah=lingkaran, kuning=bintang, biru=kotak, hijau=segitiga (putih tebal, garis navy).
- **Hewan** gemuk lucu berkepala besar, kaki pendek tebal: ayam (kuning), kucing (oranye), bebek (kuning bersayap biru), kelinci (putih telinga panjang), monyet (cokelat), kerbau (abu kebiruan, tanduk melengkung). Wajah mata besar senyum.

**Sudut kamera dan keluaran** (ortografik, 160 px/unit, transparan, dipotong ke alfa + margin 4 px, pivot di titik kontak tanah tengah-bawah):
| Sudut | Kamera | Berkas |
|---|---|---|
| samping | menghadap objek dari sisi, elevasi 8°, benda menghadap kanan | `tuut_badan` (TANPA roda dan tanpa batang roda), `gerbong_{merah,kuning,biru,hijau}_badan` (tanpa roda), `hewan_{ayam,kucing,bebek,kelinci,monyet,kerbau}` |
| belakang | kamera di belakang benda dan lebih tinggi (elevasi 20°), melihat searah gerak | `tuut_belakang` (roda ikut tergambar), `gerbong_{warna}_belakang` ×4 (roda ikut; lencana terlihat di dinding belakang) |
| depan | kamera di depan benda, elevasi 8°, benda menghadap kamera | `hewan_{nama}_depan` ×6 |

Ukuran: Tuut samping lebar ±512 px, gerbong samping ±352 px, hewan samping tinggi ±150 px (kerbau ±190). Sudut belakang/depan memakai skala 3D yang SAMA (benda yang sama harus sama ukuran relatifnya antar sudut: lebar belakang Tuut ≈ lebar sisinya dalam unit dunia, dst).

**Anchors (manifest_c.json):**
- `tuut_badan`: `roda` = 3 pusat roda `[[x,y],…]` dalam piksel sprite (proyeksi kamera, jarak merata di rangka), `roda_radius` px (±0,17 × tinggi badan), `cerobong` `[x,y]` ujung atas cerobong. `pivot` = proyeksi titik kontak tanah (boleh di bawah gambar karena roda terpisah).
- `gerbong_*_badan`: `roda` (2 titik), `roda_radius`, `isi` = `[kiri, kanan, y_permukaan_atas]` (area penaruhan benda di atas dek, dalam piksel sprite), pivot sama.
- Sudut belakang/depan: tanpa anchors khusus selain `pivot`.

**Uji kamera:** lembar kontak per sudut `docs/pratinjau/toon_{samping,belakang,depan}.png` dan gambar overlay roda pada `tuut_badan`/gerbong menggunakan `tuut_roda.png`/`gerbong_roda.png` (milik A; jika belum ada, gambar lingkaran biru 96 px di anchor) di `docs/pratinjau/uji_roda_v3.png`. LIHAT semuanya; bandingkan langsung dengan `logo.png`; ulangi sampai kemiripan gaya bagus.

## Perubahan untuk A dan B
- A: **hapus** dari tugasnya `tuut_badan`, `gerbong_*_badan`, `hewan_*` (diambil C). Tetap: `tuut_roda`, `gerbong_roda`, `buah_*`, `paket_*`, `rumah_*`. `gabung_manifest.py` harus menggabung `manifest_a.json`, `manifest_b.json`, `manifest_c.json` (yang ada), menghapus PNG yatim hanya saat ketiganya ada atau lewat bendera `--paksa`.
- B: tambah `palang_rel_depan` (lebar 420 px): palang rel TAMPAK DEPAN, lengan belang merah-putih melintang horizontal di antara dua tiang, kaki tiang di bawah; pivot tengah-bawah.
