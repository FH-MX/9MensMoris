import '../domain/action.dart';
import '../domain/game_state.dart';
import 'tutorial_goal.dart';

class TutorialStep {
  // チュートリアルの各手順で表示する固定盤面。
  final GameState initialState;
  // この手順で入力を受け付ける操作。初期版では正解候補と同じ範囲にする。
  final List<GameAction> allowedActions;
  // この手順を完了させる正解操作。将来の複合手順に備えてリストで持つ。
  final List<GameAction> correctActions;
  // 説明文の翻訳キー。
  final String explanationKey;
  // 間違えたときに表示するヒント文の翻訳キー。
  final String hintKey;
  // この手順で学ばせたいルール上の目的。
  final TutorialGoal goal;

  const TutorialStep({
    required this.initialState,
    required this.allowedActions,
    required this.correctActions,
    required this.explanationKey,
    required this.hintKey,
    required this.goal,
  });
}
