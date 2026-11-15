import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/audio.dart';
import 'core/konstanta.dart';
import 'core/teks.dart';
import 'ui/splash.dart';

class KeretaApp extends StatefulWidget {
  const KeretaApp({super.key});

  @override
  State<KeretaApp> createState() => _KeretaAppState();
}

class _KeretaAppState extends State<KeretaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      Audio.i.lanjut();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      Audio.i.jeda();
    }
  }

  @override
  Widget build(BuildContext context) => bungkusApp(const Splash());
}

/// Konfigurasi MaterialApp produksi (bahasa Indonesia lengkap). Dipakai juga oleh tes
/// supaya masalah lokalisasi (mis. "No MaterialLocalizations found") tertangkap.
Widget bungkusApp(Widget home) {
  return MaterialApp(
    title: Teks.namaApp,
    debugShowCheckedModeBanner: false,
    locale: const Locale('id'),
    supportedLocales: const [Locale('id')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Palet.biru),
    home: home,
  );
}
