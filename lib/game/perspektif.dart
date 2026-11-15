import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../core/konstanta.dart';
import 'galeri.dart';
import 'kereta_game.dart';

// ---------------------------------------------------------------------------
// Kamera orang ketiga: kamera di atas dan di belakang kereta, lurus menghadap rel.
// Dunia 3D (x kanan, y atas, z maju) diproyeksikan dengan perspektif; benda-benda
// adalah sprite pra-render dari model 3D yang sama dengan tampak samping.

/// Garis cakrawala pada kanvas desain.
const double kHorizon = 330;

/// Panjang fokal (piksel desain per unit pada z = 1).
const double kFokal = 780;

/// Tinggi kamera di atas rel (unit dunia; 1 unit = 160 px sprite).
const double kTinggiKamera = 3.4;

/// Konversi jarak dunia tampak samping (piksel) ke unit kedalaman.
const double kMeterPerPx = 1 / 55;

/// Kedalaman bidang belakang gerbong terakhir dari kamera.
const double kZBelakang = 5.2;

/// Jarak antar bidang belakang gerbong (unit).
const double kJarakGerbong = 2.35;

/// Panjang satu putaran dekorasi tepi rel.
const double kPeriodeDekor = 96;

/// Kedalaman minimum yang digambar (di depan bidang dekat kamera).
const double kZDekat = 1.4;

/// Pemetaan titik dunia ke layar.
class Proyeksi {
  const Proyeksi({required this.lebar, this.fokal = kFokal, this.dx = 0, this.dy = 0});

  final double lebar;
  final double fokal;
  final double dx;
  final double dy;

  double get cx => lebar / 2 + dx;
  double get hor => kHorizon + dy;

  /// Titik layar untuk (x lateral, y tinggi dari tanah, z kedalaman).
  Offset titik(double x, double y, double z) =>
      Offset(cx + fokal * x / z, hor + fokal * (kTinggiKamera - y) / z);

  /// Piksel desain per unit dunia pada kedalaman [z].
  double skala(double z) => fokal / z;
}

/// Kedalaman dekorasi yang berputar: bergerak mendekat saat kereta maju.
double zDekorBerputar(double zDasar, double jarakUnit) {
  final m = (zDasar - jarakUnit) % kPeriodeDekor;
  return (m < 0 ? m + kPeriodeDekor : m) + kZDekat;
}

/// Benda di dunia 3D milik misi (hewan di rel, terowongan, palang, dll.).
class ItemP {
  ItemP(this.nama,
      {this.wx = 0, this.lateral = 0, this.tinggi = 0, this.skala = 1, this.alpha = 1});

  final String nama;

  /// Posisi di sumbu rel dalam piksel dunia tampak samping (sama dengan ObjekDunia.wx).
  double wx;

  /// Pergeseran kiri(-)/kanan(+) dari tengah rel, dalam unit.
  double lateral;

  /// Tinggi dari tanah, dalam unit.
  double tinggi;
  double skala;
  double alpha;
  bool tampil = true;
}

class _Dekor {
  const _Dekor(this.nama, this.lateral, this.zDasar, this.skala);
  final String nama;
  final double lateral;
  final double zDasar;
  final double skala;
}

class _Gambar3 {
  _Gambar3(this.z, this.nama, this.dasar, this.sk, this.alpha);
  final double z;
  final String nama;
  final Offset dasar;
  final double sk;
  final double alpha;
}

class _Puff {
  _Puff(this.x, this.y, this.z, this.hidup);
  double x;
  double y;
  double z;
  final double hidup;
  double umur = 0;
}

/// Daftar sprite untuk tampak belakang.
List<String> spriteBelakang(List<String> warnaGerbong) => [
      'tuut_belakang',
      for (final w in warnaGerbong.toSet()) 'gerbong_${w}_belakang',
    ];

/// Seluruh dunia tampak belakang. Digambar sebagai satu komponen agar benda bisa diurutkan
/// berdasarkan kedalaman (jauh dulu, dekat belakangan).
class DuniaBelakang extends PositionComponent with HasGameReference<KeretaGame> {
  DuniaBelakang(this.dunia, this.warnaGerbong) : super(priority: 3);

  final int dunia;
  final List<String> warnaGerbong;

