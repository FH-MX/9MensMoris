import '../domain/board.dart';
import '../domain/board_topology.dart';
import '../domain/node_id.dart';
import '../domain/player_id.dart';

class MillDetector {
  const MillDetector();

  bool isNodeInMill({
    required NodeID node,
    required PlayerID player,
    required Board board,
  }) {
    return millLines
        .where((line) => line.contains(node))
        .any((line) => isMill(line, player, board));
  }

  bool isMill(List<NodeID> line, PlayerID player, Board board) {
    return line.every((node) => board.pieceAt(node)?.owner == player);
  }

  int millCount(PlayerID player, Board board) {
    return millLines.where((line) => isMill(line, player, board)).length;
  }

  bool formedNewMill({
    required PlayerID player,
    required Board before,
    required Board after,
  }) {
    return millCount(player, after) > millCount(player, before);
  }

  bool formedNewMillAt({
    required NodeID node,
    required PlayerID player,
    required Board before,
    required Board after,
  }) {
    return millLines.where((line) => line.contains(node)).any((line) {
      return !isMill(line, player, before) && isMill(line, player, after);
    });
  }
}
