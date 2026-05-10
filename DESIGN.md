
---

## 0. 設計方針

このアプリは、伝統的なボードゲーム **ナインメンズモリス** をベースに、初心者にも分かりやすいチュートリアルと、両プレイヤーに同じ能力カードを配る独自要素を加えたターン制戦略ゲームである。

基本方針は次の通り。

- 標準ナインメンズモリスのルールを壊さずに拡張する。
- 盤面・ルール・AI・UIを明確に分離する。
- UI側にルール判定を書かない。
- GameEngine側にFlutter Widgetや画面処理を書かない。
- 初期版では、まずEasy / Normal CPUで最後まで遊べる状態を目指す。
- Hard / Nightmare AI、オンライン対戦、デッキ構築は将来拡張として予約する。
- 文字列は日本語・英語・スペイン語対応を前提に、ARBファイルで管理する。

---

## 1. プロジェクト概要

| 項目 | 内容 |
|---|---|
| アプリ名 | 未定 |
| ベースゲーム | Nine Men's Morris / ナインメンズモリス |
| プラットフォーム | iOS / Android |
| 開発環境 | Flutter / Dart |
| アーキテクチャ | MVVM + Domain / Engine 分離 |
| 主なターゲット | 初心者〜中級者のボードゲームプレイヤー |
| コンセプト | 能力カードとチュートリアルで学べるナインメンズモリス |
| 収益化 | 初期版はなし。将来的にAdMobを検討 |
| オンライン対戦 | 初期版では実装しない。将来実装予定 |

### 1.1 想定する体験

- ルールを知らない初心者でも、固定盤面チュートリアルで操作しながら理解できる。
- クイックプレイでは設定を変えず、すぐCPUと遊べる。
- カスタムゲームではカードやローカルルールのON/OFFを調整できる。
- 能力カードはランダムではなく、両プレイヤーに同じカードセットを配る。
- 同条件でカードをいつ使うかが読み合いになる。

---

## 2. 標準ルールの要約

ナインメンズモリスは、24個の点を持つ盤面で行う2人用ボードゲームである。

各プレイヤーは9個のコマを持つ。プレイヤーが縦または横に自分のコマを3つ並べると「ミル」が成立し、相手のコマを1つ取り除くことができる。

勝利条件は、相手のコマを2個以下にすること、または相手が合法手を指せない状態にすることである。

ゲームは次の段階で進行する。

1. 配置フェーズ  
   盤面が空の状態から、プレイヤーが交互に空いている点へコマを置く。

2. 移動フェーズ  
   すべてのコマを置き終えた後、プレイヤーは自分のコマを隣接する空き点へ動かす。

3. フライング  
   コマが3個以下になったプレイヤーは、隣接点に限らず、空いている任意の点へ移動できる。

このアプリでは、フライングを標準で有効にする。ただし、ゲーム全体のフェーズとして `flying` を持つのではなく、プレイヤーごとに `canFly(player, state)` で判定する。

---

## 3. ドメインモデル

### 3.1 NodeID

盤面上の24個の点を表す。

```dart
// node_id.dart
// 盤面上の24点を表す。
// 0〜23以外の点を追加してはいけない。

enum NodeID {
  n0, n1, n2, n3, n4, n5,
  n6, n7, n8, n9, n10, n11,
  n12, n13, n14, n15, n16, n17,
  n18, n19, n20, n21, n22, n23,
}
```

### 3.2 PlayerID

プレイヤーは2人固定。

```dart
// player_id.dart
// 2人対戦専用。
// 3人以上のプレイヤーを追加してはいけない。

enum PlayerID {
  white,
  black,
}
```

補助として、相手プレイヤーを返す拡張を用意してよい。

```dart
extension PlayerIdExtension on PlayerID {
  PlayerID get opponent {
    return this == PlayerID.white ? PlayerID.black : PlayerID.white;
  }
}
```

### 3.3 Piece

盤上のコマを表す。

```dart
// piece.dart
// 盤上のコマ。
// frozenTurns が 1 以上なら、そのコマは移動できない。

class Piece {
  final String id;
  final PlayerID owner;
  final int frozenTurns;

  const Piece({
    required this.id,
    required this.owner,
    this.frozenTurns = 0,
  });
}
```

