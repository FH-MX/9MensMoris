import 'node_id.dart';
import 'piece.dart';
import 'player_id.dart';

class Board {
  final Map<NodeID, Piece?> nodes;

  Board({required Map<NodeID, Piece?> nodes})
    : nodes = Map.unmodifiable(_normalize(nodes));

  factory Board.empty() {
    return Board(nodes: {for (final node in NodeID.values) node: null});
  }

  static Map<NodeID, Piece?> _normalize(Map<NodeID, Piece?> input) {
    return {for (final node in NodeID.values) node: input[node]};
  }

  Piece? pieceAt(NodeID node) => nodes[node];

  bool isEmpty(NodeID node) => nodes[node] == null;

  int pieceCount(PlayerID owner) {
    return nodes.values.where((piece) => piece?.owner == owner).length;
  }

  Iterable<NodeID> occupiedBy(PlayerID owner) sync* {
    for (final entry in nodes.entries) {
      if (entry.value?.owner == owner) {
        yield entry.key;
      }
    }
  }

  Board put(NodeID node, Piece piece) {
    final next = Map<NodeID, Piece?>.from(nodes);
    next[node] = piece;
    return Board(nodes: next);
  }

  Board remove(NodeID node) {
    final next = Map<NodeID, Piece?>.from(nodes);
    next[node] = null;
    return Board(nodes: next);
  }

  Board move(NodeID from, NodeID to) {
    final piece = nodes[from];
    if (piece == null) {
      return this;
    }
    final next = Map<NodeID, Piece?>.from(nodes);
    next[from] = null;
    next[to] = piece;
    return Board(nodes: next);
  }

  Board updatePiece(NodeID node, Piece piece) {
    final next = Map<NodeID, Piece?>.from(nodes);
    next[node] = piece;
    return Board(nodes: next);
  }
}
