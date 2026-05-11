import 'package:flutter/material.dart';

import '../domain/ability_card_id.dart';
import '../domain/action.dart';
import '../domain/card_target.dart';
import '../domain/node_id.dart';
import '../engine/game_engine.dart';
import '../l10n/app_strings.dart';
import '../tutorial/tutorial_phase.dart';
import '../tutorial/tutorial_state.dart';
import '../tutorial/tutorial_steps.dart';
import 'board_painter.dart';
import 'card_hand_view.dart';
import 'game_ui_state.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  // チュートリアルも本編と同じルールエンジンで盤面を進める。
  final GameEngine _engine = const GameEngine();
  // 現在のチュートリアル手順と表示フェーズ。
  late TutorialState _tutorial;
  // 現在の手順内で操作された盤面状態。
  late var _state = tutorialSteps.first.initialState;
  // 選択中ノード、ハイライト、ホバーなど表示専用状態。
  GameUiState _ui = const GameUiState();
  // カード手順でプレイヤーが選択中のカード。
  AbilityCardID? _selectedCard;
  // correctActionsを複数にした将来拡張用の進行位置。
  int _actionIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStep(0, phase: TutorialPhase.showingExplanation);
  }

  @override
  Widget build(BuildContext context) {
    final step = _tutorial.currentStep;
    final isCompleted = _tutorial.phase == TutorialPhase.completed;
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('tutorial.title'))),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _TutorialHeader(
                stepNumber: _tutorial.stepIndex + 1,
                stepCount: tutorialSteps.length,
                explanation: AppStrings.t(step.explanationKey),
                hint: _tutorial.phase == TutorialPhase.showingHint
                    ? AppStrings.t(step.hintKey)
                    : null,
                completedText: isCompleted
                    ? AppStrings.t('tutorial.completed')
                    : null,
              ),
            ),
            Expanded(
              child: _TutorialBoard(
                painter: _boardPainter(),
                onNodeTap: _handleNodeTap,
                onNodeHover: _handleNodeHover,
              ),
            ),
            _TutorialControls(
              cards: _state.player(_state.currentPlayer).hand,
              canUseCards:
                  _tutorial.phase != TutorialPhase.completed &&
                  _tutorial.phase != TutorialPhase.showingExplanation,
              selectedCard: _selectedCard,
              onCardSelected: _selectCard,
              primaryLabel: _primaryButtonLabel(),
              onPrimaryPressed: _handlePrimaryButton,
              showPrimaryButton:
                  _tutorial.phase == TutorialPhase.showingExplanation ||
                  _tutorial.phase == TutorialPhase.completed,
            ),
          ],
        ),
      ),
    );
  }

  BoardPainter _boardPainter() {
    return BoardPainter(
      board: _state.board,
      highlightedNodes: _highlightedNodes().toSet(),
      selectedNode: _ui.selectedNode,
      hoveredNode: _ui.hoveredNode,
      blockedNodes: _state.blockedNodes,
    );
  }

  List<NodeID> _highlightedNodes() {
    // 説明表示中と完了後は、操作誘導のハイライトを消す。
    if (_tutorial.phase == TutorialPhase.showingExplanation ||
        _tutorial.phase == TutorialPhase.completed) {
      return const [];
    }

    final expected = _expectedAction;
    return switch (expected) {
      PlacePieceAction(:final to) => [to],
      CapturePieceAction(:final at) => [at],
      MovePieceAction(:final from, :final to) => [
        if (_ui.selectedNode == from) to else from,
      ],
      UseCardAction(
        card: AbilityCardID.freeze,
        target: PieceTarget(:final node),
      )
          when _selectedCard == AbilityCardID.freeze =>
        [node],
      UseCardAction(card: AbilityCardID.block, target: NodeTarget(:final node))
          when _selectedCard == AbilityCardID.block =>
        [node],
      UseCardAction(
        card: AbilityCardID.jump,
        target: JumpTarget(:final from, :final to),
      )
          when _selectedCard == AbilityCardID.jump =>
        [if (_ui.selectedNode == from) to else from],
      _ => const [],
    };
  }

  GameAction get _expectedAction {
    return _tutorial.currentStep.correctActions[_actionIndex];
  }

  void _handleNodeTap(NodeID node) {
    // 説明中や完了後は、盤面を触っても状態を進めない。
    if (_tutorial.phase == TutorialPhase.showingExplanation ||
        _tutorial.phase == TutorialPhase.completed) {
      return;
    }

    final expected = _expectedAction;
    switch (expected) {
      case PlacePieceAction(:final to):
        _tryAction(node == to ? expected : null);
      case CapturePieceAction(:final at):
        _tryAction(node == at ? expected : null);
      case MovePieceAction(:final from, :final to):
        _handleMoveTap(node: node, from: from, to: to, action: expected);
      case UseCardAction(:final card, :final target):
        _handleCardTargetTap(node: node, card: card, target: target);
      case SkipCardAction():
        _showHint();
    }
  }

  void _handleMoveTap({
    required NodeID node,
    required NodeID from,
    required NodeID to,
    required MovePieceAction action,
  }) {
    // 1回目のタップは移動元、2回目のタップは移動先として扱う。
    if (_ui.selectedNode == null) {
      if (node == from) {
        setState(() {
          _ui = _freshUi(selectedNode: from);
        });
        return;
      }
      _showHint();
      return;
    }

    if (_ui.selectedNode == from && node == to) {
      _tryAction(action);
      return;
    }

    _showHint();
  }

  void _selectCard(AbilityCardID card) {
    final expected = _expectedAction;
    if (expected is! UseCardAction || expected.card != card) {
      _showHint();
      return;
    }

    // 正しいカードを選んだら、盤面側の対象ハイライトを表示する。
    setState(() {
      _selectedCard = card;
      _ui = _freshUi();
      _tutorial = TutorialState(
        stepIndex: _tutorial.stepIndex,
        phase: TutorialPhase.waitingForAction,
        currentStep: _tutorial.currentStep,
      );
    });
  }

  void _handleCardTargetTap({
    required NodeID node,
    required AbilityCardID card,
    required CardTarget target,
  }) {
    if (_selectedCard != card) {
      _showHint();
      return;
    }

    switch (target) {
      case PieceTarget(node: final targetNode):
        _tryAction(node == targetNode ? _expectedAction : null);
      case NodeTarget(node: final targetNode):
        _tryAction(node == targetNode ? _expectedAction : null);
      case JumpTarget(:final from, :final to):
        _handleJumpTap(node: node, from: from, to: to);
    }
  }

  void _handleJumpTap({
    required NodeID node,
    required NodeID from,
    required NodeID to,
  }) {
    // Jumpはカード選択後に、移動元、移動先の順で選ばせる。
    if (_ui.selectedNode == null) {
      if (node == from) {
        setState(() {
          _ui = _freshUi(selectedNode: from);
        });
        return;
      }
      _showHint();
      return;
    }

    if (_ui.selectedNode == from && node == to) {
      _tryAction(_expectedAction);
      return;
    }

    _showHint();
  }

  void _tryAction(GameAction? action) {
    if (action == null || !_sameAction(action, _expectedAction)) {
      _showHint();
      return;
    }

    final next = _engine.apply(action: action, state: _state);
    if (identical(next, _state)) {
      _showHint();
      return;
    }

    final isLastAction =
        _actionIndex == _tutorial.currentStep.correctActions.length - 1;
    if (!isLastAction) {
      setState(() {
        _state = next;
        _actionIndex += 1;
        _selectedCard = null;
        _ui = _freshUi();
      });
      return;
    }

    final nextStepIndex = _tutorial.stepIndex + 1;
    if (nextStepIndex >= tutorialSteps.length) {
      setState(() {
        _state = next;
        _selectedCard = null;
        _ui = _freshUi();
        _tutorial = TutorialState(
          stepIndex: _tutorial.stepIndex,
          phase: TutorialPhase.completed,
          currentStep: _tutorial.currentStep,
        );
      });
      return;
    }

    _loadStep(nextStepIndex, phase: TutorialPhase.showingExplanation);
  }

  void _showHint() {
    setState(() {
      _tutorial = TutorialState(
        stepIndex: _tutorial.stepIndex,
        phase: TutorialPhase.showingHint,
        currentStep: _tutorial.currentStep,
      );
      _selectedCard = null;
      _ui = _freshUi();
    });
  }

  void _handleNodeHover(NodeID? node) {
    // ホバー対象が変わったときだけ再描画する。
    if (_ui.hoveredNode == node) {
      return;
    }
    setState(() {
      _ui = _ui.copyWith(hoveredNode: node, clearHoveredNode: node == null);
    });
  }

  void _handlePrimaryButton() {
    if (_tutorial.phase == TutorialPhase.completed) {
      _loadStep(0, phase: TutorialPhase.showingExplanation);
      return;
    }

    setState(() {
      _tutorial = TutorialState(
        stepIndex: _tutorial.stepIndex,
        phase: TutorialPhase.waitingForAction,
        currentStep: _tutorial.currentStep,
      );
    });
  }

  String _primaryButtonLabel() {
    return _tutorial.phase == TutorialPhase.completed
        ? AppStrings.t('tutorial.restart')
        : AppStrings.t('tutorial.try');
  }

  void _loadStep(int index, {required TutorialPhase phase}) {
    final step = tutorialSteps[index];
    setState(() {
      _tutorial = TutorialState(
        stepIndex: index,
        phase: phase,
        currentStep: step,
      );
      _state = step.initialState;
      _ui = const GameUiState();
      _selectedCard = null;
      _actionIndex = 0;
    });
  }

  GameUiState _freshUi({NodeID? selectedNode}) {
    return GameUiState(
      selectedNode: selectedNode,
      hoveredNode: _ui.hoveredNode,
    );
  }

  bool _sameAction(GameAction a, GameAction b) {
    if (a.runtimeType != b.runtimeType) {
      return false;
    }
    return switch ((a, b)) {
      (PlacePieceAction a, PlacePieceAction b) => a.to == b.to,
      (MovePieceAction a, MovePieceAction b) =>
        a.from == b.from && a.to == b.to,
      (CapturePieceAction a, CapturePieceAction b) => a.at == b.at,
      (UseCardAction a, UseCardAction b) =>
        a.card == b.card && _sameTarget(a.target, b.target),
      (SkipCardAction(), SkipCardAction()) => true,
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
}

class _TutorialHeader extends StatelessWidget {
  final int stepNumber;
  final int stepCount;
  final String explanation;
  final String? hint;
  final String? completedText;

  const _TutorialHeader({
    required this.stepNumber,
    required this.stepCount,
    required this.explanation,
    this.hint,
    this.completedText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.t('tutorial.stepCounter')
              .replaceAll('{current}', '$stepNumber')
              .replaceAll('{total}', '$stepCount'),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Text(explanation, style: Theme.of(context).textTheme.bodyLarge),
        if (hint != null) ...[
          const SizedBox(height: 8),
          Text(hint!, style: const TextStyle(color: Color(0xff9a4a20))),
        ],
        if (completedText != null) ...[
          const SizedBox(height: 8),
          Text(
            completedText!,
            style: const TextStyle(
              color: Color(0xff2f6f49),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _TutorialBoard extends StatelessWidget {
  final BoardPainter painter;
  final ValueChanged<NodeID> onNodeTap;
  final ValueChanged<NodeID?> onNodeHover;

  const _TutorialBoard({
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

class _TutorialControls extends StatelessWidget {
  final List<AbilityCardID> cards;
  final bool canUseCards;
  final AbilityCardID? selectedCard;
  final ValueChanged<AbilityCardID> onCardSelected;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final bool showPrimaryButton;

  const _TutorialControls({
    required this.cards,
    required this.canUseCards,
    required this.selectedCard,
    required this.onCardSelected,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.showPrimaryButton,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cards.isNotEmpty)
            CardHandView(
              cards: cards,
              enabled: canUseCards,
              selectedCard: selectedCard,
              onCardSelected: onCardSelected,
            ),
          if (showPrimaryButton) ...[
            if (cards.isNotEmpty) const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onPrimaryPressed,
              icon: const Icon(Icons.play_arrow),
              label: Text(primaryLabel),
            ),
          ],
        ],
      ),
    );
  }
}
