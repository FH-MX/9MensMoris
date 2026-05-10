import 'ability_card_id.dart';
import 'player_id.dart';

class PlayerState {
  final PlayerID id;
  final int piecesInHand;
  final int capturedPieces;
  final List<AbilityCardID> hand;

  const PlayerState({
    required this.id,
    required this.piecesInHand,
    required this.capturedPieces,
    required this.hand,
  });

  PlayerState copyWith({
    int? piecesInHand,
    int? capturedPieces,
    List<AbilityCardID>? hand,
  }) {
    return PlayerState(
      id: id,
      piecesInHand: piecesInHand ?? this.piecesInHand,
      capturedPieces: capturedPieces ?? this.capturedPieces,
      hand: hand ?? this.hand,
    );
  }
}
