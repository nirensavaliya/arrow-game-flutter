import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// A self-loading native ad card. Collapses to nothing if ads are
/// disabled, the ID is empty, or loading fails.
class NativeAdService extends StatefulWidget {
  final Color accent;
  final bool isDark;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;

  const NativeAdService({
    super.key,
    required this.accent,
    required this.isDark,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  State<NativeAdService> createState() => _NativeAdServiceState();
}

class _NativeAdServiceState extends State<NativeAdService> {
  NativeAd? _ad;
  bool _loaded = false;
  bool _failed = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  void _load() {
    final id = AdConfig.nativeId;

    if (!AdConfig.nativeEnabled || id.isEmpty) {
      setState(() => _failed = true);
      return;
    }

    _ad = NativeAd(
      adUnitId: id,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('NativeAd failed: ${error.message}');
          ad.dispose();
          _ad = null;
          if (mounted) setState(() => _failed = true);
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: widget.surface,
        cornerRadius: 20,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: widget.accent,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: widget.textPrimary,
          style: NativeTemplateFontStyle.bold,
          size: 15,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: widget.textSecondary,
          size: 12,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: widget.textSecondary,
          size: 12,
        ),
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
    if (_failed || !_loaded || _ad == null) {
      return const SizedBox.shrink();
    }

    const radius = 28.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 320, maxHeight: 352),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          // Painted ABOVE the native ad view, so the border stays visible.
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: widget.accent.withValues(
                alpha: widget.isDark ? 0.20 : 0.20,
              ),
              width: 1,
            ),
          ),
          child: AdWidget(ad: _ad!),
        ),
      ),
    );
  }
}
