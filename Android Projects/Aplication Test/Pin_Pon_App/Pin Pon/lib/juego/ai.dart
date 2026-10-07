// ai.dart
//
// Inteligencia artificial que controla la paleta derecha en el modo
// contra la IA y en los retos. Migrada desde la versión de consola
// (Dart Console/Pin-Pon/lib/ai.dart) sin cambios de lógica.

import 'dart:math' as math;

import 'entities.dart';
import 'game_config.dart';

/// IA de Pin-Pon.
///
/// Funciona igual que en la consola: cada frame, si la pelota viaja hacia
/// su lado del campo, calcula a qué altura debe estar su paleta y se
/// acerca un número de celdas igual a `ConfigDificultad.velocidadIA`.
/// Para no ser perfecta, añade una desviación aleatoria proporcional a
/// `ConfigDificultad.margenErrorIA`.
class IA {
  /// Generador de números aleatorios para el margen de error.
  final math.Random _azar = math.Random();

  /// Mueve la paleta de la IA un frame hacia donde debe estar la pelota.
  ///
  /// [paleta] es la paleta que controla la IA (la derecha).
  /// [pelota] es la pelota actual.
  /// [config] son los parámetros de la dificultad activa.
  void mover(Paleta paleta, Pelota pelota, ConfigDificultad config) {
    // Umbral de reacción: la IA solo empieza a moverse cuando la pelota
    // supera cierta distancia hacia su lado. En fácil reacciona "de lejos";
    // en difícil, solo cuando ya está muy cerca.
    final umbral = GameConfig.ancho * config.umbralReaccionIA;
    if (pelota.dx <= 0 || pelota.x < umbral) {
      return;
    }

    // Centro vertical de la paleta y objetivo al que quiere llegar
    // (posición de la pelota más un desvío aleatorio).
    final centro = paleta.y + paleta.alto / 2;
    final objetivo = pelota.y + _desviacion(config.margenErrorIA);

    // Se acerca al objetivo con un margen de ±0.5 para no "temblar".
    if (objetivo < centro - 0.5) {
      paleta.moverArriba(pasos: config.velocidadIA);
    } else if (objetivo > centro + 0.5) {
      paleta.moverAbajo(pasos: config.velocidadIA, limiteInferior: GameConfig.alto);
    }
  }

  /// Genera un desvío aleatorio en el rango `[-margen, +margen]`.
  ///
  /// Si `margen` es 0 (dificultad difícil), devuelve 0: la IA es perfecta.
  double _desviacion(double margen) {
    if (margen <= 0) {
      return 0;
    }
    return _azar.nextDouble() * margen * 2 - margen;
  }
}
