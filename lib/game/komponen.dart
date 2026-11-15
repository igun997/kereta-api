import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart' show Curves;

import '../core/audio.dart';
import '../core/konstanta.dart';
import 'galeri.dart';
import 'kereta_game.dart';

/// Sprite pra-render dengan pivot dari manifest (titik pegang = titik kontak tanah).
class Gambar extends SpriteComponent {
  Gambar(String nama,
      {Vector2? posisi, double skala = kSkala, int? priority, double sudut = 0})
      : this._(Galeri.i[nama], posisi, skala, priority, sudut);

  Gambar._(this.spr, Vector2? posisi, double skala, int? priority, double sudut)
      : super(
          sprite: spr.sprite,
          size: spr.ukuran * skala,
          anchor: Anchor(spr.pivot.x / spr.ukuran.x, spr.pivot.y / spr.ukuran.y),
          position: posisi,
          priority: priority,
          angle: sudut,
        );

  final Spr spr;
}

/// Efek denyut lembut tanpa henti untuk menarik perhatian anak.
void denyut(PositionComponent c, {double besar = 1.12, double detik = 0.45}) {
  c.children.whereType<ScaleEffect>().toList().forEach((e) => e.removeFromParent());
  c.add(ScaleEffect.by(
    Vector2.all(besar),
    EffectController(
      duration: detik,
      reverseDuration: detik,
      infinite: true,
      curve: Curves.easeInOut,
    ),
  ));
}

void hentikanDenyut(PositionComponent c) {
  c.children.whereType<ScaleEffect>().toList().forEach((e) => e.removeFromParent());
  c.scale = Vector2.all(1);
}

/// Goyang ke kiri-kanan (salah pilih: ramah, tanpa hukuman).
void goyang(PositionComponent c) {
  c.add(RotateEffect.by(
    0.18,
    EffectController(duration: 0.07, reverseDuration: 0.07, repeatCount: 3),
  ));
}

/// Muncul dengan membal.
void muncul(PositionComponent c, {double detik = 0.45}) {
  c.scale = Vector2.zero();
  c.add(ScaleEffect.to(
    Vector2.all(1),
    EffectController(duration: detik, curve: Curves.elasticOut),
  ));
}

/// Tombol bulat besar (minimal 200 px desain, area sentuh 20% lebih luas).
class TombolBulat extends PositionComponent with TapCallbacks {
  TombolBulat(
    this.ikon, {
    required Vector2 posisi,
    this.diameter = 200,
    this.padaTekan,
    this.padaLepas,
    this.suaraTekan = 'tap',
    super.priority = 100,
  }) : super(
          position: posisi,
          size: Vector2.all(diameter * 1.2),
          anchor: Anchor.center,
        );

  String ikon;
  final double diameter;
  final void Function()? padaTekan;
  final void Function()? padaLepas;
  final String? suaraTekan;
  late SpriteComponent _gambar;
  bool _terlihat = true;

  @override
  Future<void> onLoad() async {
    _gambar = SpriteComponent(
      sprite: await Sprite.load('ui/$ikon.png'),
      size: Vector2.all(diameter),
      anchor: Anchor.center,
      position: size / 2,
    );
    await add(_gambar);
  }

  Future<void> gantiIkon(String baru) async {
    ikon = baru;
    _gambar.sprite = await Sprite.load('ui/$baru.png');
  }

  set terlihat(bool v) {
    _terlihat = v;
    scale = v ? Vector2.all(1) : Vector2.zero();
  }

  void sorot(bool aktif) {
    if (aktif) {
      denyut(_gambar, besar: 1.14);
    } else {
      hentikanDenyut(_gambar);
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) =>
      _terlihat && super.containsLocalPoint(point);

  @override
  void onTapDown(TapDownEvent event) {
    _gambar.scale = Vector2.all(0.9);
    if (suaraTekan != null) Audio.i.sfx(suaraTekan!);
    padaTekan?.call();
  }

  @override
  void onTapUp(TapUpEvent event) {
    _gambar.scale = Vector2.all(1);
    padaLepas?.call();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _gambar.scale = Vector2.all(1);
    padaLepas?.call();
  }
}

// ---------------------------------------------------------------------------
// Bentuk geometri (lencana warna dan bentuk, juga untuk anak buta warna).

Path jalurBentuk(String bentuk, Offset c, double r) {
  switch (bentuk) {
    case 'kotak':
      return Path()
        ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: c, width: r * 1.7, height: r * 1.7),
            Radius.circular(r * 0.25)));
    case 'segitiga':
      return Path()
        ..moveTo(c.dx, c.dy - r * 1.05)
        ..lineTo(c.dx + r * 1.05, c.dy + r * 0.8)
        ..lineTo(c.dx - r * 1.05, c.dy + r * 0.8)
        ..close();
    case 'bintang':
      final p = Path();
      for (var i = 0; i < 10; i++) {
        final rr = i.isEven ? r * 1.1 : r * 0.5;
        final a = -math.pi / 2 + i * math.pi / 5;
        final x = c.dx + rr * math.cos(a);
        final y = c.dy + rr * math.sin(a);
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      return p..close();
    default:
      return Path()..addOval(Rect.fromCircle(center: c, radius: r));
  }
}

