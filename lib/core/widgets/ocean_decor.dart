import 'package:flutter/material.dart';

import 'package:divefriend/core/app_theme.dart';

/// Tepi bergelombang untuk menyambung foto atau header laut ke panel putih di bawahnya.
/// Letakkan di dasar sebuah Stack (Positioned left 0, right 0, bottom 0).
class WaveEdge extends StatelessWidget {
  const WaveEdge({super.key, this.color = AppColors.background, this.height = 34});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _WavePainter(color)),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.55)
      ..cubicTo(w * 0.12, h * 0.05, w * 0.25, h * 0.05, w * 0.33, h * 0.5)
      ..cubicTo(w * 0.42, h * 0.95, w * 0.55, h * 0.95, w * 0.66, h * 0.45)
      ..cubicTo(w * 0.77, 0, w * 0.9, h * 0.1, w, h * 0.5)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => oldDelegate.color != color;
}

/// Header laut dalam: gradasi biru tua, gelembung halus, sudut bawah membulat.
/// Otomatis memberi ruang untuk status bar di bagian atas.
class OceanHeader extends StatelessWidget {
  const OceanHeader({
    super.key,
    required this.child,
    this.bottomRadius = 32,
    this.bottomPadding = 24,
  });

  final Widget child;
  final double bottomRadius;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppGradients.deepSea,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(bottomRadius)),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _BubblePainter())),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top + 16, 20, bottomPadding),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = const Color(0x14FFFFFF);
    final ring = Paint()
      ..color = const Color(0x26FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(size.width * 0.86, size.height * 0.22), 46, fill);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.62), 14, ring);
    canvas.drawCircle(Offset(size.width * 0.93, size.height * 0.7), 8, ring);
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.82), 22, fill);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.15), 6, ring);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => false;
}
