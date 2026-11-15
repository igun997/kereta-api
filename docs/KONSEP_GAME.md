# Kereta Api — Konsep Game (anak usia 3+)

Game Flutter berbahasa Indonesia: anak melajukan kereta, membunyikan peluit, dan menjalankan misi sederhana. Jalan di HP dan tablet. Tanpa membaca, tanpa kalah, tanpa iklan.

## 1. Prinsip desain untuk usia 3 tahun

| Prinsip | Artinya di game |
|---|---|
| Satu jari, satu aksi | Semua kontrol cukup tap atau tahan. Tidak ada swipe presisi, drag halus, atau multi-touch. |
| Tidak perlu membaca | Instruksi lewat suara bahasa Indonesia dan ikon. Teks hanya untuk orang tua. |
| Tidak ada kalah | Tidak ada game over, timer, atau nyawa. Salah pilih = kereta mundur pelan dan coba lagi, tanpa suara buruk. |
| Target sentuh besar | Tombol minimal **96 dp** (tablet: 120 dp), jarak antar tombol minimal 24 dp. Tombol di tepi bawah, mudah dijangkau jempol. |
| Umpan balik instan | Setiap tap langsung menghasilkan gerak, suara, dan animasi dalam < 100 ms. |
| Sesi pendek | Satu misi 1–2 menit. Setelah 3 misi muncul "yuk istirahat" (lembut, bukan paksaan). |
| Aman | Pintu orang tua (tahan 3 detik di pojok) untuk pengaturan. Tanpa iklan, tanpa pembelian dalam aplikasi, tanpa tautan keluar, tanpa internet. |
| Pengulangan itu baik | Anak 3 tahun suka mengulang. Misi yang sama boleh dimainkan berkali-kali dengan variasi kecil. |

## 2. Mekanik inti

Kereta berjalan **di atas rel** (on-rails), jadi anak tidak perlu menyetir.

1. **GAS** — tombol hijau besar. Tahan = kereta melaju, lepas = melambat pelan. Kecepatan naik bertahap, tidak mendadak.
2. **REM** — tombol merah besar. Tap = berhenti halus di titik terdekat (otomatis tepat di peron jika dekat stasiun).
3. **PELUIT** — tombol kuning. "Tuut tuut!" Menggerakkan hewan di rel, memanggil penumpang, membuka palang.
4. **Wesel (percabangan rel)** — kereta berhenti sebelum cabang, muncul 2 pilihan besar bergambar (misalnya gambar apel vs pisang). Tap salah satu, kereta lanjut.
5. **Tap benda di dunia** — awan, domba, kupu-kupu bereaksi lucu (hiburan, tanpa skor).
6. **Kamera** — dua sudut pandang. **Samping** untuk misi di stasiun (jemput teman, warna gerbong, bentuk, paket). **Orang ketiga**, yaitu kamera di atas dan di belakang kereta, lurus menghadap rel, untuk misi hewan di rel dan terowongan, dan bisa dipilih di mode jalan-jalan bebas lewat tombol kamera. Efek kamera: zum halus saat kereta makin cepat, goyang lembut mengikuti rel, guncangan saat peluit, garis kecepatan, dan transisi "whoosh" saat sudut berganti.

Kontrol alternatif (aksesibilitas): mode **Otomatis** — kereta jalan sendiri, anak hanya tap peluit dan pilih cabang.

## 3. Misi (semua tanpa teks)

| # | Misi | Isi | Belajar |
|---|---|---|---|
| 1 | **Jemput teman** | Berhenti di peron, hewan naik (1–3 ekor). Penumpang melompat masuk satu per satu sambil dihitung "satu, dua, tiga". | Berhenti/jalan, berhitung 1–3 |
| 2 | **Warna gerbong** | Gerbong merah, kuning, biru menunggu. Tap buah yang warnanya sama ke gerbong. | Warna |
| 3 | **Bunyikan peluit** | Kerbau/ayam di rel. Bunyikan peluit, mereka minggir. | Sebab-akibat |
| 4 | **Terowongan gelap** | Masuk terowongan, nyalakan lampu dengan tap, kunang-kunang muncul. | Sebab-akibat |
| 5 | **Bentuk di jembatan** | Cocokkan bentuk (bulat, kotak, segitiga) ke lubang di jembatan. | Bentuk |
| 6 | **Antar paket** | Ambil paket di Stasiun A, antar ke rumah dengan warna sama. | Mencocokkan |

