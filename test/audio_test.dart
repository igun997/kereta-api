import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kereta_api/core/audio.dart';

/// Setiap nama suara yang dipakai kode harus ada sebagai berkas MP3 yang tidak kosong.
void main() {
  // Nama yang dipakai langsung oleh kode (bicara/bicaraUrut) dan oleh data misi.
  const suara = [
    'halo', 'ayo_jalan', 'tekan_hijau', 'tekan_merah', 'tekan_kuning', 'hebat', 'pintar', 'bagus',
    'yeay', 'coba_lagi', 'satu', 'dua', 'tiga', 'merah', 'kuning', 'biru', 'hijau', 'bulat',
    'bintang', 'kotak', 'segitiga', 'ayam', 'kucing', 'bebek', 'kerbau', 'kelinci', 'monyet',
    'apel', 'pisang', 'jeruk', 'blueberry', 'stasiun', 'tuut_tuut', 'misi1', 'misi2', 'misi3',
    'misi4', 'misi5', 'misi6', 'misi_selesai', 'istirahat', 'pilih_jalan',
  ];

  bool ada(String jalur) => File(jalur).existsSync() && File(jalur).lengthSync() > 1000;

  test('semua suara pemandu ada', () {
    final hilang = suara.where((n) => !ada('assets/audio/suara/$n.mp3')).toList();
    expect(hilang, isEmpty);
  });

  test('semua efek suara terdaftar ada', () {
    final hilang = Audio.daftarSfx.where((n) => !ada('assets/audio/sfx/$n.mp3')).toList();
    expect(hilang, isEmpty);
  });

  test('musik menu dan main ada', () {
    expect(ada('assets/audio/musik/menu.mp3'), isTrue);
    expect(ada('assets/audio/musik/main.mp3'), isTrue);
  });
}
