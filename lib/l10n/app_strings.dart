import 'dart:ui';

import '../domain/app_language.dart';
import '../engine/cpu/cpu_difficulty.dart';

class AppStrings {
  static const supportedLocales = [Locale('ja'), Locale('en'), Locale('es')];

  static AppLanguage _language = AppLanguage.system;
  static Locale _platformLocale = Locale('ja');

  static const _ja = {
    'app.title': 'ナインメンズモリス',
    'home.quickPlay': 'クイックプレイ',
    'home.customGame': 'カスタムゲーム',
    'home.tutorial': 'チュートリアル',
    'home.settings': '設定',
    'home.language': '言語',
    'language.system': 'システム',
    'language.japanese': '日本語',
    'language.english': 'English',
    'language.spanish': 'Español',
    'home.customReserved': 'カスタムゲームは初期版ではクイック設定で開始します。',
    'custom.title': 'カスタムゲーム',
    'custom.opponent': '対戦相手',
    'custom.opponent.cpu': 'CPU',
    'custom.opponent.localHuman': 'ローカル2人',
    'custom.cpuDifficulty': 'CPU難易度',
    'custom.localRules': 'ローカルルール',
    'custom.rule.flying': 'フライング',
    'custom.rule.abilityCards': '能力カード',
    'custom.rule.sameCardSet': '同一カードセット',
    'custom.rule.freezeCard': 'フリーズカード',
    'custom.rule.blockCard': 'ブロックカード',
    'custom.rule.jumpCard': 'ジャンプカード',
    'custom.start': '開始',
    'cpu.easy': 'Easy',
    'cpu.normal': 'Normal',
    'cpu.hard': 'Hard（Normal相当）',
    'cpu.nightmare': 'Nightmare（Normal相当）',
    'game.white': '白',
    'game.black': '黒',
    'game.yourTurn': 'あなたの番です',
    'game.opponentTurn': 'CPUの番です',
    'game.placePiece': '空いている点にコマを置いてください',
    'game.selectPiece': '動かすコマを選んでください',
    'game.selectDestination': '移動先を選んでください',
    'game.capturePiece': '相手のコマを1つ取り除いてください',
    'game.useCardOrContinue': 'カードを使うか、通常行動へ進んでください',
    'game.continue': '通常行動へ',
    'game.home': 'ホーム',
    'game.replay': '再戦',
    'game.winner': '勝者',
    'game.phase.placing': '配置',
    'game.phase.moving': '移動',
    'card.freeze.name': 'フリーズ',
    'card.freeze.description': '相手のコマ1つを1ターン動けなくします',
    'card.block.name': 'ブロック',
    'card.block.description': '空いている点を1ターン封鎖します',
    'card.jump.name': 'ジャンプ',
    'card.jump.description': '自分のコマ1つを任意の空き点へ移動できます',
    'tutorial.title': 'チュートリアル',
    'tutorial.body': '固定盤面で基本操作を練習します。',
    'tutorial.stepCounter': '{current} / {total}',
    'tutorial.try': 'やってみる',
    'tutorial.restart': 'もう一度',
    'tutorial.completed': 'チュートリアル完了です。',
    'tutorial.step.formMill.explanation': '白を右上に置いて、横一列のミルを作ります。',
    'tutorial.step.formMill.hint': '上辺の右端の点を選んでください。',
    'tutorial.step.capture.explanation': 'ミルができたら、相手のコマを1つ取り除けます。',
    'tutorial.step.capture.hint': '左中央の黒いコマを選んでください。',
    'tutorial.step.move.explanation': '移動フェーズでは、自分のコマを隣の空き点へ動かします。',
    'tutorial.step.move.hint': '左上の白いコマを選び、上辺中央へ動かしてください。',
    'tutorial.step.flying.explanation': 'コマが3個になると、空いている好きな点へ移動できます。',
    'tutorial.step.flying.hint': '左上の白いコマを選び、右下の点へ飛ばしてください。',
    'tutorial.step.freeze.explanation': 'Freezeカードは、相手のコマ1つを次のターン動けなくします。',
    'tutorial.step.freeze.hint': 'Freezeカードを選び、上辺中央の黒いコマを選んでください。',
    'tutorial.step.block.explanation': 'Blockカードは、空いている点を一時的に使えなくします。',
    'tutorial.step.block.hint': 'Blockカードを選び、上辺右端の空き点を封鎖してください。',
    'tutorial.step.jump.explanation': 'Jumpカードは、自分のコマを任意の空き点へ移動します。',
    'tutorial.step.jump.hint': 'Jumpカードを選び、中央上の白いコマから上辺右端へ移動してください。',
  };

