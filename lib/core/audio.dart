import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'penyimpanan.dart';

/// Layanan audio: suara pemandu (satu per satu), efek, dan musik latar.
///
/// Semua berkas ada di assets/audio/{suara,sfx,musik}/NAMA.mp3.
class Audio {
  String? _musikDiminta;
  Audio._();
  static final Audio i = Audio._();

  static const daftarSfx = [
    'peluit', 'rem', 'chug', 'ding', 'pop', 'boing', 'bintang', 'tap',
    'selesai', 'salah', 'lampu', 'kunang', 'klak_wesel',
  ];

  final Map<String, AudioPool> _pool = {};
  AudioPlayer? _suara;
  AudioPlayer? _musik;
  String? _musikSekarang;
  bool _siap = false;
  int _giliranSuara = 0;

  Penyimpanan get _s => Penyimpanan.i;

  Future<void> siapkan() async {
    if (_siap) return;
    _siap = true;
    try {
      await AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ));
      for (final n in daftarSfx) {
        _pool[n] = await AudioPool.create(
          source: AssetSource('audio/sfx/$n.mp3'),
          maxPlayers: n == 'chug' || n == 'tap' ? 4 : 2,
        );
      }
      _suara = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _musik = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
    } catch (e, st) {
      _siap = false;
      debugPrint('Audio gagal disiapkan: $e\n$st');
    }
  }

  double get _vol => _s.volumeUtama;

  /// Efek suara singkat. Diam bila efek dimatikan.
  void sfx(String nama, {double volume = 1.0}) {
    if (!_siap || !_s.efekAktif) return;
    final p = _pool[nama];
    if (p == null) return;
    unawaited(p.start(volume: (volume * _vol).clamp(0.0, 1.0)).then((_) {},
        onError: (Object e) => debugPrint('sfx $nama: $e')));
  }

  /// Suara pemandu. Memotong suara sebelumnya. Selesai saat suara habis.
  Future<void> bicara(String nama) async {
    final p = _suara;
    if (!_siap || p == null || !_s.suaraPemandu) return;
    final giliran = ++_giliranSuara;
    try {
      await p.stop();
      await p.setVolume(_vol);
      final habis = Completer<void>();
      late final StreamSubscription<void> sub;
      sub = p.onPlayerComplete.listen((_) {
        if (!habis.isCompleted) habis.complete();
      });
      await p.play(AssetSource('audio/suara/$nama.mp3'));
      await habis.future
          .timeout(const Duration(seconds: 8), onTimeout: () {});
      await sub.cancel();
      if (giliran != _giliranSuara) return;
    } catch (e) {
      debugPrint('suara $nama: $e');
    }
  }

  /// Rangkaian suara berurutan (mis. "satu", "dua", "tiga").
  Future<void> bicaraUrut(List<String> nama, {Duration jeda = Duration.zero}) async {
    for (final n in nama) {
      await bicara(n);
      if (jeda > Duration.zero) await Future<void>.delayed(jeda);
    }
  }

  void diamkanSuara() {
    _giliranSuara++;
    unawaited(_suara?.stop());
  }

  Future<void> musikMulai(String nama) async {
    _musikDiminta = nama;
    final p = _musik;
    if (!_siap || p == null) return;
    if (!_s.musikAktif) {
      await musikHenti();
      return;
    }
    if (_musikSekarang == nama) {
      await p.setVolume(_s.volumeMusik * _vol);
      return;
    }
    _musikSekarang = nama;
    try {
      await p.stop();
      await p.setVolume(_s.volumeMusik * _vol);
      await p.play(AssetSource('audio/musik/$nama.mp3'));
    } catch (e) {
      debugPrint('musik $nama: $e');
    }
  }

  Future<void> musikHenti() async {
    _musikSekarang = null;
    await _musik?.stop();
  }

  /// Terapkan ulang volume/pengaturan (dipanggil dari layar pengaturan).
  Future<void> terapkanPengaturan() async {
    if (!_s.musikAktif) {
      await musikHenti();
      return;
    }
    final diminta = _musikDiminta;
    if (diminta != null && _musikSekarang == null) {
      await musikMulai(diminta);
    } else {
      await _musik?.setVolume(_s.volumeMusik * _vol);
    }
  }

  Future<void> jeda() async {
    await _musik?.pause();
    await _suara?.pause();
  }

  Future<void> lanjut() async {
    if (_s.musikAktif && _musikSekarang != null) await _musik?.resume();
  }
}
