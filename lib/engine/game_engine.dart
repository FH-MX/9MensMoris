import '../domain/ability_card_id.dart';
import '../domain/action.dart';
import '../domain/board.dart';
import '../domain/board_topology.dart';
import '../domain/card_target.dart';
import '../domain/game_config.dart';
import '../domain/game_phase.dart';
import '../domain/game_state.dart';
import '../domain/local_rule_id.dart';
import '../domain/node_id.dart';
import '../domain/piece.dart';
import '../domain/player_id.dart';
import '../domain/player_state.dart';
import '../domain/turn_phase.dart';
import 'mill_detector.dart';

class GameEngine {
  // ミル判定は差し替え可能にして、テストとルール拡張をしやすくする。
  final MillDetector millDetector;
  // ルールON/OFFやCPU戦設定など、ゲーム開始時に決めた設定を保持する。
  final GameConfig config;

  const GameEngine({
    this.millDetector = const MillDetector(),
    this.config = quickConfig,
  });

  List<GameAction> legalActions({
    required PlayerID player,
    required GameState state,
  }) {
    if (state.gamePhase == GamePhase.gameOver ||
        player != state.currentPlayer) {
      return const [];
    }
    if (state.turnPhase == TurnPhase.pendingCapture) {
      return removablePieces(
        opponent: player.opponent,
        state: state,
      ).map(CapturePieceAction.new).toList();
    }
    if (state.turnPhase == TurnPhase.beforeAction) {
      return [
        const SkipCardAction(),
        ..._legalCardActions(player: player, state: state),
      ];
    }
    if (state.turnPhase != TurnPhase.selectingAction) {
      return const [];
    }
    if (state.gamePhase == GamePhase.placing) {
      if (state.player(player).piecesInHand <= 0) {
        return const [];
      }
      return NodeID.values
          .where(
            (node) =>
                state.board.isEmpty(node) &&
                !state.blockedNodes.containsKey(node),
          )
          .map(PlacePieceAction.new)
          .toList();
    }
    return [
      for (final from in state.board.occupiedBy(player))
        for (final to in legalDestinationsFrom(from: from, state: state))
          MovePieceAction(from: from, to: to),
    ];
  }

  List<NodeID> legalDestinationsFrom({
    required NodeID from,
    required GameState state,
  }) {
    final piece = state.board.pieceAt(from);
    if (piece == null ||
        piece.owner != state.currentPlayer ||
        piece.frozenTurns > 0) {
      return const [];
    }
    final candidates = canFly(player: piece.owner, state: state)
        ? NodeID.values
        : adjacentNodes[from]!;
    return candidates
        .where(
          (node) =>
              state.board.isEmpty(node) &&
              !state.blockedNodes.containsKey(node),
        )
        .toList();
  }

  GameState apply({required GameAction action, required GameState state}) {
    if (!legalActions(
      player: state.currentPlayer,
      state: state,
    ).any((legal) => _sameAction(legal, action))) {
      return state;
    }
    return switch (action) {
      SkipCardAction() => state.copyWith(turnPhase: TurnPhase.selectingAction),
      PlacePieceAction(:final to) => _place(state, to),
      MovePieceAction(:final from, :final to) => _move(state, from, to),
      CapturePieceAction(:final at) => _capture(state, at),
      UseCardAction() => _useCard(state, action),
    };
  }

  bool formsNewMill({
    required GameAction action,
    required GameState before,
    required GameState after,
  }) {
    final completedAt = switch (action) {
      PlacePieceAction(:final to) => to,
      MovePieceAction(:final to) => to,
      UseCardAction(card: AbilityCardID.jump, target: JumpTarget(:final to)) =>
        to,
      _ => null,
    };
    if (completedAt == null) {
      return false;
    }
    return millDetector.formedNewMillAt(
      node: completedAt,
      player: before.currentPlayer,
      before: before.board,
      after: after.board,
    );
  }

  List<NodeID> removablePieces({
    required PlayerID opponent,
    required GameState state,
  }) {
    final opponentNodes = state.board.occupiedBy(opponent).toList();
    final outsideMills = opponentNodes
        .where(
          (node) => !millDetector.isNodeInMill(
            node: node,
            player: opponent,
            board: state.board,
          ),
        )
        .toList();
    return outsideMills.isNotEmpty ? outsideMills : opponentNodes;
  }

