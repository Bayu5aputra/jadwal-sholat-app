import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_jadwal_sholat/app/app.dart';

void main() {
  testWidgets('Onboarding screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const JadwalSholatApp());
    await tester.pumpAndSettle();

    expect(find.text('Quality Jadwal'), findsOneWidget);
    expect(find.text('NEXT'), findsOneWidget);
  });
}
