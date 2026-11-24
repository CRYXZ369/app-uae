import 'dart:async';

import 'package:material_ui/material_ui.dart';

class TransportScreen extends StatefulWidget {
  const TransportScreen({super.key});

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  static const _routes = <_TransportRoute>[
    _TransportRoute(
      name: 'Ruta Larga',
      detail: 'Del Rodeo · Tlalnepantla–Atizapán · Nicolás Romero · UAE',
      stops: ['Del Rodeo', 'Nicolás Romero', 'Universidad UAE'],
    ),
    _TransportRoute(
      name: 'Ruta Corta',
      detail: 'El Charco · Nicolás Romero · UAE',
      stops: ['El Charco', 'Nicolás Romero', 'Universidad UAE'],
    ),
    _TransportRoute(
      name: 'Ruta Naucalpan',
      detail: 'Naucalpan · Universidad UAE',
      stops: ['Naucalpan', 'Universidad UAE'],
    ),
    _TransportRoute(
      name: 'Ruta por confirmar',
      detail: 'Recorrido pendiente de validación con la comunidad',
      stops: ['Origen por confirmar', 'Universidad UAE'],
    ),
  ];

  int _selectedRoute = 1;
  double _progress = .38;
  bool _running = true;
  Timer? _timer;

  _TransportRoute get _route => _routes[_selectedRoute];

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSimulation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || !_running) return;
      setState(() => _progress = _progress >= .96 ? .08 : _progress + .012);
    });
  }

  String get _currentStop {
    final stops = _route.stops;
    final index = (_progress * (stops.length - 1)).floor();
    return stops[index.clamp(0, stops.length - 1)];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Transporte universitario')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xfffff4d6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xffffdfa0)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xff8b5a00)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vista de demostración. La ruta se basa en el levantamiento; la unidad y su ubicación son simuladas. Horarios y paradas están pendientes de validación.',
                    style: TextStyle(color: Color(0xff684600), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Rutas disponibles',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _selectedRoute,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.route),
            ),
            items: [
              for (var i = 0; i < _routes.length; i++)
                DropdownMenuItem(value: i, child: Text(_routes[i].name)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _selectedRoute = value);
            },
          ),
          const SizedBox(height: 14),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  color: const Color(0xff2949b4),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.directions_bus, color: Colors.white),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Unidad de demostración',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .17),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'GPS SIMULADO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _route.detail,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _RouteDiagram(progress: _progress),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.my_location,
                            size: 15,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Ubicación simulada: $_currentStop',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            '${(_progress * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 7,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xffa9d4ff),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      Icon(Icons.timeline, color: colors.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Recorrido esquemático',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _running = !_running),
                        icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                        label: Text(_running ? 'Pausar' : 'Reanudar'),
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < _route.stops.length; i++)
                  _StopTile(
                    title: _route.stops[i],
                    isFirst: i == 0,
                    isLast: i == _route.stops.length - 1,
                    isCurrent: _currentStop == _route.stops[i],
                    passed: i / (_route.stops.length - 1) < _progress,
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Horarios informativos'),
              subtitle: const Text(
                'El levantamiento menciona 12:00, 3:00 y regreso a las 8:00; falta confirmar a qué salidas corresponden.',
              ),
              isThreeLine: true,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.how_to_vote_outlined),
              title: const Text('Salida UAE → El Charco · 12:00 p. m.'),
              subtitle: const Text(
                'La confirmación de esta salida forma parte del MVP. La votación y el mínimo de pasajeros aún requieren integración.',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'La confirmación de salida estará disponible en una siguiente iteración.',
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

class _TransportRoute {
  const _TransportRoute({
    required this.name,
    required this.detail,
    required this.stops,
  });
  final String name;
  final String detail;
  final List<String> stops;
}

class _RouteDiagram extends StatelessWidget {
  const _RouteDiagram({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 78,
    width: double.infinity,
    child: CustomPaint(painter: _RoutePainter(progress)),
  );
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(16, size.height - 14)
      ..cubicTo(
        size.width * .24,
        size.height * .9,
        size.width * .18,
        8,
        size.width * .47,
        26,
      )
      ..cubicTo(
        size.width * .72,
        42,
        size.width * .68,
        size.height - 4,
        size.width - 16,
        18,
      );
    final base = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, base);
    final active = Paint()
      ..color = const Color(0xffa9d4ff)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), active);
      final tangent = metric.getTangentForOffset(metric.length * progress);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 9, Paint()..color = Colors.white);
        canvas.drawCircle(
          tangent.position,
          6,
          Paint()..color = const Color(0xff5fb1ff),
        );
      }
    }
    final dot = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(16, 64), 5, dot);
    canvas.drawCircle(Offset(size.width - 16, 18), 5, dot);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.title,
    required this.isFirst,
    required this.isLast,
    required this.isCurrent,
    required this.passed,
  });
  final String title;
  final bool isFirst, isLast, isCurrent, passed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: Row(
      children: [
        SizedBox(
          width: 54,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: 2,
                  color: isFirst
                      ? Colors.transparent
                      : (passed
                            ? const Color(0xff3159c8)
                            : const Color(0xffd7dce5)),
                ),
              ),
              Icon(
                isLast ? Icons.school_outlined : Icons.circle,
                size: isLast ? 19 : 11,
                color: passed
                    ? const Color(0xff3159c8)
                    : const Color(0xffaab2c0),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : const Color(0xffd7dce5),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        if (isCurrent)
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text(
              'Unidad aquí',
              style: TextStyle(
                color: Color(0xff3159c8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    ),
  );
}
