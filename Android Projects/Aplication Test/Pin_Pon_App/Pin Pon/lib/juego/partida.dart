// partida.dart
//
// Lógica pura de una partida de Pin-Pon, extraída del bucle de la versión
// de consola (Dart Console/Pin-Pon/bin/pin_pon.dart) sin dependencias de
// terminal ni de temporizadores. La interfaz Flutter es responsable de
// llamar a [Partida.tick()] periódicamente (cada GameConfig.frameRate) y
// de dibujar el estado que esta clase expone.

import 'dart:math' as math;

import 'ai.dart';
import 'entities.dart';
import 'game_config.dart';

/// Resultado de la última acción de la partida, para que la interfaz sepa
/// qué mostrar (punto, fin de partida, etc.).
enum EventoPartida {
  /// No ha ocurrido nada especial en este frame.
  ninguno,

  /// Alguien ha anotado un punto.
  punto,

  /// La partida ha terminado (victoria o reto completado).
  fin,
}

/// Estado y reglas de una partida de Pin-Pon.
///
/// No maneja temporizadores ni dibujo: solo la pelota, las paletas, el
/// marcador y las reglas. La interfaz llama a [moverJ1Arriba] /
/// [moverJ1Abajo] (y equivalents del J2) cuando el jugador interactúa, y
/// a [tick] cada frame para avanzar la simulación.
class Partida {
  /// Configuración de la dificultad activa.
  final ConfigDificultad config;

  /// Modo en el que se juega esta partida.
  final ModoJuego modo;

  /// Reto asociado, solo si `modo == ModoJuego.reto`.
  final Reto? reto;

  /// Nombre del Jugador 1 (izquierda). Por defecto "Jugador 1".
  final String nombreJ1;

  /// Nombre del Jugador 2 (derecha). En contra-IA se usa "IA".
  final String nombreJ2;

  Partida({
    required this.config,
    required this.modo,
    this.reto,
    String? nombreJ1,
    String? nombreJ2,
  })  : nombreJ1 = (nombreJ1 == null || nombreJ1.trim().isEmpty)
            ? 'Jugador 1'
            : nombreJ1.trim(),
        nombreJ2 = (nombreJ2 == null || nombreJ2.trim().isEmpty)
            ? (modo == ModoJuego.contraIA ? 'IA' : 'Jugador 2')
            : nombreJ2.trim() {
    reiniciar();
  }

  /// IA que controla la paleta derecha en contra-IA y retos.
  final IA _ia = IA();

  /// Pelota en juego.
  late Pelota pelota;

  /// Paleta izquierda (Jugador 1 o persona).
  late Paleta j1;

  /// Paleta derecha (Jugador 2 o IA).
  late Paleta j2;

  /// Puntos del Jugador 1.
  int p1 = 0;

  /// Puntos del Jugador 2 / IA.
  int p2 = 0;

  /// Tiempo transcurrido desde el inicio, en milisegundos.
  int tiempoMs = 0;

  /// `true` mientras la partida sigue en curso (ni pausada ni terminada).
  bool activa = false;

  /// `true` si el juego está en pausa (el bucle no avanza).
  bool pausada = false;

  /// Mensaje final mostrado al terminar la partida.
  String mensajeFinal = '';

  /// `true` si el reto se completó con éxito (solo en modo reto).
  bool retoCompletado = false;

  /// Inicia (o reinicia) la partida desde cero.
  void reiniciar() {
    p1 = 0;
    p2 = 0;
    tiempoMs = 0;
    pausada = false;
    retoCompletado = false;
    mensajeFinal = '';
    activa = true;

    final mitad = GameConfig.alto ~/ 2;
    pelota = Pelota(
      x: GameConfig.ancho / 2,
      y: GameConfig.alto / 2,
      velocidad: config.velocidadInicial,
    );
    j1 = Paleta(
      x: 2,
      y: mitad - config.tamanoPaleta ~/ 2,
      alto: config.tamanoPaleta,
    );
    j2 = Paleta(
      x: GameConfig.ancho - 3,
      y: mitad - config.tamanoPaleta ~/ 2,
      alto: config.tamanoPaleta,
    );
  }

