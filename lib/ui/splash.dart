import 'dart:async';

import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/konstanta.dart';
import 'beranda.dart';
import 'widgets.dart';

/// Layar pembuka: logo, menyiapkan audio, lalu masuk ke beranda.
class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void initState() {
    super.initState();
    unawaited(_mulai());
  }

  Future<void> _mulai() async {
    await Future.wait([
      Audio.i.siapkan(),
      Future<void>.delayed(const Duration(milliseconds: 2200)),
    ]);
    if (!mounted) return;
    unawaited(Audio.i.musikMulai('menu'));
    Navigator.of(context).pushReplacement(rutePudar(const Beranda()));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palet.langit,
      body: Center(
        child: ScaleTransition(
          scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
          child: FractionallySizedBox(
            heightFactor: 0.72,
            child: Image.asset(
              'assets/brand/splash_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => Image.asset('assets/brand/logo.png'),
            ),
          ),
        ),
      ),
    );
  }
}
