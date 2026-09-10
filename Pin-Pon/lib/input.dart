// input.dart
import 'dart:io';

void configurarTeclado(Function(String) onTecla) {
  // Desactiva el modo de línea y el eco en pantalla
  try {
    stdin.lineMode = false;
    stdin.echoMode = false;
  } on StdinException {
    // Terminal no soporta cambio de modo
  }

  stdin.listen((List<int> codigos) {
    for (var code in codigos) {
      final char = String.fromCharCode(code).toLowerCase();
      onTecla(char);
    }
  });
}