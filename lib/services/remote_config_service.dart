import 'package:firebase_remote_config/firebase_remote_config.dart';

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

  bool _initialized = false;

  bool get isInitialized => _initialized;

  static const Map<String, dynamic> _defaults = <String, dynamic>{
    // ==================== AD CONTROL (3 separate parameters) ====================

    /// Master switch: false = no ads shown at all.
    'ads_enabled': false,

    /// true = use REAL ad unit IDs (monetized).
    /// false = use TEST ad unit IDs.
    'is_release': false,

    /// true = app behaves like debug mode
    ///        (test ads, extra logging, debug UI, etc.)
    /// false = normal behavior.
    'is_debug': false,

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
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

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

  // ==================== AD CONTROL ====================

  /// Master switch: if false, NO ads are shown anywhere in the app.
  bool get adsEnabled => _bool('ads_enabled');

  /// true = REAL ad unit IDs (monetized ads).
  /// false = TEST ad unit IDs (safe for testing).
  bool get isRelease => _bool('is_release');

  /// true = debug behavior (test ads, logging, debug tools).
  /// false = clean production behavior.
  bool get isDebug => _bool('is_debug');

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
