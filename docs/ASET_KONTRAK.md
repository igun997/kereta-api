> **Usang untuk sprite.** Bagian 1 (render Blender 8°) digantikan oleh `ASET_KONTRAK_V2.md` dan `ASET_KONTRAK_V3.md` (gaya referensi logo, tiga sudut kamera). Bagian 2 (gambar UI, suara, musik) masih berlaku.

# Kontrak Aset — Kereta Api

Sumber kebenaran tunggal antara pembuat aset dan kode game (Flame 2D, sprite pra-render dari model 3D). Nama berkas memakai huruf kecil dan garis bawah, tanpa spasi. Semua teks/suara dalam **bahasa Indonesia**.

## 0. Aturan umum
- Gaya: mainan gemuk, bentuk membulat, tanpa bagian tipis, warna datar jenuh, **garis tepi biru malam `#14213D`** (lihat `docs/KONSEP_GAME.md` bagian 6 untuk palet). Hanya 5 warna dominan per objek.
- Objek harus terbaca jelas oleh anak 3 tahun: besar, sederhana, kontras tinggi.
- Satu sandbox instabox saja (4 vCPU / 8 GB). Pakai `rblender run ...` untuk Blender (jangan jalankan Blender di komputer lokal). Jangan jalankan dua pekerjaan Blender sekaligus.
- Rahasia di `.env` (`URL`, `KEY`) jangan dicetak atau disalin ke berkas lain. Gambar AI: `python3 tools/genimg.py OUT.png "prompt" --size 1024x1024` (model `cx/gpt-6.1-sol`).
- Jangan ubah berkas di luar folder milik masing-masing (lihat pembagian di bawah). Jangan jalankan `flutter`/`dart` lokal.

## 1. Sprite 3D pra-render (Blender) — milik agen "Blender"
Skrip di `scenes/` (boleh memakai ulang `scenes/kereta_lib.py` dan `scenes/aset_inti.py`), keluaran akhir ke `assets/sprites/` + `assets/sprites/manifest.json`.

**Kamera (SAMA untuk semua sprite):** ortografik, tampak **samping murni** (azimut 0, kamera di sisi -Y melihat ke +Y), elevasi **8°** dari horizontal, latar transparan (`film_transparent`), view transform `Standard`. **1 unit dunia = 160 piksel** (`ppu = 160`). Benda menghadap **kanan** (+X di layar). Render dipotong ke kotak pembatas alfa + margin 4 px. Setiap sprite dicatat di `manifest.json`:

```json
{ "ppu": 160,
  "sprites": { "tuut_badan": { "file": "tuut_badan.png", "w": 512, "h": 380, "pivot": [256, 372],
                                "anchors": { "roda": [[120, 330], [256, 330], [392, 330]], "cerobong": [330, 40] } } } }
```
`pivot` = piksel titik kontak tanah di tengah-bawah objek (proyeksi titik asal model (0,0,0) lewat kamera ke sprite yang sudah dipotong). `anchors` = titik penting dalam piksel sprite (hitung dari proyeksi kamera, bukan ditebak).

**Garis tepi:** aktifkan Freestyle (garis biru malam `#14213D`, tebal ~3 px, hanya kontur/crease) agar mirip ilustrasi logo. Jika hasilnya jelek, cukup bayangan lembut, tetapi warna tetap persis palet.

**Daftar sprite wajib** (semua menghadap kanan, kecuali dicatat):

