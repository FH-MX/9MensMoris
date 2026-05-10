import 'dart:math';

import '../../domain/action.dart';
import '../../domain/game_state.dart';
import '../../domain/node_id.dart';
import '../../domain/player_id.dart';
import '../game_engine.dart';
import 'cpu_difficulty.dart';
import 'cpu_strategy.dart';

class NormalCpuStrategy implements CpuStrategy {
  final Random random;

  NormalCpuStrategy({Random? random}) : random = random ?? Random();

  static const _preferredNodes = [
    NodeID.n0,
    NodeID.n2,
    NodeID.n21,
    NodeID.n23,
    NodeID.n1,
    NodeID.n9,
    NodeID.n14,
    NodeID.n22,
  ];

  @override
  CpuDifficulty get difficulty => CpuDifficulty.normal;

  @override
  GameAction selectAction({
    required GameState state,
    required GameEngine engine,
  }) {
    final actions = engine.legalActions(
      player: state.currentPlayer,
      state: state,
    );
    final capture = actions.whereType<CapturePieceAction>().toList();
    if (capture.isNotEmpty) {
      return capture.first;
    }

    for (final action in actions) {
      final after = engine.apply(action: action, state: state);
      if (engine.formsNewMill(action: action, before: state, after: after)) {
        return action;
      }
    }

    final blocking = _blockingActions(state, engine, actions);
    if (blocking.isNotEmpty) {
      return blocking.first;
    }

    final preferred =
        actions.where((action) => _preferredScore(action) > 0).toList()
          ..sort((a, b) => _preferredScore(b).compareTo(_preferredScore(a)));
    if (preferred.isNotEmpty) {
      return preferred.first;
    }
    return actions[random.nextInt(actions.length)];
  }

  List<GameAction> _blockingActions(
    GameState state,
    GameEngine engine,
    List<GameAction> actions,
  ) {
    final opponentState = state.copyWith(
      currentPlayer: state.currentPlayer.opponent,
      turnPhase: state.turnPhase,
    );
    final opponentMillTargets = <NodeID>{};
    for (final action in engine.legalActions(
      player: state.currentPlayer.opponent,
      state: opponentState,
    )) {
      final after = engine.apply(action: action, state: opponentState);
      if (engine.formsNewMill(
        action: action,
        before: opponentState,
        after: after,
      )) {
        switch (action) {
          case PlacePieceAction(:final to):
            opponentMillTargets.add(to);
          case MovePieceAction(:final to):
            opponentMillTargets.add(to);
          case UseCardAction():
          case CapturePieceAction():
          case SkipCardAction():
        }
      }
    }
    return actions.where((action) {
      return switch (action) {
        PlacePieceAction(:final to) => opponentMillTargets.contains(to),
        MovePieceAction(:final to) => opponentMillTargets.contains(to),
        UseCardAction() => false,
        CapturePieceAction() => false,
        SkipCardAction() => false,
      };
    }).toList();
  }

  int _preferredScore(GameAction action) {
    final target = switch (action) {
      PlacePieceAction(:final to) => to,
      MovePieceAction(:final to) => to,
      _ => null,
    };
    if (target == null) {
      return 0;
    }
    final index = _preferredNodes.indexOf(target);
    return index == -1 ? 0 : _preferredNodes.length - index;
  }
}
