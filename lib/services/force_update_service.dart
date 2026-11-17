import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'remote_config_service.dart';

/// Decides whether the installed app is older than the minimum version
/// set in Remote Config, and opens the store page.
class ForceUpdateService {
  ForceUpdateService._();

  static final ForceUpdateService instance = ForceUpdateService._();

  final RemoteConfigService _config = RemoteConfigService.instance;

  /// True when force update is ON and installed version < min version.
  /// Never throws: on any error the app is allowed to continue.
  Future<bool> isUpdateRequired() async {
    try {
      if (!_config.forceUpdateEnabled) return false;

      final minVersion = Platform.isIOS
          ? _config.minVersionIos
          : _config.minVersionAndroid;
      if (minVersion.isEmpty) return false;

      final info = await PackageInfo.fromPlatform();
      return _compare(info.version, minVersion) < 0;
    } catch (_) {
      return false;
    }
  }

  String get storeUrl =>
      Platform.isIOS ? _config.updateUrlIos : _config.updateUrlAndroid;

  Future<void> openStore() async {
    final url = storeUrl;
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Compares "1.2.10" style versions. Returns <0, 0, or >0.
  int _compare(String a, String b) {
    List<int> parse(String v) => v
        .split('+')
        .first
        .split('.')
        .map((p) => int.tryParse(p.trim()) ?? 0)
        .toList();

    final pa = parse(a);
    final pb = parse(b);
    final length = pa.length > pb.length ? pa.length : pb.length;

    for (var i = 0; i < length; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    return 0;
  }
}
