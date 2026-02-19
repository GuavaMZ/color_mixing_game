import 'dart:ui';
import 'dart:math' as math;
import 'package:color_mixing_deductive/components/gameplay/beaker.dart';
import 'package:color_mixing_deductive/components/ui/beaker_preview.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/visual_effects.dart';
import 'package:color_mixing_deductive/components/ui/animated_card.dart';
import 'package:color_mixing_deductive/components/ui/responsive_components.dart';
import 'package:color_mixing_deductive/components/ui/coins_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../../color_mixer_game.dart';

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
      price: 900,
      type: BeakerType.laboratory,
      icon: Icons.science_rounded,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerMagic,
      price: 1200,
      type: BeakerType.magicBox,
      icon: Icons.inventory_2_rounded,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerHex,
      price: 2400,
      type: BeakerType.hexagon,
      icon: Icons.hexagon_rounded,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerCylinder,
      price: 2700,
      type: BeakerType.cylinder,
      icon: Icons.view_agenda_rounded,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerRound,
      price: 4500,
      type: BeakerType.round,
      icon: Icons.circle_outlined,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerDiamond,
      price: 3600,
      type: BeakerType.diamond,
      icon: Icons.diamond_rounded,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerStar,
      price: 5400,
      type: BeakerType.star,
      icon: Icons.star_rounded,
    ),
    ShopItemData(
      nameKey: AppStrings.beakerTriangle,
      price: 6600,
      type: BeakerType.triangle,
      icon: Icons.change_history_rounded,
    ),
  ];

  static const List<HelperItemData> _helperItems = [
    HelperItemData(
      id: 'undo',
      nameKey: AppStrings.undoTitle,
      descKey: AppStrings.undoDesc,
      price: 225,
      amount: 5,
      icon: Icons.undo_rounded,
      color: AppTheme.neonCyan,
    ),
    HelperItemData(
      id: 'extra_drops',
      nameKey: AppStrings.extraDropsTitle,
      descKey: AppStrings.extraDropsDesc,
      price: 600,
      amount: 3,
      icon: Icons.add_circle_outline,
      color: AppTheme.neonMagenta,
    ),
    HelperItemData(
      id: 'help_drop',
      nameKey: AppStrings.helpDropTitle,
      descKey: AppStrings.helpDropDesc,
      price: 1050,
      amount: 3,
      icon: Icons.water_drop_outlined,
      color: AppTheme.success,
    ),
    HelperItemData(
      id: 'reveal_color',
      nameKey: AppStrings.revealColorTitle,
      descKey: AppStrings.revealColorDesc,
      price: 1500,
      amount: 2,
      icon: Icons.visibility_outlined,
      color: AppTheme.electricYellow,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeInTransition(
        child: Stack(
          children: [
            // Enhanced background with animated particles
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.backgroundGradient.colors.length > 1
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.backgroundGradient.colors.first.withValues(
                            alpha: 0.7,
                          ),
                          AppTheme.backgroundGradient.colors.last.withValues(
                            alpha: 0.7,
                          ),
                        ],
                      )
                    : AppTheme.backgroundGradient,
              ),
            ),

            // Animated particle background
            _AnimatedParticleBackground(),

            // Original starfield
            const Positioned.fill(
              child: StarField(starCount: 40, color: Colors.white),
            ),

            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 8,
                  sigmaY: 8,
                ), // Increased blur for more cosmic effect
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.backgroundGradient.colors.length > 1
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.backgroundGradient.colors.first
                                  .withValues(alpha: 0.6),
                              AppTheme.backgroundGradient.colors.last
                                  .withValues(alpha: 0.6),
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: ResponsiveIconButton(
              onPressed: () {
                AudioManager().playButton();
                widget.game.overlays.remove('Shop');
              },
              icon: Icons.arrow_back_rounded,
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              borderColor: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(width: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Hero(
              tag: 'shop_title',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    AppStrings.shopTitle.getString(context).toUpperCase(),
                    style: AppTheme.heading3(context).copyWith(
                      fontSize: ResponsiveHelper.isMobile(context) ? 18 : 24,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: AppTheme.neonCyan.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 2,
                    width: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
                      ),
                    ),
                  ),
                ],
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
    return CoinsWidget(
      coinsNotifier: widget.game.totalCoins,
      useEnhancedStyle: false, // Use basic style to match original
      iconSize: 20,
      fontSize: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTheme.heading3(context).copyWith(
              fontSize: ResponsiveHelper.isMobile(context) ? 14 : 18,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
              shadows: [
                Shadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.3),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 1.5,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppTheme.neonCyan.withValues(alpha: 0.5),
                  AppTheme.neonMagenta.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
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

    final Color statusColor = isSelected
        ? AppTheme.neonCyan
        : isUnlocked
        ? AppTheme.success
        : AppTheme.neonMagenta;

    return AnimatedCard(
      onTap: () => _handleTap(context, isUnlocked, isSelected, canAfford),
      hasGlow: isSelected,
      fillColor: isSelected
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.black.withValues(alpha: 0.4),
      borderColor: isSelected
          ? AppTheme.neonCyan
          : (isUnlocked
                ? AppTheme.success.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1)),
      borderWidth: 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive sizes based on available space
          final iconSize = (constraints.maxWidth * 0.3).clamp(40.0, 60.0);
          final fontSize = (constraints.maxWidth * 0.08).clamp(12.0, 16.0);
          final padding = (constraints.maxWidth * 0.05).clamp(8.0, 16.0);
          final spacing = (constraints.maxWidth * 0.04).clamp(8.0, 16.0);

          return Stack(
            children: [
              // Item Content
              Center(
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon with Background Glow
                      Container(
                        width: iconSize * 1.3,
                        height: iconSize * 1.3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              statusColor.withValues(alpha: 0.3),
                              statusColor.withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: BeakerPreview(
                          type: item.type,
                          color: isUnlocked
                              ? statusColor
                              : Colors.white.withValues(alpha: 0.2),
                          size: iconSize * 0.8,
                          liquidLevel: isUnlocked ? 0.6 : 0.0,
                        ),
                      ),
                      SizedBox(height: spacing),
                      Flexible(
                        child: Text(
                          item.nameKey.getString(context),
                          style: AppTheme.bodyLarge(context).copyWith(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: isUnlocked ? Colors.white : Colors.white70,
                            shadows: [
                              Shadow(
                                color: statusColor.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: spacing),
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
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.6),
                          border: Border.all(color: Colors.redAccent, width: 2),
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                ),

              // Selection indicator
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.neonCyan,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonCyan.withValues(alpha: 0.6),
                          blurRadius: 8,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Icon(Icons.check, size: 14, color: Colors.black),
                  ),
                ),
            ],
          );
        },
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: labelColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: labelColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: labelColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isUnlocked) ...[
            Icon(Icons.monetization_on_rounded, size: 16, color: labelColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTheme.buttonText(context).copyWith(
              fontSize: 14,
              color: labelColor,
              letterSpacing: 1.2,
              fontWeight: FontWeight.bold,
            ),
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
      fillColor: Colors.black.withValues(alpha: 0.3),
      borderColor: item.color.withValues(alpha: 0.4),
      borderWidth: 2,
      hoverScale: 1.05,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive sizes based on available space
          final iconSize = (constraints.maxWidth * 0.25).clamp(30.0, 50.0);
          final fontSize = (constraints.maxWidth * 0.07).clamp(12.0, 15.0);
          final padding = (constraints.maxWidth * 0.05).clamp(12.0, 16.0);
          final spacing = (constraints.maxWidth * 0.04).clamp(8.0, 12.0);

          return Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item.color.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: iconSize * 1.2,
                      height: iconSize * 1.2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            item.color.withValues(alpha: 0.3),
                            item.color.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Icon(
                        item.icon,
                        color: item.color,
                        size: iconSize * 0.5,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: padding * 0.5,
                        vertical: padding * 0.25,
                      ),
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Text(
                        "x${item.amount}",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: fontSize * 0.7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                Flexible(
                  child: Text(
                    item.nameKey.getString(context),
                    style: AppTheme.bodyLarge(context).copyWith(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: item.color.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: spacing),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: padding * 0.75,
                    vertical: padding * 0.4,
                  ),
                  decoration: BoxDecoration(
                    color: canAfford
                        ? item.color.withValues(alpha: 0.2)
                        : Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: canAfford
                          ? item.color.withValues(alpha: 0.5)
                          : Colors.redAccent.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: canAfford
                            ? item.color.withValues(alpha: 0.3)
                            : Colors.redAccent.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on_rounded,
                        size: fontSize * 0.8,
                        color: canAfford ? item.color : Colors.redAccent,
                      ),
                      SizedBox(width: spacing * 0.5),
                      Text(
                        "${item.price}",
                        style: AppTheme.buttonText(context).copyWith(
                          fontSize: fontSize * 0.8,
                          color: canAfford ? item.color : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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

class _AnimatedParticleBackground extends StatefulWidget {
  const _AnimatedParticleBackground();

  @override
  State<_AnimatedParticleBackground> createState() =>
      _AnimatedParticleBackgroundState();
}

class _AnimatedParticleBackgroundState
    extends State<_AnimatedParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _particles = List.generate(
      30,
      (index) => _Particle(
        size: 2 + (index % 5).toDouble(),
        speed: 0.5 + (index % 3).toDouble(),
        color: [
          AppTheme.neonCyan,
          AppTheme.neonMagenta,
          AppTheme.electricYellow,
          Colors.purple,
          Colors.blue,
        ][index % 5].withValues(alpha: 0.3 + (index % 3) * 0.2),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            time: _controller.value * 100,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _Particle {
  final double size;
  final double speed;
  final Color color;

  _Particle({required this.size, required this.speed, required this.color});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;

  _ParticlePainter({required this.particles, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < particles.length; i++) {
      final particle = particles[i];

      // Calculate position with wave-like motion
      final x =
          (size.width / 2) +
          (size.width / 3) *
              math.sin(0.7 * (time * particle.speed + i) * 0.02) +
          (size.width / 4) *
              math.cos(0.3 * (time * particle.speed + i * 2) * 0.03);

      final y =
          (size.height / 2) +
          (size.height / 3) *
              math.cos(0.5 * (time * particle.speed + i * 1.5) * 0.015) +
          (size.height / 4) *
              math.sin(0.4 * (time * particle.speed + i * 0.8) * 0.025);

      // Wrap around edges
      final wrappedX = x % size.width;
      final wrappedY = y % size.height;

      final finalX = wrappedX < 0 ? wrappedX + size.width : wrappedX;
      final finalY = wrappedY < 0 ? wrappedY + size.height : wrappedY;

      paint.color = particle.color;
      canvas.drawCircle(Offset(finalX, finalY), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Simple fade-in transition widget
class FadeInTransition extends StatefulWidget {
  final Widget child;

  const FadeInTransition({super.key, required this.child});

  @override
  State<FadeInTransition> createState() => _FadeInTransitionState();
}

class _FadeInTransitionState extends State<FadeInTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}
