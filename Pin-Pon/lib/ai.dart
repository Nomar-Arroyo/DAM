// ai.dart
import 'dart:math' as math;

import 'entities.dart';
import 'game_config.dart';

class IA {
  final math.Random _azar = math.Random();

  void mover(Paleta paleta, Pelota pelota, ConfigDificultad config) {
    final umbral = GameConfig.ancho * config.umbralReaccionIA;
    if (pelota.dx <= 0 || pelota.x < umbral) {
      return;
    }

    final centro = paleta.y + paleta.alto / 2;
    final objetivo = pelota.y + _desviacion(config.margenErrorIA);

    if (objetivo < centro - 0.5) {
      paleta.moverArriba(pasos: config.velocidadIA);
    } else if (objetivo > centro + 0.5) {
      paleta.moverAbajo(pasos: config.velocidadIA, limiteInferior: GameConfig.alto);
    }
  }

  double _desviacion(double margen) {
    if (margen <= 0) {
      return 0;
    }
    return _azar.nextDouble() * margen * 2 - margen;
  }
}