  /// Pausa o despausa la partida.
  void alternarPausa() {
    if (activa) {
      pausada = !pausada;
    }
  }

  /// Detiene la partida sin marcador final (por ejemplo, al salir).
  void detener() {
    activa = false;
    pausada = false;
  }

  // ── Movimiento de paletas (llamado desde la interfaz) ──────────────

  /// Mueve la paleta del Jugador 1 hacia arriba.
  void moverJ1Arriba() {
    if (!activa || pausada) return;
    j1.moverArriba(pasos: config.velocidadPaleta);
  }

  /// Mueve la paleta del Jugador 1 hacia abajo.
  void moverJ1Abajo() {
    if (!activa || pausada) return;
    j1.moverAbajo(pasos: config.velocidadPaleta, limiteInferior: GameConfig.alto);
  }

  /// Mueve la paleta del Jugador 2 hacia arriba (solo en dos jugadores).
  void moverJ2Arriba() {
    if (!activa || pausada) return;
    if (modo != ModoJuego.dosJugadores) return;
    j2.moverArriba(pasos: config.velocidadPaleta);
  }

  /// Mueve la paleta del Jugador 2 hacia abajo (solo en dos jugadores).
  void moverJ2Abajo() {
    if (!activa || pausada) return;
    if (modo != ModoJuego.dosJugadores) return;
    j2.moverAbajo(pasos: config.velocidadPaleta, limiteInferior: GameConfig.alto);
  }

  /// Coloca la paleta del Jugador 1 con el centro en la fila [yCentro]
  /// (usado por el control táctil por arrastre).
  void moverJ1A(double yCentro) {
    if (!activa || pausada) return;
    j1.y = (yCentro - j1.alto / 2).round().clamp(1, GameConfig.alto - 1 - j1.alto);
  }

  /// Coloca la paleta del Jugador 2 con el centro en la fila [yCentro]
  /// (control táctil del segundo jugador o solo en dos jugadores).
  void moverJ2A(double yCentro) {
    if (!activa || pausada) return;
    if (modo != ModoJuego.dosJugadores) return;
    j2.y = (yCentro - j2.alto / 2).round().clamp(1, GameConfig.alto - 1 - j2.alto);
  }

  // ── Bucle de juego ─────────────────────────────────────────────────

  /// Avanza la simulación un frame. Devuelve el evento ocurrido.
  ///
  /// La interfaz debe llamar a este método cada [GameConfig.frameRate]
  /// (40 ms) mientras la partida esté activa.
  EventoPartida tick() {
    if (!activa || pausada) return EventoPartida.ninguno;

    tiempoMs += GameConfig.frameRate.inMilliseconds;

    _moverPaletasAutomaticas();
    pelota.mover();
    _rebotesYColisiones();

    final puntoAnotado = _verificarPuntos();
    if (puntoAnotado) {
      final fin = _verificarFinPartida();
      return fin ? EventoPartida.fin : EventoPartida.punto;
    }
    return EventoPartida.ninguno;
  }

  /// En modo contra-IA o reto, la IA mueve su paleta cada frame.
  /// En dos jugadores no hay movimiento automático.
  void _moverPaletasAutomaticas() {
    if (modo == ModoJuego.dosJugadores) return;
    _ia.mover(j2, pelota, config);
  }

