import 'node_id.dart';

sealed class CardTarget {
  const CardTarget();
}

class NodeTarget extends CardTarget {
  final NodeID node;
  const NodeTarget(this.node);
}

class PieceTarget extends CardTarget {
  final NodeID node;
  const PieceTarget(this.node);
}

class JumpTarget extends CardTarget {
  final NodeID from;
  final NodeID to;
  const JumpTarget({required this.from, required this.to});
}
