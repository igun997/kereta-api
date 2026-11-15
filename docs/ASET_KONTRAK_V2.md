# Kontrak Aset V2 — sprite bergaya referensi logo

Menggantikan BAGIAN 1 di `ASET_KONTRAK.md`. Sprite hasil render Blender dibuang karena gayanya jauh dari referensi. **Referensi gaya** (LIHAT DULU dengan mata): `assets/brand/logo.png`, `assets/brand/app_icon_1024.png`, `assets/stickers/stiker_*.png`, `assets/ui/tombol_*.png`, `assets/backgrounds/dunia_desa.png`, `dunia_kota.png`. Cirinya: kartun vektor datar, bentuk gemuk membulat, **garis tepi biru malam `#14213D` tebal dan rata**, warna jenuh cerah, satu kilau lembut, mata bulat besar dan senyum pada tokoh, tanpa teks.

## Prinsip
- Semua sprite dibuat dengan endpoint gambar (`tools/genimg.py`, model `cx/gpt-6.1-sol`) memakai alat yang sudah ada: `tools/aset_gambar.py` (gen, proses), `tools/hapus_latar.py`. Boleh menambah alat baru di `tools/` atau memodifikasi alat sendiri. Buat 3 varian tiap sprite, **lihat semuanya dengan mata**, pilih yang paling mirip referensi, ulangi bila belum cocok.
- Awalan prompt gaya (pakai di setiap prompt, lalu tambah objeknya): `Children's game asset matching the reference logo style: flat vector cartoon, chunky rounded shapes, thick uniform dark navy (#14213D) outline, bright saturated colors (red #FF3B30, yellow #FFD60A, blue #1E88FF, green #34C759, orange #FF9500), one soft highlight, no gradients, no text, no shadow, plain pure white background, one single object centered with generous margin, full object visible, SIDE VIEW facing RIGHT`. Untuk latar/dekorasi: tanpa tokoh/mata.
- Latar putih dihapus jadi transparan (flood-fill dari tepi, tanpa halo putih; periksa di latar navy dan kuning). Potong ke kotak pembatas alfa + margin 4 px.
- Skala: **1 unit dunia = 160 px**. Ubah ukuran tiap sprite ke ukuran "tinggi/lebar target" di tabel (LANCZOS), dengan syarat tidak melebihi 1024 px (gunung/terowongan boleh 1400 px lebar). Total `assets/sprites` ≤ 8 MB (kuantisasi PNG bila perlu).
- Tulis `assets/sprites/manifest.json` (format sama dengan yang lama: `{"ppu":160,"sprites":{nama:{file,w,h,pivot:[x,y],anchors:{...}}}}`). Hapus semua sprite lama yang tidak ada di tabel baru. Gabungkan manifest kedua agen dengan alat bersama `tools/gabung_manifest.py` (dibuat agen kelompok A; kelompok B menulis `assets/sprites/manifest_b.json` dan alat itu menggabungkannya, urutan kerja ditentukan di bawah).
- `pivot` = titik kontak tanah di tengah-bawah benda (untuk benda berdiri: tengah-bawah kotak pembatas). Untuk awan/matahari/bintang: pusat gambar.
- Semua benda menghadap **kanan**.
- Dilarang menyentuh `lib/`, `test/`, `pubspec.yaml`, `android/`, `ios/`, `web/`, `assets/ui|stickers|brand|backgrounds|audio|textures`.

## KELOMPOK A (kereta, hewan, buah, paket, rumah, roda)
| Nama | Target | Keterangan |
|---|---|---|
| `tuut_badan` | lebar 512 px | Lokomotif uap merah gemuk **tanpa roda** (rangka/chassis bawah rata dan tebal; badan seolah melayang), tampak samping menghadap kanan. Wajah ramah di **depan ketel** terlihat 3/4 (mata besar, senyum), cerobong kuning, atap kabin kuning, jendela biru, kubah hijau, penyapu rel kuning, lampu depan. Warna dan wajah harus sekeluarga dengan `logo.png` (merah, kuning, biru, hijau). Anchors: `roda` = 3 pusat roda `[[x,y],…]` (di tepi bawah rangka, jarak merata), `roda_radius` = jari-jari roda (px, ±0,17 × tinggi badan), `cerobong` = `[x,y]` ujung atas cerobong. Pivot: `x` tengah, `y` = y roda + roda_radius (titik kontak rel, boleh di bawah gambar). |
| `tuut_roda` | diameter 96 px | **Digambar dengan kode (PIL, supersampling 4×)** bukan AI: cakram biru `#1E88FF`, garis tepi navy tebal, naf kuning besar, 4 jari-jari kuning tebal (bentuk gemuk agar putaran terlihat). Pivot = pusat. |
| `gerbong_merah_badan`, `gerbong_kuning_badan`, `gerbong_biru_badan`, `gerbong_hijau_badan` | lebar 352 px | Gerbong **datar terbuka** (platform rendah gemuk dengan dinding samping rendah, **bagian atas datar agar benda bisa ditaruh di atasnya**), tanpa roda, warna sesuai nama. Buat SATU dasar dengan AI (merah), lalu turunkan keempat warna dengan pergeseran hue pada piksel jenuh (garis navy tetap) agar bentuknya identik. **Lencana bentuk dengan kode (PIL)** di sisi: merah=lingkaran, kuning=bintang, biru=kotak, hijau=segitiga; putih tebal + garis navy, besar (±40% tinggi badan). Anchors: `roda` = 2 pusat roda, `roda_radius`, `isi` = `[kiri, kanan, y_permukaan_atas]` (area untuk menaruh benda; x kiri/kanan di dalam badan, y permukaan atas). Pivot seperti Tuut. |
| `gerbong_roda` | diameter 80 px | Seperti `tuut_roda` tetapi merah `#FF3B30`, naf kuning, jari-jari putih. Kode (PIL). Pivot = pusat. |
| `hewan_ayam`, `hewan_kucing`, `hewan_bebek`, `hewan_kelinci`, `hewan_monyet` | tinggi 150 px | Berdiri menghadap kanan, mata besar, senyum, kaki jelas menapak bawah. Pivot = telapak kaki tengah. |
| `hewan_kerbau` | tinggi 190 px | Kerbau gemuk lucu abu kebiruan, tanduk melengkung, berdiri menghadap kanan. |
| `buah_apel` (merah), `buah_pisang` (kuning), `buah_jeruk` (oranye), `buah_blueberry` (tumpukan 3 bulatan biru) | tinggi 72 px | Satu buah, mata kecil lucu boleh. Pivot tengah-bawah. |
| `paket_merah`, `paket_kuning`, `paket_biru` | lebar 100 px | Kotak hadiah berpita. Buat SATU dengan AI lalu turunkan tiga warna (hue-shift jenuh) + lencana bentuk dengan kode (bulat/bintang/kotak). Pivot tengah-bawah. |
| `rumah_merah`, `rumah_kuning`, `rumah_biru` | lebar 320 px | Rumah mungil gemuk tampak depan-datar (bukan sisi), atap lancip oranye, dua jendela bulat, **pintu besar berwarna** sesuai nama + lencana bentuk di atas pintu (kode PIL: bulat/bintang/kotak). Satu dasar AI, tiga pintu diwarnai oleh kode atau tiga generasi bila lebih mudah. Anchor `pintu` = `[x,y]` tengah pintu. Pivot tengah-bawah. |