void gambarBentuk(Canvas canvas, String bentuk, Offset c, double r,
    {required Color warna, double alpha = 1, bool isi = true}) {
  final jalur = jalurBentuk(bentuk, c, r);
  if (isi) {
    canvas.drawPath(
        jalur, Paint()..color = warna.withValues(alpha: alpha)..style = PaintingStyle.fill);
  }
  canvas.drawPath(
    jalur,
    Paint()
      ..color = Palet.garis.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.16
      ..strokeJoin = StrokeJoin.round,
  );
}

/// Kartu pilihan bulat besar berisi sprite atau bentuk.
class Kartu extends PositionComponent with TapCallbacks {
  Kartu({
    required this.kunci,
    required Vector2 posisi,
    this.padaPilih,
    this.namaSprite,
    this.bentuk,
    this.warnaBentuk,
    this.diameter = 230,
  }) : super(
          position: posisi,
          size: Vector2.all(diameter),
          anchor: Anchor.center,
          priority: 90,
        );

  final String kunci;
  final String? namaSprite;
  final String? bentuk;
  final Color? warnaBentuk;
  final double diameter;
  void Function(Kartu)? padaPilih;

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(c.translate(0, 8), diameter / 2,
        Paint()..color = const Color(0x33000000));
    canvas.drawCircle(c, diameter / 2, Paint()..color = Palet.putih);
    canvas.drawCircle(
        c,
        diameter / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..color = Palet.garis);
    if (namaSprite != null) {
      final s = Galeri.i[namaSprite!];
      final k = diameter * 0.66 / math.max(s.ukuran.x, s.ukuran.y);
      final ukuran = s.ukuran * k;
      // pivot sprite adalah tengah-bawah; geser agar kotak sprite berada di tengah kartu.
      s.sprite.render(canvas,
          position: Vector2(c.dx, c.dy) - ukuran / 2, size: ukuran);
    } else if (bentuk != null) {
      gambarBentuk(canvas, bentuk!, c, diameter * 0.27,
          warna: warnaBentuk ?? Palet.merah);
    }
  }

  @override
  void onTapDown(TapDownEvent event) => padaPilih?.call(this);

  void hilang() {
    add(ScaleEffect.to(Vector2.zero(), EffectController(duration: 0.25, curve: Curves.easeIn),
        onComplete: removeFromParent));
  }
}

/// Konfeti dan bintang yang menyembur atau jatuh sebagai perayaan.
class Perayaan extends Component {
  Perayaan.meledak(this.pusat, {int jumlah = 36})
      : _hujan = false,
        _sisa = 0,
        super(priority: 150) {
    _tebar(jumlah, pusat, meledak: true);
  }

  Perayaan.hujan(this.lebar, {double detik = 3.5})
      : pusat = Vector2.zero(),
        _hujan = true,
        _sisa = detik,
        super(priority: 150);

  final Vector2 pusat;
  double lebar = 0;
  final bool _hujan;
  double _sisa;
  final _acak = math.Random();
  final List<_Butir> _butir = [];

  static const _warna = [Palet.merah, Palet.kuning, Palet.biru, Palet.hijau, Palet.oranye];

  void _tebar(int n, Vector2 dari, {required bool meledak}) {
    for (var i = 0; i < n; i++) {
      final a = _acak.nextDouble() * math.pi * 2;
      final v = 250 + _acak.nextDouble() * 550;
      _butir.add(_Butir(
        dari.clone(),
        meledak
            ? Vector2(math.cos(a) * v, math.sin(a) * v - 250)
            : Vector2((_acak.nextDouble() - 0.5) * 120, 120 + _acak.nextDouble() * 160),
        _warna[_acak.nextInt(_warna.length)],
        _acak.nextBool(),
        4 + _acak.nextDouble() * 2,
        _acak.nextDouble() * 6,
      ));
    }
  }

