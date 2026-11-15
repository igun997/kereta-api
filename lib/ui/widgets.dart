import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/konstanta.dart';

/// Tombol berupa gambar: membal saat ditekan, suara klik lembut, denyut opsional.
class TombolGambar extends StatefulWidget {
  const TombolGambar({
    super.key,
    required this.aset,
    required this.ukuran,
    required this.padaTap,
    this.berdenyut = false,
    this.semantik,
    this.suara = 'tap',
  });

  final String aset;
  final double ukuran;
  final VoidCallback padaTap;
  final bool berdenyut;
  final String? semantik;
  final String suara;

  @override
  State<TombolGambar> createState() => _TombolGambarState();
}

class _TombolGambarState extends State<TombolGambar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  bool _tekan = false;

  @override
  void initState() {
    super.initState();
    if (widget.berdenyut) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant TombolGambar old) {
    super.didUpdateWidget(old);
    if (widget.berdenyut && !_c.isAnimating) _c.repeat(reverse: true);
    if (!widget.berdenyut && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semantik,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _tekan = true),
        onTapCancel: () => setState(() => _tekan = false),
        onTapUp: (_) => setState(() => _tekan = false),
        onTap: () {
          Audio.i.sfx(widget.suara);
          widget.padaTap();
        },
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final denyut = widget.berdenyut ? 1 + 0.07 * _c.value : 1.0;
            return Transform.scale(scale: (_tekan ? 0.9 : 1.0) * denyut, child: child);
          },
          child: SizedBox(
            width: widget.ukuran,
            height: widget.ukuran,
            child: Image.asset(widget.aset, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
          ),
        ),
      ),
    );
  }
}

/// Latar layar penuh dengan gambar menu (jatuh ke warna langit bila gambar belum ada).
class LatarMenu extends StatelessWidget {
  const LatarMenu({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      const ColoredBox(color: Palet.langit),
      Image.asset(
        'assets/backgrounds/menu_latar.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => const SizedBox.shrink(),
      ),
      SafeArea(child: child),
    ]);
  }
}

/// Rute tanpa animasi peralihan (dipakai untuk pindah antar misi tanpa tumpang tindih).
Route<T> ruteInstan<T>(Widget halaman) => PageRouteBuilder<T>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, a, b) => halaman,
    );

/// Rute dengan pudar lembut.
Route<T> rutePudar<T>(Widget halaman) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, a, b) => halaman,
      transitionsBuilder: (context, a, b, child) => FadeTransition(opacity: a, child: child),
    );
