# Materi Google Play — Kereta Api

Siap salin ke Play Console. Bahasa utama: **Indonesia (id-ID)**.

## Informasi dasar
| Kolom | Isi |
|---|---|
| Nama aplikasi (maks 30) | **Kereta Api: Game Anak 3+** |
| Package | `id.kereta.kereta_api` |
| Kategori | Game › Edukasi (alternatif: Game › Kasual) |
| Tag | anak, edukasi, kereta, balita |
| Harga | Gratis, tanpa iklan, tanpa pembelian dalam aplikasi |
| Target usia | **3–5 tahun** dan masuk program *Dirancang untuk Keluarga* |
| Kebijakan privasi (URL) | Unggah `docs/PRIVASI.md` ke halaman web publik lalu isi URL-nya. Wajib untuk game anak. |

## Deskripsi singkat (maks 80)
Jalankan kereta Tuut, bunyikan peluit, dan selesaikan misi seru!

## Deskripsi lengkap (maks 4000)
Naik kereta bersama **Tuut**, lokomotif merah yang ramah!

Kereta Api adalah game untuk anak usia 3 tahun ke atas. Semuanya dirancang supaya mudah untuk jari kecil: tombol besar, warna cerah, dan **suara pemandu berbahasa Indonesia**. Anak tidak perlu membaca.

**Cara bermain**
• Tekan tombol hijau, kereta jalan. Tekan tombol merah, kereta berhenti.
• Tekan tombol kuning, Tuut membunyikan peluit "tuut tuut!".

**6 misi seru**
• Jemput teman: hewan naik kereta sambil dihitung satu, dua, tiga.
• Warna gerbong: masukkan buah ke gerbong yang warnanya sama.
• Bunyikan peluit: kerbau, ayam, dan kucing di rel akan minggir.
• Terowongan gelap: nyalakan lampu dan tangkap kunang-kunang.
• Bentuk di jembatan: cocokkan bulat, kotak, bintang, dan segitiga.
• Antar paket: antar paket ke rumah yang pintunya sewarna.

**2 dunia**: Desa Sawah dan Kota Kecil, plus mode jalan-jalan bebas.

**Kumpulkan 12 stiker** setiap menyelesaikan misi.

**Ramah anak dan orang tua**
• Tidak ada kalah, tidak ada batas waktu, tidak ada layar menakutkan.
• Tanpa iklan, tanpa pembelian dalam aplikasi, tanpa internet, tanpa izin apa pun.
• Pengaturan orang tua dilindungi gerbang tahan 3 detik.
• Mode otomatis untuk anak yang masih sangat kecil.
• Berjalan di HP dan tablet.

Belajar sambil bermain: berhitung 1–3, mengenal warna dan bentuk, sebab-akibat.
Disarankan bermain dalam sesi pendek dan didampingi orang tua.

## Aset grafis
| Aset | Berkas |
|---|---|
| Ikon aplikasi 512×512 | `assets/brand/app_icon_1024.png` (perkecil ke 512) |
| Gambar fitur 1024×500 | `assets/brand/feature_graphic.png` |
| Tangkapan layar | `docs/tangkapan_layar/` (ambil dari perangkat, landscape) |

## Kuesioner peringkat konten (IARC)
Semua jawaban **Tidak**: kekerasan, darah, seksualitas, bahasa kasar, zat terlarang, judi, interaksi pengguna, berbagi lokasi, pembelian digital, iklan. Hasil yang diharapkan: **Semua usia (3+)**.

## Keamanan data (Data safety)
- Mengumpulkan data pengguna: **Tidak**.
- Membagikan data dengan pihak ketiga: **Tidak**.
- Data dienkripsi saat transit: tidak berlaku (tanpa jaringan).
- Pengguna dapat meminta penghapusan: data hanya ada di perangkat; hapus lewat aplikasi atau hapus instalasi.

## Dirancang untuk Keluarga
- Target usia: 3–5.
- Tanpa iklan, tanpa SDK iklan/analitik, tanpa tautan keluar.
- Konten sesuai usia; tidak ada interaksi sosial.

## Rilis
```
rflutter build appbundle --release        # .aab untuk Play Console
rflutter build apk --release --split-per-abi   # .apk untuk uji manual
```
Berkas ada di `build/app/outputs/`. Kunci unggah: `android/app/upload-keystore.jks` + `android/key.properties`
(**simpan cadangannya di tempat aman dan terpisah; jangan di-commit**). Aktifkan *Play App Signing* saat unggahan pertama.
