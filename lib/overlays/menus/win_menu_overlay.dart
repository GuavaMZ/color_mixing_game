import '../../../color_mixer_game.dart';
import '../../../core/ad_manager.dart';
import '../../../core/color_science.dart';
import '../../helpers/string_manager.dart';
import '../../helpers/theme_constants.dart';
import '../../helpers/audio_manager.dart';
import '../../helpers/visual_effects.dart';
import '../../components/ui/enhanced_button.dart';
import '../../components/ui/animated_card.dart';
import '../../components/ui/responsive_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

class WinMenuOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const WinMenuOverlay({super.key, required this.game});

  @override
  State<WinMenuOverlay> createState() => _WinMenuOverlayState();
}

class _WinMenuOverlayState extends State<WinMenuOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _starsController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final AudioManager _audio = AudioManager();

  // Confetti particles
  List<Widget> _confetti = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _starsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Delay star animation & Confetti
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _starsController.forward();
        _triggerConfetti();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _awardCoins();
    });
  }

  void _triggerConfetti() {
    final size = MediaQuery.of(context).size;
    setState(() {
      _confetti = [
        ...VisualEffectManager().createConfetti(
          Offset(size.width * 0.2, size.height * 0.3),
        ),
        ...VisualEffectManager().createConfetti(
          Offset(size.width * 0.8, size.height * 0.3),
        ),
        ...VisualEffectManager().createConfetti(
          Offset(size.width * 0.5, size.height * 0.1),
        ),
      ];
    });
  }

  void _awardCoins() {
    final stars = widget.game.calculateStars();
    int coinsEarned = 0;
    if (stars == 3) coinsEarned = 100;
    if (stars == 2) coinsEarned = 50;
    if (stars == 1) coinsEarned = 20;

    widget.game.addCoins(coinsEarned);
  }

  @override
  void dispose() {
    _controller.dispose();
    _starsController.dispose();
    super.dispose();
  }

  String _getResultMessage(int stars, BuildContext context) {
    if (stars == 3) return AppStrings.perfectScore.getString(context);
    if (stars == 2) return AppStrings.greatJob.getString(context);
    return AppStrings.goodWork.getString(context);
  }

  @override
  Widget build(BuildContext context) {
    final stars = widget.game.calculateStars();
    final drops = widget.game.totalDrops.value;

    return Stack(
      children: [
        // Background Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
        ),

        // Confetti Layer
        ..._confetti,

        Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveHelper.responsive(
                    context,
                    mobile: 350.0,
                    tablet: 450.0,
                    desktop: 500.0,
                  ),
                ),
                child: AnimatedCard(
                  onTap: () {}, // Interactive glow only
                  hasGlow: true,
                  borderRadius: 35,
                  padding: EdgeInsets.zero,
                  fillColor: AppTheme.primaryMedium.withValues(alpha: 0.5),
                  child: Container(
                    padding: EdgeInsets.all(
                      ResponsiveHelper.spacing(context, 24),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        width: 2,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Trophy icon with glow
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.amber.withValues(alpha: 0.4),
                                Colors.amber.withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween(begin: 0.5, end: 1.0),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Icon(
                                  Icons.emoji_events_rounded,
                                  color: Colors.amber,
                                  size: ResponsiveHelper.iconSize(context, 80),
                                  shadows: [
                                    Shadow(
                                      color: Colors.amber.withValues(
                                        alpha: 0.6,
                                      ),
                                      blurRadius: 25,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        SizedBox(height: ResponsiveHelper.spacing(context, 16)),

                        // Win text
                        Text(
                          AppStrings.wonText.getString(context),
                          style: AppTheme.heading1(context).copyWith(
                            fontSize: ResponsiveHelper.fontSize(context, 48),
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.purpleAccent.withValues(
                                  alpha: 0.6,
                                ),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: ResponsiveHelper.spacing(context, 20)),

                        // Animated Stars
                        AnimatedBuilder(
                          animation: _starsController,
                          builder: (context, child) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(3, (index) {
                                final delay = index * 0.2;
                                final progress =
                                    ((_starsController.value - delay) / 0.4)
                                        .clamp(0.0, 1.0);
                                final isEarned = index < stars;

                                return TweenAnimationBuilder<double>(
                                  duration: Duration.zero,
                                  tween: Tween(begin: 0, end: progress),
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: isEarned
                                          ? Curves.elasticOut.transform(value)
                                          : 0.8,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Icon(
                                          isEarned
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          color: isEarned
                                              ? Colors.amber
                                              : Colors.white.withValues(
                                                  alpha: 0.3,
                                                ),
                                          size: ResponsiveHelper.iconSize(
                                            context,
                                            50,
                                          ),
                                          shadows: isEarned
                                              ? [
                                                  Shadow(
                                                    color: Colors.amber
                                                        .withValues(alpha: 0.6),
                                                    blurRadius: 15,
                                                  ),
                                                ]
                                              : [],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }),
                            );
                          },
                        ),

                        SizedBox(height: ResponsiveHelper.spacing(context, 12)),

                        // Result message
                        Text(
                          _getResultMessage(stars, context),
                          style: AppTheme.bodyLarge(context).copyWith(
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.blueAccent.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: ResponsiveHelper.spacing(context, 12)),

                        // Coins Earned Display
                        _buildCoinsEarnedDisplay(context, stars),

                        SizedBox(height: ResponsiveHelper.spacing(context, 20)),

                        // Stats container
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: AppTheme.cosmicCard(
                            borderRadius: 16,
                            fillColor: Colors.black.withValues(alpha: 0.2),
                            borderColor: Colors.white.withValues(alpha: 0.1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.water_drop_rounded,
                                color: AppTheme.neonCyan,
                                size: 22,
                                shadows: [
                                  Shadow(
                                    color: AppTheme.neonCyan.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "${AppStrings.dropsUsed.getString(context)}: $drops",
                                style: AppTheme.buttonText(context).copyWith(
                                  color: Colors.white,
                                  fontSize: ResponsiveHelper.fontSize(
                                    context,
                                    16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.spacing(context, 28)),

                        // Scientific Lab Report
                        _buildLabReport(context),

                        SizedBox(height: ResponsiveHelper.spacing(context, 20)),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: EnhancedButton(
                                label: AppStrings.replayLevel.getString(
                                  context,
                                ),
                                icon: Icons.replay_rounded,
                                isOutlined: true,
                                onTap: () {
                                  _audio.playButton();
                                  widget.game.resetGame();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: EnhancedButton(
                                label: AppStrings.newLevel.getString(context),
                                icon: Icons.arrow_forward_rounded,
                                onTap: () {
                                  _audio.playButton();
                                  if (widget
                                          .game
                                          .levelManager
                                          .currentLevelIndex >=
                                      10) {
                                    AdManager().showInterstitialAd();
                                  }
                                  widget.game.goToNextLevel();
                                },
                              ),
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
      ],
    );
  }

  Widget _buildCoinsEarnedDisplay(BuildContext context, int stars) {
    int coins = 0;
    if (stars == 3) coins = 100;
    if (stars == 2) coins = 50;
    if (stars == 1) coins = 20;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.amber.withValues(alpha: 0.2), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.monetization_on_rounded,
            color: Colors.amber,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            AppStrings.coinsEarned
                .getString(context)
                .replaceFirst('%s', coins.toString()),
            style: AppTheme.buttonText(context).copyWith(
              color: Colors.amberAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Scientific Lab Report section showing color science data.
  Widget _buildLabReport(BuildContext context) {
    final targetColor = widget.game.targetColor;
    final wavelength = ColorScience.estimateWavelength(targetColor);
    final spectralRegion = ColorScience.getSpectralRegion(wavelength);
    final temp = ColorScience.getColorTemperature(targetColor);
    final currentColor = widget.game.beaker.currentColor;
    final harmony = ColorScience.getHarmonyType(currentColor, targetColor);
    final fact = ColorScience.getColorFact(targetColor);

    String tempLabel;
    switch (temp['label']) {
      case 'warm':
        tempLabel = AppStrings.warmLabel.getString(context);
        break;
      case 'cool':
        tempLabel = AppStrings.coolLabel.getString(context);
        break;
      default:
        tempLabel = AppStrings.neutralLabel.getString(context);
    }

    String harmonyLabel;
    switch (harmony) {
      case 'complementary':
        harmonyLabel = AppStrings.complementaryLabel.getString(context);
        break;
      case 'analogous':
        harmonyLabel = AppStrings.analogousLabel.getString(context);
        break;
      case 'triadic':
        harmonyLabel = AppStrings.triadicLabel.getString(context);
        break;
      case 'splitComplementary':
        harmonyLabel = AppStrings.splitComplementaryLabel.getString(context);
        break;
      default:
        harmonyLabel = AppStrings.neutralLabel.getString(context);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cosmicCard(
        borderRadius: 20,
        fillColor: Colors.black.withValues(alpha: 0.25),
        borderColor: Colors.cyanAccent.withValues(alpha: 0.15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.science_rounded,
                color: AppTheme.neonCyan,
                size: 20,
                shadows: [
                  Shadow(
                    color: AppTheme.neonCyan.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Text(
                AppStrings.labReport.getString(context),
                style: AppTheme.buttonText(context).copyWith(
                  color: AppTheme.neonCyan,
                  fontSize: ResponsiveHelper.fontSize(context, 14),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Wavelength row with spectral gradient
          _buildReportRow(
            context,
            icon: Icons.waves_rounded,
            iconColor: Colors.purpleAccent,
            label: AppStrings.wavelengthLabel.getString(context),
            value: '$wavelength nm · $spectralRegion',
          ),

          const SizedBox(height: 8),

          // Spectral gradient bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF9400D3), // Violet
                    Color(0xFF4B0082), // Indigo
                    Color(0xFF0000FF), // Blue
                    Color(0xFF00FF00), // Green
                    Color(0xFFFFFF00), // Yellow
                    Color(0xFFFF7F00), // Orange
                    Color(0xFFFF0000), // Red
                  ],
                ),
              ),
              child: Align(
                alignment: Alignment(
                  // Map 380-780nm to -1..1
                  ((wavelength - 380) / 400.0 * 2.0 - 1.0).clamp(-1.0, 1.0),
                  0,
                ),
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.8),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Temperature row
          _buildReportRow(
            context,
            icon: IconData(temp['icon'] as int, fontFamily: 'MaterialIcons'),
            iconColor: temp['label'] == 'warm'
                ? Colors.orangeAccent
                : temp['label'] == 'cool'
                ? Colors.lightBlueAccent
                : Colors.grey,
            label: AppStrings.colorTempLabel.getString(context),
            value: '$tempLabel · ${temp['kelvin']}K',
          ),

          const SizedBox(height: 8),

          // Harmony row
          _buildReportRow(
            context,
            icon: Icons.auto_awesome_rounded,
            iconColor: Colors.amberAccent,
            label: AppStrings.colorHarmonyLabel.getString(context),
            value: harmonyLabel,
          ),

          const SizedBox(height: 12),

          // Did You Know?
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: Colors.amberAccent,
                  size: 18,
                  shadows: [
                    Shadow(
                      color: Colors.amberAccent.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.didYouKnow.getString(context),
                        style: AppTheme.buttonText(context).copyWith(
                          color: Colors.amberAccent,
                          fontSize: ResponsiveHelper.fontSize(context, 11),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fact,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: ResponsiveHelper.fontSize(context, 11),
                          height: 1.4,
                        ),
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
  }

  /// Helper to build a single row in the Lab Report.
  Widget _buildReportRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 16,
          shadows: [
            Shadow(color: iconColor.withValues(alpha: 0.4), blurRadius: 6),
          ],
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: ResponsiveHelper.fontSize(context, 11),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTheme.buttonText(context).copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: ResponsiveHelper.fontSize(context, 12),
          ),
        ),
      ],
    );
  }
}
