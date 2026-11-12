import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:legonn/data/webview_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('JSON storage escapes the key and value independently', () {
    const key = "app_data');throw new Error('bad";
    final data = {
      'name': "O'Brien\n\"quoted\"",
      'bridge': {},
      'push_enabled': false,
    };
    final script = localStorageJsonScript(key, data);
    expect(
      script,
      'localStorage.setItem(${jsonEncode(key)}, ${jsonEncode(jsonEncode(data))});',
    );
    expect(
      jsonDecode(jsonDecode(jsonEncode(jsonEncode(data))) as String),
      data,
    );
  });

  test('preferences receive a JSON object even without a controller', () async {
    SharedPreferences.setMockInitialValues({});
    final data = {
      'device_id': 'test',
      'savels': {'nested': true},
    };
    await NcupSaveJsonToLocalStorageAndPrefs(
      controller: null,
      key: appDataKey,
      data: data,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(jsonDecode(prefs.getString('app_data')!), data);
  });

  test('only exact HTTPS app origin receives device data', () {
    expect(isAppUrl(Uri.parse('$appOrigin/page?q=1')), isTrue);
    for (final url in [
      'http://gamelink.legonn.my/',
      'https://gamelink.legonn.my.evil.example/',
      'https://gamelink.legonn.my:444/',
      'https://example.com/',
    ]) {
      expect(isAppUrl(Uri.parse(url)), isFalse);
    }
  });

  test(
    'external handling allows web and app links but not script/file URLs',
    () {
      for (final url in [
        'https://example.com',
        'tel:+123',
        'mailto:a@example.com',
        'tg://resolve?domain=test',
        'intent://example/#Intent;end',
      ]) {
        expect(canOpenExternally(Uri.parse(url)), isTrue);
      }
      for (final url in [
        'javascript:alert(1)',
        'data:text/plain,test',
        'file:///secret',
        'blob:https://example.com/id',
        'about:blank',
        '/relative',
      ]) {
        expect(canOpenExternally(Uri.parse(url)), isFalse);
      }
    },
  );
  test('regular websites stay inside while social and app links leave', () {
    for (final url in [
      'https://google.com/',
      'https://www.google.com/search?q=x.com',
      'https://example.com/',
      'http://example.com/',
      'https://x.com.evil.example',
      'https://notinstagram.com',
      'https://example.com/?next=https://t.me/test',
    ]) {
      expect(shouldOpenExternally(Uri.parse(url)), isFalse, reason: url);
    }
    for (final url in [
      'https://t.me/test',
      'https://www.instagram.com/test',
      'https://m.facebook.com/',
      'https://x.com/test',
      'https://x.com./test',
      'https://wa.me/123',
      'tg://resolve?domain=test',
      'mailto:a@example.com',
      'tel:+123',
    ]) {
      expect(shouldOpenExternally(Uri.parse(url)), isTrue, reason: url);
    }
  });
}
