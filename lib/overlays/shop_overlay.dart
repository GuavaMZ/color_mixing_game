import 'dart:ui';
import 'package:color_mixing_deductive/components/beaker.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../color_mixer_game.dart';

class ShopItemData {
  final String nameKey;
  final int price;
  final BeakerType type;
  final IconData icon;

  const ShopItemData({
    required this.nameKey,
    required this.price,
    required this.type,
    required this.icon,
  });
}

class ShopOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const ShopOverlay({super.key, required this.game});

  @override
  State<ShopOverlay> createState() => _ShopOverlayState();
}

class _ShopOverlayState extends State<ShopOverlay> {
  static const List<ShopItemData> _shopItems = [
    ShopItemData(
      nameKey: AppStrings.beakerClassic,
      price: 0,
      type: BeakerType.classic,
      icon: Icons.science_outlined,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerFlask,
      price: 5,
      type: BeakerType.laboratory,
      icon: Icons.science_rounded,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerMagic,
      price: 15,
      type: BeakerType.magicBox,
      icon: Icons.inventory_2_rounded,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerHex,
      price: 25,
      type: BeakerType.hexagon,
      icon: Icons.hexagon_rounded,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerCylinder,
      price: 40,
      type: BeakerType.cylinder,
      icon: Icons.view_agenda_rounded,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerRound,
      price: 60,
      type: BeakerType.round,
      icon: Icons.circle_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blur background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(gradient: AppTheme.cosmicBackground),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: AnimatedBuilder(
                    animation: widget.game,
                    builder: (context, child) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 20,
                              childAspectRatio: 0.8,
                            ),
                        itemCount: _shopItems.length,
                        itemBuilder: (context, index) {
                          final item = _shopItems[index];
                          return ShopItemCard(game: widget.game, item: item);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () {
              AudioManager().playButton();
              widget.game.overlays.remove('Shop');
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Hero(
              tag: 'shop_title',
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: AppTheme.cosmicGlass(
                  borderRadius: 16,
                  borderColor: AppTheme.neonCyan.withValues(alpha: 0.3),
                ),
                child: Text(
                  AppStrings.shopTitle.getString(context),
                  textAlign: TextAlign.center,
                  style: AppTheme.heading2(
                    context,
                  ).copyWith(fontSize: 24, color: AppTheme.neonCyan),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildStarsDisplay(),
        ],
      ),
    );
  }

  Widget _buildStarsDisplay() {
    return AnimatedBuilder(
      animation: widget.game,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: AppTheme.cosmicGlass(
            borderRadius: 16,
            borderColor: AppTheme.electricYellow.withValues(alpha: 0.5),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.star_rounded,
                color: AppTheme.electricYellow,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                "${widget.game.totalStars}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  shadows: [
                    Shadow(color: AppTheme.electricYellow, blurRadius: 10),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppTheme.cosmicGlass(
        borderRadius: 15,
        borderColor: Colors.white.withValues(alpha: 0.2),
        isInteractive: true,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

class ShopItemCard extends StatelessWidget {
  final ColorMixerGame game;
  final ShopItemData item;

  const ShopItemCard({super.key, required this.game, required this.item});

  @override
  Widget build(BuildContext context) {
    final bool isUnlocked = game.unlockedSkins.contains(item.type);
    final bool isSelected = game.beaker.type == item.type;
    final bool canAfford = game.totalStars >= item.price;
    final Color itemColor = isSelected
        ? AppTheme.neonCyan
        : isUnlocked
        ? AppTheme.neonMagenta
        : Colors.grey;

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: AppTheme.cosmicCard(
          borderRadius: 24,
          fillColor: isSelected
              ? AppTheme.neonCyan.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderColor: isSelected
              ? AppTheme.neonCyan
              : isUnlocked
              ? AppTheme.neonMagenta.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          hasGlow: isSelected,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? (isSelected
                          ? AppTheme.neonCyan.withValues(alpha: 0.15)
                          : AppTheme.neonMagenta.withValues(alpha: 0.05))
                    : Colors.black.withValues(alpha: 0.3),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.neonCyan.withValues(alpha: 0.4),
                          blurRadius: 20,
                        ),
                      ]
                    : [],
                border: Border.all(
                  color: isSelected
                      ? AppTheme.neonCyan.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(item.icon, size: 40, color: itemColor),
            ),
            const SizedBox(height: 16),
            Text(
              item.nameKey.getString(context),
              style: AppTheme.bodyMedium(context).copyWith(
                color: isSelected ? AppTheme.neonCyan : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildActionLabel(context, isUnlocked, canAfford, isSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildActionLabel(
    BuildContext context,
    bool isUnlocked,
    bool canAfford,
    bool isSelected,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isUnlocked
            ? (isSelected
                  ? AppTheme.neonCyan
                  : AppTheme.primaryLight.withValues(alpha: 0.5))
            : (canAfford
                  ? AppTheme.success.withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? (isSelected
                    ? AppTheme.neonCyan
                    : AppTheme.neonMagenta.withValues(alpha: 0.3))
              : (canAfford
                    ? AppTheme.success.withValues(alpha: 0.5)
                    : Colors.red.withValues(alpha: 0.3)),
        ),
      ),
      child: Text(
        isUnlocked
            ? (isSelected
                  ? AppStrings.selected.getString(context)
                  : AppStrings.select.getString(context))
            : "${item.price} 🌟",
        style: TextStyle(
          color: isUnlocked
              ? (isSelected ? Colors.black : Colors.white)
              : (canAfford ? AppTheme.success : Colors.redAccent),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    AudioManager().playButton();
    final bool isUnlocked = game.unlockedSkins.contains(item.type);
    final bool isSelected = game.beaker.type == item.type;
    final bool canAfford = game.totalStars >= item.price;

    if (isUnlocked) {
      if (!isSelected) {
        game.buyOrSelectSkin(item.type, item.price);
      }
    } else {
      if (canAfford) {
        game.buyOrSelectSkin(item.type, item.price);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unlocked ${item.nameKey.getString(context)}!',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: AppTheme.neonCyan,
            duration: const Duration(milliseconds: 1500),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Not enough stars! Win more levels.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
    }
  }
}
