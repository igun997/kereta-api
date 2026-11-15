import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart' show Curves;
import 'dart:math' as math;

import '../../core/audio.dart';
import '../../core/konstanta.dart';
import '../komponen.dart';
import 'misi.dart';

const _buahWarna = {'merah': 'apel', 'kuning': 'pisang', 'biru': 'blueberry'};

/// Misi 2: Warna gerbong. Gerbong menyala, anak memilih buah berwarna sama.
class MisiWarna extends Misi {
  MisiWarna(super.game);

  @override
  List<String> get sprite => [
        'peron_stasiun', 'palang_rel_tutup',
        for (final b in _buahWarna.values) 'buah_$b',
      ];

  @override
  Future<void> jalankan() async {
    game.hud.langkah(0, 3);
    unawaited(bicara('misi2'));
    final tx = game.jarak + 2300;
    await tambah(GambarDunia('peron_stasiun',
        wx: tx + kereta.pusatX, y: kYRel - 28, priority: 9));
    final palang = GambarDunia('palang_rel_tutup',
        wx: tx + kereta.kananLoko + 60, y: kYRel + 8, priority: 15);
    await tambah(palang);

    final tiba = game.menujuBerhenti(tx);
    if (!await tunggu(0.8)) return;
    await bicara('tekan_hijau');
    await tiba;
    if (!game.aktif) return;
    game.rem = false;
    await bicara('stasiun');

    final warna = _buahWarna.keys.toList()..shuffle(acak);
    final kartu = await susunKartu([
      for (final w in warna)
        Kartu(kunci: w, namaSprite: 'buah_${_buahWarna[w]}', diameter: 190, posisi: Vector2.zero()),
    ]);
    final sisa = [...kartu];
    final urutan = [..._buahWarna.keys]..shuffle(acak);
    for (var r = 0; r < 3; r++) {
      final target = urutan[r];
      final idx = kereta.warnaGerbong.indexOf(target);
      final badan = kereta.badanGerbong[idx];
      denyut(badan, besar: 1.04);
      unawaited(bicara(target));
      final k = await tungguKartu(sisa, target, target);
      if (!game.aktif) return;
      hentikanDenyut(badan);
      sisa.remove(k);
      final nama = 'buah_${_buahWarna[target]}';
      final terbang = Gambar(nama, posisi: k.position + Vector2(0, 40), priority: 95);
      await panggung.add(terbang);
      k.hilang();
      Audio.i.sfx('boing');
      await lompat(terbang, terbang.position.clone(), kereta.keDesain(kereta.slotIsi(idx, 1, 3)), tinggi: 260);
      terbang.removeFromParent();
      for (var s = 0; s < 3; s++) {
        final g = Gambar(nama, posisi: kereta.slotIsi(idx, s, 3));
        await kereta.tambahIsi(g);
        muncul(g, detik: 0.35);
      }
      Audio.i.sfx('ding');
      game.hud.langkah(r + 1, 3);
      await panggung.add(Perayaan.meledak(kereta.keDesain(kereta.slotIsi(idx, 1, 3)), jumlah: 20));
      await bicara(_buahWarna[target]!);
    }
    bukaPalang(palang);
    Audio.i.sfx('klak_wesel');
    game.bebaskan();
    await bicara('hebat');
    if (!await tunggu(0.4)) return;
    await game.selesaiMisi();
  }
}

const _warnaBentuk = {
  'bulat': Palet.merah,
  'bintang': Palet.kuning,
  'kotak': Palet.biru,
  'segitiga': Palet.hijau,
};

/// Papan jembatan berlubang bentuk. Satu lubang menyala sebagai target.
class PapanBentuk extends PositionComponent {
  PapanBentuk(this.bentuk, Vector2 pusat)
      : super(position: pusat, size: Vector2(900, 270), anchor: Anchor.center, priority: 60);

  final List<String> bentuk;
  final Set<int> terisi = {};
  int? sorot;
  double _t = 0;

