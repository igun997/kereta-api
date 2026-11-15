import 'package:flutter_test/flutter_test.dart';
import 'package:kereta_api/game/perspektif.dart';

void main() {
  const p = Proyeksi(lebar: 1920);

  test('titik di tengah rel (x=0) selalu berada di tengah layar', () {
    for (final z in [2.0, 5.0, 20.0, 90.0]) {
      expect(p.titik(0, 0, z).dx, closeTo(960, 1e-9));
    }
  });

  test('semakin jauh, benda semakin dekat ke cakrawala dan semakin kecil', () {
    var yTerakhir = double.infinity;
    var skalaTerakhir = double.infinity;
    for (final z in [2.0, 4.0, 8.0, 16.0, 64.0]) {
      final y = p.titik(0, 0, z).dy;
      expect(y, lessThan(yTerakhir), reason: 'tanah di z=$z harus lebih tinggi di layar');
      expect(y, greaterThan(p.hor), reason: 'tanah selalu di bawah cakrawala');
      expect(p.skala(z), lessThan(skalaTerakhir));
      yTerakhir = y;
      skalaTerakhir = p.skala(z);
    }
  });

  test('rel konvergen ke titik hilang di cakrawala', () {
    final jauh = p.titik(0.72, 0, 5000);
    expect(jauh.dx, closeTo(960, 1.0));
    expect(jauh.dy, closeTo(p.hor, 1.0));
    // Di dekat kamera jarak antar rel jauh lebih lebar daripada di kejauhan.
    final lebarDekat = p.titik(0.72, 0, 3).dx - p.titik(-0.72, 0, 3).dx;
    final lebarJauh = p.titik(0.72, 0, 30).dx - p.titik(-0.72, 0, 30).dx;
    expect(lebarDekat / lebarJauh, closeTo(10, 1e-6));
  });

  test('benda yang lebih tinggi tampil lebih tinggi di layar', () {
    expect(p.titik(0, 2, 10).dy, lessThan(p.titik(0, 0, 10).dy));
  });

  test('geser lateral memindahkan benda ke sisi yang benar', () {
    expect(p.titik(3, 0, 8).dx, greaterThan(960));
    expect(p.titik(-3, 0, 8).dx, lessThan(960));
  });

  test('dekorasi berputar: selalu dalam rentang, mendekat saat kereta maju, lalu muncul lagi di jauh', () {
    const zDasar = 40.0;
    var z0 = zDekorBerputar(zDasar, 0);
    var melompatJauh = 0;
    for (var j = 0.5; j < 400; j += 0.5) {
      final z = zDekorBerputar(zDasar, j);
      expect(z, inInclusiveRange(kZDekat, kZDekat + kPeriodeDekor));
      if (z > z0 + 10) {
        melompatJauh++; // dibungkus ke belakang cakrawala
      } else {
        expect(z, lessThan(z0), reason: 'harus mendekat saat jarak bertambah');
      }
      z0 = z;
    }
    expect(melompatJauh, greaterThanOrEqualTo(3));
  });

  test('jarak negatif (mundur) tetap valid', () {
    expect(zDekorBerputar(10, -500), inInclusiveRange(kZDekat, kZDekat + kPeriodeDekor));
  });
}
