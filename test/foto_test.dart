import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kereta_api/core/penyimpanan.dart';
import 'package:kereta_api/game/kereta_game.dart';
import 'package:kereta_api/game/komponen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kereta_api/app.dart';
import 'package:kereta_api/ui/beranda.dart';
import 'package:kereta_api/ui/pilih.dart';
import 'package:kereta_api/ui/stiker.dart';
import 'e2e_game_test.dart' show bermainSampaiHadiah, cari, maju, titik;

/// Pengambil gambar (opt-in): buat berkas `test/foto_aktif.txt`, lalu `rflutter test test/foto_test.dart`.
/// Menyimpan bingkai game ke build/foto/*.png untuk ditinjau mata (bukan uji otomatis).
final bool _aktif = File('test/foto_aktif.txt').existsSync();

Future<void> foto(WidgetTester t, GlobalKey key, String nama) async {
  await t.runAsync(() async {
    final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await b.toImage();
    final d = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/foto/$nama.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(d!.buffer.asUint8List());
  });
}

Future<(KeretaGame, GlobalKey)> buka(WidgetTester t, int misi) async {
  t.view.physicalSize = const Size(1600, 720);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  SharedPreferences.setMockInitialValues({});
  await Penyimpanan.muat();
  final key = GlobalKey();
  final game = KeretaGame(dunia: 0, misiNo: misi, padaSelesai: (_) {}, padaKeluar: () {});
  await t.pumpWidget(MaterialApp(home: RepaintBoundary(key: key, child: GameWidget<KeretaGame>(game: game))));
  for (var i = 0; i < 600; i++) {
    try {
      if (game.isLoaded && game.hud.isLoaded && game.kereta!.isLoaded) break;
    } catch (_) {}
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 16));
  }
  await maju(t, 0.5);
  return (game, key);
}

void main() {
  testWidgets('foto: samping jalan', (t) async {
    final (g, k) = await buka(t, -1);
    final gas = await t.startGesture(titik(g.hud.tombolGas));
    await maju(t, 2.5);
    await foto(t, k, 'samping_jalan');
    await gas.up();
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 15));
  }, skip: !_aktif);

  testWidgets('foto: orang ketiga jalan cepat', (t) async {
    final (g, k) = await buka(t, -1);
    final kamera = g.hud.children.whereType<TombolBulat>().firstWhere((b) => b.ikon == 'tombol_kamera');
    await t.tapAt(titik(kamera));
    await maju(t, 1.4);
    final gas = await t.startGesture(titik(g.hud.tombolGas));
    await maju(t, 4.0);
    await foto(t, k, 'belakang_cepat');
    await t.tapAt(titik(g.hud.tombolPeluit));
    await maju(t, 0.15);
    await foto(t, k, 'belakang_peluit');
    await gas.up();
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 15));
  }, skip: !_aktif);

  testWidgets('foto: misi 3 hewan di rel', (t) async {
    final (g, k) = await buka(t, 2);
    final gas = await t.startGesture(titik(g.hud.tombolGas));
    var n = 0;
    for (var i = 0; i < 200; i++) {
      await maju(t, 0.3);
      if (i == 8) await foto(t, k, 'm3_jauh');
      if (g.menungguPeluitAktif && g.kecepatan < 1) {
        await foto(t, k, 'm3_berhenti');
        await t.tapAt(titik(g.hud.tombolPeluit));
        await maju(t, 0.45);
        await foto(t, k, 'm3_melompat');
        break;
      }
      n++;
    }
    await gas.up();
    expect(n, lessThan(199));
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 15));
  }, skip: !_aktif);

  testWidgets('foto: misi 4 terowongan', (t) async {
    final (g, k) = await buka(t, 3);
    final gas = await t.startGesture(titik(g.hud.tombolGas));
    var dekat = false;
    var dalam = false;
    for (var i = 0; i < 300 && !dalam; i++) {
      await maju(t, 0.2);
      if (!dekat && g.jarak > 1900) {
        dekat = true;
        await foto(t, k, 'm4_dekat');
      }
      if (g.belakang.dalamTerowongan && g.kecepatan < 1) {
        dalam = true;
        await maju(t, 1.5);
        await foto(t, k, 'm4_dalam');
        await t.tapAt(titik(cari<TombolBulat>(g).firstWhere((b) => b.ikon == 'lampu_mati')));
        await maju(t, 1.0);
        await foto(t, k, 'm4_lampu');
      }
    }
    await gas.up();
    expect(dalam, isTrue);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 15));
  }, skip: !_aktif);

  testWidgets('foto: misi 1 stasiun', (t) async {
    final (g, k) = await buka(t, 0);
    final gas = await t.startGesture(titik(g.hud.tombolGas));
    for (var i = 0; i < 200; i++) {
      await maju(t, 0.3);
      if (g.hud.bintangSelesai >= 1) break;
      if (g.kecepatan < 1 && g.fisika.diZona) await foto(t, k, 'm1_tiba');
    }
    await maju(t, 0.3);
    await foto(t, k, 'm1_naik');
    await gas.up();
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 15));
  }, skip: !_aktif);

  testWidgets('foto: layar menu dan buku stiker', (t) async {
    t.view.physicalSize = const Size(1600, 720);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    final p = await Penyimpanan.muat();
    for (final n in [1, 2, 3, 7, 8, 9, 10]) {
      await p.tambahStiker(n);
    }
    final key = GlobalKey();
    await t.pumpWidget(RepaintBoundary(key: key, child: bungkusApp(const Beranda())));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await maju(t, 0.8);
    await foto(t, key, 'menu_beranda');
    await t.tap(find.bySemanticsLabel('Mulai bermain'), warnIfMissed: false);
    await t.pumpWidget(RepaintBoundary(key: key, child: KeyedSubtree(key: UniqueKey(), child: bungkusApp(const PilihDunia()))));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await maju(t, 0.8);
    await foto(t, key, 'menu_dunia');
    await t.pumpWidget(RepaintBoundary(key: key, child: KeyedSubtree(key: UniqueKey(), child: bungkusApp(const PilihMisi(dunia: 0)))));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await maju(t, 0.8);
    await foto(t, key, 'menu_misi');
    await t.pumpWidget(RepaintBoundary(key: key, child: KeyedSubtree(key: UniqueKey(), child: bungkusApp(const BukuStiker()))));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await maju(t, 0.8);
    await foto(t, key, 'menu_stiker');
  }, skip: !_aktif);

  testWidgets('foto: layar hadiah', (t) async {
    final (g, k) = await buka(t, 0);
    await bermainSampaiHadiah(t, g);
    await maju(t, 1.6);
    await foto(t, k, 'hadiah');
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 15));
  }, skip: !_aktif);
}
