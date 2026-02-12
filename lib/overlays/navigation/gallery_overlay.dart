import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/core/color_entry.dart';
import 'package:color_mixing_deductive/core/color_palette_generator.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/helpers/visual_effects.dart';
import 'package:color_mixing_deductive/components/ui/responsive_components.dart';

class GalleryOverlay extends StatefulWidget {
  final ColorMixerGame game;

  const GalleryOverlay({super.key, required this.game});

  @override
  State<GalleryOverlay> createState() => _GalleryOverlayState();
}

class _GalleryOverlayState extends State<GalleryOverlay> {
  Set<int> discoveredColors = {};
  bool isLoading = true;
  List<ColorEntry> allColors = [];
  String selectedCategory = 'All';
  int completedLevels = 0;

  final List<String> categories = [
    'All',
    'Primary',
    'Secondary',
    'Tertiary',
    'Tinted',
    'Shaded',
    'Complex',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load discovered colors
    final discovered = await SaveManager.loadDiscoveredColors();

    // Load completed levels to determine unlocks
    final progress = await SaveManager.loadProgress('classic');
    final completed = progress.values.where((stars) => stars > 0).length;

    // Generate complete color palette
    final palette = ColorPaletteGenerator.getCompletePalette();

    setState(() {
      discoveredColors = discovered;
      completedLevels = completed;
      allColors = palette;
      isLoading = false;
    });

    // Auto-unlock colors based on progression
    _unlockColorsBasedOnProgress();
  }

  /// Unlock colors based on level completion
  void _unlockColorsBasedOnProgress() {
    // ... existing logic ...
    final Set<int> toUnlock = {};

    for (var color in allColors) {
      if (color.category == 'primary' && completedLevels >= 1) {
        toUnlock.add(color.id);
      } else if (color.category == 'secondary' && completedLevels >= 5) {
        toUnlock.add(color.id);
      } else if (color.category == 'tertiary' && completedLevels >= 15) {
        toUnlock.add(color.id);
      } else if (color.category == 'tinted' && completedLevels >= 30) {
        toUnlock.add(color.id);
      } else if (color.category == 'shaded' && completedLevels >= 50) {
        toUnlock.add(color.id);
      } else if (color.category == 'complex' && completedLevels >= 75) {
        toUnlock.add(color.id);
      }
    }

    final updated = {...discoveredColors, ...toUnlock};
    if (updated.length > discoveredColors.length) {
      SaveManager.saveDiscoveredColors(updated);
      setState(() {
        discoveredColors = updated;
      });
    }
  }

