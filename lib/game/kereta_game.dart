import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart' show Curves;

import '../core/audio.dart';
import '../core/konstanta.dart';
import '../core/penyimpanan.dart';
import 'dunia.dart';
import 'fisika.dart';
import 'galeri.dart';
import 'kereta.dart';
import 'komponen.dart';
import 'perspektif.dart';
import 'misi/misi.dart';

/// Game utama: satu misi (atau jalan-jalan bebas) di satu dunia.
class KeretaGame extends FlameGame {
  KeretaGame({
    required this.dunia,
    required this.misiNo,
    required this.padaSelesai,
    required this.padaKeluar,
  });

  /// 0 = Desa Sawah, 1 = Kota Kecil.
  final int dunia;

  /// 0..5 = misi; -1 = jalan-jalan bebas.
  final int misiNo;

  /// Dipanggil setelah hadiah: `true` = lanjut ke misi berikutnya.
  final void Function(bool lanjut) padaSelesai;
  final void Function() padaKeluar;

  static int misiSesi = 0;

  final Galeri galeri = Galeri.i;
  late final PositionComponent panggung;
  Kereta? kereta;
  late final Asap asap;
  late final Hud hud;
  late final Misi? misi;
  late final DuniaBelakang belakang;

  /// Sudut kamera saat ini (samping atau orang ketiga di belakang kereta).
  Kamera kamera = Kamera.samping;

  /// Ukuran kanvas desain (tinggi tetap 1080, lebar mengikuti rasio layar).
  Vector2 ruang = Vector2(1920, kTinggi);

  // --- Keadaan kereta ---
  final FisikaKereta fisika = FisikaKereta();
  double get kecepatan => fisika.kecepatan;
  double get jarak => fisika.jarak;
  double trainX = 1300;
  bool gas = false;
  bool rem = false;
  bool aktif = true;

  Completer<void>? _tiba;
  Completer<void>? _sampai;
  Completer<void>? _menungguPeluit;
  double _petunjukTerakhir = -99;
  double _waktu = 0;

  bool get otomatis => Penyimpanan.i.otomatis;

