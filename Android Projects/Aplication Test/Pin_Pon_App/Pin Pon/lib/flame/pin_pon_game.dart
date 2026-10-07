// pin_pon_game.dart
//
// Juego de Pin-Pon implementado con Flame.
//
// Flame se encarga del bucle de juego (update/render), del input táctil y
// de teclado, y del sistema de componentes. La lógica pura del juego
// vive en lib/juego/partida.dart (sin dependencias de Flame ni Flutter);
// esta clase solo la "mueve" y dibuja.
//
// Componentes:
//   - CampoComponent: fondo del campo + línea central + captura de drag.
//   - PelotaComponent: dibuja la pelota, sincronizada con Partida.
//   - PaletaComponent: dibuja una paleta (J1 o J2), sincronizada con Partida.
//   - MarcadorComponent: texto con el marcador actual.
//   - PausaComponent: aviso de pausa visible solo cuando está pausado.

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../juego/game_config.dart';
import '../juego/partida.dart';

// ── Colores del juego (paleta neón sobre fondo oscuro) ──────────────

/// Color base de la paleta del Jugador 1 (izquierda).
const Color colorJ1 = Color(0xFF7C6BFF);

/// Color base de la paleta del Jugador 2 / IA (derecha).
const Color colorJ2 = Color(0xFFFF6B8A);

/// Color de la pelota.
const Color colorPelota = Color(0xFFFFFFFF);

/// Fondo del campo de juego (casi negro azulado).
const Color colorCampo = Color(0xFF07070F);

/// Color neón del borde y la línea central del campo (cian).
const Color colorNeon = Color(0xFF35E8FF);

/// Devuelve una versión con brillo del [color] usando un desenfoque.
///
/// Se usa para dibujar el "halo" neón detrás de cada figura. El parámetro
/// [sigma] controla el radio del resplandor.
Paint pinturaNeon(Color color, double sigma) => Paint()
  ..color = color.withValues(alpha: 0.9)
  ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

/// Clase principal del juego Pin-Pon con Flame.
///
/// Extiende [FlameGame] y mezcla [KeyboardEvents] para recibir teclas.
/// No mezcla [HasKeyboardHandlerComponents] porque el manejo de teclado
/// se hace directamente en el juego (más simple para este caso).
class PinPonGame extends FlameGame with KeyboardEvents {
  /// Crea el juego con una partida ya configurada.
  PinPonGame({required this.partida});

  /// Lógica de la partida (fuente de verdad del estado del juego).
  final Partida partida;

  /// Teclas actualmente pulsadas, actualizadas en cada evento de teclado.
  /// Se procesan una vez por frame de juego (cada 40 ms) para mover paletas.
  Set<LogicalKeyboardKey> _teclasPulsadas = {};

  /// Acumulador de tiempo para ejecutar tick() a cadencia fija (40 ms).
  /// Flame llama a update(dt) con dt variable (segundos); nosotros
  /// acumulamos y solo llamamos a tick() cuando pasa un frame de juego.
  double _tiempoAcumulado = 0;

  /// Duración de un frame de juego en segundos, tomada de [GameConfig].
  /// Así el ritmo lógico y el visual nunca se desincronizan.
  double get _duracionFrame => GameConfig.frameRate.inMilliseconds / 1000.0;

  /// Callback invocado cuando el jugador pulsa Q (salir).
  /// La página que aloja el juego lo asigna para navegar hacia atrás.
  VoidCallback? onSalir;

  /// Callback invocado una sola vez cuando la partida termina.
  /// La página lo usa para mostrar el diálogo de fin y guardar el récord.
  VoidCallback? onFinPartida;

  /// Callback invocado cuando cambia el estado de pausa (por teclado o
  /// al reiniciar), para que la página refresque el botón del AppBar.
  VoidCallback? onPausaCambiada;

  /// Evita notificar el final de la partida más de una vez.
  bool _finNotificado = false;

  /// Tamaño de una celda del campo en píxeles.
  ///
  /// El campo mide 40 x 20 celdas y el widget se dimensiona con
  /// AspectRatio(2), así que ancho/alto de celda son iguales.
  double get celda => size.x / GameConfig.ancho;

  @override
  Future<void> onLoad() async {
    // Añade todos los componentes visuales al árbol del juego.
    add(CampoComponent());
    add(PaletaComponent(esJ1: true));
    add(PaletaComponent(esJ1: false));
    add(PelotaComponent());
    add(NombresComponent());
    add(MarcadorComponent());
    add(RetoProgresoComponent());
  }

  @override
  void update(double dt) {
    // Solo avanza la partida si está activa y no pausada.
    if (partida.activa && !partida.pausada) {
      _procesarTeclado();
      _tiempoAcumulado += dt;
      while (_tiempoAcumulado >= _duracionFrame) {
        final evento = partida.tick();
        _tiempoAcumulado -= _duracionFrame;
        if (evento == EventoPartida.fin) {
          // La partida terminó: avisa a la página (una sola vez) para que
          // muestre el diálogo de fin y guarde el récord.
          if (!_finNotificado) {
            _finNotificado = true;
            onFinPartida?.call();
          }
          break;
        }
      }
    }

    super.update(dt);
  }

