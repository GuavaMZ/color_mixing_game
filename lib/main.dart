import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/overlays/hud/controls_overlay.dart';
import 'package:color_mixing_deductive/overlays/menus/game_over_overlay.dart';
import 'package:color_mixing_deductive/overlays/navigation/level_map_overlay.dart';
import 'package:color_mixing_deductive/overlays/menus/main_menu_overlay.dart';
import 'package:color_mixing_deductive/overlays/menus/settings_overlay.dart';
import 'package:color_mixing_deductive/overlays/navigation/shop_overlay.dart';
import 'package:color_mixing_deductive/overlays/system/transition_overlay.dart';
import 'package:color_mixing_deductive/overlays/menus/win_menu_overlay.dart';
import 'package:color_mixing_deductive/overlays/menus/pause_menu_overlay.dart';
import 'package:color_mixing_deductive/overlays/hud/achievement_notification.dart';
import 'package:color_mixing_deductive/overlays/system/achievements_overlay.dart';
import 'package:color_mixing_deductive/overlays/navigation/gallery_overlay.dart';
import 'package:color_mixing_deductive/overlays/hud/color_echo_hud.dart';
import 'package:color_mixing_deductive/overlays/hud/chaos_lab_hud.dart';
import 'package:color_mixing_deductive/overlays/menus/lab_upgrade_hub.dart';
import 'package:color_mixing_deductive/overlays/menus/echo_win_overlay.dart';
import 'package:color_mixing_deductive/overlays/menus/echo_game_over_overlay.dart';
import 'package:color_mixing_deductive/overlays/menus/chaos_win_overlay.dart';
import 'package:color_mixing_deductive/overlays/menus/chaos_game_over_overlay.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:color_mixing_deductive/overlays/navigation/coin_store_overlay.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:color_mixing_deductive/overlays/system/tutorial_overlay.dart';
import 'package:color_mixing_deductive/overlays/system/loading_overlay.dart';
import 'package:color_mixing_deductive/overlays/system/statistics_overlay.dart';
import 'package:color_mixing_deductive/overlays/navigation/daily_challenge_overlay.dart';
import 'package:color_mixing_deductive/overlays/menus/daily_login_overlay.dart';
import 'package:color_mixing_deductive/overlays/menus/mode_guide_overlay.dart';
import 'package:color_mixing_deductive/overlays/system/blackout_overlay.dart';
import 'package:color_mixing_deductive/overlays/system/random_event_alert_overlay.dart';
import 'package:color_mixing_deductive/overlays/system/intro_splash_overlay.dart';
import 'package:color_mixing_deductive/overlays/system/premium_loading_screen.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:color_mixing_deductive/core/ad_manager.dart';
import 'package:color_mixing_deductive/core/security_service.dart';
import 'package:color_mixing_deductive/core/runtime_integrity_checker.dart';
import 'package:color_mixing_deductive/core/security_audit_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:color_mixing_deductive/core/firebase_sync_provider.dart';
import 'package:color_mixing_deductive/core/cloud_sync_service.dart';
import 'package:color_mixing_deductive/core/save_manager.dart';
import 'package:color_mixing_deductive/firebase_options.dart';
import 'package:color_mixing_deductive/core/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling background message: ${message.messageId}");
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize security services first
  await SecurityService.initialize();
  await RuntimeIntegrityChecker.initialize();
  await SecurityAuditLogger.initialize();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Cloud Sync
    final syncProvider = FirebaseSyncProvider();
    final syncService = CloudSyncService(syncProvider);
    SaveManager.initialize(syncService);

    // Initialize Notifications
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    // SaveManager will still work locally without cloud sync
    SaveManager.initialize(null);
  }

  // Set preferred orientations for mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style and mode
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Initialize localization
  await FlutterLocalization.instance.ensureInitialized();

  // Initialize audio
  await AudioManager().initialize();

  // Initialize Ads
  await AdManager().initialize();

  // Shorebird logging
  final shorebird = ShorebirdUpdater();
  final patch = await shorebird.readCurrentPatch();
  debugPrint('Shorebird Patch: ${patch?.number ?? "None"}');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalization _localization = FlutterLocalization.instance;

  @override
  void initState() {
    _localization.init(
      mapLocales: [
        MapLocale('en', AppStrings.en),
        MapLocale('ar', AppStrings.ar),
        MapLocale('es', AppStrings.es),
        MapLocale('fr', AppStrings.fr),
      ],
      initLanguageCode: 'en',
    );
    _localization.onTranslatedLanguage = _onTranslatedLanguage;

    SecurityAuditLogger.log(
      'app_started',
      'Application started',
      severity: SecurityEventSeverity.info,
      metadata: {'version': '1.3.0+5', 'debug_mode': kDebugMode},
    );

    // Remove native splash after a short delay to ensure everything is ready
    Future.delayed(const Duration(seconds: 1), () {
      FlutterNativeSplash.remove();
    });

    super.initState();
  }

  @override
  void dispose() {
    // Cleanup security services
    SecurityAuditLogger.dispose();
    super.dispose();
  }

  void _onTranslatedLanguage(Locale? locale) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Color Lab',
      supportedLocales: _localization.supportedLocales,
      localizationsDelegates: _localization.localizationsDelegates,
      theme: ThemeData(
        fontFamily: 'Roboto',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF667eea),
          secondary: Color(0xFF764ba2),
          surface: Color(0xFF16213E),
        ),
      ),
      builder: (context, child) {
        final data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(
            textScaler: data.textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.4,
            ),
          ),
          child: child!,
        );
      },
      home: const _GameSection(),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _GameSection — owns the game instance and layers TransitionOverlay on top
