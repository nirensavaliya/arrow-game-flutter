import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Centralized Firebase Remote Config for Arrow Escape.
///
/// Initialize this service before creating GameController:
///   await RemoteConfigService.instance.initialize();
///
/// Publish matching parameter names in Firebase Console > Remote Config.
class RemoteConfigService {
  RemoteConfigService._();

  static final RemoteConfigService instance = RemoteConfigService._();

  FirebaseRemoteConfig get _remoteConfig => FirebaseRemoteConfig.instance;

  String _appVersion = '';

  bool _initialized = false;

  bool get isInitialized => _initialized;

  static const Map<String, dynamic> _defaults = <String, dynamic>{
    // ==================== AD CONTROL ====================

    /// Master switch: false = no ads shown at all.
    'ads_enabled': '',

    /// Per-type switches (only matter when ads_enabled is true).
    'interstitial_enabled': '',
    'rewarded_enabled': '',
    'banner_enabled': '',

    /// REAL ad unit IDs (used only in release builds).
    /// Leave empty here; set the real values in Firebase Console.
    'interstitial_id_android': '',
    'interstitial_id_ios': '',
    'rewarded_id_android': '',
    'rewarded_id_ios': '',
    'banner_id_android': '',
    'banner_id_ios': '',

    'test_interstitial_id_android': '',
    'test_interstitial_id_ios': '',
    'test_rewarded_id_android': '',
    'test_rewarded_id_ios': '',
    'test_banner_id_android': '',
    'test_banner_id_ios': '',

    // Ads are shown only if app version is within [min, max] (inclusive).
    // Empty = no limit. Format: 1.2.3
    'ads_min_version_android': '',
    'ads_max_version_android': '',
    'ads_min_version_ios': '',
    'ads_max_version_ios': '',

    // ==================== FORCE UPDATE ====================
    // All empty on purpose. Set the real values in Firebase Console.

    'force_update_enabled': '',
    'min_version_android': '',
    'min_version_ios': '',
    'update_url_android': '',
    'update_url_ios': '',

    // ==================== Restarts ====================
    'initial_restarts': 5,
    'restarts_per_ad': 5,

    // ==================== Hints / Ads ====================
    'initial_hints': 0,
    'hints_per_ad': 1,
    'interstitial_every_levels': 5,

    // ==================== Coins ====================
    'reward_base': 5,
    'reward_step': 2,
    'reward_max': 40,
    'combo_coins_4': 2,
    'combo_coins_5': 3,
    'combo_coins_7': 4,
    'combo_coins_10': 5,

    // ==================== Ad bonus multipliers ====================
    'bonus_multiplier_low': 1.2,
    'bonus_multiplier_high': 1.5,

    // ==================== Rewarded Ad - Continue ====================
    'continue_lives': 2,
    'ad_continue_time_fraction': 0.5,
  };

