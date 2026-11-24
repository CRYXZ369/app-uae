import 'package:material_ui/material_ui.dart';

import '../../../core/session/session_store.dart';
import '../../grades/domain/course_grade_summary.dart';
import '../../grades/presentation/course_grades_screen.dart';
import '../../academic/presentation/academic_module_screen.dart';
import '../../academic/presentation/tasks_screen.dart';
import '../../academic/presentation/teacher_attendance_screen.dart';
import '../../transport/presentation/transport_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.onLogout,
    required this.email,
    required this.roles,
    required this.loadCourseGrades,
    required this.loadAcademicModule,
    required this.loadAttendanceRoster,
    required this.saveAttendance,
    required this.saveTaskProgress,
    super.key,
  });

  final Future<void> Function() onLogout;
  final String email;
  final List<String> roles;
  final Future<List<CourseGradeSummary>> Function() loadCourseGrades;
  final Future<List<Map<String, dynamic>>> Function(String module)
  loadAcademicModule;
  final AttendanceRosterLoader loadAttendanceRoster;
  final AttendanceSaver saveAttendance;
  final TaskProgressSaver saveTaskProgress;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoggingOut = false;
  String? _errorMessage;
  int _tab = 0;

  Set<String> get _roleSet =>
      widget.roles.map((role) => role.toUpperCase()).toSet();
  bool get _isStudent => _roleSet.contains('ESTUDIANTE');
  String get _roleTitle {
    const names = {
      'ESTUDIANTE': 'Estudiante',
      'DOCENTE': 'Docente',
      'CAFETERIA': 'Cafetería',
      'CCE': 'Consejo Cultural Estudiantil',
      'ADMIN_ESCOLAR': 'Administración escolar',
      'GESTION_ACADEMICA': 'Gestión académica',
      'RECTORIA': 'Rectoría',
      'SOPORTE_TECNICO': 'Soporte técnico',
      'TRABAJADOR': 'Personal universitario',
      'DIRECTIVO': 'Directivo',
    };
    for (final role in widget.roles) {
      if (names.containsKey(role)) return names[role]!;
    }
    return 'Usuario UAE';
  }

  List<String> get _modules {
    final modules = <String>[];
    void add(List<String> values) {
      for (final value in values) {
        if (!modules.contains(value)) modules.add(value);
      }
    }

    if (_isStudent) {
      add([
        'Materias',
        'Calificaciones',
        'Horarios',
        'Tareas',
        'Asistencia',
        'Transporte',
      ]);
    }
    if (_roleSet.contains('DOCENTE')) {
      add(['Horarios', 'Materias', 'Tareas', 'Asistencia']);
    }
    if (_roleSet.contains('CAFETERIA')) {
      add(['Cafetería', 'Pedidos']);
    }
    if (_roleSet.contains('CCE')) {
      add(['Votaciones', 'Notificaciones']);
    }
    if (_roleSet.contains('ADMIN_ESCOLAR')) {
      add(['Pagos', 'Constancias', 'Perfil']);
    }
    if (_roleSet.contains('GESTION_ACADEMICA')) {
      add(['Materias', 'Horarios', 'Grupos']);
    }
    if (_roleSet.contains('RECTORIA') || _roleSet.contains('DIRECTIVO')) {
      add(['Avisos', 'Indicadores']);
    }
    if (_roleSet.contains('SOPORTE_TECNICO')) {
      add(['Usuarios', 'Roles', 'Incidencias']);
    }
    if (_roleSet.contains('TRABAJADOR')) {
      add(['Avisos']);
    }
    if (_roleSet.isEmpty) {
      add(['Materias', 'Calificaciones', 'Horarios', 'Tareas']);
    }
    if (!modules.contains('Notificaciones')) {
      add(['Notificaciones']);
    }
    if (!modules.contains('Perfil')) {
      add(['Perfil']);
    }
    return modules;
  }

  List<String> get _navigationModules {
    if (_isStudent) return ['Materias', 'Transporte', 'Perfil'];
    if (_roleSet.contains('DOCENTE')) {
      return ['Horarios', 'Asistencia', 'Perfil'];
    }
    if (_roleSet.contains('CAFETERIA')) {
      return ['Cafetería', 'Pedidos', 'Perfil'];
    }
    if (_roleSet.contains('CCE')) {
      return ['Votaciones', 'Notificaciones', 'Perfil'];
    }
    return _modules.take(3).toList();
  }

  String get _firstName {
    final local = widget.email.split('@').first.split('.').first;
    if (local.isEmpty) return 'Estudiante';
    return '${local[0].toUpperCase()}${local.substring(1)}';
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() {
      _isLoggingOut = true;
      _errorMessage = null;
    });
    try {
      await widget.onLogout();
    } on SessionStorageException {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
          _errorMessage = 'No se pudo cerrar la sesión en el servicio o en el dispositivo. Inténtalo de nuevo.';
        });
      }
    }
  }

  void _open(String title) {
    if (title == 'Transporte') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const TransportScreen()));
      return;
    }
    if (title == 'Asistencia' && _roleSet.contains('DOCENTE')) {
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => _moduleScreen(title)));
      return;
    }
    if (title == 'Calificaciones') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              CourseGradesScreen(loadCourses: widget.loadCourseGrades),
        ),
      );
      return;
    }
    if (title == 'Tareas' && _isStudent) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TasksScreen(
            loadTasks: () => widget.loadAcademicModule('Tareas'),
            saveProgress: widget.saveTaskProgress,
          ),
        ),
      );
      return;
    }
    if (title == 'Tareas' && _roleSet.contains('DOCENTE')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _ModulePage(
            title: title,
            icon: _iconFor(title),
            message: 'La consulta y publicación de tareas para docentes todavía no está disponible.',
          ),
        ),
      );
      return;
    }
    if (const {
      'Materias',
      'Horarios',
      'Tareas',
      'Asistencia',
      'Notificaciones',
      'Perfil',
    }.contains(title)) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AcademicModuleScreen(
            title: title,
            loadRows: () => widget.loadAcademicModule(title),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ModulePage(
          title: title,
          icon: _iconFor(title),
          message: 'Este módulo está contemplado para la aplicación. Su contenido estará disponible próximamente.',
        ),
      ),
    );
  }

  IconData _iconFor(String label) => switch (label) {
    'Materias' => Icons.menu_book,
    'Horarios' => Icons.calendar_month,
    'Tareas' => Icons.assignment,
    'Asistencia' => Icons.check_circle_outline,
    'Transporte' => Icons.directions_bus_outlined,
    'Grupos' => Icons.groups_outlined,
    'Cafetería' => Icons.restaurant,
    'Pedidos' => Icons.receipt_long,
    'Votaciones' => Icons.how_to_vote,
    'Pagos' => Icons.payments_outlined,
    'Constancias' => Icons.description_outlined,
    'Usuarios' => Icons.people_outline,
    'Roles' => Icons.admin_panel_settings_outlined,
    'Incidencias' => Icons.support_agent,
    'Notificaciones' => Icons.notifications_none,
    _ => Icons.person_outline,
  };

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      backgroundColor: const Color(0xfff1f3f6),
      body: SafeArea(child: _tab == 0 ? _home(compact) : _otherTab(compact)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          for (final module in _navigationModules)
            NavigationDestination(icon: Icon(_iconFor(module)), label: module),
        ],
      ),
    );
  }

  Widget _home(bool compact) => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff19395f), Color(0xff315f9d)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            compact ? 20 : 36,
            18,
            compact ? 20 : 36,
            22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.school_rounded,
                      color: Color(0xff214b78),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UNIVERSIDAD ALBERT EINSTEIN',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .7,
                        ),
                      ),
                      Text(
                        'Mi Campus Pro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      tooltip: 'Notificaciones',
                      onPressed: () => _open('Notificaciones'),
                      color: Colors.white,
                      icon: const Icon(Icons.notifications_none),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isLoggingOut ? null : _logout,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    icon: _isLoggingOut
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.logout, size: 18),
                    label: Text(
                      _isLoggingOut ? 'Cerrando...' : 'Cerrar sesión',
                    ),
                  ),
                ],
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
              Text(
                'Buenos días,',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '¡Hola, $_firstName!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Tu espacio académico digital',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Card(
                color: Colors.white,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xffe9f0fb),
                    child: Icon(Icons.person_outline, color: Color(0xff214b78)),
                  ),
                  title: Text(
                    _roleTitle,
                    style: TextStyle(fontSize: 12, color: Color(0xff2949b4)),
                  ),
                  subtitle: Text(
                    widget.email,
                    style: TextStyle(fontWeight: FontWeight.w600, height: 1.5),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open('Perfil'),
                ),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          compact ? 16 : 36,
          16,
          compact ? 16 : 36,
          24,
        ),
        sliver: SliverList.list(
          children: [
            _MetricCard(
              title: 'Estado de tu cuenta',
              value: 'Activa',
              icon: Icons.verified_user_outlined,
            ),
            const SizedBox(height: 18),
            Text(
              _isStudent ? 'Accesos rápidos' : 'Accesos de tu área',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xff24334f),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 94,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _modules.length,
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemBuilder: (context, index) {
                  final module = _modules[index];
                  return SizedBox(
                    width: 76,
                    child: _Shortcut(
                      label: module,
                      icon: _iconFor(module),
                      onTap: () => _open(module),
                    ),
                  );
                },
              ),
            ),
            if (_isStudent)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('Consulta tus próximas clases'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open('Horarios'),
                ),
              ),
            if (_isStudent)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xffe5efff),
                    child: Icon(Icons.directions_bus, color: Color(0xff2949b4)),
                  ),
                  title: const Text('Transporte universitario'),
                  subtitle: const Text(
                    'Consulta rutas y sigue una unidad simulada',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open('Transporte'),
                ),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _otherTab(bool compact) {
    final title = _navigationModules[_tab - 1];
    if (title != 'Inicio') {
      return _moduleScreen(title);
    }
    return _ModulePage(
      title: title,
      icon: _iconFor(title),
      message: title == 'Perfil'
          ? widget.email
          : 'Aquí encontrarás tus $title.',
    );
  }

  Widget _moduleScreen(String title) {
    if (title == 'Transporte') return const TransportScreen();
    if (title == 'Asistencia' && _roleSet.contains('DOCENTE')) {
      return TeacherAttendanceScreen(
        loadSessions: () => widget.loadAcademicModule(title),
        loadRoster: widget.loadAttendanceRoster,
        saveAttendance: widget.saveAttendance,
      );
    }
    return AcademicModuleScreen(
      title: title,
      loadRows: () => widget.loadAcademicModule(title),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });
  final String title, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xffe9f5ef),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: const Color(0xff27845a)),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12, color: Color(0xff6d7c91)),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xff243953),
        ),
      ),
      trailing: const Text(
        '●',
        style: TextStyle(color: Color(0xff35a66d), fontSize: 13),
      ),
    ),
  );
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe8edf4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xffeaf1ff),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xff315d96)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xff42546b),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ModulePage extends StatelessWidget {
  const _ModulePage({
    required this.title,
    required this.icon,
    required this.message,
  });
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: const Color(0xff3159c8)),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
}
