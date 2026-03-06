import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../../color_mixer_game.dart';
import '../../helpers/theme_constants.dart';
import '../../core/save_manager.dart';
import '../../components/ui/responsive_components.dart';

class LanguageSelectionOverlay extends StatefulWidget {
  final ColorMixerGame game;
  const LanguageSelectionOverlay({super.key, required this.game});

  @override
  State<LanguageSelectionOverlay> createState() =>
      _LanguageSelectionOverlayState();
}

class _LanguageSelectionOverlayState extends State<LanguageSelectionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectLanguage(String locale) async {
    final localization = FlutterLocalization.instance;
    localization.translate(locale);
    await SaveManager.saveHasSeenLanguage(true);

    if (mounted) {
      widget.game.transitionTo('LanguageSelection', 'Tutorial');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.backgroundGradient,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ResponsiveCard(
                    padding: ResponsiveHelper.containerPadding(context),
                    color: AppTheme.primaryDark.withValues(alpha: 0.8),
                    borderColor: AppTheme.neonCyan,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.language_rounded,
                          size: 64,
                          color: AppTheme.neonCyan,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Select Language\nاختر اللغة",
                          textAlign: TextAlign.center,
                          style: AppTheme.heading2(
                            context,
                          ).copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 32),
                        _LanguageButton(
                          label: "English",
                          locale: 'en',
                          onTap: () => _selectLanguage('en'),
                        ),
                        const SizedBox(height: 16),
                        _LanguageButton(
                          label: "العربية",
                          locale: 'ar',
                          onTap: () => _selectLanguage('ar'),
                          isArabic: true,
                        ),
                      ],
                    ),
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

class _LanguageButton extends StatelessWidget {
  final String label;
  final String locale;
  final VoidCallback onTap;
  final bool isArabic;

  const _LanguageButton({
    required this.label,
    required this.locale,
    required this.onTap,
    this.isArabic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 300),
      child: ResponsiveButton(
        label: label,
        onPressed: onTap,
        isLarge: true,
        color: isArabic ? AppTheme.success : AppTheme.neonCyan,
      ),
    );
  }
}
