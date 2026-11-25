import 'package:material_ui/material_ui.dart';

class DiscountsScreen extends StatefulWidget {
  const DiscountsScreen({super.key});

  @override
  State<DiscountsScreen> createState() => _DiscountsScreenState();
}

class _DiscountsScreenState extends State<DiscountsScreen> {
  String _category = 'Todos';

  static const _categories = [
    'Todos',
    'Diseño y Dev',
    'Productividad',
    'Entretenimiento',
  ];

  static const _discounts = <_StudentDiscount>[
    _StudentDiscount(
      brand: 'Figma Education',
      category: 'Diseño y Dev',
      benefit: 'Plan Education gratuito',
      validity: 'Vigente con correo @uae.edu.mx',
      description: 'Acceso completo a Figma Professional y FigJam para prototipos de clase y proyectos universitarios.',
      steps: 'Regístrate con tu correo institucional y verifica tu estatus escolar en figma.com/education.',
      color: Color(0xff6d28d9),
      icon: Icons.design_services_outlined,
    ),
    _StudentDiscount(
      brand: 'GitHub Student Pack',
      category: 'Diseño y Dev',
      benefit: 'Copilot Pro y créditos cloud',
      validity: 'Renovación anual escolar',
      description: 'Incluye GitHub Copilot, JetBrains, dominios y créditos en la nube para proyectos de TI.',
      steps: 'Verifica tu credencial o correo @uae.edu.mx en education.github.com/pack.',
      color: Color(0xff1e3553),
      icon: Icons.code_rounded,
    ),
    _StudentDiscount(
      brand: 'Microsoft 365 Educación',
      category: 'Productividad',
      benefit: 'Licencia escolar incluida',
      validity: 'Durante tu estancia en UAE',
      description: 'Word, Excel, PowerPoint, Teams y almacenamiento en la nube vinculados a tu cuenta institucional.',
      steps: 'Inicia sesión en office.com usando tu correo institucional universitario.',
      color: Color(0xff2563eb),
      icon: Icons.work_outline_rounded,
    ),
    _StudentDiscount(
      brand: 'Spotify Premium Universitario',
      category: 'Entretenimiento',
      benefit: 'Tarifa reducida mensual',
      validity: 'Hasta 4 años verificados',
      description: 'Plan individual sin anuncios con tarifa preferencial para estudiantes activos.',
      steps: 'Selecciona el plan Estudiantes en spotify.com/student y valida tu inscripción.',
      color: Color(0xff15803d),
      icon: Icons.music_note_rounded,
    ),
    _StudentDiscount(
      brand: 'YouTube Premium Estudiante',
      category: 'Entretenimiento',
      benefit: 'Precio preferencial mensual',
      validity: 'Verificación anual',
      description: 'Videos sin anuncios, descarga sin conexión y YouTube Music incluido.',
      steps: 'Ingresa a youtube.com/premium/student y completa la validación estudiantil.',
      color: Color(0xffb91c1c),
      icon: Icons.play_circle_outline_rounded,
    ),
  ];

  List<_StudentDiscount> get _visibleDiscounts => _category == 'Todos'
      ? _discounts
      : _discounts.where((item) => item.category == _category).toList();

  void _showDetails(_StudentDiscount item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.brand),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.benefit,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xff214b78),
              ),
            ),
            const SizedBox(height: 8),
            Text(item.description),
            const SizedBox(height: 12),
            const Text(
              'Cómo activarlo:',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(item.steps),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Descuentos estudiantiles')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xffedf3fc),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.local_offer_outlined, color: Color(0xff315d96)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Catálogo de beneficios externos para estudiantes. La elegibilidad depende de cada proveedor.',
                    style: TextStyle(color: Color(0xff344e6f), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final category in _categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: _visibleDiscounts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _visibleDiscounts[index];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.icon, color: item.color),
                    ),
                    title: Text(
                      item.brand,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${item.benefit}\n${item.validity}'),
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showDetails(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentDiscount {
  const _StudentDiscount({
    required this.brand,
    required this.category,
    required this.benefit,
    required this.validity,
    required this.description,
    required this.steps,
    required this.color,
    required this.icon,
  });

  final String brand;
  final String category;
  final String benefit;
  final String validity;
  final String description;
  final String steps;
  final Color color;
  final IconData icon;
}
