import 'package:flutter_test/flutter_test.dart';
import 'package:nine_mens_morris_variant/domain/ability_card_id.dart';
import 'package:nine_mens_morris_variant/domain/action.dart';
import 'package:nine_mens_morris_variant/domain/board.dart';
import 'package:nine_mens_morris_variant/domain/card_target.dart';
import 'package:nine_mens_morris_variant/domain/game_phase.dart';
import 'package:nine_mens_morris_variant/domain/game_state.dart';
import 'package:nine_mens_morris_variant/domain/node_id.dart';
import 'package:nine_mens_morris_variant/domain/piece.dart';
import 'package:nine_mens_morris_variant/domain/player_id.dart';
import 'package:nine_mens_morris_variant/domain/player_state.dart';
import 'package:nine_mens_morris_variant/domain/turn_phase.dart';
import 'package:nine_mens_morris_variant/engine/game_engine.dart';

void main() {
  const engine = GameEngine();

  test('freeze targets opponent pieces only', () {
    final state = _cardState(
      hand: const [AbilityCardID.freeze],
      board: Board.empty()
          .put(NodeID.n0, const Piece(id: 'w', owner: PlayerID.white))
          .put(NodeID.n1, const Piece(id: 'b', owner: PlayerID.black)),
    );

    final actions = engine
        .legalActions(player: PlayerID.white, state: state)
        .whereType<UseCardAction>();

    expect(
      actions.any(
        (action) =>
            action.target is PieceTarget &&
            (action.target as PieceTarget).node == NodeID.n1,
      ),
      isTrue,
    );
    expect(
      actions.any(
        (action) =>
            action.target is PieceTarget &&
            (action.target as PieceTarget).node == NodeID.n0,
      ),
      isFalse,
    );
  });

  test('block targets empty unblocked nodes only', () {
    final state = _cardState(
      hand: const [AbilityCardID.block],
      blockedNodes: const {NodeID.n2: 1},
      board: Board.empty().put(
        NodeID.n0,
        const Piece(id: 'w', owner: PlayerID.white),
      ),
    );

    final targets = engine
        .legalActions(player: PlayerID.white, state: state)
        .whereType<UseCardAction>()
        .map((action) => action.target)
        .whereType<NodeTarget>()
        .map((target) => target.node);

    expect(targets, isNot(contains(NodeID.n0)));
    expect(targets, isNot(contains(NodeID.n2)));
    expect(targets, contains(NodeID.n1));
  });
}

GameState _cardState({
  required List<AbilityCardID> hand,
  required Board board,
  Map<NodeID, int> blockedNodes = const {},
}) {
  return GameState(
    board: board,
    currentPlayer: PlayerID.white,
    gamePhase: GamePhase.moving,
    turnPhase: TurnPhase.beforeAction,
    players: {
      PlayerID.white: PlayerState(
        id: PlayerID.white,
        piecesInHand: 0,
        capturedPieces: 0,
        hand: hand,
      ),
      PlayerID.black: const PlayerState(
        id: PlayerID.black,
        piecesInHand: 0,
        capturedPieces: 0,
        hand: [],
      ),
    },
    blockedNodes: blockedNodes,
    pendingCaptureBy: null,
    cardUsedThisTurn: false,
    turnNumber: 1,
  );
}
