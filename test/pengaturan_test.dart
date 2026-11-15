import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kereta_api/app.dart';
import 'package:kereta_api/core/penyimpanan.dart';
import 'package:kereta_api/ui/pengaturan.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pengaturan dibuka dengan konfigurasi aplikasi asli. Dulu gagal dengan
/// "No MaterialLocalizations found" karena locale id tanpa delegasi lokalisasi.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Penyimpanan.muat();
  });

  testWidgets('pengaturan tampil tanpa error lokalisasi', (tester) async {
    await tester.pumpWidget(bungkusApp(const Pengaturan()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Pengaturan orang tua'), findsOneWidget);
    expect(find.text('Mode otomatis'), findsOneWidget);
    expect(Localizations.localeOf(tester.element(find.byType(Pengaturan))), const Locale('id'));
  });

  testWidgets('semua kontrol pengaturan bekerja dan dialog terbuka', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(bungkusApp(const Pengaturan()));
    await tester.pumpAndSettle();

    // Saklar mode otomatis menyimpan nilai.
    expect(Penyimpanan.i.otomatis, isFalse);
    await tester.tap(find.text('Mode otomatis'));
    await tester.pumpAndSettle();
    expect(Penyimpanan.i.otomatis, isTrue);

    // Suara pemandu dimatikan.
    await tester.tap(find.text('Suara pemandu (bahasa Indonesia)'));
    await tester.pumpAndSettle();
    expect(Penyimpanan.i.suaraPemandu, isFalse);

    // Slider volume bisa digeser.
    await tester.drag(find.byType(Slider).first, const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(Penyimpanan.i.volumeUtama, lessThan(1.0));

    // Dialog kebijakan privasi (butuh MaterialLocalizations) terbuka dan tertutup.
    await tester.tap(find.text('Kebijakan privasi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('tidak mengumpulkan'), findsWidgets);
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();

    // Hapus stiker dengan konfirmasi.
    await Penyimpanan.i.tambahStiker(2);
    await tester.pump();
    await tester.tap(find.text('Hapus semua stiker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(Penyimpanan.i.stiker, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
