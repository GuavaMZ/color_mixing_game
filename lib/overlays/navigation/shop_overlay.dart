import 'dart:ui';
import 'package:color_mixing_deductive/components/gameplay/beaker.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/visual_effects.dart';
import 'package:color_mixing_deductive/components/ui/animated_card.dart';
import 'package:color_mixing_deductive/components/ui/responsive_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../../../color_mixer_game.dart';

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

class HelperItemData {
  final String id;
  final String nameKey;
  final String descKey;
  final int price;
  final int amount;
  final IconData icon;
  final Color color;

  const HelperItemData({
    required this.id,
    required this.nameKey,
    required this.descKey,
    required this.price,
    required this.amount,
    required this.icon,
    required this.color,
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
      price: 300,
      type: BeakerType.laboratory,
      icon: Icons.science_rounded,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerMagic,
      price: 400,
      type: BeakerType.magicBox,
      icon: Icons.inventory_2_rounded,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerHex,
      price: 800,
      type: BeakerType.hexagon,
      icon: Icons.hexagon_rounded,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerCylinder,
      price: 900,
      type: BeakerType.cylinder,
      icon: Icons.view_agenda_rounded,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerRound,
      price: 1500,
      type: BeakerType.round,
      icon: Icons.circle_outlined,
    ),
  ];

