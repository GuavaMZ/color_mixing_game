import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../color_mixer_game.dart';
import '../helpers/string_manager.dart';
import '../helpers/theme_constants.dart';
import '../helpers/audio_manager.dart';

class MainMenuOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const MainMenuOverlay({super.key, required this.game});

  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

class _MainMenuOverlayState extends State<MainMenuOverlay>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _buttonsController;
  late Animation<double> _logoScale;
  late Animation<Offset> _classicSlide;
  late Animation<Offset> _timeSlide;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    // Start logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Buttons animation
    _buttonsController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _classicSlide =
        Tween<Offset>(begin: const Offset(-1.5, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _buttonsController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
          ),
        );

    _timeSlide = Tween<Offset>(begin: const Offset(1.5, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _buttonsController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonsController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animations
    _logoController.forward().then((_) {
      _buttonsController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            // Animated background bubbles
            ...List.generate(8, (index) => _FloatingBubble(index: index)),

            // Main content
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.spacing(context, 24),
                ),
                child: Column(
                  children: [
                    // Top bar with settings
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FadeTransition(
                            opacity: _fadeIn,
                            child: Row(
                              children: [
                                _buildIconButton(
                                  icon: Icons.shopping_basket_rounded,
                                  onTap: () {
                                    AudioManager().playButton();
                                    widget.game.overlays.add('Shop');
                                  },
                                ),
                                const SizedBox(width: 12),
                                _buildIconButton(
                                  icon: Icons.settings_rounded,
                                  onTap: () {
                                    AudioManager().playButton();
                                    widget.game.overlays.add('Settings');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Animated Logo
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScale.value,
                          child: Column(
                            children: [
                              Text(
                                AppStrings.appTitle.getString(context),
                                textAlign: TextAlign.center,
                                style: AppTheme.heading1(context),
                              ),
                              const SizedBox(height: 8),
                              // Subtitle line
                              Container(
                                width: 80,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 4),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const Spacer(flex: 2),

                    // Mode selection buttons
                    SlideTransition(
                      position: _classicSlide,
                      child: _buildModeButton(
                        context: context,
                        title: AppStrings.classicMode.getString(context),
                        subtitle: AppStrings.classicModeSubtitle.getString(
                          context,
                        ),
                        icon: Icons.palette_outlined,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                        ),
                        onTap: () {
                          AudioManager().playButton();
                          widget.game.currentMode = GameMode.classic;
                          widget.game.transitionTo('MainMenu', 'LevelMap');
                        },
                      ),
                    ),

                    SizedBox(height: ResponsiveHelper.spacing(context, 16)),

                    SlideTransition(
                      position: _timeSlide,
                      child: _buildModeButton(
                        context: context,
                        title: AppStrings.timeAttackMode.getString(context),
                        subtitle: AppStrings.timeAttackModeSubtitle.getString(
                          context,
                        ),
                        icon: Icons.timer_outlined,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                        ),
                        onTap: () {
                          AudioManager().playButton();
                          widget.game.currentMode = GameMode.timeAttack;
                          widget.game.timeLeft = 30.0;
                          widget.game.transitionTo('MainMenu', 'LevelMap');
                        },
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Version info
                    FadeTransition(
                      opacity: _fadeIn,
                      child: Text('v1.0.0', style: AppTheme.caption(context)),
                    ),
                    SizedBox(height: safePadding.bottom + 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: ResponsiveHelper.responsive(
          context,
          mobile: 340.0,
          tablet: 400.0,
          desktop: 450.0,
        ),
      ),
      child: Container(
        decoration: AppTheme.cartoonDecoration(
          borderRadius: 24,
          fillColor: AppTheme.cardColor.withOpacity(0.8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 20)),
              child: Row(
                children: [
                  // Icon container with gradient
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: ResponsiveHelper.iconSize(context, 28),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.spacing(context, 16)),
                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTheme.heading3(context).copyWith(
                            fontSize: ResponsiveHelper.fontSize(context, 20),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: AppTheme.caption(context),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Arrow
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppTheme.cartoonDecoration(
        borderRadius: 15,
        borderWidth: 3,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

// Floating bubble widget for background animation
class _FloatingBubble extends StatefulWidget {
  final int index;
  const _FloatingBubble({required this.index});

  @override
  State<_FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<_FloatingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double _startX;
  late double _startY;
  late double _size;
  late double _opacity;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startX = _random.nextDouble();
    _startY = _random.nextDouble();
    _size = 30 + _random.nextDouble() * 60;
    _opacity = 0.03 + _random.nextDouble() * 0.08;

    _controller = AnimationController(
      duration: Duration(seconds: 8 + _random.nextInt(8)),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return Positioned(
          left:
              screenSize.width * _startX + sin(value * pi * 2) * 30 - _size / 2,
          top:
              screenSize.height * _startY +
              cos(value * pi * 2) * 40 -
              _size / 2,
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.primaries[widget.index % Colors.primaries.length]
                      .withOpacity(_opacity * 3),
                  Colors.primaries[widget.index % Colors.primaries.length]
                      .withOpacity(0),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
