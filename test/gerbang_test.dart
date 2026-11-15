import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kereta_api/ui/beranda.dart';

void main() {
  Widget bungkus(VoidCallback buka) => MaterialApp(
        home: Scaffold(
          body: Center(child: GerbangOrangTua(ukuran: 100, padaBuka: buka)),
        ),
      );

  testWidgets('gerbang orang tua tidak terbuka bila hanya ditekan sebentar', (tester) async {
    var terbuka = 0;
    await tester.pumpWidget(bungkus(() => terbuka++));
    final g = await tester.startGesture(tester.getCenter(find.byType(Image).first));
    await tester.pump(const Duration(seconds: 1));
    await g.up();
    await tester.pump(const Duration(seconds: 5));
    expect(terbuka, 0);
  });

  testWidgets('gerbang orang tua terbuka setelah ditahan 3 detik', (tester) async {
    var terbuka = 0;
    await tester.pumpWidget(bungkus(() => terbuka++));
    final g = await tester.startGesture(tester.getCenter(find.byType(Image).first));
    await tester.pump(); // frame pertama menandai awal animasi
    await tester.pump(const Duration(milliseconds: 3100));
    await g.up();
    await tester.pump();
    expect(terbuka, 1);
  });
}
