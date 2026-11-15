import 'package:flutter_test/flutter_test.dart';
import 'package:kereta_api/core/penyimpanan.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('nomor stiker unik 1..12 untuk setiap dunia dan misi', () {
    final semua = {
      for (var d = 0; d < 2; d++)
        for (var m = 0; m < 6; m++) nomorStiker(d, m),
    };
    expect(semua.length, 12);
    expect(semua.reduce((a, b) => a < b ? a : b), 1);
    expect(semua.reduce((a, b) => a > b ? a : b), 12);
  });

  test('stiker tersimpan, tidak ganda, dan bisa dihapus', () async {
    final p = await Penyimpanan.muat();
    expect(p.stiker, isEmpty);
    await p.tambahStiker(3);
    await p.tambahStiker(3);
    await p.tambahStiker(7);
    expect(p.stiker, {3, 7});
    final lagi = await Penyimpanan.muat();
    expect(lagi.punyaStiker(7), isTrue);
    await lagi.hapusStiker();
    expect(lagi.stiker, isEmpty);
  });

  test('pengaturan awal ramah anak: suara pemandu aktif, mode otomatis mati', () async {
    final p = await Penyimpanan.muat();
    expect(p.suaraPemandu, isTrue);
    expect(p.musikAktif, isTrue);
    expect(p.otomatis, isFalse);
    await p.aturBool('otomatis', true);
    expect(p.otomatis, isTrue);
  });
}
