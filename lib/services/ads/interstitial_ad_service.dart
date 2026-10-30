import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

class InterstitialAdService {
  InterstitialAd? _ad;
  bool _isLoading = false;
  bool _isShowing = false;

  String get _adUnitId => AdConfig.interstitialId;

  void loadAd() {
    if (_isLoading || _ad != null || _isShowing) return;

    final id = _adUnitId;
    if (id.isEmpty) return;

    _isLoading = true;

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

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}
