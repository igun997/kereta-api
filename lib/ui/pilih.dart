import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/konstanta.dart';
import '../core/penyimpanan.dart';
import 'permainan.dart';
import 'widgets.dart';

/// Pilih dunia: dua kartu gambar besar.
class PilihDunia extends StatelessWidget {
  const PilihDunia({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palet.langit,
      body: LatarMenu(
        child: LayoutBuilder(builder: (context, k) {
          final kartu = (k.maxHeight * 0.62).clamp(160.0, 420.0);
          return Stack(children: [
            Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (var d = 0; d < kJumlahDunia; d++) ...[
                  if (d > 0) SizedBox(width: k.maxHeight * 0.08),
                  _KartuDunia(
                    dunia: d,
                    tinggi: kartu,
                    padaTap: () async {
                      await Navigator.of(context).push(rutePudar(PilihMisi(dunia: d)));
                      Audio.i.musikMulai('menu');
                    },
                  ),
                ],
              ]),
            ),
            Positioned(
              top: k.maxHeight * 0.03,
              left: k.maxHeight * 0.03,
              child: TombolGambar(
                aset: 'assets/ui/tombol_beranda.png',
                ukuran: (k.maxHeight * 0.17).clamp(72.0, 130.0),
                semantik: 'Kembali ke beranda',
                padaTap: () => Navigator.of(context).pop(),
              ),
            ),
          ]);
        }),
      ),
    );
  }
}

class _KartuDunia extends StatelessWidget {
  const _KartuDunia({required this.dunia, required this.tinggi, required this.padaTap});
  final int dunia;
  final double tinggi;
  final VoidCallback padaTap;

  @override
  Widget build(BuildContext context) {
    final berkas = dunia == 0 ? 'dunia_desa' : 'dunia_kota';
    return Semantics(
      button: true,
      label: kNamaDunia[dunia],
      child: GestureDetector(
        onTap: () {
          Audio.i.sfx('pop');
          padaTap();
        },
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: tinggi * 1.15,
            height: tinggi * 0.86,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Palet.garis, width: 8),
              boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 12, offset: Offset(0, 6))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset('assets/backgrounds/$berkas.png', fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          Text(
            kNamaDunia[dunia],
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Palet.garis,
              shadows: [Shadow(color: Colors.white, blurRadius: 6)],
            ),
          ),
        ]),
      ),
    );
  }
}

/// Pilih misi: enam lingkaran bergambar + jalan-jalan bebas.
class PilihMisi extends StatelessWidget {
  const PilihMisi({super.key, required this.dunia});
  final int dunia;

  static const _ikon = <String>[
    'assets/sprites/hewan_kucing.png',
    'assets/sprites/buah_apel.png',
    'assets/ui/tombol_peluit.png',
    'assets/ui/lampu_nyala.png',
    '',
    'assets/sprites/paket_merah.png',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palet.langit,
      body: LatarMenu(
        child: LayoutBuilder(builder: (context, k) {
          final d = (k.maxHeight * 0.36).clamp(110.0, 250.0);
          return Stack(children: [
            AnimatedBuilder(
              animation: Penyimpanan.i,
              builder: (context, _) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  for (var baris = 0; baris < 2; baris++)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: k.maxHeight * 0.02),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        for (var i = 0; i < 3; i++)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: k.maxHeight * 0.025),
                            child: _BulatMisi(
                              diameter: d,
                              ikon: _ikon[baris * 3 + i],
                              bentuk: baris * 3 + i == 4,
                              nomor: baris * 3 + i,
                              selesai: Penyimpanan.i.punyaStiker(nomorStiker(dunia, baris * 3 + i)),
                              padaTap: () => _main(context, baris * 3 + i),
                            ),
                          ),
                      ]),
                    ),
                ]),
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
            Positioned(
              top: k.maxHeight * 0.03,
              right: k.maxHeight * 0.03,
              child: Column(children: [
                TombolGambar(
                  aset: 'assets/ui/tombol_gas.png',
                  ukuran: (k.maxHeight * 0.2).clamp(80.0, 150.0),
                  semantik: 'Jalan-jalan bebas',
                  padaTap: () => _main(context, -1),
                ),
                const Text('Jalan-jalan',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Palet.garis,
                        shadows: [Shadow(color: Colors.white, blurRadius: 5)])),
              ]),
            ),
          ]);
        }),
      ),
    );
  }

  Future<void> _main(BuildContext context, int misi) async {
    await Navigator.of(context).push(ruteInstan(PermainanLayar(dunia: dunia, misi: misi)));
    Audio.i.musikMulai('menu');
  }
}

class _BulatMisi extends StatelessWidget {
  const _BulatMisi({
    required this.diameter,
    required this.ikon,
    required this.bentuk,
    required this.nomor,
    required this.selesai,
    required this.padaTap,
  });

  final double diameter;
  final String ikon;
  final bool bentuk;
  final int nomor;
  final bool selesai;
  final VoidCallback padaTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: kNamaMisi[nomor],
      child: GestureDetector(
        onTap: () {
          Audio.i.sfx('pop');
          padaTap();
        },
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
                child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Palet.putih,
                border: Border.all(color: Palet.garis, width: 8),
                boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 10, offset: Offset(0, 6))],
              ),
              padding: EdgeInsets.all(diameter * 0.17),
              child: bentuk
                  ? SizedBox.expand(child: CustomPaint(painter: _BentukJembatan()))
                  : Image.asset(ikon, fit: BoxFit.contain),
            )),
            if (selesai)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: diameter * 0.32,
                  height: diameter * 0.32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Palet.kuning,
                    border: Border.all(color: Palet.garis, width: 4),
                  ),
                  child: Icon(Icons.star_rounded, color: Palet.oranye, size: diameter * 0.22),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _BentukJembatan extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide * 0.2;
    void s(Offset c, Color w, Path Function(Offset, double) p) {
      final j = p(c, r);
      canvas.drawPath(j, Paint()..color = w);
      canvas.drawPath(
          j,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.18
            ..strokeJoin = StrokeJoin.round
            ..color = Palet.garis);
    }

    s(Offset(size.width * 0.27, size.height * 0.34), Palet.merah,
        (c, r) => Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    s(Offset(size.width * 0.73, size.height * 0.34), Palet.biru,
        (c, r) => Path()..addRect(Rect.fromCenter(center: c, width: r * 1.7, height: r * 1.7)));
    s(
        Offset(size.width * 0.5, size.height * 0.72),
        Palet.hijau,
        (c, r) => Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r, c.dy + r * 0.8)
          ..lineTo(c.dx - r, c.dy + r * 0.8)
          ..close());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
