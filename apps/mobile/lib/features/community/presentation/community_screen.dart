import 'package:material_ui/material_ui.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late int _tab = widget.initialTab.clamp(0, 1);
  String _selectedCategory = 'Todos';

  static const _categories = [
    'Todos',
    'Escolar',
    'Académica',
    'Rectoría',
    'CCE',
    'Emergencia',
  ];

  static const _announcements = <_AnnouncementItem>[
    _AnnouncementItem(
      category: 'Académica',
      audience: 'Ingeniería en TI · 5.º Semestre',
      title: 'Presentación de proyectos integradores',
      body: 'Se invita a la comunidad universitaria a la muestra de prototipos del 5.º semestre en las instalaciones de la UAE.',
      date: 'Hoy · 09:00 a. m.',
    ),
    _AnnouncementItem(
      category: 'Escolar',
      audience: 'Todos los estudiantes',
      title: 'Ventana de solicitud de constancias',
      body: 'Recuerda que puedes consultar los requisitos de constancias normales y urgentes desde la sección de Pagos y constancias.',
      date: 'Ayer · 02:30 p. m.',
    ),
    _AnnouncementItem(
      category: 'CCE',
      audience: 'Comunidad estudiantil',
      title: 'Convocatoria de actividades culturales y deportivas',
      body: 'Participa en las votaciones abiertas para elegir las dinámicas del próximo encuentro universitario.',
      date: '23 nov 2026',
    ),
    _AnnouncementItem(
      category: 'Rectoría',
      audience: 'Toda la comunidad UAE',
      title: 'Actualización de canales de comunicación oficial',
      body: 'La información publicada en esta sección es ilustrativa para el MVP; valida siempre los comunicados oficiales.',
      date: '20 nov 2026',
    ),
    _AnnouncementItem(
      category: 'Emergencia',
      audience: 'Rutas de transporte',
      title: 'Aviso preventivo por lluvia en vialidades',
      body: 'Toma previsiones en tus traslados hacia el campus; los horarios estimados pueden ajustarse por tráfico.',
      date: '18 nov 2026',
    ),
  ];

  final List<_PollItem> _polls = [
    _PollItem(
      id: 'POLL-1',
      title: 'Confirmación tentativa · Salida 12:00 p. m. (UAE → El Charco)',
      closesAt: 'Cierra hoy · 11:30 a. m.',
      options: [
        _PollOption(
          label: 'Sí utilizaré la salida de las 12:00 p. m.',
          votes: 14,
        ),
        _PollOption(label: 'Prefiero el horario de las 3:00 p. m.', votes: 9),
        _PollOption(label: 'No requiero transporte hoy', votes: 5),
      ],
    ),
    _PollItem(
      id: 'POLL-2',
      title: 'Temática sugerida para el próximo taller de TI (CCE)',
      closesAt: 'Cierra el viernes · 06:00 p. m.',
      options: [
        _PollOption(label: 'Desarrollo móvil con Flutter y APIs', votes: 22),
        _PollOption(
          label: 'Ciberseguridad y pruebas de penetración',
          votes: 19,
        ),
        _PollOption(label: 'Internet de las Cosas con ESP32', votes: 15),
      ],
    ),
  ];

  List<_AnnouncementItem> get _visibleAnnouncements =>
      _selectedCategory == 'Todos'
      ? _announcements
      : _announcements
            .where((item) => item.category == _selectedCategory)
            .toList();

  void _vote(_PollItem poll, int optionIndex) {
    if (poll.selectedOption != null) return;
    setState(() {
      poll.selectedOption = optionIndex;
      poll.options[optionIndex].votes++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voto demo registrado; una respuesta por usuario.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comunidad UAE')),
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
                Icon(Icons.campaign_outlined, color: Color(0xff315d96)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Avisos y votaciones de demostración local. Las decisiones oficiales se validan con la universidad.',
                    style: TextStyle(color: Color(0xff344e6f), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(
                  value: 0,
                  icon: Icon(Icons.campaign_outlined),
                  label: Text('Avisos'),
                ),
                ButtonSegment<int>(
                  value: 1,
                  icon: Icon(Icons.how_to_vote_outlined),
                  label: Text('Votaciones'),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (value) => setState(() => _tab = value.first),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _tab == 0 ? _buildAnnouncementsTab() : _buildPollsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsTab() => Column(
    children: [
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
                  selected: _selectedCategory == category,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = category),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: _visibleAnnouncements.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = _visibleAnnouncements[index];
            return Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _CategoryPill(category: item.category),
                        const Spacer(),
                        Text(
                          item.date,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xff70819a),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff1e3553),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      style: const TextStyle(
                        color: Color(0xff42546b),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Audiencia: ${item.audience}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff315d96),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ],
  );

  Widget _buildPollsTab() => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
    itemCount: _polls.length,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (context, index) {
      final poll = _polls[index];
      final totalVotes = poll.totalVotes;
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                poll.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff1e3553),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${poll.closesAt} · $totalVotes votos acumulados',
                style: const TextStyle(fontSize: 12, color: Color(0xff70819a)),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < poll.options.length; i++) ...[
                _PollOptionTile(
                  option: poll.options[i],
                  totalVotes: totalVotes,
                  selected: poll.selectedOption == i,
                  locked: poll.selectedOption != null,
                  onTap: () => _vote(poll, i),
                ),
                const SizedBox(height: 8),
              ],
              if (poll.selectedOption != null)
                const Text(
                  'Tu voto ya quedó registrado en esta sesión.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff27845a),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _AnnouncementItem {
  const _AnnouncementItem({
    required this.category,
    required this.audience,
    required this.title,
    required this.body,
    required this.date,
  });

  final String category;
  final String audience;
  final String title;
  final String body;
  final String date;
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (category) {
      'Emergencia' => (const Color(0xfffdecec), const Color(0xffb42318)),
      'CCE' => (const Color(0xffede9fe), const Color(0xff5b21b6)),
      'Rectoría' => (const Color(0xfffff4d6), const Color(0xff8b5a00)),
      'Escolar' => (const Color(0xffe8f5ed), const Color(0xff27845a)),
      _ => (const Color(0xffeaf1ff), const Color(0xff214b78)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PollItem {
  _PollItem({
    required this.id,
    required this.title,
    required this.closesAt,
    required this.options,
  });

  final String id;
  final String title;
  final String closesAt;
  final List<_PollOption> options;
  int? selectedOption;

  int get totalVotes => options.fold(0, (sum, option) => sum + option.votes);
}

class _PollOption {
  _PollOption({required this.label, required this.votes});

  final String label;
  int votes;
}

class _PollOptionTile extends StatelessWidget {
  const _PollOptionTile({
    required this.option,
    required this.totalVotes,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final _PollOption option;
  final int totalVotes;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = totalVotes == 0 ? 0.0 : option.votes / totalVotes;
    final pct = (ratio * 100).round();
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: locked ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xffeaf1ff) : const Color(0xfff7f9fc),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xff214b78) : const Color(0xffe2e8f0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18,
                  color: selected
                      ? const Color(0xff214b78)
                      : const Color(0xff70819a),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xff214b78),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      ),
    );
  }
}
