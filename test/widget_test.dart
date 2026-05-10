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
}
