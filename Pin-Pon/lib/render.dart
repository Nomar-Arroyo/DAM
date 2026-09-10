// renderer.dart
import 'dart:io';
import 'entities.dart';
import 'game_config.dart';

class Renderer {
  static void dibujar(Pelota pelota, Paleta j1, Paleta j2, int p1, int p2) {
    final buffer = StringBuffer();

    // Código ANSI: Mover cursor al origen (1,1) sin borrar toda la memoria
    buffer.write('\x1B[H');

    // Marcador
    buffer.writeln('  Jugador 1: $p1  |  Jugador 2: $p2'.padRight(GameConfig.ancho));
    buffer.writeln('+' + '-' * (GameConfig.ancho - 2) + '+');

    for (int y = 0; y < GameConfig.alto; y++) {
      buffer.write('|'); // Borde izquierdo
      for (int x = 1; x < GameConfig.ancho - 1; x++) {
        if (x == pelota.x && y == pelota.y) {
          buffer.write('O'); // Pelota
        } else if (x == j1.x && y >= j1.y && y < j1.y + j1.alto) {
          buffer.write(']'); // Paleta 1
        } else if (x == j2.x && y >= j2.y && y < j2.y + j2.alto) {
          buffer.write('['); // Paleta 2
        } else if (x == GameConfig.ancho ~/ 2) {
          buffer.write(':'); // Red central
        } else {
          buffer.write(' ');
        }
      }
      buffer.writeln('|'); // Borde derecho
    }

    buffer.writeln('+' + '-' * (GameConfig.ancho - 2) + '+');
    stdout.write(buffer.toString());
  }
}