  /// Procesa las teclas pulsadas: mueve paletas una vez por frame.
  ///
  /// Controles:
  ///   - Jugador 1: W (arriba) y S (abajo), estilo WASD.
  ///   - Jugador 2: flecha arriba y flecha abajo (solo en dos jugadores).
  void _procesarTeclado() {
    final t = _teclasPulsadas;
    if (t.contains(LogicalKeyboardKey.keyW)) partida.moverJ1Arriba();
    if (t.contains(LogicalKeyboardKey.keyS)) partida.moverJ1Abajo();
    if (t.contains(LogicalKeyboardKey.arrowUp)) partida.moverJ2Arriba();
    if (t.contains(LogicalKeyboardKey.arrowDown)) partida.moverJ2Abajo();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _teclasPulsadas = keysPressed;

    // Acciones que solo deben ocurrir al pulsar (no al mantener).
    if (event is KeyDownEvent) {
      // P o Esc: pausar / continuar de inmediato.
      if (event.logicalKey == LogicalKeyboardKey.keyP ||
          event.logicalKey == LogicalKeyboardKey.escape) {
        partida.alternarPausa();
        onPausaCambiada?.call();
      }
      if (event.logicalKey == LogicalKeyboardKey.keyQ) {
        partida.detener();
        onSalir?.call();
      }
    }
    return KeyEventResult.handled;
  }

  /// Reinicia la partida para jugar otra vez (llamado desde el diálogo).
  void reiniciarPartida() {
    _tiempoAcumulado = 0;
    _teclasPulsadas = {};
    _finNotificado = false;
    partida.reiniciar();
  }
}

// ===========================================================================
// COMPONENTES
// ===========================================================================

/// Fondo del campo: rectángulo oscuro + línea central discontinua.
///
/// También captura los gestos de arrastre (drag) para mover las paletas:
/// arrastrar en la mitad izquierda mueve al J1, en la derecha al J2 (o
/// solo al J1 si es contra IA).
class CampoComponent extends RectangleComponent
    with HasGameReference<PinPonGame>, DragCallbacks {
  CampoComponent()
      : super(
          position: Vector2.zero(),
          paint: Paint()..color = colorCampo,
        );

  /// Pinceles reutilizables para no crear uno nuevo en cada frame.
  /// Línea central: una versión con brillo (neón) y otra nítida encima.
  static final Paint _pinceLineaGlow = Paint()
    ..color = colorNeon.withValues(alpha: 0.8)
    ..strokeWidth = 6
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  static final Paint _pinceLinea = Paint()
    ..color = Colors.white70
    ..strokeWidth = 2;

  /// Borde del campo: halo neón + trazo brillante.
  static final Paint _pinceBordeGlow = Paint()
    ..color = colorNeon.withValues(alpha: 0.8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

  static final Paint _pinceBorde = Paint()
    ..color = colorNeon
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  Future<void> onLoad() async {
    // El rectángulo ocupa todo el lienzo del juego.
    size.setFrom(game.size);
  }

  @override
  void render(Canvas canvas) {
    final rect = Offset.zero & size.toSize();

    // Fondo oscuro (con un degradado sutil para dar profundidad).
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF101024), colorCampo],
        ).createShader(rect),
    );

    // Línea central discontinua: primero el halo, luego el trazo nítido.
    final mitad = size.x / 2;
    double y = 0;
    while (y < size.y) {
      canvas.drawLine(Offset(mitad, y), Offset(mitad, y + 12), _pinceLineaGlow);
      y += 24;
    }
    y = 0;
    while (y < size.y) {
      canvas.drawLine(Offset(mitad, y), Offset(mitad, y + 12), _pinceLinea);
      y += 24;
    }

    // Borde del campo con resplandor neón.
    canvas.drawRect(rect, _pinceBordeGlow);
    canvas.drawRect(rect, _pinceBorde);
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    // Captura todos los toques dentro del campo para el drag.
    return point.x >= 0 && point.x <= size.x && point.y >= 0 && point.y <= size.y;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    // Posición actual del dedo en coordenadas del lienzo Flame.
    final pos = event.canvasEndPosition;
    final fila = (pos.y / game.size.y) * GameConfig.alto;

    if (pos.x < game.size.x / 2) {
      // Mitad izquierda: controla al J1.
      game.partida.moverJ1A(fila);
    } else {
      // Mitad derecha: controla al J2 (en dos jugadores; la partida
      // ignora el movimiento si es contra IA).
      game.partida.moverJ2A(fila);
    }
  }
}

/// Marcador central del juego: muestra los puntos con brillo neón.
class MarcadorComponent extends TextComponent
    with HasGameReference<PinPonGame> {
  MarcadorComponent()
      : super(
          text: '0 - 0',
          anchor: Anchor.topCenter,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              shadows: [
                Shadow(color: colorNeon, blurRadius: 16),
                Shadow(color: colorNeon, blurRadius: 32),
              ],
            ),
          ),
        );

  @override
  void update(double dt) {
    final partida = game.partida;
    // Se muestra el marcador como "J1 - J2" en el centro de arriba.
    position.setValues(game.size.x / 2, 4);
    text = '${partida.p1}  -  ${partida.p2}';
  }
}

