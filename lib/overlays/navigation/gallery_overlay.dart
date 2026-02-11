import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/core/color_entry.dart';
import 'package:color_mixing_deductive/core/color_palette_generator.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'dart:ui';

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
    final Set<int> toUnlock = {};

    for (var color in allColors) {
      // Progressive unlock system
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

    // Merge with existing discovered colors
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
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        children: [
                          _buildBackButton(context),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  "COLOR GALLERY",
                                  textAlign: TextAlign.center,
                                  style: AppTheme.heading1(context).copyWith(
                                    fontSize: 24,
                                    letterSpacing: 2,
                                    shadows: [
                                      Shadow(
                                        color: AppTheme.neonCyan.withValues(
                                          alpha: 0.8,
                                        ),
                                        blurRadius: 15,
                                      ),
                                    ],
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
                          const SizedBox(width: 48),
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
                            return _buildColorNode(context, color, isUnlocked);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return InkWell(
      onTap: () {
        AudioManager().playButton();
        widget.game.overlays.remove('Gallery');
      },
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
          color: Colors.black26,
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 20,
        ),
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
      child: Container(
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
            width: 2,
          ),
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

  Widget _buildColorNode(
    BuildContext context,
    ColorEntry color,
    bool isUnlocked,
  ) {
    return GestureDetector(
      onTap: () {
        if (isUnlocked) {
          AudioManager().playButton();
          _showDetailDialog(context, color);
        } else {
          AudioManager().playSfx('reset.mp3');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isUnlocked
              ? color.color
              : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: isUnlocked
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
            width: 2,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: color.color.withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Center(
          child: isUnlocked
              ? null
              : Icon(
                  Icons.lock_rounded,
                  color: Colors.white.withValues(alpha: 0.2),
                  size: 16,
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
                    Container(
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
                    const SizedBox(height: 24),

                    // Name
                    Text(
                      color.name.toUpperCase(),
                      style: AppTheme.heading2(
                        context,
                      ).copyWith(color: Colors.white, letterSpacing: 1.5),
                      textAlign: TextAlign.center,
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
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
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
                    AppTheme.primaryButton(
                      context: context,
                      text: "CLOSE",
                      onPressed: () => Navigator.pop(context),
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
