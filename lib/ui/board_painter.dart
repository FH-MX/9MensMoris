import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/board.dart';
import '../domain/board_topology.dart';
import '../domain/node_id.dart';
import '../domain/player_id.dart';

class BoardPainter extends CustomPainter {
  // 現在の盤面状態。コマの所有者や配置を描画する。
  final Board board;
  // 操作候補として強調するノード一覧。
  final Set<NodeID> highlightedNodes;
  // 移動元など、プレイヤーが明示的に選択したノード。
  final NodeID? selectedNode;
  // マウスカーソルが重なっているノード。
  final NodeID? hoveredNode;
  // ブロックカードで一時的に使えないノード。
  final Map<NodeID, int> blockedNodes;

  const BoardPainter({
    required this.board,
    required this.highlightedNodes,
    required this.selectedNode,
    required this.hoveredNode,
    required this.blockedNodes,
  });

  static Offset pointFor(NodeID node, Size size) {
    final unit = math.min(size.width, size.height) / 6;
    final left = (size.width - unit * 6) / 2;
    final top = (size.height - unit * 6) / 2;
    final coords = _coords[node]!;
    return Offset(left + coords.$1 * unit, top + coords.$2 * unit);
  }

  static NodeID? nearestNode(Offset local, Size size) {
    NodeID? nearest;
    var distance = double.infinity;
    for (final node in NodeID.values) {
      final d = (pointFor(node, size) - local).distance;
      if (d < distance) {
        distance = d;
        nearest = node;
      }
    }
    return distance <= math.min(size.width, size.height) * 0.06
        ? nearest
        : null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final wood = Paint()..color = const Color(0xffc79557);
    canvas.drawRect(Offset.zero & size, wood);

    final line = Paint()
      ..color = const Color(0xff3b2819)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    for (final edge in _uniqueEdges()) {
      canvas.drawLine(pointFor(edge.$1, size), pointFor(edge.$2, size), line);
    }

    for (final node in NodeID.values) {
      final center = pointFor(node, size);
      final isHighlighted = highlightedNodes.contains(node);
      final isSelected = selectedNode == node;
      final isHovered = hoveredNode == node;
      final blocked = blockedNodes.containsKey(node);
      if (isHovered) {
        // ホバー中の点は、空点でもコマでも分かるように先に薄い輪を描く。
        canvas.drawCircle(
          center,
          board.pieceAt(node) == null ? 18 : 29,
          Paint()
            ..color = const Color(0xffffd36a).withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }
      canvas.drawCircle(
        center,
        isSelected ? 13 : (isHovered ? 12 : 10),
        Paint()
          ..color = isHighlighted
              ? const Color(0xff2f8f83)
              : isHovered
              ? const Color(0xffffd36a)
              : const Color(0xff2c1d12),
      );
      if (blocked) {
        canvas.drawCircle(
          center,
          16,
          Paint()
            ..color = const Color(0xffa23b3b)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
      final piece = board.pieceAt(node);
      if (piece != null) {
        canvas.drawCircle(
          center,
          22,
          Paint()
            ..color = piece.owner == PlayerID.white
                ? const Color(0xfff4f0e8)
                : const Color(0xff151515)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          center,
          22,
          Paint()
            ..color = const Color(0xff3b2819)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        if (piece.frozenTurns > 0) {
          canvas.drawCircle(
            center,
            26,
            Paint()
              ..color = const Color(0xff4aa3df)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) => true;

  static Iterable<(NodeID, NodeID)> _uniqueEdges() sync* {
    final seen = <String>{};
    for (final entry in adjacentNodes.entries) {
      for (final to in entry.value) {
        final a = entry.key.index;
        final b = to.index;
        final key = a < b ? '$a-$b' : '$b-$a';
        if (seen.add(key)) {
          yield (entry.key, to);
        }
      }
    }
  }
}

const _coords = <NodeID, (double, double)>{
  NodeID.n0: (0, 0),
  NodeID.n1: (3, 0),
  NodeID.n2: (6, 0),
  NodeID.n3: (1, 1),
  NodeID.n4: (3, 1),
  NodeID.n5: (5, 1),
  NodeID.n6: (2, 2),
  NodeID.n7: (3, 2),
  NodeID.n8: (4, 2),
  NodeID.n9: (0, 3),
  NodeID.n10: (1, 3),
  NodeID.n11: (2, 3),
  NodeID.n12: (4, 3),
  NodeID.n13: (5, 3),
  NodeID.n14: (6, 3),
  NodeID.n15: (2, 4),
  NodeID.n16: (3, 4),
  NodeID.n17: (4, 4),
  NodeID.n18: (1, 5),
  NodeID.n19: (3, 5),
  NodeID.n20: (5, 5),
  NodeID.n21: (0, 6),
  NodeID.n22: (3, 6),
  NodeID.n23: (6, 6),
};
