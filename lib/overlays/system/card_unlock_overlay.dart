import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/core/card_collection_manager.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';

class CardUnlockOverlay extends StatefulWidget {
  final ColorMixerGame game;
  final CardDef card;

  const CardUnlockOverlay({super.key, required this.game, required this.card});

  @override
  State<CardUnlockOverlay> createState() => _CardUnlockOverlayState();
}

class _CardUnlockOverlayState extends State<CardUnlockOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _glowPulse;

  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    AudioManager().playWin(); // Temp SFX for card unlock

    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _scale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.elasticOut));

    _glowPulse = Tween<double>(
      begin: 0.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOutSine));

    _anim.forward();
    _anim.repeat(reverse: true, min: 0.8, max: 1.0); // Keep pulsing slightly
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _dismiss() {
    AudioManager().playButton();
    widget.game.overlays.remove('CardUnlock');
  }

  void _flip() {
    setState(() {
      _isFlipped = !_isFlipped;
      AudioManager().playButton(); // click
    });
  }

  List<Color> _getRarityColors(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.legendary:
        return [Colors.purpleAccent, Colors.pinkAccent];
      case CardRarity.epic:
        return [Colors.orange, Colors.deepOrange];
      case CardRarity.rare:
        return [AppTheme.neonCyan, Colors.blue];
      case CardRarity.common:
        return [Colors.grey.shade400, Colors.grey.shade700];
    }
  }

  String _getRarityLabel(CardRarity rarity) {
    return rarity.name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final rColors = _getRarityColors(widget.card.rarity);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Darken background
          GestureDetector(
            onTap: _dismiss,
            child: Container(color: Colors.black.withValues(alpha: 0.85)),
          ),

          Center(
            child: ScaleTransition(
              scale: _scale,
              child: GestureDetector(
                onTap: _flip,
                child: AnimatedBuilder(
                  animation: _glowPulse,
                  builder: (context, child) {
                    return Container(
                      width: 280,
                      height: 420,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: rColors.first.withValues(
                              alpha: 0.4 * _glowPulse.value,
                            ),
                            blurRadius: 40 * _glowPulse.value,
                            spreadRadius: 10,
                          ),
                        ],
                        gradient: LinearGradient(
                          colors: [
                            rColors.first.withValues(alpha: 0.2),
                            rColors.last.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: rColors.first.withValues(alpha: 0.8),
                          width: 3,
                        ),
                      ),
                      child: child,
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: _isFlipped ? _buildBack() : _buildFront(rColors),
                  ),
                ),
              ),
            ),
          ),

          // Confetti overlay could go here

          // Header Close Button
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 36),
              onPressed: _dismiss,
            ),
          ),

          // Header
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 1),
              curve: Curves.easeOutCubic,
              builder: (ctx, val, child) => Opacity(
                opacity: val,
                child: Transform.translate(
                  offset: Offset(0, 50 * (1 - val)),
                  child: Column(
                    children: [
                      Text(
                        "NEW COLOR DISCOVERED!",
                        style: AppTheme.heading2(context).copyWith(
                          color: AppTheme.electricYellow,
                          fontSize: 24,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Tap the card to read its history",
                        style: AppTheme.bodySmall(
                          context,
                        ).copyWith(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFront(List<Color> rColors) {
    return Column(
      children: [
        // Top banner (Rarity)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(gradient: LinearGradient(colors: rColors)),
          child: Text(
            _getRarityLabel(widget.card.rarity),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),

        // Color Swatch
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.card.color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24, width: 2),
              boxShadow: [
                BoxShadow(
                  color: widget.card.color.withValues(alpha: 0.5),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
        ),

        // Name & Hex
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          color: Colors.black45,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.card.name,
                style: AppTheme.heading2(
                  context,
                ).copyWith(color: Colors.white, fontSize: 28),
              ),
              const SizedBox(height: 4),
              Text(
                widget.card.hexColor.toUpperCase(),
                style: AppTheme.bodyMedium(context).copyWith(
                  color: rColors.first,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBack() {
    return Container(
      color: AppTheme.primaryDark,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, color: AppTheme.electricYellow, size: 48),
          const SizedBox(height: 24),
          Text(
            widget.card.description,
            style: AppTheme.bodyMedium(
              context,
            ).copyWith(color: Colors.white, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
