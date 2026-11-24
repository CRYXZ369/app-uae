import 'package:material_ui/material_ui.dart';

typedef TaskLoader = Future<List<Map<String, dynamic>>> Function();
typedef TaskProgressSaver = Future<void> Function(
  int taskId,
  String status, {
  String? content,
});

class TasksScreen extends StatefulWidget {
  const TasksScreen({required this.loadTasks, this.saveProgress, super.key});

  final TaskLoader loadTasks;
  final TaskProgressSaver? saveProgress;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

enum _TaskFilter { all, pending, inProgress, completed }

class _TasksScreenState extends State<TasksScreen> {
  late Future<List<Map<String, dynamic>>> _tasks;
  _TaskFilter _filter = _TaskFilter.all;

  @override
  void initState() {
    super.initState();
    _tasks = widget.loadTasks();
  }

  void _retry() => setState(() => _tasks = widget.loadTasks());

  Future<void> _refreshTasks() async {
    final refreshed = widget.loadTasks();
    setState(() => _tasks = refreshed);
    try {
      await refreshed;
    } catch (_) {
      // FutureBuilder displays the error state and its retry action.
    }
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> rows) {
    return rows.where((row) {
      final status = _text(row, 'estado').toUpperCase();
      return switch (_filter) {
        _TaskFilter.all => true,
        _TaskFilter.pending => status == 'PENDIENTE' || status == 'VENCIDA',
        _TaskFilter.inProgress => status == 'EN_PROGRESO',
        _TaskFilter.completed => status == 'ENTREGADA',
      };
    }).toList()..sort((a, b) => _date(a).compareTo(_date(b)));
  }

  int _count(List<Map<String, dynamic>> rows, _TaskFilter filter) {
    return rows.where((row) {
      final status = _text(row, 'estado').toUpperCase();
      return switch (filter) {
        _TaskFilter.all => true,
        _TaskFilter.pending => status == 'PENDIENTE' || status == 'VENCIDA',
        _TaskFilter.inProgress => status == 'EN_PROGRESO',
        _TaskFilter.completed => status == 'ENTREGADA',
      };
    }).length;
  }

  static String _text(Map<String, dynamic> row, String key) =>
      row[key]?.toString().trim() ?? '';

  static DateTime _date(Map<String, dynamic> row) =>
      DateTime.tryParse(_text(row, 'fecha_entrega')) ?? DateTime(9999);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Tareas'),
      actions: [
        IconButton(
          tooltip: 'Actualizar tareas',
          onPressed: _retry,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _tasks,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _StateMessage(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudieron cargar las tareas',
            message: 'Comprueba tu conexión e inténtalo de nuevo.',
            action: _retry,
          );
        }
        final rows = snapshot.data ?? const <Map<String, dynamic>>[];
        if (rows.isEmpty) {
          return const _StateMessage(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Aún no tienes tareas',
            message:
                'Las actividades asignadas a tus materias aparecerán aquí.',
          );
        }
        final visible = _filtered(rows);
        final pending = rows.where((row) {
          final state = _text(row, 'estado').toUpperCase();
          return state == 'PENDIENTE' || state == 'VENCIDA';
        }).length;
        return RefreshIndicator(
          onRefresh: _refreshTasks,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
            children: [
              _TasksSummary(total: rows.length, pending: pending),
              const SizedBox(height: 18),
              const Text(
                'Tus actividades',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final filter in _TaskFilter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            '${_label(filter)}  ${_count(rows, filter)}',
                          ),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 46),
                  child: Column(
                    children: [
                      Icon(
                        Icons.filter_alt_off_outlined,
                        size: 38,
                        color: Color(0xff8291a6),
                      ),
                      SizedBox(height: 10),
                      Text('No hay tareas en este filtro'),
                    ],
                  ),
                )
              else
                for (final task in visible) ...[
                  _TaskCard(task: task, onTap: () => _showDetails(task)),
                  const SizedBox(height: 10),
                ],
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Los estados y fechas se muestran según la información registrada por tus docentes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xff76859a)),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  String _label(_TaskFilter filter) => switch (filter) {
    _TaskFilter.all => 'Todas',
    _TaskFilter.pending => 'Pendientes',
    _TaskFilter.inProgress => 'En progreso',
    _TaskFilter.completed => 'Entregadas',
  };

  Future<void> _showDetails(Map<String, dynamic> task) async {
    final taskId = int.tryParse(_text(task, 'id_tarea'));
    final status = _text(task, 'estado').toUpperCase();
    final canUpdate =
        widget.saveProgress != null && taskId != null && status != 'ENTREGADA';
    final change = await showModalBottomSheet<_TaskProgressChange>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TaskDetailsSheet(task: task, canUpdate: canUpdate),
    );
    if (change == null || taskId == null || widget.saveProgress == null) return;

    try {
      await widget.saveProgress!(
        taskId,
        change.status,
        content: change.content,
      );
      if (!mounted) return;
      setState(() => _tasks = widget.loadTasks());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            change.status == 'ENTREGADA'
                ? 'Tarea entregada.'
                : 'Avance guardado.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar el avance. Inténtalo de nuevo.'),
        ),
      );
    }
  }
}

class _TaskProgressChange {
  const _TaskProgressChange(this.status, this.content);
  final String status;
  final String content;
}

class _TaskDetailsSheet extends StatefulWidget {
  const _TaskDetailsSheet({required this.task, required this.canUpdate});
  final Map<String, dynamic> task;
  final bool canUpdate;