  static const _en = {
    'app.title': "Nine Men's Morris",
    'home.quickPlay': 'Quick Play',
    'home.customGame': 'Custom Game',
    'home.tutorial': 'Tutorial',
    'home.settings': 'Settings',
    'home.language': 'Language',
    'language.system': 'System',
    'language.japanese': '日本語',
    'language.english': 'English',
    'language.spanish': 'Español',
    'home.customReserved':
        'Custom Game starts with quick settings in this early version.',
    'custom.title': 'Custom Game',
    'custom.opponent': 'Opponent',
    'custom.opponent.cpu': 'CPU',
    'custom.opponent.localHuman': 'Local 2 Players',
    'custom.cpuDifficulty': 'CPU Difficulty',
    'custom.localRules': 'Local Rules',
    'custom.rule.flying': 'Flying',
    'custom.rule.abilityCards': 'Ability Cards',
    'custom.rule.sameCardSet': 'Same Card Set',
    'custom.rule.freezeCard': 'Freeze Card',
    'custom.rule.blockCard': 'Block Card',
    'custom.rule.jumpCard': 'Jump Card',
    'custom.start': 'Start',
    'cpu.easy': 'Easy',
    'cpu.normal': 'Normal',
    'cpu.hard': 'Hard (Normal fallback)',
    'cpu.nightmare': 'Nightmare (Normal fallback)',
    'game.white': 'White',
    'game.black': 'Black',
    'game.yourTurn': 'Your turn',
    'game.opponentTurn': 'CPU turn',
    'game.placePiece': 'Place a piece on an empty point',
    'game.selectPiece': 'Select a piece to move',
    'game.selectDestination': 'Select a destination',
    'game.capturePiece': 'Remove one opponent piece',
    'game.useCardOrContinue': 'Use a card or continue to your normal action',
    'game.continue': 'Continue',
    'game.home': 'Home',
    'game.replay': 'Replay',
    'game.winner': 'Winner',
    'game.phase.placing': 'Placing',
    'game.phase.moving': 'Moving',
    'card.freeze.name': 'Freeze',
    'card.freeze.description': 'Freeze one opponent piece for one turn',
    'card.block.name': 'Block',
    'card.block.description': 'Block an empty point for one turn',
    'card.jump.name': 'Jump',
    'card.jump.description': 'Move one of your pieces to any empty point',
    'tutorial.title': 'Tutorial',
    'tutorial.body': 'Practice the core moves on fixed boards.',
    'tutorial.stepCounter': '{current} / {total}',
    'tutorial.try': 'Try it',
    'tutorial.restart': 'Restart',
    'tutorial.completed': 'Tutorial complete.',
    'tutorial.step.formMill.explanation':
        'Place the white piece on the upper-right point to make a mill.',
    'tutorial.step.formMill.hint': 'Choose the upper-right point.',
    'tutorial.step.capture.explanation':
        'After making a mill, remove one opponent piece.',
    'tutorial.step.capture.hint': 'Choose the black piece on the left middle.',
    'tutorial.step.move.explanation':
        'In the moving phase, move one of your pieces to an adjacent empty point.',
    'tutorial.step.move.hint':
        'Choose the upper-left white piece, then move it to the top center.',
    'tutorial.step.flying.explanation':
        'With three pieces left, you can move to any empty point.',
    'tutorial.step.flying.hint':
        'Choose the upper-left white piece, then fly it to the lower-right point.',
    'tutorial.step.freeze.explanation':
        'Freeze stops one opponent piece from moving on its next turn.',
    'tutorial.step.freeze.hint':
        'Choose Freeze, then choose the black piece at the top center.',
    'tutorial.step.block.explanation':
        'Block temporarily prevents use of an empty point.',
    'tutorial.step.block.hint':
        'Choose Block, then block the upper-right empty point.',
    'tutorial.step.jump.explanation':
        'Jump moves one of your pieces to any empty point.',
    'tutorial.step.jump.hint':
        'Choose Jump, then move the upper-middle white piece to the upper-right point.',
  };

