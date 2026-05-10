import 'package:flutter_test/flutter_test.dart';
import 'package:nine_mens_morris_variant/domain/board.dart';
import 'package:nine_mens_morris_variant/domain/node_id.dart';
import 'package:nine_mens_morris_variant/domain/piece.dart';
import 'package:nine_mens_morris_variant/domain/player_id.dart';
import 'package:nine_mens_morris_variant/engine/mill_detector.dart';

void main() {
  test('NodeID is fixed to 24 points', () {
    expect(NodeID.values.length, 24);
  });

  test('detects a horizontal mill', () {
    final board = Board.empty()
        .put(NodeID.n0, const Piece(id: 'w1', owner: PlayerID.white))
        .put(NodeID.n1, const Piece(id: 'w2', owner: PlayerID.white))
        .put(NodeID.n2, const Piece(id: 'w3', owner: PlayerID.white));

    const detector = MillDetector();

    expect(
      detector.isNodeInMill(
        node: NodeID.n1,
        player: PlayerID.white,
        board: board,
      ),
      isTrue,
    );
    expect(detector.millCount(PlayerID.white, board), 1);
  });
}
