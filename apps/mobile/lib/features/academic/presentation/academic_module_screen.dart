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

  void _reload() => setState(() => _rows = widget.loadRows());

  Future<void> _refresh() async {
    final future = widget.loadRows();
    setState(() => _rows = future);
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _reload,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
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
              action: _reload,
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
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                if (widget.title == 'Asistencia') ...[
                  _attendanceSummary(rows),
                  const SizedBox(height: 12),
                ],
                for (var i = 0; i < rows.length; i++) ...[
                  _buildCard(context, rows[i]),
                  if (i < rows.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
    ),
  );

  Widget _attendanceSummary(List<Map<String, dynamic>> rows) {
    final attended = rows.where((row) {
      final status = row['estado']?.toString().toUpperCase() ?? '';
      return status == 'PRESENTE' ||
          status == 'RETARDO' ||
          status == 'JUSTIFICADO';
    }).length;
    final pct = ((attended / rows.length) * 100).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff19395f), Color(0xff28548d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen de asistencia',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pct% de asistencia',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$attended de ${rows.length} sesiones registradas',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              pct >= 80 ? 'Óptima' : 'En revisión',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> row) {
    return switch (widget.title) {
      'Materias' => _subjectCard(row),
      'Horarios' => _scheduleCard(row),
      'Asistencia' => _attendanceCard(row),
      'Notificaciones' => _notificationCard(row),
      _ => _genericCard(context, row),
    };
  }

  Widget _subjectCard(Map<String, dynamic> row) {
    final name = row['materia']?.toString() ?? 'Materia';
    final code = row['codigo']?.toString() ?? '';
    final teacher = row['docente']?.toString() ?? '';
    final group = row['grupo']?.toString() ?? '';
    final semester = row['semestre']?.toString() ?? '';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (code.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffeaf1ff),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        color: Color(0xff214b78),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const Spacer(),
                if (group.isNotEmpty || semester.isNotEmpty)
                  Text(
                    [
                      if (semester.isNotEmpty) '$semester.º Sem.',
                      if (group.isNotEmpty) group,
                    ].join(' · '),
                    style: const TextStyle(
                      color: Color(0xff6b7a90),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xff1e3553),
              ),
            ),
            if (teacher.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Color(0xff6b7a90),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      teacher,
                      style: const TextStyle(
                        color: Color(0xff42546b),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _scheduleCard(Map<String, dynamic> row) {
    final day = row['dia']?.toString() ?? '';
    final start = _shortTime(row['hora_inicio']?.toString() ?? '');
    final end = _shortTime(row['hora_fin']?.toString() ?? '');
    final activity = row['actividad']?.toString() ?? 'Clase';
    final teacher = row['docente']?.toString() ?? '';
    final room = row['aula']?.toString() ?? '';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 84,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xffeaf1ff),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff214b78),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$start\n$end',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff1e3553),
                      height: 1.25,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff1e3553),
                    ),
                  ),
                  if (teacher.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      teacher,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xff5b6b80),
                      ),
                    ),
                  ],
                  if (room.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xfff1f5f9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        room,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff334155),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attendanceCard(Map<String, dynamic> row) {
    final activity = row['actividad']?.toString() ?? 'Sesión';
    final status = row['estado']?.toString().toUpperCase() ?? 'SIN_REGISTRO';
    final date = row['fecha_clase']?.toString() ?? '';
    final day = row['dia']?.toString() ?? '';
    final start = _shortTime(row['hora_inicio']?.toString() ?? '');
    final (bg, fg, label) = switch (status) {
      'PRESENTE' => (
        const Color(0xffe8f5ed),
        const Color(0xff27845a),
        'Presente',
      ),
      'RETARDO' => (
        const Color(0xfffff4d6),
        const Color(0xff8b5a00),
        'Retardo',
      ),
      'JUSTIFICADO' => (
        const Color(0xffeaf1ff),
        const Color(0xff214b78),
        'Justificado',
      ),
      _ => (const Color(0xfffdecec), const Color(0xffb42318), 'Falta'),
    };
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          activity,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xff1e3553),
          ),
        ),
        subtitle: Text(
          [
            if (day.isNotEmpty) day,
            if (date.isNotEmpty) date,
            if (start.isNotEmpty) start,
          ].join(' · '),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _notificationCard(Map<String, dynamic> row) {
    final title = row['titulo']?.toString() ?? 'Aviso';
    final message = row['mensaje']?.toString() ?? '';
    final type = row['tipo']?.toString() ?? 'Aviso';
    final read = row['leida'] == true;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffeaf1ff),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    type,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff214b78),
                    ),
                  ),
                ),
                const Spacer(),
                if (!read)
                  const Icon(Icons.circle, size: 10, color: Color(0xff2563eb)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xff1e3553),
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(color: Color(0xff42546b), height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _genericCard(BuildContext context, Map<String, dynamic> row) {
    final titleKeys = ['nombre', 'apellidos', 'titulo'];
    final title = titleKeys
        .map((key) => row[key]?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .join(' ');
    final details = row.entries
        .where((entry) => !titleKeys.contains(entry.key) && entry.value != null)
        .map((entry) => '${_label(entry.key)}: ${_value(entry.value)}')
        .toList();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(title.isEmpty ? widget.title : title),
          subtitle: details.isEmpty ? null : Text(details.join('\n')),
        ),
      ),
    );
  }

  String _shortTime(String raw) {
    final parts = raw.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return raw;
  }

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
