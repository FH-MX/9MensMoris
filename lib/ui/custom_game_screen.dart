import 'package:flutter/material.dart';

import '../domain/game_config.dart';
import '../domain/local_rule_id.dart';
import '../domain/opponent_type.dart';
import '../engine/cpu/cpu_difficulty.dart';
import '../l10n/app_strings.dart';
import 'game_screen.dart';

class CustomGameScreen extends StatefulWidget {
  const CustomGameScreen({super.key});

  @override
  State<CustomGameScreen> createState() => _CustomGameScreenState();
}

class _CustomGameScreenState extends State<CustomGameScreen> {
  // カスタム画面で編集中の設定。開始ボタンを押すまでゲーム状態には反映しない。
  GameConfig _config = defaultCustomConfig;

  @override
  Widget build(BuildContext context) {
    // 能力カード全体のON/OFFは、個別カードスイッチの有効状態にも使う。
    final abilityCardsEnabled = _config.isRuleEnabled(LocalRuleId.abilityCards);

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('custom.title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionTitle(label: AppStrings.t('custom.opponent')),
            const SizedBox(height: 8),
            SegmentedButton<OpponentType>(
              segments: [
                ButtonSegment(
                  value: OpponentType.cpu,
                  icon: const Icon(Icons.smart_toy),
                  label: Text(AppStrings.t('custom.opponent.cpu')),
                ),
                ButtonSegment(
                  value: OpponentType.localHuman,
                  icon: const Icon(Icons.people),
                  label: Text(AppStrings.t('custom.opponent.localHuman')),
                ),
              ],
              selected: {_config.opponentType},
              onSelectionChanged: (selection) {
                _setOpponentType(selection.first);
              },
            ),
            const SizedBox(height: 20),
            _SectionTitle(label: AppStrings.t('custom.cpuDifficulty')),
            const SizedBox(height: 8),
            DropdownButtonFormField<CpuDifficulty>(
              initialValue: _config.cpuDifficulty,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.speed),
                labelText: AppStrings.t('custom.cpuDifficulty'),
              ),
              items: [
                for (final difficulty in CpuDifficulty.values)
                  DropdownMenuItem(
                    value: difficulty,
                    child: Text(AppStrings.cpuDifficultyName(difficulty)),
                  ),
              ],
              onChanged: _config.opponentType == OpponentType.cpu
                  ? (difficulty) {
                      if (difficulty != null) {
                        _setCpuDifficulty(difficulty);
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 20),
            _SectionTitle(label: AppStrings.t('custom.localRules')),
            const SizedBox(height: 4),
            _RuleSwitch(
              title: AppStrings.t('custom.rule.flying'),
              value: _config.isRuleEnabled(LocalRuleId.flying),
              onChanged: (value) => _setRule(LocalRuleId.flying, value),
            ),
            _RuleSwitch(
              title: AppStrings.t('custom.rule.abilityCards'),
              value: abilityCardsEnabled,
              onChanged: (value) => _setRule(LocalRuleId.abilityCards, value),
            ),
            _RuleSwitch(
              title: AppStrings.t('custom.rule.sameCardSet'),
              value: _config.isRuleEnabled(LocalRuleId.sameCardSet),
              enabled: abilityCardsEnabled,
              onChanged: (value) => _setRule(LocalRuleId.sameCardSet, value),
            ),
            _RuleSwitch(
              title: AppStrings.t('custom.rule.freezeCard'),
              value: _config.isRuleEnabled(LocalRuleId.freezeCard),
              enabled: abilityCardsEnabled,
              onChanged: (value) => _setRule(LocalRuleId.freezeCard, value),
            ),
            _RuleSwitch(
              title: AppStrings.t('custom.rule.blockCard'),
              value: _config.isRuleEnabled(LocalRuleId.blockCard),
              enabled: abilityCardsEnabled,
              onChanged: (value) => _setRule(LocalRuleId.blockCard, value),
            ),
            _RuleSwitch(
              title: AppStrings.t('custom.rule.jumpCard'),
              value: _config.isRuleEnabled(LocalRuleId.jumpCard),
              enabled: abilityCardsEnabled,
              onChanged: (value) => _setRule(LocalRuleId.jumpCard, value),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.play_arrow),
              label: Text(AppStrings.t('custom.start')),
            ),
          ],
        ),
      ),
    );
  }

  void _setOpponentType(OpponentType opponentType) {
    // 予約済みのonlineは初期版UIに出さず、選べる2種だけを設定に反映する。
    setState(() {
      _config = _config.copyWith(opponentType: opponentType);
    });
  }

  void _setCpuDifficulty(CpuDifficulty cpuDifficulty) {
    // Hard / NightmareはFactory側でNormal相当にフォールバックする。
    setState(() {
      _config = _config.copyWith(cpuDifficulty: cpuDifficulty);
    });
  }

  void _setRule(LocalRuleId rule, bool enabled) {
    // Mapをコピーして更新し、const設定や既存Stateを破壊しない。
    final localRules = Map<LocalRuleId, bool>.from(_config.localRules);
    localRules[rule] = enabled;

    // 能力カードをOFFにしたときも個別カード値は保持して、再ON時に戻せるようにする。
    setState(() {
      _config = _config.copyWith(localRules: localRules);
    });
  }

  void _startGame() {
    // 設定済みのGameConfigをGameScreenへ渡し、GameEngineと初期手札に反映させる。
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => GameScreen(config: _config)));
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _RuleSwitch extends StatelessWidget {
  final String title;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _RuleSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}