  Vector2 pusatLubang(int i) =>
      position - size / 2 + Vector2(size.x / 2 + (i - 1) * 290, size.y / 2);

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    final papan = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(40));
    canvas.drawRRect(papan.shift(const Offset(0, 10)), Paint()..color = const Color(0x33000000));
    canvas.drawRRect(papan, Paint()..color = const Color(0xFFC98B50));
    final garis = Paint()
      ..color = const Color(0xFFA9713F)
      ..strokeWidth = 6;
    for (var y = 54.0; y < size.y; y += 54) {
      canvas.drawLine(Offset(24, y), Offset(size.x - 24, y), garis);
    }
    canvas.drawRRect(
        papan,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..color = Palet.garis);
    for (var i = 0; i < bentuk.length; i++) {
      final c = Offset(size.x / 2 + (i - 1) * 290, size.y / 2);
      if (sorot == i) {
        final a = 0.5 + 0.5 * math.sin(_t * 7);
        canvas.drawCircle(c, 118, Paint()..color = Palet.kuning.withValues(alpha: 0.35 + 0.35 * a));
      }
      if (terisi.contains(i)) {
        gambarBentuk(canvas, bentuk[i], c, 70, warna: _warnaBentuk[bentuk[i]]!);
      } else {
        gambarBentuk(canvas, bentuk[i], c, 70, warna: const Color(0xFF1B2A49), alpha: 0.9);
      }
    }
  }
}

class _BentukTerbang extends PositionComponent {
  _BentukTerbang(this.bentuk, Vector2 pos)
      : super(position: pos, size: Vector2.all(160), anchor: Anchor.center, priority: 95);
  final String bentuk;
  @override
  void render(Canvas canvas) => gambarBentuk(canvas, bentuk, Offset(size.x / 2, size.y / 2), 66,
      warna: _warnaBentuk[bentuk]!);
}

/// Misi 5: Bentuk di jembatan. Cocokkan bentuk ke lubang papan jembatan.
class MisiBentuk extends Misi {
  MisiBentuk(super.game);

  @override
  List<String> get sprite => ['jembatan_kayu'];

  @override
  Future<void> jalankan() async {
    game.hud.langkah(0, 3);
    unawaited(bicara('misi5'));
    final wxJembatan = game.jarak + 2300;
    final tx = wxJembatan - kereta.pusatX;
    final sj = game.galeri['jembatan_kayu'];
    final dek = sj.titik('dek');
    final yJembatan = kYRel + (dek.isEmpty ? 30 : (sj.pivot.y - dek.first.y) * kSkala);
    await tambah(GambarDunia('jembatan_kayu', wx: wxJembatan, y: yJembatan, priority: 9));
    final tiba = game.menujuBerhenti(tx);
    if (!await tunggu(0.8)) return;
    await bicara('tekan_hijau');
    await tiba;
    if (!game.aktif) return;
    game.rem = false;

    final semua = _warnaBentuk.keys.toList()..shuffle(acak);
    final bentuk = semua.take(3).toList();
    final papan = PapanBentuk(bentuk, Vector2(lebar / 2, 230));
    await panggung.add(papan);
    muncul(papan);
    Audio.i.sfx('pop');
    final kartu = await susunKartu([
      for (final b in bentuk)
        Kartu(kunci: b, bentuk: b, warnaBentuk: _warnaBentuk[b], diameter: 190, posisi: Vector2.zero()),
    ]);
    final sisa = [...kartu];
    final urutan = [...bentuk]..shuffle(acak);
    for (var r = 0; r < 3; r++) {
      final target = urutan[r];
      final lubang = bentuk.indexOf(target);
      papan.sorot = lubang;
      unawaited(bicara(target));
      final k = await tungguKartu(sisa, target, target);
      if (!game.aktif) return;
      sisa.remove(k);
      final terbang = _BentukTerbang(target, k.position.clone());
      await panggung.add(terbang);
      k.hilang();
      Audio.i.sfx('boing');
      await lompat(terbang, terbang.position.clone(), papan.pusatLubang(lubang), detik: 0.7, tinggi: 120);
      terbang.removeFromParent();
      papan.terisi.add(lubang);
      papan.sorot = null;
      Audio.i.sfx('ding');
      game.hud.langkah(r + 1, 3);
      await panggung.add(Perayaan.meledak(papan.pusatLubang(lubang), jumlah: 18));
    }
    await bicara('hebat');
    papan.add(ScaleEffect.to(Vector2.zero(), EffectController(duration: 0.4, curve: Curves.easeIn),
        onComplete: papan.removeFromParent));
    game.bebaskan();
    if (!await tunggu(0.5)) return;
    await game.jalanKe(tx + 1900);
    if (!game.aktif) return;
    await game.selesaiMisi();
  }
}