### 3.4 Board

24点の盤面を表す。

```dart
// board.dart
// 24点の盤面。
// 各NodeIDには最大1つのPieceだけ置ける。

class Board {
  final Map<NodeID, Piece?> nodes;

  const Board({required this.nodes});
}
```

制約：

- `nodes` は必ず24個の `NodeID` を持つ。
- 1つの点に複数のコマを置いてはいけない。
- コマの所有者は `white` または `black` のどちらかである。

### 3.5 GamePhase

ゲーム全体の大きな進行段階を表す。

```dart
// game_phase.dart

enum GamePhase {
  placing,  // 9個のコマを交互に置く段階
  moving,   // 配置完了後、コマを動かす段階
  gameOver, // 勝敗決定後
}
```

注意：

- `flying` は `GamePhase` に含めない。
- フライングはプレイヤーごとの状態であり、片方だけがフライング可能になる場合があるため、`canFly(player, state)` で判定する。

### 3.6 TurnPhase

1ターン内の状態を表す。

```dart
// turn_phase.dart

enum TurnPhase {
  beforeAction,     // カード使用可能な段階
  selectingAction,  // 配置・移動などの通常行動を選ぶ段階
  pendingCapture,   // ミル成立後、相手のコマを取る段階
  turnEnd,          // ターン終了処理
}
```

### 3.7 AbilityCardID

初期版で使う能力カードは3種類だけ。

```dart
// ability_card_id.dart
// Phase 1では freeze / block / jump の3種類以外を追加しない。

enum AbilityCardID {
  freeze,
  block,
  jump,
}
```

### 3.8 PlayerState

プレイヤーごとの状態を表す。

```dart
// player_state.dart

class PlayerState {
  final PlayerID id;
  final int piecesInHand;          // まだ配置していないコマ数
  final int capturedPieces;        // 取った相手コマ数
  final List<AbilityCardID> hand;  // 未使用カード。公開情報。

  const PlayerState({
    required this.id,
    required this.piecesInHand,
    required this.capturedPieces,
    required this.hand,
  });
}
```

### 3.9 GameState

ゲーム全体の状態を表す。

```dart
// game_state.dart

class GameState {
  final Board board;
  final PlayerID currentPlayer;
  final GamePhase gamePhase;
  final TurnPhase turnPhase;
  final Map<PlayerID, PlayerState> players;

  // ブロックされている点と残りターン数。
  final Map<NodeID, int> blockedNodes;

  // ミル成立後に、どのプレイヤーが除去権を持っているか。
  final PlayerID? pendingCaptureBy;

  // 1ターンにカードを2枚以上使わせないためのフラグ。
  final bool cardUsedThisTurn;

  final int turnNumber;

  const GameState({
    required this.board,
    required this.currentPlayer,
    required this.gamePhase,
    required this.turnPhase,
    required this.players,
    required this.blockedNodes,
    required this.pendingCaptureBy,
    required this.cardUsedThisTurn,
    required this.turnNumber,
  });
}
```

重要：

- `GameState` に UI 状態を入れてはいけない。
- `selectedNode` や `highlightedNodes` は `GameUiState` に置く。

### 3.10 GameUiState

UIだけで使う状態。

```dart
// game_ui_state.dart
// ルール判定には使わない。

class GameUiState {
  final NodeID? selectedNode;
  final List<NodeID> highlightedNodes;

  const GameUiState({
    this.selectedNode,
    this.highlightedNodes = const [],
  });
}
```

---

## 4. アクション定義

プレイヤーまたはCPUが選べる行動を表す。

```dart
// action.dart

sealed class Action {
  const Action();
}

class PlacePieceAction extends Action {
  final NodeID to;
  const PlacePieceAction(this.to);
}

class MovePieceAction extends Action {
  final NodeID from;
  final NodeID to;
  const MovePieceAction({required this.from, required this.to});
}

class CapturePieceAction extends Action {
  final NodeID at;
  const CapturePieceAction(this.at);
}

class UseCardAction extends Action {
  final AbilityCardID card;
  final CardTarget target;
  const UseCardAction({required this.card, required this.target});
}
```

