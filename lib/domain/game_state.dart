import 'ability_card_id.dart';
import 'board.dart';
import 'game_phase.dart';
import 'node_id.dart';
import 'player_id.dart';
import 'player_state.dart';
import 'turn_phase.dart';

class GameState {
  final Board board;
  final PlayerID currentPlayer;
  final GamePhase gamePhase;
  final TurnPhase turnPhase;
  final Map<PlayerID, PlayerState> players;
  final Map<NodeID, int> blockedNodes;
  final PlayerID? pendingCaptureBy;
  final bool cardUsedThisTurn;
  final int turnNumber;
  final PlayerID? winner;

  const GameState({
    required this.board,
    required this.currentPlayer,
    required this.gamePhase,
    required this.turnPhase,
    required this.players,
    required this.blockedNodes,
    required this.pendingCaptureBy,
    required this.cardUsedThisTurn,
    required this.turnNumber,
    this.winner,
  });

  factory GameState.initial({
    bool withCards = true,
    List<AbilityCardID>? cards,
  }) {
    // 設定からカード一覧が渡されない場合は、初期版の標準3枚を使う。
    const standardCards = [
      AbilityCardID.freeze,
      AbilityCardID.block,
      AbilityCardID.jump,
    ];
    // カードOFF時は空配列、ON時は設定済みカード一覧を両プレイヤーに配る。
    final initialCards = withCards
        ? (cards ?? standardCards)
        : const <AbilityCardID>[];
    return GameState(
      board: Board.empty(),
      currentPlayer: PlayerID.white,
      gamePhase: GamePhase.placing,
      turnPhase: TurnPhase.beforeAction,
      players: {
        PlayerID.white: PlayerState(
          id: PlayerID.white,
          piecesInHand: 9,
          capturedPieces: 0,
          hand: initialCards,
        ),
        PlayerID.black: PlayerState(
          id: PlayerID.black,
          piecesInHand: 9,
          capturedPieces: 0,
          hand: initialCards,
        ),
      },
      blockedNodes: const {},
      pendingCaptureBy: null,
      cardUsedThisTurn: false,
      turnNumber: 1,
    );
  }

  PlayerState player(PlayerID id) => players[id]!;

  GameState copyWith({
    Board? board,
    PlayerID? currentPlayer,
    GamePhase? gamePhase,
    TurnPhase? turnPhase,
    Map<PlayerID, PlayerState>? players,
    Map<NodeID, int>? blockedNodes,
    PlayerID? pendingCaptureBy,
    bool clearPendingCaptureBy = false,
    bool? cardUsedThisTurn,
    int? turnNumber,
    PlayerID? winner,
    bool clearWinner = false,
  }) {
    return GameState(
      board: board ?? this.board,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      gamePhase: gamePhase ?? this.gamePhase,
      turnPhase: turnPhase ?? this.turnPhase,
      players: players ?? this.players,
      blockedNodes: blockedNodes ?? this.blockedNodes,
      pendingCaptureBy: clearPendingCaptureBy
          ? null
          : (pendingCaptureBy ?? this.pendingCaptureBy),
      cardUsedThisTurn: cardUsedThisTurn ?? this.cardUsedThisTurn,
      turnNumber: turnNumber ?? this.turnNumber,
      winner: clearWinner ? null : (winner ?? this.winner),
    );
  }
}
