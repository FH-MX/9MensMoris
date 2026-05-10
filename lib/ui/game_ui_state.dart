import '../domain/node_id.dart';

class GameUiState {
  // 通常操作で選択中のノード。移動元やJump元として使う。
  final NodeID? selectedNode;
  // 合法な移動先やカード対象など、操作候補として強調するノード。
  final List<NodeID> highlightedNodes;
  // マウスカーソルが重なっているノード。ルールには影響しない表示専用状態。
  final NodeID? hoveredNode;

  const GameUiState({
    this.selectedNode,
    this.highlightedNodes = const [],
    this.hoveredNode,
  });

  // 一部のUI状態だけを差し替えるためのコピー処理。
  GameUiState copyWith({
    NodeID? selectedNode,
    List<NodeID>? highlightedNodes,
    NodeID? hoveredNode,
    bool clearSelectedNode = false,
    bool clearHoveredNode = false,
  }) {
    return GameUiState(
      selectedNode: clearSelectedNode
          ? null
          : (selectedNode ?? this.selectedNode),
      highlightedNodes: highlightedNodes ?? this.highlightedNodes,
      hoveredNode: clearHoveredNode ? null : (hoveredNode ?? this.hoveredNode),
    );
  }
}