  /// Benda dinamis milik misi.
  final List<ItemP> item = [];

  /// Bila true: di dalam terowongan (tanpa langit/pemandangan, ada cahaya ujung).
  bool dalamTerowongan = false;

  /// Radius cahaya ujung terowongan (0 = tak tampak, >1 = menutup layar).
  double cahayaUjung = 0;

  final List<_Dekor> _dekor = [];
  final List<_Puff> _asap = [];
  final math.Random _acak = math.Random(5);
  double _waktu = 0;
  double _getar = 0;
  double _kecHalus = 0;
  double _asapHitung = 0;

  static const List<String> _desaBesar = [
    'pohon_kelapa', 'pohon_bulat', 'rumah_joglo', 'gubuk_sawah', 'kincir_air', 'pohon_kelapa',
  ];
  static const List<String> _kotaBesar = [
    'gedung_1', 'gedung_2', 'gedung_3', 'pohon_kota', 'gedung_1', 'gedung_2',
  ];

  @override
  Future<void> onLoad() async {
    final besar = dunia == 0 ? _desaBesar : _kotaBesar;
    final kecil = dunia == 0
        ? const ['semak', 'padi_rumpun', 'bunga_1', 'bunga_2']
        : const ['semak', 'lampu_jalan', 'bunga_1', 'bunga_2'];
    for (final sisi in [-1.0, 1.0]) {
      var z = _acak.nextDouble() * 6;
      var i = 0;
      while (z < kPeriodeDekor) {
        final b = besar[(i + (sisi > 0 ? 3 : 0)) % besar.length];
        _dekor.add(_Dekor(b, sisi * (6.5 + _acak.nextDouble() * 6), z, 2.1 + _acak.nextDouble() * 0.5));
        z += 6 + _acak.nextDouble() * 6;
        i++;
      }
      z = _acak.nextDouble() * 4;
      i = 0;
      while (z < kPeriodeDekor) {
        final k = kecil[(i + (sisi > 0 ? 1 : 0)) % kecil.length];
        _dekor.add(_Dekor(k, sisi * (2.8 + _acak.nextDouble() * 1.8), z, 1.5 + _acak.nextDouble() * 0.4));
        z += 3.5 + _acak.nextDouble() * 4;
        i++;
      }
    }
  }

  /// Guncangan kamera sesaat (peluit, rintangan).
  void getar() => _getar = 1;

  /// Kedalaman bidang depan lokomotif (hidung).
  double get zHidung => kZBelakang + warnaGerbong.length * kJarakGerbong + 2.9;

  /// Kedalaman dunia untuk benda di sumbu rel pada posisi [wx] saat ini.
  double zUntuk(double wx) {
    final kereta = game.kereta;
    final hidungPx = kereta?.kananLoko ?? 256;
    return zHidung + (wx - game.jarak - hidungPx) * kMeterPerPx;
  }

  @override
  void renderTree(Canvas canvas) {
    if (game.kamera != Kamera.belakang) return;
    super.renderTree(canvas);
  }

  @override
  void update(double dt) {
    _waktu += dt;
    _getar = math.max(0, _getar - dt * 2.2);
    final v = game.kecepatan / 470;
    _kecHalus += (v - _kecHalus) * math.min(1, dt * 4);
    if (game.kamera != Kamera.belakang) return;
    // Asap lokomotif dalam koordinat dunia.
    _asapHitung += dt;
    final jeda = game.kecepatan > 20 ? 0.12 : 0.4;
    if (_asapHitung >= jeda) {
      _asapHitung = 0;
      _asap.add(_Puff((_acak.nextDouble() - 0.5) * 0.12, 2.5, kZBelakang + warnaGerbong.length * kJarakGerbong + 1.9, 1.1));
    }
    final geser = game.kecepatan * kMeterPerPx * dt;
    for (final p in _asap) {
      p.umur += dt;
      p.y += 0.9 * dt;
      p.z -= geser * 0.45;
    }
    // Asap tidak boleh mendekati kamera: buang sebelum menutupi gerbong.
    final zBatas = kZBelakang + warnaGerbong.length * kJarakGerbong;
    _asap.removeWhere((p) => p.umur > p.hidup || p.z < zBatas);
  }

