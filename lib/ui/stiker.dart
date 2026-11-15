import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/konstanta.dart';
import '../core/penyimpanan.dart';
import 'widgets.dart';

/// Buku stiker: 12 tempat; yang belum didapat tampak sebagai bayangan.
class BukuStiker extends StatelessWidget {
  const BukuStiker({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palet.langit,
      body: LatarMenu(
        child: LayoutBuilder(builder: (context, k) {
          final sisi = (k.maxHeight * 0.3).clamp(90.0, 220.0);
          return Stack(children: [
            Center(
              child: Container(
                padding: EdgeInsets.all(k.maxHeight * 0.025),
                decoration: BoxDecoration(
                  color: const Color(0xDDFFFFFF),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: Palet.garis, width: 8),
                ),
                child: AnimatedBuilder(
                  animation: Penyimpanan.i,
                  builder: (context, _) => Column(mainAxisSize: MainAxisSize.min, children: [
                    for (var baris = 0; baris < 2; baris++)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        for (var i = 0; i < 6; i++)
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: _Slot(
                              nomor: baris * 6 + i + 1,
                              sisi: sisi * 0.9,
                              dapat: Penyimpanan.i.punyaStiker(baris * 6 + i + 1),
                            ),
                          ),
                      ]),
                  ]),
                ),
              ),
            ),
            Positioned(
              top: k.maxHeight * 0.03,
              left: k.maxHeight * 0.03,
              child: TombolGambar(
                aset: 'assets/ui/tombol_beranda.png',
                ukuran: (k.maxHeight * 0.17).clamp(72.0, 130.0),
                semantik: 'Kembali',
                padaTap: () => Navigator.of(context).pop(),
              ),
            ),
          ]);
        }),
      ),
    );
  }
}

class _Slot extends StatefulWidget {
  const _Slot({required this.nomor, required this.sisi, required this.dapat});
  final int nomor;
  final double sisi;
  final bool dapat;

  @override
  State<_Slot> createState() => _SlotState();
}

class _SlotState extends State<_Slot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.nomor.toString().padLeft(2, '0');
    final gambar = Image.asset('assets/stickers/stiker_$n.png', fit: BoxFit.contain);
    return Semantics(
      label: widget.dapat ? 'Stiker $n' : 'Stiker $n belum didapat',
      child: GestureDetector(
        onTap: () {
          if (!widget.dapat) {
            Audio.i.sfx('tap');
            return;
          }
          Audio.i.sfx('bintang');
          _c.forward(from: 0);
        },
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final goyang = math.sin(_c.value * math.pi * 4) * 0.22 * (1 - _c.value);
            final bunyi = 1 + 0.2 * math.sin(_c.value * math.pi);
            return Transform.rotate(
              angle: goyang,
              child: Transform.scale(scale: bunyi, child: child),
            );
          },
          child: Container(
            width: widget.sisi,
            height: widget.sisi,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.dapat ? Colors.transparent : const Color(0x22000000),
            ),
            padding: EdgeInsets.all(widget.sisi * 0.04),
            child: widget.dapat
                ? gambar
                : Stack(alignment: Alignment.center, children: [
                    Opacity(
                      opacity: 0.18,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(Palet.garis, BlendMode.srcIn),
                        child: gambar,
                      ),
                    ),
                    Image.asset('assets/ui/ikon_gembok.png', width: widget.sisi * 0.34),
                  ]),
          ),
        ),
      ),
    );
  }
}
