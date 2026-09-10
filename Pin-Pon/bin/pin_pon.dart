import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:pin_pon/ai.dart';
import 'package:pin_pon/entities.dart';
import 'package:pin_pon/game_config.dart';
import 'package:pin_pon/input.dart';
import 'package:pin_pon/pin_pon.dart';
import 'package:pin_pon/render.dart';
import 'package:pin_pon/ui.dart';

enum Pantalla { inicio, dificultad, retos, finPartida }

void main() {
  stdout.write(saludo());

  final teclado = Teclado();
  final juego = PinPonJuego(teclado);

  Renderer.ocultarCursor();
  teclado.configurar(juego.procesarTecla);
  pintarInicio();

  ProcessSignal.sigint.watch().listen((_) {
    juego.detener();
    exit(0);
  });
}

class PinPonJuego {
  final Teclado _teclado;
  final IA _ia = IA();

  Pantalla _pantalla = Pantalla.inicio;
  Timer? _timer;
  bool _jugando = false;
  bool _pausado = false;

  ModoJuego? _modoPendiente;
  ModoJuego _modo = ModoJuego.dosJugadores;
  Dificultad _dificultad = Dificultad.medio;
  Reto? _reto;
  final Set<int> _retosCompletados = <int>{};

  Pelota? _pelota;
  Paleta? _j1;
  Paleta? _j2;
  int _p1 = 0;
  int _p2 = 0;
  int _tiempoMs = 0;

  PinPonJuego(this._teclado);

  ConfigDificultad get _config => GameConfig.dificultades[_dificultad]!;

  void procesarTecla(String tecla) {
    if (_jugando) {
      _procesarTeclaJuego(tecla);
      return;
    }

    switch (_pantalla) {
      case Pantalla.inicio:
        _procesarTeclaInicio(tecla);
        break;
      case Pantalla.dificultad:
        _procesarTeclaDificultad(tecla);
        break;
      case Pantalla.retos:
        _procesarTeclaRetos(tecla);
        break;
      case Pantalla.finPartida:
        _mostrarInicio();
        break;
    }
  }

  void detener() {
    _timer?.cancel();
    _teclado.restaurarModo();
    Renderer.mostrarCursor();
  }

  void _procesarTeclaInicio(String tecla) {
    switch (tecla) {
      case '1':
        _modoPendiente = ModoJuego.dosJugadores;
        _pantalla = Pantalla.dificultad;
        pintarDificultad(descripcionModo(ModoJuego.dosJugadores));
        break;
      case '2':
        _modoPendiente = ModoJuego.contraIA;
        _pantalla = Pantalla.dificultad;
        pintarDificultad(descripcionModo(ModoJuego.contraIA));
        break;
      case '3':
        _pantalla = Pantalla.retos;
        pintarRetos(GameConfig.retos, _retosCompletados);
        break;
      case '4':
      case 'q':
        _salir();
    }
  }

  void _procesarTeclaDificultad(String tecla) {
    switch (tecla) {
      case 'r':
        _mostrarInicio();
        return;
      case 'q':
        _salir();
        return;
      case '1':
        _dificultad = Dificultad.facil;
        break;
      case '2':
        _dificultad = Dificultad.medio;
        break;
      case '3':
        _dificultad = Dificultad.dificil;
        break;
      default:
        return;
    }

    _modo = _modoPendiente ?? _modo;
    _iniciarPartida();
  }

  void _procesarTeclaRetos(String tecla) {
    if (tecla == 'r') {
      _mostrarInicio();
      return;
    }
    if (tecla == 'q') {
      _salir();
      return;
    }

    final indice = int.tryParse(tecla);
    if (indice != null && indice >= 1 && indice <= GameConfig.retos.length) {
      final reto = GameConfig.retos[indice - 1];
      _reto = reto;
      _modo = ModoJuego.reto;
      _dificultad = reto.dificultad;
      _iniciarPartida();
    }
  }

  void _procesarTeclaJuego(String tecla) {
    if (tecla == 'q') {
      _terminarPartida('Partida abandonada.');
      return;
    }
    if (tecla == 'p') {
      _pausado = !_pausado;
      _dibujarPartida();
    }
  }

  void _iniciarPartida() {
    _jugando = true;
    _pausado = false;
    _p1 = 0;
    _p2 = 0;
    _tiempoMs = 0;

    final mitad = GameConfig.alto ~/ 2;
    _pelota = Pelota(
      x: GameConfig.ancho / 2,
      y: GameConfig.alto / 2,
      velocidad: _config.velocidadInicial,
    );
    _j1 = Paleta(x: 2, y: mitad - _config.tamanoPaleta ~/ 2, alto: _config.tamanoPaleta);
    _j2 = Paleta(
      x: GameConfig.ancho - 3,
      y: mitad - _config.tamanoPaleta ~/ 2,
      alto: _config.tamanoPaleta,
    );

    Renderer.ocultarCursor();
    _timer = Timer.periodic(GameConfig.frameRate, (_) => _bucle());
    _dibujarPartida();
  }

