import 'package:material_ui/material_ui.dart';

class PaymentsDocumentsScreen extends StatefulWidget {
  const PaymentsDocumentsScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<PaymentsDocumentsScreen> createState() =>
      _PaymentsDocumentsScreenState();
}

class _PaymentsDocumentsScreenState extends State<PaymentsDocumentsScreen> {
  late int _tab = widget.initialTab.clamp(0, 1);

  final List<_PaymentItem> _payments = [
    _PaymentItem(
      id: 'PAY-101',
      concept: 'Mensualidad · Noviembre 2026',
      period: 'Noviembre 2026',
      amount: 3200,
      dueDate: '05 nov 2026',
      status: _PaymentStatus.pending,
    ),
    _PaymentItem(
      id: 'PAY-102',
      concept: 'Mensualidad · Octubre 2026',
      period: 'Octubre 2026',
      amount: 3200,
      dueDate: '05 oct 2026',
      status: _PaymentStatus.paid,
      receiptFolio: 'COM-2026-8104',
    ),
    _PaymentItem(
      id: 'PAY-103',
      concept: 'Reinscripción 5.º Semestre',
      period: 'Agosto 2026',
      amount: 4000,
      dueDate: '15 ago 2026',
      status: _PaymentStatus.paid,
      receiptFolio: 'COM-2026-7490',
    ),
  ];

  static const _services = <_DocumentService>[
    _DocumentService(
      id: 'DOC-EST',
      name: 'Constancia de estudios',
      description: 'Incluye matrícula, carrera, semestre y estatus vigente.',
      price: 75,
      estimatedTime: '24 a 48 horas hábiles',
      icon: Icons.description_outlined,
    ),
    _DocumentService(
      id: 'DOC-URG',
      name: 'Constancia urgente',
      description: 'Emisión prioritaria validada por administración escolar.',
      price: 100,
      estimatedTime: 'Mismo día hábil',
      icon: Icons.flash_on_outlined,
    ),
    _DocumentService(
      id: 'DOC-HIS',
      name: 'Historial académico parcial',
      description: 'Resumen no oficial de materias cursadas y promedios.',
      price: 50,
      estimatedTime: '48 horas hábiles',
      icon: Icons.school_outlined,
    ),
  ];

  final List<_DocumentRequest> _requests = [
    _DocumentRequest(
      folio: 'SOL-2026-0412',
      serviceName: 'Constancia de estudios',
      price: 75,
      stepIndex: 1,
      estimatedTime: '24 a 48 horas hábiles',
    ),
  ];

  int _nextFolio = 413;

  double get _pendingTotal => _payments
      .where((item) => item.status != _PaymentStatus.paid)
      .fold(0, (sum, item) => sum + item.amount);