  Proyeksi _proyeksi(double lebar) {
    final k = _kecHalus;
    final guncang = _getar * _getar;
    final dy = math.sin(_waktu * 55) * 9 * guncang + math.sin(game.jarak / 22) * 3.5 * k;
    final dx = math.sin(game.jarak / 90) * 14 * k + math.sin(_waktu * 47) * 7 * guncang;
    // Zum cepat: semakin cepat, semakin sempit sudut pandang.
    return Proyeksi(lebar: lebar, fokal: kFokal * (1 + 0.1 * k), dx: dx, dy: dy);
  }

  @override
  void render(Canvas canvas) {
    final lebar = game.ruang.x;
    final p = _proyeksi(lebar);
    final k = _kecHalus;
    canvas.save();
    // Roll lembut mengikuti gerak rel.
    final sudut = math.sin(game.jarak / 140) * 0.014 * k + math.sin(_waktu * 50) * 0.01 * _getar;
    canvas.translate(lebar / 2, kTinggi / 2);
    canvas.rotate(sudut);
    canvas.scale(1 + 0.03 * k + 0.02 * _getar);
    canvas.translate(-lebar / 2, -kTinggi / 2);

    if (dalamTerowongan) {
      _gambarDalamTerowongan(canvas, p, lebar);
    } else {
      _gambarLangit(canvas, p, lebar);
      _gambarTanah(canvas, p, lebar);
    }
    _gambarRel(canvas, p);
    _gambarBenda(canvas, p);
    if (!dalamTerowongan) _garisKecepatan(canvas, lebar, k);
    canvas.restore();
  }

  // ------------------------------------------------------------------ latar

  void _gambarLangit(Canvas canvas, Proyeksi p, double lebar) {
    final hor = p.hor;
    canvas.drawRect(
      Rect.fromLTWH(-80, -80, lebar + 160, hor + 80),
      Paint()
        ..shader = Gradient.linear(const Offset(0, 0), const Offset(0, kHorizon), [Palet.langit, Palet.langitMuda]),
    );
    if (Galeri.i.ada('matahari')) {
      final s = Galeri.i['matahari'];
      s.sprite.render(canvas,
          position: Vector2(lebar * 0.72 - s.pivot.x, 150 - s.pivot.y), size: s.ukuran);
    }
    // Gunung dan bukit di cakrawala; bergeser sangat pelan saat kereta berbelok halus.
    void lapis(String nama, double xFrac, double skala, double parallax, double naik) {
      if (!Galeri.i.ada(nama)) return;
      final s = Galeri.i[nama];
      final geser = math.sin(game.jarak / 4000 * 2 * math.pi) * parallax;
      s.sprite.render(canvas,
          position: Vector2(lebar * xFrac + geser - s.pivot.x * skala, hor + naik - s.pivot.y * skala),
          size: s.ukuran * skala);
    }

    lapis('gunung_1', 0.22, 1.15, 40, 18);
    lapis('gunung_2', 0.78, 1.0, 40, 18);
    lapis('bukit_1', 0.05, 1.0, 90, 6);
    lapis('bukit_2', 0.55, 0.9, 90, 6);
    lapis('bukit_1', 0.98, 0.85, 90, 6);
    for (final (n, x, y) in [('awan_1', 0.15, 120.0), ('awan_2', 0.5, 200.0), ('awan_3', 0.85, 90.0)]) {
      if (!Galeri.i.ada(n)) continue;
      final s = Galeri.i[n];
      final dx = ((x * lebar + _waktu * 12) % (lebar + 400)) - 200;
      s.sprite.render(canvas, position: Vector2(dx - s.pivot.x, y - s.pivot.y), size: s.ukuran);
    }
  }

