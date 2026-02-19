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
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:color_mixing_deductive/overlays/system/tutorial_overlay.dart';
import 'package:color_mixing_deductive/overlays/system/loading_overlay.dart';
import 'package:color_mixing_deductive/overlays/system/statistics_overlay.dart';
import 'package:color_mixing_deductive/overlays/navigation/daily_challenge_overlay.dart';
import 'package:color_mixing_deductive/overlays/system/blackout_overlay.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:color_mixing_deductive/core/ad_manager.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        const MapLocale('en', AppStrings.En),
        const MapLocale('ar', AppStrings.Ar),
        const MapLocale('es', AppStrings.Es),
        const MapLocale('fr', AppStrings.Fr),
      ],
      initLanguageCode: 'en',
    );
    _localization.onTranslatedLanguage = _onTranslatedLanguage;
    super.initState();
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
      home: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _showExitDialog(context);
          if (shouldPop == true && mounted) {
            SystemNavigator.pop();
          }
        },
        child: GameWidget<ColorMixerGame>(
          game: ColorMixerGame(),
          overlayBuilderMap: {
            'Controls': (context, game) => ControlsOverlay(game: game),
            'WinMenu': (context, game) => WinMenuOverlay(game: game),
            'LevelMap': (context, game) => LevelMapOverlay(game: game),
            'MainMenu': (context, game) => MainMenuOverlay(game: game),
            'Settings': (context, game) => SettingsOverlay(game: game),
            'Transition': (context, game) => TransitionOverlay(game: game),
            'GameOver': (context, game) => GameOverOverlay(game: game),
            'Shop': (context, game) => ShopOverlay(game: game),
            'ColorEchoHUD': (context, game) => ColorEchoHUD(game: game),
            'ChaosLabHUD': (context, game) => ChaosLabHUD(game: game),
            'PauseMenu': (context, game) => PauseMenuOverlay(game: game),
            'Tutorial': (context, game) => TutorialOverlay(game: game),
            'Achievement': (context, game) => AchievementNotification(
              onDismiss: () => game.overlays.remove('Achievement'),
              title: "MAD CHEMIST",
              subtitle: "First successful mixture!",
              icon: Icons.science_rounded,
            ),
            'Achievements': (context, game) => AchievementsOverlay(game: game),
            'Gallery': (context, game) => GalleryOverlay(game: game),
            'Loading': (context, game) => const LoadingOverlay(),
            'Statistics': (context, game) => StatisticsOverlay(game: game),
            'DailyChallenge': (context, game) =>
                DailyChallengeOverlay(game: game),
            'Blackout': (context, game) => BlackoutOverlay(game: game),
            'LabUpgrade': (context, game) => LabUpgradeHub(game: game),
            'EchoWin': (context, game) => EchoWinOverlay(game: game),
            'EchoGameOver': (context, game) => EchoGameOverOverlay(game: game),
            'ChaosWin': (context, game) => ChaosWinOverlay(game: game),
            'ChaosGameOver': (context, game) =>
                ChaosGameOverOverlay(game: game),
          },
          initialActiveOverlays: const ['MainMenu', 'Transition'],
          loadingBuilder: (context) => Container(
            color: const Color(0xFF1A1A2E),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
              ),
            ),
          ),
        ),
      ),
    );
  }

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
}
