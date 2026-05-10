import '../../domain/action.dart';
import '../../domain/game_state.dart';
import '../game_engine.dart';
import 'cpu_difficulty.dart';

abstract class CpuStrategy {
  CpuDifficulty get difficulty;

  GameAction selectAction({
    required GameState state,
    required GameEngine engine,
  });
}
