import 'player_id.dart';

class Piece {
  final String id;
  final PlayerID owner;
  final int frozenTurns;

  const Piece({required this.id, required this.owner, this.frozenTurns = 0});

  Piece copyWith({String? id, PlayerID? owner, int? frozenTurns}) {
    return Piece(
      id: id ?? this.id,
      owner: owner ?? this.owner,
      frozenTurns: frozenTurns ?? this.frozenTurns,
    );
  }
}
