import 'dart:ui';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/sizehelper.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

class ControlsOverlay extends StatelessWidget {
  const ControlsOverlay({super.key, required this.game});

  final ColorMixerGame game;
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game,
      builder: (context, child) => Stack(
        children: [
          // Top section - Target color with circular progress
          Positioned(
            top: displayHeight(context) * 0.08,
            left: 0,
            right: 0,
            child: Center(child: _buildTargetColorDisplay(context)),
          ),

          // Bottom controls area with glass morphism
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: displayHeight(context) * 0.28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Match percentage display
                      ValueListenableBuilder<double>(
                        valueListenable: game.matchPercentage,
                        builder: (context, value, child) => Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Text(
                            "${value.toStringAsFixed(0)}% ${AppStrings.precentageMatch.getString(context)}",
                            style: TextStyle(
                              fontSize: displayHeight(context) * 0.022,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Color buttons row
                      _buildControlsRow(context),

                      const SizedBox(height: 15),

                      // Reset button (shown when drops > 0)
                      ValueListenableBuilder<int>(
                        valueListenable: game.totalDrops,
                        builder: (context, value, child) {
                          if (game.rDrops + game.gDrops + game.bDrops > 0) {
                            return _buildResetButton(context);
                          }
                          return const SizedBox(height: 40);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetColorDisplay(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: game.matchPercentage,
      builder: (context, matchValue, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular progress indicator around target color
            SizedBox(
              width: displayWidth(context) * 0.28,
              height: displayWidth(context) * 0.28,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Progress circle
                  SizedBox(
                    width: displayWidth(context) * 0.28,
                    height: displayWidth(context) * 0.28,
                    child: CircularProgressIndicator(
                      value: matchValue / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.lerp(Colors.red, Colors.green, matchValue / 100)!,
                      ),
                    ),
                  ),

                  // Target color circle
                  Container(
                    width: displayWidth(context) * 0.22,
                    height: displayWidth(context) * 0.22,
                    decoration: BoxDecoration(
                      color: game.targetColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: game.targetColor.withOpacity(0.6),
                          blurRadius: 25,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.targetColorText.getString(context),
              style: TextStyle(
                color: Colors.white,
                fontSize: displayHeight(context) * 0.022,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorButton(
    Color color,
    String label,
    BuildContext context,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: displayWidth(context) * 0.2,
        height: displayWidth(context) * 0.2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(0.8), color, color.withOpacity(0.9)],
            center: const Alignment(-0.3, -0.3),
            stops: const [0.0, 0.6, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
        ),
        child: Icon(
          Icons.water_drop,
          color: Colors.white.withOpacity(0.9),
          size: displayWidth(context) * 0.09,
          shadows: [
            Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: game.resetMixing,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  AppStrings.reset.getString(context),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlsRow(BuildContext context) {
    final currentLevel = game.levelManager.currentLevel;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: currentLevel.availableColors.map((color) {
        String label = AppStrings.colorText.getString(context);
        String type = "";
        if (color == Colors.red) {
          label = AppStrings.redColor.getString(context);
          type = "red";
        } else if (color == Colors.green) {
          label = AppStrings.greenColor.getString(context);
          type = "green";
        } else if (color == Colors.blue) {
          label = AppStrings.blueColor.getString(context);
          type = "blue";
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: _buildColorButton(
            color,
            label,
            context,
            () => game.addDrop(type),
          ),
        );
      }).toList(),
    );
  }
}
