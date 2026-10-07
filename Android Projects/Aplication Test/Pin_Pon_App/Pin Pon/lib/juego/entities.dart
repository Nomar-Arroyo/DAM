// entities.dart
//
// Entidades básicas del Pin-Pon: la pelota y las paletas.
// Migradas desde la versión de consola (Dart Console/Pin-Pon/lib/entities.dart)
// sin cambios en la lógica, porque son puro Dart y no dependen de la terminal.

import 'dart:math' as math;

/// La pelota del juego.
///
/// Su posición es en "coordenadas de campo": el tablero mide
/// [GameConfig.ancho] x [GameConfig.alto] celdas (40 x 20), y la pelota
/// se mueve en esas unidades. La pantalla (Flutter) se encarga de
/// escalarlas a píxeles para dibujarlas.
class Pelota {
  /// Posición horizontal en celdas (crece hacia la derecha).
  double x;

  /// Posición vertical en celdas (crece hacia abajo).
  double y;

  /// Dirección horizontal: 1 va a la derecha, -1 a la izquierda.
  /// Invierte en cada rebote contra una paleta.
  int dx;

  /// Dirección vertical: 1 hacia abajo, -1 hacia arriba.
  /// Invierte en cada rebote contra el techo o el suelo.
  int dy;

  /// Velocidad actual en celdas por frame. Empieza según la dificultad
  /// y crece 0.25 por cada punto anotado en la partida (hasta un máximo).
  double velocidad;

  Pelota({
    required this.x,
    required this.y,
    this.dx = 1,
    this.dy = 1,
    this.velocidad = 1.0,
  });

  /// Posición horizontal redondeada a celda entera (para colisiones y dibujo).
  int get xEntero => x.round();

  /// Posición vertical redondeada a celda entera.
  int get yEntero => y.round();

  /// Velocidad vertical derivada de la velocidad horizontal.
  ///
  /// La consola la calculaba así para que la pelota subiera y bajara de
  /// forma moderada: a velocidad 1 sube/baja 1 celda, a velocidad 4 son 2
  /// celdas y a velocidad 6 o más son 3 celdas como máximo.
  int get velocidadVertical =>
      math.max(1, math.min(3, (velocidad * 0.5).round()));

  /// Mueve la pelota un frame según su velocidad y dirección.
  void mover() {
    x += dx * velocidad;
    y += dy * velocidadVertical;
  }

  /// Invierte la dirección vertical (rebote contra techo o suelo).
  void rebotarY() => dy = -dy;

  /// Invierte la dirección horizontal (rebote contra una paleta).
  void rebotarX() => dx = -dx;

  /// Devuelve la pelota al centro del campo y cambia el sentido horizontal
  /// para que sirva desde el lado contrario (tras marcar un punto).
  void reiniciar(double centroX, double centroY) {
    x = centroX;
    y = centroY;
    dx = -dx;
  }
}

/// La paleta de un jugador.
///
/// Ocupa [alto] celdas de vertical y una celda de ancho (la consola dibujaba
/// un solo carácter). La posición vertical [y] es la fila de su borde
/// superior; su rango válido es de 1 a `GameConfig.alto - 1 - alto`.
class Paleta {
  /// Fila del borde superior de la paleta (mutable: se mueve al jugar).
  int y;

  /// Columna fija de la paleta (2 para el Jugador 1, ancho-3 para el 2).
  final int x;

  /// Altura de la paleta en celdas; cambia con la dificultad
  /// (fácil = paleta grande, difícil = paleta pequeña).
  final int alto;

  Paleta({required this.x, required this.y, required this.alto});

  /// Mueve la paleta hacia arriba sin pasar del techo (fila 1).
  void moverArriba({int pasos = 1}) {
    y = math.max(1, y - pasos);
  }

  /// Mueve la paleta hacia abajo sin pasar del suelo del campo.
  ///
  /// [limiteInferior] es el alto total del campo; la paleta se detiene en
  /// `limiteInferior - 1 - alto` para no salirse del tablero.
  void moverAbajo({int pasos = 1, required int limiteInferior}) {
    y = math.min(limiteInferior - 1 - alto, y + pasos);
  }
}
