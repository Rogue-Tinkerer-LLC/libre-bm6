import 'package:flutter/material.dart';

import 'app_env.dart';
import 'ble.dart';
import 'devices_page.dart';
import 'l10n/app_localizations.dart';
import 'legal_page.dart';
import 'store.dart';

/// A strictly black and white theme, with no seed or accent colors.
ThemeData buildTheme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final fg = light ? Colors.black : Colors.white;
  final bg = light ? Colors.white : Colors.black;
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: fg,
      onPrimary: bg,
      secondary: fg,
      onSecondary: bg,
      error: fg,
      onError: bg,
      surface: bg,
      onSurface: fg,
      outline: fg,
      surfaceTint: Colors.transparent,
    ),
  );
}

class LibreBm6App extends StatelessWidget {
  const LibreBm6App({
    super.key,
    required this.store,
    required this.ble,
    required this.env,
  });

  final Store store;
  final Ble ble;
  final AppEnv env;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ListenableBuilder(
        listenable: store,
        builder: (context, _) => store.termsAccepted
            ? DevicesPage(store: store, ble: ble, env: env)
            : TermsPage(env: env, onAccept: store.acceptTerms),
      ),
    );
  }
}
