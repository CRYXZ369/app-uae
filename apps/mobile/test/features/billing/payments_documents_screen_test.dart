import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app_unificada_uae/features/billing/presentation/payments_documents_screen.dart';

void main() {
  testWidgets('simula pago de mensualidad y solicitud de constancia', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PaymentsDocumentsScreen()));

    expect(find.text('Pagos y constancias'), findsOneWidget);
    expect(find.text('\$3200.00 MXN'), findsWidgets);

    await tester.tap(find.text('Simular pago'));
    await tester.pumpAndSettle();
    expect(find.text('\$0.00 MXN'), findsOneWidget);

    await tester.tap(find.text('Constancias'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Constancia urgente'), 200);
    expect(find.text('Constancia urgente'), findsOneWidget);

    await tester.tap(find.text('Solicitar').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('SOL-2026-0414'), -200);
    expect(find.text('SOL-2026-0414'), findsOneWidget);
  });
}
