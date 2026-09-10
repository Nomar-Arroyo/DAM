// input.dart
import 'dart:io';

class Teclado {
  final Map<String, int> _ultimasTeclas = <String, int>{};
  bool _configurado = false;

  void configurar(void Function(String) alTecla) {
    if (_configurado) {
      return;
    }
    _configurado = true;
    try {
      stdin.lineMode = false;
      stdin.echoMode = false;
    } on StdinException {
      // La terminal no soporta cambiar el modo de linea
    }

    stdin.listen((List<int> codigos) {
      final ahora = DateTime.now().millisecondsSinceEpoch;
      for (final codigo in codigos) {
        final tecla = String.fromCharCode(codigo).toLowerCase();
        _ultimasTeclas[tecla] = ahora;
        alTecla(tecla);
      }
    });
  }

  bool reciente(String tecla, int ventanaMs) {
    final instante = _ultimasTeclas[tecla];
    if (instante == null) {
      return false;
    }
    return DateTime.now().millisecondsSinceEpoch - instante < ventanaMs;
  }

  void restaurarModo() {
    try {
      stdin.lineMode = true;
      stdin.echoMode = true;
    } on StdinException {
      // La terminal no soporta cambiar el modo de linea
    }
  }
}