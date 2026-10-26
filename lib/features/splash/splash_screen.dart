import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';
import 'package:divefriend/core/widgets/app_logo.dart';

/// Layar pembuka: logo muncul dengan efek membal, gelembung naik dari dasar laut, lalu judul
/// dan tagline muncul. Setelah animasi selesai, layar memudar ke layar berikutnya
/// (Login atau Beranda). Tidak memakai Timer, hanya AnimationController.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.next});

  /// Pembuat layar tujuan setelah animasi selesai.
  final WidgetBuilder next;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _pulse;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.45, curve: Curves.elasticOut),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.05, 0.25, curve: Curves.easeOut),
    );
    _pulse = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
    );
    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.65, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.8, curve: Curves.easeOut),
    );
    _controller.addStatusListener(_onStatus);
    _controller.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) => widget.next(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.deepSea),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => CustomPaint(
                  painter: _RisingBubblesPainter(_controller.value),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (context, child) => Container(
                            width: 120 + 100 * _pulse.value,
                            height: 120 + 100 * _pulse.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.mint.withValues(alpha: 0.6 * (1 - _pulse.value)),
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                        FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(31)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x663DEBC8),
                                    blurRadius: 32,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: AppLogo(size: 120),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: const Text(
                        'DiveFriend',
                        style: TextStyle(
                          fontFamily: AppFonts.heading,
                          fontSize: 44,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  FadeTransition(
                    opacity: _taglineFade,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpace.xxl),
                      child: Text(
                        'Selam lebih tenang, mulai dari sini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, height: 1.5, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gelembung yang naik pelan dari dasar layar. Posisi dihitung dari nilai animasi (0 sampai 1),
/// jadi tidak butuh state tambahan.
class _RisingBubblesPainter extends CustomPainter {
  _RisingBubblesPainter(this.progress);

  final double progress;

  static const List<List<double>> _bubbles = [
    // x (0..1), jari-jari, kecepatan, awal fase
    [0.12, 7, 1.0, 0.0],
    [0.28, 12, 0.7, 0.3],
    [0.45, 5, 1.3, 0.55],
    [0.62, 10, 0.9, 0.15],
    [0.78, 6, 1.2, 0.7],
    [0.9, 14, 0.6, 0.4],
    [0.2, 5, 1.1, 0.85],
    [0.7, 8, 0.8, 0.95],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..color = const Color(0x40FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fill = Paint()..color = const Color(0x14FFFFFF);
    for (final bubble in _bubbles) {
      final cycle = (progress * bubble[2] + bubble[3]) % 1.0;
      final y = size.height * (1.1 - 1.3 * cycle);
      final x = size.width * bubble[0] + math.sin(cycle * math.pi * 3) * 10;
      final center = Offset(x, y);
      canvas.drawCircle(center, bubble[1], fill);
      canvas.drawCircle(center, bubble[1], ring);
    }
  }

  @override
  bool shouldRepaint(covariant _RisingBubblesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
