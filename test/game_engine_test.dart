import 'package:flutter_test/flutter_test.dart';
import 'package:nine_mens_morris_variant/domain/ability_card_id.dart';
import 'package:nine_mens_morris_variant/domain/action.dart';
import 'package:nine_mens_morris_variant/domain/board.dart';
import 'package:nine_mens_morris_variant/domain/card_target.dart';
import 'package:nine_mens_morris_variant/domain/game_config.dart';
import 'package:nine_mens_morris_variant/domain/game_phase.dart';
import 'package:nine_mens_morris_variant/domain/game_state.dart';
import 'package:nine_mens_morris_variant/domain/local_rule_id.dart';
import 'package:nine_mens_morris_variant/domain/node_id.dart';
import 'package:nine_mens_morris_variant/domain/piece.dart';
import 'package:nine_mens_morris_variant/domain/player_id.dart';
import 'package:nine_mens_morris_variant/domain/player_state.dart';
import 'package:nine_mens_morris_variant/domain/turn_phase.dart';
import 'package:nine_mens_morris_variant/engine/game_engine.dart';

void main() {
  const engine = GameEngine();

  test('placing phase allows placing on empty nodes only', () {
    final state = GameState.initial(
      withCards: false,
    ).copyWith(turnPhase: TurnPhase.selectingAction);
    final after = engine.apply(
      action: const PlacePieceAction(NodeID.n0),
      state: state,
    );

    expect(after.board.pieceAt(NodeID.n0)?.owner, PlayerID.white);
    expect(after.player(PlayerID.white).piecesInHand, 8);

    final occupied = after.copyWith(
      currentPlayer: PlayerID.white,
      turnPhase: TurnPhase.selectingAction,
    );
    final unchanged = engine.apply(
      action: const PlacePieceAction(NodeID.n0),
      state: occupied,
    );
    expect(unchanged, same(occupied));
  });

  test('forming a mill enters pendingCapture', () {
    final state = _state(
      turnPhase: TurnPhase.selectingAction,
      board: Board.empty()
          .put(NodeID.n0, const Piece(id: 'w1', owner: PlayerID.white))
          .put(NodeID.n1, const Piece(id: 'w2', owner: PlayerID.white)),
      whiteHand: 7,
    );

    final after = engine.apply(
      action: const PlacePieceAction(NodeID.n2),
      state: state,
    );

    expect(after.turnPhase, TurnPhase.pendingCapture);
    expect(after.pendingCaptureBy, PlayerID.white);
  });

  test('removablePieces prioritizes opponent pieces outside mills', () {
    final state = _state(
      board: Board.empty()
          .put(NodeID.n0, const Piece(id: 'b1', owner: PlayerID.black))
          .put(NodeID.n1, const Piece(id: 'b2', owner: PlayerID.black))
          .put(NodeID.n2, const Piece(id: 'b3', owner: PlayerID.black))
          .put(NodeID.n3, const Piece(id: 'b4', owner: PlayerID.black)),
    );

    expect(engine.removablePieces(opponent: PlayerID.black, state: state), [
      NodeID.n3,
    ]);
  });

  test(
    'removablePieces allows any opponent piece when all three are in a mill',
    () {
      final state = _state(
        gamePhase: GamePhase.moving,
        board: Board.empty()
            .put(NodeID.n0, const Piece(id: 'b1', owner: PlayerID.black))
            .put(NodeID.n1, const Piece(id: 'b2', owner: PlayerID.black))
            .put(NodeID.n2, const Piece(id: 'b3', owner: PlayerID.black)),
      );

      expect(engine.removablePieces(opponent: PlayerID.black, state: state), [
        NodeID.n0,
        NodeID.n1,
        NodeID.n2,
      ]);
    },
  );

  test(
    'jumping into a new mill allows capture even when total mill count is unchanged',
    () {
      final state = _state(
        gamePhase: GamePhase.moving,
        turnPhase: TurnPhase.beforeAction,
        whiteCards: const [AbilityCardID.jump],
        board: Board.empty()
            .put(NodeID.n0, const Piece(id: 'w1', owner: PlayerID.white))
            .put(NodeID.n1, const Piece(id: 'w2', owner: PlayerID.white))
            .put(NodeID.n4, const Piece(id: 'w3', owner: PlayerID.white))
            .put(NodeID.n7, const Piece(id: 'w4', owner: PlayerID.white))
            .put(NodeID.n9, const Piece(id: 'b1', owner: PlayerID.black))
            .put(NodeID.n10, const Piece(id: 'b2', owner: PlayerID.black))
            .put(NodeID.n11, const Piece(id: 'b3', owner: PlayerID.black)),
      );

      final after = engine.apply(
        action: const UseCardAction(
          card: AbilityCardID.jump,
          target: JumpTarget(from: NodeID.n7, to: NodeID.n2),
        ),
        state: state,
      );

      expect(after.turnPhase, TurnPhase.pendingCapture);
      expect(engine.removablePieces(opponent: PlayerID.black, state: after), [
        NodeID.n9,
        NodeID.n10,
        NodeID.n11,
      ]);
    },
  );

  test('moving phase allows adjacent movement only', () {
    final state = _state(
      gamePhase: GamePhase.moving,
      turnPhase: TurnPhase.selectingAction,
      board: Board.empty()
          .put(NodeID.n0, const Piece(id: 'w1', owner: PlayerID.white))
          .put(NodeID.n2, const Piece(id: 'w2', owner: PlayerID.white))
          .put(NodeID.n3, const Piece(id: 'w3', owner: PlayerID.white))
          .put(NodeID.n5, const Piece(id: 'w4', owner: PlayerID.white))
          .put(NodeID.n9, const Piece(id: 'b1', owner: PlayerID.black))
          .put(NodeID.n1, const Piece(id: 'b2', owner: PlayerID.black)),
    );

    expect(
      engine.legalDestinationsFrom(from: NodeID.n0, state: state),
      isEmpty,
    );
  });

  test('canFly allows any empty unblocked destination with three pieces', () {
    final state = _state(
      gamePhase: GamePhase.moving,
      turnPhase: TurnPhase.selectingAction,
      blockedNodes: {NodeID.n5: 1},
      board: Board.empty()
          .put(NodeID.n0, const Piece(id: 'w1', owner: PlayerID.white))
          .put(NodeID.n1, const Piece(id: 'w2', owner: PlayerID.white))
          .put(NodeID.n2, const Piece(id: 'w3', owner: PlayerID.white)),
    );

    final destinations = engine.legalDestinationsFrom(
      from: NodeID.n0,
      state: state,
    );

    expect(engine.canFly(player: PlayerID.white, state: state), isTrue);
    expect(destinations, contains(NodeID.n23));
    expect(destinations, isNot(contains(NodeID.n5)));
  });

  test(
    'flying local rule disables non-adjacent movement with three pieces',
    () {
      final noFlyingEngine = GameEngine(
        config: quickConfig.copyWith(
          localRules: {...quickConfig.localRules, LocalRuleId.flying: false},
        ),
      );
      final state = _state(
        gamePhase: GamePhase.moving,
        turnPhase: TurnPhase.selectingAction,
        board: Board.empty()
            .put(NodeID.n0, const Piece(id: 'w1', owner: PlayerID.white))
            .put(NodeID.n1, const Piece(id: 'w2', owner: PlayerID.white))
            .put(NodeID.n2, const Piece(id: 'w3', owner: PlayerID.white)),
      );

      final destinations = noFlyingEngine.legalDestinationsFrom(
        from: NodeID.n0,
        state: state,
      );

      expect(
        noFlyingEngine.canFly(player: PlayerID.white, state: state),
        isFalse,
      );
      expect(destinations, isNot(contains(NodeID.n23)));
    },
  );

  test('ability card local rule removes card actions', () {
    final noCardEngine = GameEngine(
      config: quickConfig.copyWith(
        localRules: {
          ...quickConfig.localRules,
          LocalRuleId.abilityCards: false,
        },
      ),
    );
    final state = _state(
      turnPhase: TurnPhase.beforeAction,
      whiteCards: const [AbilityCardID.freeze, AbilityCardID.block],
      board: Board.empty().put(
        NodeID.n0,
        const Piece(id: 'b1', owner: PlayerID.black),
      ),
    );

    final actions = noCardEngine.legalActions(
      player: PlayerID.white,
      state: state,
    );

    expect(actions.whereType<UseCardAction>(), isEmpty);
    expect(actions.whereType<SkipCardAction>(), isNotEmpty);
  });

  test('frozen pieces cannot move', () {
    final state = _state(
      gamePhase: GamePhase.moving,
      turnPhase: TurnPhase.selectingAction,
      board: Board.empty().put(
        NodeID.n0,
        const Piece(id: 'w1', owner: PlayerID.white, frozenTurns: 1),
      ),
    );

    expect(
      engine.legalDestinationsFrom(from: NodeID.n0, state: state),
      isEmpty,
    );
  });

  test('jump card is a normal action and does not allow an extra move', () {
    final state = _state(
      gamePhase: GamePhase.moving,
      turnPhase: TurnPhase.beforeAction,
      board: Board.empty().put(
        NodeID.n0,
        const Piece(id: 'w1', owner: PlayerID.white),
      ),
      whiteCards: const [AbilityCardID.jump],
    );
    final jump = engine
        .legalActions(player: PlayerID.white, state: state)
        .whereType<UseCardAction>()
        .firstWhere((action) => action.card == AbilityCardID.jump);

    final after = engine.apply(action: jump, state: state);

    expect(after.turnPhase, TurnPhase.beforeAction);
    expect(after.currentPlayer, PlayerID.black);
  });

  test('placing phase does not declare a winner for two or fewer pieces', () {
    final state = _state(
      board: Board.empty()
          .put(NodeID.n0, const Piece(id: 'w1', owner: PlayerID.white))
          .put(NodeID.n1, const Piece(id: 'b1', owner: PlayerID.black)),
    );

    expect(engine.winner(state), isNull);
  });

  test('game does not end on the same turn that placing changes to moving', () {
    final state = _state(
      turnPhase: TurnPhase.selectingAction,
      whiteHand: 1,
      blackHand: 0,
      board: Board.empty()
          .put(NodeID.n0, const Piece(id: 'w1', owner: PlayerID.white))
          .put(NodeID.n1, const Piece(id: 'w2', owner: PlayerID.white))
          .put(NodeID.n3, const Piece(id: 'w3', owner: PlayerID.white))
          .put(NodeID.n4, const Piece(id: 'w4', owner: PlayerID.white))
          .put(NodeID.n6, const Piece(id: 'w5', owner: PlayerID.white))
          .put(NodeID.n7, const Piece(id: 'w6', owner: PlayerID.white))
          .put(NodeID.n9, const Piece(id: 'w7', owner: PlayerID.white))
          .put(NodeID.n10, const Piece(id: 'w8', owner: PlayerID.white))
          .put(NodeID.n2, const Piece(id: 'b1', owner: PlayerID.black))
          .put(NodeID.n5, const Piece(id: 'b2', owner: PlayerID.black)),
    );

    final after = engine.apply(
      action: const PlacePieceAction(NodeID.n12),
      state: state,
    );

    expect(after.gamePhase, GamePhase.moving);
    expect(after.winner, isNull);
  });
}

GameState _state({
  Board? board,
  GamePhase gamePhase = GamePhase.placing,
  TurnPhase turnPhase = TurnPhase.beforeAction,
  PlayerID currentPlayer = PlayerID.white,
  int whiteHand = 0,
  int blackHand = 0,
  List<AbilityCardID> whiteCards = const [],
  List<AbilityCardID> blackCards = const [],
  Map<NodeID, int> blockedNodes = const {},
}) {
  return GameState(
    board: board ?? Board.empty(),
    currentPlayer: currentPlayer,
    gamePhase: gamePhase,
    turnPhase: turnPhase,
    players: {
      PlayerID.white: PlayerState(
        id: PlayerID.white,
        piecesInHand: whiteHand,
        capturedPieces: 0,
        hand: whiteCards,
      ),
      PlayerID.black: PlayerState(
        id: PlayerID.black,
        piecesInHand: blackHand,
        capturedPieces: 0,
        hand: blackCards,
      ),
    },
    blockedNodes: blockedNodes,
    pendingCaptureBy: null,
    cardUsedThisTurn: false,
    turnNumber: 1,
  );
}
