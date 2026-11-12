import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legonn/main.dart';
import 'package:legonn/screens/intro_screen.dart';
import 'package:legonn/screens/webview_screen.dart';
import 'package:legonn/state/app_state.dart';

class _UnusedContext extends Fake implements BuildContext {}

void main() {
  test('native intro still gates the initial website', () {
    final loading = Future<void>.value();
    final app = LegOnApp(state: AppState(), loading: loading);
    final scope = app.build(_UnusedContext()) as AppScope;
    final materialApp = scope.child as MaterialApp;
    final intro = materialApp.home! as IntroGate;

    expect(intro.loading, same(loading));
    expect(intro.child, isA<WebViewScreen>());
    expect((intro.child as WebViewScreen).windowId, isNull);
    expect(Uri.parse(WebViewScreen.initialUrl).scheme, 'https');
  });
}
