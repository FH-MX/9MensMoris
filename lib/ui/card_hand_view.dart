import 'package:flutter/material.dart';

import '../domain/ability_card_id.dart';
import '../l10n/app_strings.dart';

class CardHandView extends StatelessWidget {
  final List<AbilityCardID> cards;
  final bool enabled;
  final ValueChanged<AbilityCardID>? onCardSelected;

  const CardHandView({
    super.key,
    required this.cards,
    this.enabled = false,
    this.onCardSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final card in cards)
          Tooltip(
            message: _description(card),
            child: OutlinedButton.icon(
              onPressed: enabled ? () => onCardSelected?.call(card) : null,
              icon: Icon(_icon(card), size: 18),
              label: Text(_name(card)),
            ),
          ),
      ],
    );
  }

  String _name(AbilityCardID card) {
    return switch (card) {
      AbilityCardID.freeze => AppStrings.t('card.freeze.name'),
      AbilityCardID.block => AppStrings.t('card.block.name'),
      AbilityCardID.jump => AppStrings.t('card.jump.name'),
    };
  }

  String _description(AbilityCardID card) {
    return switch (card) {
      AbilityCardID.freeze => AppStrings.t('card.freeze.description'),
      AbilityCardID.block => AppStrings.t('card.block.description'),
      AbilityCardID.jump => AppStrings.t('card.jump.description'),
    };
  }

  IconData _icon(AbilityCardID card) {
    return switch (card) {
      AbilityCardID.freeze => Icons.ac_unit,
      AbilityCardID.block => Icons.block,
      AbilityCardID.jump => Icons.open_in_full,
    };
  }
}