  PlayerID? winner(GameState state) {
    if (state.gamePhase == GamePhase.placing) {
      return null;
    }
    for (final player in PlayerID.values) {
      final opponent = player.opponent;
      if (state.board.pieceCount(opponent) <= 2) {
        return player;
      }
      final opponentState = state.copyWith(
        currentPlayer: opponent,
        turnPhase: TurnPhase.selectingAction,
        gamePhase: GamePhase.moving,
      );
      final hasMove = legalActions(
        player: opponent,
        state: opponentState,
      ).isNotEmpty;
      if (!hasMove) {
        return player;
      }
    }
    return null;
  }

  bool canFly({required PlayerID player, required GameState state}) {
    // ローカルルールでフライングをOFFにしたゲームでは、3個以下でも隣接移動だけにする。
    return config.isRuleEnabled(LocalRuleId.flying) &&
        state.gamePhase == GamePhase.moving &&
        state.board.pieceCount(player) <= 3;
  }

  GameState _place(GameState state, NodeID to) {
    final player = state.currentPlayer;
    final pieceId =
        '${player.name}-${state.player(player).piecesInHand}-${state.turnNumber}';
    final board = state.board.put(to, Piece(id: pieceId, owner: player));
    final players = Map<PlayerID, PlayerState>.from(state.players);
    players[player] = players[player]!.copyWith(
      piecesInHand: players[player]!.piecesInHand - 1,
    );
    final after = state.copyWith(board: board, players: players);
    return _afterBoardAction(
      before: state,
      after: after,
      actor: player,
      completedAt: to,
    );
  }

  GameState _move(GameState state, NodeID from, NodeID to) {
    final after = state.copyWith(board: state.board.move(from, to));
    return _afterBoardAction(
      before: state,
      after: after,
      actor: state.currentPlayer,
      completedAt: to,
    );
  }

  GameState _capture(GameState state, NodeID at) {
    final captured = state.board.pieceAt(at);
    if (captured == null) {
      return state;
    }
    final player = state.currentPlayer;
    final players = Map<PlayerID, PlayerState>.from(state.players);
    players[player] = players[player]!.copyWith(
      capturedPieces: players[player]!.capturedPieces + 1,
    );
    final after = state.copyWith(
      board: state.board.remove(at),
      players: players,
      turnPhase: TurnPhase.turnEnd,
      clearPendingCaptureBy: true,
    );
    final win = winner(after);
    return win == null
        ? _endTurn(after)
        : after.copyWith(gamePhase: GamePhase.gameOver, winner: win);
  }

  GameState _useCard(GameState state, UseCardAction action) {
    final player = state.currentPlayer;
    final players = Map<PlayerID, PlayerState>.from(state.players);
    players[player] = players[player]!.copyWith(
      hand: players[player]!.hand.where((card) => card != action.card).toList(),
    );
    var next = state.copyWith(players: players, cardUsedThisTurn: true);

    switch (action.card) {
      case AbilityCardID.freeze:
        final target = action.target as PieceTarget;
        final piece = next.board.pieceAt(target.node)!;
        next = next.copyWith(
          board: next.board.updatePiece(
            target.node,
            piece.copyWith(frozenTurns: 1),
          ),
        );
        return next.copyWith(turnPhase: TurnPhase.selectingAction);
      case AbilityCardID.block:
        final target = action.target as NodeTarget;
        next = next.copyWith(
          blockedNodes: {...next.blockedNodes, target.node: 1},
        );
        return next.copyWith(turnPhase: TurnPhase.selectingAction);
      case AbilityCardID.jump:
        final target = action.target as JumpTarget;
        final jumped = next.copyWith(
          board: next.board.move(target.from, target.to),
        );
        return _afterBoardAction(
          before: state,
          after: jumped,
          actor: player,
          completedAt: target.to,
        );
    }
  }

  GameState _afterBoardAction({
    required GameState before,
    required GameState after,
    required PlayerID actor,
    required NodeID completedAt,
  }) {
    if (millDetector.formedNewMillAt(
      node: completedAt,
      player: actor,
      before: before.board,
      after: after.board,
    )) {
      return after.copyWith(
        turnPhase: TurnPhase.pendingCapture,
        pendingCaptureBy: actor,
      );
    }
    return _endTurn(after.copyWith(turnPhase: TurnPhase.turnEnd));
  }

