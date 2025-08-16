import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../../../generated/gen_l10n/app_localizations.dart';

/// Test wrapper that provides localization context for widget tests
class L10nTestWrapper extends StatelessWidget {
  final Widget child;
  final Locale locale;

  const L10nTestWrapper({
    Key? key,
    required this.child,
    this.locale = const Locale('th', 'TH'),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('th', 'TH'),
      ],
      home: Scaffold(body: child),
    );
  }
}
