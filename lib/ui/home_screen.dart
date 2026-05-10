import 'package:flutter/material.dart';

import '../app_language_scope.dart';
import '../domain/app_language.dart';
import '../l10n/app_strings.dart';
import 'custom_game_screen.dart';
import 'game_screen.dart';
import 'tutorial_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageScope = AppLanguageScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('app.title')),
        actions: [
          PopupMenuButton<AppLanguage>(
            tooltip: AppStrings.t('home.language'),
            icon: const Icon(Icons.language),
            initialValue: languageScope.language,
            onSelected: languageScope.onChanged,
            itemBuilder: (context) => [
              for (final language in AppLanguage.values)
                PopupMenuItem(
                  value: language,
                  child: Text(AppStrings.languageName(language)),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              FilledButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const GameScreen())),
                icon: const Icon(Icons.play_arrow),
                label: Text(AppStrings.t('home.quickPlay')),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CustomGameScreen()),
                ),
                icon: const Icon(Icons.tune),
                label: Text(AppStrings.t('home.customGame')),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TutorialScreen()),
                ),
                icon: const Icon(Icons.school),
                label: Text(AppStrings.t('home.tutorial')),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
