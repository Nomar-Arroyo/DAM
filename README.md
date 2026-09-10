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

Juego de Pin-Pon ejecutado en la terminal, desarrollado con Dart (versión 1.1.0).

**Funcionalidades:**
- Menú inicial con modos de juego: dos jugadores, contra la IA y Retos
- Selección de dificultad (Fácil, Medio, Difícil)
- Velocidad de la pelota progresiva según el puntaje
- Movimiento fluido de las paletas
- 4 retos desbloqueables
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
| P | Pausar partida |
| Q | Salir del juego |

## Requisitos

- [Dart SDK](https://dart.dev/get-dart) ^3.0.0
