import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:carwash/app.dart';
import 'package:carwash/features/auth/splash_screen.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('CarWashApp launches splash', (WidgetTester tester) async {
    await tester.pumpWidget(const CarWashApp());
    expect(find.textContaining('smooth drive'), findsOneWidget);
    expect(find.textContaining('Version 1.0.3'), findsOneWidget);
    await tester.pump(SplashScreen.loadDuration);
    await tester.pumpAndSettle();
  });
}
