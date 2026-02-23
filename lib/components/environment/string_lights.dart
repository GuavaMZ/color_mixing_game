import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../core/lab_catalog.dart';
import '../../../color_mixer_game.dart';

class StringLights extends PositionComponent with HasGameRef<ColorMixerGame> {
  LabItem? currentConfig;
  double _time = 0;

  // Basic properties
  Color wireColor = Colors.transparent;
  List<Color> bulbColors = [];
  bool isGlowing = false;
  bool isPulsing = false;

  // Pre-calculated bulb positions for performance
  final List<Offset> _bulbPositions = [];
  final Path _wirePath = Path();

  StringLights({required Vector2 size, this.currentConfig})
    : super(position: Vector2.zero()) {
    this.size = size;
    priority =
        5; // Render in front of pattern background but behind UI overlays
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _calculateWireAndBulbs();
    _applyConfig(currentConfig);
  }

  void updateConfig(LabItem? config) {
    if (currentConfig?.id == config?.id) return;
    currentConfig = config;
    _applyConfig(config);
  }

  void _applyConfig(LabItem? config) {
    if (config == null || config.id == 'lights_none') {
      wireColor = Colors.transparent;
      bulbColors = [];
      isGlowing = false;
      isPulsing = false;
      return;
    }

    // Config defaults
    wireColor = Colors.black87;
    isGlowing = true;

    switch (config.id) {
      case 'lights_warm':
        bulbColors = [const Color(0xFFFFD54F)];
        isPulsing = false;
        break;
      case 'lights_neon':
        bulbColors = [const Color(0xFF00FFFF), const Color(0xFFFF00FF)];
        isPulsing = false;
        break;
      case 'lights_bio':
        bulbColors = [const Color(0xFF00FF00), const Color(0xFFB2FF59)];
        isPulsing = true;
        break;
      case 'lights_starlight':
        wireColor = Colors.white24; // Ghostly wire
        bulbColors = [const Color(0xFFFFFFFF), const Color(0xFFE3F2FD)];
        isPulsing = true;
        break;
      default:
        // Fallback to config gradient if any
        if (config.gradientColors.isNotEmpty) {
          bulbColors = config.gradientColors;
          isPulsing = false;
        } else {
          wireColor = Colors.transparent;
          bulbColors = [];
        }
    }
  }

  void _calculateWireAndBulbs() {
    _wirePath.reset();
    _bulbPositions.clear();

    final double w = size.x;

    // We drape a quadratic bezier curve across the top
    final double startY = 10;
    final double endY = 20;
    final double controlY = 120; // sag amount

    _wirePath.moveTo(0, startY);
    _wirePath.quadraticBezierTo(w / 2, controlY, w, endY);

    // Calculate roughly evenly spaced points along the curve for the bulbs
    const int numBulbs = 10;
    for (int i = 1; i <= numBulbs; i++) {
      double t = i / (numBulbs + 1);

      // Quadratic Bezier formula: P(t) = (1-t)^2 * P0 + 2(1-t)t * P1 + t^2 * P2
      double x = pow(1 - t, 2) * 0 + 2 * (1 - t) * t * (w / 2) + pow(t, 2) * w;
      double y =
          pow(1 - t, 2) * startY +
          2 * (1 - t) * t * controlY +
          pow(t, 2) * endY;

      _bulbPositions.add(Offset(x, y));
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    _calculateWireAndBulbs();
  }

  // Force re-calculate if size changes dynamically
  void _checkDimensions() {
    if (gameRef.size.x != size.x) {
      size = Vector2(gameRef.size.x, 200);
      _calculateWireAndBulbs();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _checkDimensions();

    if (bulbColors.isEmpty) return;
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (bulbColors.isEmpty) return;

    // Draw Wire
    final Paint wirePaint = Paint()
      ..color = wireColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawPath(_wirePath, wirePaint);

    // Draw Bulbs
    if (_bulbPositions.isEmpty) return;

    for (int i = 0; i < _bulbPositions.length; i++) {
      final pos = _bulbPositions[i];
      final baseColor = bulbColors[i % bulbColors.length];

      // Calculate dynamic effects
      double bulbIntensity = 1.0;
      double radiusMultiplier = 1.0;

      if (isPulsing) {
        // Offset time by bulb index to create a wave or twinkling effect
        final double offset = i * 0.5;
        bulbIntensity = 0.6 + 0.4 * sin(_time * 2 + offset);

        // Starlight twinkles faster and sharper
        if (currentConfig?.id == 'lights_starlight') {
          bulbIntensity = 0.3 + 0.7 * pow(sin(_time * 4 + offset * 3), 2);
          radiusMultiplier = 0.5 + 0.5 * bulbIntensity;
        }
      }

      final Color displayColor = baseColor.withValues(alpha: bulbIntensity);

      // Draw outer glow
      if (isGlowing) {
        canvas.drawCircle(
          pos,
          15.0 * radiusMultiplier,
          Paint()
            ..color = displayColor.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }

      // Draw inner bulb
      canvas.drawCircle(
        pos,
        (currentConfig?.id == 'lights_starlight' ? 3.0 : 6.0) *
            radiusMultiplier,
        Paint()..color = Colors.white.withValues(alpha: 0.9),
      );

      // Draw bulb base/socket connecting to wire
      if (currentConfig?.id != 'lights_starlight') {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(pos.dx, pos.dy - 6),
            width: 6,
            height: 6,
          ),
          Paint()..color = wireColor.withValues(alpha: 0.8),
        );
      }
    }
  }
}
