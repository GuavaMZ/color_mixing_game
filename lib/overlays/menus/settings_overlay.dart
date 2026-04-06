import 'package:color_mixing_deductive/helpers/global_variables.dart';
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
              final successStr = AppStrings.success.getString(context);
              final downloadedStr = AppStrings.updateDownloaded.getString(
                context,
              );
              final errorStr = AppStrings.error.getString(context);
              try {
                await _shorebird.update();
                if (mounted) {
                  _showResultDialog(successStr, downloadedStr);
                }
              } catch (e) {
                if (mounted) {
                  _showResultDialog(errorStr, '$errorStr: $e');
                }
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
    AudioManager().playButton();
    widget.game.returnToMainMenu();
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
    if (!mounted) return;
    if (redeemed) {
      _showResultDialog(
        AppStrings.alreadyRedeemed.getString(context),
        AppStrings.alreadyRedeemedDesc.getString(context),
      );
      return;
    }

    if (code == 'lifesmzcmp080799') {
      LivesManager().addLives(3);
      await SaveManager.markCodeAsRedeemed(code);
      _audio.playWin();
      if (mounted) {
        _showResultDialog(
          AppStrings.success.getString(context),
          AppStrings.codeRedeemedLives.getString(context),
        );
      }
    } else if (code == 'richiemzcmp080799') {
      await widget.game.addCoins(99999);
      await SaveManager.markCodeAsRedeemed(code);
      _audio.playWin();
      if (mounted) {
        _showResultDialog(
          AppStrings.jackpot.getString(context),
          AppStrings.codeRedeemedCoins.getString(context),
        );
      }
    } else if (code == 'helpersmzcmp080799') {
      widget.game.addHelpers('extra_drops', 3);
      widget.game.addHelpers('help_drop', 3);
      widget.game.addHelpers('reveal_color', 3);
      widget.game.addHelpers('undo', 3);

      await SaveManager.markCodeAsRedeemed(code);
      _audio.playWin();
      if (mounted) {
        _showResultDialog(
          AppStrings.success.getString(context),
          AppStrings.codeRedeemedHelpers.getString(context),
        );
      }
    } else {
      _audio.playButton();
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
          // Standard Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.backgroundGradient,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.spacing(context, 20),
                vertical: ResponsiveHelper.spacing(context, 20),
              ),
              child: AnimatedCard(
                onTap: () {}, // For glow effect
                hasGlow: true,
                borderRadius: 24,
                fillColor: AppTheme.primaryDark.withValues(alpha: 0.7),
                borderColor: AppTheme.neonCyan.withValues(alpha: 0.3),
                padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 20)),
                child: SingleChildScrollView(
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

                      // Settings Tiles
                      Column(
                        children: [
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
                                  _localization.currentLocale?.languageCode ??
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
                                  AppStrings.accessibility.getString(context),
                                  style: AppTheme.bodyLarge(context).copyWith(
                                    color: AppTheme.neonCyan,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _SettingsTile(
                            icon: Icons.motion_photos_off_rounded,
                            title: AppStrings.reducedMotion.getString(context),
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
                                      : 'v${GlobalConstants.appVersion}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
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

                      const SizedBox(height: 24),

                      /* 
                      // ── VIP Scientist Section ──────────────────────────────
                      ValueListenableBuilder<bool>(
                        valueListenable: VipManager.instance.isVip,
                        builder: (ctx, isVip, _) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isVip
                                    ? const Color(0xFFFFD700)
                                    : Colors.white24,
                                width: isVip ? 2 : 1,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isVip
                                    ? [
                                        const Color(
                                          0xFFFFD700,
                                        ).withValues(alpha: 0.15),
                                        const Color(
                                          0xFFFF8C00,
                                        ).withValues(alpha: 0.05),
                                      ]
                                    : [
                                        Colors.white.withValues(alpha: 0.04),
                                        Colors.white.withValues(alpha: 0.02),
                                      ],
                              ),
                              boxShadow: isVip
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFFD700,
                                        ).withValues(alpha: 0.2),
                                        blurRadius: 16,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.workspace_premium_rounded,
                                      color: Color(0xFFFFD700),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppStrings.vipTitle.getString(context),
                                      style: AppTheme.heading3(context)
                                          .copyWith(
                                            color: const Color(0xFFFFD700),
                                            fontSize: 16,
                                          ),
                                    ),
                                    if (isVip) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.green.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'ACTIVE',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (isVip)
                                  Text(
                                    '✅ ${VipManager.instance.expiryLabel} · +20% coins on every win',
                                    style: AppTheme.bodySmall(
                                      context,
                                    ).copyWith(color: Colors.white70),
                                  )
                                else ...[
                                  _vipBenefitRow(
                                    '🚫',
                                    AppStrings.vipBenefit1.getString(context),
                                  ),
                                  _vipBenefitRow(
                                    '💰',
                                    AppStrings.vipBenefit2.getString(context),
                                  ),
                                  _vipBenefitRow(
                                    '🧪',
                                    AppStrings.vipBenefit3.getString(context),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFFFD700,
                                        ),
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      onPressed: () async {
                                        _audio.playButton();
                                        // TODO: hook to CoinStoreService vip_monthly product
                                        // For dev: activate immediately
                                        await VipManager.instance.activate();
                                        if (mounted) setState(() {});
                                      },
                                      child: Text(
                                        AppStrings.vipSubscribe.getString(
                                          context,
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      */

                      // Tutorial Button
                      SizedBox(
                        width: double.infinity,
                        child: EnhancedButton(
                          label: AppStrings.replayTutorial.getString(context),
                          icon: Icons.school_rounded,
                          onTap: () {
                            _audio.playButton();
                            widget.game.transitionTo('Settings', 'Tutorial');
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

  /*
  Widget _vipBenefitRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  */
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLocale,
          dropdownColor: AppTheme.primaryDark,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppTheme.neonCyan,
            size: 20,
          ),
          items: const [
            DropdownMenuItem(value: 'en', child: Text('English', style: TextStyle(color: Colors.white, fontSize: 13))),
            DropdownMenuItem(value: 'tr', child: Text('Türkçe', style: TextStyle(color: Colors.white, fontSize: 13))),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}
