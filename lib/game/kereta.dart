import 'package:flame/effects.dart';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/audio.dart';
import '../core/konstanta.dart';
import 'komponen.dart';
import 'kereta_game.dart';

/// Sprite yang dibutuhkan kereta dengan gerbong berwarna tertentu.
List<String> spriteKereta(List<String> warnaGerbong) => [
      'tuut_badan', 'tuut_roda', 'gerbong_roda',
      for (final w in warnaGerbong.toSet()) 'gerbong_${w}_badan',
    ];

/// Lokomotif Tuut + gerbong. Pivot kereta = titik kontak roda lokomotif di rel.
class Kereta extends PositionComponent with HasGameReference<KeretaGame>, HanyaSamping {
  Kereta(this.warnaGerbong) : super(priority: 20);

  final List<String> warnaGerbong;

  late final Gambar _loko;
  final List<Gambar> badanGerbong = [];
  final List<Vector2> pivotGerbong = []; // dalam koordinat lokal kereta (tanpa skala)
  final List<_Roda> _roda = [];
  late final double _lebarTotal;
  late final double _kananLoko;
  late final double _kiriTotal;
  double _skalaKereta = 1;
  double _jarakChug = 0;
  double _bob = 0;

  double get skalaKereta => _skalaKereta;

  /// Jarak (piksel desain) dari pivot ke hidung lokomotif.
  double get kananLoko => _kananLoko * _skalaKereta;

  /// Posisi tengah seluruh rangkaian relatif terhadap pivot lokomotif (piksel desain).
  double get pusatX => (_kananLoko + _kiriTotal) / 2 * _skalaKereta;

  /// Lebar seluruh rangkaian (piksel desain).
  double get lebar => _lebarTotal * _skalaKereta;

  @override
  Future<void> onLoad() async {
    final g = game.galeri;
    // Lokomotif.
    _loko = Gambar('tuut_badan', priority: 10);
    await add(_loko);
    final lokoSpr = g['tuut_badan'];
    final rodaLoko = g['tuut_roda'];
    final rLoko = (lokoSpr.anchors['roda_radius'] as num?)?.toDouble() ?? rodaLoko.ukuran.x / 2;
    final skalaRodaLoko = rLoko / (rodaLoko.ukuran.x / 2);
    for (final p in lokoSpr.relatif('roda')) {
      final r = _Roda(
          Gambar('tuut_roda', posisi: p * kSkala, skala: kSkala * skalaRodaLoko, priority: 12),
          rLoko * kSkala);
      _roda.add(r);
      await add(r.gambar);
    }
    _kananLoko = (lokoSpr.ukuran.x - lokoSpr.pivot.x) * kSkala;
    // Gerbong ke belakang.
    var kiri = -lokoSpr.pivot.x * kSkala;
    for (final w in warnaGerbong) {
      final s = g['gerbong_${w}_badan'];
      final px = kiri - (s.ukuran.x - s.pivot.x) * kSkala - 2;
      final b = Gambar('gerbong_${w}_badan', posisi: Vector2(px, 0), priority: 10);
      badanGerbong.add(b);
      pivotGerbong.add(Vector2(px, 0));
      await add(b);
      final rodaG = g['gerbong_roda'];
      final rG = (s.anchors['roda_radius'] as num?)?.toDouble() ?? rodaG.ukuran.x / 2;
      final skalaRodaG = rG / (rodaG.ukuran.x / 2);
      for (final p in s.relatif('roda')) {
        final r = _Roda(
            Gambar('gerbong_roda',
                posisi: Vector2(px, 0) + p * kSkala, skala: kSkala * skalaRodaG, priority: 12),
            rG * kSkala);
        _roda.add(r);
        await add(r.gambar);
      }
      kiri = px - s.pivot.x * kSkala - 2;
    }
    _kiriTotal = kiri;
    _lebarTotal = _kananLoko - kiri;
    _hitungSkala();
  }

  void _hitungSkala() {
    final dipakai = game.ruang.x * 0.76;
    _skalaKereta = math.min(1.0, dipakai / _lebarTotal);
    scale = Vector2.all(_skalaKereta);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _hitungSkala();
  }

  /// Ubah koordinat lokal kereta menjadi koordinat desain (kanvas 1080 tinggi).
  Vector2 keDesain(Vector2 lokal) =>
      Vector2(game.trainX + lokal.x * _skalaKereta, kYRel + lokal.y * _skalaKereta);

