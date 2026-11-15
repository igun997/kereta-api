import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan lokal: stiker, pengaturan orang tua. Tanpa jaringan, tanpa data pribadi.
class Penyimpanan extends ChangeNotifier {
  Penyimpanan._(this._p);

  static late Penyimpanan i;

  final SharedPreferences _p;

  static Future<Penyimpanan> muat() async {
    i = Penyimpanan._(await SharedPreferences.getInstance());
    return i;
  }

  /// Nomor stiker (1..12) yang sudah didapat.
  Set<int> get stiker =>
      (_p.getStringList('stiker') ?? const <String>[]).map(int.parse).toSet();

  bool punyaStiker(int n) => stiker.contains(n);

  Future<void> tambahStiker(int n) async {
    final s = stiker..add(n);
    await _p.setStringList('stiker', s.map((e) => '$e').toList());
    notifyListeners();
  }

  Future<void> hapusStiker() async {
    await _p.remove('stiker');
    notifyListeners();
  }

  bool get suaraPemandu => _p.getBool('suaraPemandu') ?? true;
  bool get musikAktif => _p.getBool('musikAktif') ?? true;
  bool get efekAktif => _p.getBool('efekAktif') ?? true;
  bool get otomatis => _p.getBool('otomatis') ?? false;
  double get volumeMusik => _p.getDouble('volumeMusik') ?? 0.5;
  double get volumeUtama => _p.getDouble('volumeUtama') ?? 1.0;

  Future<void> aturBool(String kunci, bool nilai) async {
    await _p.setBool(kunci, nilai);
    notifyListeners();
  }

  Future<void> aturDouble(String kunci, double nilai) async {
    await _p.setDouble(kunci, nilai);
    notifyListeners();
  }
}

/// Nomor stiker untuk dunia (0..1) dan misi (0..5).
int nomorStiker(int dunia, int misi) => dunia * 6 + misi + 1;
