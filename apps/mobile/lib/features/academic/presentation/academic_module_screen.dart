import 'package:material_ui/material_ui.dart';

class AcademicModuleScreen extends StatefulWidget {
  const AcademicModuleScreen({
    required this.title,
    required this.loadRows,
    super.key,
  });

  final String title;
  final Future<List<Map<String, dynamic>>> Function() loadRows;

  @override
  State<AcademicModuleScreen> createState() => _AcademicModuleScreenState();
}

class _AcademicModuleScreenState extends State<AcademicModuleScreen> {
  late Future<List<Map<String, dynamic>>> _rows;

  @override
  void initState() {
    super.initState();
    _rows = widget.loadRows();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: SafeArea(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _rows,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _state(
              context,
              Icons.cloud_off,
              'No se pudo cargar ${widget.title.toLowerCase()}.',
              'Comprueba la conexión e inténtalo de nuevo.',
              action: () => setState(() => _rows = widget.loadRows()),
            );
          }
          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          if (rows.isEmpty) {
            return _state(
              context,
              Icons.inbox_outlined,
              'Aún no hay información',
              'Cuando haya datos disponibles para tu cuenta, aparecerán aquí.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _rowCard(context, rows[index]),
          );
        },
      ),
    ),
  );

  Widget _rowCard(BuildContext context, Map<String, dynamic> row) {
    final titleKeys = switch (widget.title) {
      'Materias' => ['materia'],
      'Horarios' => ['actividad'],
      'Asistencia' => ['actividad'],
      'Tareas' => ['titulo'],
      'Notificaciones' => ['titulo'],
      _ => ['nombre', 'apellidos'],
    };
    final title = titleKeys
        .map((key) => row[key]?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .join(' ');
    final details = row.entries
        .where((entry) => !titleKeys.contains(entry.key) && entry.value != null)
        .map((entry) => '${_label(entry.key)}: ${_value(entry.value)}')
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                _icon,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(title.isEmpty ? widget.title : title),
              subtitle: details.isEmpty
                  ? null
                  : Text(details.take(3).join('\n')),
              isThreeLine: details.length > 1,
            ),
            if (details.length > 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(details.skip(3).join('\n')),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (widget.title) {
    'Materias' => Icons.menu_book,
    'Horarios' => Icons.calendar_month,
    'Tareas' => Icons.assignment_outlined,
    'Notificaciones' => Icons.notifications_none,
    _ => Icons.person_outline,
  };

  String _label(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');

  String _value(Object value) {
    if (value is bool) return value ? 'Sí' : 'No';
    if (value is String && value.startsWith('{')) return value;
    return value.toString();
  }

  Widget _state(
    BuildContext context,
    IconData icon,
    String title,
    String message, {
    VoidCallback? action,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: action,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    ),
  );
}
