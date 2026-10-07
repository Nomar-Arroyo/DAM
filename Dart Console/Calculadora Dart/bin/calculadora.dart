import 'dart:io';

void main() {
  stdout.writeln('=== CALCULADORA DE OPERACIONES ARITMETICAS ===');
  stdout.writeln('Opciones disponibles:');
  stdout.writeln('  1. Sumar (+)');
  stdout.writeln('  2. Restar (-)');
  stdout.writeln('  3. Multiplicar (*)');
  stdout.writeln('  4. Dividir (/)');
  stdout.writeln('  5. Salir');
  stdout.writeln('');

  while (true) {
    stdout.write('Elige una opcion (1-5): ');
    final opcion = stdin.readLineSync();

    if (opcion == '5') {
      stdout.writeln('Gracias por usar la calculadora. Hasta luego!');
      break;
    }

    if (opcion == null ||
        opcion.trim() != '1' &&
            opcion.trim() != '2' &&
            opcion.trim() != '3' &&
            opcion.trim() != '4') {
      stdout.writeln('Opcion invalida. Intenta de nuevo.\n');
      continue;
    }

    final numero1 = _leerNumero('Ingresa el primer numero: ');
    final numero2 = _leerNumero('Ingresa el segundo numero: ');

    try {
      final resultado = _calcular(opcion, numero1, numero2);
      final simbolo = _simbolo(opcion);
      stdout.writeln('Resultado: $numero1 $simbolo $numero2 = $resultado\n');
    } on ArgumentError catch (e) {
      stdout.writeln('Error: ${e.message}\n');
    }
  }
}

int _leerNumero(String mensaje) {
  while (true) {
    stdout.write(mensaje);
    final valor = stdin.readLineSync();
    final numero = int.tryParse(valor ?? '');
    if (numero != null) {
      return numero;
    }
    stdout.writeln('Entrada invalida. Debes ingresar un numero entero.\n');
  }
}

int _calcular(String opcion, int a, int b) {
  switch (opcion.trim()) {
    case '1':
      return a + b;
    case '2':
      return a - b;
    case '3':
      return a * b;
    case '4':
      if (b == 0) {
        throw ArgumentError('No se puede dividir entre cero.');
      }
      return a ~/ b;
    default:
      throw ArgumentError('Operacion no soportada.');
  }
}

String _simbolo(String opcion) {
  switch (opcion.trim()) {
    case '1':
      return '+';
    case '2':
      return '-';
    case '3':
      return '*';
    case '4':
      return '/';
    default:
      return '?';
  }
}
