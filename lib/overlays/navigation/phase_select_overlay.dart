import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../../../color_mixer_game.dart';
import '../../../core/phase_model.dart';
import '../../helpers/string_manager.dart';
import '../../helpers/theme_constants.dart';
import '../../helpers/audio_manager.dart';
import '../../components/ui/responsive_components.dart';

class PhaseSelectOverlay extends StatefulWidget {
  final ColorMixerGame game;

  const PhaseSelectOverlay({super.key, required this.game});

  @override
  State<PhaseSelectOverlay> createState() => _PhaseSelectOverlayState();
}

class _PhaseSelectOverlayState extends State<PhaseSelectOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectPhase(PhaseModel phase) {
    if (!widget.game.levelManager.isPhaseUnlocked(phase.id)) return;
    AudioManager().playButton();
    widget.game.showLevelMapForPhase(phase.id);
  }

  @override
  Widget build(BuildContext context) {
    final lm = widget.game.levelManager;
    final totalStars = PhaseCatalog.all.fold(
      0,
      (sum, p) => sum + lm.phaseStars(p.id),
    );
    final maxStars = PhaseCatalog.all.fold(
      0,
      (sum, p) => sum + lm.levelsForPhase(p.id).length * 3,
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppTheme.cosmicBackground),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, totalStars, maxStars),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.spacing(context, 16),
                      vertical: 8,
                    ),
                    itemCount: PhaseCatalog.all.length,
                    itemBuilder: (context, index) {
                      final phase = PhaseCatalog.all[index];
                      final unlocked = lm.isPhaseUnlocked(phase.id);
                      final (completed, total) = lm.phaseProgress(phase.id);
                      final stars = lm.phaseStars(phase.id);
                      return _PhaseCard(
                        phase: phase,
                        isUnlocked: unlocked,
                        completed: completed,
                        total: total,
                        stars: stars,
                        delay: index * 80,
                        onTap: () => _selectPhase(phase),
                      );
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

  Widget _buildHeader(BuildContext context, int totalStars, int maxStars) {
    return Padding(
      padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 16)),
      child: Row(
        children: [
          ResponsiveIconButton(
            onPressed: () {
              AudioManager().playButton();
              widget.game.returnToMainMenu();
            },
            icon: Icons.arrow_back_ios_rounded,
            color: AppTheme.neonCyan,
            size: 22,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            borderColor: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.phaseSelectTitle.getString(context),
                  style: AppTheme.heading2(context),
                ),
                Text(
                  AppStrings.classicMode.getString(context),
                  style: const TextStyle(
                    color: AppTheme.neonCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Total stars badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: AppTheme.cosmicGlass(
              borderRadius: 20,
              borderColor: AppTheme.electricYellow.withValues(alpha: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppTheme.electricYellow,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '$totalStars / $maxStars',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Phase Card ───────────────────────────────────────────────────────────────

class _PhaseCard extends StatefulWidget {
  final PhaseModel phase;
  final bool isUnlocked;
  final int completed;
  final int total;
  final int stars;
  final int delay;
  final VoidCallback onTap;

  const _PhaseCard({
    required this.phase,
    required this.isUnlocked,
    required this.completed,
    required this.total,
    required this.stars,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_PhaseCard> createState() => _PhaseCardState();
}

class _PhaseCardState extends State<_PhaseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 40,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
    final phase = widget.phase;
    final isComplete = widget.completed == widget.total && widget.total > 0;
    final progress = widget.total > 0 ? widget.completed / widget.total : 0.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _slideAnimation.value),
        child: Opacity(opacity: _fadeAnimation.value, child: child),
      ),
      child: GestureDetector(
        onTap: widget.isUnlocked ? widget.onTap : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: AppTheme.cosmicCard(
            borderRadius: 24,
            fillColor: widget.isUnlocked
                ? phase.color.withValues(alpha: isComplete ? 0.25 : 0.12)
                : AppTheme.primaryDark.withValues(alpha: 0.5),
            borderColor: widget.isUnlocked
                ? isComplete
                      ? AppTheme.electricYellow
                      : phase.color.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.1),
            borderWidth: isComplete ? 2.5 : 1.5,
            hasGlow: widget.isUnlocked,
            glowColor: isComplete ? AppTheme.electricYellow : phase.color,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Phase Icon
                _buildIcon(phase, isComplete),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: _buildContent(context, phase, progress, isComplete),
                ),
                const SizedBox(width: 12),
                // Right side
                _buildRightSide(isComplete),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(PhaseModel phase, bool isComplete) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.isUnlocked) ...[
          // Glow ring
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  phase.color.withValues(alpha: 0.4),
                  phase.color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isUnlocked
                ? phase.color.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.3),
            border: Border.all(
              color: widget.isUnlocked ? phase.color : Colors.white12,
              width: 2,
            ),
          ),
          child: Icon(
            widget.isUnlocked ? phase.icon : Icons.lock_rounded,
            color: widget.isUnlocked ? phase.color : Colors.white24,
            size: 26,
          ),
        ),
        if (isComplete)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.success,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    PhaseModel phase,
    double progress,
    bool isComplete,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${AppStrings.phasePrefix.getString(context)} ${phase.id}',
              style: TextStyle(
                color: widget.isUnlocked ? phase.color : Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            if (isComplete) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '✓ ${AppStrings.phaseDone.getString(context)}',
                  style: const TextStyle(
                    color: AppTheme.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          phase.nameKey.getString(context),
          style: TextStyle(
            color: widget.isUnlocked ? Colors.white : Colors.white38,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          phase.descKey.getString(context),
          style: TextStyle(
            color: widget.isUnlocked ? Colors.white60 : Colors.white24,
            fontSize: 12,
          ),
        ),
        if (widget.isUnlocked) ...[
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? AppTheme.success : phase.color,
              ),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.phaseLevelsCount
                .getString(context)
                .replaceFirst('%s', '${widget.completed}')
                .replaceFirst('%s', '${widget.total}'),
            style: TextStyle(
              color: widget.isUnlocked ? Colors.white54 : Colors.white24,
              fontSize: 11,
            ),
          ),
        ] else ...[
          const SizedBox(height: 6),
          Text(
            AppStrings.phaseLockedHint.getString(context),
            style: const TextStyle(color: Colors.white30, fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _buildRightSide(bool isComplete) {
    if (!widget.isUnlocked) {
      return Icon(Icons.lock_rounded, color: Colors.white24, size: 20);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStarCount(),
        const SizedBox(height: 8),
        Icon(
          Icons.chevron_right_rounded,
          color: widget.phase.color.withValues(alpha: 0.7),
          size: 24,
        ),
      ],
    );
  }

  Widget _buildStarCount() {
    final maxStars = widget.total * 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.electricYellow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.electricYellow.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            color: AppTheme.electricYellow,
            size: 14,
          ),
          const SizedBox(width: 3),
          Text(
            AppStrings.starsCount
                .getString(context)
                .replaceFirst('%s', '${widget.stars}')
                .replaceFirst('%s', '$maxStars'),
            style: const TextStyle(
              color: AppTheme.electricYellow,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Phase Color Badge ─────────────────────────────────────────────────────────
// Used internally by cards to show the color swatch for this phase
