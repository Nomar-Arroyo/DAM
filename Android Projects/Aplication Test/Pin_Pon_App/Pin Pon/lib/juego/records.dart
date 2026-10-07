// records.dart
//
// Historial de partidas (récords) del Pin-Pon.
//
// Guarda un registro por cada partida terminada con: modo, nombres de los
// jugadores, marcador, duración y fecha. Se usa para mostrar dos rankings:
// el de mayor puntaje y el de mayor duración.
//
// La persistencia se hace con `shared_preferences` (funciona en Android,
// iOS, web y escritorio). Si el plugin no está disponible (por ejemplo en
// algunos tests), los métodos devuelven listas vacías en lugar de fallar.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Un registro de una partida terminada.
class RegistroPartida {
  /// Descripción del modo jugado (por ejemplo "Dos jugadores").
  final String modo;

  /// Nombre del Jugador 1.
  final String j1;

  /// Nombre del Jugador 2 (o "IA").
  final String j2;

  /// Puntos anotados por el Jugador 1.
  final int puntosJ1;

  /// Puntos anotados por el Jugador 2.
  final int puntosJ2;

  /// Duración de la partida en milisegundos.
  final int duracionMs;

  /// Fecha de la partida en formato ISO 8601.
  final String fecha;

  const RegistroPartida({
    required this.modo,
    required this.j1,
    required this.j2,
    required this.puntosJ1,
    required this.puntosJ2,
    required this.duracionMs,
    required this.fecha,
  });

  /// Puntaje más alto anotado por cualquiera de los dos jugadores.
  int get puntaje => puntosJ1 > puntosJ2 ? puntosJ1 : puntosJ2;

  /// Duración en segundos (redondeada), para mostrar.
  int get duracionSegundos => (duracionMs / 1000).round();

  /// Marcador legible ("5 - 3").
  String get marcador => '$puntosJ1 - $puntosJ2';

  /// Convierte el registro a un mapa serializable a JSON.
  Map<String, dynamic> toJson() => {
        'modo': modo,
        'j1': j1,
        'j2': j2,
        'puntosJ1': puntosJ1,
        'puntosJ2': puntosJ2,
        'duracionMs': duracionMs,
        'fecha': fecha,
      };

  /// Reconstruye un registro desde un mapa JSON.
  factory RegistroPartida.fromJson(Map<String, dynamic> json) => RegistroPartida(
        modo: json['modo'] as String? ?? '',
        j1: json['j1'] as String? ?? '',
        j2: json['j2'] as String? ?? '',
        puntosJ1: (json['puntosJ1'] as num?)?.toInt() ?? 0,
        puntosJ2: (json['puntosJ2'] as num?)?.toInt() ?? 0,
        duracionMs: (json['duracionMs'] as num?)?.toInt() ?? 0,
        fecha: json['fecha'] as String? ?? '',
      );
}

/// Guarda y recupera el historial de récords.
class AlmacenRecords {
  /// Clave bajo la que se guarda la lista en `shared_preferences`.
  static const String _clave = 'records_pinpon';

  /// Número máximo de partidas que se conservan en el historial.
  static const int _maximo = 50;

  /// Carga el historial completo (de más antigua a más reciente).
  ///
  /// Si algo falla (plugin no disponible o JSON corrupto) devuelve `[]`.
  Future<List<RegistroPartida>> cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(_clave);
      if (texto == null || texto.isEmpty) return [];
      final lista = jsonDecode(texto) as List<dynamic>;
      return lista
          .map((e) => RegistroPartida.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Añade un registro al historial, conservando solo los [_maximo] últimos.
  Future<void> agregar(RegistroPartida registro) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actuales = await cargar();
      actuales.add(registro);
      final recortada = actuales.length > _maximo
          ? actuales.sublist(actuales.length - _maximo)
          : actuales;
      await prefs.setString(
        _clave,
        jsonEncode(recortada.map((r) => r.toJson()).toList()),
      );
    } catch (_) {
      // Si no se puede guardar, se ignora: el juego sigue funcionando.
    }
  }

  /// Borra todo el historial.
  Future<void> limpiar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_clave);
    } catch (_) {
      // Ignorado a propósito.
    }
  }
}