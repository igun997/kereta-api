import '../perspektif.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/animation.dart' show Curves;


import '../../core/audio.dart';
import '../../core/konstanta.dart';
import '../komponen.dart';
import 'misi.dart';

const _namaHewan = ['ayam', 'kucing', 'bebek', 'kelinci', 'monyet'];
const _angka = ['satu', 'dua', 'tiga'];

/// Misi 1: Jemput teman. Berhenti di peron, hewan naik satu per satu sambil dihitung 1-2-3.
class MisiJemput extends Misi {
  MisiJemput(super.game);

  @override
  List<String> get sprite => [
        'peron_stasiun', 'palang_rel_tutup',
        for (final h in _namaHewan) 'hewan_$h',
      ];

  @override
  Future<void> jalankan() async {
    game.hud.langkah(0, 2);
    unawaited(bicara('misi1'));
    final jumlahPerStasiun = [1 + acak.nextInt(2), 3];
    var tx = game.jarak + 2300;
    for (var babak = 0; babak < 2; babak++) {
      final jumlah = jumlahPerStasiun[babak];
      // Peron berpusat di gerbong pertama; palang di depan hidung lokomotif.
      final pusatPeron = tx + kereta.pivotGerbong[0].x * kereta.skalaKereta;
      final peron = await tambah(GambarDunia('peron_stasiun', wx: pusatPeron, y: kYRel - 28, priority: 9));
      final palang = GambarDunia('palang_rel_tutup',
          wx: tx + kereta.kananLoko + 60, y: kYRel + 8, priority: 15);
      await tambah(palang);

      final daftar = <GambarDunia>[];
      final pilihan = [..._namaHewan]..shuffle(acak);
      for (var i = 0; i < jumlah; i++) {
        final h = GambarDunia('hewan_${pilihan[i]}',
            wx: pusatPeron - 110 + i * 110.0, y: kYRel - 68, priority: 12, skala: 1.05);
        await tambah(h);
        hidupkan(h, tinggi: 8);
        daftar.add(h);
      }

      final tiba = game.menujuBerhenti(tx);
      if (!await tunggu(0.8)) return;
      if (babak == 0) await bicara('tekan_hijau');
      await tiba;
      if (!game.aktif) return;
      game.rem = false;
      await bicara('stasiun');
      if (!await tunggu(0.3)) return;

      // Naik satu per satu sambil berhitung.
      for (var i = 0; i < daftar.length; i++) {
        final h = daftar[i];
        h.ikutDunia = false;
        final slot = kereta.slotIsi(0, i, 3);
        final target = kereta.keDesain(slot);
        Audio.i.sfx('boing');
        await lompat(h, h.position.clone(), target, tinggi: 200);
        final nama = _namaHewan.firstWhere((n) => h.nama == 'hewan_$n');
        h.removeFromParent();
        final g = Gambar('hewan_$nama', posisi: slot, skala: 1.0);
        await kereta.tambahIsi(g);
        hidupkan(g, tinggi: 6);
        await bicara(_angka[i]);
      }
      Audio.i.sfx('ding');
      game.hud.langkah(babak + 1, 2);
      await panggung.add(Perayaan.meledak(kereta.keDesain(kereta.slotIsi(0, 1, 3)), jumlah: 22));

      // Palang membuka, lanjut jalan.
      bukaPalang(palang);
      Audio.i.sfx('klak_wesel');
      game.bebaskan();
      peron.priority = 9;
      if (babak == 0) {
        await bicara('ayo_jalan');
        tx = game.jarak + 2600;
      }
    }
    if (!await tunggu(0.6)) return;
    await game.selesaiMisi();
  }
}

/// Misi 3: Bunyikan peluit. Kamera orang ketiga: hewan di rel di depan kereta minggir saat peluit.
class MisiPeluit extends Misi {
  MisiPeluit(super.game);

  static const _urutan = ['kerbau', 'ayam', 'kucing'];

  @override
  List<String> get sprite => [for (final h in _urutan) 'hewan_${h}_depan'];

  @override
  Future<void> jalankan() async {
    game.hud.langkah(0, 3);
    unawaited(bicara('misi3'));
    var basis = game.jarak + 2100;
    for (var i = 0; i < _urutan.length; i++) {
      final nama = _urutan[i];
      final hewan = ItemP('hewan_${nama}_depan', wx: basis, skala: nama == 'kerbau' ? 5.0 : 5.8);
      game.belakang.item.add(hewan);
      // Berhenti jauh di depan hewan: kamera belakang tidak bisa melihat menembus kereta,
      // jadi hewan harus muncul di atas lokomotif dan tetap jelas.
      final tiba = game.menujuBerhenti(basis - kereta.kananLoko - 520);
      await tiba;
      if (!game.aktif) return;
      game.rem = false;
      game.belakang.getar();
      if (i > 0) await bicara('tekan_kuning');
      await game.menungguPeluit();
      if (!game.aktif) return;

      // Hewan melompat ke rumput di samping rel dan diam di sana.
      final arah = i.isEven ? 1.0 : -1.0;
      Audio.i.sfx('boing');
      await animasi(0.9, (t) {
        hewan.lateral = arah * 8.0 * Curves.easeOut.transform(t);
        hewan.tinggi = math.sin(math.pi * t) * 2.4;
      });
      await bicara(nama);
      game.hud.langkah(i + 1, 3);
      Audio.i.sfx('ding');
      game.bebaskan();
      basis = game.jarak + 2200;
      if (i < _urutan.length - 1) await bicara('hebat');
    }
    if (!await tunggu(0.5)) return;
    await game.selesaiMisi();
  }
}
