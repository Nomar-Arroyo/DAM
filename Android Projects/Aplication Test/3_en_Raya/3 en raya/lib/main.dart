// ===========================================================================
// TRES EN RAYA - Aplicación Flutter multiplataforma
// ===========================================================================
// El juego se juega tocando las casillas del tablero. El jugador es la "X"
// (morada) y la máquina juega con la "O" (rosa). También hay un modo para
// dos personas jugando en el mismo dispositivo.
//
// INTELIGENCIA ARTIFICIAL
// La máquina usa el algoritmo Minimax: prueba mentalmente TODAS las jugadas
// posibles hasta el final de la partida y elige la que le da mejor resultado.
// En la dificultad "Imposible" nunca pierde, porque siempre halla la jugada
// óptima. En "Normal" usa el mismo cálculo pero se equivoca a propósito el
// 30% de las veces, y en "Fácil" elige casillas al azar.
//
// SISTEMA DE PUNTOS
//   - Victoria: puntos base según la dificultad (Fácil 20, Normal 50,
//     Imposible 100).
//   - Racha: cada victoria consecutiva aplica un multiplicador mayor.
//   - Rapidez: bonus de 20 puntos si ganas en 15 segundos o menos.
//   - Empate: 10 puntos contra la máquina.
//   - Cada partida muestra el desglose de cómo se obtuvo la nota.
//
// ARQUITECTURA
// Toda la lógica vive en [_TresEnRayaPageState]. El resto de clases son
// widgets de presentación que reciben los datos por parámetros y no
// guardan estado propio.
// ===========================================================================

import 'dart:math';

import 'package:flutter/material.dart';

/// Punto de entrada de la aplicación. Lanza el widget raíz.
void main() {
  runApp(const TresEnRayaApp());
}

/// Color del jugador (X) en toda la interfaz.
const Color _colorJugador = Color(0xFF7C6BFF);

/// Color de la máquina (O) en toda la interfaz.
const Color _colorMaquina = Color(0xFFFF6B8A);

/// Niveles de dificultad de la máquina.
///
/// Cada nivel lleva una etiqueta para el botón y una descripción que se
/// muestra debajo para explicar cómo juega el rival.
enum Dificultad {
  facil('Fácil', 'La máquina juega al azar'),
  medio('Normal', 'Juega bien, pero comete errores'),
  dificil('Imposible', 'Nunca puedes ganarle');

  const Dificultad(this.etiqueta, this.descripcion);

  /// Texto visible en el botón.
  final String etiqueta;

  /// Explicación que se muestra bajo los botones de dificultad.
  final String descripcion;
}

/// Modos de juego disponibles.
enum Modo {
  maquina('Contra máquina'),
  dosJugadores('Dos jugadores');

  const Modo(this.etiqueta);

  /// Texto visible en el botón.
  final String etiqueta;
}

/// Las 8 combinaciones de casillas que forman una línea ganadora.
/// Cada lista guarda los 3 índices del tablero que deben coincidir.
/// El tablero se recorre del 0 al 8 así:
///
///     0 | 1 | 2
///    ---------
///     3 | 4 | 5
///    ---------
///     6 | 7 | 8
const List<List<int>> _lineas = [
  [0, 1, 2],
  [3, 4, 5],
  [6, 7, 8],
  [0, 3, 6],
  [1, 4, 7],
  [2, 5, 8],
  [0, 4, 8],
  [2, 4, 6],
];

/// Valor con el que se representa una X dentro del tablero.
const int _x = 0;

/// Valor con el que se representa una O dentro del tablero.
/// Una casilla vacía se guarda como `null`.
const int _o = 1;

/// Registro de un movimiento, necesario para poder deshacer.
///
/// Guarda el tablero ANTES de jugar, quién hizo la jugada y si esa jugada
/// terminó la partida. Con esos tres datos el botón "Deshacer" también sabe
/// si debe quitar el resultado del marcador.
class _Movimiento {
  _Movimiento(this.tableroAntes, this.fueJugador, this.terminoAqui);

  /// Copia del tablero antes de aplicar esta jugada.
  final List<int?> tableroAntes;

  /// `true` si la hizo el jugador, `false` si la hizo la máquina.
  final bool fueJugador;

  /// `true` si esta jugada cerró la partida (línea o tablero lleno).
  final bool terminoAqui;
}

/// Widget raíz de la aplicación.
///
/// Solo define el tema oscuro y la pantalla inicial. Al ser `StatelessWidget`
/// no guarda estado propio.
class TresEnRayaApp extends StatelessWidget {
  const TresEnRayaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // A partir de un solo color semilla se genera toda la paleta, así el
    // tema queda coherente sin tener que definir cada color a mano.
    final esquema = ColorScheme.fromSeed(
      seedColor: _colorJugador,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Tres en Raya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: esquema,
        scaffoldBackgroundColor: const Color(0xFF0C0C18),
      ),
      home: const TresEnRayaPage(),
    );
  }
}

/// Pantalla principal del juego.
///
/// Al ser `StatefulWidget` delega todo el trabajo en [_TresEnRayaPageState],
/// que es la clase que guarda el estado del juego.
class TresEnRayaPage extends StatefulWidget {
  const TresEnRayaPage({super.key});

  @override
  State<TresEnRayaPage> createState() => _TresEnRayaPageState();
}

