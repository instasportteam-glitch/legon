import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';

const appDataKey = 'app_data';
const appOrigin = 'https://gamelink.legonn.my';

String localStorageJsonScript(String key, Map<String, dynamic> data) {
  // Encode BOTH arguments, so quotes/newlines cannot turn values into JS code.
  return 'localStorage.setItem(${jsonEncode(key)}, ${jsonEncode(jsonEncode(data))});';
}

// Retains the integration's public function name.
// ignore: non_constant_identifier_names
Future<void> NcupSaveJsonToLocalStorageAndPrefs({
  required InAppWebViewController? controller,
  required String key,
  required Map<String, dynamic> data,
}) async {
  if (controller != null) {
    try {
      final url = await controller.getUrl();
      // Device metadata is only shared with the app's own HTTPS origin.
      if (url != null && isAppUrl(Uri.parse(url.toString()))) {
        await controller.evaluateJavascript(
          source: localStorageJsonScript(key, data),
        );
      }
    } catch (error, stack) {
      debugPrint('app_data localStorage error: $error\n$stack');
    }
  }
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  } catch (error, stack) {
    debugPrint('app_data preferences error: $error\n$stack');
  }
}

bool isAppUrl(Uri url) =>
    url.scheme == 'https' &&
    url.host == 'gamelink.legonn.my' &&
    url.port == 443;

bool canOpenExternally(Uri url) =>
    url.hasScheme &&
    !const {
      'javascript',
      'data',
      'blob',
      'file',
      'about',
    }.contains(url.scheme.toLowerCase());

// Match complete hosts or their subdomains, never URL substrings.
const externalAppDomains = <String>[
  't.me',
  'telegram.me',
  'telegram.org',
  'instagram.com',
  'facebook.com',
  'fb.com',
  'fb.me',
  'messenger.com',
  'm.me',
  'x.com',
  'twitter.com',
  't.co',
  'whatsapp.com',
  'wa.me',
  'viber.com',
  'discord.com',
  'discord.gg',
  'discordapp.com',
  'tiktok.com',
  'youtube.com',
  'youtu.be',
  'linkedin.com',
  'reddit.com',
  'redd.it',
  'snapchat.com',
  'threads.net',
  'threads.com',
  'vk.com',
  'vk.me',
  'signal.me',
];

bool shouldOpenExternally(Uri url) {
  if (!canOpenExternally(url)) return false;
  if (!const {'http', 'https'}.contains(url.scheme.toLowerCase())) return true;
  final host = url.host.toLowerCase().replaceFirst(RegExp(r'\.$'), '');
  return externalAppDomains.any(
    (domain) => host == domain || host.endsWith('.$domain'),
  );
}

String _randomId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

final _sessionId = _randomId();

Future<Map<String, dynamic>> loadDeviceData({String? fcmToken}) async {
  final prefs = await SharedPreferences.getInstance();
  var deviceId = prefs.getString('legon_installation_id');
  if (deviceId == null) {
    deviceId = _randomId();
    await prefs.setString('legon_installation_id', deviceId);
  }
  Map<String, dynamic> previous = {};
  try {
    final raw = prefs.getString(appDataKey);
    if (raw != null)
      previous = Map<String, dynamic>.from(jsonDecode(raw) as Map);
  } catch (_) {
    // A malformed saved payload must not prevent the website from opening.
  }
  String? userAgent;
  try {
    userAgent = await InAppWebViewController.getDefaultUserAgent();
  } catch (_) {}
  final locale = PlatformDispatcher.instance.locale;
  return {
    'fcm_token': fcmToken ?? 'missing_token',
    'device_id': deviceId, // App installation ID, not a hardware identifier.
    'app_name': 'legon',
    'location': 'unknown', // No location permission or geolocation lookup.
    'instance_id': _sessionId,
    'platform': Platform.operatingSystem,
    'os_version': Platform.operatingSystemVersion,
    'app_version': '1.0.0', // Matches pubspec.yaml.
    'language': locale.languageCode,
    'timezone': DateTime.now().timeZoneName,
    'push_enabled': false, // Push notifications are not configured in this app.
    'safe_area_native': true,
    'useragent': userAgent ?? 'unknown_useragent',
    'savels': previous['savels'] is Map
        ? previous['savels']
        : <String, dynamic>{},
    'bridge': <String, dynamic>{},
  };
}