### 4.1 CardTarget

```dart
// card_target.dart

sealed class CardTarget {
  const CardTarget();
}

class NodeTarget extends CardTarget {
  final NodeID node;
  const NodeTarget(this.node);
}

class PieceTarget extends CardTarget {
  final NodeID node;
  const PieceTarget(this.node);
}

class JumpTarget extends CardTarget {
  final NodeID from;
  final NodeID to;
  const JumpTarget({required this.from, required this.to});
}
```

---

## 5. 能力カード設計

### 5.1 基本方針

- ランダム配布ではなく、両プレイヤーに同じカードを配る。
- 手札は公開情報にする。
- 1ターンに使えるカードは最大1枚。
- カードは `beforeAction` でのみ使用できる。
- 初期版では `Freeze` / `Block` / `Jump` の3種類だけ。

### 5.2 Freeze

効果：

- 相手の盤上コマ1つを対象にする。
- 対象コマの `frozenTurns` を1にする。
- `frozenTurns > 0` のコマは移動できない。

制約：

- 相手の盤上コマにのみ使用可能。
- 空き点には使用不可。
- 自分のコマには使用不可。
- 使用後も通常行動は可能。

### 5.3 Block

効果：

- 空いている点1つを1ターン封鎖する。
- 封鎖された点には、配置・移動・Jumpの移動先として入れない。

制約：

- コマがある点には使用不可。
- すでにブロックされている点には使用不可。
- 使用後も通常行動は可能。

### 5.4 Jump

効果：

- 自分のコマ1つを、任意の空き点へ移動できる。
- 隣接している必要はない。

制約：

- 配置フェーズでは使用不可。
- 自分の盤上コマにのみ使用可能。
- 移動先は空き点でなければならない。
- ブロック中の点には移動できない。
- Freeze中のコマはJumpできない。
- Jumpは通常行動扱いとする。
- Jump使用後に追加の `MovePieceAction` を許可してはいけない。

---

## 6. ゲームモード

```dart
// app_mode.dart

enum AppMode {
  quick,
  custom,
  tutorial,
}
```

### 6.1 Quick

初心者向けに、設定変更不可のモード。

仕様：

- CPU対戦
- CPU難易度はNormal固定
- フライングあり
- 能力カードあり
- 同一カードセットあり
- カードはFreeze / Block / Jumpの3枚
- 勝利条件はstandard
- タイマーなし

### 6.2 Custom

設定変更可能なモード。

設定候補：

- 対戦相手：ローカル2人 / CPU / 将来オンライン
- CPU難易度：Easy / Normal / Hard / Nightmare
- フライングON/OFF
- 能力カードON/OFF
- 同一カードセットON/OFF

ただし、初期版ではHard / Nightmare / onlineは予約のみ。

### 6.3 Tutorial

固定盤面と指示でルールを学ぶモード。

仕様：

- 盤面は固定。
- 正解操作は基本1つ。
- 間違った操作では状態を進めない。
- ヒントを表示する。
- カード説明も含める。

---

## 7. OpponentType

```dart
// opponent_type.dart

enum OpponentType {
  localHuman,
  cpu,
  online, // 将来実装予定。初期版では使わない。
}
```

オンライン対戦は初期版では実装しない。ただし、将来追加しやすいように `OpponentType.online` は予約しておく。

オンライン化の前提：

- `GameState` は純粋データであること。
- UI状態を含まないこと。
- プレイヤー操作は `Action` として表現されること。
- 通信では状態そのものより、原則としてActionを送る設計にすること。

---

## 8. 勝利条件

```dart
// victory_condition.dart

enum VictoryCondition {
  standard,
}
```

### 8.1 standard

勝利条件：

1. 相手の盤上コマ数が2個以下になる。
2. 相手に合法手がない。

注意：

- 配置フェーズ中は、相手の盤上コマが2個以下でも敗北判定しない。
- 未配置コマがあるため、配置フェーズ中の2個以下判定は無効。
- 勝敗判定は基本的に `turnEnd` または `capturePiece` 後に行う。

---

## 9. ローカルルール・拡張設計

### 9.1 LocalRuleId

