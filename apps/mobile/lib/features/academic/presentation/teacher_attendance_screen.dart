import 'package:material_ui/material_ui.dart';

typedef AttendanceRosterLoader = Future<List<Map<String, dynamic>>> Function(
  int scheduleId,
  DateTime date,
);
typedef AttendanceSaver = Future<void> Function(
  int scheduleId,
  int studentId,
  DateTime date,
  String status,
);

class TeacherAttendanceScreen extends StatelessWidget {
  const TeacherAttendanceScreen({
    required this.loadSessions,
    required this.loadRoster,
    required this.saveAttendance,
    super.key,
  });

  final Future<List<Map<String, dynamic>>> Function() loadSessions;
  final AttendanceRosterLoader loadRoster;
  final AttendanceSaver saveAttendance;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Asistencia')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: loadSessions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('No se pudieron cargar tus grupos.'));
        }
        final sessions = snapshot.data ?? const [];
        if (sessions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No hay horarios asignados a tu cuenta docente.'),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final session = sessions[index];
            final scheduleId = (session['id_horario'] as num).toInt();
            return Card(
              child: ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: Text(session['actividad']?.toString() ?? 'Clase'),
                subtitle: Text(
                  '${session['grupo']} · ${session['dia']} · '
                  '${session['hora_inicio']}–${session['hora_fin']} · '
                  '${session['alumnos']} estudiantes',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _RosterScreen(
                      session: session,
                      loadRoster: (date) => loadRoster(scheduleId, date),
                      save: (studentId, date, status) =>
                          saveAttendance(scheduleId, studentId, date, status),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

class _RosterScreen extends StatefulWidget {
  const _RosterScreen({
    required this.session,
    required this.loadRoster,
    required this.save,
  });
  final Map<String, dynamic> session;
  final Future<List<Map<String, dynamic>>> Function(DateTime date) loadRoster;
  final Future<void> Function(int studentId, DateTime date, String status) save;

  @override
  State<_RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<_RosterScreen> {
  static const statuses = ['PRESENTE', 'RETARDO', 'FALTA', 'JUSTIFICADO'];
  late DateTime _date = _dateForDay(widget.session['dia']?.toString());
  late Future<List<Map<String, dynamic>>> _roster = widget.loadRoster(_date);
  final Map<int, String> _changes = {};
  bool _saving = false;

  DateTime _dateForDay(String? day) {
    const weekdays = {
      'Lunes': DateTime.monday,
      'Martes': DateTime.tuesday,
      'Miércoles': DateTime.wednesday,
      'Jueves': DateTime.thursday,
      'Viernes': DateTime.friday,
    };
    final target = weekdays[day] ?? DateTime.now().weekday;
    var date = DateTime.now();
    while (date.weekday != target) {
      date = date.subtract(const Duration(days: 1));
    }
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _selectDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      selectableDayPredicate: (date) => date.weekday == _date.weekday,
    );
    if (chosen == null || !mounted) return;
    setState(() {
      _date = chosen;
      _changes.clear();
      _roster = widget.loadRoster(_date);
    });
  }

  Future<void> _save(List<Map<String, dynamic>> rows) async {
    setState(() => _saving = true);
    try {
      for (final row in rows) {
        final id = (row['id_usuario'] as num).toInt();
        await widget.save(
          id,
          _date,
          _changes[id] ??
              (row['estado'] == 'SIN_REGISTRO'
                  ? 'PRESENTE'
                  : row['estado'].toString()),
        );
      }
      if (!mounted) return;
      setState(() {
        _changes.clear();
        _roster = widget.loadRoster(_date);
        _saving = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Asistencia guardada.')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la asistencia.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.session['grupo']?.toString() ?? 'Lista de asistencia'),
      actions: [
        IconButton(onPressed: _selectDate, icon: const Icon(Icons.event)),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _roster,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('No se pudo cargar la lista.'));
        }
        final rows = snapshot.data ?? const [];
        if (rows.isEmpty) {
          return const Center(child: Text('No hay estudiantes en este grupo.'));
        }
        return Column(
          children: [
            ListTile(
              title: Text(widget.session['actividad']?.toString() ?? 'Clase'),
              subtitle: Text(
                'Fecha: ${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
              ),
              trailing: TextButton(
                onPressed: _selectDate,
                child: const Text('Cambiar'),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  final id = (row['id_usuario'] as num).toInt();
                  final saved = row['estado']?.toString() ?? 'SIN_REGISTRO';
                  final value =
                      _changes[id] ??
                      (saved == 'SIN_REGISTRO' ? 'PRESENTE' : saved);
                  return ListTile(
                    title: Text(row['estudiante']?.toString() ?? 'Estudiante'),
                    subtitle: Text(
                      saved == 'SIN_REGISTRO'
                          ? 'Sin registro'
                          : 'Guardado: $saved',
                    ),
                    trailing: DropdownButton<String>(
                      value: value,
                      items: [
                        for (final status in statuses)
                          DropdownMenuItem(value: status, child: Text(status)),
                      ],
                      onChanged: _saving
                          ? null
                          : (status) => setState(() => _changes[id] = status!),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : () => _save(rows),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Guardando...' : 'Guardar asistencia'),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