Tiap misi selesai dengan: konfeti, kembang api bintang, kereta "tuut tuut!", dan **stiker** (koleksi, bukan skor). Stiker disimpan di buku stiker.

## 4. Dunia (4 tema Indonesia)

| Dunia | Latar | Karakter |
|---|---|---|
| **Desa Sawah** | Sawah hijau, kerbau, rumah joglo, pohon kelapa, gunung kerucut di belakang | ayam, kerbau, bebek |
| **Pantai** | Pasir, ombak, perahu layar, mercusuar | kepiting, penyu, camar |
| **Kota Kecil** | Rumah warna-warni, stasiun besar, jembatan | kucing, anjing, burung |
| **Hutan Pelangi** | Pohon besar, terowongan, jembatan kayu | monyet, kupu-kupu, kelinci |

Dunia dibuka bertahap oleh stiker (bukan oleh uang). Untuk versi 1 cukup **Desa Sawah** + **Kota Kecil**.

## 5. Tokoh

- **Tuut** — lokomotif merah, mata bulat besar, senyum. Maskot dan ikon aplikasi.
- Gerbong: **Kuning** (penumpang), **Biru** (buah), **Hijau** (paket).
- Pembantu: **Pak Wesel** (kucing petugas stasiun) memberi petunjuk lewat suara.
- Pengisi suara: bahasa Indonesia, hangat, pelan, kalimat pendek ("Ayo jalan!", "Hebat!", "Satu, dua, tiga!").

## 6. Arah seni (art direction)

**Gaya:** mainan kayu / vinyl yang gemuk: bentuk membulat, tanpa sudut tajam, tanpa bagian tipis. Garis tepi tebal biru tua. Warna datar dengan satu lapis bayangan lembut. Bisa diwujudkan dari model 3D yang dirender ke sprite 2D transparan.

**Palet (kontras tinggi):**

| Peran | Warna | Hex |
|---|---|---|
| Garis tepi / teks | Biru malam | `#14213D` |
| Langit | Biru langit | `#6FD3FF` |
| Rumput / GAS | Hijau cerah | `#34C759` |
| Lokomotif / REM | Merah | `#FF3B30` |
| Aksen / PELUIT | Kuning | `#FFD60A` |
| Roda / air | Biru | `#1E88FF` |
| Jeruk / matahari | Oranye | `#FF9500` |
| Rel / tanah | Cokelat hangat | `#A9713F` |
| Putih | Awan, mata | `#FFFFFF` |

Aturan:
- Maksimal 5 warna dominan per layar. Objek yang harus ditap selalu **paling jenuh** dan **paling besar**; latar sedikit lebih pucat.
- Jangan membedakan hanya merah vs hijau. Setiap warna misi juga punya **bentuk/pola** (merah = bulat, kuning = bintang, biru = kotak) untuk anak buta warna.
- Rasio kontras objek terhadap latar minimal 3:1.
- Tanpa kilatan cepat (aman untuk epilepsi), animasi lembut, maksimal 3 gerakan besar sekaligus.

## 7. Layar & responsif (HP dan tablet)

- **Landscape terkunci.** Anak 3 tahun memegang tablet melebar, dan rel horizontal paling natural.
- Kanvas desain **1920×1080** (16:9). Game skala `BoxFit.contain` untuk elemen penting (kereta, tombol), sedangkan latar diperluas ke samping untuk rasio lebar/tinggi seperti 19.5:9 (HP) dan 4:3 (tablet).
- Zona aman: semua tombol dan kereta di dalam area 16:9 tengah; sisanya hanya dekorasi.
- Tombol: ukuran dalam dp ikut `shortestSide`: HP ≥ 96 dp, tablet ≥ 120 dp. Tombol di kiri-bawah dan kanan-bawah.
- Uji target: 360×640 dp (HP kecil), 412×915 dp (HP biasa), 800×1280 dp (tablet 8"), 1024×1366 dp (tablet 11").
- Performa: target 60 fps di HP Android ~3 GB RAM (contoh uji: Samsung A22). Semua model dibuat **low-poly gemuk** dan diekspor `.glb`; jika 3D saat jalan terlalu berat di HP lama, sprite pra-render (`assets/sprites`) jadi cadangan 2.5D dari model yang sama.