  static const _es = {
    'app.title': "Nine Men's Morris",
    'home.quickPlay': 'Partida rápida',
    'home.customGame': 'Partida personalizada',
    'home.tutorial': 'Tutorial',
    'home.settings': 'Ajustes',
    'home.language': 'Idioma',
    'language.system': 'Sistema',
    'language.japanese': '日本語',
    'language.english': 'English',
    'language.spanish': 'Español',
    'home.customReserved':
        'En esta versión inicial, la partida personalizada empieza con ajustes rápidos.',
    'custom.title': 'Partida personalizada',
    'custom.opponent': 'Rival',
    'custom.opponent.cpu': 'CPU',
    'custom.opponent.localHuman': '2 jugadores locales',
    'custom.cpuDifficulty': 'Dificultad de CPU',
    'custom.localRules': 'Reglas locales',
    'custom.rule.flying': 'Vuelo',
    'custom.rule.abilityCards': 'Cartas de habilidad',
    'custom.rule.sameCardSet': 'Mismo set de cartas',
    'custom.rule.freezeCard': 'Carta Congelar',
    'custom.rule.blockCard': 'Carta Bloquear',
    'custom.rule.jumpCard': 'Carta Saltar',
    'custom.start': 'Empezar',
    'cpu.easy': 'Easy',
    'cpu.normal': 'Normal',
    'cpu.hard': 'Hard (usa Normal)',
    'cpu.nightmare': 'Nightmare (usa Normal)',
    'game.white': 'Blancas',
    'game.black': 'Negras',
    'game.yourTurn': 'Tu turno',
    'game.opponentTurn': 'Turno de la CPU',
    'game.placePiece': 'Coloca una ficha en un punto vacío',
    'game.selectPiece': 'Elige una ficha para mover',
    'game.selectDestination': 'Elige un destino',
    'game.capturePiece': 'Retira una ficha del rival',
    'game.useCardOrContinue': 'Usa una carta o continúa con tu acción normal',
    'game.continue': 'Continuar',
    'game.home': 'Inicio',
    'game.replay': 'Revancha',
    'game.winner': 'Ganador',
    'game.phase.placing': 'Colocación',
    'game.phase.moving': 'Movimiento',
    'card.freeze.name': 'Congelar',
    'card.freeze.description': 'Congela una ficha rival durante un turno',
    'card.block.name': 'Bloquear',
    'card.block.description': 'Bloquea un punto vacío durante un turno',
    'card.jump.name': 'Saltar',
    'card.jump.description': 'Mueve una ficha propia a cualquier punto vacío',
    'tutorial.title': 'Tutorial',
    'tutorial.body': 'Practica los movimientos básicos en tableros fijos.',
    'tutorial.stepCounter': '{current} / {total}',
    'tutorial.try': 'Probar',
    'tutorial.restart': 'Reiniciar',
    'tutorial.completed': 'Tutorial completado.',
    'tutorial.step.formMill.explanation':
        'Coloca la ficha blanca en el punto superior derecho para formar un molino.',
    'tutorial.step.formMill.hint': 'Elige el punto superior derecho.',
    'tutorial.step.capture.explanation':
        'Después de formar un molino, retira una ficha rival.',
    'tutorial.step.capture.hint':
        'Elige la ficha negra de la izquierda central.',
    'tutorial.step.move.explanation':
        'En la fase de movimiento, mueve una ficha a un punto vecino vacío.',
    'tutorial.step.move.hint':
        'Elige la ficha blanca superior izquierda y muévela al centro superior.',
    'tutorial.step.flying.explanation':
        'Con tres fichas, puedes moverte a cualquier punto vacío.',
    'tutorial.step.flying.hint':
        'Elige la ficha blanca superior izquierda y vuela al punto inferior derecho.',
    'tutorial.step.freeze.explanation':
        'Freeze impide que una ficha rival se mueva en su siguiente turno.',
    'tutorial.step.freeze.hint':
        'Elige Freeze y luego la ficha negra del centro superior.',
    'tutorial.step.block.explanation':
        'Block impide temporalmente usar un punto vacío.',
    'tutorial.step.block.hint':
        'Elige Block y bloquea el punto superior derecho vacío.',
    'tutorial.step.jump.explanation':
        'Jump mueve una de tus fichas a cualquier punto vacío.',
    'tutorial.step.jump.hint':
        'Elige Jump y mueve la ficha blanca superior central al punto superior derecho.',
  };

  static AppLanguage get language => _language;

  static Locale? get appLocale {
    return switch (_language) {
      AppLanguage.system => null,
      AppLanguage.japanese => const Locale('ja'),
      AppLanguage.english => const Locale('en'),
      AppLanguage.spanish => const Locale('es'),
    };
  }

  static Locale get resolvedLocale => switch (_language) {
    AppLanguage.system => _supportedLocaleFor(_platformLocale),
    AppLanguage.japanese => const Locale('ja'),
    AppLanguage.english => const Locale('en'),
    AppLanguage.spanish => const Locale('es'),
  };

  static void setLanguage(AppLanguage language) {
    _language = language;
  }

  static void setPlatformLocale(Locale locale) {
    _platformLocale = locale;
  }

  static String t(String key) {
    final primary = _valuesFor(resolvedLocale.languageCode);
    return primary[key] ?? _ja[key] ?? _en[key] ?? key;
  }

  static String languageName(AppLanguage language) {
    return switch (language) {
      AppLanguage.system => t('language.system'),
      AppLanguage.japanese => t('language.japanese'),
      AppLanguage.english => t('language.english'),
      AppLanguage.spanish => t('language.spanish'),
    };
  }

  static String cpuDifficultyName(CpuDifficulty difficulty) {
    return switch (difficulty) {
      CpuDifficulty.easy => t('cpu.easy'),
      CpuDifficulty.normal => t('cpu.normal'),
      CpuDifficulty.hard => t('cpu.hard'),
      CpuDifficulty.nightmare => t('cpu.nightmare'),
    };
  }

  static Locale _supportedLocaleFor(Locale locale) {
    return switch (locale.languageCode) {
      'en' => const Locale('en'),
      'es' => const Locale('es'),
      _ => const Locale('ja'),
    };
  }

  static Map<String, String> _valuesFor(String languageCode) {
    return switch (languageCode) {
      'en' => _en,
      'es' => _es,
      _ => _ja,
    };
  }
}