  @override
  void update(double dt) {
    if (_hujan && _sisa > 0) {
      _sisa -= dt;
      if (_acak.nextDouble() < dt * 40) {
        _tebar(1, Vector2(_acak.nextDouble() * lebar, -30), meledak: false);
      }
    }
    for (final b in _butir) {
      b.umur += dt;
      b.p += b.v * dt;
      b.v.y += (_hujan ? 90 : 900) * dt;
      b.v.x *= 1 - 0.6 * dt;
    }
    _butir.removeWhere((b) => b.umur > b.hidup || b.p.y > kTinggi + 60);
    if (_butir.isEmpty && (!_hujan || _sisa <= 0)) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    for (final b in _butir) {
      final a = (1 - (b.umur / b.hidup)).clamp(0.0, 1.0);
      final c = Offset(b.p.x, b.p.y);
      if (b.bintang) {
        gambarBentuk(canvas, 'bintang', c, 14, warna: Palet.kuning, alpha: a);
      } else {
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(b.umur * 6 + b.fase);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-9, -5, 18, 10), const Radius.circular(3)),
          Paint()..color = b.warna.withValues(alpha: a),
        );
        canvas.restore();
      }
    }
  }
}

class _Butir {
  _Butir(this.p, this.v, this.warna, this.bintang, this.hidup, this.fase);
  Vector2 p;
  Vector2 v;
  final Color warna;
  final bool bintang;
  final double hidup;
  final double fase;
  double umur = 0;
}

/// Objek yang berdiri di dunia: posisi layar mengikuti jarak tempuh kereta.
class ObjekDunia extends PositionComponent with HasGameReference<KeretaGame>, HanyaSamping {
  ObjekDunia({required this.wx, required double y, super.priority, super.anchor}) : yDasar = y;

  double wx;
  double yDasar;
  bool ikutDunia = true;

  @override
  void update(double dt) {
    if (ikutDunia) position.setValues(game.trainX + wx - game.jarak, yDasar);
  }
}

/// ObjekDunia berisi satu Gambar.
class GambarDunia extends ObjekDunia {
  GambarDunia(this.nama,
      {required super.wx, required super.y, super.priority, this.skala = kSkala});

  final String nama;
  final double skala;
  late final Gambar gambar;

  @override
  Future<void> onLoad() async {
    gambar = Gambar(nama, skala: skala);
    await add(gambar);
  }
}


/// Melompat berbusur dari titik [dari] ke titik [ke] (koordinat induk). Future selesai saat mendarat.
class Lompat extends Component {
  Lompat(this.c, this.dari, this.ke, {this.detik = 0.75, this.tinggi = 190});

  final PositionComponent c;
  final Vector2 dari;
  final Vector2 ke;
  final double detik;
  final double tinggi;
  final Completer<void> selesai = Completer<void>();
  double _t = 0;

  @override
  void update(double dt) {
    _t = math.min(1, _t + dt / detik);
    final e = Curves.easeInOut.transform(_t);
    c.position = dari + (ke - dari) * e - Vector2(0, math.sin(math.pi * _t) * tinggi);
    if (_t >= 1) {
      c.position = ke.clone();
      if (!selesai.isCompleted) selesai.complete();
      removeFromParent();
    }
  }
}

/// Menjalankan [f] pada tiap frame dengan t = 0..1 selama [detik]. Future [selesai] terpenuhi di akhir.
class Animasi extends Component {
  Animasi(this.detik, this.f);

  final double detik;
  final void Function(double t) f;
  final Completer<void> selesai = Completer<void>();
  double _t = 0;

  @override
  void update(double dt) {
    _t = math.min(detik, _t + dt);
    f(_t / detik);
    if (_t >= detik) {
      if (!selesai.isCompleted) selesai.complete();
      removeFromParent();
    }
  }
}

/// Memanggil [tiap] pada setiap frame sampai dilepas.
class Pengawas extends Component {
  Pengawas(this.tiap);
  final void Function(double dt) tiap;

  @override
  void update(double dt) => tiap(dt);
}
