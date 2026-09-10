# DAM - Desarrollo de Aplicaciones Multiplataforma

Repositorio de actividades realizadas en la materia de DAM del tercer trimestre del ITSU.

## Proyectos

### Calculadora Dart

Aplicación de consola que realiza operaciones aritméticas básicas (suma, resta, multiplicación y división) en el lenguaje Dart.

**Funcionalidades:**
- Menú interactivo con opciones de operación
- Validación de entrada de datos
- Manejo de errores (división entre cero)
- Bucle hasta que el usuario decida salir

**Ejecución:**
```bash
cd "Calculadora Dart"
dart run bin/calculadora.dart
```

---

### Pin-Pon

Juego de Pin-Pon de dos jugadores ejecutado en la terminal, desarrollado con Dart.

**Funcionalidades:**
- Dos jugadores controlan paletas con el teclado (W/S para J1, I/K para J2)
- Pelota con movimiento y rebotes en bordes y paletas
- Sistema de puntaje
- Renderizado en tiempo real usando códigos ANSI

**Ejecución:**
```bash
cd Pin-Pon
dart run bin/pin_pon.dart
```

**Controles:**
| Tecla | Acción |
|-------|--------|
| W | Mover paleta J1 arriba |
| S | Mover paleta J1 abajo |
| I | Mover paleta J2 arriba |
| K | Mover paleta J2 abajo |
| Q | Salir del juego |

## Requisitos

- [Dart SDK](https://dart.dev/get-dart) ^3.0.0
