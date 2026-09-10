enum Dificultad { facil, medio, dificil }

extension DificultadInfo on Dificultad {
  String get nombre {
    switch (this) {
      case Dificultad.facil:
        return 'Facil';
      case Dificultad.medio:
        return 'Medio';
      case Dificultad.dificil:
        return 'Dificil';
    }
  }
}

enum ModoJuego { dosJugadores, contraIA, reto }

class ConfigDificultad {
  final double velocidadInicial;
  final double velocidadMaxima;
  final int velocidadPaleta;
  final int velocidadIA;
  final int tamanoPaleta;
  final double margenErrorIA;
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

class Reto {
  final int id;
  final String nombre;
  final String descripcion;
  final Dificultad dificultad;
  final int objetivo;
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

abstract class GameConfig {
  static const int ancho = 40;
  static const int alto = 20;
  static const int puntosParaGanar = 10;
  static const int msRetencionTecla = 150;
  static const double incrementoVelocidadPorPunto = 0.25;
  static const Duration frameRate = Duration(milliseconds: 40);

  static const Map<Dificultad, ConfigDificultad> dificultades = {
    Dificultad.facil: ConfigDificultad(
      velocidadInicial: 1,
      velocidadMaxima: 2,
      velocidadPaleta: 1,
      velocidadIA: 1,
      tamanoPaleta: 5,
      margenErrorIA: 2.5,
      umbralReaccionIA: 0.7,
    ),
    Dificultad.medio: ConfigDificultad(
      velocidadInicial: 1,
      velocidadMaxima: 4,
      velocidadPaleta: 2,
      velocidadIA: 1,
      tamanoPaleta: 4,
      margenErrorIA: 1.0,
      umbralReaccionIA: 0.55,
    ),
    Dificultad.dificil: ConfigDificultad(
      velocidadInicial: 2,
      velocidadMaxima: 6,
      velocidadPaleta: 2,
      velocidadIA: 2,
      tamanoPaleta: 3,
      margenErrorIA: 0.0,
      umbralReaccionIA: 0.3,
    ),
  };

  static const List<Reto> retos = [
    Reto(
      id: 1,
      nombre: 'Calentamiento',
      descripcion: 'Anota 3 puntos contra la IA (Facil)',
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
      descripcion: 'Gana 9 puntos contra la IA (Dificil)',
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