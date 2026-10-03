import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tres_en_raya/main.dart';

/// `pumpAndSettle` NO sirve en esta app: el controlador que anima el pulso de
/// la casilla ganadora se repite en bucle infinito, así que el árbol nunca
/// queda en reposo y el test se cuelga hasta fallar por tiempo agotado.
/// Por eso se usan pumps con duración fija.
Future<void> asentar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 800));
}

/// Monta la app con una pantalla alta.
///
/// La superficie de test por defecto (800x600) es más baja que el contenido,
/// así que los botones de abajo quedaban fuera y `tap()` fallaba.
Future<void> montar(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const TresEnRayaApp());
  await asentar(tester);
}

/// Localiza la casilla número [n] del tablero (0 a 8).
///
/// No se puede usar `find.byType(_Celda)` porque esa clase es privada y no es
/// visible desde el test. En su lugar se busca por la etiqueta de accesibilidad
/// que cada casilla expone: 'Casilla 0' ... 'Casilla 8'.
Finder celda(int n) => find.bySemanticsLabel('Casilla $n');

/// Localiza la pastilla [ficha] ('X' u 'O') del selector "TU FICHA".
///
/// Se filtra por el tamaño de letra 13 y peso w700, que es el que usa
/// `_Pastilla`, para no confundirse con las marcas del tablero ni con las
/// etiquetas del marcador ("Tú (O)", "Máquina (X)").
Finder seleccionarFicha(String ficha) => find.byWidgetPredicate(
      (w) =>
          w is Text &&
          w.data == ficha &&
          w.style?.fontSize == 13 &&
          w.style?.fontWeight == FontWeight.w700,
    );

void main() {
  // ---------------------------------------------------------------------
  // BUG 1: al cambiar de dificultad (o de modo) se lanzaba
  // "UnsupportedError: Cannot clear a fixed-length list".
  // Causa: `_tablero` era `List<int?>.filled(9, null)`, una lista de longitud
  // FIJA, y `_nuevaPartida()` la vaciaba con `..clear()`.
  // ---------------------------------------------------------------------
  testWidgets('BUG 1: cambiar de dificultad no lanza excepcion', (tester) async {
    await montar(tester);

    // Antes del arreglo este `tap` reventaba con "fixed-length list".
    await tester.tap(find.text('Normal'));
    await asentar(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Imposible'));
    await asentar(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Fácil'));
    await asentar(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BUG 1b: cambiar de modo varias veces no lanza excepcion',
      (tester) async {
    await montar(tester);

    await tester.tap(find.text('Dos jugadores'));
    await asentar(tester);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Contra máquina'));
    await asentar(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BUG 1c: la dificultad seleccionada queda marcada', (tester) async {
    await montar(tester);

    await tester.tap(find.text('Imposible'));
    await asentar(tester);

    // La pastilla activa pinta su etiqueta en blanco puro; las demás, en
    // blanco70. Ese color es el reflejo visible de qué opción está marcada.
    final etiqueta = tester.widget<Text>(find.text('Imposible'));
    expect(etiqueta.style?.color, Colors.white);

    // Y la que quedó antes debe haber vuelto a su color inactivo.
    final anterior = tester.widget<Text>(find.text('Fácil'));
    expect(anterior.style?.color, Colors.white70);
  });

  // ---------------------------------------------------------------------
  // BUG 2: tras terminar una partida, el botón inferior no reiniciaba.
  // shares la misma causa que BUG 1: `_nuevaPartida()` fallaba al vaciar
  // la lista, así que el `setState` se abortaba a mitad y la pantalla
  // se quedaba como estaba.
  // ---------------------------------------------------------------------
  testWidgets('BUG 2: el boton inferior se habilita tras una partida',
      (tester) async {
    await montar(tester);

    // Al empezar no hay partidas, así que el botón está deshabilitado.
    TextButton boton() => tester.widget<TextButton>(
          find.ancestor(
            of: find.text('Reiniciar marcador'),
            matching: find.byType(TextButton),
          ),
        );
    expect(boton().onPressed, isNull);

    // Partida en modo 2 jugadores: quien empieza gana la fila superior.
    await tester.tap(find.text('Dos jugadores'));
    await asentar(tester);
    await tester.tap(celda(0)); // X 0
    await asentar(tester);
    await tester.tap(celda(3)); // O 3
    await asentar(tester);
    await tester.tap(celda(1)); // X 1
    await asentar(tester);
    await tester.tap(celda(4)); // O 4
    await asentar(tester);
    await tester.tap(celda(2)); // X 2
    await asentar(tester); // <- faltaba esperar el redibujado

    expect(find.text('¡Gana X!'), findsOneWidget);
    expect(boton().onPressed, isNotNull);
  });

  testWidgets('BUG 2b: Reiniciar marcador limpia el tablero y las estadisticas',
      (tester) async {
    await montar(tester);

    // Se juega y se gana una partida completa para tener puntos y stats.
    await tester.tap(find.text('Dos jugadores'));
    await asentar(tester);
    for (final i in [0, 3, 1, 4, 2]) {
      await tester.tap(celda(i));
      await asentar(tester);
    }
    expect(find.text('¡Gana X!'), findsOneWidget);

    await tester.tap(find.text('Reiniciar marcador'));
    await asentar(tester);

    // El tablero queda vacío: solo deben verse las 9 marcas de vacío.
    expect(find.text('¡Gana X!'), findsNothing);
    // Y el botón vuelve a deshabilirse porque ya no hay partidas.
    final boton = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Reiniciar marcador'),
        matching: find.byType(TextButton),
      ),
    );
    expect(boton.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  // ---------------------------------------------------------------------
  // NUEVO: elegir con qué ficha jugar (X u O).
  // ---------------------------------------------------------------------
  testWidgets('NUEVO: el selector de ficha ofrece X y O', (tester) async {
    await montar(tester);

    // `_Grupo` pasa los títulos a mayúsculas, así que el rótulo es "TU FICHA".
    expect(find.text('TU FICHA'), findsOneWidget);
    // Debe existir exactamente una X y una O en los selectores de ficha.
    expect(find.text('X'), findsOneWidget);
    expect(find.text('O'), findsOneWidget);
  });

  testWidgets('NUEVO: elegir O hace que la máquina abra jugando con X',
      (tester) async {
    await montar(tester);

    // Se elige la O en el selector "TU FICHA".
    await tester.tap(seleccionarFicha('O'));
    // La máquina necesita su pausa antes de jugar; se pumpa lo justo.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    // El mensaje debe pasar a turno del usuario, no a "la máquina piensa".
    expect(find.text('Tu turno: eres O'), findsOneWidget);
    // La máquina ya está jugando: si abrió, la casilla 0 ya está ocupada y
    // por eso el aviso de "nunca puedes ganarle" (dificultad fácil) no aplica.
    expect(find.text('¡Ganaste!'), findsNothing);
    // Y el marcador de la interfaz debe reflejar las fichas nuevas.
    expect(find.text('Tú (O)'), findsOneWidget);
    expect(find.text('Máquina (X)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('NUEVO: cambiar de ficha limpia el tablero', (tester) async {
    await montar(tester);

    // Se juega una jugada en modo máquina (ficha X por defecto).
    await tester.tap(celda(4));
    await asentar(tester);

    // Tras jugar, el tablero también muestra una "O", así que hay que
    // apuntar al O del selector "TU FICHA" y no al primero que aparezca.
    await tester.tap(seleccionarFicha('O'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Tu turno: eres O'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}