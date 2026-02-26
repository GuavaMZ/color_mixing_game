import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../../../color_mixer_game.dart';
import '../../helpers/string_manager.dart';
import '../../helpers/theme_constants.dart';
import '../../helpers/audio_manager.dart';
import '../../components/ui/animated_card.dart';
import '../../components/ui/enhanced_button.dart';

class ModeGuideOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const ModeGuideOverlay({super.key, required this.game});

  @override
  State<ModeGuideOverlay> createState() => _ModeGuideOverlayState();
}

class _ModeGuideOverlayState extends State<ModeGuideOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    AudioManager().playButton();
    widget.game.returnToMainMenu();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Backdrop with Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withValues(alpha: 0.7)),
            ),
          ),

          // Content
          Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.spacing(context, 24),
                  vertical: ResponsiveHelper.spacing(context, 40),
                ),
                constraints: BoxConstraints(
                  maxWidth: 600,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: AnimatedCard(
                  onTap: () {}, // For glow
                  hasGlow: true,
                  borderRadius: 32,
                  fillColor: AppTheme.primaryDark.withValues(alpha: 0.9),
                  borderColor: AppTheme.neonCyan,
                  padding: EdgeInsets.all(
                    ResponsiveHelper.spacing(context, 24),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.modeGuidesTitle.getString(context),
                            style: AppTheme.heading2(context),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                            ),
                            onPressed: _close,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Guides List
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              _buildGuideSection(
                                title: AppStrings.classicGuideTitle.getString(
                                  context,
                                ),
                                description: AppStrings.classicGuideDesc
                                    .getString(context),
                                icon: Icons.palette_rounded,
                                color: AppTheme.neonCyan,
                              ),
                              const SizedBox(height: 16),
                              _buildGuideSection(
                                title: AppStrings.timeAttackGuideTitle
                                    .getString(context),
                                description: AppStrings.timeAttackGuideDesc
                                    .getString(context),
                                icon: Icons.timer_rounded,
                                color: AppTheme.electricYellow,
                              ),
                              const SizedBox(height: 16),
                              _buildGuideSection(
                                title: AppStrings.colorEchoGuideTitle.getString(
                                  context,
                                ),
                                description: AppStrings.colorEchoGuideDesc
                                    .getString(context),
                                icon: Icons.waves_rounded,
                                color: AppTheme.neonMagenta,
                              ),
                              const SizedBox(height: 16),
                              _buildGuideSection(
                                title: AppStrings.chaosLabGuideTitle.getString(
                                  context,
                                ),
                                description: AppStrings.chaosLabGuideDesc
                                    .getString(context),
                                icon: Icons.science_rounded,
                                color: AppTheme.success,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),

                      // Footer Action
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: EnhancedButton(
                          label: AppStrings.gotIt.getString(context),
                          onTap: _close,
                        ),
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

  Widget _buildGuideSection({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyLarge(context).copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: AppTheme.bodyMedium(
                    context,
                  ).copyWith(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
