// ===========================================================================
// PIN-PON - Aplicación Flutter multiplataforma con Flame
// ===========================================================================
// Juego de Pin-Pon (Pong) migrado desde la versión de consola en Dart.
// Se juega tocando y arrastrando el dedo en tu mitad del campo para mover
// la paleta. También admite dos jugadores en el mismo dispositivo.
//
// MODOS
//   - Dos jugadores: cada uno controla su paleta (izq. y der.), con
//     nombres personalizados. Teclado: J1 (W/S), J2 (flechas ↑/↓).
//   - Contra la IA: la paleta derecha la controla la computadora.
//   - Retos: objetivos puntuales (anotar X puntos o sobrevivir Y segundos).
//
// DIFICULTADES
//   - Fácil: paletas grandes, pelota lenta, IA imprecisa.
//   - Medio: equilibrado.
//   - Difícil: paletas pequeñas, pelota rápida, IA casi perfecta.
//
// ARQUITECTURA
//   - lib/juego/        Lógica pura del juego (sin Flame ni Flutter):
//                       entities, game_config, ai, partida, records.
//   - lib/flame/        Juego Flame: PinPonGame (bucle, input, componentes)
//                       y PartidaFlamePage (página que aloja el GameWidget).
//   - lib/main.dart     Punto de entrada y pantallas de menú (Flutter).
// ===========================================================================

import 'package:flutter/material.dart';

import 'flame/partida_page.dart';
import 'juego/game_config.dart';
import 'juego/records.dart';

/// Punto de entrada. Lanza la aplicación.
void main() {
  runApp(const PinPonApp());
}

// ── Paleta neón de la interfaz ─────────────────────────────────────────

/// Color neón principal (cian).
const Color colorNeon = Color(0xFF35E8FF);

/// Morado del Jugador 1 (también usado como color semilla).
const Color colorMorado = Color(0xFF7C6BFF);

/// Rosa del Jugador 2.
const Color colorRosa = Color(0xFFFF6B8A);

/// Fondo oscuro de las pantallas.
const Color colorFondo = Color(0xFF07070F);

/// Devuelve un estilo de texto con resplandor neón del color indicado.
TextStyle neon(TextStyle base, Color color) => base.copyWith(
      shadows: [
        Shadow(color: color.withValues(alpha: 0.8), blurRadius: 12),
        Shadow(color: color.withValues(alpha: 0.5), blurRadius: 28),
      ],
    );

/// Widget raíz de la aplicación.
class PinPonApp extends StatelessWidget {
  const PinPonApp({super.key});

  @override
  Widget build(BuildContext context) {
    final esquema = ColorScheme.fromSeed(
      seedColor: colorNeon,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'Pin-Pon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: esquema,
        scaffoldBackgroundColor: colorFondo,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0C0C1E),
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF12122A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: colorNeon.withValues(alpha: 0.35)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: colorNeon.withValues(alpha: 0.18),
            foregroundColor: Colors.white,
            side: const BorderSide(color: colorNeon),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: colorMorado),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: colorNeon, width: 2),
          ),
        ),
      ),
      home: const InicioPage(),
    );
  }
}

// ===========================================================================
// PANTALLA DE INICIO
// ===========================================================================