```dart
// local_rule_id.dart

enum LocalRuleId {
  flying,
  abilityCards,
  sameCardSet,
  freezeCard,
  blockCard,
  jumpCard,
  deckBuilding,
  randomCardDeal,
}
```

### 9.2 初期採用ルール

| ルール | 内容 | 初期値 |
|---|---|---|
| flying | 3個以下で任意移動 | ON |
| abilityCards | 能力カードを使う | ON |
| sameCardSet | 両者に同じカードを配る | ON |
| freezeCard | Freezeを使う | ON |
| blockCard | Blockを使う | ON |
| jumpCard | Jumpを使う | ON |
| deckBuilding | 自分でカードを組む | OFF |
| randomCardDeal | ランダム配布 | OFF |

### 9.3 RuleModifier

新しいルールをコアロジックに直接混ぜすぎないため、将来的には `RuleModifier` 方式を使う。

```dart
abstract class RuleModifier {
  LocalRuleId get id;

  List<Action> modifyLegalActions({
    required GameState state,
    required PlayerID player,
    required List<Action> baseActions,
  });

  GameState afterActionApplied({
    required GameState before,
    required Action action,
    required GameState after,
  });
}
```

初期版で必要な考え方：

- FlyingRuleModifier
- AbilityCardRuleModifier
- BlockNodeRuleModifier

---

## 10. 状態機械

### 10.1 GamePhase

```text
placing → moving → gameOver
```

### 10.2 TurnPhase

```text
beforeAction
  ↓
selectingAction
  ↓
pendingCapture  ※ミル成立時のみ
  ↓
turnEnd
  ↓
次プレイヤーの beforeAction
```

### 10.3 状態遷移

#### 配置フェーズ

```text
[placing / beforeAction]
  → useCard() または skipCard()
      → [placing / selectingAction]

[placing / selectingAction]
  → placePiece()
      → ミル成立あり
          → [placing / pendingCapture]
      → ミル成立なし
          → [placing / turnEnd]

[placing / pendingCapture]
  → capturePiece()
      → [placing / turnEnd]
```

すべてのコマを置き終えたら、次のターンから `moving` に移行する。

#### 移動フェーズ

```text
[moving / beforeAction]
  → useCard() または skipCard()
      → [moving / selectingAction]

[moving / selectingAction]
  → movePiece()
      → ミル成立あり
          → [moving / pendingCapture]
      → ミル成立なし
          → [moving / turnEnd]

[moving / pendingCapture]
  → capturePiece()
      → 勝利条件成立
          → [gameOver]
      → 勝利条件なし
          → [moving / turnEnd]
```

#### フライング

フライングはGamePhaseではなく、移動先判定で使う。

```dart
bool canFly(PlayerID player, GameState state)
```

`canFly` がtrueなら、そのプレイヤーは空いている任意の点へ移動できる。

---

## 11. GameEngine

GameEngineは、ゲームルールだけを扱う。

```dart
// game_engine.dart
// UI、広告、音声、アニメーションを入れてはいけない。

class GameEngine {
  List<Action> legalActions({
    required PlayerID player,
    required GameState state,
  });

  List<NodeID> legalDestinationsFrom({
    required NodeID from,
    required GameState state,
  });

  GameState apply({
    required Action action,
    required GameState state,
  });

  bool formsNewMill({
    required Action action,
    required GameState before,
    required GameState after,
  });

  List<NodeID> removablePieces({
    required PlayerID opponent,
    required GameState state,
  });

  PlayerID? winner(GameState state);

  bool canFly({
    required PlayerID player,
    required GameState state,
  });
}
```

### 11.1 legalDestinationsFrom の仕様

コマをタップしたときに、そのコマが動ける点だけを返す。

条件：

- from に現在プレイヤーのコマがあること。
- `frozenTurns > 0` のコマは移動不可。
- 通常移動では隣接する空き点だけを返す。
- `canFly` がtrueなら、空いている任意の点を返す。
- ブロック中の点は返さない。

UIはこの関数の結果だけを使ってハイライトする。

### 11.2 removablePieces の仕様

相手のコマを取り除く候補を返す。

ルール：

