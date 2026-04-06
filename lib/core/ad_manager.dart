import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:color_mixing_deductive/color_mixer_game.dart';
import 'vip_manager.dart';

/// Enum for different types of rewards in the game.
enum RewardType {
  life,
  coins2x,
  extraDrops,
  helperSample,
}

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  static AdManager get instance => _instance;

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  
  bool _isInterstitialAdReady = false;
  bool _isRewardedAdLoading = false;
  int _rewardedRetryAttempt = 0;

  VoidCallback? onAdOpened;
  VoidCallback? onAdClosed;

  int _wonLevelsCount = 0;
  int _triesCount = 0;

  // Ad Unit IDs (Keeping existing IDs as placeholders)
  final String _androidBannerId = 'ca-app-pub-7510332808716092/6879301632';
  final String _iosBannerId = 'ca-app-pub-7510332808716092/6879301632';
  final String _androidInterstitialId = 'ca-app-pub-7510332808716092/8248769768';
  final String _iosInterstitialId = 'ca-app-pub-7510332808716092/8248769768';
  
  // OFFICIAL GOOGLE TEST REWARDED ID for Android/iOS
  final String _androidRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  final String _iosRewardedId = 'ca-app-pub-3940256099942544/1712485313';

  String get bannerAdUnitId {
    if (kDebugMode) return Platform.isAndroid ? 'ca-app-pub-3940256099942544/6300978111' : 'ca-app-pub-3940256099942544/2934735716';
    return Platform.isAndroid ? _androidBannerId : _iosBannerId;
  }

  String get interstitialAdUnitId {
    if (kDebugMode) return Platform.isAndroid ? 'ca-app-pub-3940256099942544/1033173712' : 'ca-app-pub-3940256099942544/4411468910';
    return Platform.isAndroid ? _androidInterstitialId : _iosInterstitialId;
  }

  String get rewardedAdUnitId {
    if (kDebugMode) return Platform.isAndroid ? _androidRewardedId : _iosRewardedId;
    return Platform.isAndroid ? 'ca-app-pub-7510332808716092/8391481823' : 'ca-app-pub-7510332808716092/8391481823';
  }

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadInterstitialAd();
    loadRewardedAd();
  }

  // --- Banner Ads ---
  void loadBannerAd(Function(Ad) onAdLoaded) {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => onAdLoaded(ad),
        onAdFailedToLoad: (ad, err) {
          debugPrint('AdManager: Banner Ad failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  // --- Interstitial Ads ---
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('AdManager: Interstitial Ad failed to load: $err');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  void showInterstitialAd({VoidCallback? onAdDismissed}) {
    if (VipManager.instance.isVip.value) {
      onAdDismissed?.call();
      return;
    }

    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          onAdDismissed?.call();
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          onAdDismissed?.call();
          loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _isInterstitialAdReady = false;
      _interstitialAd = null;
    } else {
      resetAdCounters();
      onAdDismissed?.call();
    }
  }

  void recordWin() {
    _wonLevelsCount++;
    _triesCount++;
  }

  void recordLoss() {
    _triesCount++;
  }

  void resetAdCounters() {
    _wonLevelsCount = 0;
    _triesCount = 0;
  }

  bool shouldShowInterstitial() {
    return _wonLevelsCount >= 2 || _triesCount >= 2;
  }

  BannerAd? get bannerAd => _bannerAd;

  // --- Rewarded Ads ---
  bool get isRewardedAdReady => _rewardedAd != null;

  void loadRewardedAd() {
    if (_isRewardedAdLoading || _rewardedAd != null) return;
    _isRewardedAdLoading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AdManager: Rewarded Ad loaded.');
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          _rewardedRetryAttempt = 0;
        },
        onAdFailedToLoad: (err) {
          debugPrint('AdManager: Rewarded Ad failed to load: $err');
          _isRewardedAdLoading = false;
          _rewardedAd = null;
          
          // Exponential backoff
          _rewardedRetryAttempt++;
          final delay = Duration(seconds: (1 << _rewardedRetryAttempt).clamp(1, 60));
          Timer(delay, loadRewardedAd);
        },
      ),
    );
  }

  /// Production-grade show rewarded ad with engine pause/resume.
  void showRewardedAd({
    required ColorMixerGame game,
    required void Function(AdWithoutView ad, RewardItem reward) onUserEarnedReward,
    VoidCallback? onAdFailed,
    VoidCallback? onAdClosed,
  }) {
    if (isRewardedAdReady && _rewardedAd != null) {
      // PAUSE ENGINE
      game.pauseEngine();

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          game.resumeEngine(); // RESUME ENGINE
          if (onAdClosed != null) onAdClosed();
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          debugPrint('AdManager: Rewarded Ad failed to show: $err');
          ad.dispose();
          _rewardedAd = null;
          game.resumeEngine(); // RESUME ENGINE
          loadRewardedAd();
          if (onAdFailed != null) onAdFailed();
        },
      );
      
      _rewardedAd!.show(onUserEarnedReward: onUserEarnedReward);
    } else {
      debugPrint('AdManager: Rewarded Ad not ready yet');
      if (onAdFailed != null) onAdFailed();
      loadRewardedAd();
    }
  }

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
