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
    final w = size.width;
    final h = size.height;

    // 1. Refined Glass Shaders (Volumetric)
    final glassFrontPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.05),
          Colors.transparent,
          Colors.black.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.2),
        ],
        stops: const [0.0, 0.15, 0.5, 0.85, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final glassBackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02;

    // 2. Liquid Volume with Depth
    final liquidPaint = Paint()
      ..shader =
          RadialGradient(
            center: const Alignment(0.0, -0.5),
            radius: 1.5,
            colors: [
              color.withValues(alpha: 0.9),
              color.withValues(alpha: 0.95),
              color.withValues(alpha: 1.0),
            ],
            stops: const [0.0, 0.7, 1.0],
          ).createShader(
            Rect.fromLTWH(0, h * (1 - liquidLevel), w, h * liquidLevel),
          );

    // 1. Draw Glass Back
    canvas.drawPath(path, glassBackPaint);

    // 2. Draw Liquid with Clipping
    if (liquidLevel > 0.01) {
      canvas.save();
      canvas.clipPath(path);
      final liquidHeight = h * liquidLevel;
      final surfaceY = h - liquidHeight;

      canvas.drawRect(Rect.fromLTWH(0, surfaceY, w, liquidHeight), liquidPaint);

      // Refined surface line (meniscus)
      final surfacePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(0, surfaceY), Offset(w, surfaceY), surfacePaint);
      canvas.restore();
    }

    // 3. Draw Front Glass and Rim
    canvas.drawPath(path, glassFrontPaint);
    canvas.drawPath(path, rimPaint);

    // 4. Sharp Highlights
    canvas.save();
    canvas.clipPath(path);

    // Left gleam
    final leftRect = Rect.fromLTWH(w * 0.08, 0, w * 0.12, h);
    canvas.drawRect(
      leftRect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.4), Colors.transparent],
        ).createShader(leftRect),
    );

    // Top catch light
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.1),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.2), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.1)),
    );

    canvas.restore();
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
        final double nx = w * 0.3; // neck x offset (40% width overall)
        final double wx = w; // max width
        final double bx = w * 0.2; // base x offset (60% width overall)

        path.moveTo(nx, 0); // Top left
        path.lineTo(w - nx, 0); // Top right
        path.lineTo(w - nx, h * 0.1); // Neck right down
        path.lineTo(wx, h * 0.65); // Flare right down to max width
        path.lineTo(w - bx, h); // Taper right down to base
        path.lineTo(bx, h); // Base width
        path.lineTo(0, h * 0.65); // Taper left up to max width
        path.lineTo(nx, h * 0.1); // Flare left up to neck
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
        // Faceted Diamond Flask (standing)
        final double nx = w * 0.35; // Neck inset (30% width)
        final double bx = w * 0.40; // Base inset (20% width)

        path.moveTo(nx, 0); // Top left
        path.lineTo(w - nx, 0); // Top right
        path.lineTo(w - nx, h * 0.15); // Neck straight down
        path.lineTo(w, h * 0.45); // Flare right out
        path.lineTo(w - bx, h); // Taper down to base right
        path.lineTo(bx, h); // Base flat
        path.lineTo(0, h * 0.45); // Taper up to base left
        path.lineTo(nx, h * 0.15); // Flare in to neck
        path.close();
        break;
      case BeakerType.star:
        // Stylized 4-Point Mystic Vessel
        final double cx = w / 2;

        final double neckW = w * 0.25;
        final double shoulderW = w * 0.95;
        final double waistW = w * 0.40;
        final double baseW = w * 0.85;

        final double neckY = h * 0.15;
        final double shoulderY = h * 0.40;
        final double waistY = h * 0.60;
        final double baseY = h * 0.95;

        path.moveTo(cx - (neckW / 2), 0); // Top left rim
        path.lineTo(cx + (neckW / 2), 0); // Top right rim
        path.lineTo(cx + (neckW / 2), neckY); // Neck right down
        path.cubicTo(
          cx + (neckW / 2),
          neckY + (shoulderY - neckY) * 0.5, // c1
          cx + (shoulderW / 2),
          shoulderY - (shoulderY - neckY) * 0.5, // c2
          cx + (shoulderW / 2),
          shoulderY, // Right top point
        );
        path.cubicTo(
          cx + (shoulderW / 2),
          shoulderY + (waistY - shoulderY) * 0.5,
          cx + (waistW / 2),
          waistY - (waistY - shoulderY) * 0.5,
          cx + (waistW / 2),
          waistY, // Inner right corner
        );
        path.cubicTo(
          cx + (waistW / 2),
          waistY + (baseY - waistY) * 0.5,
          cx + (baseW / 2),
          baseY - (baseY - waistY) * 0.5,
          cx + (baseW / 2),
          baseY, // Right bottom point
        );
        path.cubicTo(
          cx + (baseW / 2),
          baseY + (h - baseY) * 0.5,
          cx,
          h,
          cx,
          h, // Absolute bottom tip
        );

        // Mirror for left side
        path.cubicTo(
          cx,
          h,
          cx - (baseW / 2),
          baseY + (h - baseY) * 0.5,
          cx - (baseW / 2),
          baseY, // Left bottom point
        );
        path.cubicTo(
          cx - (baseW / 2),
          baseY - (baseY - waistY) * 0.5,
          cx - (waistW / 2),
          waistY + (baseY - waistY) * 0.5,
          cx - (waistW / 2),
          waistY, // Inner left corner
        );
        path.cubicTo(
          cx - (waistW / 2),
          waistY - (waistY - shoulderY) * 0.5,
          cx - (shoulderW / 2),
          shoulderY + (waistY - shoulderY) * 0.5,
          cx - (shoulderW / 2),
          shoulderY, // Left top point
        );
        path.cubicTo(
          cx - (shoulderW / 2),
          shoulderY - (shoulderY - neckY) * 0.5,
          cx - (neckW / 2),
          neckY + (shoulderY - neckY) * 0.5,
          cx - (neckW / 2),
          neckY, // Neck left down
        );
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
