import 'dart:ui';
import 'package:color_mixing_deductive/components/beaker.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../color_mixer_game.dart';

class ShopOverlay extends StatelessWidget {
  final ColorMixerGame game;
  const ShopOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent, // Background handled by main game or underlying
      body: Stack(
        children: [
          // Blur background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: AppTheme.primaryDark.withOpacity(0.8)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _buildIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () {
                          AudioManager().playButton();
                          game.overlays.remove('Shop');
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: AppTheme.cosmicGlass(
                            borderRadius: 16,
                            borderColor: AppTheme.neonCyan.withOpacity(0.3),
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
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: AppTheme.cosmicGlass(
                          borderRadius: 16,
                          borderColor: AppTheme.electricYellow.withOpacity(0.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: AppTheme.electricYellow,
                              size: 20,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "${game.totalStars}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Shop Items Grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(20),
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    children: [
                      _shopItem(
                        context,
                        AppStrings.beakerClassic.getString(context),
                        0,
                        BeakerType.classic,
                      ),
                      _shopItem(
                        context,
                        AppStrings.beakerFlask.getString(context),
                        5,
                        BeakerType.laboratory,
                      ),
                      _shopItem(
                        context,
                        AppStrings.beakerMagic.getString(context),
                        15,
                        BeakerType.magicBox,
                      ),
                      _shopItem(
                        context,
                        AppStrings.beakerHex.getString(context),
                        25,
                        BeakerType.hexagon,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shopItem(
    BuildContext context,
    String name,
    int price,
    BeakerType type,
  ) {
    final bool isUnlocked = game.unlockedSkins.contains(type);
    final bool isSelected = game.beaker.type == type;

    return Container(
      decoration: AppTheme.cosmicGlass(
        borderRadius: 24,
        borderColor: isSelected
            ? AppTheme.neonCyan
            : isUnlocked
            ? AppTheme.neonMagenta.withOpacity(0.3)
            : Colors.white.withOpacity(0.1),
        isInteractive: true,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? (isSelected
                        ? AppTheme.neonCyan.withOpacity(0.1)
                        : AppTheme.neonMagenta.withOpacity(0.05))
                  : Colors.black.withOpacity(0.2),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.neonCyan.withOpacity(0.2),
                        blurRadius: 15,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              _getBeakerIcon(type),
              size: 40,
              color: isUnlocked
                  ? (isSelected ? AppTheme.neonCyan : Colors.white)
                  : Colors.grey.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: AppTheme.bodyMedium(context).copyWith(
              color: isSelected ? AppTheme.neonCyan : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              AudioManager().playButton();
              game.buyOrSelectSkin(type, price);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? (isSelected ? AppTheme.neonCyan : AppTheme.primaryLight)
                    : AppTheme.primaryDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUnlocked
                      ? (isSelected
                            ? AppTheme.neonCyan
                            : AppTheme.neonMagenta.withOpacity(0.5))
                      : Colors.grey.withOpacity(0.3),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.neonCyan.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ]
                    : [],
              ),
              child: Text(
                isUnlocked
                    ? (isSelected
                          ? AppStrings.selected.getString(context)
                          : AppStrings.select.getString(context))
                    : "$price 🌟",
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBeakerIcon(BeakerType type) {
    switch (type) {
      case BeakerType.laboratory:
        return Icons.science_rounded;
      case BeakerType.magicBox:
        return Icons.inventory_2_rounded;
      case BeakerType.hexagon:
        return Icons.hexagon_rounded;
      default:
        return Icons.science_outlined;
    }
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppTheme.cosmicGlass(
        borderRadius: 15,
        borderColor: Colors.white.withOpacity(0.2),
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