  @override
  Color backgroundColor() => Palet.langit;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.y <= 0 || size.x <= 0) return;
    final k = size.y / kTinggi;
    ruang = Vector2(size.x / k, kTinggi);
    if (_panggungSiap) panggung.scale.setAll(k);
  }

  bool _panggungSiap = false;

  @override
  Future<void> onLoad() async {
    Flame.images.prefix = 'assets/';
    panggung = PositionComponent(scale: Vector2.all(math.max(0.01, size.y) / kTinggi));
    _panggungSiap = true;
    await add(panggung);

    final warna = _warnaGerbong();
    misi = buatMisi(misiNo, this);
    // Misi hewan di rel dan terowongan memakai kamera orang ketiga; jalan-jalan bebas bisa berganti.
    kamera = (misiNo == 2 || misiNo == 3) ? Kamera.belakang : Kamera.samping;
    final adaBelakang = misiNo == -1 || misiNo == 2 || misiNo == 3;
    final perlu = <String>{
      ...spriteDunia(dunia),
      ...spriteKereta(warna),
      if (adaBelakang) ...spriteBelakang(warna),
      ...?misi?.sprite,
    };
    galeri.lepasKecuali(perlu);
    await galeri.muat(perlu);

    for (final c in bangunDunia(dunia, benih: 11 + dunia * 5)) {
      await panggung.add(c);
    }
    belakang = DuniaBelakang(dunia, warna);
    await panggung.add(belakang);
    final k = Kereta(warna);
    kereta = k;
    await panggung.add(k);
    asap = Asap();
    await panggung.add(asap);
    hud = Hud();
    await panggung.add(hud);

    unawaited(Audio.i.musikMulai('main'));
    final m = misi;
    if (m != null) {
      unawaited(m.jalankan().catchError((Object e, StackTrace st) {
        // Misi tidak boleh membuat game macet: tulis ke log, anak tetap bisa bermain.
        // ignore: avoid_print
        print('Misi $misiNo gagal: $e\n$st');
      }));
    } else {
      unawaited(Audio.i.bicara('halo'));
    }
  }

  List<String> _warnaGerbong() {
    switch (misiNo) {
      case 0:
        return ['kuning', 'kuning'];
      case 1:
        return ['merah', 'kuning', 'biru'];
      case 5:
        return ['hijau'];
      default:
        return ['kuning'];
    }
  }

  @override
  void onRemove() {
    aktif = false;
    super.onRemove();
  }

  // ---------------------------------------------------------------- fisika

  @override
  void update(double dt) {
    super.update(dt);
    final d = math.min(dt, 0.05);
    _waktu += d;
    _fisika(d);
  }

  void _fisika(double dt) {
    final manual = gas || otomatis;
    final hasil = fisika.langkah(dt, gas: gas, rem: rem, otomatis: otomatis);
    if (hasil.tiba && _tiba != null && !_tiba!.isCompleted) _tiba!.complete();
    if (hasil.sampai && _sampai != null && !_sampai!.isCompleted) _sampai!.complete();

    // Petunjuk suara bila kereta diam lama padahal anak perlu menjalankannya.
    if (fisika.diamLama > 8 && !manual && fisika.tujuan != null && _waktu - _petunjukTerakhir > 18) {
      _petunjukTerakhir = _waktu;
      hud.sorotGas(true);
      unawaited(Audio.i.bicara('tekan_hijau'));
    }
    if (gas || kecepatan > 30) hud.sorotGas(false);
  }

  /// Kereta menuju titik henti [wx] (jarak dunia posisi pivot lokomotif).
  /// Selesai saat kereta berhenti di zona (260 px sebelum sampai 60 px sesudah titik).
  Future<void> menujuBerhenti(double wx) {
    fisika.pasangTujuan(wx);
    _tiba = Completer<void>();
    return _tiba!.future;
  }

  /// Lepaskan palang dan tujuan.
  void bebaskan() => fisika.bebaskan();

  /// Kereta jalan sendiri sampai jarak dunia [wx] (tanpa perlu menekan gas).
  Future<void> jalanKe(double wx) {
    fisika.jalanKe = wx;
    _sampai = Completer<void>();
    return _sampai!.future;
  }

  /// Untuk uji: apakah game sedang menunggu anak membunyikan peluit.
  bool get menungguPeluitAktif => _menungguPeluit != null && !_menungguPeluit!.isCompleted;

  /// Menunggu anak menekan tombol peluit.
  Future<void> menungguPeluit() {
    _menungguPeluit = Completer<void>();
    hud.sorotPeluit(true);
    return _menungguPeluit!.future;
  }

  void peluitDitekan() {
    kereta?.bunyikanPeluit();
    belakang.getar();
    hud.sorotPeluit(false);
    final c = _menungguPeluit;
    if (c != null && !c.isCompleted) {
      _menungguPeluit = null;
      c.complete();
    }
  }

  /// Jeda yang aman bila game sudah ditutup. `false` = game sudah tidak aktif.
  Future<bool> tunggu(double detik) async {
    await Future<void>.delayed(Duration(milliseconds: (detik * 1000).round()));
    return aktif;
  }

  // -------------------------------------------------------------- selesai

  Future<void> selesaiMisi() async {
    if (!aktif || misiNo < 0) return;
    final stiker = nomorStiker(dunia, misiNo);
    await Penyimpanan.i.tambahStiker(stiker);
    misiSesi++;
    Audio.i.sfx('selesai');
    await panggung.add(Perayaan.hujan(ruang.x));
    final h = Hadiah(stiker, istirahat: misiSesi % 3 == 0);
    await panggung.add(h);
  }

  void kembaliKeBeranda() => padaKeluar();

  /// Ketuk tombol beranda: tampilkan konfirmasi dengan dua tombol besar.
  void tampilKonfirmasi() {
    if (panggung.children.any((c) => c is KonfirmasiKeluar)) return;
    panggung.add(KonfirmasiKeluar());
  }

  /// Ganti sudut kamera dengan efek "whoosh".
  void gantiKamera(Kamera ke) {
    if (ke == kamera || panggung.children.any((c) => c is Transisi)) return;
    panggung.add(Transisi(ke));
  }

  void gantiKameraBergilir() =>
      gantiKamera(kamera == Kamera.samping ? Kamera.belakang : Kamera.samping);
}

