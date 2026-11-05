import 'dart:io';

import 'package:flutter/foundation.dart';

import '../remote_config_service.dart';

class AdConfig {
  AdConfig._();
  static void printAdConfiguration() {
    debugPrint('========== AD CONFIG ==========');
    debugPrint('kDebugMode: $kDebugMode');
    debugPrint('adsEnabled: $adsEnabled');
    debugPrint('isDebug: $isDebug');
    debugPrint('isRelease: $isRelease');
    debugPrint('useTestIds: $_useTestIds');
    debugPrint('Interstitial ID: $interstitialId');
    debugPrint('Rewarded ID: $rewardedId');
    debugPrint('==============================');
  }

  // ==================== AD CONTROL (3 separate checks) ====================

  /// Parameter 1: ads_enabled — master switch.
  /// false = NO ads shown at all, regardless of anything else.
  static bool get adsEnabled => RemoteConfigService.instance.adsEnabled;

  /// Parameter 2: is_debug — debug behavior.
  /// true = test ads + logging. Checked FIRST for ad IDs.
  static bool get isDebug => RemoteConfigService.instance.isDebug;

  /// Parameter 3: is_release — real monetized ads.
  /// true = REAL ad IDs (only used when is_debug is false).
  static bool get isRelease => RemoteConfigService.instance.isRelease;

  // ==================== AD UNIT IDs ====================

  // AdMob official TEST IDs
  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIos =
      'ca-app-pub-3940256099942544/1712485313';

  // YOUR REAL IDs — fill these in for release
  static const String _realInterstitialAndroid =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _realInterstitialIos =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _realRewardedAndroid =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _realRewardedIos =
      'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  /// Decides test vs real IDs — is_debug checked first, then is_release.
  /// kDebugMode is kept as a hard safety net: debug builds can NEVER
  /// use real IDs even if Remote Config says otherwise.
  static bool get _useTestIds => kDebugMode || isDebug || !isRelease;

  static String get interstitialId {
    if (_useTestIds) {
      if (Platform.isAndroid) return _testInterstitialAndroid;
      if (Platform.isIOS) return _testInterstitialIos;
      return '';
    }

    if (Platform.isAndroid) return _realInterstitialAndroid;
    if (Platform.isIOS) return _realInterstitialIos;
    return '';
  }

  static String get rewardedId {
    if (_useTestIds) {
      if (Platform.isAndroid) return _testRewardedAndroid;
      if (Platform.isIOS) return _testRewardedIos;
      return '';
    }

    if (Platform.isAndroid) return _realRewardedAndroid;
    if (Platform.isIOS) return _realRewardedIos;
    return '';
  }
}
