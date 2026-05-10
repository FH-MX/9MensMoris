import '../engine/cpu/cpu_difficulty.dart';
import 'ability_card_id.dart';
import 'app_language.dart';
import 'app_mode.dart';
import 'local_rule_id.dart';
import 'opponent_type.dart';
import 'victory_condition.dart';

class GameConfig {
  // アプリの開始導線を表す。quick / custom / tutorial の分岐に使う。
  final AppMode mode;
  // 対戦相手の種類を表す。localHumanなら黒番も人間が操作する。
  final OpponentType opponentType;
  // 現在はstandardのみだが、将来拡張できるよう設定として保持する。
  final VictoryCondition victoryCondition;
  // CPU戦で黒番CPUが使う戦略の強さを表す。
  final CpuDifficulty cpuDifficulty;
  // UI言語はアプリ全体の設定と同期させるため設定値として保持する。
  final AppLanguage language;
  // ローカルルールのON/OFFをLocalRuleId単位で保持する。
  final Map<LocalRuleId, bool> localRules;

  const GameConfig({
    required this.mode,
    required this.opponentType,
    required this.victoryCondition,
    required this.cpuDifficulty,
    required this.language,
    required this.localRules,
  });

  // 指定したローカルルールが有効かどうかを返す。
  bool isRuleEnabled(LocalRuleId id) => localRules[id] ?? false;

  // 画面設定から一部だけ変更した新しい設定を作る。
  GameConfig copyWith({
    AppMode? mode,
    OpponentType? opponentType,
    VictoryCondition? victoryCondition,
    CpuDifficulty? cpuDifficulty,
    AppLanguage? language,
    Map<LocalRuleId, bool>? localRules,
  }) {
    return GameConfig(
      mode: mode ?? this.mode,
      opponentType: opponentType ?? this.opponentType,
      victoryCondition: victoryCondition ?? this.victoryCondition,
      cpuDifficulty: cpuDifficulty ?? this.cpuDifficulty,
      language: language ?? this.language,
      localRules: localRules ?? this.localRules,
    );
  }

  // 現在のローカルルールから、初期手札に入れるカードだけを返す。
  List<AbilityCardID> enabledCards() {
    // 能力カード全体がOFFなら、個別カード設定に関係なく手札なしにする。
    if (!isRuleEnabled(LocalRuleId.abilityCards)) {
      return const [];
    }

    // 初期版のカード3種を、個別ルールのON/OFFに合わせて並べる。
    return [
      if (isRuleEnabled(LocalRuleId.freezeCard)) AbilityCardID.freeze,
      if (isRuleEnabled(LocalRuleId.blockCard)) AbilityCardID.block,
      if (isRuleEnabled(LocalRuleId.jumpCard)) AbilityCardID.jump,
    ];
  }
}

// クイックプレイで使う固定設定。設計書16.1の内容に合わせる。
const quickConfig = GameConfig(
  mode: AppMode.quick,
  opponentType: OpponentType.cpu,
  victoryCondition: VictoryCondition.standard,
  cpuDifficulty: CpuDifficulty.normal,
  language: AppLanguage.system,
  localRules: {
    LocalRuleId.flying: true,
    LocalRuleId.abilityCards: true,
    LocalRuleId.sameCardSet: true,
    LocalRuleId.freezeCard: true,
    LocalRuleId.blockCard: true,
    LocalRuleId.jumpCard: true,
    LocalRuleId.deckBuilding: false,
    LocalRuleId.randomCardDeal: false,
  },
);

// カスタムゲーム画面の初期値。ユーザーがここから対戦形式やルールを変える。
const defaultCustomConfig = GameConfig(
  mode: AppMode.custom,
  opponentType: OpponentType.cpu,
  victoryCondition: VictoryCondition.standard,
  cpuDifficulty: CpuDifficulty.normal,
  language: AppLanguage.system,
  localRules: {
    LocalRuleId.flying: true,
    LocalRuleId.abilityCards: true,
    LocalRuleId.sameCardSet: true,
    LocalRuleId.freezeCard: true,
    LocalRuleId.blockCard: true,
    LocalRuleId.jumpCard: true,
    LocalRuleId.deckBuilding: false,
    LocalRuleId.randomCardDeal: false,
  },
);