## 8. Teknis Flutter

- Mesin: game ini **3D**. Model 3D dibuat di Blender (bergaya kartun dengan garis tepi tebal, serupa logo) dan dirender dari tiga sudut (samping, belakang, depan) menjadi sprite dengan garis tepi yang konsisten. Di Flutter/Flame, dunia orang ketiga diproyeksikan dengan **perspektif sungguhan** (kamera dengan tinggi dan panjang fokal, titik hilang di cakrawala, benda diurutkan menurut kedalaman). Kami tidak memuat mesh 3D saat berjalan karena Samsung A22 menjalankan Impeller lewat OpenGL ES, sedangkan Flutter GPU/`flutter_scene` memerlukan Vulkan. **Terukur di Samsung A22 (APK rilis):** tampak samping 59 fps, kamera orang ketiga 60 fps (interval frame rata-rata 16,6 ms, p99 16,8 ms), memori total ±200 MB. UI orang tua memakai widget Flutter biasa.
- Lokalisasi: `id` sebagai bahasa utama (ARB), bahasa Inggris opsional nanti.
- Audio: `audioplayers` (MP3 pendek; efek lewat `AudioPool`, suara pemandu satu per satu, musik loop). Suara pelan dan hangat, tanpa bunyi keras.
- Penyimpanan lokal (stiker, dunia terbuka): `shared_preferences`.
- Build dan tes **hanya lewat `rflutter`** di sandbox jarak jauh.

## 9. Alur pembuatan aset

```
Blender 3D (remote, rblender)  ──render──►  sprite PNG transparan (atlas)  ──►  Flutter/Flame
Blender 3D                      ──export─►  .glb (cadangan jika nanti butuh 3D)
Endpoint gambar (cx/gpt-6.1-sol, via tools/genimg.py) ─► logo, ikon aplikasi, tekstur, latar, stiker
```

- **Model 3D (Blender, via `rblender run scenes/toon_game.py`):** lokomotif Tuut, 4 gerbong, 6 hewan; satu model per tokoh dirender dari tiga sudut (samping, belakang, depan) dengan material toon dan garis tepi navy.
- **Hasil:** `assets/sprites/<nama>.png` + `manifest.json` (pivot dan anchor dalam piksel). Dunia, rumah, dan buah dibuat dengan gambar AI bergaya logo.
- **Tekstur & gambar 2D (AI):** logo, ikon aplikasi (1024×1024), stiker, latar langit, tekstur kayu/rumput/rel yang bisa diulang (tileable), ikon tombol, ikon hewan dan buah.

Struktur folder:

```
assets/
  brand/       logo, ikon aplikasi
  textures/    tekstur tileable (rumput, kayu, batu)
  sprites/     hasil render Blender (kereta, gerbong, rel)
  ui/          tombol GAS/REM/PELUIT, ikon
  scenery/     latar, pohon, rumah
  stickers/    stiker koleksi
  models/      .glb
scenes/        skrip Blender (rb)
tools/         genimg.py
docs/
```

## 10. Urutan kerja

1. Konsep, palet, dan logo (selesai: dokumen ini + draft logo).
2. Aset 3D inti: lokomotif Tuut, gerbong, rel, peron → render sprite.
3. Tekstur dan gambar 2D lewat endpoint gambar.
4. Prototipe Flame: kereta jalan di rel dengan GAS/REM/PELUIT (satu dunia).
5. Misi 1 (jemput teman) end-to-end, lalu misi lain.
6. Uji dengan anak 3 tahun dan orang tua, perbaiki, baru tambah dunia.
