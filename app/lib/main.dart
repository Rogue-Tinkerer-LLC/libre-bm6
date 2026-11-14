import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'app_env.dart';
import 'ble.dart';
import 'legal_text.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    LibreBm6App(
      store: Store(prefs, termsFingerprint: termsFingerprint()),
      ble: Ble.platform,
      env: AppEnv.platform,
    ),
  );
}