  GameState _endTurn(GameState state) {
    final moving = _nextGamePhase(state);
    final justEnteredMoving =
        state.gamePhase == GamePhase.placing && moving == GamePhase.moving;
    final board = _tickFrozenPieces(state.board);
    final blocked = <NodeID, int>{};
    for (final entry in state.blockedNodes.entries) {
      if (entry.value > 1) {
        blocked[entry.key] = entry.value - 1;
      }
    }
    final next = state.copyWith(
      board: board,
      blockedNodes: blocked,
      currentPlayer: state.currentPlayer.opponent,
      gamePhase: moving,
      turnPhase: TurnPhase.beforeAction,
      cardUsedThisTurn: false,
      turnNumber: state.turnNumber + 1,
      clearPendingCaptureBy: true,
    );
    if (justEnteredMoving) {
      return next;
    }
    final win = winner(next);
    return win == null
        ? next
        : next.copyWith(gamePhase: GamePhase.gameOver, winner: win);
  }

  GamePhase _nextGamePhase(GameState state) {
    if (state.gamePhase != GamePhase.placing) {
      return state.gamePhase;
    }
    final allPlaced = PlayerID.values.every(
      (player) => state.player(player).piecesInHand == 0,
    );
    return allPlaced ? GamePhase.moving : GamePhase.placing;
  }

  Board _tickFrozenPieces(Board board) {
    var next = board;
    for (final entry in board.nodes.entries) {
      final piece = entry.value;
      if (piece != null && piece.frozenTurns > 0) {
        next = next.updatePiece(
          entry.key,
          piece.copyWith(frozenTurns: piece.frozenTurns - 1),
        );
      }
    }
    return next;
  }

  List<GameAction> _legalCardActions({
    required PlayerID player,
    required GameState state,
  }) {
    // 能力カード全体がOFFなら、beforeActionでもSkip以外は出さない。
    if (!config.isRuleEnabled(LocalRuleId.abilityCards)) {
      return const [];
    }
    if (state.cardUsedThisTurn) {
      return const [];
    }
    final hand = state.player(player).hand;
    final actions = <GameAction>[];
    if (config.isRuleEnabled(LocalRuleId.freezeCard) &&
        hand.contains(AbilityCardID.freeze)) {
      actions.addAll(
        state.board
            .occupiedBy(player.opponent)
            .map(
              (node) => UseCardAction(
                card: AbilityCardID.freeze,
                target: PieceTarget(node),
              ),
            ),
      );
    }
    if (config.isRuleEnabled(LocalRuleId.blockCard) &&
        hand.contains(AbilityCardID.block)) {
      actions.addAll(
        NodeID.values
            .where(
              (node) =>
                  state.board.isEmpty(node) &&
                  !state.blockedNodes.containsKey(node),
            )
            .map(
              (node) => UseCardAction(
                card: AbilityCardID.block,
                target: NodeTarget(node),
              ),
            ),
      );
    }
    if (config.isRuleEnabled(LocalRuleId.jumpCard) &&
        hand.contains(AbilityCardID.jump) &&
        state.gamePhase == GamePhase.moving) {
      for (final from in state.board.occupiedBy(player)) {
        final piece = state.board.pieceAt(from);
        if (piece == null || piece.frozenTurns > 0) {
          continue;
        }
        for (final to in NodeID.values.where(
          (node) =>
              state.board.isEmpty(node) &&
              !state.blockedNodes.containsKey(node),
        )) {
          actions.add(
            UseCardAction(
              card: AbilityCardID.jump,
              target: JumpTarget(from: from, to: to),
            ),
          );
        }
      }
    }
    return actions;
  }

  bool _sameAction(GameAction a, GameAction b) {
    if (a.runtimeType != b.runtimeType) {
      return false;
    }
    return switch ((a, b)) {
      (SkipCardAction(), SkipCardAction()) => true,
      (PlacePieceAction a, PlacePieceAction b) => a.to == b.to,
      (MovePieceAction a, MovePieceAction b) =>
        a.from == b.from && a.to == b.to,
      (CapturePieceAction a, CapturePieceAction b) => a.at == b.at,
      (UseCardAction a, UseCardAction b) =>
        a.card == b.card && _sameTarget(a.target, b.target),
      _ => false,
    };
  }

  bool _sameTarget(CardTarget a, CardTarget b) {
    if (a.runtimeType != b.runtimeType) {
      return false;
    }
    return switch ((a, b)) {
      (NodeTarget a, NodeTarget b) => a.node == b.node,
      (PieceTarget a, PieceTarget b) => a.node == b.node,
      (JumpTarget a, JumpTarget b) => a.from == b.from && a.to == b.to,
      _ => false,
    };
  }
}
