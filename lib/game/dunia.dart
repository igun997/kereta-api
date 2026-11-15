import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/painting.dart';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

import '../core/konstanta.dart';
import 'galeri.dart';
import 'kereta_game.dart';

/// Satu benda dekorasi pada lapisan paralaks.
class ItemLapisan {
  const ItemLapisan(this.nama, this.x, {this.dy = 0, this.skala = 1});
  final String nama;
  final double x;
  final double dy;
  final double skala;
}

/// Lapisan yang berulang (seamless) dan bergeser sebanding dengan jarak tempuh kereta.
class LapisanParalaks extends PositionComponent with HasGameReference<KeretaGame>, HanyaSamping {
  LapisanParalaks({
    required this.item,
    required this.periode,
    required this.faktor,
    required this.yDasar,
    this.geserOtomatis = 0,
    super.priority,
  });

  final List<ItemLapisan> item;
  final double periode;
  final double faktor;
  final double yDasar;
  final double geserOtomatis;
  double _waktu = 0;

  @override
  void update(double dt) => _waktu += dt;

  @override
  void render(Canvas canvas) {
    final lebar = game.ruang.x;
    final geser = game.jarak * faktor + _waktu * geserOtomatis;
    for (final it in item) {
      final s = Galeri.i[it.nama];
      final k = it.skala * kSkala;
      final w = s.ukuran.x * k;
      var x = (it.x - geser) % periode;
      x -= periode;
      while (x < lebar + w) {
        if (x + w * 0.6 > 0 && x - w * 0.6 < lebar) {
          s.sprite.render(
            canvas,
            position: Vector2(x - s.pivot.x * k, yDasar + it.dy - s.pivot.y * k),
            size: s.ukuran * k,
          );
        }
        x += periode;
      }
    }
  }
}

/// Langit gradasi + matahari ramah.
class Langit extends PositionComponent with HasGameReference<KeretaGame>, HanyaSamping {
  Langit() : super(priority: 0);

  Paint? _cat;
  double _lebar = 0;

  @override
  void render(Canvas canvas) {
    final lebar = game.ruang.x;
    if (_cat == null || _lebar != lebar) {
      _lebar = lebar;
      _cat = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palet.langit, Palet.langitMuda],
        ).createShader(Rect.fromLTWH(0, 0, lebar, kYCakrawala));
    }
    canvas.drawRect(Rect.fromLTWH(0, 0, lebar, kYCakrawala + 4), _cat!);
    if (Galeri.i.ada('matahari')) {
      final s = Galeri.i['matahari'];
      s.sprite.render(canvas,
          position: Vector2(lebar * 0.3 - s.pivot.x, 170 - s.pivot.y),
          size: s.ukuran);
    }
  }
}

/// Tanah rumput bertekstur dan rel yang bergerak.
class Tanah extends PositionComponent with HasGameReference<KeretaGame>, HanyaSamping {
  Tanah() : super(priority: 5);

  late Image _rumput;
  late Image _kerikil;
  final _cat = Paint()..filterQuality = FilterQuality.medium;

  @override
  Future<void> onLoad() async {
    _rumput = await Flame.images.load('textures/rumput.png');
    _kerikil = await Flame.images.load('textures/batu_kerikil.png');
  }

  void _ubin(Canvas canvas, Image img, double geser, double ukuran, Rect area) {
    canvas.save();
    canvas.clipRect(area);
    final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    final mulaiX = -(geser % ukuran) - ukuran;
    for (var x = mulaiX; x < area.right; x += ukuran) {
      for (var y = area.top; y < area.bottom; y += ukuran) {
        canvas.drawImageRect(img, src, Rect.fromLTWH(x, y, ukuran + 1, ukuran + 1), _cat);
      }
    }
    canvas.restore();
  }

  @override
  void render(Canvas canvas) {
    final lebar = game.ruang.x;
    final j = game.jarak;
    // Rumput.
    _ubin(canvas, _rumput, j, 420, Rect.fromLTWH(0, kYCakrawala, lebar, kTinggi - kYCakrawala));
    // Garis tepi cakrawala (tipis, agar bukit dan tanah terpisah jelas).
    canvas.drawRect(
      Rect.fromLTWH(0, kYCakrawala - 2, lebar, 6),
      Paint()..color = Palet.rumputTua,
    );
    // Hamparan kerikil rel.
    const atas = kYRel - 30;
    const tinggiBed = 62.0;
    _ubin(canvas, _kerikil, j, 240, Rect.fromLTWH(0, atas, lebar, tinggiBed));
    final garisBed = Paint()
      ..color = Palet.garis
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawLine(const Offset(0, atas), Offset(lebar, atas), garisBed);
    canvas.drawLine(const Offset(0, atas + tinggiBed), Offset(lebar, atas + tinggiBed), garisBed);
    // Bantalan kayu.
    final kayu = Paint()..color = const Color(0xFFB9814A);
    final tepi = Paint()
      ..color = Palet.garis
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    const jarakBantalan = 76.0;
    for (var x = -(j % jarakBantalan) - jarakBantalan; x < lebar; x += jarakBantalan) {
      final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, atas + 8, 24, tinggiBed - 16), const Radius.circular(6));
      canvas.drawRRect(r, kayu);
      canvas.drawRRect(r, tepi);
    }
    // Rel baja: jauh (tipis) dan dekat (tebal, tempat roda menapak di y = kYRel).
    final baja = Paint()..color = Palet.baja;
    final terang = Paint()..color = const Color(0xFFD5DEE8);
    canvas.drawRect(Rect.fromLTWH(0, kYRel - 12, lebar, 8), baja);
    canvas.drawRect(Rect.fromLTWH(0, kYRel - 12, lebar, 8), tepi);
    canvas.drawRect(Rect.fromLTWH(0, kYRel, lebar, 14), baja);
    canvas.drawRect(Rect.fromLTWH(0, kYRel, lebar, 4), terang);
    canvas.drawRect(Rect.fromLTWH(0, kYRel, lebar, 14), tepi);
  }
}

