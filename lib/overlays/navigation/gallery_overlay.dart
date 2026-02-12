import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/core/color_entry.dart';
import 'package:color_mixing_deductive/core/color_palette_generator.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/helpers/visual_effects.dart';
import 'package:color_mixing_deductive/components/ui/responsive_components.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';

class GalleryOverlay extends StatefulWidget {
  final ColorMixerGame game;

  const GalleryOverlay({super.key, required this.game});

  @override
  State<GalleryOverlay> createState() => _GalleryOverlayState();
}

enum SortOption { id, spectrum, brightness, saturation }

class _GalleryOverlayState extends State<GalleryOverlay> {
  Set<int> discoveredColors = {};
  bool isLoading = true;
  List<ColorEntry> allColors = [];
  String selectedCategory = 'All';
  SortOption currentSort = SortOption.id;
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

  List<ColorEntry> _getFilteredAndSortedColors() {
    // 1. Filter
    List<ColorEntry> filtered;
    if (selectedCategory == 'All') {
      filtered = List.from(allColors);
    } else {
      filtered = allColors
          .where(
            (c) => c.category.toLowerCase() == selectedCategory.toLowerCase(),
          )
          .toList();
    }

    // 2. Sort
    switch (currentSort) {
      case SortOption.id:
        filtered.sort((a, b) => a.id.compareTo(b.id));
        break;
      case SortOption.spectrum:
        filtered.sort((a, b) {
          double hueA = a.hsv.hue;
          double hueB = b.hsv.hue;
          return hueA.compareTo(hueB);
        });
        break;
      case SortOption.brightness:
        filtered.sort((a, b) {
          // Sort Dark -> Light
          double lumA = a.color.computeLuminance();
          double lumB = b.color.computeLuminance();
          return lumA.compareTo(lumB);
        });
        break;
      case SortOption.saturation:
        filtered.sort((a, b) {
          double satA = a.hsv.saturation;
          double satB = b.hsv.saturation;
          return satA.compareTo(satB);
        });
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final displayColors = _getFilteredAndSortedColors();
    final unlockedCount = displayColors
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
                                      AppStrings.labArchives.getString(
                                        context,
                                      ), // More scientific name
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
                                    "$unlockedCount / ${displayColors.length} ${AppStrings.samplesCount.getString(context)}",
                                    style: AppTheme.caption(context).copyWith(
                                      color: AppTheme.neonMagenta,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Sorting Dropdown
                            _buildSortButton(),
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
                            itemCount: displayColors.length,
                            itemBuilder: (context, index) {
                              final color = displayColors[index];
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

  Widget _buildSortButton() {
    return PopupMenuButton<SortOption>(
      icon: const Icon(Icons.sort, color: Colors.white),
      color: AppTheme.primaryDark,
      onSelected: (SortOption result) {
        setState(() {
          currentSort = result;
        });
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOption>>[
        PopupMenuItem<SortOption>(
          value: SortOption.id,
          child: Text(
            AppStrings.sortDiscovery.getString(context),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        PopupMenuItem<SortOption>(
          value: SortOption.spectrum,
          child: Text(
            AppStrings.sortSpectral.getString(context),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        PopupMenuItem<SortOption>(
          value: SortOption.brightness,
          child: Text(
            AppStrings.sortLuminance.getString(context),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        PopupMenuItem<SortOption>(
          value: SortOption.saturation,
          child: Text(
            AppStrings.sortSaturation.getString(context),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
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
          _getLocalizedCategory(category),
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

  String _getLocalizedCategory(String category) {
    switch (category) {
      case 'All':
        return AppStrings.allCategory.getString(context);
      case 'Primary':
        return AppStrings.primaryCategory.getString(context);
      case 'Secondary':
        return AppStrings.secondaryCategory.getString(context);
      case 'Tertiary':
        return AppStrings.tertiaryCategory.getString(context);
      case 'Tinted':
        return AppStrings.tintedCategory.getString(context);
      case 'Shaded':
        return AppStrings.shadedCategory.getString(context);
      case 'Complex':
        return AppStrings.complexCategory.getString(context);
      default:
        return category.toUpperCase();
    }
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
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark.withValues(alpha: 0.95),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Lab Report Header ---
                    Text(
                      AppStrings.analysisReport.getString(context),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- Color Preview Card ---
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: color.color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.color.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                color.hexCode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Name and Category ---
                    Text(
                      color.name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTheme.heading2(
                        context,
                      ).copyWith(color: Colors.white, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(color.category),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getLocalizedCategory(color.category),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Scientific Data Grid ---
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            "RGB",
                            "${color.color.red}, ${color.color.green}, ${color.color.blue}",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            "HSL",
                            "${color.hsv.hue.round()}°, ${(color.hsv.saturation * 100).round()}%",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            "CMYK",
                            "${color.cmyk[0]}, ${color.cmyk[1]}, ${color.cmyk[2]}, ${color.cmyk[3]}",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Formula ---
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.synthesisFormula.getString(context),
                      style: const TextStyle(
                        color: AppTheme.neonMagenta,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppTheme.cosmicGlass(
                        borderRadius: 12,
                        borderColor: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: _buildRecipeRow(color.recipe),
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

  Widget _buildMetricTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.neonCyan,
              fontSize: 14,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