/// Misi 6: Antar paket. Paket diantar ke rumah yang pintunya sewarna.
class MisiPaket extends Misi {
  MisiPaket(super.game);

  static const _warna = ['merah', 'kuning', 'biru'];

  @override
  List<String> get sprite =>
      [for (final w in _warna) ...['paket_$w', 'rumah_$w']];

  @override
  Future<void> jalankan() async {
    game.hud.langkah(0, 3);
    unawaited(bicara('misi6'));
    final urutanRumah = [..._warna]..shuffle(acak);
    final dasar = game.jarak + 2300;
    final rumah = <String, GambarDunia>{};
    for (var k = 0; k < 3; k++) {
      final w = urutanRumah[k];
      final r = GambarDunia('rumah_$w', wx: dasar + k * 2500, y: kYRel - 62, priority: 9, skala: 1.3);
      await tambah(r);
      rumah[w] = r;
    }
    // Paket di dalam gerbong hijau.
    final isi = <String, Gambar>{};
    final susunan = [..._warna]..shuffle(acak);
    for (var s = 0; s < 3; s++) {
      final g = Gambar('paket_${susunan[s]}', posisi: kereta.slotIsi(0, s, 3));
      await kereta.tambahIsi(g);
      isi[susunan[s]] = g;
    }
    var sisa = <Kartu>[];
    for (var k = 0; k < 3; k++) {
      final w = urutanRumah[k];
      final r = rumah[w]!;
      final tx = r.wx - kereta.pivotGerbong[0].x * kereta.skalaKereta;
      final tiba = game.menujuBerhenti(tx);
      if (k == 0) {
        if (!await tunggu(0.8)) return;
        await bicara('tekan_hijau');
      }
      await tiba;
      if (!game.aktif) return;
      game.rem = false;
      if (k == 0) {
        final baru = [..._warna]..shuffle(acak);
        sisa = await susunKartu([
          for (final x in baru) Kartu(kunci: x, namaSprite: 'paket_$x', diameter: 190, posisi: Vector2.zero()),
        ]);
      }
      denyut(r.gambar, besar: 1.05);
      unawaited(bicara(w));
      final kartu = await tungguKartu(sisa, w, w);
      if (!game.aktif) return;
      hentikanDenyut(r.gambar);
      sisa.remove(kartu);
      kartu.hilang();
      isi[w]?.removeFromParent();
      final pintuRel = game.galeri['rumah_$w'].relatif('pintu');
      final pintu = Vector2(r.position.x, r.position.y) +
          (pintuRel.isEmpty ? Vector2(0, -90) : pintuRel.first * 1.3);
      final paket = Gambar('paket_$w', posisi: kereta.keDesain(kereta.slotIsi(0, 1, 3)), priority: 95);
      await panggung.add(paket);
      Audio.i.sfx('boing');
      await lompat(paket, paket.position.clone(), pintu + Vector2(0, 30), tinggi: 320);
      paket.removeFromParent();
      Audio.i.sfx('ding');
      await panggung.add(Perayaan.meledak(pintu, jumlah: 24));
      game.hud.langkah(k + 1, 3);
      unawaited(bicara('yeay'));
      game.bebaskan();
      if (!await tunggu(0.8)) return;
    }
    await bicara('hebat');
    await game.selesaiMisi();
  }
}
