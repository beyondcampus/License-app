/*
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/constants/app_constants.dart';

/// Pure-Dart gate for interstitial frequency: cooldown between shows and a
/// hard per-session cap. Unit-testable with an injected clock.
class InterstitialGate {
  InterstitialGate({
    DateTime Function()? clock,
    this.cooldown = AppConstants.interstitialCooldown,
    this.maxPerSession = AppConstants.maxInterstitialsPerSession,
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Duration cooldown;
  final int maxPerSession;

  DateTime? _lastShownAt;
  int _shownCount = 0;

  int get shownCount => _shownCount;

  bool get canShow {
    if (_shownCount >= maxPerSession) return false;
    final last = _lastShownAt;
    if (last == null) return true;
    return _clock().difference(last) >= cooldown;
  }

  void recordShown() {
    _lastShownAt = _clock();
    _shownCount++;
  }
}

/// Central AdMob manager: initialization, banner factory, interstitial
/// loading/showing with cooldown, and failure handling.
///
class AdManager {
  AdManager({InterstitialGate? gate}) : gate = gate ?? InterstitialGate();

  final InterstitialGate gate;

  InterstitialAd? _interstitial;
  bool _initialized = false;
  int _interstitialLoadAttempts = 0;
  static const int _maxLoadAttempts = 3;

  /// The plugin only exists on Android/iOS; everywhere else (tests, desktop)
  /// every ad API is a silent no-op so the app works identically without ads.
  static bool get adsSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  static const _testAndroidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testIosBannerId = 'ca-app-pub-3940256099942544/2934735716';
  static const _testAndroidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testIosInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';

  static const _androidBannerId = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
    defaultValue: 'ca-app-pub-3892219323174069/7499028630',
  );
  static const _iosBannerId = String.fromEnvironment(
    'ADMOB_IOS_BANNER_ID',
    defaultValue: '',
  );
  static const _androidInterstitialId = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-3892219323174069/5402339177',
  );
  static const _iosInterstitialId = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL_ID',
    defaultValue: '',
  );

  static String _unitId(String configured, String fallback) {
    return RegExp(r'^ca-app-pub-\d{16}/\d{10}$').hasMatch(configured)
        ? configured
        : fallback;
  }

  static String get bannerAdUnitId => Platform.isAndroid
      ? _unitId(_androidBannerId, _testAndroidBannerId)
      : _unitId(_iosBannerId, _testIosBannerId);

  static String get interstitialAdUnitId => Platform.isAndroid
      ? _unitId(_androidInterstitialId, _testAndroidInterstitialId)
      : _unitId(_iosInterstitialId, _testIosInterstitialId);

  Future<void> initialize() async {
    if (!adsSupported || _initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadInterstitial();
    } catch (e) {
      // Ads must never affect app functionality.
      debugPrint('AdManager.initialize failed: $e');
    }
  }

  /// Creates and starts loading a banner. Returns null off-platform or on
  /// failure; callers render nothing in that case.
  BannerAd? createBanner({required void Function(Ad) onLoaded,
      required void Function(Ad, LoadAdError) onFailed}) {
    if (!adsSupported) return null;
    try {
      final banner = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: onLoaded,
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner failed to load: $error');
            ad.dispose();
            onFailed(ad, error);
          },
        ),
      );
      banner.load();
      return banner;
    } catch (e) {
      debugPrint('AdManager.createBanner failed: $e');
      return null;
    }
  }

  void _loadInterstitial() {
    if (!adsSupported || _interstitialLoadAttempts >= _maxLoadAttempts) {
      return;
    }
    _interstitialLoadAttempts++;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _interstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: $error');
          _interstitial = null;
        },
      ),
    );
  }

  /// Shows an interstitial if one is loaded AND the cooldown allows it.
  /// Never blocks, never throws — a quiz result is shown regardless.
  Future<void> maybeShowInterstitial() async {
    if (!adsSupported) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    if (!gate.canShow) return;
    try {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitial();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Interstitial failed to show: $error');
          ad.dispose();
          _loadInterstitial();
        },
      );
      gate.recordShown();
      _interstitial = null;
      await ad.show();
    } catch (e) {
      debugPrint('AdManager.maybeShowInterstitial failed: $e');
    }
  }

  void dispose() {
    _interstitial?.dispose();
    _interstitial = null;
  }
}
*/