  void _bucle() {
    if (_pausado || !_jugando) {
      return;
    }
    _tiempoMs += GameConfig.frameRate.inMilliseconds;

    _moverPaletas();
    _pelota!.mover();
    _rebotesYColisiones();
    _verificarPuntos();
    if (_jugando) {
      _dibujarPartida();
    }
  }

  void _moverPaletas() {
    final pasos = _config.velocidadPaleta;
    final ventana = GameConfig.msRetencionTecla;

    if (_teclado.reciente('w', ventana)) {
      _j1!.moverArriba(pasos: pasos);
    }
    if (_teclado.reciente('s', ventana)) {
      _j1!.moverAbajo(pasos: pasos, limiteInferior: GameConfig.alto);
    }

    if (_modo == ModoJuego.dosJugadores) {
      if (_teclado.reciente('i', ventana)) {
        _j2!.moverArriba(pasos: pasos);
      }
      if (_teclado.reciente('k', ventana)) {
        _j2!.moverAbajo(pasos: pasos, limiteInferior: GameConfig.alto);
      }
    } else {
      _ia.mover(_j2!, _pelota!, _config);
    }
  }

  void _rebotesYColisiones() {
    final pelota = _pelota!;
    final j1 = _j1!;
    final j2 = _j2!;

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
    }
    if (pelota.dx > 0 && pelota.x >= j2.x - 1 && _dentroRango(pelota.y, j2)) {
      pelota.x = j2.x - 1;
      pelota.rebotarX();
    }
  }

  bool _dentroRango(double y, Paleta paleta) =>
      y >= paleta.y && y < paleta.y + paleta.alto;

  void _verificarPuntos() {
    final pelota = _pelota!;
    final j1 = _j1!;
    final j2 = _j2!;

    if (pelota.x <= j1.x) {
      _p2++;
      _registrarPunto();
    } else if (pelota.x >= j2.x) {
      _p1++;
      _registrarPunto();
    }
  }

  void _registrarPunto() {
    final puntos = _p1 + _p2;
    final base = _config.velocidadInicial + puntos * GameConfig.incrementoVelocidadPorPunto;
    final velocidad = math.min(
      _config.velocidadMaxima,
      base,
    );
    _pelota!.velocidad = velocidad;
    _pelota!.reiniciar(GameConfig.ancho / 2, GameConfig.alto / 2);
    _verificarFinPartida();
  }

  void _verificarFinPartida() {
    if (_modo == ModoJuego.reto) {
      final reto = _reto!;
      if (reto.tiempoSegundos > 0) {
        if (_tiempoMs >= reto.tiempoSegundos * 1000) {
          _terminarPartida(
            'Reto "${reto.nombre}" completado! Sobreviviste '
            '${reto.tiempoSegundos} segundos.',
            completo: true,
          );
        }
      } else if (_p1 >= reto.objetivo) {
        _terminarPartida(
          'Reto "${reto.nombre}" completado! Anotaste $_p1 puntos.',
          completo: true,
        );
      }
      return;
    }

    if (_p1 >= GameConfig.puntosParaGanar) {
      _terminarPartida('Victoria del Jugador 1!  Marcador final: $_p1 - $_p2');
    } else if (_p2 >= GameConfig.puntosParaGanar) {
      final ganador = _modo == ModoJuego.contraIA ? 'la IA' : 'el Jugador 2';
      _terminarPartida('Victoria de $ganador!  Marcador final: $_p1 - $_p2');
    }
  }

  void _terminarPartida(String mensaje, {bool completo = false}) {
    _jugando = false;
    _timer?.cancel();
    _timer = null;

    if (completo && _reto != null) {
      _retosCompletados.add(_reto!.id);
    }

    Renderer.mostrarCursor();
    _pantalla = Pantalla.finPartida;
    pintarFin(mensaje);
    _reto = null;
    _modoPendiente = null;
  }

  void _dibujarPartida() {
    final encabezado =
        '  ${descripcionModo(_modo, _reto)} [${_dificultad.nombre}]'
        '  J1: $_p1  |  J2: $_p2  |  Vel x${_pelota!.velocidad.toStringAsFixed(1)}';

    Renderer.dibujar(
      pelota: _pelota!,
      j1: _j1!,
      j2: _j2!,
      p1: _p1,
      p2: _p2,
      encabezado: encabezado,
    );

    if (_pausado) {
      stdout.write(Renderer.amarillo('\n  [PAUSA]  P para continuar, Q para salir'));
    }
  }

  void _mostrarInicio() {
    _pantalla = Pantalla.inicio;
    Renderer.ocultarCursor();
    pintarInicio();
  }

  void _salir() {
    detener();
    Renderer.limpiarPantalla();
    stdout.writeln('Gracias por jugar Pin-Pon. Hasta pronto!');
    exit(0);
  }
}