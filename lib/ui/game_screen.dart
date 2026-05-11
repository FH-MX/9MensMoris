import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/ability_card_id.dart';
import '../domain/action.dart';
import '../domain/card_target.dart';
import '../domain/game_config.dart';
import '../domain/game_phase.dart';
import '../domain/game_state.dart';
import '../domain/node_id.dart';
import '../domain/opponent_type.dart';
import '../domain/player_id.dart';
import '../domain/player_state.dart';
import '../domain/turn_phase.dart';
import '../engine/cpu/cpu_strategy_factory.dart';
import '../engine/game_engine.dart';
import '../l10n/app_strings.dart';
import 'ads/ad_sense_banner.dart';
import 'board_painter.dart';
import 'card_hand_view.dart';
import 'game_ui_state.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  // 起動元が指定したゲーム設定を受け取り、クイックプレイ時はquickConfigを使う。
  final GameConfig config;

  const GameScreen({super.key, this.config = quickConfig});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameEngine _engine;
  late GameState _state;
  GameUiState _ui = const GameUiState();
  AbilityCardID? _selectedCard;

  @override
  void initState() {
    super.initState();
    // GameEngineにも同じ設定を渡し、UIと合法手判定のルールを一致させる。
    _engine = GameEngine(config: widget.config);
    // 初期手札はローカルルールから作る。初期版ではsameCardSetにより両者同一になる。
    _state = GameState.initial(cards: widget.config.enabledCards());
  }

  @override
  Widget build(BuildContext context) {
    final black = _state.player(PlayerID.black);
    final white = _state.player(PlayerID.white);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('app.title')),
        actions: [
          IconButton(
            tooltip: AppStrings.t('game.home'),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.home),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const AdSenseBanner(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 900) {
                    return _buildWideLayout(black, white);
                  }
                  return _buildNarrowLayout(black, white);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrowLayout(PlayerState black, PlayerState white) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // スマホWebではブラウザUIや広告で縦幅が小さくなるため、盤面は高さではなく幅を基準に確保する。
        final boardSide = math.max(
          0.0,
          math.min(constraints.maxWidth - 24, 520.0),
        );
        return SingleChildScrollView(
          child: ConstrainedBox(
            // 内容が少ない端末では画面いっぱいに広げ、多い端末では自然に縦スクロールさせる。
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                _PlayerPanel(
                  player: PlayerID.black,
                  piecesInHand: black.piecesInHand,
                  capturedPieces: black.capturedPieces,
                  cards: black.hand,
                  active: _state.currentPlayer == PlayerID.black,
                  canUseCards:
                      _state.currentPlayer == PlayerID.black &&
                      _state.turnPhase == TurnPhase.beforeAction &&
                      _isHumanTurn,
                  selectedCard: _state.currentPlayer == PlayerID.black
                      ? _selectedCard
                      : null,
                  onCardSelected: _selectCard,
                ),
                SizedBox(
                  // 盤面を正方形で固定し、狭いWeb表示でも潰れて線やコマが消えないようにする。
                  width: boardSide,
                  height: boardSide,
                  child: _BoardSurface(
                    painter: _boardPainter(),
                    onNodeTap: _handleNodeTap,
                    onNodeHover: _handleNodeHover,
                  ),
                ),
                _TurnControls(
                  instruction: _instruction(),
                  canContinue:
                      _state.turnPhase == TurnPhase.beforeAction &&
                      _isHumanTurn,
                  onContinue: () => _apply(const SkipCardAction()),
                ),
                _PlayerPanel(
                  player: PlayerID.white,
                  piecesInHand: white.piecesInHand,
                  capturedPieces: white.capturedPieces,
                  cards: white.hand,
                  active: _state.currentPlayer == PlayerID.white,
                  canUseCards:
                      _state.currentPlayer == PlayerID.white &&
                      _state.turnPhase == TurnPhase.beforeAction &&
                      _isHumanTurn,
                  selectedCard: _state.currentPlayer == PlayerID.white
                      ? _selectedCard
                      : null,
                  onCardSelected: _selectCard,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideLayout(PlayerState black, PlayerState white) {
    return Row(
      children: [
        SizedBox(
          width: 280,
          child: Column(
            children: [
              _PlayerPanel(
                player: PlayerID.black,
                piecesInHand: black.piecesInHand,
                capturedPieces: black.capturedPieces,
                cards: black.hand,
                active: _state.currentPlayer == PlayerID.black,
                canUseCards:
                    _state.currentPlayer == PlayerID.black &&
                    _state.turnPhase == TurnPhase.beforeAction &&
                    _isHumanTurn,
                selectedCard: _state.currentPlayer == PlayerID.black
                    ? _selectedCard
                    : null,
                onCardSelected: _selectCard,
              ),
              const Spacer(),
              _PlayerPanel(
                player: PlayerID.white,
                piecesInHand: white.piecesInHand,
                capturedPieces: white.capturedPieces,
                cards: white.hand,
                active: _state.currentPlayer == PlayerID.white,
                canUseCards:
                    _state.currentPlayer == PlayerID.white &&
                    _state.turnPhase == TurnPhase.beforeAction &&
                    _isHumanTurn,
                selectedCard: _state.currentPlayer == PlayerID.white
                    ? _selectedCard
                    : null,
                onCardSelected: _selectCard,
              ),
            ],
          ),
        ),
        Expanded(
          child: _BoardSurface(
            painter: _boardPainter(),
            onNodeTap: _handleNodeTap,
            onNodeHover: _handleNodeHover,
          ),
        ),
        SizedBox(
          width: 260,
          child: _TurnControls(
            instruction: _instruction(),
            canContinue:
                _state.turnPhase == TurnPhase.beforeAction && _isHumanTurn,
            onContinue: () => _apply(const SkipCardAction()),
          ),
        ),
      ],
    );
  }

  BoardPainter _boardPainter() {
    return BoardPainter(
      board: _state.board,
      highlightedNodes: _ui.highlightedNodes.toSet(),
      selectedNode: _ui.selectedNode,
      hoveredNode: _ui.hoveredNode,
      blockedNodes: _state.blockedNodes,
    );
  }

  // ローカル2人対戦では白黒どちらも人間、CPU戦では白だけ人間として扱う。
  bool get _isHumanTurn {
    return widget.config.opponentType == OpponentType.localHuman ||
        _state.currentPlayer == PlayerID.white;
  }

  // 黒番CPUを自動実行すべき状態かどうかを一箇所で判定する。
  bool get _isCpuTurn {
    return widget.config.opponentType == OpponentType.cpu &&
        _state.currentPlayer == PlayerID.black;
  }

  void _selectCard(AbilityCardID card) {
    final actions = _engine
        .legalActions(player: _state.currentPlayer, state: _state)
        .whereType<UseCardAction>();
    setState(() {
      _selectedCard = card;
      _ui = _freshUi(highlightedNodes: _targetNodesFor(card, actions).toList());
    });
  }

  // ホバー以外のUI状態を作り直すときに、現在のホバー表示だけは維持する。
  GameUiState _freshUi({
    NodeID? selectedNode,
    List<NodeID> highlightedNodes = const [],
  }) {
    return GameUiState(
      selectedNode: selectedNode,
      highlightedNodes: highlightedNodes,
      hoveredNode: _ui.hoveredNode,
    );
  }

  Iterable<NodeID> _targetNodesFor(
    AbilityCardID card,
    Iterable<UseCardAction> actions,
  ) sync* {
    for (final action in actions.where((action) => action.card == card)) {
      switch (action.target) {
        case NodeTarget(:final node):
          yield node;
        case PieceTarget(:final node):
          yield node;
        case JumpTarget(:final from):
          yield from;
      }
    }
  }

  void _handleNodeTap(NodeID node) {
    if (!_isHumanTurn || _state.gamePhase == GamePhase.gameOver) {
      return;
    }
    final selectedCard = _selectedCard;
    if (selectedCard != null) {
      _handleCardTargetTap(selectedCard, node);
      return;
    }
    if (_state.turnPhase == TurnPhase.pendingCapture) {
      if (_engine
          .removablePieces(
            opponent: _state.currentPlayer.opponent,
            state: _state,
          )
          .contains(node)) {
        _apply(CapturePieceAction(node));
      }
      return;
    }
    if (_state.turnPhase == TurnPhase.beforeAction) {
      return;
    }
    if (_state.gamePhase == GamePhase.placing) {
      final action = PlacePieceAction(node);
      if (_isLegal(action)) {
        _apply(action);
      }
      return;
    }
    final selected = _ui.selectedNode;
    if (selected == null) {
      final destinations = _engine.legalDestinationsFrom(
        from: node,
        state: _state,
      );
      if (destinations.isNotEmpty) {
        setState(
          () => _ui = _freshUi(
            selectedNode: node,
            highlightedNodes: destinations,
          ),
        );
      }
    } else {
      if (node == selected) {
        setState(() => _ui = _freshUi());
        return;
      }
      if (_ui.highlightedNodes.contains(node)) {
        _apply(MovePieceAction(from: selected, to: node));
        return;
      }
      final destinations = _engine.legalDestinationsFrom(
        from: node,
        state: _state,
      );
      setState(() {
        _ui = destinations.isEmpty
            ? _freshUi()
            : _freshUi(selectedNode: node, highlightedNodes: destinations);
      });
    }
  }

  void _handleNodeHover(NodeID? node) {
    // 同じ点の上でマウスが動き続けても、不要な再描画はしない。
    if (_ui.hoveredNode == node) {
      return;
    }
    setState(() {
      _ui = _ui.copyWith(hoveredNode: node, clearHoveredNode: node == null);
    });
  }

  void _handleCardTargetTap(AbilityCardID card, NodeID node) {
    final actions = _engine
        .legalActions(player: _state.currentPlayer, state: _state)
        .whereType<UseCardAction>();
    if (card == AbilityCardID.jump) {
      final selected = _ui.selectedNode;
      if (selected == null) {
        final destinations = actions
            .where((action) => action.card == card)
            .map((action) => action.target)
            .whereType<JumpTarget>()
            .where((target) => target.from == node)
            .map((target) => target.to)
            .toList();
        if (destinations.isNotEmpty) {
          setState(
            () => _ui = _freshUi(
              selectedNode: node,
              highlightedNodes: destinations,
            ),
          );
        }
      } else {
        if (_ui.highlightedNodes.contains(node)) {
          _apply(
            UseCardAction(
              card: card,
              target: JumpTarget(from: selected, to: node),
            ),
          );
          return;
        }
        final destinations = actions
            .where((action) => action.card == card)
            .map((action) => action.target)
            .whereType<JumpTarget>()
            .where((target) => target.from == node)
            .map((target) => target.to)
            .toList();
        setState(() {
          _ui = destinations.isEmpty
              ? _freshUi()
              : _freshUi(selectedNode: node, highlightedNodes: destinations);
        });
      }
      return;
    }
    if (!_ui.highlightedNodes.contains(node)) {
      return;
    }
    final target = card == AbilityCardID.freeze
        ? PieceTarget(node)
        : NodeTarget(node);
    _apply(UseCardAction(card: card, target: target));
  }

  void _apply(GameAction action) {
    final next = _engine.apply(action: action, state: _state);
    if (identical(next, _state)) {
      return;
    }
    final highlightedNodes =
        next.turnPhase == TurnPhase.pendingCapture &&
            (widget.config.opponentType == OpponentType.localHuman ||
                next.currentPlayer == PlayerID.white)
        ? _engine.removablePieces(
            opponent: next.currentPlayer.opponent,
            state: next,
          )
        : const <NodeID>[];
    setState(() {
      _state = next;
      _ui = _freshUi(highlightedNodes: highlightedNodes);
      _selectedCard = null;
    });
    _afterStateChanged();
  }

  bool _isLegal(GameAction action) {
    return _engine
        .legalActions(player: _state.currentPlayer, state: _state)
        .any((legal) => _sameAction(legal, action));
  }

  bool _sameAction(GameAction a, GameAction b) {
    if (a.runtimeType != b.runtimeType) {
      return false;
    }
    return switch ((a, b)) {
      (SkipCardAction(), SkipCardAction()) => true,
      (PlacePieceAction a, PlacePieceAction b) => a.to == b.to,
      (MovePieceAction a, MovePieceAction b) =>
        a.from == b.from && a.to == b.to,
      (CapturePieceAction a, CapturePieceAction b) => a.at == b.at,
      (UseCardAction a, UseCardAction b) =>
        a.card == b.card && _sameTarget(a.target, b.target),
      _ => false,
    };
  }

  bool _sameTarget(CardTarget a, CardTarget b) {
    if (a.runtimeType != b.runtimeType) {
      return false;
    }
    return switch ((a, b)) {
      (NodeTarget a, NodeTarget b) => a.node == b.node,
      (PieceTarget a, PieceTarget b) => a.node == b.node,
      (JumpTarget a, JumpTarget b) => a.from == b.from && a.to == b.to,
      _ => false,
    };
  }

  void _afterStateChanged() {
    if (_state.gamePhase == GamePhase.gameOver && _state.winner != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultScreen(winner: _state.winner!),
          ),
        );
      });
      return;
    }
    if (_isCpuTurn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runCpuTurn());
    }
  }

  void _runCpuTurn() {
    if (!mounted || !_isCpuTurn || _state.gamePhase == GamePhase.gameOver) {
      return;
    }
    final strategy = CpuStrategyFactory.create(widget.config.cpuDifficulty);
    final action = strategy.selectAction(state: _state, engine: _engine);
    setState(() {
      _state = _engine.apply(action: action, state: _state);
    });
    _afterStateChanged();
  }

  String _instruction() {
    if (_isCpuTurn) {
      return AppStrings.t('game.opponentTurn');
    }
    return switch (_state.turnPhase) {
      TurnPhase.beforeAction => AppStrings.t('game.useCardOrContinue'),
      TurnPhase.pendingCapture => AppStrings.t('game.capturePiece'),
      TurnPhase.selectingAction when _state.gamePhase == GamePhase.placing =>
        AppStrings.t('game.placePiece'),
      TurnPhase.selectingAction when _ui.selectedNode == null => AppStrings.t(
        'game.selectPiece',
      ),
      TurnPhase.selectingAction => AppStrings.t('game.selectDestination'),
      TurnPhase.turnEnd => '',
    };
  }
}

