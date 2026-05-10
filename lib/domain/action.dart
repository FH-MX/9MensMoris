import 'ability_card_id.dart';
import 'card_target.dart';
import 'node_id.dart';

sealed class GameAction {
  const GameAction();
}

class PlacePieceAction extends GameAction {
  final NodeID to;
  const PlacePieceAction(this.to);
}

class MovePieceAction extends GameAction {
  final NodeID from;
  final NodeID to;
  const MovePieceAction({required this.from, required this.to});
}

class CapturePieceAction extends GameAction {
  final NodeID at;
  const CapturePieceAction(this.at);
}

class UseCardAction extends GameAction {
  final AbilityCardID card;
  final CardTarget target;
  const UseCardAction({required this.card, required this.target});
}

class SkipCardAction extends GameAction {
  const SkipCardAction();
}
