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

  test('block remains active through the opponent turn', () {
    final blocked = engine.apply(
      action: const UseCardAction(
        card: AbilityCardID.block,
        target: NodeTarget(NodeID.n1),
      ),
      state: _cardState(
        hand: const [AbilityCardID.block],
        board: _durationBoard(),
      ),
    );
    final opponentTurn = engine.apply(
      action: const MovePieceAction(from: NodeID.n0, to: NodeID.n9),
      state: blocked,
    );

    expect(opponentTurn.currentPlayer, PlayerID.black);
    expect(opponentTurn.blockedNodes, containsPair(NodeID.n1, 1));
    expect(
      engine.legalDestinationsFrom(from: NodeID.n2, state: opponentTurn),
      isNot(contains(NodeID.n1)),
    );

    final selecting = engine.apply(
      action: const SkipCardAction(),
      state: opponentTurn,
    );
    final cleared = engine.apply(
      action: const MovePieceAction(from: NodeID.n14, to: NodeID.n13),
      state: selecting,
    );

    expect(cleared.blockedNodes, isNot(contains(NodeID.n1)));
  });

  test('freeze remains active through the opponent turn', () {
    final frozen = engine.apply(
      action: const UseCardAction(
        card: AbilityCardID.freeze,
        target: PieceTarget(NodeID.n2),
      ),
      state: _cardState(
        hand: const [AbilityCardID.freeze],
        board: _durationBoard(),
      ),
    );
    final opponentTurn = engine.apply(
      action: const MovePieceAction(from: NodeID.n0, to: NodeID.n9),
      state: frozen,
    );

    expect(opponentTurn.currentPlayer, PlayerID.black);
    expect(opponentTurn.board.pieceAt(NodeID.n2)?.frozenTurns, 1);
    expect(
      engine.legalDestinationsFrom(from: NodeID.n2, state: opponentTurn),
      isEmpty,
    );

    final selecting = engine.apply(
      action: const SkipCardAction(),
      state: opponentTurn,
    );
    final thawed = engine.apply(
      action: const MovePieceAction(from: NodeID.n14, to: NodeID.n13),
      state: selecting,
    );

    expect(thawed.board.pieceAt(NodeID.n2)?.frozenTurns, 0);
  });
}

Board _durationBoard() {
  return Board.empty()
      .put(NodeID.n0, const Piece(id: 'w1', owner: PlayerID.white))
      .put(NodeID.n3, const Piece(id: 'w2', owner: PlayerID.white))
      .put(NodeID.n6, const Piece(id: 'w3', owner: PlayerID.white))
      .put(NodeID.n2, const Piece(id: 'b1', owner: PlayerID.black))
      .put(NodeID.n14, const Piece(id: 'b2', owner: PlayerID.black))
      .put(NodeID.n23, const Piece(id: 'b3', owner: PlayerID.black));
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
