import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

class RewardedAdService {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _isShowing = false;

  bool get isReady => _rewardedAd != null;

  String get _adUnitId => AdConfig.rewardedId;

  // Tracks which unit ID the loaded ad belongs to, so a Remote Config
  // flip between test/real IDs triggers a reload.
  String? _loadedAdUnitId;

  void loadAd() {
    if (_isLoading || _rewardedAd != null || _isShowing) return;

    // ads_enabled — master switch. Also disposes a stale preloaded ad
    // if ads were turned off remotely.
    if (!AdConfig.adsEnabled) {
      _rewardedAd?.dispose();
      _rewardedAd = null;
      return;
    }

    final id = _adUnitId;
    if (id.isEmpty) return;

    // Remote Config changed test/real mode → reload with the new ID.
    if (_loadedAdUnitId != null && _loadedAdUnitId != id) {
      _rewardedAd?.dispose();
      _rewardedAd = null;
    }

    _isLoading = true;
    _loadedAdUnitId = id;

    RewardedAd.load(
      adUnitId: id,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _rewardedAd = ad;
          debugPrint('Rewarded ad ready');
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          debugPrint('Rewarded ad load failed: $error');
        },
      ),
    );
  }

  void showAd({
    required VoidCallback onRewardEarned,
    required VoidCallback onUnavailable,
    VoidCallback? onClosedWithoutReward,
  }) {
    if (_isShowing) return;

    // Master switch checked at show-time too: a preloaded rewarded ad
    // must not appear (or grant rewards) after ads were disabled remotely.
    if (!AdConfig.adsEnabled) {
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _loadedAdUnitId = null;
      onUnavailable();
      return;
    }

    final ad = _rewardedAd;

    if (ad == null) {
      onUnavailable();
      loadAd();
      return;
    }

    _rewardedAd = null;
    _isShowing = true;

    var rewardEarned = false;
    var rewardCallbackCalled = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isShowing = false;
        loadAd();

        if (!rewardEarned) {
          onClosedWithoutReward?.call();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isShowing = false;
        loadAd();

        if (!rewardEarned) {
          onUnavailable();
        }
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        if (rewardCallbackCalled) return;

        rewardEarned = true;
        rewardCallbackCalled = true;
        onRewardEarned();
      },
    );
  }

  /// Call after Remote Config values change (e.g. app resumed and
  /// fetchAndActivate() returned true) to drop stale ads and reload
  /// with the correct test/real ID.
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
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}