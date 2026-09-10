// input.dart
import 'dart:io';

void configurarTeclado(Function(String) onTecla) {
  // Desactiva el modo de línea y el eco en pantalla
  stdin.lineMode = false;
  stdin.echoMode = false;

  stdin.listen((List<int> codigos) {
    for (var code in codigos) {
      final char = String.fromCharCode(code).toLowerCase();
      onTecla(char);
    }
  });
}