- 相手にミル外のコマがある場合、ミル内のコマは除去不可。
- 相手のすべてのコマがミル内にある場合、ミル内のコマも除去可能。

### 11.3 winner の仕様

- 配置フェーズ中は2個以下判定をしない。
- 移動フェーズ以降で、相手の盤上コマが2個以下なら勝利。
- 移動フェーズ以降で、相手に合法手がなければ勝利。

---

## 12. UI設計

### 12.1 画面構成

```text
HomeScreen
├── Quick Play
├── Custom Game
├── Tutorial
└── Settings

GameScreen
├── 上部：相手情報・相手カード
├── 中央：盤面
├── 下部：自分情報・自分カード・操作説明

TutorialScreen
├── 説明テキスト
├── 固定盤面
├── 正解位置ハイライト
└── ヒント表示

ResultScreen
└── 勝敗・再戦・ホームへ戻る
```

### 12.2 盤面描画

Flutterの `CustomPainter` を使う。

```dart
class BoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 盤面の線を描画する。
    // 24個のノードを描画する。
    // コマを描画する。
    // 選択中ノードをハイライトする。
    // legalDestinationsFrom() の結果をハイライトする。
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return true;
  }
}
```

### 12.3 操作方法

#### 配置フェーズ

```text
空き点をタップ → コマ配置
```

#### 移動フェーズ

```text
自分のコマをタップ
  ↓
移動可能点だけハイライト
  ↓
ハイライトされた点をタップ
  ↓
movePiece(from, to) を実行
```

#### 除去フェーズ

```text
除去可能な相手コマをタップ → capturePiece
```

#### カード使用

```text
カードをタップ
  ↓
対象候補をハイライト
  ↓
対象をタップ
  ↓
useCard
```

### 12.4 カードUI

カードは公開情報なので、相手の未使用カードも表示する。

```text
相手カード： [Freeze] [Block] [Jump]

          盤面

自分カード： [Freeze] [Block] [Jump]
```

### 12.5 ビジュアル方針

初期版：

- 木製ボード風
- 白黒のシンプルなコマ
- ミル成立時のみ軽いエフェクト
- カードはアイコン + 名前

将来スキン：

```dart
enum AppSkin {
  classicWood,
  modernDark,
  paper,
}
```

初期実装は `classicWood` のみでよい。

### 12.6 広告スペース

初期版では広告なし。ただし、将来的にAdMobを入れる可能性があるため、画面上部にバナー領域を確保しやすい設計にしておく。

下部は操作と被るため、広告を入れるなら上部推奨。

---

## 13. チュートリアル設計

### 13.1 基本方針

- 固定盤面で始める。
- 指示通りに動かす。
- 正解操作以外では状態を進めない。
- 間違えたらヒントを表示する。
- 文章だけでなく、実際に操作させる。
- 説明文は1〜2文にする。

### 13.2 TutorialStep

```dart
class TutorialStep {
  final GameState initialState;
  final List<Action> allowedActions;
  final List<Action> correctActions;
  final String explanationKey;
  final String hintKey;
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
```

`correctActions` をリストにしている理由：

- Jumpなど、カード使用と移動先選択が複合操作になる場合があるため。
- 将来的な複数手順チュートリアルに対応するため。

### 13.3 TutorialGoal

```dart
enum TutorialGoal {
  formMill,
  capturePiece,
  movePiece,
  useFlying,
  useFreezeCard,
  useBlockCard,
  useJumpCard,
}
```

### 13.4 TutorialPhase

```dart
enum TutorialPhase {
  showingExplanation,
  waitingForAction,
  showingHint,
  completed,
}
```

### 13.5 TutorialState

```dart
class TutorialState {
  final int stepIndex;
  final TutorialPhase phase;
  final TutorialStep currentStep;

  const TutorialState({
    required this.stepIndex,
    required this.phase,
    required this.currentStep,
  });
}
```

### 13.6 チュートリアル構成

1. ミルを作る  
   あと1手でミルになる固定盤面から始める。

2. 相手のコマを取る  
   ミル成立後、相手のコマを1つ選ばせる。

3. 隣接点へ移動する  
   移動フェーズで、自分のコマを隣の点へ動かす。

