import 'package:flutter/material.dart';

import '../domain/ability_card_id.dart';
import '../l10n/app_strings.dart';

class CardHandView extends StatelessWidget {
  final List<AbilityCardID> cards;
  final bool enabled;
  final AbilityCardID? selectedCard;
  final ValueChanged<AbilityCardID>? onCardSelected;

  const CardHandView({
    super.key,
    required this.cards,
    this.enabled = false,
    this.selectedCard,
    this.onCardSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final card in cards) ...[
          // 選択中カードは、盤面の対象を選ぶ間もひと目で分かるように強調表示する。
          // 非選択カードは従来のOutlinedButtonの見た目を保ち、差分だけ目立たせる。
          if (card == selectedCard)
            Tooltip(
              message: _description(card),
              child: OutlinedButton.icon(
                onPressed: enabled ? () => onCardSelected?.call(card) : null,
                style: OutlinedButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  side: BorderSide(color: colorScheme.primary, width: 2),
                ),
                icon: Icon(_icon(card), size: 18),
                label: Text(_name(card)),
              ),
            )
          else
            Tooltip(
              message: _description(card),
              child: OutlinedButton.icon(
                onPressed: enabled ? () => onCardSelected?.call(card) : null,
                icon: Icon(_icon(card), size: 18),
                label: Text(_name(card)),
              ),
            ),
        ],
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