  void _gambarTanah(Canvas canvas, Proyeksi p, double lebar) {
    final hor = p.hor;
    canvas.drawRect(Rect.fromLTWH(-80, hor, lebar + 160, kTinggi - hor + 80), Paint()..color = Palet.rumput);
    // Pita rumput bergantian berdasarkan kedalaman (memberi rasa kecepatan).
    final jarakUnit = game.jarak * kMeterPerPx;
    const lebarPita = 3.2;
    final gelap = Paint()..color = Palet.rumputTua.withValues(alpha: 0.55);
    final mulai = (jarakUnit / lebarPita).floor();
    for (var i = mulai; i < mulai + 40; i++) {
      if (i.isEven) continue;
      final z1 = math.max(kZDekat * 0.8, i * lebarPita - jarakUnit + 0.0001);
      final z2 = (i + 1) * lebarPita - jarakUnit;
      if (z2 <= 0.8) continue;
      final y1 = p.titik(0, 0, math.max(0.8, z1)).dy;
      final y2 = p.titik(0, 0, z2).dy;
      if (y2 > kTinggi + 80) continue;
      canvas.drawRect(Rect.fromLTRB(-80, math.min(y1, y2), lebar + 80, math.max(y1, y2)), gelap);
    }
    // Kabut tipis di cakrawala agar menyatu dengan langit.
    canvas.drawRect(
      Rect.fromLTWH(-80, hor - 2, lebar + 160, 70),
      Paint()
        ..shader = Gradient.linear(Offset(0, hor), Offset(0, hor + 70),
            [Palet.langitMuda.withValues(alpha: 0.85), Palet.langitMuda.withValues(alpha: 0)]),
    );
  }

