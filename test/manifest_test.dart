import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kereta_api/game/dunia.dart';
import 'package:kereta_api/game/kereta.dart';
import 'package:kereta_api/game/kereta_game.dart';
import 'package:kereta_api/game/misi/misi.dart';

/// Kontrak antara kode game dan aset: semua yang diminta kode harus ada di manifest,
/// ukurannya sama dengan berkas PNG, dan anchor yang dipakai kereta/misi lengkap.
void main() {
  final manifest = jsonDecode(File('assets/sprites/manifest.json').readAsStringSync())
      as Map<String, dynamic>;
  final sprites = manifest['sprites'] as Map<String, dynamic>;

  KeretaGame buatGame() => KeretaGame(dunia: 0, misiNo: 0, padaSelesai: (_) {}, padaKeluar: () {});

  List<int> ukuranPng(String berkas) {
    final b = File('assets/sprites/$berkas').readAsBytesSync();
    expect(b.sublist(1, 4), [0x50, 0x4E, 0x47], reason: '$berkas bukan PNG');
    final d = ByteData.sublistView(b);
    return [d.getUint32(16), d.getUint32(20)];
  }

  test('skala manifest 160 piksel per unit', () {
    expect(manifest['ppu'], 160);
  });

  test('setiap sprite di manifest punya berkas, ukuran cocok, dan pivot wajar', () {
    expect(sprites, isNotEmpty);
    for (final e in sprites.entries) {
      final m = e.value as Map<String, dynamic>;
      final w = (m['w'] as num).toInt();
      final h = (m['h'] as num).toInt();
      expect(ukuranPng(m['file'] as String), [w, h], reason: '${e.key}: ukuran PNG != manifest');
      final p = m['pivot'] as List;
      expect(p[0], inInclusiveRange(0, w), reason: '${e.key}: pivot x di luar gambar');
      // Badan kereta dirender tanpa roda, jadi titik kontak tanah boleh sedikit di bawah gambar.
      expect(p[1], inInclusiveRange(0, h + 160), reason: '${e.key}: pivot y tidak wajar');
    }
  });

  test('semua sprite yang diminta dunia, kereta, dan misi ada di manifest', () {
    final diminta = <String>{
      ...spriteDunia(0),
      ...spriteDunia(1),
      ...spriteKereta(['merah', 'kuning', 'biru', 'hijau']),
    };
    final game = buatGame();
    for (var i = 0; i < 6; i++) {
      diminta.addAll(buatMisi(i, game)!.sprite);
    }
    final hilang = diminta.where((n) => !sprites.containsKey(n)).toList()..sort();
    expect(hilang, isEmpty, reason: 'sprite diminta kode tapi tidak ada di manifest');
  });

  test('anchor yang dipakai kereta dan misi tersedia dan masuk akal', () {
    List<dynamic> titik(String n, String k) {
      final a = (sprites[n] as Map<String, dynamic>)['anchors'] as Map<String, dynamic>?;
      expect(a, isNotNull, reason: '$n tanpa anchors');
      expect(a!.containsKey(k), isTrue, reason: '$n tanpa anchor "$k"');
      return a[k] as List;
    }

    expect(titik('tuut_badan', 'roda').length, 3);
    expect(titik('tuut_badan', 'cerobong'), isNotEmpty);
    for (final w in ['merah', 'kuning', 'biru', 'hijau']) {
      expect(titik('gerbong_${w}_badan', 'roda').length, 2);
      final isi = titik('gerbong_${w}_badan', 'isi');
      expect(isi.length, 3, reason: 'isi = [kiri, kanan, y_lantai]');
      expect(isi[0] as num, lessThan(isi[1] as num));
    }
    for (final w in ['merah', 'kuning', 'biru']) {
      titik('rumah_$w', 'pintu');
    }
  });

  test('roda terpasang di anchor: jari-jari roda tersedia dan wajar, roda di dalam badan', () {
    for (final n in ['tuut_badan', 'gerbong_merah_badan', 'gerbong_kuning_badan', 'gerbong_biru_badan', 'gerbong_hijau_badan']) {
      final m = sprites[n] as Map<String, dynamic>;
      final a = m['anchors'] as Map<String, dynamic>;
      final r = (a['roda_radius'] as num).toDouble();
      expect(r, inInclusiveRange(15, 90), reason: '$n: roda_radius tidak wajar');
      for (final p in a['roda'] as List) {
        expect((p[0] as num), inInclusiveRange(0, m['w'] as num), reason: '$n: roda di luar badan');
        expect((p[1] as num), inInclusiveRange(0, (m['h'] as num) + 80), reason: '$n: roda di luar badan');
      }
    }
    for (final n in ['tuut_roda', 'gerbong_roda']) {
      final m = sprites[n] as Map<String, dynamic>;
      expect(m['w'], m['h'], reason: '$n harus persegi');
      expect(m['pivot'], [(m['w'] as num) / 2, (m['h'] as num) / 2], reason: '$n berpivot di pusat');
    }
  });

  test('jembatan punya anchor dek di dalam gambar', () {
    final m = sprites['jembatan_kayu'] as Map<String, dynamic>;
    final dek = (m['anchors'] as Map<String, dynamic>)['dek'] as List;
    expect(dek[0] as num, inInclusiveRange(0, m['w'] as num));
    expect(dek[1] as num, inInclusiveRange(0, m['h'] as num));
  });

  test('ukuran total sprite terkendali (HP lama)', () {
    var total = 0;
    for (final m in sprites.values) {
      total += File('assets/sprites/${(m as Map<String, dynamic>)['file']}').lengthSync();
    }
    expect(total, lessThan(12 * 1024 * 1024));
  });
}
