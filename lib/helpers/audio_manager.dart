import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized audio management with caching and volume controls
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  bool _initialized = false;
  bool _sfxEnabled = true;
  bool _musicEnabled = true;
  double _sfxVolume = 0.7;
  double _musicVolume = 0.3;

  // Audio file names
  static const String dropSound = 'drop.mp3';
  static const String winSound = 'win.mp3';
  static const String resetSound = 'reset.mp3';
  static const String buttonSound = 'button.mp3';
  static const String starSound = 'star.mp3';
  static const String unlockSound = 'unlock.mp3';
  static const String gameOverSound = 'game_over.mp3';

  // BGM files
  static const String bgmClassic = 'bgm_classic.ogg';
  static const String bgmTime = 'bgm_time.ogg';
  static const String bgmEcho = 'bgm_echo.ogg';

  // Persistence keys
  static const String _sfxKey = 'sfx_enabled';
  static const String _musicKey = 'music_enabled';

  final Set<String> _loadedSounds = {};

  String? _currentBgm;

  /// Initialize audio system and preload sounds
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Load settings
      final prefs = await SharedPreferences.getInstance();
      _sfxEnabled = prefs.getBool(_sfxKey) ?? true;
      _musicEnabled = prefs.getBool(_musicKey) ?? true;

      // Preload available sound effects
      final soundsToLoad = [
        dropSound,
        winSound,
        resetSound,
        buttonSound,
        starSound,
        unlockSound,
        gameOverSound,
      ];

      for (final sound in soundsToLoad) {
        try {
          await FlameAudio.audioCache.load(sound);
          _loadedSounds.add(sound);
          debugPrint('AudioManager: Loaded $sound');
        } catch (e) {
          debugPrint('AudioManager: Asset $sound not found or failed to load');
        }
      }

      _initialized = true;
      debugPrint(
        'AudioManager: Initialized with ${_loadedSounds.length} sounds',
      );

      // Don't auto-start music here, let the game controller decide which track
    } catch (e) {
      debugPrint('AudioManager: Critical initialization failure - $e');
      // Even if cache fails, we mark initialized to allow settings to work
      _initialized = true;
    }
  }

  /// Play sound effect
  Future<void> playSfx(String sound, {double? volume}) async {
    if (!_sfxEnabled || !_initialized) return;

    if (!_loadedSounds.contains(sound)) {
      debugPrint('AudioManager: Cannot play $sound - not loaded');
      return;
    }

    try {
      await FlameAudio.play(sound, volume: volume ?? _sfxVolume);
    } catch (e) {
      debugPrint('AudioManager: Failed to play $sound - $e');
    }
  }

  /// Play drop sound
  void playDrop() => playSfx(dropSound, volume: 0.8);

  /// Play win celebration sound
  void playWin() => playSfx(winSound, volume: 0.7);

  /// Play reset/clear sound
  void playReset() => playSfx(resetSound, volume: 0.4);

  /// Play button click sound
  void playButton() => playSfx(buttonSound, volume: 0.3);

  /// Play star reveal sound
  void playStar() => playSfx(starSound, volume: 0.5);

  /// Play level unlock sound
  void playUnlock() => playSfx(unlockSound, volume: 0.6);

  /// Play game over sound
  void playGameOver() => playSfx(gameOverSound, volume: 0.5);

  /// Start background music for a specific mode
  Future<void> playMusicForMode(String mode) async {
    String track;
    switch (mode) {
      case 'timeAttack':
        track = bgmTime;
        break;
      case 'colorEcho':
        track = bgmEcho;
        break;
      case 'classic':
      default:
        track = bgmClassic;
        break;
    }

    await playMusic(track);
  }

  /// play specific music track
  Future<void> playMusic(String track) async {
    if (!_musicEnabled || !_initialized) return;

    if (_currentBgm == track && FlameAudio.bgm.isPlaying) return;

    try {
      // If a different track is playing, stop it first
      if (FlameAudio.bgm.isPlaying) {
        FlameAudio.bgm.stop();
      }

      _currentBgm = track;
      await FlameAudio.bgm.play(track, volume: _musicVolume);
    } catch (e) {
      debugPrint('AudioManager: Failed to start music $track - $e');
    }
  }

  /// Stop background music
  void stopMusic() {
    FlameAudio.bgm.stop();
    _currentBgm = null;
  }

  /// Pause background music
  void pauseMusic() {
    FlameAudio.bgm.pause();
  }

  /// Resume background music
  void resumeMusic() {
    if (_musicEnabled && _currentBgm != null) {
      FlameAudio.bgm.resume();
    }
  }

  // === Settings ===

  bool get sfxEnabled => _sfxEnabled;
  set sfxEnabled(bool value) {
    _sfxEnabled = value;
    _saveSettings();
  }

  bool get musicEnabled => _musicEnabled;
  set musicEnabled(bool value) {
    _musicEnabled = value;
    _saveSettings();
    if (!value) {
      stopMusic();
    } else if (_initialized && _currentBgm != null) {
      playMusic(_currentBgm!);
    }
  }

  double get sfxVolume => _sfxVolume;
  set sfxVolume(double value) {
    _sfxVolume = value.clamp(0.0, 1.0);
  }

  double get musicVolume => _musicVolume;
  set musicVolume(double value) {
    _musicVolume = value.clamp(0.0, 1.0);
    if (_musicEnabled) {
      // Update current music volume
      FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxKey, _sfxEnabled);
    await prefs.setBool(_musicKey, _musicEnabled);
  }

  /// Toggle SFX on/off
  void toggleSfx() {
    sfxEnabled = !sfxEnabled;
  }

  /// Toggle Music on/off
  void toggleMusic() {
    musicEnabled = !musicEnabled;
  }

  /// Dispose audio resources
  void dispose() {
    FlameAudio.bgm.stop();
    FlameAudio.audioCache.clearAll();
    _initialized = false;
  }
}
