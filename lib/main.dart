import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/intro_screen.dart';
import 'screens/shell.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  final state = AppState();
  // Load saved data while the intro plays; IntroGate waits for both.
  final loading = state.load();
  runApp(LegOnApp(state: state, loading: loading));
}

class LegOnApp extends StatelessWidget {
  const LegOnApp({super.key, required this.state, required this.loading});

  final AppState state;
  final Future<void> loading;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'LEG ON',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: IntroGate(loading: loading, child: const Shell()),
      ),
    );
  }
}