  /// Posisi lokal slot isi gerbong `g`, urutan `k` dari `n` slot.
  Vector2 slotIsi(int g, int k, int n) {
    final s = game.galeri['gerbong_${warnaGerbong[g]}_badan'];
    final isi = s.isi;
    final kiri = (isi[0] - s.pivot.x) * kSkala;
    final kanan = (isi[1] - s.pivot.x) * kSkala;
    final lantai = (isi[2] - s.pivot.y) * kSkala;
    final x = kiri + (k + 0.5) / n * (kanan - kiri);
    return pivotGerbong[g] + Vector2(x, lantai);
  }

  /// Taruh benda di dalam gerbong (tergambar di belakang dinding bak).
  Future<void> tambahIsi(PositionComponent c) async {
    c.priority = 11;
    await add(c);
  }

  Vector2 get titikAsapDesain {
    final p = game.galeri['tuut_badan'].relatif('cerobong');
    return keDesain((p.isEmpty ? Vector2(0, -300) : p.first) * kSkala);
  }

  /// Peluit: Tuut membal sebentar dan mengeluarkan uap.
  void bunyikanPeluit() {
    Audio.i.sfx('peluit');
    game.asap.semburan();
    _loko.add(ScaleEffect.by(
      Vector2(1.06, 0.93),
      EffectController(duration: 0.12, reverseDuration: 0.12, repeatCount: 3),
    ));
  }

  @override
  void update(double dt) {
    final v = game.kecepatan;
    position.setValues(game.trainX, kYRel);
    // Roda berputar sesuai jarak.
    for (final r in _roda) {
      r.gambar.angle = game.jarak / (r.radius * _skalaKereta);
    }
    // Goyangan lembut saat berjalan.
    final amp = math.min(1.0, v / 250);
    _bob = math.sin(game.jarak / 38) * 3.0 * amp;
    _loko.position.y = -_bob.abs();
    for (var i = 0; i < badanGerbong.length; i++) {
      badanGerbong[i].position.y = -(math.sin(game.jarak / 38 + 1.2 + i) * 2.4 * amp).abs();
    }
    // Bunyi "cuk" per jarak tempuh.
    if (v > 12) {
      _jarakChug += v * dt;
      if (_jarakChug > 230) {
        _jarakChug = 0;
        Audio.i.sfx('chug', volume: 0.35 + 0.4 * amp);
      }
    }
  }
}

class _Roda {
  _Roda(this.gambar, this.radius);
  final Gambar gambar;
  final double radius;
}

/// Asap cerobong: gumpalan lunak yang naik dan tertinggal di belakang.
class Asap extends Component with HasGameReference<KeretaGame>, HanyaSamping {
  Asap() : super(priority: 25);

  final List<_Gumpal> _g = [];
  double _hitung = 0;
  final _acak = math.Random(3);

  void semburan() {
    for (var i = 0; i < 7; i++) {
      _tambah(besar: 1.5);
    }
  }

  void _tambah({double besar = 1}) {
    final k = game.kereta;
    if (k == null) return;
    final p = k.titikAsapDesain;
    _g.add(_Gumpal(
      p + Vector2((_acak.nextDouble() - 0.5) * 18, (_acak.nextDouble() - 0.5) * 8),
      (26 + _acak.nextDouble() * 12) * besar,
      0.9 + _acak.nextDouble() * 0.5,
    ));
  }

  @override
  void update(double dt) {
    final v = game.kecepatan;
    _hitung += dt;
    final jeda = v > 20 ? 0.14 : 0.45;
    if (_hitung >= jeda) {
      _hitung = 0;
      _tambah();
    }
    for (final g in _g) {
      g.umur += dt;
      g.p.x -= v * dt * 0.9 + 18 * dt;
      g.p.y -= 70 * dt;
    }
    _g.removeWhere((g) => g.umur > g.hidup);
  }

  @override
  void render(Canvas canvas) {
    for (final g in _g) {
      final t = g.umur / g.hidup;
      final a = (1 - t).clamp(0.0, 1.0) * 0.9;
      final r = g.radius * (0.7 + t * 1.3);
      canvas.drawCircle(Offset(g.p.x, g.p.y), r, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: a));
      canvas.drawCircle(
        Offset(g.p.x, g.p.y),
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Palet.garis.withValues(alpha: a * 0.35),
      );
    }
  }
}

class _Gumpal {
  _Gumpal(this.p, this.radius, this.hidup);
  final Vector2 p;
  final double radius;
  final double hidup;
  double umur = 0;
}
