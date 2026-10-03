import 'package:flutter_test/flutter_test.dart';

import 'package:tres_en_raya/main.dart';

void main() {
  testWidgets('muestra el tablero vacio y el marcador en cero',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TresEnRayaApp());

    expect(find.text('Tres en Raya'), findsOneWidget);
    expect(find.text('Tu turno: eres X'), findsOneWidget);
    expect(find.text('Nueva partida'), findsOneWidget);
  });

  testWidgets('ofrece los tres niveles de dificultad',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TresEnRayaApp());

    expect(find.text('Fácil'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Imposible'), findsOneWidget);
  });

  testWidgets('permite volver a una partida nueva', (tester) async {
    await tester.pumpWidget(const TresEnRayaApp());

    await tester.tap(find.text('Nueva partida'));
    await tester.pump();

    expect(find.text('Tu turno: eres X'), findsOneWidget);
  });
}