  void _gambarDalamTerowongan(Canvas canvas, Proyeksi p, double lebar) {
    canvas.drawRect(Rect.fromLTWH(-80, -80, lebar + 160, kTinggi + 160), Paint()..color = const Color(0xFF0B1426));
    // Dinding berbentuk terowongan melengkung yang menyempit ke titik hilang.
    final c = Offset(p.cx, p.hor);
    for (var i = 0; i < 7; i++) {
      final r = 1100.0 / (1 + i * 0.9);
      canvas.drawOval(
        Rect.fromCenter(center: c, width: r * 2.1, height: r * 1.7),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = const Color(0xFF223055).withValues(alpha: 0.9 - i * 0.1),
      );
    }
    // Lantai terowongan.
    canvas.drawRect(
      Rect.fromLTWH(-80, p.hor, lebar + 160, kTinggi - p.hor + 80),
      Paint()..color = const Color(0xFF16213C),
    );
    final cahaya = cahayaUjung;
    if (cahaya > 0) {
      final r = 16 + 2400 * cahaya * cahaya;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = Gradient.radial(c, r, [
            const Color(0xFFFFFBE0),
            const Color(0xFFFFF3A8),
            const Color(0x00FFF3A8),
          ], const [0.0, 0.7, 1.0]),
      );
    }
  }

  void _gambarRel(Canvas canvas, Proyeksi p) {
    final jarakUnit = game.jarak * kMeterPerPx;
    const zJauh = 160.0;
    Path kuad(double x1, double x2, double z1, double z2) {
      final a = p.titik(x1, 0, z1);
      final b = p.titik(x2, 0, z1);
      final c = p.titik(x2, 0, z2);
      final d = p.titik(x1, 0, z2);
      return Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy)
        ..lineTo(d.dx, d.dy)
        ..close();
    }

    // Hamparan kerikil.
    canvas.drawPath(kuad(-1.35, 1.35, 0.7, zJauh), Paint()..color = Palet.kerikil);
    final tepi = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..color = Palet.garis;
    // Bantalan kayu tiap 0,95 unit, bergerak mendekat sesuai jarak.
    const langkah = 0.95;
    final kayu = Paint()..color = const Color(0xFFB9814A);
    final mulai = (jarakUnit / langkah).floor();
    for (var i = mulai + 80; i >= mulai; i--) {
      final z1 = i * langkah - jarakUnit;
      if (z1 < 0.75 || z1 > 85) continue;
      final jalur = kuad(-1.15, 1.15, z1, z1 + 0.34);
      canvas.drawPath(jalur, kayu);
      if (z1 < 30) canvas.drawPath(jalur, tepi);
    }
    // Dua rel baja.
    final baja = Paint()..color = Palet.baja;
    final terang = Paint()..color = const Color(0xFFD5DEE8);
    for (final x in [-0.72, 0.72]) {
      canvas.drawPath(kuad(x - 0.09, x + 0.09, 0.7, zJauh), baja);
      canvas.drawPath(kuad(x - 0.09, x + 0.09, 0.7, zJauh), tepi);
      canvas.drawPath(kuad(x - 0.03, x + 0.03, 0.7, zJauh), terang);
    }
  }

  // ------------------------------------------------------------------ benda

  void _gambarBenda(Canvas canvas, Proyeksi p) {
    final daftar = <_Gambar3>[];
    final jarakUnit = game.jarak * kMeterPerPx;

    if (!dalamTerowongan) {
      for (final d in _dekor) {
        if (!Galeri.i.ada(d.nama)) continue;
        final z = zDekorBerputar(d.zDasar, jarakUnit);
        final a = ((kPeriodeDekor + kZDekat - z) / 12).clamp(0.0, 1.0);
        daftar.add(_Gambar3(z, d.nama, p.titik(d.lateral, 0, z), d.skala, a));
      }
    }
    for (final it in item) {
      if (!it.tampil || !Galeri.i.ada(it.nama)) continue;
      final z = zUntuk(it.wx);
      if (z < 0.5 || z > 150) continue;
      final a = ((120 - z) / 20).clamp(0.0, 1.0) * it.alpha;
      daftar.add(_Gambar3(z, it.nama, p.titik(it.lateral, it.tinggi, z), it.skala, a));
    }
    // Kereta: gerbong terakhir paling dekat, lokomotif paling jauh.
    final n = warnaGerbong.length;
    final k = _kecHalus;
    for (var i = 0; i < n; i++) {
      final idx = n - 1 - i;
      final z = kZBelakang + i * kJarakGerbong;
      final goyang = (math.sin(game.jarak / 38 + i * 1.3) * 0.035 * k).abs();
      final nama = 'gerbong_${warnaGerbong[idx]}_belakang';
      if (Galeri.i.ada(nama)) daftar.add(_Gambar3(z - 0.01, nama, p.titik(0, goyang, z), 1, 1));
    }
    final zLoko = kZBelakang + n * kJarakGerbong;
    final goyangLoko = (math.sin(game.jarak / 38 + 0.4) * 0.04 * k).abs();
    if (Galeri.i.ada('tuut_belakang')) {
      daftar.add(_Gambar3(zLoko - 0.01, 'tuut_belakang', p.titik(0, goyangLoko, zLoko), 1, 1));
    }

    daftar.sort((a, b) => b.z.compareTo(a.z));
    for (final g in daftar) {
      final s = Galeri.i[g.nama];
      final sc = p.skala(g.z) / 160 * g.sk * kSkala;
      if (sc < 0.01 || sc > 12) continue;
      final w = s.ukuran.x * sc;
      if (g.dasar.dx + w < -200 || g.dasar.dx - w > game.ruang.x + 200) continue;
      final paint = g.alpha >= 0.99 ? null : (Paint()..color = Color.fromRGBO(255, 255, 255, g.alpha));
      s.sprite.render(
        canvas,
        position: Vector2(g.dasar.dx - s.pivot.x * sc, g.dasar.dy - s.pivot.y * sc),
        size: s.ukuran * sc,
        overridePaint: paint,
      );
    }
    // Asap lokomotif.
    for (final a in _asap) {
      final t = a.umur / a.hidup;
      final pt = p.titik(a.x, a.y, a.z);
      final r = (0.16 + t * 0.42) * p.skala(a.z);
      canvas.drawCircle(pt, r, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: (1 - t) * 0.9));
      canvas.drawCircle(
        pt,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Palet.garis.withValues(alpha: (1 - t) * 0.35),
      );
    }
  }

  void _garisKecepatan(Canvas canvas, double lebar, double k) {
    if (k < 0.55) return;
    final a = ((k - 0.55) / 0.45).clamp(0.0, 1.0) * 0.4;
    final cat = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: a)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final c = Offset(lebar / 2, kHorizon);
    for (var i = 0; i < 14; i++) {
      final ang = (i / 14) * math.pi * 2 + 0.2;
      final fase = ((_waktu * 1.6 + i * 0.37) % 1.0);
      final r1 = 700 + fase * 700;
      final r2 = r1 + 120 + fase * 120;
      canvas.drawLine(
        c + Offset(math.cos(ang), math.sin(ang)) * r1,
        c + Offset(math.cos(ang), math.sin(ang)) * r2,
        cat,
      );
    }
  }
}
