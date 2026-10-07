# Pin-Pon

Juego de Pin-Pon (Pong) hecho en **Flutter + Flame**, migrado desde la
versión de consola en Dart (`Dart Console/Pin-Pon/`).

## Qué incluye

- **Dos jugadores** en el mismo dispositivo. Puedes **registrar los nombres**
  de ambos jugadores antes de empezar.
- **Controles**:
  - Táctil: arrastra el dedo en tu mitad del campo.
  - Teclado: Jugador 1 con **W/S** y Jugador 2 con las **flechas ↑/↓**
    (en Android/iOS se juega íntegramente por pantalla táctil).
  - **P** pausa y **Q** sale de la partida.
- **Contra la IA** con tres dificultades:
  - **Fácil**: paletas grandes, pelota lenta, IA imprecisa.
  - **Medio**: equilibrado.
  - **Difícil**: paletas pequeñas, pelota rápida, IA casi perfecta.
- **Retos**: objetivos puntuales (anotar X puntos o sobrevivir Y segundos).
- **Historial de récords** con dos rankings: **mayor puntaje** y **mayor
  tiempo de partida**. Se guarda en el dispositivo (y en el navegador).
- Velocidad de la pelota ajustada para que sea jugable: la aceleración por
  punto es suave (0.08) y el bucle va a 20 fps.
- Estética **modo oscuro con reflejos neón** (borde del campo, pelota,
  paletas y textos con resplandor).

## Estructura

- `lib/juego/`: lógica pura del juego, sin dependencias de Flame ni Flutter.
  - `entities.dart`: Pelota y Paleta.
  - `game_config.dart`: constantes, dificultades y retos.
  - `ai.dart`: inteligencia artificial de la paleta derecha.
  - `partida.dart`: estado y reglas de una partida (`tick()`, colisiones,
    puntuación, retos, nombres de jugadores).
  - `records.dart`: historial de récords (persistencia con
    `shared_preferences`).
- `lib/flame/`: juego Flame (presentación y bucle).
  - `pin_pon_game.dart`: `PinPonGame` (extiende `FlameGame`) con componentes
    `CampoComponent`, `PelotaComponent`, `PaletaComponent`, `NombresComponent`,
    `MarcadorComponent`, `RetoProgresoComponent` y `PausaComponent`, todos
    con estilo neón. Flame ejecuta el bucle de juego y gestiona el input
    táctil y de teclado.
  - `partida_page.dart`: `PartidaFlamePage`, la página Flutter que aloja el
    `GameWidget` con AspectRatio(2). Muestra el diálogo de fin de partida
    (jugar otra vez / menú principal) y guarda el récord.
- `lib/main.dart`: punto de entrada y pantallas de menú (inicio, nombres,
  dificultad, retos, récords).

Los tests están en tres archivos:

- `test/widget_test.dart`: arranque y navegación del menú.
- `test/juego_test.dart`: lógica de entidades, configuración y partida
  (migrados desde la consola y ampliados).
- `test/records_test.dart`: persistencia del historial de récords.

## Cómo probarlo

```bash
flutter pub get
flutter test
flutter run
```

> Nota: en los tests de la pantalla de partida no se usa `pumpAndSettle`,
> porque Flame mantiene un bucle de renderizado activo y la pantalla nunca
> queda en reposo. Por eso se usan pumps con duración fija.

## Nota sobre el nombre

La carpeta del proyecto se llama `Pin Pon`, pero el paquete Dart se llama
`pin_pon_app`, porque en Dart los nombres de paquete no admiten espacios ni
pueden empezar por un número.