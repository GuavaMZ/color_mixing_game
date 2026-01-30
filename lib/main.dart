import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'package:color_mixing_deductive/overlays/controls_overlay.dart';
import 'package:color_mixing_deductive/overlays/win_menu_overlay.dart';
import 'package:color_mixing_deductive/helpers/string_manager.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterLocalization.instance.ensureInitialized();
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
      supportedLocales: _localization.supportedLocales,
      localizationsDelegates: _localization.localizationsDelegates,
      theme: ThemeData(fontFamily: 'Roboto'), // Example font
      home: GameWidget<ColorMixerGame>(
        game: ColorMixerGame(),
        overlayBuilderMap: {
          'Controls': (context, game) => ControlsOverlay(game: game),
          'WinMenu': (context, game) => WinMenuOverlay(game: game),
        },
        initialActiveOverlays: const ['Controls'],
      ),
    );
  }
}