4. フライングを使う  
   自分のコマが3個の状態で、任意の空き点へ移動させる。

5. Freezeカードを使う  
   相手の重要なコマを1ターン動けなくする。

6. Blockカードを使う  
   相手がミルを作れそうな点を封鎖する。

7. Jumpカードを使う  
   自分のコマを任意の空き点へ移動してミルを狙う。

---

## 14. CPU / AI 設計

### 14.1 難易度

```dart
enum CpuDifficulty {
  easy,
  normal,
  hard,
  nightmare,
}
```

### 14.2 実装方針

| 難易度 | 方針 | 実装状態 |
|---|---|---|
| Easy | 合法手からランダム | 初期実装 |
| Normal | 優先順位ルール | 初期実装 |
| Hard | Minimax + αβ枝刈り | 実装予定 |
| Nightmare | 深い探索 + 高度評価 + カード先読み | 将来候補 |

### 14.3 CpuStrategy

```dart
abstract class CpuStrategy {
  CpuDifficulty get difficulty;

  Action selectAction({
    required GameState state,
    required GameEngine engine,
  });
}
```

### 14.4 Easy

仕様：

- `GameEngine.legalActions()` から取得した合法手の中からランダムに選ぶ。
- UI側やCPU側で独自に非合法手を生成しない。

### 14.5 Normal

優先順位：

1. ミルを作れる手を選ぶ。
2. 相手のミルを防げる手を選ぶ。
3. 駒を取れる状態なら、価値の高いコマを取る。
4. カードを有効に使えるなら使う。
5. 有利な位置を取る。
6. それでも決まらなければランダム。

カード判断：

- Freeze：相手が次にミルを作れそうなコマを止める。
- Block：相手のミル完成地点を封鎖する。
- Jump：自分がミルを作れるときだけ使う。

### 14.6 Hard / Nightmare

初期版では実装しない。

ただし、enumとFactory上の予約枠は用意してよい。

```dart
class CpuStrategyFactory {
  static CpuStrategy create(CpuDifficulty difficulty) {
    switch (difficulty) {
      case CpuDifficulty.easy:
        return EasyCpuStrategy();
      case CpuDifficulty.normal:
        return NormalCpuStrategy();
      case CpuDifficulty.hard:
        return HardCpuStrategyPlaceholder();
      case CpuDifficulty.nightmare:
        return NightmareCpuStrategyPlaceholder();
    }
  }
}
```

初期版ではHard / Nightmareを選んでもNormal相当にフォールバックする。

### 14.7 将来の評価関数案

```text
評価値 =
  駒数差 × 100
+ ミル数差 × 50
+ 潜在ミル差 × 20
+ 合法手数差 × 10
+ 未使用カード数差 × 5
```

---

## 15. 多言語対応

### 15.1 対応言語

- 日本語
- 英語
- スペイン語
- 端末言語に従う system 設定

```dart
enum AppLanguage {
  system,
  japanese,
  english,
  spanish,
}
```

### 15.2 ファイル構成

```text
lib/l10n/
├── app_ja.arb
├── app_en.arb
└── app_es.arb
```

### 15.3 キー命名規則

```text
category.screen.key
```

例：

```json
{
  "home.title": "Nine Men's Morris",
  "home.quickPlay": "クイックプレイ",
  "home.customGame": "カスタムゲーム",
  "home.tutorial": "チュートリアル",

  "game.yourTurn": "あなたの番です",
  "game.opponentTurn": "相手の番です",
  "game.placePiece": "空いている点にコマを置いてください",
  "game.selectPiece": "動かすコマを選んでください",
  "game.selectDestination": "移動先を選んでください",
  "game.capturePiece": "相手のコマを1つ取り除いてください",

  "card.freeze.name": "フリーズ",
  "card.freeze.description": "相手のコマ1つを1ターン動けなくします",
  "card.block.name": "ブロック",
  "card.block.description": "空いている点を1ターン封鎖します",
  "card.jump.name": "ジャンプ",
  "card.jump.description": "自分のコマ1つを任意の空き点へ移動できます"
}
```

注意：

