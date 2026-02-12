import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../../../color_mixer_game.dart';
import '../../helpers/string_manager.dart';
import '../../helpers/theme_constants.dart';
import '../../core/lives_manager.dart';
import '../../helpers/audio_manager.dart';
import '../../helpers/visual_effects.dart';
import '../../components/ui/responsive_components.dart';
import '../../components/ui/animated_card.dart';

class MainMenuOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const MainMenuOverlay({super.key, required this.game});

  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

class _MainMenuOverlayState extends State<MainMenuOverlay>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _glowController;
  late Animation<double> _logoScale;
  late Animation<double> _glowPulse;

  // Staggered animations for buttons
  final List<AnimationController> _buttonControllers = [];

  @override
  void initState() {
    super.initState();

    // Logo Animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Glow Pulse
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _glowPulse = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Start
    _logoController.forward();
    _glowController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    for (var controller in _buttonControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background - Deep Cosmic Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),

          // Starfield Effect
          const StarField(starCount: 80, color: Colors.white),

          // Floating Bubbles (Legacy but enhanced)
          ...List.generate(6, (index) => _FloatingBubble(index: index)),

          // Main Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.spacing(context, 16),
              ),
              child: Column(
                children: [
                  // Top Bar (Status & Utils)
                  _buildTopBar(),

                  const Spacer(),

                  // Hero Logo Section
                  _buildHeroLogo(),

                  const Spacer(),

                  // Game Modes
                  _buildGameModes(),

                  const Spacer(),

                  // Footer
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'v1.1.0',
                      style: AppTheme.caption(
                        context,
                      ).copyWith(color: Colors.white.withValues(alpha: 0.3)),
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

  Widget _buildTopBar() {
    return Column(
      children: [
        // Status Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildLivesDisplay(), _buildCoinsDisplay()],
          ),
        ),

        // Horizontal Scrollable Utils
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildUtilButton(
                icon: Icons.emoji_events_rounded,
                tooltip: AppStrings.achievementsTitle.getString(context),
                onTap: () => _navTo('Achievements'),
                delay: 0,
              ),
              _buildUtilButton(
                icon: Icons.bar_chart_rounded,
                tooltip: AppStrings.statisticsTitle.getString(context),
                onTap: () => _navTo('Statistics'),
                delay: 100,
              ),
              _buildUtilButton(
                icon: Icons.event_available_rounded,
                tooltip: AppStrings.dailyChallengeTitle.getString(context),
                onTap: () => _navTo('DailyChallenge'),
                delay: 200,
              ),
              _buildUtilButton(
                icon: Icons.shopping_basket_rounded,
                tooltip: AppStrings.shopTitle.getString(context),
                onTap: () => _navTo('Shop'),
                delay: 300,
              ),
              _buildUtilButton(
                icon: Icons.auto_stories_rounded,
                tooltip: AppStrings.galleryTitle.getString(context),
                onTap: () => _navTo('Gallery'),
                delay: 400,
              ),
              _buildUtilButton(
                icon: Icons.settings_rounded,
                tooltip: AppStrings.settings.getString(context),
                onTap: () => _navTo('Settings'),
                delay: 500,
              ),
              _buildUtilButton(
                icon: Icons.science_outlined,
                tooltip: AppStrings.labUpgradeTitle.getString(context),
                onTap: () => _navTo('LabUpgrade'),
                delay: 600,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navTo(String overlay) {
    AudioManager().playButton();
    widget.game.overlays.add(overlay);
  }

  Widget _buildUtilButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 6.0,
            ), // Tighter spacing
            child: ResponsiveIconButton(
              icon: icon,
              onPressed: onTap,
              tooltip: tooltip,
              size: 20, // Compact size
              color: Colors.white,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLivesDisplay() {
    return AnimatedBuilder(
      animation: LivesManager(),
      builder: (context, child) {
        final lives = LivesManager().lives;
        final isFull = lives >= LivesManager.maxLives;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: AppTheme.cosmicGlass(borderRadius: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_rounded,
                color: isFull
                    ? Colors.redAccent
                    : Colors.redAccent.withValues(alpha: 0.7),
                size: ResponsiveHelper.iconSize(context, 20),
              ),
              const SizedBox(width: 8),
              Text(
                "$lives",
                style: AppTheme.bodyLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w900, color: Colors.white),
              ),
              if (!isFull) ...[
                const SizedBox(width: 8),
                Text(
                  LivesManager().timeUntilNextLife,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoinsDisplay() {
    return ValueListenableBuilder<int>(
      valueListenable: widget.game.totalCoins,
      builder: (context, coins, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: AppTheme.cosmicGlass(
            borderRadius: 20,
            borderColor: Colors.amber.withValues(alpha: 0.3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "$coins",
                style: AppTheme.bodyLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _glowController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 32)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.neonCyan.withValues(
                        alpha: _glowPulse.value * 0.5,
                      ),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonMagenta.withValues(
                        alpha: _glowPulse.value * 0.3,
                      ),
                      blurRadius: 50,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.science_rounded,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.appTitle.getString(context).toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTheme.heading1(context).copyWith(
                        letterSpacing: 4,
                        shadows: [
                          Shadow(color: AppTheme.neonCyan, blurRadius: 20),
                          Shadow(
                            // Holographic edge
                            color: Colors.white,
                            offset: const Offset(-2, -2),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameModes() {
    return Column(
      children: [
        _buildModeCard(
          title: AppStrings.classicMode.getString(context),
          subtitle: AppStrings.classicModeSubtitle.getString(context),
          icon: Icons.palette_outlined,
          gradient: AppTheme.primaryGradient,
          onTap: () {
            AudioManager().playButton();
            widget.game.currentMode = GameMode.classic;
            widget.game.transitionTo('MainMenu', 'LevelMap');
          },
          delay: 0,
        ),

        SizedBox(height: ResponsiveHelper.spacing(context, 12)),

        _buildModeCard(
          title: AppStrings.colorEcho.getString(context),
          subtitle: AppStrings.colorEchoSubtitle.getString(context),
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
          delay: 100,
        ),

        SizedBox(height: ResponsiveHelper.spacing(context, 12)),

        _buildModeCard(
          title: AppStrings.timeAttackMode.getString(context),
          subtitle: AppStrings.timeAttackModeSubtitle.getString(context),
          icon: Icons.timer_outlined,
          gradient: AppTheme.secondaryGradient,
          onTap: () {
            AudioManager().playButton();
            widget.game.currentMode = GameMode.timeAttack;
            widget.game.timeLeft = 30.0;
            widget.game.transitionTo('MainMenu', 'LevelMap');
          },
          delay: 200,
        ),

        SizedBox(height: ResponsiveHelper.spacing(context, 12)),

        _buildModeCard(
          title: AppStrings.chaosLabTitle.getString(context),
          subtitle: AppStrings.chaosLabSubtitle.getString(context),
          icon: Icons.warning_amber_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF0000), Color(0xFFFF8800)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: () {
            if (LivesManager().lives <= 0) {
              _showNoLivesDialog(context);
              return;
            }
            AudioManager().playButton();
            widget.game.currentMode = GameMode.chaosLab;
            widget.game.startLevel();
            widget.game.transitionTo('MainMenu', 'ChaosLabHUD');
          },
          delay: 300,
        ),
      ],
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
    required int delay,
  }) {
    // Determine wide constraints
    final double maxWidth = ResponsiveHelper.responsive(
      context,
      mobile: 400.0,
      tablet: 500.0,
      desktop: 600.0,
    );

    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: const Offset(0, 50), end: Offset.zero),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, offset, child) {
        return Transform.translate(
          offset: offset,
          child: AnimatedFade(
            delay: delay,
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: AnimatedCard(
                onTap: onTap,
                padding: EdgeInsets.zero, // We control padding inside
                hasGlow: false, // Custom glow logic via AnimatedCard
                borderColor: gradient.colors.first.withValues(alpha: 0.3),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradient.colors.first.withValues(alpha: 0.1),
                        gradient.colors.last.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Icon Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: gradient.colors.first.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 28),
                        ),

                        const SizedBox(width: 16),

                        // Text Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppTheme.heading3(context).copyWith(
                                  letterSpacing: 1,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: AppTheme.bodySmall(
                                  context,
                                ).copyWith(color: Colors.white70),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Arrow
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
        title: Text(
          AppStrings.outOfLives.getString(context),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_rounded,
              color: AppTheme.neonMagenta,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.noLivesDesc.getString(context),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              "${AppStrings.nextLifeIn.getString(context)} ${LivesManager().timeUntilNextLife}",
              style: const TextStyle(
                color: AppTheme.neonCyan,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.ok.getString(context),
              style: const TextStyle(
                color: AppTheme.neonCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedFade extends StatefulWidget {
  final Widget child;
  final int delay;
  const AnimatedFade({super.key, required this.child, required this.delay});

  @override
  State<AnimatedFade> createState() => _AnimatedFadeState();
}

class _AnimatedFadeState extends State<AnimatedFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

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
    return FadeTransition(opacity: _fade, child: widget.child);
  }
}

// Keeping the _FloatingBubble class as it was useful for background depth
class _FloatingBubble extends StatefulWidget {
  final int index;
  const _FloatingBubble({required this.index});

  @override
  State<_FloatingBubble> createState() => _FloatingBubbleState();
}

class _FloatingBubbleState extends State<_FloatingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    final duration = 10 + _random.nextInt(10);
    _controller = AnimationController(
      duration: Duration(seconds: duration),
      vsync: this,
    )..repeat(reverse: true);

    final startX = _random.nextDouble() * 2 - 1;
    final startY = _random.nextDouble() * 2 - 1;
    final endX = startX + (_random.nextDouble() - 0.5);
    final endY = startY + (_random.nextDouble() - 0.5);

    _animation = Tween<Offset>(
      begin: Offset(startX, startY),
      end: Offset(endX, endY),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = 50.0 + _random.nextDouble() * 100;
    return SlideTransition(
      position: _animation,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.012),
              Colors.white.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}
