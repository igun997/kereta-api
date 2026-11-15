import 'dart:math' as math;

/// Hasil satu langkah fisika.
class PeristiwaFisika {
  const PeristiwaFisika({this.tiba = false, this.sampai = false});

  /// Kereta berhenti di zona tujuan.
  final bool tiba;

  /// Kereta melewati titik "jalan ke".
  final bool sampai;
}

/// Fisika kereta murni (tanpa Flame): gas, rem, palang, dan bantuan merayap.
///
/// Prinsip untuk anak kecil: tidak ada tabrakan, tidak ada macet. Palang menghentikan
/// kereta dengan halus, dan bila anak belum menekan gas kereta merayap pelan ke zona tujuan.
class FisikaKereta {
  static const double vMaks = 470;
  static const double vMerayap = 150;
  static const double vBantuan = 400;
  static const double percepatan = 300;
  static const double perlambatanLepas = 170;
  static const double perlambatanRem = 820;
  static const double perlambatanPalang = 520;

  /// Zona berhenti: [tujuan - zonaSebelum, tujuan + zonaSesudah].
  static const double zonaSebelum = 260;
  static const double zonaSesudah = 60;

  /// Detik diam sebelum bantuan merayap aktif.
  static const double tungguMerayap = 3.0;

  double kecepatan = 0;
  double jarak = 0;
  double diamLama = 0;

  /// Palang di jarak dunia ini; kereta berhenti halus sebelum melewatinya.
  double? penghalang;
  double? tujuan;

  /// Titik yang harus dilewati dengan jalan otomatis.
  double? jalanKe;
  bool _merayap = false;

  void pasangTujuan(double wx) {
    tujuan = wx;
    penghalang = wx + zonaSesudah;
  }

  void bebaskan() {
    tujuan = null;
    penghalang = null;
    _merayap = false;
  }

  bool get diZona {
    final t = tujuan;
    return t != null && jarak >= t - zonaSebelum && jarak <= t + zonaSesudah + 1;
  }

  PeristiwaFisika langkah(double dt,
      {required bool gas, required bool rem, required bool otomatis}) {
    final manual = gas || otomatis;
    final bantuan = jalanKe != null;
    var v = kecepatan;
    var batas = vMaks;

    final t = tujuan;
    // Bantuan merayap dikunci: sekali aktif tetap jalan sampai anak menekan gas
    // atau kereta tiba di zona (kalau tidak, kereta macet begitu mulai bergerak).
    if (manual || bantuan || t == null || jarak >= t - zonaSebelum) {
      _merayap = false;
    } else if (diamLama > tungguMerayap) {
      _merayap = true;
    }
    final merayap = _merayap;
    if (bantuan) batas = vBantuan;

    if (manual || bantuan || merayap) {
      if (merayap) batas = vMerayap;
      if (v < batas) {
        v = math.min(batas, v + percepatan * dt);
      } else {
        v = math.max(batas, v - perlambatanLepas * dt);
      }
    } else {
      v -= perlambatanLepas * dt;
    }
    if (rem) v -= perlambatanRem * dt;
    v = math.max(0, v);

    final p = penghalang;
    if (p != null) {
      final sisa = math.max(0, p - jarak);
      v = math.min(v, math.sqrt(2 * perlambatanPalang * sisa));
    }
    jarak += v * dt;
    if (p != null && jarak > p) {
      jarak = p;
      v = 0;
    }
    kecepatan = v;
    diamLama = (v < 5 && !gas) ? diamLama + dt : 0;

    final tiba = t != null && v < 5 && diZona;
    var sampai = false;
    final j = jalanKe;
    if (j != null && jarak >= j) {
      jalanKe = null;
      sampai = true;
    }
    return PeristiwaFisika(tiba: tiba, sampai: sampai);
  }
}
