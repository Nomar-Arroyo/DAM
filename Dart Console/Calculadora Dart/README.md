# Calculadora Dart

Calculadora de operaciones aritméticas para terminal, escrita en Dart.

## Funcionalidades

- Menú interactivo con cinco opciones: sumar, restar, multiplicar, dividir y salir.
- Validación de la entrada: si la opción no es válida o el número no es un entero,
  vuelve a preguntar en lugar de romperse.
- Manejo de la división entre cero con una excepción `ArgumentError` y un mensaje
  explicativo, en lugar de dejar que el programa colapse.
- Bucle que se repite hasta que el usuario elige la opción de salir.

## Cómo ejecutarlo

```bash
cd "Calculadora Dart"
dart run bin/calculadora.dart
```

## Notas de implementación

Todo está en un solo archivo, `bin/calculadora.dart`, dividido en cuatro
funciones con una responsabilidad cada una:

| Función | Qué hace |
|---------|----------|
| `main` | Muestra el menú y controla el bucle principal |
| `_leerNumero` | Lee y valida un número entero, reintentando si hace falta |
| `_calcular` | Ejecuta la operación elegida |
| `_simbolo` | Traduce la opción al símbolo que se imprime |

El uso de `int.tryParse` y de `on ArgumentError` evita los dos errores típicos
de este tipo de ejercicios: aceptar basura como número y dividir entre cero.

## Requisitos

- [Dart SDK](https://dart.dev/get-dart) ^3.0.0