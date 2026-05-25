import 'package:flutter_test/flutter_test.dart';

import 'package:svacron_chitra/src/app/chitra_app.dart';

void main() {
  testWidgets('renders Svacron Chitra shell', (WidgetTester tester) async {
    await tester.pumpWidget(const ChitraApp());

    expect(find.text('Svacron Chitra'), findsOneWidget);
    expect(find.text('Scanner Workspace'), findsNothing);
  });
}