  void _simulatePayment(_PaymentItem item) {
    setState(() {
      item.status = _PaymentStatus.paid;
      item.receiptFolio = 'COM-2026-${8200 + _nextFolio++}';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pago simulado registrado (${item.receiptFolio}). No es un cobro real.',
        ),
      ),
    );
  }

  void _showReceipt(_PaymentItem item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comprobante demo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Folio: ${item.receiptFolio ?? "N/A"}'),
            const SizedBox(height: 6),
            Text('Concepto: ${item.concept}'),
            const SizedBox(height: 6),
            Text('Monto: \$${item.amount.toStringAsFixed(2)} MXN'),
            const SizedBox(height: 6),
            const Text(
              'Documento ilustrativo generado en modo demostración sin cargo real.',
              style: TextStyle(fontSize: 12, color: Color(0xff6b7a90)),
            ),
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

  void _requestDocument(_DocumentService service) {
    final folio = 'SOL-2026-0${_nextFolio++}';
    setState(() {
      _requests.insert(
        0,
        _DocumentRequest(
          folio: folio,
          serviceName: service.name,
          price: service.price,
          stepIndex: 0,
          estimatedTime: service.estimatedTime,
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Solicitud demo registrada con folio $folio.')),
    );
  }

  void _advanceDocumentStep(_DocumentRequest req) {
    if (req.stepIndex >= 2) return;
    setState(() => req.stepIndex++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos y constancias')),
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
                Icon(Icons.info_outline_rounded, color: Color(0xff315d96)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Prototipo informativo sin cobro real ni captura de tarjetas. Montos sujetos a validación administrativa.',
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
                  icon: Icon(Icons.payments_outlined),
                  label: Text('Mensualidades'),
                ),
                ButtonSegment<int>(
                  value: 1,
                  icon: Icon(Icons.description_outlined),
                  label: Text('Constancias'),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (value) => setState(() => _tab = value.first),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _tab == 0 ? _buildPaymentsTab() : _buildDocumentsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff19395f), Color(0xff2c5892)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
                    'Saldo pendiente estimado',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${_pendingTotal.toStringAsFixed(2)} MXN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _pendingTotal == 0
                        ? 'Al corriente en tus pagos demo'
                        : 'Periodo actual · Referencia institucional',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Estado de cuenta',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xff24334f),
        ),
      ),
      const SizedBox(height: 8),
      for (final item in _payments)
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.concept,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _StatusChip(status: item.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Periodo: ${item.period} · Vence: ${item.dueDate}',
                  style: const TextStyle(
                    color: Color(0xff6b7a90),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '\$${item.amount.toStringAsFixed(2)} MXN',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff1e3553),
                      ),
                    ),
                    const Spacer(),
                    if (item.status != _PaymentStatus.paid)
                      FilledButton.icon(
                        onPressed: () => _simulatePayment(item),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Simular pago'),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () => _showReceipt(item),
                        icon: const Icon(Icons.receipt_long, size: 18),
                        label: const Text('Comprobante'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ],
  );

  Widget _buildDocumentsTab() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
    children: [
      const Text(
        'Seguimiento de solicitudes',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xff24334f),
        ),
      ),
      const SizedBox(height: 8),
      for (final req in _requests)
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        req.serviceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      req.folio,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff315d96),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Entrega estimada: ${req.estimatedTime} · \$${req.price.toStringAsFixed(2)} MXN',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff6b7a90),
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: (req.stepIndex + 1) / 3,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StepLabel('Solicitada', req.stepIndex >= 0),
                    _StepLabel('En revisión', req.stepIndex >= 1),
                    _StepLabel('Lista', req.stepIndex >= 2),
                  ],
                ),
                if (req.stepIndex < 2) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _advanceDocumentStep(req),
                      icon: const Icon(Icons.fast_forward_outlined, size: 18),
                      label: const Text('Simular avance'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      const SizedBox(height: 8),
      const Text(
        'Catálogo de servicios',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xff24334f),
        ),
      ),
      const SizedBox(height: 8),
      for (final service in _services)
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xffeaf1ff),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(service.icon, color: const Color(0xff315d96)),
            ),
            title: Text(
              service.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${service.description}\n\$${service.price.toStringAsFixed(2)} MXN · ${service.estimatedTime}',
            ),
            isThreeLine: true,
            trailing: FilledButton(
              onPressed: () => _requestDocument(service),
              child: const Text('Solicitar'),
            ),
          ),
        ),
    ],
  );
}

enum _PaymentStatus { pending, paid, overdue }

class _PaymentItem {
  _PaymentItem({
    required this.id,
    required this.concept,
    required this.period,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.receiptFolio,
  });

  final String id;
  final String concept;
  final String period;
  final double amount;
  final String dueDate;
  _PaymentStatus status;
  String? receiptFolio;
}

class _DocumentService {
  const _DocumentService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.estimatedTime,
    required this.icon,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String estimatedTime;
  final IconData icon;
}

class _DocumentRequest {
  _DocumentRequest({
    required this.folio,
    required this.serviceName,
    required this.price,
    required this.stepIndex,
    required this.estimatedTime,
  });

  final String folio;
  final String serviceName;
  final double price;
  int stepIndex;
  final String estimatedTime;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final _PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      _PaymentStatus.paid => (
        'Pagado',
        const Color(0xffe8f5ed),
        const Color(0xff27845a),
      ),
      _PaymentStatus.overdue => (
        'Vencido',
        const Color(0xfffdecec),
        const Color(0xffb42318),
      ),
      _PaymentStatus.pending => (
        'Pendiente',
        const Color(0xfffff4d6),
        const Color(0xff8b5a00),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel(this.text, this.active);

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      color: active ? const Color(0xff214b78) : const Color(0xff8c99ad),
    ),
  );
}
