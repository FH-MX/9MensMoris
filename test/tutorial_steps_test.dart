import 'package:flutter_test/flutter_test.dart';
import 'package:nine_mens_morris_variant/engine/game_engine.dart';
import 'package:nine_mens_morris_variant/tutorial/tutorial_steps.dart';

void main() {
  const engine = GameEngine();

  test('tutorial steps have legal correct actions', () {
    for (final step in tutorialSteps) {
      var state = step.initialState;
      for (final action in step.correctActions) {
        final legalActions = engine.legalActions(
          player: state.currentPlayer,
          state: state,
        );

        expect(
          legalActions.any((legal) => legal.runtimeType == action.runtimeType),
          isTrue,
        );

        final after = engine.apply(action: action, state: state);
        expect(after, isNot(same(state)));
        state = after;
      }
    }
  });
}