/// Daftar sprite yang dibutuhkan oleh dunia (untuk dimuat lebih dulu).
List<String> spriteDunia(int dunia) => [
      'matahari', 'awan_1', 'awan_2', 'awan_3',
      'gunung_1', 'gunung_2', 'bukit_1', 'bukit_2',
      'semak', 'bunga_1', 'bunga_2',
      if (dunia == 0) ...[
        'rumah_joglo', 'pohon_kelapa', 'pohon_bulat', 'padi_rumpun',
        'gubuk_sawah', 'kincir_air',
      ] else ...[
        'gedung_1', 'gedung_2', 'gedung_3', 'lampu_jalan', 'pohon_kota',
      ],
    ];

/// Merangkai semua lapisan dunia menjadi komponen siap pakai.
List<Component> bangunDunia(int dunia, {int benih = 7}) {
  final acak = math.Random(benih);
  List<ItemLapisan> sebar(List<String> nama, int jumlah, double jarakMin, double jarakMax,
      {double skala = 1, double dy = 0, double skalaAcak = 0}) {
    final hasil = <ItemLapisan>[];
    var x = 200.0;
    for (var i = 0; i < jumlah; i++) {
      hasil.add(ItemLapisan(nama[i % nama.length], x,
          dy: dy, skala: skala + acak.nextDouble() * skalaAcak));
      x += jarakMin + acak.nextDouble() * (jarakMax - jarakMin);
    }
    return hasil;
  }

  double periodeDari(List<ItemLapisan> l, double celah) => l.last.x + celah;

  final awan = [
    const ItemLapisan('awan_1', 300, dy: 170),
    const ItemLapisan('awan_2', 1300, dy: 280),
    const ItemLapisan('awan_3', 2300, dy: 130),
  ];
  final gunung = [
    const ItemLapisan('gunung_1', 500),
    const ItemLapisan('gunung_2', 2000),
  ];
  final bukit = [
    const ItemLapisan('bukit_1', 300),
    const ItemLapisan('bukit_2', 1500),
    const ItemLapisan('bukit_1', 2600, skala: 0.85),
  ];

  final List<ItemLapisan> tengah;
  final List<ItemLapisan> dekat;
  if (dunia == 0) {
    tengah = sebar(
        ['pohon_kelapa', 'rumah_joglo', 'gubuk_sawah', 'pohon_bulat', 'kincir_air', 'pohon_kelapa', 'padi_rumpun'],
        7, 520, 880, skala: 0.82, skalaAcak: 0.12);
    dekat = sebar(['semak', 'padi_rumpun', 'bunga_1', 'bunga_2', 'semak', 'bunga_2'], 9, 260, 520,
        skala: 0.62, skalaAcak: 0.1);
  } else {
    tengah = sebar(['gedung_1', 'pohon_kota', 'gedung_2', 'lampu_jalan', 'gedung_3', 'pohon_kota', 'gedung_1', 'lampu_jalan'],
        8, 520, 800, skala: 0.82);
    dekat = sebar(['semak', 'bunga_1', 'lampu_jalan', 'bunga_2', 'semak'], 8, 300, 560,
        skala: 0.6, skalaAcak: 0.08);
  }

  return [
    Langit(),
    LapisanParalaks(item: awan, periode: 3200, faktor: 0.04, yDasar: 0, geserOtomatis: 14, priority: 1),
    LapisanParalaks(item: gunung, periode: 3400, faktor: 0.08, yDasar: kYCakrawala + 20, priority: 2),
    LapisanParalaks(item: bukit, periode: 3300, faktor: 0.2, yDasar: kYCakrawala + 36, priority: 3),
    Tanah(),
    LapisanParalaks(item: tengah, periode: periodeDari(tengah, 700), faktor: 0.55, yDasar: kYCakrawala + 76, priority: 7),
    LapisanParalaks(item: dekat, periode: periodeDari(dekat, 380), faktor: 1.0, yDasar: kYRel - 40, priority: 8),
  ];
}