class _BoardSurface extends StatelessWidget {
  final BoardPainter painter;
  final ValueChanged<NodeID> onNodeTap;
  final ValueChanged<NodeID?> onNodeHover;

  const _BoardSurface({
    required this.painter,
    required this.onNodeTap,
    required this.onNodeHover,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onHover: (event) {
                  // クリック判定と同じ近接判定で、点やコマの上にいるかを調べる。
                  onNodeHover(
                    BoardPainter.nearestNode(event.localPosition, size),
                  );
                },
                onExit: (_) => onNodeHover(null),
                child: GestureDetector(
                  onTapUp: (details) {
                    final node = BoardPainter.nearestNode(
                      details.localPosition,
                      size,
                    );
                    if (node != null) {
                      onNodeTap(node);
                    }
                  },
                  child: CustomPaint(painter: painter),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TurnControls extends StatelessWidget {
  final String instruction;
  final bool canContinue;
  final VoidCallback onContinue;

  const _TurnControls({
    required this.instruction,
    required this.canContinue,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(instruction, textAlign: TextAlign.center),
          if (canContinue) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.arrow_forward),
              label: Text(AppStrings.t('game.continue')),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayerPanel extends StatelessWidget {
  final PlayerID player;
  final int piecesInHand;
  final int capturedPieces;
  final List<AbilityCardID> cards;
  final bool active;
  final bool canUseCards;
  final AbilityCardID? selectedCard;
  final ValueChanged<AbilityCardID>? onCardSelected;

  const _PlayerPanel({
    required this.player,
    required this.piecesInHand,
    required this.capturedPieces,
    required this.cards,
    required this.active,
    this.canUseCards = false,
    this.selectedCard,
    this.onCardSelected,
  });

  @override
  Widget build(BuildContext context) {
    final name = player == PlayerID.white
        ? AppStrings.t('game.white')
        : AppStrings.t('game.black');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: active ? const Color(0xfff0e3ce) : const Color(0xfffaf7f2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$name  $piecesInHand / $capturedPieces',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          CardHandView(
            cards: cards,
            enabled: canUseCards,
            selectedCard: selectedCard,
            onCardSelected: onCardSelected,
          ),
        ],
      ),
    );
  }
}
