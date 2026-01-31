import 'dart:ui';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/sizehelper.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

class WinMenuOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const WinMenuOverlay({super.key, required this.game});

  @override
  State<WinMenuOverlay> createState() => _WinMenuOverlayState();
}

class _WinMenuOverlayState extends State<WinMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int stars = widget.game.calculateStars();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 30),
                  padding: const EdgeInsets.all(35),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trophy icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.amber.withOpacity(0.3),
                              Colors.amber.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: displayHeight(context) * 0.1,
                          shadows: [
                            Shadow(
                              color: Colors.amber.withOpacity(0.5),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Win text
                      Text(
                        AppStrings.wonText.getString(context),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: displayHeight(context) * 0.04,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              blurRadius: 15,
                              color: Colors.amber.withOpacity(0.6),
                              offset: const Offset(0, 0),
                            ),
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Stars display
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          return TweenAnimationBuilder<double>(
                            duration: Duration(
                              milliseconds: 300 + (index * 150),
                            ),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                  ),
                                  child: Icon(
                                    index < stars
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: index < stars
                                        ? Colors.amber
                                        : Colors.white.withOpacity(0.3),
                                    size: 55,
                                    shadows: index < stars
                                        ? [
                                            Shadow(
                                              color: Colors.amber.withOpacity(
                                                0.6,
                                              ),
                                              blurRadius: 10,
                                            ),
                                          ]
                                        : [],
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ),

                      const SizedBox(height: 15),

                      // Genius text
                      Text(
                        AppStrings.urGeniusText.getString(context),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: displayHeight(context) * 0.02,
                          decoration: TextDecoration.none,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Stats
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          "Drops used: ${widget.game.totalDrops.value}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Next Level button
                          _buildButton(
                            context: context,
                            label: AppStrings.newLevel.getString(context),
                            icon: Icons.arrow_forward_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            onTap: () => widget.game.goToNextLevel(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon, color: Colors.white, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
