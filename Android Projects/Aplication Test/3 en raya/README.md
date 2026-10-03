# 3 en raya

Juego de Tres en Raya hecho en Flutter.

## Qué incluye

- Dos modos: **contra la máquina** y **dos jugadores** en el mismo dispositivo.
- Tres dificultades de la máquina:
  - **Fácil**: juega al azar.
  - **Normal**: casi siempre la mejor jugada, pero se equivoca a propósito.
  - **Imposible**: usa Minimax y nunca pierde.
- Opción de jugar **con X o con O**. Si eliges la O, la máquina pone la X y abre
  la partida, como manda el Tres en Raya clásico.
- Marcador de puntos, rachas y bonus por rapidez, con el desglose de cada
  partida ganada.
- Botones **Deshacer**, **Nueva partida** y **Reiniciar marcador**.

## Estructura

Todo el juego está en un único archivo:

- `lib/main.dart`: interfaz, reglas, puntuación e IA (Minimax).

Los tests están repartidos en dos archivos:

- `test/widget_test.dart`: comprobaciones básicas de arranque.
- `test/juego_test.dart`: tests de los cambios de dificultad, reinicio y
  elección de ficha.

## Cómo probarlo

```bash
flutter pub get
flutter test
flutter run
```

> Nota: en los tests no se usa `pumpAndSettle`, porque el controlador que
> anima el pulso de la casilla ganadora se repite en bucle infinito y la
> pantalla nunca queda en reposo. Por eso los tests usan pumps con duración
> fija (`asentar`).

## Nota sobre el nombre

La carpeta del proyecto se llama `3 en raya`, pero el paquete Dart se llama
`tres_en_raya`, porque en Dart los nombres de paquete no admiten espacios ni
pueden empezar por un número.