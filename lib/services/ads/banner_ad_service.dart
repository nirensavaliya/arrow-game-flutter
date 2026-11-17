import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Anchored adaptive banner. Takes no space until an ad has loaded.
class BannerAdService extends StatefulWidget {
  const BannerAdService({super.key});

  @override
  State<BannerAdService> createState() => _BannerAdServiceState();
}

class _BannerAdServiceState extends State<BannerAdService> {
  BannerAd? _ad;
  AdSize? _size;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    if (_requested) return;

    // Master + banner switches, checked right before loading.
    if (!AdConfig.bannerEnabled) return;

    final id = AdConfig.bannerId;
    if (id.isEmpty) return;

    _requested = true;

    final width = MediaQuery.sizeOf(context).width.truncate();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );

    if (!mounted || size == null) {
      _requested = false;
      return;
    }

    _ad = BannerAd(
      adUnitId: id,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() {
            _size = size;
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner load failed: $error');
          ad.dispose();
          _ad = null;
          _loaded = false;
          _requested = false; // allow a later retry
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    final size = _size;

    // Nothing is shown (and no space is used) if ads are off or not loaded yet.
    if (!AdConfig.bannerEnabled || !_loaded || ad == null || size == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: size.width.toDouble(),
        height: size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