  Future<void> initialize() async {
    await _remoteConfig.setDefaults(_defaults);

    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(seconds: 2),
      ),
    );


    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version; // e.g. 1.0.5 (without build number)
    } catch (_) {}

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (error) {
      // Keep using local defaults if fetch fails.
      // Do not prevent the game from starting.
    }

    _initialized = true;
  }

  // ==================== Safe getters ====================

  int _int(String key) => _initialized
      ? _remoteConfig.getInt(key)
      : (_defaults[key] as num).toInt();

  double _double(String key) => _initialized
      ? _remoteConfig.getDouble(key)
      : (_defaults[key] as num).toDouble();

  bool _bool(String key) =>
      _initialized ? _remoteConfig.getBool(key) : _defaults[key] as bool;

  String _string(String key) => _initialized
      ? _remoteConfig.getString(key).trim()
      : (_defaults[key] as String).trim();

  // ==================== Ads version range ====================

  String get adsMinVersion => Platform.isIOS
      ? _string('ads_min_version_ios')
      : _string('ads_min_version_android');

  String get adsMaxVersion => Platform.isIOS
      ? _string('ads_max_version_ios')
      : _string('ads_max_version_android');

  /// Returns <0 if a<b, 0 if equal, >0 if a>b.
  int _compareVersions(String a, String b) {
    final pa = a.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final pb = b.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }

  /// True if the current app version is inside [min, max].
  bool get adsAllowedForCurrentVersion {
    if (_appVersion.isEmpty) return true; // can't detect -> don't block
    final min = adsMinVersion;
    final max = adsMaxVersion;
    if (min.isNotEmpty && _compareVersions(_appVersion, min) < 0) return false;
    if (max.isNotEmpty && _compareVersions(_appVersion, max) > 0) return false;
    return true;
  }

  // ==================== AD CONTROL ====================

  /// Master switch: if false, NO ads are shown anywhere in the app.
  /// Master switch + version range.
  bool get adsEnabled =>
      _bool('ads_enabled') && adsAllowedForCurrentVersion;

  /// Interstitial switch (also requires adsEnabled).
  bool get interstitialEnabled => _bool('interstitial_enabled');

  /// Rewarded switch (also requires adsEnabled).
  bool get rewardedEnabled => _bool('rewarded_enabled');


  /// Banner switch (also requires adsEnabled).
  bool get bannerEnabled => _bool('banner_enabled');

  // Real ad unit IDs from Remote Config.
  String get interstitialIdAndroid => _string('interstitial_id_android');
  String get interstitialIdIos => _string('interstitial_id_ios');
  String get rewardedIdAndroid => _string('rewarded_id_android');
  String get rewardedIdIos => _string('rewarded_id_ios');
  String get bannerIdAndroid => _string('banner_id_android');
  String get bannerIdIos => _string('banner_id_ios');



  // Test ad unit IDs from Remote Config.
  String get testInterstitialIdAndroid =>
      _string('test_interstitial_id_android');

  String get testInterstitialIdIos =>
      _string('test_interstitial_id_ios');

  String get testRewardedIdAndroid =>
      _string('test_rewarded_id_android');

  String get testRewardedIdIos =>
      _string('test_rewarded_id_ios');
  String get testBannerIdAndroid => _string('test_banner_id_android');
  String get testBannerIdIos => _string('test_banner_id_ios');

  // ==================== Force Update ====================

  bool get forceUpdateEnabled => _bool('force_update_enabled');

  String get minVersionAndroid => _string('min_version_android');
  String get minVersionIos => _string('min_version_ios');

  String get updateUrlAndroid => _string('update_url_android');
  String get updateUrlIos => _string('update_url_ios');

  // ==================== Restarts ====================

  /// Restarts a new player starts with.
  int get initialRestarts =>
      _int('initial_restarts').clamp(0, 999).toInt();

  /// Restarts granted after watching a rewarded ad.
  int get restartsPerAd =>
      _int('restarts_per_ad').clamp(0, 999).toInt();

  // ==================== Hints / Ads ====================

  int get initialHints => _int('initial_hints');

  int get hintsPerAd => _int('hints_per_ad');

  int get interstitialEveryLevels => _int('interstitial_every_levels');

  // ==================== Coins ====================

  int get rewardBase => _int('reward_base');

  int get rewardStep => _int('reward_step');

  int get rewardMax => _int('reward_max');

  int get comboCoins4 => _int('combo_coins_4');

  int get comboCoins5 => _int('combo_coins_5');

  int get comboCoins7 => _int('combo_coins_7');

  int get comboCoins10 => _int('combo_coins_10');

  double get bonusMultiplierLow => _double('bonus_multiplier_low');

  double get bonusMultiplierHigh => _double('bonus_multiplier_high');

  // ==================== Rewarded Ad - Continue ====================

  int get continueLives => _int('continue_lives');

  double get adContinueTimeFraction =>
      _double('ad_continue_time_fraction').clamp(0.05, 1.0).toDouble();

  Future<bool> fetchAndActivate() => _remoteConfig.fetchAndActivate();
}
