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
      price: 250,
      type: BeakerType.laboratory,
      icon: Icons.science_rounded,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerMagic,
      price: 500,
      type: BeakerType.magicBox,
      icon: Icons.inventory_2_rounded,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerHex,
      price: 1000,
      type: BeakerType.hexagon,
      icon: Icons.hexagon_rounded,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerCylinder,
      price: 1500,
      type: BeakerType.cylinder,
      icon: Icons.view_agenda_rounded,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerRound,
      price: 2500,
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
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.backgroundGradient,
                ),
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
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryGradient.colors.first.withValues(
                        alpha: 0.08,
                      ),
                      AppTheme.primaryGradient.colors.last.withValues(
                        alpha: 0.08,
                      ),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    width: 2,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGradient.colors.first.withValues(
                        alpha: 0.2,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  decoration: AppTheme.cosmicCard(
                    borderRadius: 16,
                    fillColor: AppTheme.primaryMedium.withValues(alpha: 0.5),
                    borderColor: Colors.transparent,
                    hasGlow: false,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    AppStrings.shopTitle.getString(context),
                    textAlign: TextAlign.center,
                    style: AppTheme.heading2(context).copyWith(
                      fontSize: 24,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildCoinsDisplay(),
        ],
      ),
    );
  }

  Widget _buildCoinsDisplay() {
    return AnimatedBuilder(
      animation: widget.game.totalCoins,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                AppTheme.secondaryGradient.colors.first.withValues(alpha: 0.08),
                AppTheme.secondaryGradient.colors.last.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              width: 2,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryGradient.colors.first.withValues(
                  alpha: 0.2,
                ),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            decoration: AppTheme.cosmicCard(
              borderRadius: 16,
              fillColor: AppTheme.primaryMedium.withValues(alpha: 0.5),
              borderColor: Colors.transparent,
              hasGlow: false,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.monetization_on_rounded, // Coin icon
                  color: Colors.amber,
                  size: 24,
                  shadows: [
                    Shadow(
                      color: Colors.amber.withValues(alpha: 0.6),
                      blurRadius: 10,
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Text(
                  "${widget.game.totalCoins.value}",
                  style: AppTheme.buttonText(context, isLarge: true).copyWith(
                    color: Colors.white,
                    fontSize: 22,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          width: 1.5,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                ),
              ],
            ),
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
    final bool canAfford = game.totalCoins.value >= item.price;
    final Color itemColor = isSelected
        ? AppTheme.neonCyan
        : isUnlocked
        ? Colors.greenAccent
        : Colors.white.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              (isSelected
                      ? AppTheme.neonCyan
                      : AppTheme.primaryGradient.colors.first)
                  .withValues(alpha: 0.08),
              (isSelected
                      ? AppTheme.neonCyan
                      : AppTheme.primaryGradient.colors.last)
                  .withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            width: 2,
            color: isSelected
                ? AppTheme.neonCyan
                : isUnlocked
                ? Colors.greenAccent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.15),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.neonCyan.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Container(
          decoration: AppTheme.cosmicCard(
            borderRadius: 24,
            fillColor: isSelected
                ? AppTheme.neonCyan.withValues(alpha: 0.15)
                : isUnlocked
                ? Colors.greenAccent.withValues(alpha: 0.08)
                : AppTheme.primaryMedium.withValues(alpha: 0.5),
            borderColor: Colors.transparent,
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
                            ? AppTheme.neonCyan.withValues(alpha: 0.2)
                            : Colors.greenAccent.withValues(alpha: 0.1))
                      : Colors.black.withValues(alpha: 0.4),
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
                style: AppTheme.buttonText(context).copyWith(
                  color: Colors.white,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildActionLabel(context, isUnlocked, canAfford, isSelected),
            ],
          ),
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
                  ? AppTheme.neonCyan.withValues(alpha: 0.3)
                  : Colors.greenAccent.withValues(alpha: 0.15))
            : (canAfford
                  ? AppTheme.success.withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? (isSelected
                    ? AppTheme.neonCyan
                    : Colors.greenAccent.withValues(alpha: 0.6))
              : (canAfford
                    ? AppTheme.success.withValues(alpha: 0.4)
                    : Colors.red.withValues(alpha: 0.4)),
        ),
      ),
      child: Text(
        isUnlocked
            ? (isSelected ? "SELECTED" : "SELECT")
            : "${item.price} COINS",
        style: AppTheme.buttonText(context).copyWith(
          fontSize: 12,
          color: isUnlocked
              ? (isSelected ? AppTheme.neonCyan : Colors.greenAccent)
              : (canAfford ? AppTheme.success : Colors.redAccent),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    AudioManager().playButton();
    final bool isUnlocked = game.unlockedSkins.contains(item.type);
    final bool isSelected = game.beaker.type == item.type;
    final bool canAfford = game.totalCoins.value >= item.price;

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
              'Not enough coins! Win more levels.',
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
