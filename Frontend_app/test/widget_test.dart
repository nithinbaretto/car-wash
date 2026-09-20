import 'package:flutter_test/flutter_test.dart';

import 'package:carwash/app.dart';

void main() {
  testWidgets('CarWashApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CarWashApp());
    expect(find.text('Car Wash'), findsOneWidget);
  });
}
