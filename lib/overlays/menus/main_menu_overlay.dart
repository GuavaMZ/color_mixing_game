import 'dart:math';
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
import '../../components/ui/coins_widget.dart';
import '../../helpers/daily_login_manager.dart';

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

    // Check for Daily Login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyLogin();
    });
  }

  Future<void> _checkDailyLogin() async {
    final canClaim = await DailyLoginManager.canClaimToday();
    if (canClaim && mounted) {
      widget.game.transitionTo('MainMenu', 'DailyLogin');
    }
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
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.backgroundGradient,
              ),
            ),
          ),

          // Starfield Effect
          const StarField(starCount: 80, color: Colors.white),

          // Floating Bubbles (Legacy but enhanced)
          ...List.generate(6, (index) => _FloatingBubble(index: index)),

          // Main Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveHelper.spacing(context, 16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              // Top Bar (Status & Utils)
                              _buildTopBar(),
                              SizedBox(
                                height: ResponsiveHelper.spacing(context, 20),
                              ),
                            ],
                          ),

                          // Hero Logo Section
                          _buildHeroLogo(),

                          Column(
                            children: [
                              SizedBox(
                                height: ResponsiveHelper.spacing(context, 20),
                              ),
                              // Game Modes
                              _buildGameModes(),
                              SizedBox(
                                height: ResponsiveHelper.spacing(context, 20),
                              ),

                              // Footer
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildTermsAcceptance(),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  'v1.3.0',
                                  style: AppTheme.caption(context).copyWith(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
              _buildUtilButton(
                icon: Icons.help_outline_rounded,
                tooltip: AppStrings.modeGuidesTitle.getString(context),
                onTap: () => _navTo('ModeGuide'),
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
    widget.game.transitionTo('MainMenu', overlay);
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
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.spacing(context, 4),
            ), // Responsive spacing
            child: Semantics(
              label: tooltip,
              button: true,
              child: ExcludeSemantics(
                child: ResponsiveIconButton(
                  icon: icon,
                  onPressed: onTap,
                  tooltip: tooltip,
                  size: ResponsiveHelper.responsive(
                    context,
                    mobile: 20,
                    tablet: 22,
                    desktop: 24,
                  ), // Responsive size
                  color: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                ),
              ),
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
    return GestureDetector(
      onTap: () {
        AudioManager().playButton();
        widget.game.transitionTo('MainMenu', 'CoinStore');
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoinsWidget(
            coinsNotifier: widget.game.totalCoins,
            useEnhancedStyle: false,
            iconSize: 20,
            fontSize: 16,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          const SizedBox(width: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, v, child) =>
                Transform.scale(scale: v, child: child),
            child: GestureDetector(
              onTap: () {
                AudioManager().playButton();
                widget.game.transitionTo('MainMenu', 'CoinStore');
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.amber, Colors.orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
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
                child: Semantics(
                  label: AppStrings.appTitle.getString(context),
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        Icon(
                          Icons.science_rounded,
                          size: ResponsiveHelper.responsive(
                            context,
                            mobile: 56,
                            tablet: 64,
                            desktop: 72,
                          ),
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.appTitle.getString(context).toUpperCase(),
                          textAlign: TextAlign.center,
                          semanticsLabel: AppStrings.appTitle.getString(
                            context,
                          ),
                          style: AppTheme.heading1(context).copyWith(
                            fontSize: ResponsiveHelper.fontSize(
                              context,
                              ResponsiveHelper.responsive(
                                context,
                                mobile: 32,
                                tablet: 36,
                                desktop: 42,
                              ),
                            ),
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
            widget.game.selectModeAndStart(GameMode.classic);
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
            widget.game.selectModeAndStart(GameMode.timeAttack);
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
                child: Semantics(
                  label: '$title. $subtitle',
                  button: true,
                  child: ExcludeSemantics(
                    child: GlowingBorder(
                      color: gradient.colors.first,
                      blurRadius: 5,
                      strokeWidth: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              gradient.colors.first.withValues(alpha: 0.1),
                              gradient.colors.last.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(
                            ResponsiveHelper.responsive(
                              context,
                              mobile: 16,
                              tablet: 20,
                              desktop: 24,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Icon Box
                              Container(
                                padding: EdgeInsets.all(
                                  ResponsiveHelper.responsive(
                                    context,
                                    mobile: 12,
                                    tablet: 14,
                                    desktop: 16,
                                  ),
                                ),
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
                                child: Icon(
                                  icon,
                                  color: Colors.white,
                                  size: ResponsiveHelper.responsive(
                                    context,
                                    mobile: 24,
                                    tablet: 28,
                                    desktop: 32,
                                  ),
                                ),
                              ),

                              SizedBox(
                                width: ResponsiveHelper.spacing(context, 16),
                              ),

                              // Text Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: AppTheme.heading3(context)
                                          .copyWith(
                                            fontSize: ResponsiveHelper.fontSize(
                                              context,
                                              ResponsiveHelper.responsive(
                                                context,
                                                mobile: 20,
                                                tablet: 22,
                                                desktop: 24,
                                              ),
                                            ),
                                            letterSpacing: 1,
                                            color: Colors.white,
                                          ),
                                    ),
                                    SizedBox(
                                      height: ResponsiveHelper.spacing(
                                        context,
                                        4,
                                      ),
                                    ),
                                    Text(
                                      subtitle,
                                      style: AppTheme.bodySmall(context)
                                          .copyWith(
                                            fontSize: ResponsiveHelper.fontSize(
                                              context,
                                              ResponsiveHelper.responsive(
                                                context,
                                                mobile: 12,
                                                tablet: 14,
                                                desktop: 16,
                                              ),
                                            ),
                                            color: Colors.white70,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // Arrow
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: ResponsiveHelper.responsive(
                                  context,
                                  mobile: 14,
                                  tablet: 16,
                                  desktop: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildTermsAcceptance() {
    final statement = AppStrings.termsAcceptanceStatement.getString(context);
    final label = AppStrings.termsOfUseLabel.getString(context);

    // Split statement at %s
    final parts = statement.split('%s');

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          parts[0],
          style: AppTheme.caption(
            context,
          ).copyWith(color: Colors.white.withValues(alpha: 0.5)),
        ),
        GestureDetector(
          onTap: () => _showTermsDialog(context),
          child: Text(
            label,
            style: AppTheme.caption(context).copyWith(
              color: AppTheme.neonCyan,
              decoration: TextDecoration.underline,
              decorationColor: AppTheme.neonCyan,
            ),
          ),
        ),
        if (parts.length > 1)
          Text(
            parts[1],
            style: AppTheme.caption(
              context,
            ).copyWith(color: Colors.white.withValues(alpha: 0.5)),
          ),
      ],
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.neonCyan, width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.gavel_rounded, color: AppTheme.neonCyan),
            const SizedBox(width: 12),
            Text(
              AppStrings.termsOfUseLabel.getString(context),
              style: AppTheme.heading2(context).copyWith(fontSize: 24),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTermsSection(
                  "1. Acceptance of Terms",
                  "By using Color Lab, you agree to be bound by these Terms. If you disagree, do not use the App.",
                ),
                _buildTermsSection(
                  "2. License Grant",
                  "We grant you a personal, non-exclusive, limited license for non-commercial entertainment purposes.",
                ),
                _buildTermsSection(
                  "3. Restrictions",
                  "You agree not to reverse engineer, decompile, or disassemble the App, or use it for any illegal purpose.",
                ),
                _buildTermsSection(
                  "4. Intellectual Property",
                  "All rights, title, and interest in and to the App (code, graphics) are owned by DV Zeyad.",
                ),
                _buildTermsSection(
                  "5. Virtual Currency",
                  "Coins and items have no real-world value, are non-refundable, and cannot be exchanged for real money.",
                ),
                _buildTermsSection(
                  "6. Disclaimer of Warranties",
                  "The App is provided 'AS IS' without warranties of any kind regarding its performance or reliability.",
                ),
                _buildTermsSection(
                  "7. Limitation of Liability",
                  "DV Zeyad shall not be liable for any indirect, incidental, or consequential damages arising from use.",
                ),
                _buildTermsSection(
                  "8. Governing Law",
                  "These Terms are governed by and construed in accordance with the laws of the developer's jurisdiction.",
                ),
                _buildTermsSection(
                  "9. Changes to Terms",
                  "We reserve the right to modify these Terms at any time by updating the effective date.",
                ),
                _buildTermsSection(
                  "10. Contact Information",
                  "For questions, contact us at: elqutamy.zeyad8@gmail.com",
                ),
                const Divider(color: Colors.white24, height: 32),
                Text(
                  "Last Updated: February 27, 2026",
                  style: AppTheme.caption(
                    context,
                  ).copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.ok.getString(context),
              style: TextStyle(
                color: AppTheme.neonCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
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