/// Nombres de los jugadores en las esquinas superiores del campo.
///
/// Se dibujan directamente con [TextPaint] para no crear dos componentes.
class NombresComponent extends PositionComponent
    with HasGameReference<PinPonGame> {
  NombresComponent() : super(position: Vector2.zero());

  /// Pincel del nombre del Jugador 1 (morado neón).
  static final TextPaint _paintJ1 = TextPaint(
    style: const TextStyle(
      color: colorJ1,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
      shadows: [Shadow(color: colorJ1, blurRadius: 10)],
    ),
  );

  /// Pincel del nombre del Jugador 2 (rosa neón).
  static final TextPaint _paintJ2 = TextPaint(
    style: const TextStyle(
      color: colorJ2,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      letterSpacing: 1,
      shadows: [
        Shadow(color: colorJ2, blurRadius: 16),
        Shadow(color: colorJ2, blurRadius: 32),
      ],
    ),
  );

  @override
  void render(Canvas canvas) {
    final partida = game.partida;
    final margen = game.celda * 0.6;
    _paintJ1.render(canvas, partida.nombreJ1, Vector2(12, 8));
    // El nombre del Jugador 2 se alinea a la derecha.
    final anchoJ2 = _paintJ2.getLineMetrics(partida.nombreJ2).width;
    _paintJ2.render(
      canvas,
      partida.nombreJ2,
      Vector2(game.size.x - anchoJ2 - margen, 8),
    );
  }
}

/// Pelota del juego: círculo blanco con halo neón cuya posición se
/// sincroniza con [Partida.pelota] en cada frame.
class PelotaComponent extends CircleComponent
    with HasGameReference<PinPonGame> {
  PelotaComponent()
      : super(
          radius: 1,
          anchor: Anchor.center,
          paint: Paint()..color = colorPelota,
        );

  /// Pincel del resplandor de la pelota (cian blanquecino).
  static final Paint _pinceGlow = Paint()
    ..color = const Color(0xFFBFEFFF).withValues(alpha: 0.95)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

  @override
  void update(double dt) {
    final pelota = game.partida.pelota;
    // Radio = 45% de una celda (ligeramente más pequeño que la celda).
    radius = game.celda * 0.45;
    position.setValues(
      (pelota.x + 0.5) * game.celda,
      (pelota.y + 0.5) * game.celda,
    );
  }

  @override
  void render(Canvas canvas) {
    // Halo neón detrás de la pelota (el centro local es (radius, radius)).
    final centro = Offset(radius, radius);
    canvas.drawCircle(centro, radius + 2, _pinceGlow);
    super.render(canvas);
  }
}

/// Paleta de un jugador: rectángulo con brillo neón cuya posición y tamaño
/// se sincronizan con [Partida.j1] o [Partida.j2].
class PaletaComponent extends RectangleComponent
    with HasGameReference<PinPonGame> {
  /// Crea la paleta. `esJ1` = izquierda (morada), `false` = derecha (rosa).
  PaletaComponent({required this.esJ1})
      : super(
          position: Vector2.zero(),
          size: Vector2.all(1),
          paint: Paint()..color = esJ1 ? colorJ1 : colorJ2,
        );

  /// `true` si es la paleta del Jugador 1 (izquierda).
  final bool esJ1;

  @override
  void update(double dt) {
    final partida = game.partida;
    final paleta = esJ1 ? partida.j1 : partida.j2;
    final celda = game.celda;

    position.setValues(paleta.x * celda, paleta.y * celda);
    size.setValues(celda * 0.9, paleta.alto * celda);
  }

  @override
  void render(Canvas canvas) {
    // Resplandor neón del mismo color que la paleta.
    final color = esJ1 ? colorJ1 : colorJ2;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size.toSize(),
      Radius.circular(size.x / 2),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    // La paleta sólida encima del resplandor.
    canvas.drawRRect(rect, Paint()..color = color);
    // Brillo interior para dar aspecto de tubo de neón.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.25, size.y * 0.06, size.x * 0.5, size.y * 0.88),
        Radius.circular(size.x / 4),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }
}

/// Indicador de progreso del reto: solo visible en modo reto.
/// Muestra "3 / 7 pts" o "12 / 45 s" según el tipo de reto.
class RetoProgresoComponent extends TextComponent
    with HasGameReference<PinPonGame>, HasVisibility {
  RetoProgresoComponent()
      : super(
          text: '',
          anchor: Anchor.bottomCenter,
          position: Vector2.zero(),
          textRenderer: TextPaint(
            style: const TextStyle(
              color: colorJ1,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

  @override
  void update(double dt) {
    final p = game.partida;
    // Solo se muestra en modo reto y mientras la partida siga activa.
    final esReto = p.modo == ModoJuego.reto && p.reto != null;
    isVisible = esReto && p.activa;
    if (esReto) {
      text = p.progresoReto;
      // Centrado abajo, justo por encima del borde inferior.
      position.setValues(game.size.x / 2, game.size.y - game.celda * 0.3);
    }
  }
}
