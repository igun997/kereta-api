import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/konstanta.dart';
import '../game/kereta_game.dart';
import 'widgets.dart';

/// Halaman yang menampung satu permainan (misi atau jalan-jalan bebas).
class PermainanLayar extends StatefulWidget {
  const PermainanLayar({super.key, required this.dunia, required this.misi});

  final int dunia;

  /// 0..5 = misi, -1 = jalan-jalan bebas.
  final int misi;

  @override
  State<PermainanLayar> createState() => _PermainanLayarState();
}

class _PermainanLayarState extends State<PermainanLayar> {
  late final KeretaGame _game;

  @override
  void initState() {
    super.initState();
    _game = KeretaGame(
      dunia: widget.dunia,
      misiNo: widget.misi,
      padaSelesai: _selesai,
      padaKeluar: _keluar,
    );
  }

  void _selesai(bool lanjut) {
    if (!mounted) return;
    final berikut = widget.misi + 1;
    if (lanjut && widget.misi >= 0 && berikut < kMisiPerDunia) {
      Navigator.of(context).pushReplacement(
        ruteInstan(PermainanLayar(dunia: widget.dunia, misi: berikut)),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _keluar() {
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    Audio.i.diamkanSuara();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palet.langit,
      body: GameWidget<KeretaGame>(
        game: _game,
        loadingBuilder: (context) => const ColoredBox(
          color: Palet.langit,
          child: Center(child: CircularProgressIndicator(color: Palet.putih, strokeWidth: 8)),
        ),
        errorBuilder: (context, error) => ColoredBox(
          color: Palet.langit,
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TombolGambar(
                aset: 'assets/ui/tombol_beranda.png',
                ukuran: 140,
                padaTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 12),
              const Text('Ups, ada masalah. Tekan rumah untuk kembali.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Palet.garis)),
            ]),
          ),
        ),
      ),
    );
  }
}