/// Pantalla inicial: elige el modo de juego.
class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Título del juego con resplandor neón.
                Text(
                  'PIN-PON',
                  textAlign: TextAlign.center,
                  style: neon(
                    Theme.of(context).textTheme.displayLarge!.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                          color: Colors.white,
                        ),
                    colorNeon,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Migrado desde la consola en Dart',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white54,
                      ),
                ),
                const SizedBox(height: 40),

                // Botón: dos jugadores en el mismo dispositivo.
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NombresPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('Dos jugadores'),
                ),
                const SizedBox(height: 12),

                // Botón: contra la IA.
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DificultadPage(
                          modo: ModoJuego.contraIA,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.smart_toy),
                  label: const Text('Contra la IA'),
                ),
                const SizedBox(height: 12),

                // Botón: retos.
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RetosPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('Retos'),
                ),
                const SizedBox(height: 12),

                // Botón: historial de récords.
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RecordsPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.leaderboard),
                  label: const Text('Récords'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// PANTALLA DE NOMBRES (modo dos jugadores)
// ===========================================================================

/// Pantalla para registrar los nombres de los dos jugadores.
class NombresPage extends StatefulWidget {
  const NombresPage({super.key});

  @override
  State<NombresPage> createState() => _NombresPageState();
}

class _NombresPageState extends State<NombresPage> {
  /// Controladores de los campos de texto de cada jugador.
  final _controlJ1 = TextEditingController();
  final _controlJ2 = TextEditingController();

  @override
  void dispose() {
    _controlJ1.dispose();
    _controlJ2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dos jugadores')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nombre de los jugadores',
                  textAlign: TextAlign.center,
                  style: neon(
                    Theme.of(context).textTheme.titleLarge ?? const TextStyle(),
                    colorNeon,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controlJ1,
                  decoration: const InputDecoration(
                    labelText: 'Jugador 1 (izquierda)',
                    hintText: 'Jugador 1',
                    prefixIcon: Icon(Icons.person, color: colorMorado),
                  ),
                  maxLength: 16,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _controlJ2,
                  decoration: const InputDecoration(
                    labelText: 'Jugador 2 (derecha)',
                    hintText: 'Jugador 2',
                    prefixIcon: Icon(Icons.person, color: colorRosa),
                  ),
                  maxLength: 16,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DificultadPage(
                          modo: ModoJuego.dosJugadores,
                          nombreJ1: _controlJ1.text,
                          nombreJ2: _controlJ2.text,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continuar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// PANTALLA DE DIFICULTAD
// ===========================================================================

/// Pantalla para elegir la dificultad antes de empezar una partida.
class DificultadPage extends StatelessWidget {
  const DificultadPage({
    super.key,
    required this.modo,
    this.nombreJ1 = 'Jugador 1',
    this.nombreJ2 = 'Jugador 2',
  });

  /// Modo de juego seleccionado en la pantalla anterior.
  final ModoJuego modo;

  /// Nombre del Jugador 1 (solo en dos jugadores).
  final String nombreJ1;

  /// Nombre del Jugador 2 (solo en dos jugadores).
  final String nombreJ2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(modo == ModoJuego.contraIA
          ? 'Contra la IA'
          : 'Dos jugadores')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Elige la dificultad',
                  textAlign: TextAlign.center,
                  style: neon(
                    Theme.of(context).textTheme.titleLarge ?? const TextStyle(),
                    colorNeon,
                  ),
                ),
                const SizedBox(height: 24),
                for (final d in Dificultad.values) ...[
                  FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PartidaFlamePage(
                            modo: modo,
                            dificultad: d,
                            nombreJ1: nombreJ1,
                            nombreJ2: nombreJ2,
                          ),
                        ),
                      );
                    },
                    child: Text(d.nombre),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// PANTALLA DE RETOS
// ===========================================================================

/// Pantalla que lista los retos disponibles.
class RetosPage extends StatelessWidget {
  const RetosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retos')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: GameConfig.retos.length,
            itemBuilder: (context, index) {
              final reto = GameConfig.retos[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorNeon.withValues(alpha: 0.2),
                    child: Text(
                      '${reto.id}',
                      style: const TextStyle(color: colorNeon),
                    ),
                  ),
                  title: Text(reto.nombre),
                  subtitle: Text(reto.descripcion),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PartidaFlamePage(
                          modo: ModoJuego.reto,
                          dificultad: reto.dificultad,
                          reto: reto,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// PANTALLA DE RÉCORDS
// ===========================================================================

/// Pantalla con el historial de partidas: mayor puntaje y mayor duración.
class RecordsPage extends StatefulWidget {
  const RecordsPage({super.key});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  /// Almacén de récords.
  final AlmacenRecords _almacen = AlmacenRecords();

  /// Futuro con la lista de récords cargada.
  late Future<List<RegistroPartida>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _almacen.cargar();
  }

  /// Vuelve a cargar el historial.
  void _recargar() {
    setState(() => _futuro = _almacen.cargar());
  }

  /// Pide confirmación y borra todo el historial.
  Future<void> _borrar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF12122A),
        title: const Text('Borrar récords'),
        content: const Text('¿Seguro que quieres borrar todo el historial?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await _almacen.limpiar();
      _recargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Récords'),
          actions: [
            IconButton(
              onPressed: _borrar,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Borrar historial',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mayor puntaje'),
              Tab(text: 'Mayor tiempo'),
            ],
          ),
        ),
        body: FutureBuilder<List<RegistroPartida>>(
          future: _futuro,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final registros = snapshot.data ?? [];
            if (registros.isEmpty) {
              return const Center(
                child: Text('Todavía no hay partidas registradas'),
              );
            }

            return TabBarView(
              children: [
                // Ranking por puntaje (mayor primero).
                _ListaRegistros(
                  registros: [...registros]
                    ..sort((a, b) => b.puntaje.compareTo(a.puntaje)),
                  valor: (r) => '${r.puntaje} pts',
                  color: colorRosa,
                ),
                // Ranking por duración (mayor primero).
                _ListaRegistros(
                  registros: [...registros]
                    ..sort((a, b) => b.duracionMs.compareTo(a.duracionMs)),
                  valor: (r) => '${r.duracionSegundos} s',
                  color: colorNeon,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Lista de registros genérica con un valor y color destacados.
class _ListaRegistros extends StatelessWidget {
  const _ListaRegistros({
    required this.registros,
    required this.valor,
    required this.color,
  });

  final List<RegistroPartida> registros;
  final String Function(RegistroPartida) valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: registros.length,
      itemBuilder: (context, index) {
        final r = registros[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              child: Text('${index + 1}', style: TextStyle(color: color)),
            ),
            title: Text('${r.j1}  vs  ${r.j2}'),
            subtitle: Text('${r.modo}  ·  Marcador ${r.marcador}'),
            trailing: Text(
              valor(r),
              style: neon(
                Theme.of(context).textTheme.titleMedium ?? const TextStyle(),
                color,
              ),
            ),
          ),
        );
      },
    );
  }
}