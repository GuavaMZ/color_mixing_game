import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../color_mixer_game.dart';
import '../core/lives_manager.dart';

class PauseMenuOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const PauseMenuOverlay({super.key, required this.game});

  @override
  State<PauseMenuOverlay> createState() => _PauseMenuOverlayState();
}

class _PauseMenuOverlayState extends State<PauseMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final AudioManager _audio = AudioManager();
  bool _showConfirmGiveUp = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resume() {
    _audio.playButton();
    _controller.reverse().then((_) {
      widget.game.overlays.remove('PauseMenu');
    });
  }

  void _quit() {
    AudioManager().playButton();
    LivesManager().consumeLife();
    widget.game.returnToMainMenu();
  }

  void _giveUp() {
    if (!_showConfirmGiveUp) {
      _audio.playButton();
      setState(() {
        _showConfirmGiveUp = true;
      });
      return;
    }

    // Confirm Give Up -> Exit to Map
    _audio.playButton();
    LivesManager().consumeLife();
    final bool isEcho = widget.game.currentMode == GameMode.colorEcho;
    widget.game.currentMode = GameMode.none; // Stop timer
    widget.game.overlays.remove('PauseMenu');
    if (isEcho) {
      widget.game.transitionTo('ColorEchoHUD', 'MainMenu');
    } else {
      widget.game.transitionTo('Controls', 'LevelMap');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Darken background
          FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: _resume,
              child: Container(color: Colors.black.withValues(alpha: 0.7)),
            ),
          ),

          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: ResponsiveHelper.responsive(
                  context,
                  mobile: 300.0,
                  tablet: 350.0,
                ),
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.cosmicGlass(
                  borderRadius: 30,
                  borderColor: AppTheme.neonCyan.withValues(alpha: 0.4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.menu.getString(context),
                      style: AppTheme.heading2(context),
                    ),
                    const SizedBox(height: 30),

                    // Resume Button
                    _MenuButton(
                      label: AppStrings.resume.getString(context),
                      icon: Icons.play_arrow_rounded,
                      color: AppTheme.neonCyan,
                      onTap: _resume,
                    ),
                    const SizedBox(height: 16),

                    // Audio Toggles Row
                    Row(
                      children: [
                        Expanded(
                          child: _AudioToggle(
                            icon: Icons.music_note_rounded,
                            isEnabled: _audio.musicEnabled,
                            onToggle: (v) =>
                                setState(() => _audio.musicEnabled = v),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _AudioToggle(
                            icon: Icons.volume_up_rounded,
                            isEnabled: _audio.sfxEnabled,
                            onToggle: (v) =>
                                setState(() => _audio.sfxEnabled = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Divider(color: Colors.white.withValues(alpha: 0.1)),

                    const SizedBox(height: 16),

                    // Give Up / Quit Area
                    if (_showConfirmGiveUp) ...[
                      Text(
                        AppStrings.giveUpConfirm.getString(context),
                        style: TextStyle(
                          color: AppTheme.electricYellow,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                    ],

                    _MenuButton(
                      label: _showConfirmGiveUp
                          ? AppStrings.areYouSure.getString(context)
                          : AppStrings.giveUp.getString(context),
                      icon: _showConfirmGiveUp
                          ? Icons.warning_rounded
                          : Icons.flag_rounded,
                      color: _showConfirmGiveUp
                          ? Colors.red
                          : AppTheme.neonMagenta,
                      isOutlined: !_showConfirmGiveUp,
                      onTap: _giveUp,
                    ),

                    const SizedBox(height: 16),

                    _MenuButton(
                      label: AppStrings.quit.getString(context),
                      icon: Icons.exit_to_app_rounded,
                      color: Colors.grey,
                      isOutlined: true,
                      onTap: _quit,
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
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isOutlined;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: AppTheme.cosmicCard(
            borderRadius: 16,
            fillColor: isOutlined
                ? Colors.transparent
                : color.withValues(alpha: 0.2),
            borderColor: isOutlined ? color.withValues(alpha: 0.5) : color,
            borderWidth: 1.5,
            hasGlow: !isOutlined,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isOutlined ? color : Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTheme.buttonText(
                  context,
                ).copyWith(color: isOutlined ? color : Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioToggle extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final Function(bool) onToggle;

  const _AudioToggle({
    required this.icon,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AudioManager().playButton();
        onToggle(!isEnabled);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: AppTheme.cosmicCard(
          borderRadius: 12,
          fillColor: isEnabled ? AppTheme.primaryLight : Colors.transparent,
          borderColor: isEnabled
              ? AppTheme.neonCyan
              : Colors.white.withValues(alpha: 0.2),
          hasGlow: isEnabled,
        ),
        child: Icon(
          isEnabled ? icon : Icons.volume_off_rounded,
          color: isEnabled ? AppTheme.neonCyan : Colors.grey,
        ),
      ),
    );
  }
}