- UIに直接表示文字列を書かない。
- チュートリアル説明も `explanationKey` / `hintKey` で管理する。
- スペイン語は文字列が長くなりやすいため、UIに余白を持たせる。
- RTL対応は初期版では不要。

---

## 16. GameConfig

```dart
class GameConfig {
  final AppMode mode;
  final OpponentType opponentType;
  final VictoryCondition victoryCondition;
  final CpuDifficulty cpuDifficulty;
  final AppLanguage language;
  final Map<LocalRuleId, bool> localRules;

  const GameConfig({
    required this.mode,
    required this.opponentType,
    required this.victoryCondition,
    required this.cpuDifficulty,
    required this.language,
    required this.localRules,
  });

  bool isRuleEnabled(LocalRuleId id) {
    return localRules[id] ?? false;
  }
}
```

### 16.1 Quick設定

```dart
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
```

---

## 17. 実装フェーズ計画

### Phase 1a：Unit Test

最初にテストを書く。

完了条件：

- GameEngineの主要ルールテストが通る。
- 配置、移動、ミル、除去、勝敗判定がテスト済み。

最低限テストすること：

- 24点以外を使わない。
- 配置フェーズで空き点に置ける。
- 配置フェーズでコマがある点に置けない。
- 3つ並ぶとミルになる。
- ミル成立後 `pendingCapture` に入る。
- 相手のミル外コマを優先して除去対象にする。
- 移動フェーズで隣接点にだけ動ける。
- `canFly` がtrueのとき任意の空き点に動ける。
- Freeze中のコマは動けない。
- Block中の点には移動できない。
- Jump使用後に追加移動できない。
- 配置中に2コマ以下でも敗北判定しない。

### Phase 1b：Domain / Engine

実装内容：

- domain層
- engine層
- 標準ナインメンズモリスの基本処理

完了条件：

- ローカル2人対戦がロジック上成立する。
- UIなしでもテストでゲーム進行を確認できる。

### Phase 1c：基本UI + Easy / Normal CPU

実装内容：

- HomeScreen
- GameScreen
- BoardPainter
- タップ操作
- 移動可能点ハイライト
- Easy CPU
- Normal CPU

完了条件：

- CPU相手に1ゲーム最後まで遊べる。

### Phase 2：能力カード

実装内容：

- Freeze
- Block
- Jump
- 同一カードセット配布
- カードUI

完了条件：

- カードありで1ゲーム最後まで遊べる。

### Phase 3：チュートリアル

実装内容：

- 固定盤面
- 7ステップ
- 正解操作判定
- ヒント表示

完了条件：

- 初心者が基本ルールとカード効果を一通り学べる。

### Phase 4：多言語対応

実装内容：

- 日本語
- 英語
- スペイン語
- ARB管理

完了条件：

- UI文字列を3言語で切り替え可能。

### Phase 5：上位AI

実装予定：

- Hard
- Nightmare
- Minimax
- αβ枝刈り
- 評価関数強化

完了条件：

- Normalより明確に強いAIになる。

### Phase 6：オンライン対戦

実装予定：

- FirebaseまたはSupabase
- 部屋作成
- ターン同期
- 切断対応

完了条件：

- 別端末同士で対戦できる。

---

## 18. フォルダ構成案

```text
lib/
├── main.dart
├── domain/
│   ├── node_id.dart
│   ├── player_id.dart
│   ├── piece.dart
│   ├── board.dart
│   ├── game_phase.dart
│   ├── turn_phase.dart
│   ├── player_state.dart
│   ├── game_state.dart
│   ├── action.dart
│   ├── ability_card_id.dart
│   ├── card_target.dart
│   ├── local_rule_id.dart
│   └── game_config.dart
├── engine/
│   ├── game_engine.dart
│   ├── mill_detector.dart
│   ├── rule_modifier.dart
│   └── cpu/
│       ├── cpu_difficulty.dart
│       ├── cpu_strategy.dart
│       ├── easy_cpu_strategy.dart
│       ├── normal_cpu_strategy.dart
│       ├── hard_cpu_strategy_placeholder.dart
│       └── nightmare_cpu_strategy_placeholder.dart
├── ui/
│   ├── home_screen.dart
│   ├── game_screen.dart
│   ├── tutorial_screen.dart
│   ├── result_screen.dart
│   ├── settings_screen.dart
│   ├── board_painter.dart
│   ├── card_hand_view.dart
│   └── game_ui_state.dart
├── tutorial/
│   ├── tutorial_step.dart
│   ├── tutorial_state.dart
│   └── tutorial_steps.dart
└── l10n/
    ├── app_ja.arb
    ├── app_en.arb
    └── app_es.arb

test/
├── game_engine_test.dart
├── mill_detector_test.dart
├── ability_card_test.dart
└── cpu_strategy_test.dart
```

