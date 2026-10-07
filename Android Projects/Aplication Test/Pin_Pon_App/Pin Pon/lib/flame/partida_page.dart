// partida_page.dart
//
// Pantalla de partida que aloja el juego Flame ([PinPonGame]).
//
// Flame gestiona el campo, la pelota, las paletas, el input y el bucle
// de juego. Esta página se encarga de:
//   - Crear la instancia de juego con la configuración elegida.
//   - Mostrar el AppBar con botones de pausa y salida.
//   - Envolver el [GameWidget] en un AspectRatio(2) para mantener la
//     proporción 40:20 del campo original.
//   - Mostrar el diálogo de fin de partida y guardar el récord.
//
// El fin de partida se gestiona con un diálogo Flutter (en vez de un
// overlay de Flame) para que los botones "Jugar otra vez" y "Menú
// principal" naveguen de forma fiable.

import 'dart:ui' show ImageFilter;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../juego/game_config.dart';
import '../juego/partida.dart';
import '../juego/records.dart';
import 'pin_pon_game.dart';

/// Página donde se juega una partida de Pin-Pon con Flame.
class PartidaFlamePage extends StatefulWidget {
  const PartidaFlamePage({
    super.key,
    required this.modo,
    required this.dificultad,
    this.reto,
    this.nombreJ1 = 'Jugador 1',
    this.nombreJ2 = 'Jugador 2',
  });

  /// Modo de juego (dos jugadores, contra IA o reto).
  final ModoJuego modo;

  /// Dificultad seleccionada.
  final Dificultad dificultad;

  /// Reto activo, solo si `modo == ModoJuego.reto`.
  final Reto? reto;

  /// Nombre del Jugador 1 (izquierda).
  final String nombreJ1;

  /// Nombre del Jugador 2 (derecha).
  final String nombreJ2;

  @override
  State<PartidaFlamePage> createState() => _PartidaFlamePageState();
}

class _PartidaFlamePageState extends State<PartidaFlamePage> {
  /// Instancia del juego Flame. Se crea una sola vez y se reutiliza.
  late final PinPonGame _game;

  /// Evita que el diálogo de fin se muestre más de una vez.
  bool _mostrandoFin = false;

  /// Almacén de récords para guardar el resultado al terminar.
  final AlmacenRecords _almacen = AlmacenRecords();

  @override
  void initState() {
    super.initState();
    _game = PinPonGame(
      partida: Partida(
        config: GameConfig.dificultades[widget.dificultad]!,
        modo: widget.modo,
        reto: widget.reto,
        nombreJ1: widget.nombreJ1,
        nombreJ2: widget.modo == ModoJuego.contraIA
            ? 'IA'
            : widget.nombreJ2,
      ),
    );

    // Salir con la tecla Q: vuelve atrás una pantalla.
    _game.onSalir = () {
      if (mounted) Navigator.pop(context);
    };

    // Refrescar el botón de pausa del AppBar cuando cambia por teclado.
    _game.onPausaCambiada = () {
      if (mounted) setState(() {});
    };

    // Fin de partida: se delega en la página (diálogo + récord).
    _game.onFinPartida = () {
      if (_mostrandoFin) return;
      _mostrandoFin = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _mostrarFin());
    };
  }

  /// Guarda el récord y muestra el diálogo de fin de partida.
  Future<void> _mostrarFin() async {
    if (!mounted) return;
    final partida = _game.partida;

    // Guarda el resultado en el historial (no bloquea la interfaz).
    await _almacen.agregar(
      RegistroPartida(
        modo: partida.descripcion,
        j1: partida.nombreJ1,
        j2: partida.nombreJ2,
        puntosJ1: partida.p1,
        puntosJ2: partida.p2,
        duracionMs: partida.tiempoMs,
        fecha: DateTime.now().toIso8601String(),
      ),
    );

    if (!mounted) return;

    // El diálogo devuelve la acción elegida ('menu' o 'replay').
    final accion = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DialogoFin(partida: partida),
    );

    if (!mounted) return;
    if (accion == 'replay') {
      _jugarOtraVez();
    } else {
      _volverAlMenu();
    }
  }

  /// Vuelve a jugar la misma configuración.
  void _jugarOtraVez() {
    _mostrandoFin = false;
    _game.reiniciarPartida();
    setState(() {});
  }

  /// Vuelve al menú principal (primera pantalla).
  void _volverAlMenu() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_game.partida.descripcion),
        actions: [
          // Botón de pausa / continuar.
          IconButton(
            onPressed: () {
              _game.partida.alternarPausa();
              // Reconstruye el AppBar para actualizar el icono y tooltip.
              setState(() {});
            },
            icon: Icon(
              _game.partida.pausada ? Icons.play_arrow : Icons.pause,
            ),
            tooltip: _game.partida.pausada ? 'Continuar' : 'Pausa',
          ),
          // Botón de salida.
          IconButton(
            onPressed: () {
              _game.partida.detener();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.close),
            tooltip: 'Salir',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Indicación de control ─────────────────────────────
                Text(
                  _textoControles(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                ),
                const SizedBox(height: 8),

                // ── Campo de juego Flame ──────────────────────────────
                // AspectRatio(2) mantiene la proporción 40:20 del campo.
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 2,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          GameWidget<PinPonGame>(game: _game),
                          // Capa de pausa: desenfoca el campo y muestra el
                          // texto PAUSA con el mismo estilo neón del resto.
                          if (_game.partida.pausada) const _CapaPausa(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Devuelve el texto de ayuda de controles según el modo y la plataforma.
  String _textoControles() {
    if (widget.modo == ModoJuego.dosJugadores) {
      return 'Táctil: arrastra en tu mitad.  Teclado: J1 (W/S)  ·  '
          'J2 (flechas ↑/↓)  ·  Pausa (P/Esc)';
    }
    return 'Arrastra en tu mitad (o usa W/S) para mover tu paleta  ·  '
        'Pausa (P/Esc)';
  }
}

/// Capa que se muestra al pausar: desenfoca el campo de juego y dibuja el
/// texto "PAUSA" con el mismo estilo neón que el resto de la interfaz.
class _CapaPausa extends StatelessWidget {
  const _CapaPausa();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        // Desenfoque del contenido que queda detrás (el juego de Flame).
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.35),
          child: Center(
            child: Text(
              'PAUSA',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    shadows: [
                      Shadow(
                        color: colorNeon.withValues(alpha: 0.9),
                        blurRadius: 16,
                      ),
                      Shadow(
                        color: colorNeon.withValues(alpha: 0.5),
                        blurRadius: 36,
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Diálogo que se muestra al terminar la partida, con el resultado y dos
/// botones: volver a jugar o ir al menú principal.
class _DialogoFin extends StatelessWidget {
  const _DialogoFin({required this.partida});

  /// Partida terminada (para leer el mensaje y el marcador).
  final Partida partida;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF12122A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: colorNeon, width: 1.5),
      ),
      title: const Text(
        'Fin de la partida',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            partida.mensajeFinal,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Marcador: ${partida.p1} - ${partida.p2}\n'
            'Duración: ${(partida.tiempoMs / 1000).toStringAsFixed(1)} s',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('menu'),
          child: const Text('Menú principal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop('replay'),
          child: const Text('Jugar otra vez'),
        ),
      ],
    );
  }
}