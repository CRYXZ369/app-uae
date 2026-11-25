import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:app_unificada_uae/features/commerce/presentation/discounts_screen.dart';

void main() {
  testWidgets('filtra descuentos estudiantiles y muestra detalle', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: DiscountsScreen()));

    expect(find.text('Descuentos estudiantiles'), findsOneWidget);
    expect(find.text('Figma Education'), findsOneWidget);

    await tester.tap(find.text('Entretenimiento'));
    await tester.pumpAndSettle();
    expect(find.text('Figma Education'), findsNothing);
    expect(find.text('Spotify Premium Universitario'), findsOneWidget);

    await tester.tap(find.text('Spotify Premium Universitario'));
    await tester.pumpAndSettle();
    expect(find.text('Cómo activarlo:'), findsOneWidget);
  });
}