/// Tombol kendali: GAS, REM, PELUIT, BERANDA, dan bintang kemajuan misi.
class Hud extends PositionComponent with HasGameReference<KeretaGame> {
  Hud() : super(priority: 100);

  late TombolBulat _gas;
  late TombolBulat _rem;
  late TombolBulat _peluit;
  late TombolBulat _beranda;
  late TombolBulat _kamera;
  late BintangProgres _bintang;
  Vector2 _ruangTerakhir = Vector2.zero();

  /// Akses untuk uji end-to-end: tombol asli dan jumlah bintang.
  TombolBulat get tombolGas => _gas;
  TombolBulat get tombolRem => _rem;
  TombolBulat get tombolPeluit => _peluit;
  TombolBulat get tombolBeranda => _beranda;
  int get bintangSelesai => _bintang._selesai;
  int get bintangTotal => _bintang._total;

  @override
  Future<void> onLoad() async {
    _gas = TombolBulat('tombol_gas',
        posisi: Vector2.zero(),
        diameter: 250,
        padaTekan: () => game.gas = true,
        padaLepas: () => game.gas = false,
        suaraTekan: null);
    _rem = TombolBulat('tombol_rem',
        posisi: Vector2.zero(),
        diameter: 210,
        padaTekan: () => game.rem = true,
        padaLepas: () => game.rem = false,
        suaraTekan: 'rem');
    _peluit = TombolBulat('tombol_peluit',
        posisi: Vector2.zero(), diameter: 210, padaTekan: game.peluitDitekan, suaraTekan: null);
    _beranda = TombolBulat('tombol_beranda',
        posisi: Vector2.zero(), diameter: 140, padaLepas: game.tampilKonfirmasi);
    _kamera = TombolBulat('tombol_kamera',
        posisi: Vector2.zero(), diameter: 140, padaLepas: game.gantiKameraBergilir);
    _bintang = BintangProgres();
    await addAll([_gas, _rem, _peluit, _beranda, _kamera, _bintang]);
    _atur();
  }

  void _atur() {
    final w = game.ruang.x;
    _ruangTerakhir = game.ruang.clone();
    _gas.position.setValues(w - 190, kTinggi - 180);
    _rem.position.setValues(150, kTinggi - 170);
    _peluit.position.setValues(370, kTinggi - 160);
    _beranda.position.setValues(270, 120);
    _kamera.position.setValues(w - 190, 130);
    _kamera.terlihat = game.misiNo < 0;
    _bintang.position.setValues(w - 420, 40);
    _gas.terlihat = !game.otomatis;
  }

  void sorotGas(bool v) => _gas.sorot(v);
  void sorotPeluit(bool v) => _peluit.sorot(v);
  void langkah(int selesai, int total) => _bintang.atur(selesai, total);

  @override
  void update(double dt) {
    if (_ruangTerakhir.x != game.ruang.x) _atur();
  }
}

/// Tiga bintang kemajuan di pojok kanan atas.
class BintangProgres extends PositionComponent {
  BintangProgres() : super(size: Vector2(360, 110));
  int _selesai = 0;
  int _total = 0;

  void atur(int selesai, int total) {
    _selesai = selesai;
    _total = total;
  }

  @override
  void render(Canvas canvas) {
    if (_total <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(55)),
      Paint()..color = const Color(0x7314213D),
    );
    final gap = size.x / _total;
    for (var i = 0; i < _total; i++) {
      final c = Offset(gap * (i + 0.5), 55);
      final terisi = i < _selesai;
      gambarBentuk(canvas, 'bintang', c, 38,
          warna: terisi ? Palet.kuning : const Color(0xFFFFFFFF),
          alpha: terisi ? 1 : 0.55);
    }
  }
}

/// Layar hadiah: stiker besar, konfeti, tombol LANJUT dan BERANDA.
class Hadiah extends PositionComponent with HasGameReference<KeretaGame> {
  Hadiah(this.stiker, {required this.istirahat}) : super(priority: 200);

  final int stiker;
  final bool istirahat;

