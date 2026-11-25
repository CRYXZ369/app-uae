import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app_unificada_uae/features/transport/presentation/transport_screen.dart';

void main() {
  testWidgets(
    'muestra las rutas documentadas y aclara que el GPS es simulado',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: TransportScreen()));

      expect(find.text('Transporte universitario'), findsOneWidget);
      expect(find.text('Ruta Corta'), findsOneWidget);
      expect(find.text('GPS SIMULADO'), findsOneWidget);
      expect(find.textContaining('Ubicación simulada:'), findsOneWidget);
      expect(find.text('El Charco'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Confirmar salida 12:00 p. m.'),
        200,
      );
      expect(find.text('12 / 15'), findsOneWidget);
      await tester.tap(find.text('Confirmar salida 12:00 p. m.'));
      await tester.pumpAndSettle();
      expect(find.text('13 / 15'), findsOneWidget);
    },
  );
}