Urutan kerja A: buat semua; jalankan `tools/gabung_manifest.py` yang membaca `assets/sprites/manifest_a.json` dan `manifest_b.json` (jika ada) menjadi `manifest.json`. Tulis hasil A ke `manifest_a.json`.

## KELOMPOK B (dunia, stasiun, terowongan, jembatan, efek)
| Nama | Target | Keterangan |
|---|---|---|
| `gunung_1`, `gunung_2` | lebar 720–800 px | Gunung kerucut hijau dengan puncak salju putih sederhana, garis navy; berbeda bentuk. Pivot tengah-bawah. |
| `bukit_1`, `bukit_2` | lebar 640–720 px | Bukit hijau membulat landai dengan tepi navy, boleh sedikit pohon kecil. |
| `awan_1`, `awan_2`, `awan_3` | lebar 220–300 px | Awan putih gemuk, garis navy, tiga bentuk. Pivot pusat. |
| `matahari` | diameter 200 px | Matahari kuning ramah (mata, senyum) dengan sinar bulat. Pivot pusat. |
| `pohon_kelapa` | tinggi 300 px | Pohon kelapa melengkung gemuk. |
| `pohon_bulat` | tinggi 230 px | Pohon tajuk bulat. |
| `pohon_kota` | tinggi 220 px | Pohon kecil bulat warna hijau cerah. |
| `semak` | lebar 110 px | Semak bulat hijau. |
| `bunga_1`, `bunga_2` | tinggi 70 px | Bunga cerah (merah/kuning). |
| `padi_rumpun` | tinggi 110 px | Rumpun padi hijau kekuningan. |
| `rumah_joglo` | lebar 380 px | Rumah joglo Jawa gemuk (atap tumpang cokelat, tiang kayu). |
| `gubuk_sawah` | lebar 220 px | Gubuk sawah kecil beratap jerami. |
| `kincir_air` | tinggi 220 px | Kincir air kayu gemuk. |
| `gedung_1`, `gedung_2`, `gedung_3` | tinggi 340 px | Gedung 2–4 lantai gemuk warna cerah (merah, kuning, biru), jendela bulat/kotak besar. |
| `lampu_jalan` | tinggi 220 px | Lampu jalan gemuk. |
| `peron_stasiun` | lebar 800 px | Peron stasiun samping: lantai peron tebal, atap merah, tiang kayu, bangku, rambu bulat. Pivot tengah-bawah lantai. |
| `palang_rel_tutup` | lebar 160 px | Palang rel: tiang di kiri, lengan horizontal belang merah-putih tebal. (Versi "buka" tidak perlu; kode membuatnya hilang.) |
| `terowongan_belakang` | lebar 1100 px | Bukit hijau besar dengan **mulut terowongan melengkung berwarna gelap** (tampak depan), jalan rel masuk. Satu sprite saja; kode menaruhnya di belakang kereta. Pivot tengah-bawah. |
| `jembatan_kayu` | lebar 960 px | Jembatan kayu tampak samping, bentang datar, pagar kayu, tiang penyangga di bawah. Pivot: titik kontak tanah tengah. Anchor `dek` = `[x,y]` permukaan dek tengah (tempat roda menapak; y relatif gambar). |
| `bintang_kecil` | 48 px | Bintang kuning gemuk bergaris navy. Pivot pusat. |

Urutan B: tulis hasil ke `assets/sprites/manifest_b.json` (format sama).

## Selesai
Semua nama di tabel ada, file PNG sesuai ukuran manifest, transparan bersih, gaya serasi dengan referensi, dan dilihat satu per satu lewat lembar kontak (`docs/pratinjau/sprite_v2_*.png`). Lapor singkat: daftar, kekurangan, cara menjalankan ulang. Jangan mengklaim selesai tanpa melihat hasil.
