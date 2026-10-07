// Tests de lógica pura del Pin-Pon, migrados desde la versión de consola
// (Dart Console/Pin-Pon/test/pin_pon_test.dart) y ampliados con tests de
// la clase Partida que usa la interfaz Flutter.

import 'package:flutter_test/flutter_test.dart';

import 'package:pin_pon_app/juego/entities.dart';
import 'package:pin_pon_app/juego/game_config.dart';
import 'package:pin_pon_app/juego/partida.dart';

void main() {
  // ---------------------------------------------------------------------
  // Tests migrados desde la consola (entidades y configuración).
  // ---------------------------------------------------------------------

  test('la pelota avanza segun su velocidad', () {
    final pelota = Pelota(x: 10, y: 10, velocidad: 2);
    pelota.mover();
    expect(pelota.xEntero, 12);
    expect(pelota.yEntero, 11);
  });

  test('la velocidad vertical se escala progresivamente', () {
    expect(Pelota(x: 0, y: 0, velocidad: 1).velocidadVertical, 1);
    expect(Pelota(x: 0, y: 0, velocidad: 4).velocidadVertical, 2);
    expect(Pelota(x: 0, y: 0, velocidad: 6).velocidadVertical, 3);
  });

  test('los rebotes invierten la direccion', () {
    final pelota = Pelota(x: 10, y: 10);
    pelota.rebotarX();
    pelota.rebotarY();
    expect(pelota.dx, -1);
    expect(pelota.dy, -1);
  });

  test('la paleta no sale de los limites', () {
    final paleta = Paleta(x: 2, y: 1, alto: 4);
    paleta.moverArriba();
    expect(paleta.y, 1);

    paleta.moverAbajo(pasos: 20, limiteInferior: GameConfig.alto);
    expect(paleta.y, GameConfig.alto - 1 - paleta.alto);
  });

  test('la velocidad progresiva crece hasta el maximo', () {
    final cfg = GameConfig.dificultades[Dificultad.medio]!;
    double velocidad(int puntos) {
      final base =
          cfg.velocidadInicial + puntos * GameConfig.incrementoVelocidadPorPunto;
      return base.clamp(cfg.velocidadInicial, cfg.velocidadMaxima).toDouble();
    }

    expect(velocidad(0), cfg.velocidadInicial);
    expect(velocidad(30), cfg.velocidadMaxima);
  });

  test('existen retos configurables', () {
    expect(GameConfig.retos, isNotEmpty);
    expect(GameConfig.retos.first.objetivo, greaterThan(0));
    expect(GameConfig.retos.any((r) => r.tiempoSegundos > 0), isTrue);
  });

  // ---------------------------------------------------------------------
  // Tests de la clase Partida (lógica de una partida completa).
  // ---------------------------------------------------------------------

  test('la partida inicia con marcador 0-0 y piezas en el centro', () {
    final partida = Partida(
      config: GameConfig.dificultades[Dificultad.facil]!,
      modo: ModoJuego.contraIA,
    );

    expect(partida.p1, 0);
    expect(partida.p2, 0);
    expect(partida.activa, isTrue);
    expect(partida.pausada, isFalse);
    expect(partida.pelota.x, GameConfig.ancho / 2);
    expect(partida.pelota.y, GameConfig.alto / 2);
  });

  test('tick mueve la pelota un frame', () {
    final partida = Partida(
      config: GameConfig.dificultades[Dificultad.facil]!,
      modo: ModoJuego.contraIA,
    );

    final xAntes = partida.pelota.x;
    partida.tick();
    expect(partida.pelota.x, greaterThan(xAntes));
  });

  test('pausar la partida detiene el avance de la pelota', () {
    final partida = Partida(
      config: GameConfig.dificultades[Dificultad.facil]!,
      modo: ModoJuego.contraIA,
    );

    partida.alternarPausa();
    expect(partida.pausada, isTrue);

    final xAntes = partida.pelota.x;
    final evento = partida.tick();
    expect(evento, EventoPartida.ninguno);
    expect(partida.pelota.x, xAntes);
  });

  test('en dos jugadores la IA no mueve su paleta', () {
    final partida = Partida(
      config: GameConfig.dificultades[Dificultad.dificil]!,
      modo: ModoJuego.dosJugadores,
    );

    // La pelota empieza yendo hacia la derecha (dx=1 por defecto), pero la
    // IA no debe reaccionar en modo dos jugadores.
    partida.pelota.x = GameConfig.ancho * 0.8;
    partida.pelota.dx = 1;
    final yJ2Antes = partida.j2.y;
    partida.tick();
    expect(partida.j2.y, yJ2Antes);
  });

  test('contra la IA, la paleta derecha reacciona a la pelota', () {
    final partida = Partida(
      config: GameConfig.dificultades[Dificultad.facil]!,
      modo: ModoJuego.contraIA,
    );

    // Colocamos la pelota lejos a la derecha, viajando hacia la IA.
    partida.pelota.x = GameConfig.ancho * 0.85;
    partida.pelota.y = 2;
    partida.pelota.dx = 1;
    partida.pelota.dy = 0;

    final yJ2Antes = partida.j2.y;
    partida.tick();
    // La IA debe haber intentado moverse hacia arriba (la pelota está en y=2
    // y la paleta está centrada en y≈8).
    expect(partida.j2.y, lessThan(yJ2Antes));
  });

  test('el reto por tiempo se completa al llegar al limite', () {
    final reto = GameConfig.retos.firstWhere((r) => r.tiempoSegundos > 0);
    final partida = Partida(
      config: GameConfig.dificultades[reto.dificultad]!,
      modo: ModoJuego.reto,
      reto: reto,
    );

    // Simulamos que ya ha pasado casi todo el tiempo del reto.
    partida.tiempoMs = (reto.tiempoSegundos * 1000) - GameConfig.frameRate.inMilliseconds;

    // Forzamos un punto para que tick() llame a _verificarFinPartida.
    // La pelota se coloca en y=1 para que NO colisione con la paleta J1
    // (que ocupa las filas centrales) y salga limpia por el borde.
    partida.pelota.x = -1;
    partida.pelota.dx = -1;
    partida.pelota.y = 1;
    final evento = partida.tick();

    expect(evento, EventoPartida.fin);
    expect(partida.retoCompletado, isTrue);
    expect(partida.activa, isFalse);
    expect(partida.mensajeFinal, contains(reto.nombre));
  });

  test('el reto por puntos se completa al alcanzar el objetivo', () {
    final reto = GameConfig.retos.firstWhere((r) => r.objetivo > 0);
    final partida = Partida(
      config: GameConfig.dificultades[reto.dificultad]!,
      modo: ModoJuego.reto,
      reto: reto,
    );

    // Colocamos al J1 a un punto de ganar.
    partida.p1 = reto.objetivo - 1;

    // La pelota sale por la derecha: punto para el J1.
    // y=1 evita la colisión con la paleta J2 (fila central).
    partida.pelota.x = GameConfig.ancho + 1;
    partida.pelota.dx = 1;
    partida.pelota.y = 1;
    final evento = partida.tick();

    expect(evento, EventoPartida.fin);
    expect(partida.retoCompletado, isTrue);
    expect(partida.p1, reto.objetivo);
  });

  test('la partida normal termina al llegar a puntosParaGanar', () {
    final partida = Partida(
      config: GameConfig.dificultades[Dificultad.medio]!,
      modo: ModoJuego.contraIA,
    );

    partida.p1 = GameConfig.puntosParaGanar - 1;
    // Pelota fuera por la derecha, y=1 para no chocar con la paleta J2.
    partida.pelota.x = GameConfig.ancho + 1;
    partida.pelota.dx = 1;
    partida.pelota.y = 1;
    final evento = partida.tick();

    expect(evento, EventoPartida.fin);
    expect(partida.activa, isFalse);
    expect(partida.mensajeFinal, contains('Jugador 1'));
  });

  test('moverJ1A limita la paleta dentro del campo', () {
    final partida = Partida(
      config: GameConfig.dificultades[Dificultad.facil]!,
      modo: ModoJuego.contraIA,
    );

    partida.moverJ1A(-10);
    expect(partida.j1.y, 1);

    partida.moverJ1A(999);
    expect(partida.j1.y, GameConfig.alto - 1 - partida.j1.alto);
  });

  test('reiniciar reinicia marcador y estado', () {
    final partida = Partida(
      config: GameConfig.dificultades[Dificultad.medio]!,
      modo: ModoJuego.contraIA,
    );

    partida.p1 = 5;
    partida.p2 = 3;
    partida.detener();
    expect(partida.activa, isFalse);

    partida.reiniciar();
    expect(partida.p1, 0);
    expect(partida.p2, 0);
    expect(partida.activa, isTrue);
  });

  test('en dos jugadores se usan los nombres indicados', () {
    final partida = Partida(
      config: GameConfig.dificultades[Dificultad.facil]!,
      modo: ModoJuego.dosJugadores,
      nombreJ1: 'Ana',
      nombreJ2: 'Luis',
    );

    expect(partida.nombreJ1, 'Ana');
    expect(partida.nombreJ2, 'Luis');

    // El mensaje final debe incluir el nombre del ganador.
    partida.p1 = GameConfig.puntosParaGanar - 1;
    partida.pelota.x = GameConfig.ancho + 1;
    partida.pelota.dx = 1;
    partida.pelota.y = 1;
    partida.tick();
    expect(partida.mensajeFinal, contains('Ana'));
  });

  test('los nombres vacíos usan los valores por defecto', () {
    final partida = Partida(
      config: GameConfig.dificultades[Dificultad.facil]!,
      modo: ModoJuego.contraIA,
      nombreJ1: '   ',
      nombreJ2: '',
    );

    expect(partida.nombreJ1, 'Jugador 1');
    // En contra-IA el segundo nombre por defecto es "IA".
    expect(partida.nombreJ2, 'IA');
  });
}
