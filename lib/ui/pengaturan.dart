import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/konstanta.dart';
import '../core/penyimpanan.dart';
import '../core/teks.dart';

/// Pengaturan untuk orang tua (dibuka lewat gerbang tahan 3 detik).
class Pengaturan extends StatelessWidget {
  const Pengaturan({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Penyimpanan.i;
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBFF),
      appBar: AppBar(
        backgroundColor: Palet.biru,
        foregroundColor: Colors.white,
        title: const Text('Pengaturan orang tua', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: s,
          builder: (context, _) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(padding: const EdgeInsets.all(16), children: [
                const _Judul('Suara'),
                SwitchListTile(
                  title: const Text('Suara pemandu (bahasa Indonesia)'),
                  subtitle: const Text('Suara yang menjelaskan misi dan menghitung'),
                  value: s.suaraPemandu,
                  onChanged: (v) => _ubah(s.aturBool('suaraPemandu', v)),
                ),
                SwitchListTile(
                  title: const Text('Musik latar'),
                  value: s.musikAktif,
                  onChanged: (v) => _ubah(s.aturBool('musikAktif', v), musik: true),
                ),
                SwitchListTile(
                  title: const Text('Efek suara'),
                  value: s.efekAktif,
                  onChanged: (v) => _ubah(s.aturBool('efekAktif', v)),
                ),
                ListTile(
                  title: const Text('Volume utama'),
                  subtitle: Slider(
                    value: s.volumeUtama,
                    min: 0.1,
                    onChanged: (v) => _ubah(s.aturDouble('volumeUtama', v), musik: true),
                    onChangeEnd: (_) => Audio.i.sfx('ding'),
                  ),
                ),
                ListTile(
                  title: const Text('Volume musik'),
                  subtitle: Slider(
                    value: s.volumeMusik,
                    onChanged: (v) => _ubah(s.aturDouble('volumeMusik', v), musik: true),
                  ),
                ),
                const _Judul('Permainan'),
                SwitchListTile(
                  title: const Text('Mode otomatis'),
                  subtitle: const Text('Kereta jalan sendiri; anak hanya membunyikan peluit dan memilih. '
                      'Cocok untuk anak yang masih sangat kecil.'),
                  value: s.otomatis,
                  onChanged: (v) => _ubah(s.aturBool('otomatis', v)),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Hapus semua stiker'),
                  subtitle: Text('Sekarang: ${s.stiker.length} dari 12 stiker'),
                  onTap: () => _konfirmasiHapus(context, s),
                ),
                const _Judul('Informasi'),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Kebijakan privasi'),
                  onTap: () => _dialog(context, 'Kebijakan privasi', Teks.privasi),
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Tentang Kereta Api'),
                  subtitle: Text('Versi ${Teks.versi}'),
                  onTap: () => _dialog(context, 'Tentang', '${Teks.tentang}\n\n${Teks.saranWaktu}'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  void _ubah(Future<void> f, {bool musik = false}) {
    f.then((_) {
      if (musik) Audio.i.terapkanPengaturan();
    });
  }

  Future<void> _konfirmasiHapus(BuildContext context, Penyimpanan s) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus semua stiker?'),
        content: const Text('Stiker yang sudah dikumpulkan anak akan hilang.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ya == true) await s.hapusStiker();
  }

  void _dialog(BuildContext context, String judul, String isi) {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(judul),
        content: SingleChildScrollView(child: Text(isi)),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup'))],
      ),
    );
  }
}

class _Judul extends StatelessWidget {
  const _Judul(this.teks);
  final String teks;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(teks.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w900, color: Palet.biru, letterSpacing: 1)),
      );
}
