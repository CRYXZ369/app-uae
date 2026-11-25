import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app_unificada_uae/features/community/presentation/community_screen.dart';

void main() {
  testWidgets('filtra avisos y registra un único voto demo', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CommunityScreen()));

    expect(find.text('Comunidad UAE'), findsOneWidget);
    expect(find.text('Presentación de proyectos integradores'), findsOneWidget);

    await tester.tap(find.text('Votaciones'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Confirmación tentativa · Salida 12:00 p. m. (UAE → El Charco)',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Sí utilizaré la salida de las 12:00 p. m.'));
    await tester.pumpAndSettle();
    expect(
      find.text('Tu voto ya quedó registrado en esta sesión.'),
      findsOneWidget,
    );
  });
}
