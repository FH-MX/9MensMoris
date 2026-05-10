import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_language_scope.dart';
import 'domain/app_language.dart';
import 'l10n/app_strings.dart';
import 'ui/home_screen.dart';

void main() {
  runApp(const NineMensMorrisApp());
}

class NineMensMorrisApp extends StatefulWidget {
  const NineMensMorrisApp({super.key});

  @override
  State<NineMensMorrisApp> createState() => _NineMensMorrisAppState();
}

class _NineMensMorrisAppState extends State<NineMensMorrisApp>
    with WidgetsBindingObserver {
  AppLanguage _language = AppLanguage.system;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncStrings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    _syncStrings();
    setState(() {});
  }

  void _setLanguage(AppLanguage language) {
    setState(() {
      _language = language;
      _syncStrings();
    });
  }

  void _syncStrings() {
    AppStrings.setLanguage(_language);
    AppStrings.setPlatformLocale(
      WidgetsBinding.instance.platformDispatcher.locale,
    );
  }

  @override
  Widget build(BuildContext context) {
    _syncStrings();
    return AppLanguageScope(
      language: _language,
      onChanged: _setLanguage,
      child: MaterialApp(
        title: AppStrings.t('app.title'),
        debugShowCheckedModeBanner: false,
        locale: AppStrings.appLocale,
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff6c5135),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xfffbf7ef),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
