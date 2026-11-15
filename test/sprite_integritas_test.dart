import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// Setiap PNG sprite harus benar-benar bisa di-decode dan berukuran sama dengan manifest.
/// Header PNG saja tidak cukup: transfer yang terpotong menghasilkan berkas yang header-nya
/// valid tetapi isinya rusak.
void main() {
  testWidgets('semua sprite dapat di-decode utuh dan ukurannya cocok manifest', (tester) async {
    final sprites = (jsonDecode(File('assets/sprites/manifest.json').readAsStringSync())
        as Map<String, dynamic>)['sprites'] as Map<String, dynamic>;
    final rusak = <String>[];
    await tester.runAsync(() async {
      for (final e in sprites.entries) {
        final m = e.value as Map<String, dynamic>;
        try {
          final bytes = File('assets/sprites/${m['file']}').readAsBytesSync();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          final w = frame.image.width;
          final h = frame.image.height;
          // Bacah piksel supaya decode benar-benar dipaksa selesai.
          await frame.image.toByteData();
          if (w != m['w'] || h != m['h']) rusak.add('${e.key}: ${w}x$h != ${m['w']}x${m['h']}');
          frame.image.dispose();
        } catch (err) {
          rusak.add('${e.key}: $err');
        }
      }
    });
    expect(rusak, isEmpty, reason: 'sprite rusak: $rusak');
  });
}