  @override
  State<_TaskDetailsSheet> createState() => _TaskDetailsSheetState();
}

class _TaskDetailsSheetState extends State<_TaskDetailsSheet> {
  late final TextEditingController _contentController;
  String? _validationMessage;

  String _text(String key) => widget.task[key]?.toString().trim() ?? '';

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
      text: _text('contenido_entrega'),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _text('titulo');
    final description = _text('descripcion');
    final subject = _text('materia');
    final teacher = _text('docente');
    final status = _text('estado').toUpperCase();
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          22,
          8,
          22,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.isEmpty ? 'Detalle de tarea' : title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _DetailLine(
              icon: Icons.menu_book_outlined,
              text: subject.isEmpty ? 'Materia por confirmar' : subject,
            ),
            if (teacher.isNotEmpty)
              _DetailLine(icon: Icons.person_outline, text: teacher),
            _DetailLine(
              icon: Icons.event_outlined,
              text: _formatDate(DateTime.tryParse(_text('fecha_entrega'))),
            ),
            _DetailLine(
              icon: Icons.flag_outlined,
              text: 'Prioridad ${_text('prioridad').toLowerCase()}',
            ),
            _DetailLine(
              icon: Icons.pending_actions_outlined,
              text: _statusLabel(status),
            ),
            const Divider(height: 26),
            Text(
              description.isEmpty
                  ? 'El docente no agregó una descripción.'
                  : description,
              style: const TextStyle(height: 1.45),
            ),
            if (widget.canUpdate) ...[
              const SizedBox(height: 18),
              TextField(
                controller: _contentController,
                minLines: 2,
                maxLines: 5,
                maxLength: 20000,
                decoration: const InputDecoration(
                  labelText: 'Tu respuesta o enlace de entrega',
                  hintText: 'Escribe aquí tu entrega en texto',
                  alignLabelWithHint: true,
                ),
              ),
              if (_validationMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _validationMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const Text(
                'Esta versión guarda texto; todavía no admite archivos adjuntos.',
                style: TextStyle(fontSize: 12, color: Color(0xff76859a)),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(
                      _TaskProgressChange(
                        'EN_PROGRESO',
                        _contentController.text.trim(),
                      ),
                    ),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar avance'),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      if (_contentController.text.trim().isEmpty) {
                        setState(
                          () => _validationMessage = 'Escribe tu entrega antes de marcarla como entregada.',
                        );
                        return;
                      }
                      Navigator.of(context).pop(
                        _TaskProgressChange(
                          'ENTREGADA',
                          _contentController.text.trim(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.task_alt),
                    label: const Text('Entregar tarea'),
                  ),
                ],
              ),
            ] else if (status == 'ENTREGADA' &&
                _text('contenido_entrega').isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'Tu entrega',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              SelectableText(_text('contenido_entrega')),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Text(
                  'La entrega de archivos todavía no está disponible en esta versión.',
                  style: TextStyle(fontSize: 12, color: Color(0xff76859a)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TasksSummary extends StatelessWidget {
  const _TasksSummary({required this.total, required this.pending});
  final int total;
  final int pending;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xff1e416c), Color(0xff315f9d)],
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mantén tus entregas al día',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 7),
              Text(
                '$pending ${pending == 1 ? 'pendiente' : 'pendientes'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$total actividades en tus materias',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.checklist_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    ),
  );
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onTap});
  final Map<String, dynamic> task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = task['titulo']?.toString() ?? 'Tarea';
    final subject = task['materia']?.toString() ?? 'Materia';
    final status = (task['estado']?.toString() ?? 'PENDIENTE').toUpperCase();
    final priority = (task['prioridad']?.toString() ?? 'MEDIA').toUpperCase();
    final due = DateTime.tryParse(task['fecha_entrega']?.toString() ?? '');
    final tardy =
        task['entrega_tardia'] == true ||
        task['entrega_tardia']?.toString() == 'true';
    final statusColor = switch (status) {
      'ENTREGADA' => const Color(0xff27845a),
      'EN_PROGRESO' => const Color(0xff3267b2),
      'VENCIDA' => const Color(0xffc74e4e),
      _ => const Color(0xffbd7a1c),
    };
    final priorityColor = switch (priority) {
      'ALTA' => const Color(0xffc74e4e),
      'BAJA' => const Color(0xff27845a),
      _ => const Color(0xffbd7a1c),
    };
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xffedf3fc),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Color(0xff315d96),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        letterSpacing: .7,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff426ca4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff243953),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Color(0xff8291a6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDate(due),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xff687990),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        _Tag(label: _statusLabel(status), color: statusColor),
                        _Tag(
                          label: 'Prioridad ${priority.toLowerCase()}',
                          color: priorityColor,
                        ),
                        if (tardy)
                          const _Tag(
                            label: 'Entrega tardía',
                            color: Color(0xffc74e4e),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Color(0xff8291a6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xff59718d)),
        const SizedBox(width: 9),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: const Color(0xff315d96)),
          const SizedBox(height: 15),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 7),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 17),
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

String _statusLabel(String status) => switch (status) {
  'EN_PROGRESO' => 'En progreso',
  'ENTREGADA' => 'Entregada',
  'VENCIDA' => 'Vencida',
  _ => 'Pendiente',
};

String _formatDate(DateTime? date) {
  if (date == null || date.year == 9999) return 'Fecha por confirmar';
  const weekdays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  final local = date.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${weekdays[local.weekday - 1]}, ${local.day} ${months[local.month - 1]} · $hour:$minute';
}
