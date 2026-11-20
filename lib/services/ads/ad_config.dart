import 'dart:io';

import 'package:flutter/foundation.dart';

import '../remote_config_service.dart';

class AdConfig {
  AdConfig._();

  static void printAdConfiguration() {
    debugPrint('========== AD CONFIG ==========');
    debugPrint('kDebugMode: $kDebugMode');
    debugPrint('kReleaseMode: $kReleaseMode');
    debugPrint('adsEnabled: $adsEnabled');
    debugPrint('interstitialEnabled: $interstitialEnabled');
    debugPrint('rewardedEnabled: $rewardedEnabled');
    debugPrint('bannerEnabled: $bannerEnabled');
    debugPrint('appOpenEnabled: $appOpenEnabled');
    debugPrint('useTestIds: $_useTestIds');
    debugPrint('Interstitial ID: $interstitialId');
    debugPrint('Rewarded ID: $rewardedId');
    debugPrint('Banner ID: $bannerId');
    debugPrint('App Open ID: $appOpenId');
    debugPrint('==============================');
  }

  static RemoteConfigService get _rc => RemoteConfigService.instance;

  // ==================== AD CONTROL ====================

  /// Master switch: false = NO ads at all.
  static bool get adsEnabled => _rc.adsEnabled;

  /// Interstitials allowed = master switch AND interstitial switch.
  static bool get interstitialEnabled =>
      _rc.adsEnabled && _rc.interstitialEnabled;

  /// Rewarded ads allowed = master switch AND rewarded switch.
  static bool get rewardedEnabled => _rc.adsEnabled && _rc.rewardedEnabled;

  /// Banners allowed = master switch AND banner switch.
  static bool get bannerEnabled => _rc.adsEnabled && _rc.bannerEnabled;

  /// App open ads allowed = master switch AND app open switch.
  static bool get appOpenEnabled => _rc.adsEnabled && _rc.appOpenEnabled;

  /// Automatic: debug and profile builds use TEST ids.
  /// Only a real release build uses the REAL ids from Remote Config.
  static bool get _useTestIds => !kReleaseMode;


  static String get interstitialId {
    if (_useTestIds) {
      return Platform.isAndroid
          ? _rc.testInterstitialIdAndroid
          : _rc.testInterstitialIdIos;
    }

    return Platform.isAndroid
        ? _rc.interstitialIdAndroid
        : _rc.interstitialIdIos;
  }

  static String get rewardedId {
    if (_useTestIds) {
      return Platform.isAndroid
          ? _rc.testRewardedIdAndroid
          : _rc.testRewardedIdIos;
    }

    return Platform.isAndroid ? _rc.rewardedIdAndroid : _rc.rewardedIdIos;
  }
  static String get bannerId {
    if (_useTestIds) {
      return Platform.isAndroid ? _rc.testBannerIdAndroid : _rc.testBannerIdIos;
    }
    return Platform.isAndroid ? _rc.bannerIdAndroid : _rc.bannerIdIos;
  }

  static String get appOpenId {
    if (_useTestIds) {
      return Platform.isAndroid
          ? _rc.testAppOpenIdAndroid
          : _rc.testAppOpenIdIos;
    }
    return Platform.isAndroid ? _rc.appOpenIdAndroid : _rc.appOpenIdIos;
  }
}
