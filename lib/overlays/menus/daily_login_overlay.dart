import 'package:flutter/material.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:color_mixing_deductive/components/ui/animated_card.dart';
import 'package:color_mixing_deductive/components/ui/enhanced_button.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/daily_login_manager.dart';

class DailyLoginOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const DailyLoginOverlay({super.key, required this.game});

  @override
  State<DailyLoginOverlay> createState() => _DailyLoginOverlayState();
}

class _DailyLoginOverlayState extends State<DailyLoginOverlay> {
  int _currentStreak = 1;
  bool _canClaim = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final streak = await DailyLoginManager.getCurrentStreak();
    final canClaim = await DailyLoginManager.canClaimToday();

    // If they claimed today already, they are on day X, and can't claim
    // If they haven't claimed, they are 'about to claim' day X

    if (mounted) {
      setState(() {
        _currentStreak = streak;
        _canClaim = canClaim;
      });
    }
  }

  Future<void> _claimReward() async {
    if (!_canClaim) return;
    AudioManager().playButton();

    final rewarded = await DailyLoginManager.claimToday();

    // Update local state to reflect claimed status visually
    if (mounted) {
      if (rewarded > 0) {
        widget.game.totalCoins.value += rewarded;
      }

      setState(() {
        _canClaim = false;
        // Keep _currentStreak the same so it shows as 'claimed' for today
      });
    }

    // Show a quick success dialog or just pop
    widget.game.returnToMainMenu();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Background Dim
          Container(color: Colors.black.withValues(alpha: 0.8)),

          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AnimatedCard(
                onTap: () {},
                hasGlow: true,
                borderRadius: 24,
                fillColor: AppTheme.primaryDark.withValues(alpha: 0.95),
                borderColor: AppTheme.neonCyan,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.dailyLoginTitle.getString(context),
                          style: AppTheme.heading2(
                            context,
                          ).copyWith(color: Colors.white, fontSize: 24),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            AudioManager().playButton();
                            widget.game.returnToMainMenu();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.dailyLoginSubtitle.getString(context),
                      style: AppTheme.bodyMedium(
                        context,
                      ).copyWith(color: Colors.white60),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // 7-Day Track
                    _buildDaysTrack(),

                    const SizedBox(height: 32),

                    // Claim Button
                    SizedBox(
                      width: double.infinity,
                      child: EnhancedButton(
                        label: _canClaim
                            ? AppStrings.claimDay
                                  .getString(context)
                                  .replaceFirst('%s', '$_currentStreak')
                            : AppStrings.comeBackTomorrow.getString(context),
                        icon: _canClaim
                            ? Icons.redeem_rounded
                            : Icons.check_circle_rounded,
                        // If we can't claim, dim the button and disable interaction
                        // (EnhancedButton handles this gracefully if we pass a null onTap, or we can just pass an empty one)
                        onTap: _canClaim ? _claimReward : () {},
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
  }

  Widget _buildDaysTrack() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(7, (index) {
        final day = index + 1;

        // Logic for state:
        // Past: day < _currentStreak || (day == _currentStreak && !_canClaim)
        // Today: day == _currentStreak && _canClaim
        // Future: day > _currentStreak

        bool isPast =
            day < _currentStreak || (day == _currentStreak && !_canClaim);
        bool isToday = day == _currentStreak && _canClaim;
        bool isFuture = day > _currentStreak;

        return _buildDayItem(
          day,
          isPast: isPast,
          isToday: isToday,
          isFuture: isFuture,
        );
      }),
    );
  }

  Widget _buildDayItem(
    int day, {
    required bool isPast,
    required bool isToday,
    required bool isFuture,
  }) {
    final reward = DailyLoginManager.getRewardForDay(day);

    // Styling based on state
    Color borderColor = Colors.white24;
    Color bgColor = Colors.black45;
    Color iconColor = Colors.white30;
    Color textColor = Colors.white54;

    if (isPast) {
      borderColor = Colors.green;
      bgColor = Colors.green.withValues(alpha: 0.2);
      iconColor = Colors.green;
      textColor = Colors.green;
    } else if (isToday) {
      borderColor = AppTheme.neonCyan;
      bgColor = AppTheme.neonCyan.withValues(alpha: 0.2);
      iconColor = AppTheme.neonCyan;
      textColor = Colors.white;
    } else if (isFuture && day == 7) {
      borderColor = AppTheme.neonMagenta;
      bgColor = AppTheme.neonMagenta.withValues(alpha: 0.1);
      iconColor = AppTheme.neonMagenta;
    }

    return Container(
      width: day == 7 ? 160 : 70, // Make day 7 larger
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isToday ? 2 : 1),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.3),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.dayLabel.getString(context).replaceFirst('%s', '$day'),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            isPast
                ? Icons.check_circle_rounded
                : (day == 7
                      ? Icons.stars_rounded
                      : Icons.monetization_on_rounded),
            color: iconColor,
            size: day == 7 ? 32 : 24,
          ),
          const SizedBox(height: 4),
          if (!isPast)
            Text(
              "$reward",
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
