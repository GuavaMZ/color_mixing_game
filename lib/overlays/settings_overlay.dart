import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../color_mixer_game.dart';
import '../helpers/string_manager.dart';
import '../helpers/theme_constants.dart';
import '../helpers/audio_manager.dart';

class SettingsOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const SettingsOverlay({super.key, required this.game});

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final AudioManager _audio = AudioManager();
  final FlutterLocalization _localization = FlutterLocalization.instance;

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

  void _close() {
    _audio.playButton();
    _controller.reverse().then((_) {
      widget.game.overlays.remove('Settings');
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.black.withValues(alpha: 0.4),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.spacing(context, 24),
              ),
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.responsive(
                  context,
                  mobile: 340.0,
                  tablet: 420.0,
                  desktop: 480.0,
                ),
              ),
              child: Container(
                decoration: AppTheme.cosmicCard(
                  borderRadius: 30,
                  fillColor: AppTheme.primaryDark,
                  borderColor: AppTheme.neonCyan.withValues(alpha: 0.3),
                  hasGlow: true,
                ),
                padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.settings.getString(context),
                          style: AppTheme.heading2(context),
                        ),
                        _CloseButton(onTap: _close),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Sound Effects toggle
                    _SettingsTile(
                      icon: Icons.volume_up_rounded,
                      title: AppStrings.soundEffects.getString(context),
                      trailing: _ToggleSwitch(
                        value: _audio.sfxEnabled,
                        onChanged: (value) {
                          setState(() {
                            _audio.sfxEnabled = value;
                          });
                          if (value) _audio.playButton();
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Music toggle
                    _SettingsTile(
                      icon: Icons.music_note_rounded,
                      title: AppStrings.music.getString(context),
                      trailing: _ToggleSwitch(
                        value: _audio.musicEnabled,
                        onChanged: (value) {
                          _audio.playButton();
                          setState(() {
                            _audio.musicEnabled = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Language selector
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      title: '',
                      trailing: _LanguageSelector(
                        currentLocale:
                            _localization.currentLocale?.languageCode ?? 'en',
                        onChanged: (code) {
                          _audio.playButton();
                          _localization.translate(code);
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: _GradientButton(
                        label: AppStrings.back.getString(context).toUpperCase(),
                        onTap: _close,
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
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryMedium.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.8),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: AppTheme.bodyLarge(context))),
          trailing,
        ],
      ),
    );
  }
}

class _ToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: value ? AppTheme.primaryGradient : null,
          color: value ? null : Colors.white.withValues(alpha: 0.15),
          border: Border.all(color: Colors.black, width: 2.5),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  final String currentLocale;
  final ValueChanged<String> onChanged;

  const _LanguageSelector({
    required this.currentLocale,
    required this.onChanged,
  });

  static const Map<String, String> _languages = {
    'en': 'EN',
    'ar': 'عر',
    'es': 'ES',
    'fr': 'FR',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryMedium.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _languages.entries.map((entry) {
          final isSelected = entry.key == currentLocale;
          return GestureDetector(
            onTap: () => onChanged(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppTheme.secondaryGradient : null,
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                entry.value,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.5),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryMedium.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.close_rounded,
            color: Colors.white.withValues(alpha: 0.7),
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cosmicCard(
        borderRadius: 16,
        fillColor: AppTheme.primaryColor.withValues(alpha: 0.2),
        borderColor: AppTheme.neonCyan,
        hasGlow: true,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                label,
                style: AppTheme.buttonText(context, isLarge: true),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