/// Estado de la pantalla: aquí vive TODA la lógica del juego y del marcador.
///
/// Cada vez que cambia una variable de este `State`, Flutter vuelve a dibujar
/// la pantalla, por eso las modificaciones siempre van dentro de `setState`.
class _TresEnRayaPageState extends State<TresEnRayaPage>
    with SingleTickerProviderStateMixin {
  /// Controla el brillo pulsante de las casillas ganadoras.
  /// `repeat(reverse: true)` lo hace ir de 0 a 1 y de vuelta a 0 en bucle
  /// infinito, cada vuelta de 850 ms.
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);

  /// Generador de números aleatorios (nivel fácil y retardos de la máquina).
  final Random _aleatorio = Random();

  /// Estado del tablero: 9 casillas con `null` (vacía), `_x` (0) u `_o` (1).
  ///
  /// Se declara con `<int?>[null, ...]` en vez de `List<int?>.filled(9, null)`
  /// porque este último crea una lista de longitud FIJA, y las funciones
  /// `_nuevaPartida()` y `_deshacer()` usan `..clear()` para vaciarla.
  /// Sobre una lista fija eso lanza "Cannot clear a fixed-length list".
  List<int?> _tablero = List<int?>.filled(9, null);

  /// Historial de movimientos, usado por el botón "Deshacer".
  final List<_Movimiento> _historial = [];

  /// Resultado de cada partida jugada:
  /// 'J' = gana X, 'M' = gana O (máquina), 'E' = empate.
  final List<String> _resultados = [];

  /// Modo de juego seleccionado.
  Modo _modo = Modo.maquina;

  /// Dificultad de la máquina seleccionada.
  Dificultad _dificultad = Dificultad.dificil;

  /// Ficha que juega el usuario: `_x` o `_o`.
  ///
  /// Si el usuario elige la O, la máquina pone la X y además abre la partida
  /// jugando ella sola, porque en el Tres en Raya convencional empieza la X.
  int _fichaJugador = _x;

  /// `true` mientras la máquina "piensa". Bloquea los toques del jugador.
  bool _pensando = false;

  /// `true` cuando la partida terminó (línea ganadora o tablero lleno).
  bool _terminado = false;

  /// Índices de las 3 casillas que forman la línea ganadora. Vacía si no hay.
  List<int> _lineaGanadora = const [];

  /// Puntuación acumulada en la sesión actual.
  int _puntos = 0;

  /// Victorias consecutivas. Se reinicia al perder o empatar.
  int _racha = 0;

  /// Récord histórico de la mejor racha alcanzada.
  int _mejorRacha = 0;

  /// Momento en que empezó la partida, para calcular el bonus de rapidez.
  DateTime? _inicioPartida;

  /// Partidas ganadas por el usuario.
  ///
  /// 'J' siempre significa "ganó X", así que si el usuario juega con la O
  /// hay que contar los 'M'. Por eso se compara con [_fichaJugador] y no con
  /// una letra fija.
  int get _ganadasJugador => _resultados.where((r) => r == _clave(_fichaJugador)).length;

  /// Partidas ganadas por la máquina (la ficha contraria a la del usuario).
  int get _ganadasMaquina =>
      _resultados.where((r) => r == _clave(_fichaMaquina)).length;

  /// Partidas empatadas.
  int get _empates => _resultados.where((r) => r == 'E').length;

  /// Puntos base por victoria según la dificultad del rival.
  /// Ganarle a la máquina "Imposible" vale el doble que a la "Fácil".
  static const Map<Dificultad, int> _base = {
    Dificultad.facil: 20,
    Dificultad.medio: 50,
    Dificultad.dificil: 100,
  };

  /// Desglose de puntos de la última partida.
  /// Se devuelve una copia para que la interfaz no pueda modificarlo.
  List<String> get _desglose => List<String>.from(_ultimoDesglose);

  /// Lista interna con el desglose de la última partida.
  final List<String> _ultimoDesglose = [];

  /// Ficha que controla la máquina: la contraria a la del usuario.
  int get _fichaMaquina => _fichaJugador == _x ? _o : _x;

  /// Traduce una ficha a la letra que se usa en [_resultados].
  /// `_x` se guarda como 'J' (jugador) y `_o` como 'M' (máquina).
  String _clave(int ficha) => ficha == _x ? 'J' : 'M';

  /// Texto que describe la racha actual, con tono épico según su tamaño.
  String get _etiquetaRacha {
    if (_racha == 0) return 'Sin racha';
    if (_racha >= 5) return 'Racha x5 legendaria';
    if (_racha >= 3) return 'Racha x3';
    if (_racha == 2) return 'Doble victoria';
    return 'Victoria seguidas: 1';
  }

  /// Busca si alguna de las 8 líneas tiene sus tres casillas iguales.
  ///
  /// Devuelve los índices de la línea ganadora o `null` si todavía no hay.
  /// Se devuelven los índices porque la interfaz los usa para resaltar
  /// visualmente las casillas que ganaron la partida.
  List<int>? _buscarLinea(List<int?> t) {
    for (final linea in _lineas) {
      final a = t[linea[0]];
      if (a != null && a == t[linea[1]] && a == t[linea[2]]) return linea;
    }
    return null;
  }

  /// Algoritmo Minimax: el "cerebro" de la máquina.
  ///
  /// Parámetros:
  ///   - [t]: tablero a evaluar.
  ///   - [turnoMaquina]: a quién le toca mover en esta simulación.
  ///   - [profundidad]: cuántas jugadas quedan por simular.
  ///
  /// La idea es probar TODAS las jugadas posibles una por una hasta llegar al
  /// final de la partida, y devolver un número que diga qué tan bueno es el
  /// resultado para la máquina:
  ///   -  +(10 - profundidad): la máquina ganó. Cuanto antes, más alto.
  ///   -  (profundidad - 10): ganó el jugador. Cuanto antes, más bajo.
  ///   -   0: empate.
  ///
  /// Luego se queda con el MEJOR de esos números: la máquina toma el máximo
  /// (le interesa ganar) y el jugador el mínimo (el peor caso para ella).
  /// El jugador nunca la llama directamente, así que la máquina anticipa
  /// todas las respuestas posibles del humano antes de decidirse.
  ///
  /// Es un árbol de decisiones: cada nivel es una jugada posible y cada hoja
  /// es un resultado final. El tablero 3x3 es pequeño (9 casillas), así que
  /// el número de simulaciones es asumible.
  ///
  /// `turnoMaquina` indica si quien mueve en este nivel es la máquina. Como
  /// la máquina puede tener la X o la O según lo que eligió el usuario, se usa
  /// [_fichaMaquina] en lugar de una letra fija.
  int _minimax(List<int?> t, bool turnoMaquina, int profundidad) {
    final linea = _buscarLinea(t);
    if (linea != null) {
      final ganoLaMaquina = t[linea[0]] == _fichaMaquina;
      return ganoLaMaquina ? 10 - profundidad : profundidad - 10;
    }
    if (!t.contains(null)) return 0;

    var mejor = turnoMaquina ? -99 : 99;
    for (var i = 0; i < 9; i++) {
      if (t[i] != null) continue; // casilla ocupada, se salta
      t[i] = turnoMaquina ? _fichaMaquina : _fichaJugador;
      final valor = _minimax(t, !turnoMaquina, profundidad + 1);
      t[i] = null; // se deshace la jugada simulada para probar la siguiente
      mejor = turnoMaquina ? max(mejor, valor) : min(mejor, valor);
    }
    return mejor;
  }

  /// Decide en qué casilla juega la máquina, según la dificultad.
  ///
  /// - Fácil: elige cualquier casilla libre al azar.
  /// - Imposible: usa Minimax y siempre hace la mejor jugada posible.
  /// - Normal: usa Minimax pero un 30% de las veces se equivoca a propósito,
  ///   para que el nivel siga siendo ganable.
  ///
  /// Devuelve el índice de la casilla elegida, o `null` si el tablero está lleno.
  int? _elegirJugadaMaquina(List<int?> t) {
    final libres = [for (var i = 0; i < 9; i++) if (t[i] == null) i];
    if (libres.isEmpty) return null;

    if (_dificultad == Dificultad.facil) {
      return libres[_aleatorio.nextInt(libres.length)];
    }

    // Se simula la jugada de la máquina en cada casilla libre y se puntúa el
    // resultado. `prueba` es una copia para no tocar el tablero real del juego.
    final prueba = List<int?>.from(t);
    final puntajes = <int, int>{};
    for (final i in libres) {
      prueba[i] = _fichaMaquina;
      // Tras simular la jugada de la máquina le toca al usuario, por eso
      // el siguiente nivel se evalúa con `turnoMaquina: false`.
      puntajes[i] = _minimax(prueba, false, 0);
      prueba[i] = null;
    }

    // Se localizan las jugadas con la máxima puntuación.
    final mejor = puntajes.values.reduce(max);
    final mejores = puntajes.entries
        .where((e) => e.value == mejor)
        .map((e) => e.key)
        .toList();

    if (_dificultad == Dificultad.dificil) {
      return mejores[_aleatorio.nextInt(mejores.length)];
    }

    // Nivel Normal: 30% de probabilidad de elegir cualquier casilla libre.
    if (_aleatorio.nextDouble() < 0.3) {
      return libres[_aleatorio.nextInt(libres.length)];
    }
    return mejores[_aleatorio.nextInt(mejores.length)];
  }

  /// Coloca una ficha en el tablero y comprueba si la partida terminó.
  ///
  /// Si la partida se cierra, registra el resultado en el marcador y calcula
  /// los puntos correspondientes.
  void _jugar(int indice, int ficha, {required bool porJugador}) {
    final antes = List<int?>.from(_tablero);
    setState(() => _tablero[indice] = ficha);

    final linea = _buscarLinea(_tablero);
    final lleno = !_tablero.contains(null);

    if (linea != null || lleno) {
      setState(() {
        _terminado = true;
        _lineaGanadora = linea ?? const [];
      });
      _resultados.add(linea != null ? _clave(ficha) : 'E');
      _sumarPuntos(ficha, gano: linea != null, completo: lleno);
    }

    _historial.add(_Movimiento(antes, porJugador, linea != null || lleno));
  }

  /// Calcula y suma los puntos de la partida que acaba de terminar.
  ///
  /// El desglose se guarda en [_ultimoDesglose] para que la interfaz muestre
  /// de dónde sale cada punto y no solo el total.
  void _sumarPuntos(int ganador, {required bool gano, required bool completo}) {
    _ultimoDesglose.clear();

    // En modo dos jugadores solo puntúa el jugador 1 (X), para no premiar
    // a quien está usando el mismo dispositivo.
    if (_modo == Modo.dosJugadores) {
      if (gano && ganador == _fichaJugador) {
        _racha++;
        _mejorRacha = max(_mejorRacha, _racha);
        final base = 15;
        final bonus = (_racha - 1) * 10;
        final total = base + bonus;
        _puntos += total;
        _ultimoDesglose.addAll([
          'Victoria de X: +$base',
          if (bonus > 0) 'Racha x$_racha: +$bonus',
        ]);
      } else if (completo) {
        _ultimoDesglose.add('Empate: +0');
      } else {
        _racha = 0;
      }
      return;
    }

    // Empate contra la máquina: da algo de puntos por el esfuerzo.
    if (!gano) {
      if (completo) {
        final bonus = 10;
        _puntos += bonus;
        _ultimoDesglose.add('Empate contra la máquina: +$bonus');
      }
      return;
    }

    // Si gana la máquina, se pierde la racha y no suman puntos.
    if (ganador == _fichaMaquina) {
      _racha = 0;
      return;
    }

    // Victoria del jugador: se acumula la racha y se aplican los bonus.
    _racha++;
    _mejorRacha = max(_mejorRacha, _racha);

    final base = _base[_dificultad]!;
    // Cada victoria consecutiva sube el multiplicador medio punto:
    // racha 1 -> x1, racha 2 -> x1.5, racha 3 -> x2, racha 4 -> x2.5...
    final multiplicador = (1 + (_racha - 1) * 0.5).round();
    final puntos = base * multiplicador;

    // Bonus de rapidez: solo si la partida se resolvió en 15 s o menos.
    final segundos = _inicioPartida == null
        ? 0
        : DateTime.now().difference(_inicioPartida!).inSeconds;
    final bonusVelocidad = segundos > 0 && segundos <= 15 ? 20 : 0;

    final total = puntos + bonusVelocidad;
    _puntos += total;

    _ultimoDesglose.addAll([
      'Victoria (${_dificultad.etiqueta.toLowerCase()}): +$base',
      if (multiplicador > 1) 'Racha x$_racha (x$multiplicador): +${puntos - base}',
      if (bonusVelocidad > 0) 'Rapidez $segundos s: +$bonusVelocidad',
    ]);
  }

  /// Turno de la máquina.
  ///
  /// Primero muestra "la máquina está pensando" y espera un retardo aleatorio
  /// de 260 a 600 ms, para que la partida se sienta natural y las jugadas no
  /// aparezcan de forma instantánea. Después calcula y juega su casilla.
  Future<void> _turnoMaquina() async {
    setState(() => _pensando = true);
    await Future<void>.delayed(
      Duration(milliseconds: 260 + _aleatorio.nextInt(340)),
    );
    // Tras la espera hay que comprobar que la pantalla siga montada y que la
    // partida no haya terminado mientras tanto.
    if (!mounted || _terminado) {
      if (mounted) setState(() => _pensando = false);
      return;
    }
    final jugada = _elegirJugadaMaquina(_tablero);
    if (jugada == null) return;
    setState(() => _pensando = false);
    _jugar(jugada, _fichaMaquina, porJugador: false);
  }

  /// Callback que se ejecuta al tocar una casilla del tablero.
  ///
  /// Descarta los toques que no son válidos: partida terminada, máquina
  /// pensando o casilla ya ocupada.
  void _tocarCelda(int indice) {
    if (_terminado || _pensando || _tablero[indice] != null) return;

    // En modo dos jugadores se alterna la ficha según cuántas jugadas haya
    // en el historial. El primer jugador de la partida siempre es la X.
    if (_modo == Modo.dosJugadores) {
      final ficha = _historial.length.isEven ? _x : _o;
      _jugar(indice, ficha, porJugador: true);
      return;
    }

    _jugar(indice, _fichaJugador, porJugador: true);
    // Si la jugada del usuario no cerró la partida, responde la máquina.
    if (!_terminado) _turnoMaquina();
  }

  /// Deshace jugadas hasta devolver el turno al jugador.
  ///
  /// Como la máquina responde después de cada jugada del jugador, deshacer
  /// solo un movimiento dejaría un tablero con la máquina "ganando el turno".
  /// Por eso el bucle retrocede hasta deshacer la última jugada del JUGADOR,
  /// arrastrando también la de la máquina que fue respuesta.
  void _deshacer() {
    if (_historial.isEmpty) return;

    var completo = false;
    while (_historial.isNotEmpty) {
      final mov = _historial.removeLast();
      // Si la jugada deshecha había cerrado la partida, se retira su
      // resultado del marcador para que las estadísticas sigan cuadrando.
      if (mov.terminoAqui && _resultados.isNotEmpty) {
        _resultados.removeLast();
      }
      setState(() {
        // Se asigna una lista nueva en vez de usar `..clear()`, porque la
        // copia guardada en el historial es de longitud fija y no admite
        // `clear()`.
        _tablero = List<int?>.from(mov.tableroAntes);
      });
      if (mov.fueJugador) {
        completo = true;
        break;
      }
    }

    if (completo) {
      setState(() {
        _terminado = false;
        _pensando = false;
        _lineaGanadora = const [];
      });
    }
  }

  /// Empieza una partida en blanco.
  ///
  /// No toca los puntos ni el historial de resultados: el marcador se mantiene
  /// para poder seguir acumulando la puntuación entre partidas.
  ///
  /// Si el usuario eligió jugar con la O, la máquina pone la X y abre la
  /// partida jugando primero, porque en el Tres en Raya convencional la X
  /// siempre empieza.
  void _nuevaPartida() {
    setState(() {
      // Importante: se crea una lista NUEVA y_opsional. La anterior puede
      // ser de longitud fija (las copias del historial lo son), y hacer
      // `..clear()` sobre una fija lanza excepción.
      _tablero = List<int?>.filled(9, null);
      _historial.clear();
      _terminado = false;
      _pensando = false;
      _lineaGanadora = const [];
      _ultimoDesglose.clear();
      _inicioPartida = DateTime.now();
    });

    // La máquina abre si el usuario juega con la ficha O.
    if (_modo == Modo.maquina && _fichaJugador == _o) {
      _turnoMaquina();
    }
  }

  /// Pone a cero todas las estadísticas y además empieza una partida nueva.
  void _reiniciarMarcador() {
    setState(() {
      _resultados.clear();
      _puntos = 0;
      _racha = 0;
      _mejorRacha = 0;
      _ultimoDesglose.clear();
    });
    _nuevaPartida();
  }

  /// Texto que resume el estado de la partida, mostrado bajo el tablero.
  String get _mensaje {
    if (!_terminado) {
      if (_modo == Modo.dosJugadores) {
        return 'Turno de ${_historial.length.isEven ? "X" : "O"}';
      }
      if (_pensando) return 'La máquina está pensando...';
      return 'Tu turno: eres ${_fichaJugador == _x ? "X" : "O"}';
    }
    if (_lineaGanadora.isEmpty) return 'Empate. Nadie gana.';
    // Se compara con la ficha del usuario, que ya no siempre es la X.
    final ganoUsuario = _tablero[_lineaGanadora.first] == _fichaJugador;
    if (_modo == Modo.dosJugadores) {
      return '¡Gana ${ganoUsuario ? "X" : "O"}!';
    }
    return ganoUsuario ? '¡Ganaste!' : 'Gana la máquina';
  }

  /// Libera el controlador de animación cuando la pantalla se destruye.
  /// Es obligatorio hacerlo para no dejar memoria reservada.
  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  /// Construye toda la pantalla.
  ///
  /// Se usa `SingleChildScrollView` para que en pantallas pequeñas (móvil en
  /// vertical) el contenido se pueda desplazar, y `ConstrainedBox` para que en
  /// pantallas grandes no se estire más allá de 520 px de ancho.
  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _FondoDecorativo()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    // stretch hace que cada hijo ocupe todo el ancho, para que
                    // los botones y el tablero queden alineados.
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Título con degradado.
                      _Encabezado(tema: tema),
                      const SizedBox(height: 18),
                      // Panel de puntos y racha.
                      _PanelPuntos(
                        puntos: _puntos,
                        racha: _racha,
                        mejorRacha: _mejorRacha,
                        etiquetaRacha: _etiquetaRacha,
                      ),
                      const SizedBox(height: 16),
                      // Contadores de victorias y empates.
                      _Marcadores(
                        jugador: _ganadasJugador,
                        maquina: _ganadasMaquina,
                        empates: _empates,
                        dosJugadores: _modo == Modo.dosJugadores,
            fichaJugador: _fichaJugador,
            fichaMaquina: _fichaMaquina,
                      ),
                      const SizedBox(height: 18),
                      // Selector de modo. Cambiarlo reinicia la partida, ya
                      // que las reglas (turnos y puntos) son distintas.
                      //
                      // OJO: no se mete dentro de `setState` porque
                      // `_nuevaPartida()` ya llama a `setState` por su cuenta.
                      // Anidarlos lanzaría "setState() called during build".
                      _SelectorModo(
                        modo: _modo,
                        onChanged: (m) {
                          setState(() => _modo = m);
                          _nuevaPartida();
                        },
                      ),
                      // El selector de ficha solo tiene sentido contra la
                      // máquina: en dos jugadores ambos eligen por turnos.
                      if (_modo == Modo.maquina) ...[
                        const SizedBox(height: 14),
                        _SelectorFicha(
                          ficha: _fichaJugador,
                          onChanged: (f) {
                            setState(() => _fichaJugador = f);
                            _nuevaPartida();
                          },
                        ),
                      ],
                      // El selector de dificultad también solo aplica contra
                      // la máquina, así que se oculta en modo 2 jugadores.
                      if (_modo == Modo.maquina) ...[
                        const SizedBox(height: 14),
                        _SelectorDificultad(
                          dificultad: _dificultad,
                          onChanged: (d) {
                            setState(() => _dificultad = d);
                            _nuevaPartida();
                          },
                        ),
                      ],
                      const SizedBox(height: 22),
                      // Cuadrícula 3x3.
                      _Tablero(
                        tablero: _tablero,
                        lineaGanadora: _lineaGanadora,
                        pulso: _pulso,
                        onTap: _tocarCelda,
                      ),
                      const SizedBox(height: 18),
                      // Estado de la partida y desglose de puntos.
                      _Mensaje(
                        texto: _mensaje,
                        terminado: _terminado,
                        desglose: _desglose,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          // "Deshacer" ocupa 1 parte y "Nueva partida" 2,
                          // de ahí el `flex: 2` que lo hace más ancho.
                          Expanded(
                            child: _BotonAccion(
                              icono: Icons.undo,
                              etiqueta: 'Deshacer',
                              activo: _historial.isNotEmpty,
                              onTap: _deshacer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _BotonAccion(
                              icono: Icons.refresh,
                              etiqueta: 'Nueva partida',
                              activo: true,
                              destacado: true,
                              onTap: _nuevaPartida,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Se deshabilita (onPressed null) si no hay partidas.
                      TextButton.icon(
                        onPressed:
                            _resultados.isEmpty ? null : _reiniciarMarcador,
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: const Text('Reiniciar marcador'),
                        style: TextButton.styleFrom(
                          foregroundColor: tema.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de la aplicación con degradado morado-rosa.
///
/// `ShaderMask` aplica el degradado directamente al texto.
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.tema});

  /// Tema actual, necesario para heredar los estilos de tipografía.
  final ThemeData tema;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [_colorJugador, _colorMaquina],
          ).createShader(r),
          child: Text(
            'Tres en Raya',
            style: tema.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Toca la casilla. La máquina responde.',
          style: tema.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

/// Panel principal de puntuación.
///
/// Cuando hay racha activa el panel se ilumina con el degradado morado-rosa y
/// muestra un icono de fuego; sin racha queda apagado en gris.
class _PanelPuntos extends StatelessWidget {
  const _PanelPuntos({
    required this.puntos,
    required this.racha,
    required this.mejorRacha,
    required this.etiquetaRacha,
  });

  /// Puntuación total acumulada.
  final int puntos;

  /// Victorias consecutivas actuales.
  final int racha;

  /// Récord de la mejor racha.
  final int mejorRacha;

  /// Texto descriptivo de la racha ("Racha x3", "Doble victoria"...).
  final String etiquetaRacha;

  @override
  Widget build(BuildContext context) {
    // `activo` decide si el panel se ve encendido o apagado.
    final activo = racha > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: activo
              ? [
                  _colorJugador.withValues(alpha: 0.35),
                  _colorMaquina.withValues(alpha: 0.35),
                ]
              : [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.04),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: activo
              ? Colors.white.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.12),
          width: activo ? 1.8 : 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            activo ? Icons.local_fire_department : Icons.star_outline,
            color: activo ? Colors.amber : Colors.white54,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PUNTOS',
                  style: TextStyle(
                    fontSize: 10.5,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Text(
                    '$puntos',
                    key: ValueKey(puntos),
                    style: const TextStyle(
                      fontSize: 34,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                etiquetaRacha,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: activo ? Colors.amberAccent : Colors.white54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Mejor racha: $mejorRacha',
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fila con las tres contadores: jugador, máquina y empates.
class _Marcadores extends StatelessWidget {
  const _Marcadores({
    required this.jugador,
    required this.maquina,
    required this.empates,
    required this.dosJugadores,
    required this.fichaJugador,
    required this.fichaMaquina,
  });

  /// Partidas ganadas por el usuario (con la ficha que eligió).
  final int jugador;

  /// Partidas ganadas por la máquina (con la ficha que le tocó).
  final int maquina;

  /// Partidas empatadas.
  final int empates;

  /// Cambia las etiquetas según se esté jugando contra la máquina o no.
  final bool dosJugadores;

  /// Ficha del usuario (`_x` o `_o`), para etiquetar bien el marcador.
  final int fichaJugador;

  /// Ficha de la máquina, la contraria a la del usuario.
  final int fichaMaquina;

  @override
  Widget build(BuildContext context) {
    // En dos jugadores el marcador siempre muestra "X" y "O", porque ahí no
    // hay una ficha elegida: se alternan solas.
    final letraJugador = fichaJugador == _x ? 'X' : 'O';
    final letraMaquina = fichaMaquina == _x ? 'X' : 'O';

    return Row(
      children: [
        Expanded(
          child: _Puntuacion(
            color: _colorJugador,
            titulo: dosJugadores ? 'X' : 'Tú ($letraJugador)',
            valor: jugador,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Puntuacion(
            color: _colorMaquina,
            titulo: dosJugadores ? 'O' : 'Máquina ($letraMaquina)',
            valor: maquina,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Puntuacion(
            color: Colors.amberAccent,
            titulo: 'Empates',
            valor: empates,
          ),
        ),
      ],
    );
  }
}

/// Tarjeta de un contador individual (color, número y título).
class _Puntuacion extends StatelessWidget {
  const _Puntuacion({
    required this.color,
    required this.titulo,
    required this.valor,
  });

  /// Color de acento de la tarjeta.
  final Color color;

  /// Texto bajo el número ("Tú (X)", "Empates"...).
  final String titulo;

  /// Número mostrado.
  final int valor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      // La tarjeta se ilumina cuando el contador es mayor que cero.
      decoration: BoxDecoration(
        color: color.withValues(alpha: valor > 0 ? 0.18 : 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          // AnimatedSwitcher con el número como clave hace que el número
          // "rebote" con una animación de escala cada vez que cambia.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: child,
            ),
            child: Text(
              '$valor',
              key: ValueKey(valor),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector de modo de juego (contra máquina / dos jugadores).
class _SelectorModo extends StatelessWidget {
  const _SelectorModo({required this.modo, required this.onChanged});

  /// Modo actualmente seleccionado.
  final Modo modo;

  /// Se dispara al pulsar otro modo. La pantalla decide qué hacer después.
  final ValueChanged<Modo> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Grupo(
      titulo: 'Modo',
      child: Row(
        children: [
          // `for` dentro de `children` es sugar syntax de Dart: equivale a
          // un bucle que añade un widget por cada elemento del enum.
          for (final m in Modo.values) ...[
            Expanded(
              child: _Pastilla(
                texto: m.etiqueta,
                activa: modo == m,
                onTap: () => onChanged(m),
              ),
            ),
            if (m != Modo.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// Selector de ficha: con qué símbolo juega el usuario.
///
/// Si se elige la O, la máquina juega con la X y además es ella quien abre
/// la partida, ya que en el Tres en Raya convencional siempre empieza la X.
class _SelectorFicha extends StatelessWidget {
  const _SelectorFicha({required this.ficha, required this.onChanged});

  /// Ficha elegida actualmente (`_x` o `_o`).
  final int ficha;

  /// Se dispara al pulsar la otra ficha.
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Grupo(
      titulo: 'Tu ficha',
      child: Row(
        children: [
          for (final f in [_x, _o]) ...[
            Expanded(
              child: _Pastilla(
                texto: f == _x ? 'X' : 'O',
                activa: ficha == f,
                colorActiva: f == _x ? _colorJugador : _colorMaquina,
                onTap: () => onChanged(f),
              ),
            ),
            if (f != _o) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// Selector de dificultad, visible solo en modo "Contra máquina".
///
/// Muestra los tres botones y debajo la descripción del nivel elegido.
class _SelectorDificultad extends StatelessWidget {
  const _SelectorDificultad({
    required this.dificultad,
    required this.onChanged,
  });

  /// Dificultad seleccionada en este momento.
  final Dificultad dificultad;

  /// Se dispara al pulsar otro nivel.
  final ValueChanged<Dificultad> onChanged;

  @override
  Widget build(BuildContext context) {
    return _Grupo(
      titulo: 'Dificultad de la máquina',
      child: Column(
        children: [
          Row(
            children: [
              for (final d in Dificultad.values) ...[
                Expanded(
                  child: _Pastilla(
                    texto: d.etiqueta,
                    activa: dificultad == d,
                    onTap: () => onChanged(d),
                  ),
                ),
                if (d != Dificultad.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // Descripción que explica cómo juega la máquina en este nivel.
          Text(
            dificultad.descripcion,
            style: const TextStyle(fontSize: 11.5, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta pequeña en mayúsculas que encabeza un grupo de controles.
class _Grupo extends StatelessWidget {
  const _Grupo({required this.titulo, required this.child});

  /// Texto de la etiqueta ("Modo", "Dificultad de la máquina"...).
  final String titulo;

  /// Contenido que va bajo la etiqueta.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            titulo.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              color: Colors.white38,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Botón tipo "pastilla" usado en todos los selectores.
///
/// Cuando está activo se pinta con el degradado morado-rosa; si no, queda
/// en gris translúcido.
class _Pastilla extends StatelessWidget {
  const _Pastilla({
    required this.texto,
    required this.activa,
    required this.onTap,
    this.colorActiva,
  });

  /// Texto del botón.
  final String texto;

  /// `true` si esta opción es la seleccionada.
  final bool activa;

  /// Callback al pulsar.
  final VoidCallback onTap;

  /// Color del degradado cuando la pastilla está activa.
  /// Si es `null` se usa el degradado morado-rosa de marca.
  final Color? colorActiva;

  @override
  Widget build(BuildContext context) {
    // Semantics describe el control para los lectores de pantalla.
    return Semantics(
      button: true,
      selected: activa,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: activa
                ? LinearGradient(
                    colors: [
                      colorActiva ?? _colorJugador,
                      colorActiva ?? _colorMaquina,
                    ],
                  )
                : null,
            color: activa ? null : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: activa
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: activa ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cuadrícula 3x3 del juego.
///
/// Construye las nueve casillas a partir del índice `fila * 3 + columna` y
/// reparte el espacio disponible con `Expanded` + `AspectRatio`, de modo que
/// las casillas siempre son cuadradas y caben en cualquier tamaño de pantalla.
class _Tablero extends StatelessWidget {
  const _Tablero({
    required this.tablero,
    required this.lineaGanadora,
    required this.pulso,
    required this.onTap,
  });

  /// Estado actual de las 9 casillas (`null`, `_x` u `_o`).
  final List<int?> tablero;

  /// Índices de las casillas que forman la línea ganadora.
  final List<int> lineaGanadora;

  /// Animación de pulso usada para iluminar esas casillas.
  final Animation<double> pulso;

  /// Callback que recibe el índice de la casilla tocada.
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder da acceso al tamaño disponible antes de construir el
    // layout, y permite que el hueco entre casillas sea proporcional
    // (2,8% del ancho) en lugar de un valor fijo.
    return LayoutBuilder(
      builder: (context, constraints) {
        final hueco = constraints.maxWidth * 0.028;

        return Container(
          padding: EdgeInsets.all(hueco),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              // Se generan 3 filas de 3 celdas con dos bucles anidados.
              // El índice de cada casilla se calcula como fila * 3 + columna.
              for (var fila = 0; fila < 3; fila++) ...[
                if (fila > 0) SizedBox(height: hueco),
                Row(
                  children: [
                    for (var col = 0; col < 3; col++) ...[
                      if (col > 0) SizedBox(width: hueco),
                      // Expanded reparte el ancho disponible y
                      // AspectRatio obliga a que la casilla sea cuadrada.
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _Celda(
                            indice: fila * 3 + col,
                            valor: tablero[fila * 3 + col],
                            ganadora: lineaGanadora.contains(fila * 3 + col),
                            pulso: pulso,
                            onTap: () => onTap(fila * 3 + col),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Una casilla individual del tablero.
///
/// Es responsable de tres efectos: mostrar la X o la O con una animación de
/// entrada, iluminar la casilla si forma parte de la línea ganadora, y
/// disregard los toques cuando la casilla ya está ocupada.
class _Celda extends StatelessWidget {
  const _Celda({
    required this.indice,
    required this.valor,
    required this.ganadora,
    required this.pulso,
    required this.onTap,
  });

  /// Posición de la casilla en el tablero (0 a 8).
  final int indice;

  /// Contenido de la casilla: `null` si está vacía, `_x` u `_o`.
  final int? valor;

  /// `true` si la casilla pertenece a la línea ganadora.
  final bool ganadora;

  /// Animación de pulso para el efecto de brillo.
  final Animation<double> pulso;

  /// Callback al tocarla.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esGanadora = ganadora;
    final color = valor == _x ? _colorJugador : _colorMaquina;

    return Semantics(
      button: true,
      label: esGanadora ? 'Casilla ganadora' : 'Casilla $indice',
      child: GestureDetector(
        // Si la casilla ya tiene ficha, `onTap` es null y no responde al
        // toque. Así la casilla vacía es la única pulsable.
        onTap: valor == null ? onTap : null,
        child: AnimatedBuilder(
          animation: pulso,
          builder: (context, child) {
            // El brillo solo existe en las casillas ganadoras y oscila
            // entre 0.25 y 0.60 siguiendo el valor del pulso.
            final brillo = esGanadora ? 0.25 + pulso.value * 0.35 : 0.0;
            return Container(
              decoration: BoxDecoration(
                color: valor == null
                    ? Colors.white.withValues(alpha: 0.05)
                    : color.withValues(alpha: 0.16 + brillo),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: valor == null
                      ? Colors.white.withValues(alpha: 0.08)
                      : color.withValues(alpha: 0.65 + brillo),
                  width: esGanadora ? 2.4 : 1.4,
                ),
                // La sombra difusa crea el efecto de "resplandor".
                boxShadow: esGanadora
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: brillo * 0.8),
                          blurRadius: 22,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: child,
            );
          },
          // TweenAnimationBuilder anima la aparición de la ficha: cuando `valor` pasa
          // de null a una letra, el tween va de 0 a 1 y con eso la letra
          // aparece escalada desde la mitad de su tamaño (curva easeOutBack,
          // que además le da un pequeño rebote al entrar).
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: valor == null ? 0 : 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.scale(scale: 0.5 + t * 0.5, child: child),
            ),
            child: Center(
              child: valor == null
                  ? null
                  // FittedBox reduce la letra si la casilla es muy pequeña,
                  // para que la X o la O nunca se corten.
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                      valor == _x ? 'X' : 'O',
                      style: TextStyle(
                        fontSize: 44,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: color,
                        shadows: [
                          Shadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner de estado de la partida, situado bajo el tablero.
///
/// Muestra el texto principal ("Tu turno", "¡Ganaste!"...) y, cuando la
/// partida acaba, el desglose de puntos línea a línea.
class _Mensaje extends StatelessWidget {
  const _Mensaje({
    required this.texto,
    required this.terminado,
    required this.desglose,
  });

  /// Mensaje principal del estado.
  final String texto;

  /// `true` si la partida ya terminó, para cambiar el color de fondo.
  final bool terminado;

  /// Líneas del desglose de puntos de la última partida.
  final List<String> desglose;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      child: Container(
        // La clave hace que AnimatedSwitcher detecte el cambio de texto y
        // anime la transición de uno a otro.
        key: ValueKey(texto),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: terminado
              ? _colorJugador.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
        children: [
          // El texto principal, con transición suave de estilo.
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 260),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: terminado ? Colors.white : Colors.white70,
            ),
            child: Text(texto),
          ),
          // AnimatedSize hace que el bloque de desglose aparezca y desaparezca
          // animando la altura, en lugar de dar un salto brusco.
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: desglose.isEmpty
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      children: [
                        // Una fila por cada bonus obtenido, con una flecha
                        // verde que indica que suma puntos.
                        for (final linea in desglose)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.arrow_upward,
                                  size: 12,
                                  color: Colors.greenAccent,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    linea,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

/// Botón grande de acción ("Deshacer", "Nueva partida").
///
/// Cuando [activo] es `false` se muestra atenuado y no responde al toque.
/// Con [destacado] en `true` usa el degradado morado-rosa para destacar
/// la acción principal.
class _BotonAccion extends StatelessWidget {
  const _BotonAccion({
    required this.icono,
    required this.etiqueta,
    required this.activo,
    required this.onTap,
    this.destacado = false,
  });

  /// Icono del botón.
  final IconData icono;

  /// Texto del botón.
  final String etiqueta;

  /// `false` deshabilita el botón visualmente y lógicamente.
  final bool activo;

  /// `true` pinta el botón con el degradado de marca.
  final bool destacado;

  /// Callback al pulsar.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: activo ? 1 : 0.35,
      child: InkWell(
        onTap: activo ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: destacado
                ? const LinearGradient(colors: [_colorJugador, _colorMaquina])
                : null,
            color: destacado ? null : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: destacado
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 19, color: Colors.white),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Capa decorativa del fondo.
///
/// Envuelve al [CustomPainter] en `IgnorePointer` para que esas manchas de
/// color no intercepten los toques destinados al juego.
class _FondoDecorativo extends StatelessWidget {
  const _FondoDecorativo();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _FondoPainter(), size: Size.infinite),
    );
  }
}

/// Dibuja tres manchas de color difuminadas en el fondo.
///
/// Usa `MaskFilter.blur` con radio 70 para lograr el efecto de glow suave.
/// Se posicionan con proporciones del tamaño de pantalla (por ejemplo
/// `size.width * 0.15`), así se adaptan a cualquier dispositivo.
class _FondoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    /// Dibuja un círculo difuminado en la posición y color indicados.
    void mancha(Offset centro, double radio, Color color) {
      final pintura = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
      canvas.drawCircle(centro, radio, pintura);
    }

    // Mancha morada arriba a la izquierda.
    mancha(
      Offset(size.width * 0.15, size.height * 0.12),
      size.width * 0.35,
      _colorJugador.withValues(alpha: 0.30),
    );
    // Mancha rosa arriba a la derecha.
    mancha(
      Offset(size.width * 0.95, size.height * 0.28),
      size.width * 0.32,
      _colorMaquina.withValues(alpha: 0.24),
    );
    // Mancha índigo abajo, más grande, para dar profundidad.
    mancha(
      Offset(size.width * 0.45, size.height * 0.95),
      size.width * 0.38,
      Colors.indigo.withValues(alpha: 0.20),
    );
  }

  /// El fondo es estático, así que no hace falta redibujarlo.
  /// Devolver `false` evita repintarlo en cada frame y ahorra batería.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}