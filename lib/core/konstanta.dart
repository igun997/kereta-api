import 'package:flutter/material.dart';

/// Tinggi kanvas desain game (piksel desain). Lebar mengikuti rasio layar.
const double kTinggi = 1080;

/// Garis rel (titik kontak roda) pada kanvas desain.
const double kYRel = 800;

/// Garis cakrawala (batas langit dan tanah).
const double kYCakrawala = 690;

/// Skala sprite pra-render (1 unit dunia = 160 px) ke piksel desain.
const double kSkala = 1.0;

/// Jumlah dunia dan misi per dunia.
const int kJumlahDunia = 2;
const int kMisiPerDunia = 6;

/// Palet resmi (lihat docs/KONSEP_GAME.md).
class Palet {
  static const garis = Color(0xFF14213D);
  static const langit = Color(0xFF6FD3FF);
  static const langitMuda = Color(0xFFC4EEFF);
  static const hijau = Color(0xFF34C759);
  static const merah = Color(0xFFFF3B30);
  static const kuning = Color(0xFFFFD60A);
  static const biru = Color(0xFF1E88FF);
  static const oranye = Color(0xFFFF9500);
  static const cokelat = Color(0xFFA9713F);
  static const putih = Color(0xFFFFFFFF);
  static const rumput = Color(0xFF45C940);
  static const rumputTua = Color(0xFF2FA83A);
  static const kerikil = Color(0xFFB9A98F);
  static const baja = Color(0xFF8A98A8);

  static Color warna(String nama) => switch (nama) {
        'merah' => merah,
        'kuning' => kuning,
        'biru' => biru,
        'hijau' => hijau,
        _ => putih,
      };
}

/// Nama dunia dan misi (untuk tampilan orang tua dan semantik aksesibilitas).
const List<String> kNamaDunia = ['Desa Sawah', 'Kota Kecil'];
const List<String> kNamaMisi = [
  'Jemput teman',
  'Warna gerbong',
  'Bunyikan peluit',
  'Terowongan gelap',
  'Bentuk di jembatan',
  'Antar paket',
];
