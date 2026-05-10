import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nine_mens_morris_variant/main.dart';

void main() {
  testWidgets('home screen shows primary navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NineMensMorrisApp());

    expect(find.text('Quick Play'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('home screen can switch language', (WidgetTester tester) async {
    await tester.pumpWidget(const NineMensMorrisApp());

    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Español').last);
    await tester.pumpAndSettle();

    expect(find.text('Partida rápida'), findsOneWidget);
  });

  testWidgets('custom game screen exposes opponent and rule settings', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NineMensMorrisApp());

    await tester.tap(find.text('Custom Game'));
    await tester.pumpAndSettle();

    expect(find.text('Opponent'), findsOneWidget);
    expect(find.text('Local 2 Players'), findsOneWidget);
    expect(find.text('CPU Difficulty'), findsWidgets);
    expect(find.text('Ability Cards'), findsOneWidget);
  });

  testWidgets('tutorial screen starts with an interactive fixed-board lesson', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NineMensMorrisApp());

    await tester.tap(find.text('Tutorial'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 7'), findsOneWidget);
    expect(find.text('Try it'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('game board keeps usable size on a narrow mobile web viewport', (
    WidgetTester tester,
  ) async {
    // スマホWebに近い狭い表示領域を作り、縦幅不足で盤面が押し潰されないことを確認する。
    await tester.binding.setSurfaceSize(const Size(390, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const NineMensMorrisApp());

    await tester.tap(find.text('Quick Play'));
    await tester.pumpAndSettle();

    // ゲーム画面には広告用のCustomPaintが増えてもよいので、最大サイズのCustomPaintを盤面として扱う。
    final boardSize = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => tester.getSize(find.byWidget(paint)))
        .reduce((largest, current) {
          return current.width * current.height > largest.width * largest.height
              ? current
              : largest;
        });

    // 390px幅のスマホでは、余白込みでも300px以上の正方形盤面を確保する。
    expect(boardSize.width, greaterThanOrEqualTo(300));
    expect(boardSize.height, greaterThanOrEqualTo(300));
  });
}
