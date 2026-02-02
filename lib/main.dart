import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/helpers/audio_manager.dart';
import 'package:color_mixing_deductive/overlays/controls_overlay.dart';
import 'package:color_mixing_deductive/overlays/game_over_overlay.dart';
import 'package:color_mixing_deductive/overlays/level_map_overlay.dart';
import 'package:color_mixing_deductive/overlays/main_menu_overlay.dart';
import 'package:color_mixing_deductive/overlays/settings_overlay.dart';
import 'package:color_mixing_deductive/overlays/shop_overlay.dart';
import 'package:color_mixing_deductive/overlays/transition_overlay.dart';
import 'package:color_mixing_deductive/overlays/win_menu_overlay.dart';
import 'package:color_mixing_deductive/overlays/pause_menu_overlay.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations for mobile
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A1A2E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize localization
  await FlutterLocalization.instance.ensureInitialized();

  // Initialize audio
  await AudioManager().initialize();

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
      home: GameWidget<ColorMixerGame>(
        game: ColorMixerGame(),
        overlayBuilderMap: {
          'Controls': (context, game) => ControlsOverlay(game: game),
          'WinMenu': (context, game) => WinMenuOverlay(game: game),
          'LevelMap': (context, game) => LevelMapOverlay(game: game),
          'MainMenu': (context, game) => MainMenuOverlay(game: game),
          'Settings': (context, game) => SettingsOverlay(game: game),
          'Transition': (context, game) => TransitionOverlay(game: game),
          'GameOver': (context, game) =>
              GameOverOverlay(game: game), // إضافة هذا السطر
          'Shop': (context, game) => ShopOverlay(game: game),
          'PauseMenu': (context, game) => PauseMenuOverlay(game: game),
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
    );
  }
}
