import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart' show Curves;

import '../../core/audio.dart';
import '../../core/konstanta.dart';
import '../kereta.dart';
import '../kereta_game.dart';
import '../komponen.dart';
import 'misi_a.dart';
import 'misi_b.dart';
import 'misi_c.dart';

/// Dasar semua misi. Alur misi ditulis berurutan dengan async/await dan
/// selalu memeriksa [KeretaGame.aktif] setelah menunggu.
abstract class Misi {
  Misi(this.game);

  final KeretaGame game;
  final math.Random acak = math.Random();

  /// Nama sprite tambahan yang dibutuhkan misi.
  List<String> get sprite;

  /// Seluruh jalannya misi, sampai [KeretaGame.selesaiMisi].
  Future<void> jalankan();

  Kereta get kereta => game.kereta!;
  PositionComponent get panggung => game.panggung;
  double get lebar => game.ruang.x;

  Future<bool> tunggu(double detik) => game.tunggu(detik);
  Future<void> bicara(String nama) => Audio.i.bicara(nama);

  Future<T> tambah<T extends Component>(T c) async {
    await game.panggung.add(c);
    return c;
  }

  /// Palang naik dan menghilang dengan lembut (tanpa sprite "terbuka").
  void bukaPalang(GambarDunia p) {
    p.gambar.add(MoveByEffect(
      Vector2(0, -70),
      EffectController(duration: 0.6, curve: Curves.easeOut),
    ));
    p.gambar.add(OpacityEffect.fadeOut(
      EffectController(duration: 0.6),
      onComplete: p.removeFromParent,
    ));
  }

  /// Hewan/benda bergoyang naik-turun pelan agar terlihat hidup.
  void hidupkan(PositionComponent c, {double tinggi = 10}) {
    c.add(MoveByEffect(
      Vector2(0, -tinggi),
      EffectController(
        duration: 0.45 + acak.nextDouble() * 0.2,
        reverseDuration: 0.45,
        infinite: true,
        startDelay: acak.nextDouble() * 0.5,
      ),
    ));
  }

  /// Animasi berdurasi [detik] dengan t = 0..1 pada tiap frame.
  Future<void> animasi(double detik, void Function(double t) f) async {
    final a = Animasi(detik, f);
    await game.panggung.add(a);
    await a.selesai.future;
  }

  Future<void> lompat(PositionComponent c, Vector2 dari, Vector2 ke,
      {double detik = 0.75, double tinggi = 190}) async {
    final l = Lompat(c, dari, ke, detik: detik, tinggi: tinggi);
    await game.panggung.add(l);
    await l.selesai.future;
  }

  /// Susun kartu pilihan di bawah tengah layar (di antara tombol kiri dan kanan).
  Future<List<Kartu>> susunKartu(List<Kartu> kartu) async {
    for (var i = 0; i < kartu.length; i++) {
      final k = kartu[i];
      k.position = Vector2(lebar / 2 + (i - (kartu.length - 1) / 2) * 220, kTinggi - 130);
      await game.panggung.add(k);
      muncul(k);
      Audio.i.sfx('pop');
      if (!await tunggu(0.18)) break;
    }
    return kartu;
  }

  /// Menunggu anak memilih kartu [benar]. Pilihan salah digoyang dengan ramah.
  /// Petunjuk suara diulang tiap 11 detik bila anak diam.
  Future<Kartu> tungguKartu(List<Kartu> kartu, String benar, String ulangSuara) async {
    final selesai = Completer<Kartu>();
    var terakhirSalah = DateTime.fromMillisecondsSinceEpoch(0);
    for (final k in kartu) {
      k.padaPilih = (pilih) {
        if (selesai.isCompleted) return;
        if (pilih.kunci == benar) {
          selesai.complete(pilih);
        } else {
          goyang(pilih);
          Audio.i.sfx('salah');
          final sekarang = DateTime.now();
          if (sekarang.difference(terakhirSalah).inSeconds >= 5) {
            terakhirSalah = sekarang;
            unawaited(Audio.i.bicara('coba_lagi'));
          }
        }
      };
    }
    unawaited(() async {
      while (!selesai.isCompleted && game.aktif) {
        if (!await tunggu(11)) return;
        if (!selesai.isCompleted) await bicara(ulangSuara);
      }
    }());
    return selesai.future;
  }
}

Misi? buatMisi(int no, KeretaGame g) => switch (no) {
      0 => MisiJemput(g),
      1 => MisiWarna(g),
      2 => MisiPeluit(g),
      3 => MisiTerowongan(g),
      4 => MisiBentuk(g),
      5 => MisiPaket(g),
      _ => null,
    };