  List<ColorEntry> _getFilteredColors() {
    if (selectedCategory == 'All') return allColors;
    return allColors
        .where(
          (c) => c.category.toLowerCase() == selectedCategory.toLowerCase(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredColors = _getFilteredColors();
    final unlockedCount = filteredColors
        .where((c) => discoveredColors.contains(c.id))
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // StarField Background
          const Positioned.fill(
            child: StarField(starCount: 60, color: Colors.white),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.backgroundGradient.colors.first.withValues(
                        alpha: 0.8,
                      ),
                      AppTheme.backgroundGradient.colors.last.withValues(
                        alpha: 0.9,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Header
                        Row(
                          children: [
                            ResponsiveIconButton(
                              onPressed: () {
                                AudioManager().playButton();
                                widget.game.overlays.remove('Gallery');
                              },
                              icon: Icons.arrow_back_rounded,
                              color: Colors.white,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  ShimmerEffect(
                                    baseColor: Colors.white,
                                    highlightColor: AppTheme.neonCyan,
                                    child: Text(
                                      "COLOR GALLERY",
                                      textAlign: TextAlign.center,
                                      style: AppTheme.heading1(context)
                                          .copyWith(
                                            fontSize: 24,
                                            letterSpacing: 2,
                                            shadows: [
                                              Shadow(
                                                color: AppTheme.neonCyan
                                                    .withValues(alpha: 0.8),
                                                blurRadius: 15,
                                              ),
                                            ],
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$unlockedCount / ${filteredColors.length} Discovered",
                                    style: AppTheme.caption(context).copyWith(
                                      color: AppTheme.neonMagenta,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 48,
                            ), // Spacer to balance back button
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Category Tabs
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final isSelected = category == selectedCategory;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildCategoryTab(category, isSelected),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Color Grid
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.only(bottom: 20),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      MediaQuery.of(context).size.width > 600
                                      ? 6
                                      : 4,
                                  childAspectRatio: 1.0,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: filteredColors.length,
                            itemBuilder: (context, index) {
                              final color = filteredColors[index];
                              final isUnlocked = discoveredColors.contains(
                                color.id,
                              );
                              return _ColorNode(
                                color: color,
                                isUnlocked: isUnlocked,
                                delay: index * 30, // Staggered animation
                                onTap: () {
                                  if (isUnlocked) {
                                    AudioManager().playButton();
                                    _showDetailDialog(context, color);
                                  } else {
                                    AudioManager().playSfx('reset.mp3');
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String category, bool isSelected) {
    return GestureDetector(
      onTap: () {
        AudioManager().playButton();
        setState(() {
          selectedCategory = category;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.neonCyan.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.neonCyan
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.neonCyan.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        child: Text(
          category.toUpperCase(),
          style: TextStyle(
            color: isSelected ? AppTheme.neonCyan : Colors.white70,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, ColorEntry color) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.neonCyan.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonCyan.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Color Swatch
                    Hero(
                      tag: 'color_${color.id}',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.color,
                          boxShadow: [
                            BoxShadow(
                              color: color.color.withValues(alpha: 0.6),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name
                    ShimmerEffect(
                      baseColor: Colors.white,
                      highlightColor: color.color,
                      child: Text(
                        color.name.toUpperCase(),
                        style: AppTheme.heading2(
                          context,
                        ).copyWith(color: Colors.white, letterSpacing: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(color.category),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        color.category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      color.description,
                      style: AppTheme.bodySmall(
                        context,
                      ).copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Recipe
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppTheme.cosmicGlass(
                        borderRadius: 12,
                        borderColor: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "FORMULA",
                            style: TextStyle(
                              color: AppTheme.neonMagenta,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildRecipeRow(color.recipe),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    ResponsiveIconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icons.close_rounded,
                      color: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'primary':
        return Colors.red.withValues(alpha: 0.7);
      case 'secondary':
        return Colors.orange.withValues(alpha: 0.7);
      case 'tertiary':
        return Colors.purple.withValues(alpha: 0.7);
      case 'tinted':
        return Colors.lightBlue.withValues(alpha: 0.7);
      case 'shaded':
        return Colors.indigo.withValues(alpha: 0.7);
      case 'complex':
        return Colors.pink.withValues(alpha: 0.7);
      default:
        return Colors.grey.withValues(alpha: 0.7);
    }
  }

  Widget _buildRecipeRow(Map<String, int> recipe) {
    List<Widget> drops = [];
    recipe.forEach((colorName, count) {
      // ... existing recipe logic ... (omitted for brevity, keep same)
      // Re-implementing for completeness
      if (count > 0) {
        Color c;
        switch (colorName) {
          case 'red':
            c = Colors.red;
            break;
          case 'green':
            c = Colors.green;
            break;
          case 'blue':
            c = Colors.blue;
            break;
          case 'white':
            c = Colors.white;
            break;
          case 'black':
            c = Colors.black;
            break;
          default:
            c = Colors.transparent;
        }

        drops.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "$count",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    return Wrap(alignment: WrapAlignment.center, spacing: 8, children: drops);
  }
}

class _ColorNode extends StatefulWidget {
  final ColorEntry color;
  final bool isUnlocked;
  final int delay;
  final VoidCallback onTap;

  const _ColorNode({
    required this.color,
    required this.isUnlocked,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_ColorNode> createState() => _ColorNodeState();
}

class _ColorNodeState extends State<_ColorNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Hero(
          tag: 'color_${widget.color.id}',
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isUnlocked
                  ? widget.color.color
                  : Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: widget.isUnlocked
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
                width: 2,
              ),
              boxShadow: widget.isUnlocked
                  ? [
                      BoxShadow(
                        color: widget.color.color.withValues(alpha: 0.6),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: widget.isUnlocked
                  ? null
                  : Icon(
                      Icons.lock_rounded,
                      color: Colors.white.withValues(alpha: 0.2),
                      size: 16,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
