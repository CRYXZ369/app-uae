import 'package:material_ui/material_ui.dart';

import '../../../core/session/session_store.dart';
import '../../academic/presentation/academic_module_screen.dart';
import '../../academic/presentation/tasks_screen.dart';
import '../../academic/presentation/teacher_attendance_screen.dart';
import '../../billing/presentation/payments_documents_screen.dart';
import '../../cafeteria/presentation/cafeteria_screen.dart';
import '../../commerce/presentation/discounts_screen.dart';
import '../../community/presentation/community_screen.dart';
import '../../grades/domain/course_grade_summary.dart';
import '../../grades/presentation/course_grades_screen.dart';
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
    this.hasApi = false,
    super.key,
  });

  final Future<void> Function() onLogout;
  final String email;
  final List<String> roles;
  final bool hasApi;
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

  Map<String, dynamic>? _profile;
  double? _averageGrade;
  int _gradedCoursesCount = 0;
  int? _attendancePercent;
  List<Map<String, dynamic>> _upcomingTasks = const [];

  @override
  void initState() {
    super.initState();
    if (widget.hasApi) {
      _loadDashboardSummary();
    }
  }

  Future<void> _loadDashboardSummary() async {
    try {
      final profileRows = await widget.loadAcademicModule('Perfil');
      if (mounted && profileRows.isNotEmpty) {
        setState(() => _profile = profileRows.first);
      }
    } catch (_) {}

    if (!_isStudent) return;

    try {
      final courses = await widget.loadCourseGrades();
      final averages = courses
          .map((course) => course.estimatedAverage)
          .whereType<double>()
          .toList();
      if (mounted) {
        setState(() {
          _gradedCoursesCount = averages.length;
          _averageGrade = averages.isEmpty
              ? null
              : averages.reduce((a, b) => a + b) / averages.length;
        });
      }
    } catch (_) {}

    try {
      final attendanceRows = await widget.loadAcademicModule('Asistencia');
      if (mounted && attendanceRows.isNotEmpty) {
        final attended = attendanceRows.where((row) {
          final status = row['estado']?.toString().toUpperCase() ?? '';
          return status == 'PRESENTE' ||
              status == 'RETARDO' ||
              status == 'JUSTIFICADO';
        }).length;
        setState(() {
          _attendancePercent = ((attended / attendanceRows.length) * 100)
              .round();
        });
      }
    } catch (_) {}

    try {
      final taskRows = await widget.loadAcademicModule('Tareas');
      final pending = taskRows
          .where(
            (row) =>
                (row['estado']?.toString().toUpperCase() ?? '') != 'ENTREGADA',
          )
          .take(3)
          .toList(growable: false);
      if (mounted) {
        setState(() => _upcomingTasks = pending);
      }
    } catch (_) {}
  }

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
        'Horarios',
        'Tareas',
        'Calificaciones',
        'Asistencia',
        'Transporte',
        'Cafetería',
        'Pagos',
        'Constancias',
        'Descuentos',
        'Avisos',
        'Votaciones',
      ]);
    }
    if (_roleSet.contains('DOCENTE')) {
      add([
        'Horarios',
        'Materias',
        'Tareas',
        'Asistencia',
        'Cafetería',
        'Avisos',
      ]);
    }
    if (_roleSet.contains('CAFETERIA')) {
      add(['Cafetería', 'Pedidos', 'Avisos']);
    }
    if (_roleSet.contains('CCE')) {
      add(['Votaciones', 'Avisos', 'Notificaciones']);
    }
    if (_roleSet.contains('ADMIN_ESCOLAR')) {
      add(['Pagos', 'Constancias', 'Avisos', 'Perfil']);
    }
    if (_roleSet.contains('GESTION_ACADEMICA')) {
      add(['Materias', 'Horarios', 'Grupos', 'Avisos']);
    }
    if (_roleSet.contains('RECTORIA') || _roleSet.contains('DIRECTIVO')) {
      add(['Avisos', 'Votaciones', 'Indicadores']);
    }
    if (_roleSet.contains('SOPORTE_TECNICO')) {
      add(['Usuarios', 'Roles', 'Incidencias', 'Avisos']);
    }
    if (_roleSet.contains('TRABAJADOR')) {
      add(['Avisos', 'Descuentos']);
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
    final profileName = _profile?['nombre']?.toString().trim() ?? '';
    if (profileName.isNotEmpty) return profileName.split(' ').first;
    final local = widget.email.split('@').first.split('.').first;
    if (local.isEmpty) return 'Estudiante';
    return '${local[0].toUpperCase()}${local.substring(1)}';
  }

  String? get _academicBadge {
    if (_profile == null) return null;
    final career = _profile!['carrera']?.toString().trim() ?? '';
    final semester = int.tryParse(_profile!['semestre']?.toString() ?? '') ?? 0;
    if (career.isEmpty && semester <= 0) return null;
    if (semester > 0 && career.isNotEmpty) {
      return '$semester.º Semestre · $career';
    }
    return career.isNotEmpty ? career : '$semester.º Semestre';
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
    if (title == 'Cafetería') {
      if (_roleSet.contains('CAFETERIA')) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _ModulePage(
              title: 'Cafetería',
              icon: _iconFor(title),
              message: 'La gestión de menú y pedidos para el personal de cafetería está pendiente. La pantalla actual es una demostración de pedidos para estudiantes y docentes.',
            ),
          ),
        );
        return;
      }
      final userRole = _roleSet.contains('DOCENTE') ? 'DOCENTE' : 'ESTUDIANTE';
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CafeteriaScreen(userRole: userRole),
        ),
      );
      return;
    }
    if (title == 'Transporte') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const TransportScreen()));
      return;
    }
    if (title == 'Pagos') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PaymentsDocumentsScreen(initialTab: 0),
        ),
      );
      return;
    }
    if (title == 'Constancias') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PaymentsDocumentsScreen(initialTab: 1),
        ),
      );
      return;
    }
    if (title == 'Descuentos') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const DiscountsScreen()));
      return;
    }
    if (title == 'Avisos') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const CommunityScreen(initialTab: 0),
        ),
      );
      return;
    }
    if (title == 'Votaciones') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const CommunityScreen(initialTab: 1),
        ),
      );
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
    if (title == 'Perfil') {
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => _profileScaffold()));
      return;
    }
    if (const {
      'Materias',
      'Horarios',
      'Tareas',
      'Asistencia',
      'Notificaciones',
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
    'Materias' => Icons.menu_book_rounded,
    'Horarios' => Icons.calendar_month_rounded,
    'Tareas' => Icons.assignment_outlined,
    'Calificaciones' => Icons.bar_chart_rounded,
    'Asistencia' => Icons.check_circle_outline_rounded,
    'Transporte' => Icons.directions_bus_outlined,
    'Cafetería' => Icons.restaurant_menu_rounded,
    'Grupos' => Icons.groups_outlined,
    'Pedidos' => Icons.receipt_long_rounded,
    'Votaciones' => Icons.how_to_vote_outlined,
    'Avisos' => Icons.campaign_outlined,
    'Descuentos' => Icons.local_offer_outlined,
    'Pagos' => Icons.payments_outlined,
    'Constancias' => Icons.description_outlined,
    'Usuarios' => Icons.people_outline,
    'Roles' => Icons.admin_panel_settings_outlined,
    'Incidencias' => Icons.support_agent,
    'Notificaciones' => Icons.notifications_none_rounded,
    _ => Icons.person_outline_rounded,
  };

  (Color bg, Color fg) _colorsFor(String label) => switch (label) {
    'Materias' => (const Color(0xffe8f1ff), const Color(0xff2563eb)),
    'Horarios' => (const Color(0xfff3e8ff), const Color(0xff7c3aed)),
    'Tareas' => (const Color(0xffffedd5), const Color(0xffea580c)),
    'Calificaciones' => (const Color(0xffe0e7ff), const Color(0xff4338ca)),
    'Asistencia' => (const Color(0xffdcfce7), const Color(0xff15803d)),
    'Transporte' => (const Color(0xffe0f2fe), const Color(0xff0284c7)),
    'Cafetería' => (const Color(0xfffef3c7), const Color(0xffd97706)),
    'Pagos' => (const Color(0xffd1fae5), const Color(0xff059669)),
    'Constancias' => (const Color(0xffe2e8f0), const Color(0xff334155)),
    'Descuentos' => (const Color(0xfffce7f3), const Color(0xffdb2777)),
    'Avisos' => (const Color(0xffccfbf1), const Color(0xff0d9488)),
    'Votaciones' => (const Color(0xffede9fe), const Color(0xff6d28d9)),
    _ => (const Color(0xffeaf1ff), const Color(0xff315d96)),
  };

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      backgroundColor: const Color(0xfff3f6fb),
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
              colors: [Color(0xff18375c), Color(0xff2a5690)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            compact ? 20 : 36,
            12,
            compact ? 20 : 36,
            16,
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
              const SizedBox(height: 8),
              const Text(
                'Buenos días,',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '¡Hola, $_firstName!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              if (_academicBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _academicBadge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Text(
                  'Tu espacio académico digital',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              const SizedBox(height: 10),
              Card(
                color: Colors.white,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xffe9f0fb),
                    child: Icon(Icons.person_outline, color: Color(0xff214b78)),
                  ),
                  title: Text(
                    _roleTitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff2949b4),
                    ),
                  ),
                  subtitle: Text(
                    widget.email,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
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
          12,
          compact ? 16 : 36,
          24,
        ),
        sliver: SliverList.list(
          children: [
            if (_isStudent)
              _StudentKpiRow(
                averageGrade: _averageGrade,
                gradedCoursesCount: _gradedCoursesCount,
                attendancePercent: _attendancePercent,
                onTapGrades: () => _open('Calificaciones'),
                onTapAttendance: () => _open('Asistencia'),
              )
            else
              const _MetricCard(
                title: 'Estado de tu cuenta',
                value: 'Activa',
                icon: Icons.verified_user_outlined,
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  _isStudent ? 'Accesos rápidos' : 'Accesos de tu área',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff24334f),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _modules.length,
                separatorBuilder: (_, _) => const SizedBox(width: 9),
                itemBuilder: (context, index) {
                  final module = _modules[index];
                  final (bg, fg) = _colorsFor(module);
                  return SizedBox(
                    width: 80,
                    child: _Shortcut(
                      label: module,
                      icon: _iconFor(module),
                      iconBackground: bg,
                      iconColor: fg,
                      onTap: () => _open(module),
                    ),
                  );
                },
              ),
            ),
            if (_isStudent) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'Próximas entregas',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff24334f),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _open('Tareas'),
                    child: const Text('Ver todas'),
                  ),
                ],
              ),
              if (_upcomingTasks.isEmpty)
                Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xffffedd5),
                      child: Icon(
                        Icons.assignment_outlined,
                        color: Color(0xffea580c),
                      ),
                    ),
                    title: const Text('Consulta tus tareas y horarios'),
                    subtitle: const Text(
                      'Revisa entregas pendientes y calendario académico',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open('Tareas'),
                  ),
                )
              else
                for (final task in _upcomingTasks) ...[
                  _UpcomingTaskCard(task: task, onTap: () => _open('Tareas')),
                  const SizedBox(height: 8),
                ],
              const SizedBox(height: 12),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xffe5efff),
                    child: Icon(Icons.directions_bus, color: Color(0xff2949b4)),
                  ),
                  title: const Text('Transporte universitario'),
                  subtitle: const Text(
                    'Consulta rutas y confirma la salida de las 12:00 p. m.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open('Transporte'),
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );

  Widget _otherTab(bool compact) {
    final title = _navigationModules[_tab - 1];
    if (title == 'Perfil') {
      return _profileBody();
    }
    if (title != 'Inicio') {
      return _moduleScreen(title);
    }
    return _ModulePage(
      title: title,
      icon: _iconFor(title),
      message: 'Aquí encontrarás tus $title.',
    );
  }

  Widget _profileScaffold() => Scaffold(
    appBar: AppBar(title: const Text('Mi Perfil')),
    body: SafeArea(child: _profileBody()),
  );

  Widget _profileBody() {
    final fullName = _profile == null
        ? _firstName
        : '${_profile!['nombre'] ?? ''} ${_profile!['apellidos'] ?? ''}'.trim();
    final career = _profile?['carrera']?.toString() ?? '';
    final group = _profile?['grupo']?.toString() ?? '';
    final semester = int.tryParse(_profile?['semestre']?.toString() ?? '') ?? 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: const Color(0xff19395f),
                  child: Text(
                    _firstName.isNotEmpty ? _firstName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  fullName.isEmpty ? _firstName : fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff1e3553),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: const TextStyle(color: Color(0xff6b7a90)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffeaf1ff),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _roleTitle,
                    style: const TextStyle(
                      color: Color(0xff214b78),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (career.isNotEmpty || group.isNotEmpty || semester > 0) ...[
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                if (career.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.school_outlined),
                    title: const Text('Carrera'),
                    subtitle: Text(career),
                  ),
                if (semester > 0)
                  ListTile(
                    leading: const Icon(Icons.layers_outlined),
                    title: const Text('Semestre'),
                    subtitle: Text('$semester.º semestre'),
                  ),
                if (group.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.groups_outlined),
                    title: const Text('Grupo'),
                    subtitle: Text(group),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Pagos y mensualidades'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open('Pagos'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Solicitud de constancias'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open('Constancias'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _isLoggingOut ? null : _logout,
          icon: const Icon(Icons.logout),
          label: Text(_isLoggingOut ? 'Cerrando sesión...' : 'Cerrar sesión'),
        ),
      ],
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

class _StudentKpiRow extends StatelessWidget {
  const _StudentKpiRow({
    required this.averageGrade,
    required this.gradedCoursesCount,
    required this.attendancePercent,
    required this.onTapGrades,
    required this.onTapAttendance,
  });

  final double? averageGrade;
  final int gradedCoursesCount;
  final int? attendancePercent;
  final VoidCallback onTapGrades;
  final VoidCallback onTapAttendance;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTapGrades,
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xff19395f), Color(0xff28548d)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        gradedCoursesCount > 0
                            ? '$gradedCoursesCount mat.'
                            : 'Estimado',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Promedio General',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  averageGrade == null
                      ? '--'
                      : averageGrade!.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  averageGrade == null
                      ? 'Ver calificaciones'
                      : 'Escala 0 a 100',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTapAttendance,
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xffe2e8f0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xffe8f5ed),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xff27845a),
                        size: 16,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffe8f5ed),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        attendancePercent == null
                            ? 'Activa'
                            : (attendancePercent! >= 80 ? 'Óptima' : 'Revisar'),
                        style: const TextStyle(
                          color: Color(0xff27845a),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Asistencia',
                  style: TextStyle(color: Color(0xff6b7a90), fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  attendancePercent == null ? '--' : '$attendancePercent%',
                  style: const TextStyle(
                    color: Color(0xff1e3553),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Este semestre',
                  style: TextStyle(color: Color(0xff6b7a90), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _UpcomingTaskCard extends StatelessWidget {
  const _UpcomingTaskCard({required this.task, required this.onTap});

  final Map<String, dynamic> task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subject = (task['materia']?.toString() ?? 'MATERIA').toUpperCase();
    final title = task['titulo']?.toString() ?? 'Tarea';
    final due = task['fecha_entrega']?.toString() ?? '';
    final priority = task['prioridad']?.toString() ?? 'MEDIA';
    final (bg, fg, label) = switch (priority.toUpperCase()) {
      'ALTA' => (const Color(0xfffdecec), const Color(0xffb42318), 'Alta'),
      'BAJA' => (const Color(0xffe8f5ed), const Color(0xff27845a), 'Baja'),
      _ => (const Color(0xfffff4d6), const Color(0xff8b5a00), 'Media'),
    };
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        title: Text(
          subject,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Color(0xff2563eb),
            letterSpacing: .5,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1e3553),
                ),
              ),
              if (due.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  due,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff6b7a90),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
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
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 21, color: iconColor),
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