---

## 19. AIエージェントへの基本指示

AIエージェントに実装を依頼する場合、次の文を必ず冒頭に入れる。

```text
このプロジェクトはFlutter/Dart製のナインメンズモリス派生ゲームです。
実装は必ずDESIGN.mdの定義に従ってください。
UIより先に、domain / engine / test を実装してください。
DESIGN.mdにないルールや状態を勝手に追加しないでください。
```

### 19.1 Domain実装依頼例

```text
DESIGN.mdに従って、まず domain 層を実装してください。

対象：
- NodeID
- PlayerID
- Piece
- Board
- GamePhase
- TurnPhase
- PlayerState
- GameState
- Action
- CardTarget
- AbilityCardID
- LocalRuleId
- GameConfig

条件：
- UIは実装しない
- GameEngineはまだ実装しない
- 各クラスにはコメントを付ける
- 表示文字列は直接書かない
```

### 19.2 GameEngine実装依頼例

```text
DESIGN.mdに従って GameEngine を実装してください。

実装対象：
- legalActions()
- legalDestinationsFrom()
- apply()
- formsNewMill()
- removablePieces()
- winner()
- canFly()

条件：
- GameEngineにUI処理を入れない
- selectedNodeなどのUI状態を使わない
- Block中の点は移動先から除外する
- Freeze中の駒は移動不可にする
- pendingCapture中はcapturePieceのみ許可する
```

---

## 20. 禁止事項

以下は必ず守ること。

```text
- DESIGN.mdにないルールを勝手に追加しない。
- 盤面点数は必ず24点に固定する。
- プレイヤーはwhite / blackの2人だけにする。
- 各プレイヤーの通常コマ数は9個にする。
- GameStateにUI状態を混ぜない。
- selectedNode / highlightedNodes は GameUiState に置く。
- pendingCapture中に通常行動やカード使用を許可しない。
- 配置フェーズ中にmovePieceを許可しない。
- 移動フェーズ中にplacePieceを許可しない。
- カードはbeforeActionでのみ使用可能。
- 1ターンにカードは1枚まで。
- Jumpカードは通常行動扱いにし、使用後に追加のmovePieceを許可しない。
- Freeze / Block はカード使用後も通常行動を許可する。
- Hard / Nightmare AIは初期実装しない。
- Hard / NightmareはNormal相当にフォールバックする。
- オンライン対戦は初期実装しない。
- UI内にルール判定を書かない。
- GameEngine内にFlutter Widgetを書かない。
- 表示文字列をコードに直書きしない。
- deckBuilding と randomCardDeal を同時ONにしない。
- abilityCards がfalseのとき、freeze / block / jump を使用可能にしない。
```

---

## 21. 未確定事項

現時点で後から決めるもの。

- アプリ名
- 正式な盤面座標の割り当て
- 各NodeIDの隣接関係
- ミルを構成する全ライン一覧
- Normal CPUの具体的な位置評価点
- チュートリアル各ステップの具体盤面
- UIの最終デザイン
- AdMob導入の有無
- Firebase / Supabase のどちらを使うか

---

## 22. 次に実施する作業

次にやるべきことは、Phase 1aのUnit Testからである。

優先順：

1. NodeID 24点の定義
2. 隣接関係の定義
3. ミルラインの定義
4. MillDetectorのテスト
5. GameEngineの配置・移動テスト
6. 勝敗判定テスト
7. Freeze / Block / Jump のテスト

---

*DESIGN.md 初版*
*作成目的：Flutter版ナインメンズモリス派生ゲームの実装仕様書*
