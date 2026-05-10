import 'dart:math';

import '../../domain/action.dart';
import '../../domain/game_state.dart';
import '../game_engine.dart';
import 'cpu_difficulty.dart';
import 'cpu_strategy.dart';

class EasyCpuStrategy implements CpuStrategy {
  final Random random;

  EasyCpuStrategy({Random? random}) : random = random ?? Random();

  @override
  CpuDifficulty get difficulty => CpuDifficulty.easy;

  @override
  GameAction selectAction({
    required GameState state,
    required GameEngine engine,
  }) {
    final actions = engine.legalActions(
      player: state.currentPlayer,
      state: state,
    );
    return actions[random.nextInt(actions.length)];
  }
}
