import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../color_mixer_game.dart';
import '../helpers/string_manager.dart';
import '../helpers/theme_constants.dart';
import '../core/lives_manager.dart';
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
  late AnimationController _glowController;
  late Animation<double> _logoScale;
  late Animation<Offset> _classicSlide;
  late Animation<Offset> _echoSlide;
  late Animation<Offset> _timeSlide;
  late Animation<double> _fadeIn;
  late Animation<double> _glowPulse;

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

    _echoSlide = Tween<Offset>(begin: const Offset(-1.5, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _buttonsController,
            curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
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

    // Glow pulse animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowPulse = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Start animations
    _logoController.forward().then((_) {
      _buttonsController.forward();
      _glowController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _buttonsController.dispose();
    _glowController.dispose();
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
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FadeTransition(
                            opacity: _fadeIn,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLivesDisplay(),
                                const SizedBox(width: 6),
                                _buildIconButton(
                                  icon: Icons.emoji_events_rounded,
                                  onTap: () {
                                    AudioManager().playButton();
                                    widget.game.overlays.add('Achievements');
                                  },
                                ),
                                const SizedBox(width: 6),
                                _buildCoinsDisplay(),
                                const SizedBox(width: 6),
                                _buildIconButton(
                                  icon: Icons.shopping_basket_rounded,
                                  onTap: () {
                                    AudioManager().playButton();
                                    widget.game.overlays.add('Shop');
                                  },
                                ),
                                const SizedBox(width: 6),
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

                    // Animated Logo with Glow
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        _logoController,
                        _glowController,
                      ]),
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScale.value,
                          child: Column(
                            children: [
                              // Logo with glow effect
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.neonCyan.withValues(
                                        alpha: _glowPulse.value * 0.3,
                                      ),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                    BoxShadow(
                                      color: AppTheme.neonMagenta.withValues(
                                        alpha: _glowPulse.value * 0.2,
                                      ),
                                      blurRadius: 60,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  AppStrings.appTitle.getString(context),
                                  textAlign: TextAlign.center,
                                  style: AppTheme.heading1(context).copyWith(
                                    shadows: [
                                      Shadow(
                                        color: AppTheme.neonCyan.withValues(
                                          alpha: _glowPulse.value,
                                        ),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Gradient decorative line
                              Container(
                                width: 120,
                                height: 4,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppTheme.neonCyan.withValues(
                                        alpha: _glowPulse.value,
                                      ),
                                      AppTheme.neonMagenta.withValues(
                                        alpha: _glowPulse.value,
                                      ),
                                      Colors.transparent,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.neonCyan.withValues(
                                        alpha: _glowPulse.value * 0.5,
                                      ),
                                      blurRadius: 8,
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
                        gradient: AppTheme.primaryGradient,
                        onTap: () {
                          AudioManager().playButton();
                          widget.game.currentMode = GameMode.classic;
                          widget.game.transitionTo('MainMenu', 'LevelMap');
                        },
                      ),
                    ),

                    SizedBox(height: ResponsiveHelper.spacing(context, 14)),

                    SlideTransition(
                      position: _echoSlide,
                      child: _buildModeButton(
                        context: context,
                        title: "COLOR ECHO",
                        subtitle:
                            "Sync the spectral ghost to the laboratory core.",
                        icon: Icons.graphic_eq_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFCCFF00), Color(0xFFFF007F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        onTap: () {
                          if (LivesManager().lives <= 0) {
                            _showNoLivesDialog(context);
                            return;
                          }
                          AudioManager().playButton();
                          widget.game.currentMode = GameMode.colorEcho;
                          widget.game.startLevel();
                          widget.game.transitionTo('MainMenu', 'ColorEchoHUD');
                        },
                      ),
                    ),

                    SizedBox(height: ResponsiveHelper.spacing(context, 14)),

                    SlideTransition(
                      position: _timeSlide,
                      child: _buildModeButton(
                        context: context,
                        title: AppStrings.timeAttackMode.getString(context),
                        subtitle: AppStrings.timeAttackModeSubtitle.getString(
                          context,
                        ),
                        icon: Icons.timer_outlined,
                        gradient: AppTheme.secondaryGradient,
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              gradient.colors.first.withValues(alpha: 0.08),
              gradient.colors.last.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            width: 2,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          decoration: AppTheme.cosmicCard(
            borderRadius: 24,
            fillColor: AppTheme.primaryMedium.withValues(alpha: 0.5),
            borderColor: Colors.transparent,
            hasGlow: false,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              splashColor: gradient.colors.first.withValues(alpha: 0.2),
              highlightColor: gradient.colors.first.withValues(alpha: 0.1),
              child: Padding(
                padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 20)),
                child: Row(
                  children: [
                    // Icon container with gradient
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: gradient.colors.first.withValues(alpha: 0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: gradient.colors.last.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: ResponsiveHelper.iconSize(context, 32),
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.spacing(context, 18)),
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTheme.buttonText(context, isLarge: true)
                                .copyWith(
                                  fontSize: ResponsiveHelper.fontSize(
                                    context,
                                    22,
                                  ),
                                  letterSpacing: 0.5,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            style: AppTheme.bodySmall(context).copyWith(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: ResponsiveHelper.fontSize(context, 13),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Arrow with gradient
                    ShaderMask(
                      shaderCallback: (bounds) => gradient.createShader(bounds),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          width: 1.5,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.2),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLivesDisplay() {
    return AnimatedBuilder(
      animation: LivesManager(),
      builder: (context, child) {
        final lives = LivesManager().lives;
        final isFull = lives >= LivesManager.maxLives;

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 1.0, end: isFull ? 1.0 : 1.05),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.12),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    width: 1.5,
                    color: Colors.redAccent.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withValues(
                        alpha: isFull ? 0.15 : 0.25,
                      ),
                      blurRadius: isFull ? 8 : 12,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: Colors.redAccent,
                      size: 18,
                      shadows: [
                        Shadow(
                          color: Colors.redAccent.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    if (isFull)
                      Text(
                        "$lives",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$lives",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            LivesManager().timeUntilNextLife,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCoinsDisplay() {
    return AnimatedBuilder(
      animation: widget.game.totalCoins,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                AppTheme.secondaryGradient.colors.first.withValues(alpha: 0.1),
                AppTheme.secondaryGradient.colors.last.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              width: 1.5,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monetization_on_rounded,
                color: Colors.amber,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                "${widget.game.totalCoins.value}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNoLivesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryDark.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.neonMagenta, width: 2),
        ),
        title: const Text(
          "Out of Lives!",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: AppTheme.neonMagenta,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              "You need at least 1 life to play. Take a short break or wait for recharge.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: LivesManager(),
              builder: (context, _) => Text(
                "Next life in: ${LivesManager().timeUntilNextLife}",
                style: const TextStyle(
                  color: AppTheme.neonCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(
                color: AppTheme.neonCyan,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
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
    _size = 40 + _random.nextDouble() * 80;
    _opacity = 0.04 + _random.nextDouble() * 0.10;

    _controller = AnimationController(
      duration: Duration(seconds: 10 + _random.nextInt(12)),
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
              screenSize.width * _startX + sin(value * pi * 2) * 40 - _size / 2,
          top:
              screenSize.height * _startY +
              cos(value * pi * 2) * 50 -
              _size / 2,
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.primaries[widget.index % Colors.primaries.length]
                      .withValues(alpha: _opacity * 4),
                  Colors.primaries[widget.index % Colors.primaries.length]
                      .withValues(alpha: _opacity * 2),
                  Colors.primaries[widget.index % Colors.primaries.length]
                      .withValues(alpha: 0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
  }
}
