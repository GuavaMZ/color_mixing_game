import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart'; // For Game access
import 'package:color_mixing_deductive/core/color_names.dart';
import 'package:color_mixing_deductive/core/level_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/core/level_model.dart';
import 'dart:ui';

class GalleryOverlay extends StatefulWidget {
  final ColorMixerGame game;

  const GalleryOverlay({super.key, required this.game});

  @override
  State<GalleryOverlay> createState() => _GalleryOverlayState();
}

class _GalleryOverlayState extends State<GalleryOverlay> {
  Map<int, int> unlockedLevels = {};
  bool isLoading = true;
  List<LevelModel> levels = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Assuming 'classic' mode progress determines the gallery
    final progress = await SaveManager.loadProgress('classic');

    // We need level definitions to get the colors.
    // game.levelManager should be initialized.
    // If not, we might need a local instance, but game.levelManager is best.

    setState(() {
      unlockedLevels = progress;
      levels = widget.game.levelManager.classicLevels;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        children: [
                          _buildBackButton(context),
                          Expanded(
                            child: Text(
                              "MOLECULAR GALLERY",
                              textAlign: TextAlign.center,
                              style: AppTheme.heading1(context).copyWith(
                                fontSize: 28,
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
                          ),
                          const SizedBox(width: 48), // Balance back button
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Collection of Synthesized Compounds",
                        style: AppTheme.caption(
                          context,
                        ).copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 24),

                      // Grid
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4, // Adjust for screen size?
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: levels
                              .length, // Show all logic?? Or just first 50?

                          // Let's cap it or show what's available in LevelManager
                          // LevelManager generates 100 levels.
                          itemBuilder: (context, index) {
                            final level = levels[index];
                            // Levels use 1-based ID usually, but check LevelManager
                            // In LevelManager: _createLevel(id: i...) where i starts at 1
                            final isUnlocked =
                                unlockedLevels.containsKey(level.id) &&
                                unlockedLevels[level.id]! > 0;

                            // Also index 0 in levels list is level ID 1.

                            return _buildColorNode(context, level, isUnlocked);
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
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildColorNode(
    BuildContext context,
    LevelModel level,
    bool isUnlocked,
  ) {
    return GestureDetector(
      onTap: () {
        if (isUnlocked) {
          AudioManager().playButton();
          _showDetailDialog(context, level);
        } else {
          AudioManager().playSfx('reset.mp3'); // Error/Locked sound
        }
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isUnlocked
              ? level.targetColor
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
                    color: level.targetColor.withValues(alpha: 0.6),
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
                  size: 20,
                ),
        ),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, LevelModel level) {
    final name = ColorNameGenerator.getNameForLevel(level.id);
    final description = ColorNameGenerator.getDescriptionForLevel(level.id);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Backdrop blur
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
                    // Big Color Swatch
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: level.targetColor,
                        boxShadow: [
                          BoxShadow(
                            color: level.targetColor.withValues(alpha: 0.6),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                          const BoxShadow(
                            color: Colors.white,
                            blurRadius: 20, // Inner glow simulation
                            spreadRadius: -10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name
                    Text(
                      name.toUpperCase(),
                      style: AppTheme.heading2(
                        context,
                      ).copyWith(color: Colors.white, letterSpacing: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      description,
                      style: AppTheme.bodySmall(
                        context,
                      ).copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Stats/Formula
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "MOLECULAR FORMULA",
                            style: TextStyle(
                              color: AppTheme.neonMagenta,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildRecipeRow(level.recipe),
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

  Widget _buildRecipeRow(Map<String, dynamic> recipe) {
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
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  "$count",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: drops,
    );
  }
}
