import '../domain/ability_card_id.dart';
import '../domain/action.dart';
import '../domain/board.dart';
import '../domain/card_target.dart';
import '../domain/game_phase.dart';
import '../domain/game_state.dart';
import '../domain/node_id.dart';
import '../domain/piece.dart';
import '../domain/player_id.dart';
import '../domain/player_state.dart';
import '../domain/turn_phase.dart';
import 'tutorial_goal.dart';
import 'tutorial_step.dart';

// 初期版チュートリアルで使う7つの固定手順。
final tutorialSteps = <TutorialStep>[
  TutorialStep(
    initialState: _state(
      turnPhase: TurnPhase.selectingAction,
      whiteHand: 7,
      blackHand: 7,
      board: Board.empty()
          .put(NodeID.n0, const Piece(id: 't1-w0', owner: PlayerID.white))
          .put(NodeID.n1, const Piece(id: 't1-w1', owner: PlayerID.white))
          .put(NodeID.n9, const Piece(id: 't1-b9', owner: PlayerID.black))
          .put(NodeID.n14, const Piece(id: 't1-b14', owner: PlayerID.black)),
    ),
    allowedActions: const [PlacePieceAction(NodeID.n2)],
    correctActions: const [PlacePieceAction(NodeID.n2)],
    explanationKey: 'tutorial.step.formMill.explanation',
    hintKey: 'tutorial.step.formMill.hint',
    goal: TutorialGoal.formMill,
  ),
  TutorialStep(
    initialState: _state(
      turnPhase: TurnPhase.pendingCapture,
      pendingCaptureBy: PlayerID.white,
      whiteHand: 6,
      blackHand: 7,
      board: Board.empty()
          .put(NodeID.n0, const Piece(id: 't2-w0', owner: PlayerID.white))
          .put(NodeID.n1, const Piece(id: 't2-w1', owner: PlayerID.white))
          .put(NodeID.n2, const Piece(id: 't2-w2', owner: PlayerID.white))
          .put(NodeID.n9, const Piece(id: 't2-b9', owner: PlayerID.black))
          .put(NodeID.n14, const Piece(id: 't2-b14', owner: PlayerID.black)),
    ),
    allowedActions: const [CapturePieceAction(NodeID.n9)],
    correctActions: const [CapturePieceAction(NodeID.n9)],
    explanationKey: 'tutorial.step.capture.explanation',
    hintKey: 'tutorial.step.capture.hint',
    goal: TutorialGoal.capturePiece,
  ),
  TutorialStep(
    initialState: _state(
      gamePhase: GamePhase.moving,
      turnPhase: TurnPhase.selectingAction,
      board: Board.empty()
          .put(NodeID.n0, const Piece(id: 't3-w0', owner: PlayerID.white))
          .put(NodeID.n3, const Piece(id: 't3-w3', owner: PlayerID.white))
          .put(NodeID.n6, const Piece(id: 't3-w6', owner: PlayerID.white))
          .put(NodeID.n9, const Piece(id: 't3-w9', owner: PlayerID.white))
          .put(NodeID.n2, const Piece(id: 't3-b2', owner: PlayerID.black))
          .put(NodeID.n5, const Piece(id: 't3-b5', owner: PlayerID.black))
          .put(NodeID.n14, const Piece(id: 't3-b14', owner: PlayerID.black)),
    ),
    allowedActions: const [MovePieceAction(from: NodeID.n0, to: NodeID.n1)],
    correctActions: const [MovePieceAction(from: NodeID.n0, to: NodeID.n1)],
    explanationKey: 'tutorial.step.move.explanation',
    hintKey: 'tutorial.step.move.hint',
    goal: TutorialGoal.movePiece,
  ),
  TutorialStep(
    initialState: _state(
      gamePhase: GamePhase.moving,
      turnPhase: TurnPhase.selectingAction,
      board: Board.empty()
          .put(NodeID.n0, const Piece(id: 't4-w0', owner: PlayerID.white))
          .put(NodeID.n1, const Piece(id: 't4-w1', owner: PlayerID.white))
          .put(NodeID.n6, const Piece(id: 't4-w6', owner: PlayerID.white))
          .put(NodeID.n9, const Piece(id: 't4-b9', owner: PlayerID.black))
          .put(NodeID.n10, const Piece(id: 't4-b10', owner: PlayerID.black))
          .put(NodeID.n14, const Piece(id: 't4-b14', owner: PlayerID.black)),
    ),
    allowedActions: const [MovePieceAction(from: NodeID.n0, to: NodeID.n23)],
    correctActions: const [MovePieceAction(from: NodeID.n0, to: NodeID.n23)],
    explanationKey: 'tutorial.step.flying.explanation',
    hintKey: 'tutorial.step.flying.hint',
    goal: TutorialGoal.useFlying,
  ),
  TutorialStep(
    initialState: _state(
      gamePhase: GamePhase.moving,
      turnPhase: TurnPhase.beforeAction,
      whiteCards: const [AbilityCardID.freeze],
      board: Board.empty()
          .put(NodeID.n0, const Piece(id: 't5-w0', owner: PlayerID.white))
          .put(NodeID.n6, const Piece(id: 't5-w6', owner: PlayerID.white))
          .put(NodeID.n9, const Piece(id: 't5-w9', owner: PlayerID.white))
          .put(NodeID.n1, const Piece(id: 't5-b1', owner: PlayerID.black))
          .put(NodeID.n2, const Piece(id: 't5-b2', owner: PlayerID.black))
          .put(NodeID.n14, const Piece(id: 't5-b14', owner: PlayerID.black)),
    ),
    allowedActions: const [
      UseCardAction(card: AbilityCardID.freeze, target: PieceTarget(NodeID.n1)),
    ],
    correctActions: const [
      UseCardAction(card: AbilityCardID.freeze, target: PieceTarget(NodeID.n1)),
    ],
    explanationKey: 'tutorial.step.freeze.explanation',
    hintKey: 'tutorial.step.freeze.hint',
    goal: TutorialGoal.useFreezeCard,
  ),
  TutorialStep(
    initialState: _state(
      gamePhase: GamePhase.moving,
      turnPhase: TurnPhase.beforeAction,
      whiteCards: const [AbilityCardID.block],
      board: Board.empty()
          .put(NodeID.n0, const Piece(id: 't6-w0', owner: PlayerID.white))
          .put(NodeID.n6, const Piece(id: 't6-w6', owner: PlayerID.white))
          .put(NodeID.n9, const Piece(id: 't6-w9', owner: PlayerID.white))
          .put(NodeID.n1, const Piece(id: 't6-b1', owner: PlayerID.black))
          .put(NodeID.n14, const Piece(id: 't6-b14', owner: PlayerID.black)),
    ),
    allowedActions: const [
      UseCardAction(card: AbilityCardID.block, target: NodeTarget(NodeID.n2)),
    ],
    correctActions: const [
      UseCardAction(card: AbilityCardID.block, target: NodeTarget(NodeID.n2)),
    ],
    explanationKey: 'tutorial.step.block.explanation',
    hintKey: 'tutorial.step.block.hint',
    goal: TutorialGoal.useBlockCard,
  ),
  TutorialStep(
    initialState: _state(
      gamePhase: GamePhase.moving,
      turnPhase: TurnPhase.beforeAction,
      whiteCards: const [AbilityCardID.jump],
      board: Board.empty()
          .put(NodeID.n0, const Piece(id: 't7-w0', owner: PlayerID.white))
          .put(NodeID.n1, const Piece(id: 't7-w1', owner: PlayerID.white))
          .put(NodeID.n7, const Piece(id: 't7-w7', owner: PlayerID.white))
          .put(NodeID.n9, const Piece(id: 't7-b9', owner: PlayerID.black))
          .put(NodeID.n10, const Piece(id: 't7-b10', owner: PlayerID.black))
          .put(NodeID.n14, const Piece(id: 't7-b14', owner: PlayerID.black)),
    ),
    allowedActions: const [
      UseCardAction(
        card: AbilityCardID.jump,
        target: JumpTarget(from: NodeID.n7, to: NodeID.n2),
      ),
    ],
    correctActions: const [
      UseCardAction(
        card: AbilityCardID.jump,
        target: JumpTarget(from: NodeID.n7, to: NodeID.n2),
      ),
    ],
    explanationKey: 'tutorial.step.jump.explanation',
    hintKey: 'tutorial.step.jump.hint',
    goal: TutorialGoal.useJumpCard,
  ),
];

GameState _state({
  required Board board,
  GamePhase gamePhase = GamePhase.placing,
  TurnPhase turnPhase = TurnPhase.beforeAction,
  PlayerID currentPlayer = PlayerID.white,
  PlayerID? pendingCaptureBy,
  int whiteHand = 0,
  int blackHand = 0,
  List<AbilityCardID> whiteCards = const [],
  List<AbilityCardID> blackCards = const [],
}) {
  // チュートリアルは固定盤面なので、必要な値だけを明示してGameStateを作る。
  return GameState(
    board: board,
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
    blockedNodes: const {},
    pendingCaptureBy: pendingCaptureBy,
    cardUsedThisTurn: false,
    turnNumber: 1,
  );
}
