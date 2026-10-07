// game_config.dart
//
// Configuración central del Pin-Pon: constantes del campo, dificultades,
// retos y reglas de puntuación. Migrada desde la versión de consola
// (Dart Console/Pin-Pon/lib/game_config.dart) sin cambios de lógica.

/// Nivel de dificultad seleccionable antes de empezar una partida.
enum Dificultad { facil, medio, dificil }

/// Información legible de cada dificultad para mostrar en la interfaz.
extension DificultadInfo on Dificultad {
  /// Nombre en español para mostrar en pantallas y menús.
  String get nombre {
    switch (this) {
      case Dificultad.facil:
        return 'Fácil';
      case Dificultad.medio:
        return 'Medio';
      case Dificultad.dificil:
        return 'Difícil';
    }
  }
}

/// Modo de juego elegido por el jugador.
enum ModoJuego { dosJugadores, contraIA, reto }

/// Parámetros que controlan cómo se comporta el juego en una dificultad
/// concreta: velocidad de la pelota, de las paletas, tamaño de paleta y
/// precisión de la IA.
class ConfigDificultad {
  /// Velocidad inicial de la pelota (celdas por frame).
  final double velocidadInicial;

  /// Velocidad máxima que alcanza la pelota tras acumular puntos.
  final double velocidadMaxima;

  /// Celdas que se mueve la paleta del jugador por frame al pulsar tecla.
  final int velocidadPaleta;

  /// Celdas que se mueve la paleta de la IA por frame.
  final int velocidadIA;

  /// Altura de la paleta en celdas (más grande = más fácil defender).
  final int tamanoPaleta;

  /// Margen de error aleatorio de la IA al calcular a dónde moverse.
  /// En fácil se desvía hasta ±2.5 celdas; en difícil es 0 (perfecta).
  final double margenErrorIA;

  /// Fracción del ancho del campo a partir de la cual la IA reacciona.
  /// En fácil empieza a moverse pronto (0.7); en difícil solo cerca (0.3).
  final double umbralReaccionIA;

  const ConfigDificultad({
    required this.velocidadInicial,
    required this.velocidadMaxima,
    required this.velocidadPaleta,
    required this.velocidadIA,
    required this.tamanoPaleta,
    required this.margenErrorIA,
    required this.umbralReaccionIA,
  });
}

/// Definición de un reto: objetivo que debe cumplir el jugador.
///
/// Los retos con `objetivo > 0` piden anotar esa cantidad de puntos;
/// los que solo tienen `tiempoSegundos > 0` piden sobrevivir ese tiempo.
class Reto {
  /// Identificador numérico del reto (para ordenarlos en la interfaz).
  final int id;

  /// Nombre corto del reto.
  final String nombre;

  /// Explicación de lo que hay que hacer.
  final String descripcion;

  /// Dificultad con la que se juega el reto.
  final Dificultad dificultad;

  /// Puntos que hay que anotar para completarlo (0 = no aplica).
  final int objetivo;

  /// Segundos que hay que sobrevivir para completarlo (0 = no aplica).
  final int tiempoSegundos;

  const Reto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.dificultad,
    this.objetivo = 0,
    this.tiempoSegundos = 0,
  });
}

/// Constantes y catálogos del juego, igual que en la consola.
///
/// Se mantiene como clase abstracta con solo miembros estáticos porque
/// así ya existía en el proyecto original.
abstract class GameConfig {
  // ── Dimensiones del campo ──────────────────────────────────────────

  /// Ancho del campo en celdas (columnas).
  static const int ancho = 40;

  /// Alto del campo en celdas (filas).
  static const int alto = 20;

  // ── Reglas de juego ────────────────────────────────────────────────

  /// Puntos que hay que anotar para ganar una partida normal.
  static const int puntosParaGanar = 10;

  /// Milisegundos que un jugador puede mantener pulsada la tecla antes
  /// de que la paleta deje de moverse (suaviza el control en teclado).
  /// En Flutter lo usamos como referencia de velocidad táctil.
  static const int msRetencionTecla = 150;

  /// Cuánto se acelera la pelota por cada punto anotado en la partida.
  ///
  /// Se redujo respecto a la consola (0.25) porque en pantalla el
  /// incremento se sentía demasiado brusco y hacía imposible reaccionar.
  /// Con 0.08 la pelota sube de velocidad de forma suave.
  static const double incrementoVelocidadPorPunto = 0.08;

  /// Duración de un frame del juego. En Flutter corresponde al intervalo
  /// del `Timer.periodic` que ejecuta `Partida.tick()`.
  ///
  /// Se subió de 40 ms a 50 ms (20 fps) para que la pelota vaya algo más
  /// lenta y sea más fácil devolverla.
  static const Duration frameRate = Duration(milliseconds: 50);

  // ── Catálogo de dificultades ───────────────────────────────────────

  /// Parámetros concretos de cada dificultad.
  static const Map<Dificultad, ConfigDificultad> dificultades = {
    Dificultad.facil: ConfigDificultad(
      velocidadInicial: 0.9,
      velocidadMaxima: 1.6,
      velocidadPaleta: 1,
      velocidadIA: 1,
      tamanoPaleta: 5,
      margenErrorIA: 2.5,
      umbralReaccionIA: 0.7,
    ),
    Dificultad.medio: ConfigDificultad(
      velocidadInicial: 1.0,
      velocidadMaxima: 2.2,
      velocidadPaleta: 2,
      velocidadIA: 1,
      tamanoPaleta: 4,
      margenErrorIA: 1.0,
      umbralReaccionIA: 0.55,
    ),
    Dificultad.dificil: ConfigDificultad(
      velocidadInicial: 1.1,
      velocidadMaxima: 3.0,
      velocidadPaleta: 2,
      velocidadIA: 2,
      tamanoPaleta: 3,
      margenErrorIA: 0.0,
      umbralReaccionIA: 0.3,
    ),
  };

  // ── Catálogo de retos ──────────────────────────────────────────────

  /// Lista de retos disponibles en el modo reto.
  static const List<Reto> retos = [
    Reto(
      id: 1,
      nombre: 'Calentamiento',
      descripcion: 'Anota 3 puntos contra la IA (Fácil)',
      dificultad: Dificultad.facil,
      objetivo: 3,
    ),
    Reto(
      id: 2,
      nombre: 'Ritmo',
      descripcion: 'Anota 7 puntos contra la IA (Medio)',
      dificultad: Dificultad.medio,
      objetivo: 7,
    ),
    Reto(
      id: 3,
      nombre: 'Tanque',
      descripcion: 'Gana 9 puntos contra la IA (Difícil)',
      dificultad: Dificultad.dificil,
      objetivo: 9,
    ),
    Reto(
      id: 4,
      nombre: 'Resistencia',
      descripcion: 'Sobrevive 45 segundos contra la IA (Medio)',
      dificultad: Dificultad.medio,
      tiempoSegundos: 45,
    ),
  ];
}
