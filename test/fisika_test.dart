import 'package:flutter_test/flutter_test.dart';
import 'package:kereta_api/game/fisika.dart';

const dt = 1 / 60;

PeristiwaFisika _jalan(FisikaKereta f, double detik,
    {bool gas = false, bool rem = false, bool otomatis = false}) {
  var tiba = false;
  var sampai = false;
  for (var i = 0; i < detik / dt; i++) {
    final h = f.langkah(dt, gas: gas, rem: rem, otomatis: otomatis);
    tiba |= h.tiba;
    sampai |= h.sampai;
  }
  return PeristiwaFisika(tiba: tiba, sampai: sampai);
}

void main() {
  test('gas menambah kecepatan bertahap dan tidak melebihi batas', () {
    final f = FisikaKereta();
    f.langkah(dt, gas: true, rem: false, otomatis: false);
    expect(f.kecepatan, lessThan(10), reason: 'tidak boleh melonjak');
    _jalan(f, 10, gas: true);
    expect(f.kecepatan, FisikaKereta.vMaks);
    expect(f.jarak, greaterThan(2000));
  });

  test('melepas gas memperlambat sampai berhenti, tidak pernah mundur', () {
    final f = FisikaKereta();
    _jalan(f, 3, gas: true);
    var terakhir = f.jarak;
    for (var i = 0; i < 600; i++) {
      f.langkah(dt, gas: false, rem: false, otomatis: false);
      expect(f.kecepatan, greaterThanOrEqualTo(0));
      expect(f.jarak, greaterThanOrEqualTo(terakhir));
      terakhir = f.jarak;
    }
    expect(f.kecepatan, 0);
  });

  test('rem berhenti jauh lebih cepat daripada melepas gas', () {
    final a = FisikaKereta();
    final b = FisikaKereta();
    _jalan(a, 3, gas: true);
    _jalan(b, 3, gas: true);
    _jalan(a, 1, rem: true);
    _jalan(b, 1);
    expect(a.kecepatan, 0);
    expect(b.kecepatan, greaterThan(0));
  });

  test('palang tidak pernah terlewati walau gas ditahan terus, berhenti halus di zona', () {
    final f = FisikaKereta()..pasangTujuan(3000);
    final puncak = <double>[];
    var tiba = false;
    for (var i = 0; i < 60 * 40; i++) {
      final h = f.langkah(dt, gas: true, rem: false, otomatis: false);
      tiba |= h.tiba;
      puncak.add(f.jarak);
      expect(f.jarak, lessThanOrEqualTo(3000 + FisikaKereta.zonaSesudah));
    }
    expect(tiba, isTrue);
    expect(f.kecepatan, 0);
    expect(f.diZona, isTrue);
    // Perlambatan halus: tidak ada lompatan kecepatan mendadak > 15 px/s per frame.
    // Perlambatan palang tidak lebih keras dari 1,5x rancangan, kecuali saat sudah hampir berhenti.
    final g = FisikaKereta()..pasangTujuan(3000);
    var v0 = 0.0;
    for (var i = 0; i < 60 * 40; i++) {
      g.langkah(dt, gas: true, rem: false, otomatis: false);
      if (v0 > 40) {
        expect((g.kecepatan - v0).abs() / dt, lessThan(FisikaKereta.perlambatanPalang * 1.5));
      }
      v0 = g.kecepatan;
    }
  });

  test('anak berhenti sendiri di zona dengan rem: tiba tercatat', () {
    final f = FisikaKereta()..pasangTujuan(2000);
    _jalan(f, 1.5, gas: true);
    while (f.jarak < 1900) {
      f.langkah(dt, gas: true, rem: false, otomatis: false);
    }
    final h = _jalan(f, 3, rem: true);
    expect(h.tiba, isTrue);
    expect(f.diZona, isTrue);
  });

  test('bantuan merayap: anak diam saja, kereta tetap sampai ke zona tujuan', () {
    final f = FisikaKereta()..pasangTujuan(2500);
    var gerak = false;
    var tiba = false;
    for (var i = 0; i < 60 * 60 && !tiba; i++) {
      final h = f.langkah(dt, gas: false, rem: false, otomatis: false);
      gerak |= f.kecepatan > 1;
      tiba |= h.tiba;
    }
    expect(gerak, isTrue, reason: 'harus mulai merayap setelah anak diam beberapa detik');
    expect(tiba, isTrue);
    expect(f.diZona, isTrue);
  });

  test('merayap tidak aktif sebelum anak sempat menekan gas', () {
    final f = FisikaKereta()..pasangTujuan(2500);
    _jalan(f, FisikaKereta.tungguMerayap - 0.3);
    expect(f.jarak, 0);
  });

  test('mode otomatis berjalan sendiri sampai berhenti di palang', () {
    final f = FisikaKereta()..pasangTujuan(1800);
    final h = _jalan(f, 30, otomatis: true);
    expect(h.tiba, isTrue);
    expect(f.kecepatan, 0);
  });

  test('jalanKe membawa kereta melewati titik tanpa gas', () {
    final f = FisikaKereta()..jalanKe = 1500;
    final h = _jalan(f, 20);
    expect(h.sampai, isTrue);
    expect(f.jarak, greaterThanOrEqualTo(1500));
  });

  test('bebaskan melepas palang sehingga kereta bisa lewat', () {
    final f = FisikaKereta()..pasangTujuan(500);
    _jalan(f, 15, gas: true);
    expect(f.kecepatan, 0);
    f.bebaskan();
    _jalan(f, 5, gas: true);
    expect(f.jarak, greaterThan(1000));
  });
}
