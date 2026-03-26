import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/helpers/theme_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:restart_app/restart_app.dart';

class IntroSplashOverlay extends StatefulWidget {
  final ColorMixerGame game;

  const IntroSplashOverlay({super.key, required this.game});

  @override
  State<IntroSplashOverlay> createState() => _IntroSplashOverlayState();
}

class _IntroSplashOverlayState extends State<IntroSplashOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<double> _barFade;

  final ShorebirdUpdater _updater = ShorebirdUpdater();
  String _statusKey = AppStrings.labArchivesInitialized;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
      ),
    );

    _barFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    _startInitalization();
  }

  Future<void> _startInitalization() async {
    _controller.forward();

    // Check for updates in parallel with animations
    final requiresRestart = await _checkForUpdates();

    // Small extra delay to ensure logo isn't too fast
    await Future.delayed(const Duration(milliseconds: 1000));

    if (requiresRestart) {
      _showRestartDialog();
      return; // Break initialization loop to prevent moving to MainMenu
    }

    if (mounted) {
      final hasSeenLanguage = await SaveManager.loadHasSeenLanguage();
      final hasSeenTutorial = await SaveManager.loadHasSeenTutorial();

      widget.game.overlays.remove('IntroSplash');
      if (!hasSeenLanguage) {
        widget.game.overlays.add('LanguageSelection');
      } else if (!hasSeenTutorial) {
        widget.game.overlays.add('Tutorial');
      } else {
        widget.game.overlays.add('MainMenu');
      }
    }
  }

  Future<bool> _checkForUpdates() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) return false;

      setState(() => _statusKey = AppStrings.checkingForUpdates);

      final isUpdateAvailable = await _updater.checkForUpdate();
      if (isUpdateAvailable == UpdateStatus.outdated) {
        setState(() => _statusKey = AppStrings.downloadingUpdate);

        await _updater.update();

        if (mounted) {
          setState(() => _statusKey = AppStrings.updateReady);
        }
        return true;
      } else {
        setState(() => _statusKey = AppStrings.labArchivesInitialized);
        return false;
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
      if (mounted) {
        setState(() => _statusKey = AppStrings.labArchivesInitialized);
      }
      return false;
    }
  }

  void _showRestartDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E2A4A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            AppStrings.updateReady.getString(context),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.system_update_rounded,
                color: AppTheme.neonCyan,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.updateReadyDesc.getString(context),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                Restart.restartApp();
              },
              child: Text(
                AppStrings.restart.getString(context),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Deep Blue
      body: Stack(
        children: [
          // Logo + Text in Center
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          FadeTransition(
                            opacity: _logoFade,
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: SvgPicture.asset(
                                'assets/images/dv-logo.svg',
                                width: 150,
                                height: 150,
                                colorFilter: const ColorFilter.mode(
                                  Colors.white,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          // Text
                          FadeTransition(
                            opacity: _textFade,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                AppStrings.presents.getString(context),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 4.0,
                                  fontFamily: 'Roboto',
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 100,
                          ), // Space for the bottom bar
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Mirror the loading bar at the bottom (Static 100% since loading is done)
          Positioned(
            left: 40,
            right: 40,
            bottom: 60,
            child: FadeTransition(
              opacity: _barFade,
              child: _StaticPremiumBar(statusKey: _statusKey),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticPremiumBar extends StatelessWidget {
  final String statusKey;
  const _StaticPremiumBar({required this.statusKey});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          statusKey.getString(context).toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
            fontFamily: 'Roboto',
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonCyan.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
