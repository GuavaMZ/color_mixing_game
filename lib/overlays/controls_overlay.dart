import 'dart:ui';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/core/color_logic.dart';
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
          // Glass background for the entire bottom control area
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: displayHeight(context) * 0.25,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Target Color Display with Glow
              Container(
                width: displayWidth(context) * 0.2, // Responsive width
                height: displayWidth(context) * 0.2,
                decoration: BoxDecoration(
                  color: game.targetColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: game.targetColor.withValues(alpha: 0.6),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppStrings.targetColorText.getString(context),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: displayHeight(context) * 0.025,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),

              ValueListenableBuilder<int>(
                valueListenable: game.totalDrops,
                builder: (context, value, child) {
                  if (game.rDrops + game.gDrops + game.bDrops > 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _buildResetButton(context),
                    );
                  }
                  return const SizedBox(
                    height: 60,
                  ); // Spacer to keep layout stable
                },
              ),

              // Controls Area
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: displayWidth(context) * 0.05,
                  vertical: displayHeight(context) * 0.02,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildColorButton(
                      Colors.red,
                      AppStrings.redColor,
                      context,
                      () => game.addDrop('red'),
                    ),
                    _buildColorButton(
                      Colors.green,
                      AppStrings.greenColor,
                      context,
                      () => game.addDrop('green'),
                    ),
                    _buildColorButton(
                      Colors.blue,
                      AppStrings.blueColor,
                      context,
                      () => game.addDrop('blue'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(
    Color color,
    String label,
    BuildContext context,
    VoidCallback onTap,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<double>(
          valueListenable: game.matchPercentage,
          builder: (context, value, child) => Text(
            "${ColorLogic.checkMatch(game.beaker.currentColor, game.targetColor).toStringAsFixed(0)}%",
            style: TextStyle(
              fontSize: displayHeight(context) * 0.018,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: displayWidth(context) * 0.18,
            height: displayWidth(context) * 0.18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withValues(alpha: 0.7), color],
                center: Alignment(-0.4, -0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.water_drop,
              color: Colors.white.withValues(alpha: 0.8),
              size: displayWidth(context) * 0.08,
            ),
          ),
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return TextButton.icon(
      onPressed: game.resetMixing,
      icon: const Icon(Icons.refresh, color: Colors.white70),
      label: Text(
        AppStrings.reset.getString(context),
        style: const TextStyle(color: Colors.white70),
      ),
      style: TextButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
