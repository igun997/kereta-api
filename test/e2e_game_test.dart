import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kereta_api/app.dart';
import 'package:kereta_api/core/penyimpanan.dart';
import 'package:kereta_api/game/kereta_game.dart';
import 'package:kereta_api/game/komponen.dart';
import 'package:kereta_api/game/misi/misi_c.dart';
import 'package:kereta_api/ui/beranda.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uji end-to-end: game sungguhan (aset asli, hit-test asli), disentuh seperti jari anak.
/// Layar uji 1600x720 (seperti Samsung A22 landscape).

class Sesi {
  bool keluar = false;
  bool? lanjut;
}

bool _siap(KeretaGame g) {
  try {
    return g.isLoaded && g.hud.isLoaded && g.kereta != null && g.kereta!.isLoaded;
  } catch (_) {
    return false;
  }
}

Future<void> maju(WidgetTester t, double detik) async {
  final n = (detik / 0.05).ceil();
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 50));
    // Decode gambar butuh waktu nyata (bukan jam palsu): beri irisan kecil tiap beberapa frame.
    if (i % 4 == 3) await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 12)));
  }
}

Future<KeretaGame> mulai(WidgetTester t, Sesi s, {int dunia = 0, required int misi}) async {
  t.view.physicalSize = const Size(1600, 720);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  SharedPreferences.setMockInitialValues({});
  await Penyimpanan.muat();
  final game = KeretaGame(
    dunia: dunia,
    misiNo: misi,
    padaSelesai: (l) => s.lanjut = l,
    padaKeluar: () => s.keluar = true,
  );
  await t.pumpWidget(MaterialApp(home: GameWidget<KeretaGame>(game: game)));
  for (var i = 0; i < 600 && !_siap(game); i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 16));
  }
  expect(_siap(game), isTrue, reason: 'game gagal dimuat (aset/manifest)');
  await maju(t, 0.3);
  return game;
}

Offset titik(PositionComponent c) => c.absoluteCenter.toOffset();

List<T> cari<T extends Component>(KeretaGame g) => g.panggung.children.whereType<T>().toList();

/// "Anak" bermain sampai hadiah muncul: menahan GAS, membunyikan peluit, memilih kartu,
/// menyalakan lampu, menangkap kunang-kunang. Pilihan salah tidak merugikan, jadi aman dicoba urut.
Future<void> bermainSampaiHadiah(WidgetTester t, KeretaGame g, {double maksDetik = 400}) async {
  TestGesture? gas;
  var kartuKe = 0;
  final langkah = (maksDetik / 0.3).ceil();
  for (var i = 0; i < langkah; i++) {
    if (cari<Hadiah>(g).isNotEmpty) break;
    final kartu = cari<Kartu>(g);
    final lampu = cari<TombolBulat>(g).where((b) => b.ikon == 'lampu_mati').toList();
    final kunang = cari<Kunang>(g);
    if (kartu.isNotEmpty) {
      await gas?.up();
      gas = null;
      await t.tapAt(titik(kartu[kartuKe++ % kartu.length]));
    } else if (lampu.isNotEmpty) {
      await gas?.up();
      gas = null;
      await t.tapAt(titik(lampu.first));
    } else if (kunang.isNotEmpty) {
      await t.tapAt(titik(kunang.first));
    } else if (g.menungguPeluitAktif && g.kecepatan < 1) {
      await gas?.up();
      gas = null;
      await t.tapAt(titik(g.hud.tombolPeluit));
    } else {
      gas ??= await t.startGesture(titik(g.hud.tombolGas));
    }
    await maju(t, 0.3);
  }
  await gas?.up();
  expect(cari<Hadiah>(g), isNotEmpty,
      reason: 'hadiah tidak muncul: misi macet. v=${g.kecepatan.toStringAsFixed(1)} '
          'jarak=${g.jarak.toStringAsFixed(0)} bintang=${g.hud.bintangSelesai}/${g.hud.bintangTotal} '
          'diZona=${g.fisika.diZona} tujuan=${g.fisika.tujuan} menungguPeluit=${g.menungguPeluitAktif} '
          'anak=${g.panggung.children.map((c) => c.runtimeType).toSet()}');
}

