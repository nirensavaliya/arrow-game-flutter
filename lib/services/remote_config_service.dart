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
    // Hints / Ads
    'initial_hints': 0,
    'hints_per_ad': 1,
    'interstitial_every_levels': 5,
    'ads_enabled': true,

    // Coins
    'reward_base': 5,
    'reward_step': 2,
    'reward_max': 40,
    'combo_coins_4': 2,
    'combo_coins_5': 3,
    'combo_coins_7': 4,
    'combo_coins_10': 5,

    // Watch ad after winning: coin bonus multipliers (x1.2 and x1.5)
    'bonus_multiplier_low': 1.2,
    'bonus_multiplier_high': 1.5,

    // Rewarded Ad - Continue
    'continue_lives': 2,
    // Fraction of the FULL timer given back after "Watch Ad & Continue".
    // 0.5 = half of the full time.
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
      // Keep using the local defaults / last activated values if fetch fails.
      // Do not prevent the game from starting because Remote Config is offline.
    }

    _initialized = true;
  }

  // Safe getters: fall back to the local defaults if initialize() was not
  // called yet, so the game never crashes because of Remote Config.
  int _int(String key) => _initialized
      ? _remoteConfig.getInt(key)
      : (_defaults[key] as num).toInt();

  double _double(String key) => _initialized
      ? _remoteConfig.getDouble(key)
      : (_defaults[key] as num).toDouble();

  bool _bool(String key) =>
      _initialized ? _remoteConfig.getBool(key) : _defaults[key] as bool;

  // Hints / Ads
  int get initialHints => _int('initial_hints');

  int get hintsPerAd => _int('hints_per_ad');

  int get interstitialEveryLevels => _int('interstitial_every_levels');

  bool get adsEnabled => _bool('ads_enabled');

  // Coins
  int get rewardBase => _int('reward_base');

  int get rewardStep => _int('reward_step');

  int get rewardMax => _int('reward_max');

  int get comboCoins4 => _int('combo_coins_4');

  int get comboCoins5 => _int('combo_coins_5');

  int get comboCoins7 => _int('combo_coins_7');

  int get comboCoins10 => _int('combo_coins_10');

  // Ad bonus multipliers after a win (x1.2 / x1.5)
  double get bonusMultiplierLow => _double('bonus_multiplier_low');

  double get bonusMultiplierHigh => _double('bonus_multiplier_high');

  // Rewarded Ad - Continue
  int get continueLives => _int('continue_lives');

  /// Fraction of the FULL timer given after the continue ad (0.5 = half).
  double get adContinueTimeFraction =>
      _double('ad_continue_time_fraction').clamp(0.05, 1.0).toDouble();

  /// Optional: force a fresh fetch when the user explicitly requests it.
  /// Firebase minimumFetchInterval still applies unless overridden in settings.
  Future<bool> fetchAndActivate() => _remoteConfig.fetchAndActivate();
}
