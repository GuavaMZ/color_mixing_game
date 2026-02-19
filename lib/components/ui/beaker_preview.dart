import 'dart:math';
import 'package:flutter/material.dart';
import '../../components/gameplay/beaker.dart';

class BeakerPreview extends StatelessWidget {
  final BeakerType type;
  final Color color;
  final double size;
  final double liquidLevel;

  const BeakerPreview({
    super.key,
    required this.type,
    this.color = Colors.cyan,
    this.size = 60,
    this.liquidLevel = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BeakerPreviewPainter(
          type: type,
          color: color,
          liquidLevel: liquidLevel,
        ),
      ),
    );
  }
}

class _BeakerPreviewPainter extends CustomPainter {
  final BeakerType type;
  final Color color;
  final double liquidLevel;

  _BeakerPreviewPainter({
    required this.type,
    required this.color,
    required this.liquidLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _getBeakerPath(size);

    // Glass Paints
    final glassPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Liquid Paints
    final liquidPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // 1. Draw Glass Back
    canvas.drawPath(path, glassPaint);

    // 2. Draw Liquid with Clipping
    canvas.save();
    canvas.clipPath(path);
    final liquidHeight = size.height * liquidLevel;
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - liquidHeight, size.width, liquidHeight),
      liquidPaint,
    );

    // Simple surface line
    final surfaceY = size.height - liquidHeight;
    final surfacePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, surfaceY),
      Offset(size.width, surfaceY),
      surfacePaint,
    );

    canvas.restore();

    // 3. Draw Rim
    canvas.drawPath(path, rimPaint);

    // 4. Subtle Highlight
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, highlightPaint);
  }

  Path _getBeakerPath(Size size) {
    final path = Path();
    final double w = size.width;
    final double h = size.height;

    switch (type) {
      case BeakerType.classic:
      case BeakerType.cylinder:
        final double ellipseHeight = w * 0.15;
        final double actualW = (type == BeakerType.cylinder) ? w * 0.8 : w;
        final double ox = (w - actualW) / 2;

        path.moveTo(ox, ellipseHeight / 2);
        path.lineTo(ox, h - ellipseHeight / 2);
        path.arcTo(
          Rect.fromLTWH(ox, h - ellipseHeight, actualW, ellipseHeight),
          pi,
          -pi,
          false,
        );
        path.lineTo(ox + actualW, ellipseHeight / 2);
        path.arcTo(Rect.fromLTWH(ox, 0, actualW, ellipseHeight), 0, -pi, false);
        path.close();
        break;
      case BeakerType.laboratory:
        path.moveTo(w * 0.35, 0);
        path.lineTo(w * 0.65, 0);
        path.lineTo(w * 0.65, h * 0.35);
        path.cubicTo(w * 0.9, h * 0.45, w, h * 0.8, w * 0.8, h);
        path.lineTo(w * 0.2, h);
        path.cubicTo(0, h * 0.8, w * 0.1, h * 0.45, w * 0.35, h * 0.35);
        path.close();
        break;
      case BeakerType.magicBox:
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, w, h),
            const Radius.circular(8),
          ),
        );
        break;
      case BeakerType.hexagon:
        path.moveTo(w * 0.5, 0);
        path.lineTo(w, h * 0.25);
        path.lineTo(w, h * 0.75);
        path.lineTo(w * 0.5, h);
        path.lineTo(0, h * 0.75);
        path.lineTo(0, h * 0.25);
        path.close();
        break;
      case BeakerType.round:
        double neckW = w * 0.35;
        double sphereR = w / 2;
        path.moveTo((w - neckW) / 2, 0);
        path.lineTo((w + neckW) / 2, 0);
        path.lineTo((w + neckW) / 2, h * 0.35);
        path.arcToPoint(
          Offset((w - neckW) / 2, h * 0.35),
          radius: Radius.circular(sphereR),
          largeArc: true,
          clockwise: true,
        );
        path.close();
        break;
      case BeakerType.diamond:
        path.moveTo(w / 2, 0);
        path.lineTo(w, h * 0.45);
        path.lineTo(w / 2, h);
        path.lineTo(0, h * 0.45);
        path.close();
        break;
      case BeakerType.star:
        final double cx = w / 2;
        final double cy = h / 2;
        final double outerR = w / 2;
        final double innerR = outerR * 0.42;
        const int points = 5;
        for (int i = 0; i < points * 2; i++) {
          final double angle = (pi / points) * i - pi / 2;
          final double r = (i % 2 == 0) ? outerR : innerR;
          if (i == 0) {
            path.moveTo(cx + r * cos(angle), cy + r * sin(angle));
          } else {
            path.lineTo(cx + r * cos(angle), cy + r * sin(angle));
          }
        }
        path.close();
        break;
      case BeakerType.triangle:
        path.moveTo(w / 2, 0);
        path.lineTo(w, h);
        path.lineTo(0, h);
        path.close();
        break;
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _BeakerPreviewPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.color != color ||
        oldDelegate.liquidLevel != liquidLevel;
  }
}