// using a plain Flutter Stack so it is ALWAYS rendered above every Flame overlay.
// ────────────────────────────────────────────────────────────────────────────
class _GameSection extends StatefulWidget {
  const _GameSection();

  @override
  State<_GameSection> createState() => _GameSectionState();
}

class _GameSectionState extends State<_GameSection> {
  final ColorMixerGame _game = ColorMixerGame();

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          AppStrings.quitGame.getString(context),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          AppStrings.areYouSureQuit.getString(context),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppStrings.cancel.getString(context),
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
            ),
            child: Text(
              AppStrings.quit.getString(context),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitDialog(context);
        if (shouldPop == true && mounted) {
          SystemNavigator.pop();
        }
      },
      child: Stack(
        children: [
          // ── Layer 1: Game + all Flame overlays (screens) ──────────────────
          GameWidget<ColorMixerGame>(
            game: _game,
            overlayBuilderMap: {
              'Controls': (context, game) => ControlsOverlay(game: game),
              'WinMenu': (context, game) => WinMenuOverlay(game: game),
              'LevelMap': (context, game) => LevelMapOverlay(game: game),
              'MainMenu': (context, game) => MainMenuOverlay(game: game),
              'Settings': (context, game) => SettingsOverlay(game: game),
              'GameOver': (context, game) => GameOverOverlay(game: game),
              'Shop': (context, game) => ShopOverlay(game: game),
              'ColorEchoHUD': (context, game) => ColorEchoHUD(game: game),
              'ChaosLabHUD': (context, game) => ChaosLabHUD(game: game),
              'PauseMenu': (context, game) => PauseMenuOverlay(game: game),
              'Tutorial': (context, game) => TutorialOverlay(game: game),
              'Achievement': (context, game) => AchievementNotification(
                onDismiss: () => game.overlays.remove('Achievement'),
                title: AppStrings.achievement1Title.getString(context),
                subtitle: AppStrings.achievement1Desc.getString(context),
                icon: Icons.science_rounded,
              ),
              'Achievements': (context, game) =>
                  AchievementsOverlay(game: game),
              'Gallery': (context, game) => GalleryOverlay(game: game),
              'Loading': (context, game) => const LoadingOverlay(),
              'Statistics': (context, game) => StatisticsOverlay(game: game),
              'DailyChallenge': (context, game) =>
                  DailyChallengeOverlay(game: game),
              'DailyLogin': (context, game) => DailyLoginOverlay(game: game),
              'Blackout': (context, game) => BlackoutOverlay(game: game),
              'LabUpgrade': (context, game) => LabUpgradeHub(game: game),
              'EchoWin': (context, game) => EchoWinOverlay(game: game),
              'EchoGameOver': (context, game) =>
                  EchoGameOverOverlay(game: game),
              'ChaosWin': (context, game) => ChaosWinOverlay(game: game),
              'ChaosGameOver': (context, game) =>
                  ChaosGameOverOverlay(game: game),
              'CoinStore': (context, game) => CoinStoreOverlay(game: game),
              'ModeGuide': (context, game) => ModeGuideOverlay(game: game),
              'RandomEventAlert': (context, game) =>
                  RandomEventAlertOverlay(game: game),
              'IntroSplash': (context, game) => IntroSplashOverlay(game: game),
            },
            initialActiveOverlays: const ['IntroSplash'],
            loadingBuilder: (context) =>
                PremiumLoadingScreen(progress: _game.loadingProgress),
          ),

          // ── Layer 2: Transition — always on top of every screen ───────────
          TransitionOverlay(game: _game),
        ],
      ),
    );
  }
}
