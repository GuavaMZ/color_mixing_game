import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../../../color_mixer_game.dart';
import '../../helpers/string_manager.dart';
import '../../helpers/theme_constants.dart';
import '../../helpers/audio_manager.dart';
import '../../helpers/visual_effects.dart';
import '../../components/ui/responsive_components.dart';
import '../../components/ui/animated_card.dart';
import '../../components/ui/enhanced_button.dart';
import '../../core/lives_manager.dart';
import '../../core/save_manager.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

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
  final _shorebird = ShorebirdUpdater();
  int? _currentPatch;
  bool _isCheckingForUpdate = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9, // Slightly larger start
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
    _loadPatchNumber();
  }

  Future<void> _loadPatchNumber() async {
    final patch = await _shorebird.readCurrentPatch();
    if (mounted) {
      setState(() {
        _currentPatch = patch?.number;
      });
    }
  }

  Future<void> _checkForUpdate() async {
    if (_isCheckingForUpdate) return;
    setState(() => _isCheckingForUpdate = true);

    try {
      final status = await _shorebird.checkForUpdate();
      if (mounted) {
        if (status == UpdateStatus.upToDate) {
          _showResultDialog(
            AppStrings.noUpdateAvailable.getString(context),
            AppStrings.latestVersion.getString(context),
          );
        } else if (status == UpdateStatus.outdated) {
          _showUpdateDialog();
        } else {
          _showResultDialog(
            AppStrings.status.getString(context),
            '${AppStrings.status.getString(context)}: ${status.name}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showResultDialog(
          AppStrings.error.getString(context),
          '${AppStrings.error.getString(context)}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingForUpdate = false);
      }
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryDark,
        title: Text(AppStrings.updateAvailable.getString(context)),
        content: Text(AppStrings.updateDesc.getString(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.later.getString(context)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _shorebird.update();
                _showResultDialog(
                  AppStrings.success.getString(context),
                  AppStrings.updateDownloaded.getString(context),
                );
              } catch (e) {
                _showResultDialog(
                  AppStrings.error.getString(context),
                  '${AppStrings.error.getString(context)}: $e',
                );
              }
            },
            child: Text(AppStrings.download.getString(context)),
          ),
        ],
      ),
    );
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

  void _showRedeemDialog(BuildContext context) {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.neonCyan, width: 2),
        ),
        title: Text(
          AppStrings.redeemTitle.getString(context),
          style: AppTheme.heading2(context).copyWith(fontSize: 24),
        ),
        content: TextField(
          controller: codeController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: AppStrings.enterCodeHint.getString(context),
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.cancel.getString(context),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () async {
              final code = codeController.text.trim().toLowerCase();
              Navigator.pop(context);
              await _handleRedeem(code);
            },
            child: Text(
              AppStrings.redeemCode.getString(context),
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

  Future<void> _handleRedeem(String code) async {
    bool redeemed = await SaveManager.isCodeRedeemed(code);
    if (redeemed) {
      _showResultDialog(
        AppStrings.alreadyRedeemed.getString(context),
        AppStrings.alreadyRedeemedDesc.getString(context),
      );
      return;
    }

    if (code == 'lifesmzcmp080799') {
      LivesManager().addLives(3);
      // await SaveManager.markCodeAsRedeemed('totymz');
      _audio.playWin();
      _showResultDialog(
        AppStrings.success.getString(context),
        AppStrings.codeRedeemedLives.getString(context),
      );
    } else if (code == 'richiemzcmp080799') {
      widget.game.addCoins(99999);
      // await SaveManager.markCodeAsRedeemed('richie');
      _audio.playWin();
      _showResultDialog(
        AppStrings.jackpot.getString(context),
        AppStrings.codeRedeemedCoins.getString(context),
      );
    } else {
      _audio.playButton(); // Play some sound
      _showResultDialog(
        AppStrings.invalidCode.getString(context),
        AppStrings.invalidCodeDesc.getString(context),
      );
    }
  }

  void _showResultDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.neonCyan, width: 2),
        ),
        title: Text(
          title,
          style: AppTheme.heading2(context).copyWith(fontSize: 20),
        ),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.ok.getString(context),
              style: TextStyle(color: AppTheme.neonCyan),
            ),
          ),
        ],
      ),
    );
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
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),

          // Content
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.spacing(context, 24),
                ),
                constraints: BoxConstraints(
                  maxWidth: ResponsiveHelper.responsive(
                    context,
                    mobile: 360.0,
                    tablet: 450.0,
                    desktop: 500.0,
                  ),
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: AnimatedCard(
                  onTap: () {}, // For glow effect
                  hasGlow: true,
                  borderRadius: 30,
                  fillColor: AppTheme.primaryDark.withValues(alpha: 0.9),
                  padding: EdgeInsets.all(
                    ResponsiveHelper.spacing(context, 24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShimmerEffect(
                            baseColor: Colors.white,
                            highlightColor: AppTheme.neonCyan,
                            child: Text(
                              AppStrings.settings.getString(context),
                              style: AppTheme.heading2(context),
                            ),
                          ),
                          ResponsiveIconButton(
                            onPressed: _close,
                            icon: Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.7),
                            backgroundColor: AppTheme.primaryMedium.withValues(
                              alpha: 0.3,
                            ),
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Sound Effects toggle
                              _SettingsTile(
                                icon: Icons.volume_up_rounded,
                                title: AppStrings.soundEffects.getString(
                                  context,
                                ),
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
                                title: AppStrings.language.getString(context),
                                trailing: _LanguageSelector(
                                  currentLocale:
                                      _localization
                                          .currentLocale
                                          ?.languageCode ??
                                      'en',
                                  onChanged: (code) {
                                    _audio.playButton();
                                    _localization.translate(code);
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Blind Mode
                              _SettingsTile(
                                icon: Icons.visibility_off_rounded,
                                title: AppStrings.blindMode.getString(context),
                                trailing: _ToggleSwitch(
                                  value: widget.game.globalBlindMode,
                                  onChanged: (value) {
                                    _audio.playButton();
                                    widget.game.toggleBlindMode(value);
                                    setState(() {});
                                  },
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Accessibility Section Header
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.accessibility_new_rounded,
                                      color: AppTheme.neonCyan,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppStrings.accessibility.getString(
                                        context,
                                      ),
                                      style: AppTheme.bodyLarge(context)
                                          .copyWith(
                                            color: AppTheme.neonCyan,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),

                              _SettingsTile(
                                icon: Icons.contrast_rounded,
                                title: AppStrings.highContrast.getString(
                                  context,
                                ),
                                trailing: _ToggleSwitch(
                                  value: widget.game.highContrastEnabled,
                                  onChanged: (value) {
                                    _audio.playButton();
                                    widget.game.toggleHighContrast(value);
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              _SettingsTile(
                                icon: Icons.motion_photos_off_rounded,
                                title: AppStrings.reducedMotion.getString(
                                  context,
                                ),
                                trailing: _ToggleSwitch(
                                  value: widget.game.reducedMotionEnabled,
                                  onChanged: (value) {
                                    _audio.playButton();
                                    widget.game.toggleReducedMotion(value);
                                    setState(() {});
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              _SettingsTile(
                                icon: Icons.system_update_rounded,
                                title: AppStrings.appVersion.getString(context),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _currentPatch != null
                                          ? '${AppStrings.patch.getString(context)} #$_currentPatch'
                                          : 'v1.2.0',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (_isCheckingForUpdate)
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    else
                                      IconButton(
                                        icon: const Icon(
                                          Icons.refresh_rounded,
                                          size: 20,
                                        ),
                                        onPressed: _checkForUpdate,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tutorial Button
                      SizedBox(
                        width: double.infinity,
                        child: EnhancedButton(
                          label: AppStrings.replayTutorial.getString(context),
                          icon: Icons.school_rounded,
                          onTap: () {
                            _audio.playButton();
                            widget.game.overlays.remove('Settings');
                            widget.game.overlays.add('Tutorial');
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Redeem Code Button
                      SizedBox(
                        width: double.infinity,
                        child: EnhancedButton(
                          label: AppStrings.redeemCode.getString(context),
                          icon: Icons.card_giftcard_rounded,
                          isOutlined: true,
                          onTap: () {
                            _audio.playButton();
                            _showRedeemDialog(context);
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Close button
                      SizedBox(
                        width: double.infinity,
                        child: EnhancedButton(
                          label: AppStrings.back
                              .getString(context)
                              .toUpperCase(),
                          icon: Icons.arrow_back_rounded,
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

  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration:
          AppTheme.cosmicGlass(
            borderRadius: 16,
            borderColor: AppTheme.neonCyan.withValues(alpha: 0.2),
          ).copyWith(
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.9),
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
          color: value ? null : Colors.white.withValues(alpha: 0.1),
          border: Border.all(
            color: value ? AppTheme.neonCyan : Colors.white24,
            width: 2.0,
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: AppTheme.neonCyan.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            AnimatedAlign(
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
          ],
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
    'ar': 'AR',
    'es': 'ES',
    'fr': 'FR',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryMedium.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                color: isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.neonMagenta.withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ]
                    : [],
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