  @override
  Future<void> onLoad() async {
    final w = game.ruang.x;
    await add(_Tirai(w));
    final nomor = stiker.toString().padLeft(2, '0');
    final gambar = SpriteComponent(
      sprite: await Sprite.load('stickers/stiker_$nomor.png'),
      size: Vector2.all(520),
      anchor: Anchor.center,
      position: Vector2(w / 2, 430),
      angle: -0.08,
    );
    await add(gambar);
    muncul(gambar, detik: 0.9);
    gambar.add(RotateEffect.to(
      0.08,
      EffectController(duration: 1.2, reverseDuration: 1.2, infinite: true, curve: Curves.easeInOut),
    ));
    await add(TombolBulat('tombol_beranda',
        posisi: Vector2(w / 2 - 190, 900),
        diameter: 210,
        padaLepas: () => game.padaSelesai(false)));
    final lanjut = TombolBulat('tombol_lanjut',
        posisi: Vector2(w / 2 + 190, 900), diameter: 230, padaLepas: () => game.padaSelesai(true));
    await add(lanjut);
    denyut(lanjut.children.whereType<SpriteComponent>().first);
    unawaited(() async {
      await Audio.i.bicara('misi_selesai');
      if (istirahat && game.aktif) await Audio.i.bicara('istirahat');
    }());
  }
}

class _Tirai extends PositionComponent with TapCallbacks {
  _Tirai(this.w) : super(priority: -1, size: Vector2(w, kTinggi));
  final double w;

  /// Menyerap ketukan agar tombol di belakang tirai tidak ikut tertekan.
  @override
  void onTapDown(TapDownEvent event) {}

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, w, kTinggi), Paint()..color = const Color(0x99000000));
  }
}

enum Kamera { samping, belakang }

/// Komponen tampak samping: tidak digambar saat kamera orang ketiga aktif.
mixin HanyaSamping on Component, HasGameReference<KeretaGame> {
  @override
  void renderTree(Canvas canvas) {
    if (game.kamera == Kamera.samping) super.renderTree(canvas);
  }
}

/// Konfirmasi keluar: dua tombol besar, PULANG atau LANJUT MAIN.
class KonfirmasiKeluar extends PositionComponent with HasGameReference<KeretaGame> {
  KonfirmasiKeluar() : super(priority: 190);

  @override
  Future<void> onLoad() async {
    final w = game.ruang.x;
    await add(_Tirai(w));
    await add(TombolBulat('tombol_beranda',
        posisi: Vector2(w / 2 - 210, 540),
        diameter: 260,
        priority: 195,
        padaLepas: game.kembaliKeBeranda));
    final lanjut = TombolBulat('tombol_mulai',
        posisi: Vector2(w / 2 + 210, 540),
        diameter: 260,
        priority: 195,
        padaLepas: removeFromParent);
    await add(lanjut);
    denyut(lanjut.children.whereType<SpriteComponent>().first);
  }
}

/// Efek "whoosh" saat kamera berganti sudut: layar tersapu warna langit dan garis kecepatan.
class Transisi extends PositionComponent with HasGameReference<KeretaGame> {
  Transisi(this.ke) : super(priority: 180);

  final Kamera ke;
  double _t = 0;
  bool _sudahGanti = false;
  static const double durasi = 0.9;

  @override
  void update(double dt) {
    _t += dt;
    if (!_sudahGanti && _t >= durasi / 2) {
      _sudahGanti = true;
      game.kamera = ke;
      game.belakang.getar();
      Audio.i.sfx('bintang');
    }
    if (_t >= durasi) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = math.sin(math.pi * (_t / durasi).clamp(0.0, 1.0));
    final w = game.ruang.x;
    canvas.drawRect(
      Rect.fromLTWH(-50, -50, w + 100, kTinggi + 100),
      Paint()..color = Palet.langitMuda.withValues(alpha: a * 0.92),
    );
    final c = Offset(w / 2, kTinggi / 2);
    final garis = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: a)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 22; i++) {
      final ang = i / 22 * math.pi * 2;
      final r1 = 180 + (1 - a) * 500;
      final r2 = r1 + 260 + a * 300;
      canvas.drawLine(
          c + Offset(math.cos(ang), math.sin(ang)) * r1, c + Offset(math.cos(ang), math.sin(ang)) * r2, garis);
    }
  }
}
