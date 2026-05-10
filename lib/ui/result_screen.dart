import 'package:flutter/material.dart';

import '../domain/player_id.dart';
import '../l10n/app_strings.dart';
import 'game_screen.dart';

class ResultScreen extends StatelessWidget {
  final PlayerID winner;

  const ResultScreen({super.key, required this.winner});

  @override
  Widget build(BuildContext context) {
    final name = winner == PlayerID.white
        ? AppStrings.t('game.white')
        : AppStrings.t('game.black');
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('game.winner'))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${AppStrings.t('game.winner')}: $name',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const GameScreen()),
                ),
                icon: const Icon(Icons.refresh),
                label: Text(AppStrings.t('game.replay')),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.home),
                label: Text(AppStrings.t('game.home')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
