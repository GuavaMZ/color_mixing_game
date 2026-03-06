import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'vip_manager.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;

  VoidCallback? onAdOpened;
  VoidCallback? onAdClosed;

  // Test Ad Unit IDs
  final String _androidBannerId = 'ca-app-pub-7510332808716092/6879301632';
  final String _iosBannerId = 'ca-app-pub-7510332808716092/6879301632';
  final String _androidInterstitialId =
      'ca-app-pub-7510332808716092/8248769768';
  final String _iosInterstitialId = 'ca-app-pub-7510332808716092/8248769768';
  final String _androidRewardedId = 'ca-app-pub-7510332808716092/8391481823';
  final String _iosRewardedId = 'ca-app-pub-7510332808716092/8391481823';

  String get bannerAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) return _androidBannerId;
      if (Platform.isIOS) return _iosBannerId;
    }
    // Replace with production IDs
    return Platform.isAndroid
        ? 'ca-app-pub-7510332808716092/6879301632'
        : 'ca-app-pub-7510332808716092/6879301632';
  }

  String get interstitialAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) return _androidInterstitialId;
      if (Platform.isIOS) return _iosInterstitialId;
    }
    // Replace with production IDs
    return Platform.isAndroid
        ? 'ca-app-pub-7510332808716092/8248769768'
        : 'ca-app-pub-7510332808716092/8248769768';
  }

  String get rewardedAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) return _androidRewardedId;
      if (Platform.isIOS) return _iosRewardedId;
    }
    // Replace with production IDs
    return Platform.isAndroid
        ? 'ca-app-pub-7510332808716092/8391481823'
        : 'ca-app-pub-7510332808716092/8391481823';
  }

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadInterstitialAd();
    loadRewardedAd();
  }

  void loadBannerAd(Function(Ad) onAdLoaded) {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Banner Ad failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  onAdClosed?.call();
                  loadInterstitialAd(); // Preload details for next time
                },
                onAdFailedToShowFullScreenContent: (ad, err) {
                  ad.dispose();
                  onAdClosed?.call();
                  loadInterstitialAd();
                },
              );
        },
        onAdFailedToLoad: (err) {
          debugPrint('Interstitial Ad failed to load: $err');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (VipManager.instance.isVip.value) {
      debugPrint('Skipping Interstitial Ad for VIP user');
      return;
    }

    if (_isInterstitialAdReady && _interstitialAd != null) {
      onAdOpened?.call();
      _interstitialAd!.show();
      _isInterstitialAdReady = false;
      _interstitialAd = null;
    } else {
      debugPrint('Interstitial Ad not ready yet');
      loadInterstitialAd(); // Try loading one for next time
    }
  }

  BannerAd? get bannerAd => _bannerAd;

  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              onAdClosed?.call();
              _isRewardedAdReady = false;
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              onAdClosed?.call();
              _isRewardedAdReady = false;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          debugPrint('Rewarded Ad failed to load: $err');
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  void showRewardedAd({
    required void Function(AdWithoutView ad, RewardItem reward)
    onUserEarnedReward,
    VoidCallback? onAdFailed,
  }) {
    if (_isRewardedAdReady && _rewardedAd != null) {
      onAdOpened?.call();
      _rewardedAd!.show(onUserEarnedReward: onUserEarnedReward);
      _rewardedAd = null;
      _isRewardedAdReady = false;
    } else {
      debugPrint('Rewarded Ad not ready yet');
      onAdFailed?.call();
      loadRewardedAd();
    }
  }

  bool get isRewardedAdReady => _isRewardedAdReady;

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
