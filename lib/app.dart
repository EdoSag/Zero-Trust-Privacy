import 'package:flutter/material.dart';

import 'l10n/l10n.dart';
import 'ui/phone_test_controller.dart';
import 'ui/phone_test_page.dart';

/// Slate, this app's colour among the Zero-Trust apps.
const privacyAccent = Color(0xFF64748B);

class PrivacyApp extends StatelessWidget {
  const PrivacyApp({super.key, required this.controller, this.locale});

  final PhoneTestController controller;

  /// Left empty, the phone's language is used (English or Hebrew).
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZT Privacy',
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: PhoneTestPage(controller: controller),
    );
  }

  ThemeData _theme(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: privacyAccent,
      brightness: brightness,
    ),
    useMaterial3: true,
  );
}
