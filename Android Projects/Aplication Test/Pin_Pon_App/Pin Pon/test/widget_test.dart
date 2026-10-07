// Tests básicos de la interfaz: arranque y navegación del menú principal.
//
// NOTA: en esta app NO se usa pumpAndSettle en la pantalla de partida,
// porque el bucle del juego (Timer.periodic de 40 ms) se repite en bucle
// infinito y el árbol nunca queda en reposo. Los tests de partida usan
// pumps con duración fija.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pin_pon_app/main.dart';

/// Monta la app con una pantalla alta para que los botones quepan.
Future<void> montar(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const PinPonApp());
  await tester.pump();
}

void main() {
  testWidgets('la pantalla de inicio muestra el titulo y los modos',
      (tester) async {
    await montar(tester);

    expect(find.text('PIN-PON'), findsOneWidget);
    expect(find.text('Dos jugadores'), findsOneWidget);
    expect(find.text('Contra la IA'), findsOneWidget);
    expect(find.text('Retos'), findsOneWidget);
  });

  testWidgets('elegir Contra la IA lleva a la pantalla de dificultad',
      (tester) async {
    await montar(tester);

    await tester.tap(find.text('Contra la IA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Elige la dificultad'), findsOneWidget);
    expect(find.text('Fácil'), findsOneWidget);
    expect(find.text('Medio'), findsOneWidget);
    expect(find.text('Difícil'), findsOneWidget);
  });

  testWidgets('elegir Retos muestra la lista de retos', (tester) async {
    await montar(tester);

    await tester.tap(find.text('Retos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Calentamiento'), findsOneWidget);
    expect(find.text('Ritmo'), findsOneWidget);
    expect(find.text('Tanque'), findsOneWidget);
    expect(find.text('Resistencia'), findsOneWidget);
  });

testWidgets('elegir Dos jugadores y una dificultad entra en partida',
      (tester) async {
    await montar(tester);

    // Dos jugadores ahora pide primero los nombres.
    await tester.tap(find.text('Dos jugadores'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Nombre de los jugadores'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Medio'));
    // Pumps fijos: Flame tiene su propio bucle, no se puede pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Debe mostrarse la pantalla de partida con sus instrucciones.
    expect(find.textContaining('Táctil: arrastra'), findsOneWidget);
    expect(find.byTooltip('Salir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el boton de pausa alterna el estado', (tester) async {
    await montar(tester);

    await tester.tap(find.text('Contra la IA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Fácil'));
    // Pumps más largos para que la transición de ruta termine y el
    // AppBar de la pantalla de partida quede visible y tocable.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Buscamos el botón de pausa por su tooltip (más fiable que por icono).
    final pausa = find.byTooltip('Pausa');
    expect(pausa, findsOneWidget);

    await tester.tap(pausa);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    // Tras pausar, el tooltip del mismo botón cambia a "Continuar".
    expect(find.byTooltip('Continuar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