  /// Rebotes contra techo, suelo y paletas. Devuelve `true` si ha habido
  /// colisión con alguna paleta.
  bool _rebotesYColisiones() {
    var huboColision = false;

    if (pelota.y <= 0) {
      pelota.y = 0;
      pelota.rebotarY();
    }
    if (pelota.y >= GameConfig.alto - 1) {
      pelota.y = GameConfig.alto - 1;
      pelota.rebotarY();
    }

    if (pelota.dx < 0 && pelota.x <= j1.x + 1 && _dentroRango(pelota.y, j1)) {
      pelota.x = j1.x + 1;
      pelota.rebotarX();
      huboColision = true;
    }
    if (pelota.dx > 0 && pelota.x >= j2.x - 1 && _dentroRango(pelota.y, j2)) {
      pelota.x = j2.x - 1;
      pelota.rebotarX();
      huboColision = true;
    }
    return huboColision;
  }

  /// `true` si la fila [y] está dentro del rango vertical de la [paleta].
  bool _dentroRango(double y, Paleta paleta) =>
      y >= paleta.y && y < paleta.y + paleta.alto;

  /// Comprueba si la pelota ha salido por algún lateral y, en caso
  /// afirmativo, suma el punto, reinicia la pelota y acelera el juego.
  /// Devuelve `true` si se ha anotado.
  bool _verificarPuntos() {
    if (pelota.x <= j1.x) {
      p2++;
      _registrarPunto();
      return true;
    }
    if (pelota.x >= j2.x) {
      p1++;
      _registrarPunto();
      return true;
    }
    return false;
  }

  /// Aplica la aceleración progresiva y devuelve la pelota al centro.
  void _registrarPunto() {
    final puntos = p1 + p2;
    final base =
        config.velocidadInicial + puntos * GameConfig.incrementoVelocidadPorPunto;
    pelota.velocidad = math.min(config.velocidadMaxima, base);
    pelota.reiniciar(GameConfig.ancho / 2, GameConfig.alto / 2);
  }

  /// Comprueba si la partida debe terminar (victoria o reto completado).
  /// Devuelve `true` si ha terminado.
  bool _verificarFinPartida() {
    if (modo == ModoJuego.reto) {
      final r = reto!;
      if (r.tiempoSegundos > 0) {
        if (tiempoMs >= r.tiempoSegundos * 1000) {
          mensajeFinal =
              'Reto "${r.nombre}" completado. Sobreviviste ${r.tiempoSegundos} segundos.';
          retoCompletado = true;
          detener();
          return true;
        }
      } else if (p1 >= r.objetivo) {
        mensajeFinal =
            'Reto "${r.nombre}" completado. Anotaste $p1 puntos.';
        retoCompletado = true;
        detener();
        return true;
      }
      return false;
    }

    if (p1 >= GameConfig.puntosParaGanar) {
      mensajeFinal = 'Victoria de $nombreJ1. Marcador final: $p1 - $p2';
      detener();
      return true;
    }
    if (p2 >= GameConfig.puntosParaGanar) {
      mensajeFinal = 'Victoria de $nombreJ2. Marcador final: $p1 - $p2';
      detener();
      return true;
    }
    return false;
  }

  /// Descripción legible del modo y el reto, para mostrar en la interfaz.
  String get descripcion {
    if (modo == ModoJuego.reto && reto != null) {
      return 'Reto: ${reto!.nombre}';
    }
    switch (modo) {
      case ModoJuego.dosJugadores:
        return 'Dos jugadores';
      case ModoJuego.contraIA:
        return 'Contra la IA';
      case ModoJuego.reto:
        return 'Reto';
    }
  }

  /// Progreso del reto en modo tiempo (segundos transcurridos / objetivo).
  /// En modo puntos, devuelve los puntos del J1 / objetivo.
  String get progresoReto {
    if (modo != ModoJuego.reto || reto == null) return '';
    final r = reto!;
    if (r.tiempoSegundos > 0) {
      final seg = (tiempoMs / 1000).clamp(0, r.tiempoSegundos);
      return '${seg.toStringAsFixed(0)} / ${r.tiempoSegundos} s';
    }
    return '$p1 / ${r.objetivo} pts';
  }
}
