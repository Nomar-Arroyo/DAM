// render.dart
import 'dart:io';

import 'entities.dart';
import 'game_config.dart';

class Renderer {
  static const String _reset = '\x1B[0m';
  static const String _negrita = '\x1B[1m';
  static const String _cian = '\x1B[96m';
  static const String _verde = '\x1B[92m';
  static const String _rojo = '\x1B[91m';
  static const String _amarillo = '\x1B[93m';
  static const String _gris = '\x1B[90m';

  static void ocultarCursor() => stdout.write('\x1B[?25l');
  static void mostrarCursor() => stdout.write('\x1B[?25h');
  static void limpiarPantalla() => stdout.write('\x1B[2J\x1B[H');
  static void inicioPantalla() => stdout.write('\x1B[H');

  static String titulo(String texto) => ' $_negrita$_cian$texto$_reset';
  static String resaltar(String texto) => ' $_negrita$texto$_reset';
  static String verde(String texto) => '$_verde$texto$_reset';
  static String rojo(String texto) => '$_rojo$texto$_reset';
  static String amarillo(String texto) => '$_amarillo$texto$_reset';
  static String gris(String texto) => '$_gris$texto$_reset';

  static void dibujar({
    required Pelota pelota,
    required Paleta j1,
    required Paleta j2,
    required int p1,
    required int p2,
    required String encabezado,
  }) {
    final buffer = StringBuffer();
    buffer.write('\x1B[H');
    buffer.writeln(encabezado.padRight(GameConfig.ancho));
    buffer.writeln('+${'-' * (GameConfig.ancho - 2)}+');

    final px = pelota.xEntero;
    final py = pelota.yEntero;

    for (int y = 0; y < GameConfig.alto; y++) {
      buffer.write('|');
      for (int x = 1; x < GameConfig.ancho - 1; x++) {
        if (x == px && y == py) {
          buffer.write('${_amarillo}O$_reset');
        } else if (x == j1.x && y >= j1.y && y < j1.y + j1.alto) {
          buffer.write('${_verde}H$_reset');
        } else if (x == j2.x && y >= j2.y && y < j2.y + j2.alto) {
          buffer.write('${_rojo}H$_reset');
        } else if (x == GameConfig.ancho ~/ 2) {
          buffer.write(':');
        } else {
          buffer.write(' ');
        }
      }
      buffer.writeln('|');
    }

    buffer.writeln('+${'-' * (GameConfig.ancho - 2)}+');
    stdout.write(buffer.toString());
  }
}