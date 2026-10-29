//
// import 'package:flutter/foundation.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
//
// import 'ad_config.dart';
//
// class RewardedAdService {
//   RewardedAd? _rewardedAd;
//   bool _isLoading = false;
//   bool _isShowing = false;
//
//   bool get isReady => _rewardedAd != null;
//
//   String get _adUnitId => AdConfig.rewardedId;q
//
//   void loadAd() {
//     if (_isLoading || _rewardedAd != null || _isShowing) return;
//
//     final id = _adUnitId;
//     if (id.isEmpty) return;
//
//     _isLoading = true;
//
//     RewardedAd.load(
//       adUnitId: id,
//       request: const AdRequest(),
//       rewardedAdLoadCallback: RewardedAdLoadCallback(
//         onAdLoaded: (ad) {
//           _isLoading = false;
//           _rewardedAd = ad;
//           debugPrint('Rewarded ad ready');
//         },
//         onAdFailedToLoad: (error) {
//           _isLoading = false;
//           debugPrint('Rewarded ad load failed: $error');
//         },
//       ),
//     );
//   }
//
//   void showAd({
//     required VoidCallback onRewardEarned,
//     required VoidCallback onUnavailable,
//     VoidCallback? onClosedWithoutReward,
//   }) {
//     if (_isShowing) return;
//
//     final ad = _rewardedAd;
//
//     if (ad == null) {
//       onUnavailable();
//       loadAd();
//       return;
//     }
//
//     _rewardedAd = null;
//     _isShowing = true;
//
//     var rewardEarned = false;
//     var rewardCallbackCalled = false;
//
//     ad.fullScreenContentCallback = FullScreenContentCallback(
//       onAdDismissedFullScreenContent: (ad) {
//         ad.dispose();
//         _isShowing = false;
//         loadAd();
//
//         if (!rewardEarned) {
//           onClosedWithoutReward?.call();
//         }
//       },
//       onAdFailedToShowFullScreenContent: (ad, error) {
//         ad.dispose();
//         _isShowing = false;
//         loadAd();
//
//         if (!rewardEarned) {
//           onUnavailable();
//         }
//       },
//     );
//
//     ad.show(
//       onUserEarnedReward: (ad, reward) {
//         if (rewardCallbackCalled) return;
//
//         rewardEarned = true;
//         rewardCallbackCalled = true;
//         onRewardEarned();
//       },
//     );
//   }
//
//   void dispose() {
//     _rewardedAd?.dispose();
//     _rewardedAd = null;
//   }
// }
