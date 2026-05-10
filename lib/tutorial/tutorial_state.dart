import 'tutorial_phase.dart';
import 'tutorial_step.dart';

class TutorialState {
  // 現在表示中の手順番号。
  final int stepIndex;
  // 説明中、操作待ち、ヒント表示中、完了のどれかを表す。
  final TutorialPhase phase;
  // 現在の手順定義。
  final TutorialStep currentStep;

  const TutorialState({
    required this.stepIndex,
    required this.phase,
    required this.currentStep,
  });
}
