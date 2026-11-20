import 'dart:async';

import 'package:arrow/services/remote_config_service.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';


import 'ad_config.dart';

/// Shows an App Open ad when the user returns to the app from background.
/// Never shown on cold start, only on resume.
class AppOpenAdService {
  AppOpenAdService._();
  static final AppOpenAdService instance = AppOpenAdService._();

  static const Duration _adExpiry = Duration(hours: 4);

  AppOpenAd? _ad;
  DateTime? _loadedAt;
  bool _isLoading = false;
  bool _isShowing = false;
  bool _started = false;

  DateTime? _backgroundedAt;
  DateTime? _lastShownAt;

  /// Set to true by interstitial / rewarded services while THEY are
  /// showing, so their dismissal (which triggers a "resume") does not
  /// pop an app open ad on top.
  bool suppress = false;

  /// Call once after MobileAds.instance.initialize() and
  /// RemoteConfigService.initialize().
  void start() {
    if (_started) return;
    _started = true;

    AppStateEventNotifier.startListening();
    AppStateEventNotifier.appStateStream.forEach(_onAppState);

    _load();
  }

  void _onAppState(AppState state) {
    if (state == AppState.background) {
      _backgroundedAt = DateTime.now();
      return;
    }

    if (state == AppState.foreground) {
      _onResume();
    }
  }

  bool get _isAvailable =>
      _ad != null &&
          _loadedAt != null &&
          DateTime.now().difference(_loadedAt!) < _adExpiry;

  void _onResume() {
    final rc = RemoteConfigService.instance;

    // Re-check Remote Config at the moment of showing.
    if (!AdConfig.appOpenEnabled) return;
    if (_isShowing || suppress) return;

    final bgAt = _backgroundedAt;
    _backgroundedAt = null;
    if (bgAt == null) return;

    if (DateTime.now().difference(bgAt).inSeconds <
        rc.appOpenMinBackgroundSeconds) {
      return;
    }

    final last = _lastShownAt;
    if (last != null &&
        DateTime.now().difference(last).inSeconds <
            rc.appOpenCooldownSeconds) {
      return;
    }

    if (!_isAvailable) {
      _disposeAd();
      _load();
      return;
    }

    _show();
  }

  void _load() {
    if (!AdConfig.appOpenEnabled) return;
    if (_isLoading || _isAvailable) return;

    final id = AdConfig.appOpenId;
    if (id.isEmpty) return; // no id in Remote Config -> do nothing

    _isLoading = true;

    AppOpenAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _ad = ad;
          _loadedAt = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  void _show() {
    final ad = _ad;
    if (ad == null) return;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _isShowing = true;
        _lastShownAt = DateTime.now();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowing = false;
        ad.dispose();
        _ad = null;
        _load(); // preload the next one
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowing = false;
        debugPrint('AppOpenAd failed to show: $error');
        ad.dispose();
        _ad = null;
        _load();
      },
    );

    ad.show();
  }

  void _disposeAd() {
    _ad?.dispose();
    _ad = null;
    _loadedAt = null;
  }
}