import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

class InterstitialAdService {
  InterstitialAd? _ad;
  bool _isLoading = false;
  bool _isShowing = false;

  String get _adUnitId => AdConfig.interstitialId;

  // Cache the last-used ad unit ID so we can detect when Remote Config
  // flips between test and real IDs and reload accordingly.
  String? _loadedAdUnitId;

  void loadAd() {
    if (_isLoading || _ad != null || _isShowing) return;

    // Parameter 1: ads_enabled — master switch.
    // If ads were turned off in Remote Config after an ad was already
    // loaded, this also disposes the stale ad.
    if (!AdConfig.adsEnabled) {
      _ad?.dispose();
      _ad = null;
      return;
    }

    final id = _adUnitId;
    if (id.isEmpty) return;

    // Remote Config changed test/real mode after preload → reload with new ID.
    if (_loadedAdUnitId != null && _loadedAdUnitId != id) {
      _ad?.dispose();
      _ad = null;
    }

    _isLoading = true;
    _loadedAdUnitId = id;

    InterstitialAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _ad = ad;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          debugPrint('Interstitial load failed: $error');
        },
      ),
    );
  }

  /// Shows the ad if one is ready.
  /// [onDone] is always called once, after the ad closes,
  /// or immediately if no ad is available.
  void show({required VoidCallback onDone}) {
    // Master switch checked at show-time too: a preloaded ad must not
    // appear after ads were disabled remotely.
    if (!AdConfig.adsEnabled) {
      _ad?.dispose();
      _ad = null;
      onDone();
      return;
    }

    final ad = _ad;

    if (ad == null || _isShowing) {
      loadAd();
      onDone();
      return;
    }

    _ad = null;
    _isShowing = true;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowing = false;
        loadAd();
        onDone();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isShowing = false;
        loadAd();
        onDone();
      },
    );

    ad.show();
  }

  /// Call this after Remote Config values change (e.g. user pulls to refresh,
  /// or app returns to foreground and fetchAndActivate() succeeded).
  void onRemoteConfigUpdated() {
    final id = _adUnitId;

    // Ads turned off → drop everything.
    if (!AdConfig.adsEnabled || id.isEmpty) {
      dispose();
      _loadedAdUnitId = null;
      return;
    }

    // ID mode changed (test ↔ real) → reload with the new ID.
    if (_loadedAdUnitId != null && _loadedAdUnitId != id) {
      dispose();
      _loadedAdUnitId = null;
      loadAd();
    }
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}