Future<void> selesaikan(WidgetTester t, int misi, {int dunia = 0}) async {
  final s = Sesi();
  final g = await mulai(t, s, dunia: dunia, misi: misi);
  await bermainSampaiHadiah(t, g);
  final stiker = nomorStiker(dunia, misi);
  expect(Penyimpanan.i.punyaStiker(stiker), isTrue, reason: 'stiker $stiker harus tersimpan');
  expect(g.hud.bintangSelesai, g.hud.bintangTotal);
  // Tombol LANJUT pada layar hadiah bekerja.
  await maju(t, 1.5);
  final lanjut = cari<Hadiah>(g).first.children.whereType<TombolBulat>().firstWhere((b) => b.ikon == 'tombol_lanjut');
  await t.tapAt(titik(lanjut));
  await maju(t, 0.2);
  expect(s.lanjut, isTrue);
  await bersihkan(t);
}

/// Membuang game dan menghabiskan timer petunjuk (jeda 11 dtk) supaya tes tidak meninggalkan timer.
Future<void> bersihkan(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
}

void main() {
  group('tombol beranda dan kendali dasar', () {
    testWidgets('ketuk beranda membuka konfirmasi; PULANG keluar dari game', (t) async {
      final s = Sesi();
      final g = await mulai(t, s, misi: -1);
      await t.tapAt(titik(g.hud.tombolBeranda));
      await maju(t, 0.4);
      expect(cari<KonfirmasiKeluar>(g), isNotEmpty, reason: 'ketukan biasa harus membuka konfirmasi');
      expect(s.keluar, isFalse);
      final pulang = cari<KonfirmasiKeluar>(g).first.children.whereType<TombolBulat>().firstWhere((b) => b.ikon == 'tombol_beranda');
      await t.tapAt(titik(pulang));
      await maju(t, 0.2);
      expect(s.keluar, isTrue);
    });

    testWidgets('LANJUT MAIN menutup konfirmasi dan GAS tetap bekerja (tidak macet)', (t) async {
      final s = Sesi();
      final g = await mulai(t, s, misi: -1);
      await t.tapAt(titik(g.hud.tombolBeranda));
      await maju(t, 0.4);
      // Selama konfirmasi terbuka, tombol di belakangnya tidak ikut tertekan.
      final tahan = await t.startGesture(titik(g.hud.tombolGas));
      await maju(t, 0.6);
      await tahan.up();
      expect(g.jarak, 0, reason: 'tirai konfirmasi harus menyerap sentuhan');
      final lanjut = cari<KonfirmasiKeluar>(g).first.children.whereType<TombolBulat>().firstWhere((b) => b.ikon == 'tombol_mulai');
      await t.tapAt(titik(lanjut));
      await maju(t, 0.3);
      expect(cari<KonfirmasiKeluar>(g), isEmpty);
      expect(s.keluar, isFalse);
      final gas = await t.startGesture(titik(g.hud.tombolGas));
      await maju(t, 2.0);
      expect(g.kecepatan, greaterThan(100));
      await gas.up();
    });

    testWidgets('GAS menjalankan, REM menghentikan, PELUIT membunyikan', (t) async {
      final s = Sesi();
      final g = await mulai(t, s, misi: -1);
      final gas = await t.startGesture(titik(g.hud.tombolGas));
      await maju(t, 3);
      expect(g.kecepatan, greaterThan(200));
      expect(g.jarak, greaterThan(300));
      await gas.up();
      final rem = await t.startGesture(titik(g.hud.tombolRem));
      await maju(t, 1.5);
      expect(g.kecepatan, 0);
      await rem.up();
      final jarakBerhenti = g.jarak;
      await t.tapAt(titik(g.hud.tombolPeluit));
      await maju(t, 0.5);
      expect(g.jarak, jarakBerhenti, reason: 'peluit tidak menggerakkan kereta');
      expect(tester(t), isNull);
    });

    testWidgets('jalan-jalan bebas: tombol kamera berganti samping dan orang ketiga', (t) async {
      final s = Sesi();
      final g = await mulai(t, s, misi: -1);
      expect(g.kamera, Kamera.samping);
      final kamera = g.hud.children.whereType<TombolBulat>().firstWhere((b) => b.ikon == 'tombol_kamera');
      await t.tapAt(titik(kamera));
      await maju(t, 1.3);
      expect(g.kamera, Kamera.belakang);
      // Berjalan di kamera orang ketiga tidak menimbulkan galat.
      final gas = await t.startGesture(titik(g.hud.tombolGas));
      await maju(t, 3);
      expect(g.kecepatan, greaterThan(200));
      await gas.up();
      await t.tapAt(titik(g.hud.tombolPeluit));
      await maju(t, 0.5);
      await t.tapAt(titik(kamera));
      await maju(t, 1.3);
      expect(g.kamera, Kamera.samping);
      expect(tester(t), isNull);
    });
  });

  group('misi dimainkan sampai tamat (sentuhan asli)', () {
    testWidgets('misi 1 Jemput teman', (t) => selesaikan(t, 0));
    testWidgets('misi 2 Warna gerbong', (t) => selesaikan(t, 1));
    testWidgets('misi 3 Bunyikan peluit (kamera orang ketiga)', (t) async {
      final s = Sesi();
      final g = await mulai(t, s, misi: 2);
      expect(g.kamera, Kamera.belakang, reason: 'misi 3 memakai kamera orang ketiga');
      await bermainSampaiHadiah(t, g);
      expect(Penyimpanan.i.punyaStiker(nomorStiker(0, 2)), isTrue);
    });
    testWidgets('misi 4 Terowongan gelap (kamera orang ketiga)', (t) async {
      final s = Sesi();
      final g = await mulai(t, s, misi: 3);
      expect(g.kamera, Kamera.belakang);
      await bermainSampaiHadiah(t, g);
      expect(Penyimpanan.i.punyaStiker(nomorStiker(0, 3)), isTrue);
      expect(g.belakang.dalamTerowongan, isFalse, reason: 'kereta sudah keluar dari terowongan');
    });
    testWidgets('misi 5 Bentuk di jembatan', (t) => selesaikan(t, 4));
    testWidgets('misi 6 Antar paket', (t) => selesaikan(t, 5));
    testWidgets('dunia Kota Kecil: misi 1 juga tamat', (t) => selesaikan(t, 0, dunia: 1));
  });

  group('alur menu sampai game dan kembali', () {
    testWidgets('splash, beranda, dunia, misi, game, konfirmasi pulang, kembali', (t) async {
      t.view.physicalSize = const Size(1600, 720);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      SharedPreferences.setMockInitialValues({});
      await Penyimpanan.muat();
      final sem = t.ensureSemantics();
      await t.pumpWidget(bungkusApp(const Beranda()));
      await maju(t, 0.5);
      expect(find.bySemanticsLabel('Mulai bermain'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Mulai bermain'));
      await maju(t, 0.6);
      expect(find.text('Desa Sawah'), findsOneWidget);
      expect(find.text('Kota Kecil'), findsOneWidget);
      await t.tap(find.text('Desa Sawah'));
      await maju(t, 0.6);
      expect(find.bySemanticsLabel('Jemput teman'), findsOneWidget);
      expect(find.bySemanticsLabel('Bentuk di jembatan'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Jalan-jalan bebas'));
      for (var i = 0; i < 600 && find.byType(GameWidget<KeretaGame>).evaluate().isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 30));
      }
      final game = (t.widget(find.byType(GameWidget<KeretaGame>)) as GameWidget<KeretaGame>).game!;
      for (var i = 0; i < 600 && !_siap(game); i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(_siap(game), isTrue);
      await maju(t, 0.3);
      await t.tapAt(titik(game.hud.tombolBeranda));
      await maju(t, 0.4);
      final pulang = cari<KonfirmasiKeluar>(game).first.children.whereType<TombolBulat>().firstWhere((b) => b.ikon == 'tombol_beranda');
      await t.tapAt(titik(pulang));
      await maju(t, 0.8);
      expect(find.byType(GameWidget<KeretaGame>), findsNothing);
      expect(find.bySemanticsLabel('Jemput teman'), findsOneWidget, reason: 'kembali ke pilihan misi');
      await t.tap(find.bySemanticsLabel('Kembali'));
      await maju(t, 0.6);
      expect(find.text('Desa Sawah'), findsOneWidget);
      sem.dispose();
    });
  });
}

/// Pengecualian yang tertangkap framework selama uji (null bila bersih).
Object? tester(WidgetTester t) => t.takeException();
