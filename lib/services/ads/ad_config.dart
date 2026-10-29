import 'dart:io';

import 'package:flutter/foundation.dart';

class AdConfig {
  AdConfig._();

  // Keep true while testing.
  static const bool testMode = true;

  static bool get isTestMode => kDebugMode || testMode;

  static String get interstitialId {
    if (isTestMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/1033173712';
      }

      if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/4411468910';
      }
    }

    // Add your real AdMob interstitial IDs here for release.
    return '';
  }

  static String get rewardedId {
    if (isTestMode) {
      if (Platform.isAndroid) {
        return 'ca-app-pub-3940256099942544/5224354917';
      }

      if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/1712485313';
      }
    }

    // Add your real AdMob rewarded IDs here fo  r release.
    return '';
  }
}
