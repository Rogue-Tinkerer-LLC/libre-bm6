import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const issuesUrl = 'https://github.com/Rogue-Tinkerer-LLC/libre-bm6/issues';

typedef AppInfo = ({String version, String build, String os});

/// App and OS details plus URI launching, so tests can swap in fakes.
class AppEnv {
  const AppEnv({required this.info, required this.openUri});

  static const platform = AppEnv(info: _platformInfo, openUri: _openUri);

  final Future<AppInfo> Function() info;

  /// Opens [Uri] in another app. Returns false if no app can handle it.
  final Future<bool> Function(Uri uri) openUri;
}

Future<AppInfo> _platformInfo() async {
  final package = await PackageInfo.fromPlatform();
  final device = DeviceInfoPlugin();
  final String os;
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    final ios = await device.iosInfo;
    os = iosDetails(ios.systemName, ios.systemVersion);
  } else {
    final android = await device.androidInfo;
    os = androidDetails(android.version.release, android.version.sdkInt);
  }
  return (version: package.version, build: package.buildNumber, os: os);
}

/// The OS part of a bug report's details line on Android.
String androidDetails(String release, int sdkLevel) =>
    'Android $release (API $sdkLevel)';

/// The OS part of a bug report's details line on iOS.
String iosDetails(String systemName, String systemVersion) =>
    '$systemName $systemVersion';

Future<bool> _openUri(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on PlatformException {
    return false;
  }
}

/// The new-issue page with [body] pre-filled. Built by hand because
/// [Uri.queryParameters] encodes spaces as `+`.
Uri newIssueUri(String body) =>
    Uri.parse('$issuesUrl/new?body=${Uri.encodeComponent(body)}');
