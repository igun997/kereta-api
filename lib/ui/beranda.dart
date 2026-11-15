import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/konstanta.dart';
import 'pengaturan.dart';
import 'pilih.dart';
import 'stiker.dart';
import 'widgets.dart';

/// Beranda: logo, tombol MULAI besar, buku stiker, dan pengaturan (gerbang orang tua).
class Beranda extends StatefulWidget {
  const Beranda({super.key});

  @override
  State<Beranda> createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> with SingleTickerProviderStateMixin {
  late final AnimationController _ayun = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Audio.i.musikMulai('menu');
  }

  @override
  void dispose() {
    _ayun.dispose();
    super.dispose();
  }

  Future<void> _buka(Widget layar) async {
    await Navigator.of(context).push(rutePudar(layar));
    Audio.i.musikMulai('menu');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palet.langit,
      body: LatarMenu(
        child: LayoutBuilder(builder: (context, k) {
          final tinggi = k.maxHeight;
          final besar = (tinggi * 0.34).clamp(120.0, 260.0);
          final kecil = (tinggi * 0.2).clamp(84.0, 150.0);
          return Stack(children: [
            Positioned(
              top: tinggi * 0.04,
              left: 0,
              right: 0,
              height: tinggi * 0.52,
              child: AnimatedBuilder(
                animation: _ayun,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, -10 * _ayun.value),
                  child: Transform.rotate(angle: (_ayun.value - 0.5) * 0.03, child: child),
                ),
                child: Image.asset(
                  'assets/brand/logo_transparan.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, e, s) => Image.asset('assets/brand/logo.png', fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              bottom: tinggi * 0.06,
              left: 0,
              right: 0,
              child: Center(
                child: TombolGambar(
                  aset: 'assets/ui/tombol_mulai.png',
                  ukuran: besar,
                  berdenyut: true,
                  semantik: 'Mulai bermain',
                  padaTap: () => _buka(const PilihDunia()),
                ),
              ),
            ),
            Positioned(
              bottom: tinggi * 0.07,
              left: tinggi * 0.07,
              child: TombolGambar(
                aset: 'assets/ui/tombol_stiker.png',
                ukuran: kecil,
                semantik: 'Buku stiker',
                padaTap: () => _buka(const BukuStiker()),
              ),
            ),
            Positioned(
              bottom: tinggi * 0.07,
              right: tinggi * 0.07,
              child: GerbangOrangTua(
                ukuran: kecil * 0.8,
                padaBuka: () => _buka(const Pengaturan()),
              ),
            ),
          ]);
        }),
      ),
    );
  }
}

/// Tombol pengaturan yang harus ditahan 3 detik (anak kecil tidak sengaja membukanya).
class GerbangOrangTua extends StatefulWidget {
  const GerbangOrangTua({super.key, required this.ukuran, required this.padaBuka});
  final double ukuran;
  final VoidCallback padaBuka;

  @override
  State<GerbangOrangTua> createState() => _GerbangState();
}

class _GerbangState extends State<GerbangOrangTua> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _c.value = 0;
        widget.padaBuka();
      }
    });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Listener(
        onPointerDown: (_) => _c.forward(),
        onPointerUp: (_) => _c.reverse(),
        onPointerCancel: (_) => _c.reverse(),
        child: Semantics(
          button: true,
          label: 'Pengaturan orang tua. Tahan 3 detik.',
          child: SizedBox(
            width: widget.ukuran,
            height: widget.ukuran,
            child: Stack(alignment: Alignment.center, children: [
              Image.asset('assets/ui/tombol_pengaturan.png', fit: BoxFit.contain),
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) => SizedBox(
                  width: widget.ukuran,
                  height: widget.ukuran,
                  child: CircularProgressIndicator(
                    value: _c.value,
                    strokeWidth: 8,
                    color: Palet.kuning,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Orang tua: tahan 3 detik',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Palet.garis,
          shadows: [Shadow(color: Colors.white, blurRadius: 4)],
        ),
      ),
    ]);
  }
}
