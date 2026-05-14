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
  // ミル成立直後に光らせる3点ライン。複数ミル同時成立にも対応する。
  final List<List<NodeID>> millEffectLines;
  // カード使用直後に反応させる対象ノード。
  final Set<NodeID> cardEffectNodes;
  // カードごとに異なるパルス色。演出がないときはnullにする。
  final Color? cardEffectColor;
  // 0.0から1.0へ進む短い演出の進行度。
  final double effectProgress;

  const BoardPainter({
    required this.board,
    required this.highlightedNodes,
    required this.selectedNode,
    required this.hoveredNode,
    required this.blockedNodes,
    this.millEffectLines = const [],
    this.cardEffectNodes = const {},
    this.cardEffectColor,
    this.effectProgress = 1,
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
    _drawMillEffects(canvas, size);

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
          18,
          Paint()
            ..color = const Color(0xff9f2525)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        _drawNoEntryMark(canvas, center, 12, filled: true);
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
          _drawNoEntryMark(canvas, center + const Offset(14, -14), 9);
        }
      }
      if (cardEffectNodes.contains(node) && cardEffectColor != null) {
        _drawCardPulse(canvas, center, cardEffectColor!);
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

  void _drawMillEffects(Canvas canvas, Size size) {
    if (millEffectLines.isEmpty) {
      return;
    }
    final pulse = math.sin(effectProgress * math.pi).clamp(0.0, 1.0);
    final glow = const Color(0xffffd24d).withValues(alpha: 0.25 + pulse * 0.45);
    final stroke = Paint()
      ..color = glow
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10 + pulse * 8;
    final core = Paint()
      ..color = const Color(0xfffff0a6).withValues(alpha: 0.65 + pulse * 0.25)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3 + pulse * 2;
    for (final line in millEffectLines) {
      if (line.length < 3) {
        continue;
      }
      final start = pointFor(line.first, size);
      final end = pointFor(line.last, size);
      canvas.drawLine(start, end, stroke);
      canvas.drawLine(start, end, core);
      for (final node in line) {
        final center = pointFor(node, size);
        canvas.drawCircle(
          center,
          30 + pulse * 8,
          Paint()
            ..color = const Color(0xffffd24d).withValues(alpha: 0.2)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          center,
          28 + pulse * 7,
          Paint()
            ..color = const Color(0xfffff0a6).withValues(alpha: 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 + pulse * 2,
        );
      }
    }
  }

  void _drawCardPulse(Canvas canvas, Offset center, Color color) {
    final pulse = math.sin(effectProgress * math.pi).clamp(0.0, 1.0);
    canvas.drawCircle(
      center,
      24 + effectProgress * 22,
      Paint()
        ..color = color.withValues(alpha: (1 - effectProgress) * 0.35)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      28 + pulse * 10,
      Paint()
        ..color = color.withValues(alpha: 0.45 + pulse * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 + pulse * 2,
    );
  }

  void _drawNoEntryMark(
    Canvas canvas,
    Offset center,
    double radius, {
    bool filled = false,
  }) {
    final red = Paint()
      ..color = const Color(0xffc62828).withValues(alpha: filled ? 0.86 : 0.95)
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final slash = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, red);
    if (filled) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xff7f1515)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.drawLine(
      center + Offset(-radius * 0.55, radius * 0.55),
      center + Offset(radius * 0.55, -radius * 0.55),
      slash,
    );
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
