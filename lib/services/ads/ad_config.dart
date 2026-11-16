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
    debugPrint('useTestIds: $_useTestIds');
    debugPrint('Interstitial ID: $interstitialId');
    debugPrint('Rewarded ID: $rewardedId');
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

  /// Automatic: debug and profile builds use TEST ids.
  /// Only a real release build uses the REAL ids from Remote Config.
  static bool get _useTestIds => !kReleaseMode;

  /// A real ID is accepted only if it looks like an AdMob unit ID.
  /// Otherwise '' is returned and no ad is loaded.
  static String _validReal(String id) =>
      RegExp(r'^ca-app-pub-\d{16}/\d{10}$').hasMatch(id) ? id : '';

  static String get interstitialId {
    if (_useTestIds) {
      if (Platform.isAndroid) return _testInterstitialAndroid;
      if (Platform.isIOS) return _testInterstitialIos;
      return '';
    }
    if (Platform.isAndroid) return _validReal(_rc.interstitialIdAndroid);
    if (Platform.isIOS) return _validReal(_rc.interstitialIdIos);
    return '';
  }

  static String get rewardedId {
    if (_useTestIds) {
      if (Platform.isAndroid) return _testRewardedAndroid;
      if (Platform.isIOS) return _testRewardedIos;
      return '';
    }
    if (Platform.isAndroid) return _validReal(_rc.rewardedIdAndroid);
    if (Platform.isIOS) return _validReal(_rc.rewardedIdIos);
    return '';
  }
}