  static const List<HelperItemData> _helperItems = [
    HelperItemData(
      id: 'undo',
      nameKey: AppStrings.undoTitle,
      descKey: AppStrings.undoDesc,
      price: 75,
      amount: 5,
      icon: Icons.undo_rounded,
      color: AppTheme.neonCyan,
    ),
    HelperItemData(
      id: 'extra_drops',
      nameKey: AppStrings.extraDropsTitle,
      descKey: AppStrings.extraDropsDesc,
      price: 200,
      amount: 3,
      icon: Icons.add_circle_outline,
      color: AppTheme.neonMagenta,
    ),
    HelperItemData(
      id: 'help_drop',
      nameKey: AppStrings.helpDropTitle,
      descKey: AppStrings.helpDropDesc,
      price: 350,
      amount: 3,
      icon: Icons.water_drop_outlined,
      color: AppTheme.success,
    ),
    HelperItemData(
      id: 'reveal_color',
      nameKey: AppStrings.revealColorTitle,
      descKey: AppStrings.revealColorDesc,
      price: 500,
      amount: 2,
      icon: Icons.visibility_outlined,
      color: AppTheme.electricYellow,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background with StarField
          const Positioned.fill(
            child: StarField(starCount: 40, color: Colors.white),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 5,
                sigmaY: 5,
              ), // Reduced blur for star visibility
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.backgroundGradient.colors.length > 1
                      ? LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.backgroundGradient.colors.first.withValues(
                              alpha: 0.8,
                            ),
                            AppTheme.backgroundGradient.colors.last.withValues(
                              alpha: 0.8,
                            ),
                          ],
                        )
                      : AppTheme.backgroundGradient,
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
                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildSectionTitle(
                            context,
                            AppStrings.helpersTitle.getString(context),
                            Icons.auto_awesome,
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.9,
                                ),
                            itemCount: _helperItems.length,
                            itemBuilder: (context, index) {
                              return HelperItemCard(
                                game: widget.game,
                                item: _helperItems[index],
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          _buildSectionTitle(
                            context,
                            AppStrings.shopTitle.getString(context),
                            Icons.science_outlined,
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.85,
                                ),
                            itemCount: _shopItems.length,
                            itemBuilder: (context, index) {
                              final item = _shopItems[index];
                              return ShopItemCard(
                                game: widget.game,
                                item: item,
                              );
                            },
                          ),
                        ],
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
          ResponsiveIconButton(
            onPressed: () {
              AudioManager().playButton();
              widget.game.overlays.remove('Shop');
            },
            icon: Icons.arrow_back_rounded,
            color: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            borderColor: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Hero(
              tag: 'shop_title',
              child: ShimmerEffect(
                baseColor: Colors.white,
                highlightColor: AppTheme.neonCyan,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: AppTheme.cosmicGlass(
                    borderRadius: 16,
                    borderColor: AppTheme.neonCyan.withValues(alpha: 0.3),
                  ),
                  child: Text(
                    AppStrings.shopTitle.getString(context),
                    textAlign: TextAlign.center,
                    style: AppTheme.heading3(context).copyWith(
                      fontSize: 22,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: AppTheme.neonCyan.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: AppTheme.cosmicGlass(
            borderRadius: 16,
            borderColor: Colors.amber.withValues(alpha: 0.3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                "${widget.game.totalCoins.value}",
                style: AppTheme.buttonText(
                  context,
                ).copyWith(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.neonCyan, size: 24),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: AppTheme.heading3(context).copyWith(
            fontSize: 16,
            letterSpacing: 2,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.neonCyan.withValues(alpha: 0.5),
                  AppTheme.neonCyan.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
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

    final Color statusColor = isSelected
        ? AppTheme.neonCyan
        : isUnlocked
        ? AppTheme.success
        : AppTheme.neonMagenta;

    return AnimatedCard(
      onTap: () => _handleTap(context, isUnlocked, isSelected, canAfford),
      hasGlow: isSelected,
      fillColor: Colors.black.withValues(alpha: 0.2), // Darker base
      borderColor: isSelected
          ? AppTheme.neonCyan
          : (isUnlocked
                ? AppTheme.success.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1)),
      child: Stack(
        children: [
          // Item Content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon with Background Glow
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          statusColor.withValues(alpha: 0.2),
                          statusColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                    child: Icon(
                      item.icon,
                      size: 40,
                      color: isUnlocked
                          ? statusColor
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.nameKey.getString(context),
                    style: AppTheme.bodyLarge(context).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  _buildActionLabel(
                    context,
                    isUnlocked,
                    canAfford,
                    isSelected,
                    statusColor,
                  ),
                ],
              ),
            ),
          ),

          // "Locked" overlay effect
          if (!isUnlocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionLabel(
    BuildContext context,
    bool isUnlocked,
    bool canAfford,
    bool isSelected,
    Color color,
  ) {
    Color labelColor = isSelected
        ? AppTheme.neonCyan
        : isUnlocked
        ? AppTheme.success
        : (canAfford ? Colors.white : Colors.redAccent);

    String label = isSelected
        ? AppStrings.active.getString(context)
        : isUnlocked
        ? AppStrings.unlocked.getString(context)
        : item.price.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: labelColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: labelColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isUnlocked) ...[
            Icon(Icons.monetization_on_rounded, size: 14, color: labelColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTheme.buttonText(
              context,
            ).copyWith(fontSize: 12, color: labelColor, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    bool isUnlocked,
    bool isSelected,
    bool canAfford,
  ) {
    AudioManager().playButton();

    if (isUnlocked) {
      if (!isSelected) {
        game.buyOrSelectSkin(item.type, item.price);
      }
    } else {
      if (canAfford) {
        game.buyOrSelectSkin(item.type, item.price);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.itemActivated.getString(context)),
            backgroundColor: AppTheme.neonCyan.withValues(alpha: 0.8),
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.insufficientCredits.getString(context)),
            backgroundColor: AppTheme.neonMagenta,
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class HelperItemCard extends StatelessWidget {
  final ColorMixerGame game;
  final HelperItemData item;

  const HelperItemCard({super.key, required this.game, required this.item});

  @override
  Widget build(BuildContext context) {
    final bool canAfford = game.totalCoins.value >= item.price;

    return AnimatedCard(
      onTap: () => _handlePurchase(context),
      fillColor: Colors.black.withValues(alpha: 0.2), // Dark card base
      borderColor: item.color.withValues(alpha: 0.3),
      hoverScale: 1.02,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.color.withValues(alpha: 0.1),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "x${item.amount}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.nameKey.getString(context),
            style: AppTheme.bodyLarge(
              context,
            ).copyWith(fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (canAfford ? Colors.white : Colors.redAccent).withValues(
                alpha: 0.1,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (canAfford ? Colors.white : Colors.redAccent).withValues(
                  alpha: 0.3,
                ),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on_rounded,
                  size: 12,
                  color: canAfford ? Colors.white : Colors.redAccent,
                ),
                const SizedBox(width: 4),
                Text(
                  "${item.price}",
                  style: AppTheme.buttonText(context).copyWith(
                    fontSize: 12,
                    color: canAfford ? Colors.white : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handlePurchase(BuildContext context) {
    AudioManager().playButton();
    if (game.totalCoins.value >= item.price) {
      game.addCoins(-item.price);
      game.addHelper(item.id, item.amount);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.helperPurchased.getString(context)),
          backgroundColor: AppTheme.success.withValues(alpha: 0.8),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.insufficientCredits.getString(context)),
          backgroundColor: AppTheme.neonMagenta,
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
