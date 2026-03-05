import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/core/card_collection_manager.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';

class CardCollectionOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const CardCollectionOverlay({super.key, required this.game});

  @override
  State<CardCollectionOverlay> createState() => _CardCollectionOverlayState();
}

class _CardCollectionOverlayState extends State<CardCollectionOverlay>
    with SingleTickerProviderStateMixin {
  CardDef? _selectedCard;
  bool _isFlipped = false;

  late AnimationController _pulseController;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulse = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _close() {
    AudioManager().playButton();
    widget.game.returnToMainMenu();
  }

  void _selectCard(CardDef def) {
    if (!CardCollectionManager.instance.isUnlocked(def.id)) {
      AudioManager().playError();
      return; // Locked
    }
    AudioManager().playButton();
    setState(() {
      _selectedCard = def;
      _isFlipped = false;
    });
  }

  void _closePreview() {
    AudioManager().playButton();
    setState(() {
      _selectedCard = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background Dim
          Container(color: Colors.black.withValues(alpha: 0.9)),

          Column(
            children: [
              // Header
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ALCHEMY COLLECTION",
                            style: AppTheme.heading2(context).copyWith(
                              color: AppTheme.electricYellow,
                              fontSize: 28,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            "${CardCollectionManager.instance.unlockedIds.length} / ${CardCatalog.allCards.length} Colors Discovered",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: _close,
                      ),
                    ],
                  ),
                ),
              ),

              // Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 140,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: CardCatalog.allCards.length,
                    itemBuilder: (context, index) {
                      final def = CardCatalog.allCards[index];
                      return _buildGridCard(def);
                    },
                  ),
                ),
              ),
            ],
          ),

          // Detail Modal
          if (_selectedCard != null) _buildDetailModal(),
        ],
      ),
    );
  }

  Widget _buildGridCard(CardDef def) {
    bool isUnlocked = CardCollectionManager.instance.isUnlocked(def.id);

    // Base colors
    final colors = _getRarityColors(def.rarity);

    if (!isUnlocked) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: const Center(
          child: Icon(Icons.lock_outline, color: Colors.white24, size: 32),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _selectCard(def),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final isLegendary = def.rarity == CardRarity.legendary;
          return Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colors.first.withValues(alpha: 0.8),
                width: 2,
              ),
              boxShadow: isLegendary
                  ? [
                      BoxShadow(
                        color: colors.first.withValues(
                          alpha: 0.4 * _pulse.value,
                        ),
                        blurRadius: 15 * _pulse.value,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
              gradient: LinearGradient(
                colors: [
                  colors.first.withValues(alpha: 0.1),
                  def.color.withValues(alpha: 0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: def.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6, right: 6, bottom: 8),
                  child: Text(
                    def.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailModal() {
    final def = _selectedCard!;
    final colors = _getRarityColors(def.rarity);

    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: _closePreview,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black54),
          ),
        ),

        // Huge Card Centered
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (ctx, val, child) =>
                Transform.scale(scale: val, child: child),
            child: GestureDetector(
              onTap: () {
                AudioManager().playButton();
                setState(() => _isFlipped = !_isFlipped);
              },
              child: Container(
                width: 320,
                height: 480,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colors.first.withValues(alpha: 0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                  border: Border.all(color: colors.first, width: 3),
                  color: AppTheme.primaryDark,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: _isFlipped
                      ? _buildBackside(def)
                      : _buildFrontside(def, colors),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrontside(CardDef def, List<Color> colors) {
    return Column(
      children: [
        // Top banner (Rarity)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
          child: Text(
            def.rarity.name.toUpperCase(),
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
              color: def.color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24, width: 2),
              boxShadow: [
                BoxShadow(
                  color: def.color.withValues(alpha: 0.5),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
        ),

        // Name & Hex
        Container(
          padding: const EdgeInsets.all(24),
          width: double.infinity,
          color: Colors.black54,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                def.name,
                style: AppTheme.heading2(
                  context,
                ).copyWith(color: Colors.white, fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                def.hexColor.toUpperCase(),
                style: AppTheme.bodyMedium(context).copyWith(
                  color: colors.first,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackside(CardDef def) {
    return Container(
      color: AppTheme.primaryDark,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, color: AppTheme.electricYellow, size: 64),
          const SizedBox(height: 32),
          Text(
            def.description,
            style: AppTheme.bodyMedium(
              context,
            ).copyWith(color: Colors.white, fontSize: 18, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
}
