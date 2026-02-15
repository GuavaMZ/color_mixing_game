import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerAdReady = false;
  bool _isInterstitialAdReady = false;

  // Test Ad Unit IDs
  final String _androidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  final String _iosBannerId = 'ca-app-pub-3940256099942544/2934735716';
  final String _androidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  final String _iosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';

  String get bannerAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) return _androidBannerId;
      if (Platform.isIOS) return _iosBannerId;
    }
    // Replace with production IDs
    return Platform.isAndroid ? 'YOUR_ANDROID_BANNER_ID' : 'YOUR_IOS_BANNER_ID';
  }

  String get interstitialAdUnitId {
    if (kDebugMode) {
      if (Platform.isAndroid) return _androidInterstitialId;
      if (Platform.isIOS) return _iosInterstitialId;
    }
    // Replace with production IDs
    return Platform.isAndroid
        ? 'YOUR_ANDROID_INTERSTITIAL_ID'
        : 'YOUR_IOS_INTERSTITIAL_ID';
  }

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  void loadBannerAd(Function(Ad) onAdLoaded) {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdReady = true;
          onAdLoaded(ad);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('Banner Ad failed to load: $err');
          _isBannerAdReady = false;
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
                  loadInterstitialAd(); // Preload details for next time
                },
                onAdFailedToShowFullScreenContent: (ad, err) {
                  ad.dispose();
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
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
      _isInterstitialAdReady = false;
      _interstitialAd = null;
    } else {
      debugPrint('Interstitial Ad not ready yet');
      loadInterstitialAd(); // Try loading one for next time
    }
  }

  BannerAd? get bannerAd => _bannerAd;

  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }
}
