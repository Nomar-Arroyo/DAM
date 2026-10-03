# DAM - Desarrollo de Aplicaciones Multiplataforma

Repositorio de las actividades realizadas en la materia de DAM del tercer
trimestre del ITSU.

## Proyectos

| Proyecto | Tecnología | Descripción |
|----------|-----------|-------------|
| [Calculadora Dart](Calculadora%20Dart/) | Dart (consola) | Calculadora aritmética con menú, validación de entrada y control de errores |
| [Pin-Pon](Pin-Pon/) | Dart (consola) | Juego de pin pon con IA, dificultades, retos y velocidad progresiva |
| [2 Pantallas](Android%20Projects/2%20Pantallas/) | Android, Jetpack Compose | Navegación entre dos pantallas usando estado y callbacks |
| [3 en raya](Android%20Projects/Aplication%20Test/3%20en%20raya/) | Flutter (multiplataforma) | Tres en Raya contra la máquina o en dos jugadores, con Minimax |

---

### Calculadora Dart

Aplicación de consola que realiza operaciones aritméticas básicas (suma, resta,
multiplicación y división).

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

---

### 2 Pantallas

App Android con Jetpack Compose que muestra dos pantallas y navega entre ellas
mediante una variable de estado y un callback por pantalla.

**Funcionalidades:**
- Estado local con `remember` y `mutableStateOf`
- Cada pantalla declara su callback en lugar de modificar el estado directamente
- Material 3 con `enableEdgeToEdge()`
- Vista previa en Android Studio

**Abrir:** abrir la carpeta en Android Studio y pulsar **Run**.

---

### 3 en raya

Juego de Tres en Raya multiplataforma hecho con Flutter, con interfaz
personalizada, animaciones y una IA que juega usando el algoritmo Minimax.

**Funcionalidades:**
- Dos modos: contra la máquina y dos jugadores en el mismo dispositivo
- Tres dificultades: **Fácil** (aleatoria), **Normal** (se equivoca a veces) e
  **Imposible** (Minimax, nunca pierde)
- Opción de jugar con **X** u **O**; si eliges la O, la máquina pone la X y abre
  la partida
- Puntos, rachas y bonus por rapidez, con desglose de cada partida
- Botones de deshacer, nueva partida y reiniciar marcador
- Animaciones implícitas y soporte de lectores de pantalla

**Ejecución:**
```bash
cd "Android Projects/Aplication Test/3 en raya"
flutter pub get
flutter run
```

**Plataformas:** Android, Web, Windows y iOS (este último requiere macOS).

## Requisitos

- [Dart SDK](https://dart.dev/get-dart) ^3.0.0 para los proyectos de consola
- [Flutter](https://docs.flutter.dev/get-started/install) para los proyectos de
  Android, web y escritorio
- Android Studio para el proyecto de Jetpack Compose

## Estructura

```
DAM/
├── Calculadora Dart/           Consola, un solo archivo
├── Pin-Pon/                    Consola, código dividido por módulos
├── Android Projects/
│   ├── 2 Pantallas/            Android nativo con Compose
│   └── Aplication Test/
│       └── 3 en raya/          Flutter multiplataforma
└── Recursos/                   Material de apoyo (no versionado)
```

Cada proyecto tiene su propio `README.md` con el detalle de su implementación.