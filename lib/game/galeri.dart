import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/services.dart';

/// Satu sprite pra-render dengan titik pivot dan anchor dari manifest.json.
class Spr {
  Spr(this.nama, this.sprite, this.ukuran, this.pivot, this.anchors);

  final String nama;
  final Sprite sprite;

  /// Ukuran piksel asli sprite.
  final Vector2 ukuran;

  /// Titik kontak tanah (piksel sprite).
  final Vector2 pivot;
  final Map<String, dynamic> anchors;

  bool punya(String kunci) => anchors.containsKey(kunci);

  /// Anchor sebagai daftar titik (piksel sprite). Mendukung `[x, y]` dan `[[x, y], ...]`.
  List<Vector2> titik(String kunci) {
    final a = anchors[kunci];
    if (a is! List || a.isEmpty) return const [];
    if (a.first is List) {
      return [
        for (final p in a)
          Vector2((p[0] as num).toDouble(), (p[1] as num).toDouble()),
      ];
    }
    return [Vector2((a[0] as num).toDouble(), (a[1] as num).toDouble())];
  }

  /// Titik anchor relatif terhadap pivot (piksel sprite, sumbu y ke bawah).
  List<Vector2> relatif(String kunci) =>
      [for (final p in titik(kunci)) p - pivot];

  /// Area isi gerbong: kiri, kanan, y lantai (piksel sprite).
  List<double> get isi {
    final a = anchors['isi'];
    if (a is List && a.length >= 3 && a.first is num) {
      return [for (final v in a) (v as num).toDouble()];
    }
    return [ukuran.x * 0.2, ukuran.x * 0.8, ukuran.y * 0.5];
  }
}

/// Memuat sprite berdasarkan nama. Hanya yang diminta yang dimuat (hemat memori di HP lama).
class Galeri {
  Galeri._();
  static final Galeri i = Galeri._();

  Map<String, dynamic>? _manifest;
  final Map<String, Spr> _spr = {};
  final Map<String, String> _file = {};

  Future<void> muat(Iterable<String> nama) async {
    _manifest ??= (jsonDecode(
            await rootBundle.loadString('assets/sprites/manifest.json'))
        as Map<String, dynamic>)['sprites'] as Map<String, dynamic>;
    for (final n in nama) {
      if (_spr.containsKey(n)) continue;
      final m = _manifest![n] as Map<String, dynamic>?;
      if (m == null) throw StateError('Sprite "$n" tidak ada di manifest.json');
      final img = await Flame.images.load('sprites/${m['file']}');
      _file[n] = 'sprites/${m['file']}';
      final pivot = m['pivot'] as List;
      _spr[n] = Spr(
        n,
        Sprite(img),
        Vector2((m['w'] as num).toDouble(), (m['h'] as num).toDouble()),
        Vector2((pivot[0] as num).toDouble(), (pivot[1] as num).toDouble()),
        (m['anchors'] as Map<String, dynamic>?) ?? const {},
      );
    }
  }

  /// Apakah sprite sudah dimuat dan siap digambar.
  bool ada(String nama) => _spr.containsKey(nama);

  Spr operator [](String nama) =>
      _spr[nama] ?? (throw StateError('Sprite "$nama" belum dimuat'));

  /// Buang sprite yang tidak dipakai misi berikutnya dari memori (hemat RAM di HP lama).
  void lepasKecuali(Set<String> pakai) {
    for (final n in _spr.keys.where((k) => !pakai.contains(k)).toList()) {
      _spr.remove(n);
      final f = _file.remove(n);
      if (f != null) Flame.images.clear(f);
    }
  }
}