| Kelompok | Nama berkas | Keterangan |
|---|---|---|
| Kereta | `tuut_badan` | Lokomotif merah TANPA roda dan batang penggerak. **Wajah ada di SISI ketel** (mata besar bulat putih + pupil menghadap kanan, pipi pink, senyum lebar) karena tampak samping. Cerobong kuning, atap kabin kuning, kubah hijau, penyapu rel kuning di depan, lampu depan. Panjang ~3,2 unit. Anchor `roda` = 3 titik pusat roda, `cerobong` = ujung atas cerobong (tempat asap), `klakson` = titik peluit. |
| | `tuut_badan_peluit` | Sama persis, tetapi mulut terbuka lebar "tuut!" dan mata menyipit senang. Ukuran dan pivot sama. |
| | `tuut_roda` | Satu roda biru dengan naf kuning dan **4 jari-jari kuning** (supaya putarannya terlihat), tampak samping murni, persegi, diameter 0,72 unit. Pivot = pusat roda. |
| Gerbong terbuka | `gerbong_merah_badan`, `gerbong_kuning_badan`, `gerbong_biru_badan`, `gerbong_hijau_badan` | Bak gerbong terbuka (dinding rendah ±0,55 unit, lantai, kopel di kedua ujung), tanpa roda. Panjang ~2,2 unit. **Lencana bentuk besar di sisi** (putih tebal, kontras): merah = lingkaran, kuning = bintang, biru = kotak, hijau = segitiga. Bagian atas bak terbuka tanpa isi (isi digambar kode). Anchor `roda` = 2 titik, `isi` = [kiri, kanan, y_lantai] area penumpang/buah. |
| | `gerbong_roda` | Roda gerbong: roda merah (naf kuning, 4 jari-jari putih), diameter 0,6 unit. |
| Hewan | `hewan_ayam`, `hewan_kucing`, `hewan_bebek`, `hewan_kerbau`, `hewan_kelinci`, `hewan_monyet` | Berdiri, menghadap kanan, mata besar, senyum. Tinggi ~0,9 unit (kerbau 1,4). Pivot di telapak kaki tengah. |
| Buah | `buah_apel` (merah), `buah_pisang` (kuning), `buah_jeruk` (oranye), `buah_blueberry` (biru; tumpukan 3 bulatan) | Tinggi ~0,45 unit. |
| Paket | `paket_merah`, `paket_kuning`, `paket_biru` | Kotak hadiah berpita, lencana bentuk sesuai warna (bulat/bintang/kotak). Lebar ~0,6 unit. |
| Rumah | `rumah_merah`, `rumah_kuning`, `rumah_biru` | Rumah mungil gemuk (atap lancip, jendela bulat) dengan **pintu besar berwarna** sesuai nama + lencana bentuk di atas pintu. Lebar ~2 unit. Anchor `pintu` = tengah pintu. |
| Desa | `rumah_joglo`, `pohon_kelapa`, `pohon_bulat`, `semak`, `bunga_1`, `bunga_2`, `padi_rumpun`, `gubuk_sawah`, `kincir_air` | Dekorasi Desa Sawah. `rumah_joglo` bergaya atap joglo gemuk. |
| Kota | `gedung_1`, `gedung_2`, `gedung_3`, `lampu_jalan`, `pohon_kota`, `bus_mungil` | Gedung 2–4 lantai gemuk berwarna cerah (bukan abu-abu), jendela bulat/kotak besar. Dekorasi Kota Kecil. |
| Latar | `gunung_1`, `gunung_2`, `bukit_1`, `bukit_2`, `awan_1`, `awan_2`, `awan_3`, `matahari` | Gunung kerucut hijau/biru lembut dengan puncak pucat, bukit membulat, awan putih gemuk, matahari kuning dengan wajah ramah. Ukuran besar (gunung ~8 unit lebar). |
| Stasiun | `peron_stasiun` | Peron panjang ~5 unit + atap merah + tiang kayu + bangku + rambu bulat. Pivot = tengah bawah lantai peron. Anchor `berhenti` = titik di mana lokomotif berhenti (pivot x). |
| | `palang_rel_tutup`, `palang_rel_buka` | Palang rel merah-putih (bergaris tebal). |
| Terowongan | `terowongan_belakang`, `terowongan_depan` | Bukit besar dengan lubang melengkung. `_belakang` = bagian dalam gelap + dinding belakang (digambar SEBELUM kereta), `_depan` = bukit depan dengan lubang transparan (digambar SESUDAH kereta sehingga kereta tampak masuk). Ukuran sama, pivot sama. Lebar ±5 unit, tinggi ±3,5. |
| Jembatan | `jembatan_kayu` | Jembatan kayu tampak samping, bentang ±6 unit, pagar kayu, tiang bawah. Tiga lubang bulat/kotak tidak perlu digambar (digambar kode). |
| Efek | `bintang_kecil` | Bintang kuning gemuk 0,3 unit untuk partikel. |

Penyelesaian: `manifest.json` memuat SEMUA sprite di atas. Skrip utama `scenes/sprite_game.py` dapat dijalankan ulang (`rblender run scenes/sprite_game.py [nama ...]`). Sprite tidak boleh melebihi 1024×1024 px (gunung/terowongan boleh 1400 px lebar). Total `assets/sprites` ≤ 12 MB (kuantisasi PNG dengan PIL bila perlu).

## 2. Gambar 2D, suara, musik — milik agen "Gambar & Suara"

### 2a. Gambar (AI via `tools/genimg.py`), keluaran transparan PNG kecuali dicatat
Latar putih/solid hasil AI harus dihapus menjadi transparan (alat bantu di `tools/`, mis. `tools/hapus_latar.py`, flood-fill dari tepi dengan toleransi; periksa tepi tidak berhalo).

| Folder | Berkas | Ukuran | Keterangan |
|---|---|---|---|
| `assets/ui/` | `tombol_gas`, `tombol_rem`, `tombol_peluit` | 512² | Sudah ada (latar putih). Buat versi transparan, nama sama. |
| | `tombol_mulai`, `tombol_stiker`, `tombol_pengaturan`, `tombol_beranda`, `tombol_ulang`, `tombol_lanjut`, `tombol_otomatis`, `tombol_suara_on`, `tombol_suara_off`, `ikon_gembok` | 512² | Tombol bulat besar tanpa teks, ikon sederhana (segitiga play, buku stiker, roda gigi, rumah, panah melingkar, panah kanan, tangan di setir/mode otomatis, speaker, speaker dicoret, gembok). Warna palet, garis tepi biru malam. |
| | `lampu_nyala`, `lampu_mati` | 512² | Saklar/lampu besar. |
| `assets/stickers/` | `stiker_01` … `stiker_12` | 512² | 12 stiker koleksi: 01 Tuut senang, 02 bintang emas, 03 medali, 04 pelangi, 05 balon, 06 mahkota, 07 ayam, 08 kucing, 09 bebek, 10 kerbau, 11 kelinci, 12 monyet. Gaya sticker: garis tepi putih tebal di luar garis biru malam. |
| `assets/brand/` | `logo.png` (ada, latar biru; buat `logo_transparan.png`), `app_icon.png` (ada, 1254²), `app_icon_1024.png`, `app_icon_foreground.png` (adaptive icon foreground, objek di 66% tengah, transparan), `feature_graphic.png` (1024×500, tanpa teks kecil), `splash_logo.png` | | Ikon aplikasi harus terbaca di 48 px: wajah Tuut besar. |
| `assets/backgrounds/` | `menu_latar.png` (1920×1080, langit, bukit, rel; **tanpa teks dan tanpa tokoh**), `dunia_desa.png`, `dunia_kota.png` (kartu pilih dunia 800×600 ilustrasi, tanpa teks) | | Opaque PNG. |

