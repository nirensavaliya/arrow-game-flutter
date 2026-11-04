
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Log a custom Firebase Analytics event.
  /// Analytics errors will never interrupt gameplay.
  Future<void> logEvent(
      String name, {
        Map<String, Object>? parameters,
      }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      // Ignore analytics errors to keep gameplay running.
    }
  }

  /// Set the currently selected game mode as a user property.
  Future<void> setGameMode(String mode) async {
    try {
      await _analytics.setUserProperty(
        name: 'game_mode',
        value: mode,
      );
    } catch (e) {
      // Ignore analytics errors.
    }
  }

  /// Set a user property.
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(
        name: name,
        value: value,
      );
    } catch (e) {
      // Ignore analytics errors.
    }
  }

  /// Set the user's ID, if you use Firebase Authentication.
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      // Ignore analytics errors.
    }
  }

  /// Enable or disable analytics collection.
  Future<void> setAnalyticsEnabled(bool enabled) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
    } catch (e) {
      // Ignore analytics errors.
    }
  }
}
