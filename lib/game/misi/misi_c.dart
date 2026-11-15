import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../../core/audio.dart';
import '../../core/konstanta.dart';
import '../komponen.dart';
import '../perspektif.dart';
import 'misi.dart';

/// Lapisan gelap di dalam terowongan. Alfa bergerak halus menuju target.
class Gelap extends PositionComponent {
  Gelap() : super(priority: 40);
  double alfa = 0;
  double target = 0;

  @override
  void update(double dt) {
    alfa += (target - alfa) * math.min(1, dt * 3);
  }

  @override
  void render(Canvas canvas) {
    if (alfa < 0.01) return;
    canvas.drawRect(
      Rect.fromLTWH(-100, -100, 4200, kTinggi + 200),
      Paint()..color = const Color(0xFF050A18).withValues(alpha: alfa),
    );
  }
}

/// Kunang-kunang bercahaya yang melayang; ketuk untuk menangkapnya.
class Kunang extends PositionComponent with TapCallbacks {
  Kunang(Vector2 pusat, this.padaTangkap, this.fase)
      : _pusat = pusat,
        super(position: pusat, size: Vector2.all(190), anchor: Anchor.center, priority: 70);

  final Vector2 _pusat;
  final void Function(Kunang) padaTangkap;
  final double fase;
  double _t = 0;
  bool _kena = false;

  @override
  void update(double dt) {
    _t += dt;
    position = _pusat + Vector2(math.sin(_t * 0.9 + fase) * 70, math.cos(_t * 1.3 + fase) * 40);
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    final kilau = 0.7 + 0.3 * math.sin(_t * 5 + fase);
    canvas.drawCircle(
      c,
      86,
      Paint()
        ..shader = Gradient.radial(c, 86, [
          Palet.kuning.withValues(alpha: 0.75 * kilau),
          Palet.kuning.withValues(alpha: 0),
        ]),
    );
    canvas.drawCircle(c, 26, Paint()..color = Palet.kuning);
    canvas.drawCircle(
        c,
        26,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = Palet.garis);
    canvas.drawCircle(c.translate(-7, -8), 8, Paint()..color = const Color(0xFFFFFFFF));
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_kena) return;
    _kena = true;
    padaTangkap(this);
  }
}

/// Misi 4: Terowongan gelap (kamera orang ketiga). Kereta masuk terowongan, anak menyalakan
/// lampu dan menangkap kunang-kunang, lalu kereta melaju ke cahaya di ujung terowongan.
class MisiTerowongan extends Misi {
  MisiTerowongan(super.game);

  @override
  List<String> get sprite => ['terowongan_belakang'];

  @override
  Future<void> jalankan() async {
    game.hud.langkah(0, 2);
    final dunia3 = game.belakang;
    final wxT = game.jarak + 2900;
    final terowongan = ItemP('terowongan_belakang', wx: wxT, skala: 1.0);
    dunia3.item.add(terowongan);
    final gelap = Gelap();
    await panggung.add(gelap);

    // Berhenti saat seluruh kereta sudah di dalam: bidang mulut terowongan 2 unit di belakang kamera.
    final tx = wxT - kereta.kananLoko + (2.0 + dunia3.zHidung) / kMeterPerPx;
    var masuk = false;
    final pengawas = Pengawas((dt) {
      if (masuk) return;
      final z = dunia3.zUntuk(wxT);
      if (z < 0.6) {
        masuk = true;
        dunia3.dalamTerowongan = true;
        terowongan.tampil = false;
        dunia3.getar();
        Audio.i.sfx('rem', volume: 0.6);
      } else {
        // Makin dekat mulut terowongan, makin redup.
        gelap.target = ((9 - z) / 9).clamp(0.0, 1.0) * 0.55;
      }
    });
    await panggung.add(pengawas);

    final tiba = game.menujuBerhenti(tx);
    if (!await tunggu(0.8)) return;
    await bicara('tekan_hijau');
    await tiba;
    if (!game.aktif) return;
    game.rem = false;
    pengawas.removeFromParent();

    gelap.target = 0.88;
    if (!await tunggu(0.9)) return;
    unawaited(bicara('misi4'));

    final tekan = Completer<void>();
    final lampu = TombolBulat('lampu_mati',
        posisi: Vector2(lebar / 2, 330),
        diameter: 300,
        priority: 80,
        suaraTekan: null,
        padaTekan: () {
          if (!tekan.isCompleted) tekan.complete();
        });
    await panggung.add(lampu);
    muncul(lampu);
    lampu.sorot(true);
    await tekan.future;
    if (!game.aktif) return;
    lampu.sorot(false);
    await lampu.gantiIkon('lampu_nyala');
    Audio.i.sfx('lampu');
    gelap.target = 0.5;
    game.hud.langkah(1, 2);

    // Tiga kunang-kunang.
    final semua = Completer<void>();
    var tertangkap = 0;
    for (var i = 0; i < 3; i++) {
      final pusat = Vector2(lebar * (0.28 + 0.22 * i), 520 + (i == 1 ? 90 : 0));
      final k = Kunang(pusat, (kn) {
        Audio.i.sfx('kunang');
        panggung.add(Perayaan.meledak(kn.position, jumlah: 14));
        kn.removeFromParent();
        tertangkap++;
        if (tertangkap == 3 && !semua.isCompleted) semua.complete();
      }, i * 1.7);
      await panggung.add(k);
      muncul(k, detik: 0.5);
    }
    await semua.future;
    if (!game.aktif) return;
    lampu.removeFromParent();
    Audio.i.sfx('ding');
    game.hud.langkah(2, 2);
    unawaited(bicara('hebat'));
    game.bebaskan();
    if (!await tunggu(0.8)) return;

    // Melaju ke cahaya di ujung terowongan; cahaya membesar sampai menutup layar.
    gelap.target = 0.35;
    final awal = game.jarak;
    final keluar = awal + 2600;
    final cahaya = Pengawas((dt) {
      dunia3.cahayaUjung = ((game.jarak - awal) / (keluar - awal)).clamp(0.0, 1.2);
    });
    await panggung.add(cahaya);
    await game.jalanKe(keluar);
    if (!game.aktif) return;
    cahaya.removeFromParent();

    // Keluar ke cahaya terang: dunia kembali.
    dunia3.dalamTerowongan = false;
    dunia3.cahayaUjung = 0;
    gelap.target = 0;
    dunia3.getar();
    await panggung.add(Perayaan.hujan(lebar, detik: 1.5));
    if (!await tunggu(1.0)) return;
    await game.selesaiMisi();
  }
}