Semua gambar diperiksa dengan mata (lihat hasilnya) dan dikoreksi sampai bersih: tanpa teks acak, tanpa artefak, tanpa tepi putih.

### 2b. Suara (`assets/audio/`) — format **MP3** (iOS dan Android sama-sama bisa), mono, 44,1 kHz, `ffmpeg -c:a libmp3lame -q:a 4`
- **Suara pemandu (TTS)** `edge-tts` suara `id-ID-GadisNeural`, `--rate=-12%`, `--pitch=+4Hz`, di `assets/audio/suara/`. Normalisasi volume (`loudnorm` atau `volume`), potong hening di awal/akhir. Berkas dan teks:

| Berkas | Teks |
|---|---|
| `halo` | Halo! Ayo naik kereta bersama Tuut! |
| `ayo_jalan` | Ayo jalan! |
| `tekan_hijau` | Tekan tombol hijau, supaya kereta jalan! |
| `tekan_merah` | Tekan tombol merah, supaya kereta berhenti! |
| `tekan_kuning` | Tekan tombol kuning, untuk bunyikan peluit! |
| `hebat` / `pintar` / `bagus` / `yeay` | Hebat! / Pintar sekali! / Bagus! / Yeay! |
| `coba_lagi` | Coba lagi ya! |
| `satu` / `dua` / `tiga` | Satu / Dua / Tiga |
| `merah` / `kuning` / `biru` / `hijau` | Merah / Kuning / Biru / Hijau |
| `bulat` / `bintang` / `kotak` / `segitiga` | Bulat / Bintang / Kotak / Segitiga |
| `ayam` / `kucing` / `bebek` / `kerbau` / `kelinci` / `monyet` | Ayam / Kucing / Bebek / Kerbau / Kelinci / Monyet |
| `apel` / `pisang` / `jeruk` / `blueberry` | Apel / Pisang / Jeruk / Blueberry |
| `stasiun` | Stasiun! Tekan tombol merah ya! |
| `tuut_tuut` | Tuut tuut! |
| `misi1` | Ayo jemput teman-teman! |
| `misi2` | Masukkan buah ke gerbong yang warnanya sama! |
| `misi3` | Ada hewan di rel! Ayo bunyikan peluit! |
| `misi4` | Gelap sekali! Ayo nyalakan lampunya! |
| `misi5` | Cocokkan bentuknya ke lubang jembatan! |
| `misi6` | Antar paket ke rumah yang warnanya sama! |
| `misi_selesai` | Hebat! Misi selesai! Kamu dapat stiker! |
| `istirahat` | Yuk, istirahat dulu ya! Sampai jumpa! |
| `pilih_jalan` | Mau lewat jalan yang mana? |

- **Efek suara** (sintesis dengan numpy → wav → mp3, lembut, tidak keras, puncak ≤ -6 dBFS) di `assets/audio/sfx/`: `peluit` (peluit uap dua nada naik ±0,9 s), `rem` (desis lembut), `chug` (satu ketukan "cuk" pendek, dipicu berulang oleh kode sesuai kecepatan), `ding`, `pop`, `boing` (naik/hewan masuk), `bintang` (kilau naik), `tap` (klik lembut), `selesai` (fanfare riang 2 detik), `salah` (nada turun lembut, ramah), `lampu` (klik + dengung), `kunang` (nada tinggi lembut), `klak_wesel` (tok-tok kayu).
- **Musik** latar loop mulus (tanpa klik di sambungan) di `assets/audio/musik/`: `menu` (±40 s, riang pelan 100 bpm, pentatonik C mayor, marimba/xilofon sintetis + bass lembut) dan `main` (±50 s, 110 bpm, ritme kereta ringan). Volume rendah (-18 LUFS), tanpa suara tajam.
- Buat `assets/audio/daftar.md` berisi tabel berkas, durasi, dan teks. Verifikasi dengan `ffprobe` (durasi > 0, mp3 valid).

## 3. Milik saya (agen utama Flutter)
`lib/`, `test/`, `pubspec.yaml`, `android/`, `ios/`, `web/`, `docs/` (selain berkas ini), `rflutter.toml`. Agen aset jangan menyentuhnya.
