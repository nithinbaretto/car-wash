import 'dart:convert';
import 'package:carwash/core/models/shop.dart';
import 'package:carwash/core/models/user_role.dart';
import 'package:carwash/core/network/api_client.dart';
import 'package:carwash/core/services/app_session.dart';
import 'package:carwash/core/services/auth_service.dart';
import 'package:carwash/features/auth/splash_screen.dart';
import 'package:carwash/features/vendor/onboarding/onboarding_draft.dart';
import 'package:carwash/features/vendor/onboarding/vendor_onboarding_screen.dart';
import 'package:carwash/features/vendor/vendor_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Auth extends AuthService {
  @override
  Future<String?> getToken() async => 'test-token';
}

http.Response _ok(Map<String, dynamic> data) =>
    http.Response(jsonEncode({'success': true, 'data': data}), 200);
http.Response _failure() => http.Response(
  jsonEncode({
    'success': false,
    'error': {'code': 'UNAVAILABLE', 'message': 'Connection unavailable'},
  }),
  503,
);
AppSession _session(Future<http.Response> Function(http.Request) respond) =>
    AppSession(
        authService: _Auth(),
        apiClient: ApiClient(httpClient: MockClient(respond)),
      )
      ..loggedIn = true
      ..role = UserRole.vendor;
Widget _app(AppSession session, Widget home) => SessionScope(
  session: session,
  child: MaterialApp(
    home: home,
    routes: {VendorShell.route: (_) => const VendorShell()},
  ),
);
Future<void> _largeScreen(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1100, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Map<String, dynamic> _draft() => {
  'name': 'Bright Wash',
  'contactPhone': '+919876543210',
  'line1': '12 Main Road',
  'area': 'Centre',
  'city': 'Pune',
  'state': 'Maharashtra',
  'postalCode': '411001',
  'latitude': '18.52',
  'longitude': '73.85',
  'services': [
    {
      'name': 'Interior clean',
      'price': '499.50',
      'duration': '45',
      'category': 'interior',
      'active': true,
    },
  ],
  'opens': '09:00',
  'closes': '11:00',
  'days': '2',
  'capacity': '3',
  'firstDate': '2030-01-01',
  'replaceSchedule': true,
};
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('Schedule uses chosen dates, capacity and service length', () {
    final days = buildOnboardingAvailability(
      firstDate: DateTime(2030, 12, 31),
      days: 2,
      opensAt: '09:00',
      closesAt: '11:00',
      slotMinutes: 45,
      capacity: 3,
    );
    expect(days.map((day) => day['date']), ['2030-12-31', '2031-01-01']);
    expect(days.first['slots'], [
      {'startAt': '09:00', 'endAt': '09:45', 'capacity': 3, 'enabled': true},
      {'startAt': '09:45', 'endAt': '10:30', 'capacity': 3, 'enabled': true},
    ]);
    for (final times in [
      ('25:00', '26:00'),
      ('09:00', '09:30'),
      ('10:00', '09:00'),
    ]) {
      expect(
        () => buildOnboardingAvailability(
          firstDate: DateTime(2030),
          days: 1,
          opensAt: times.$1,
          closesAt: times.$2,
          slotMinutes: 45,
          capacity: 1,
        ),
        throwsFormatException,
      );
    }
  });
  testWidgets(
    'New form is blank, validates required fields and flushes draft on exit',
    (tester) async {
      await _largeScreen(tester);
      final session = _session((_) async => _ok({'carWashes': []}));
      await tester.pumpWidget(_app(session, const VendorOnboardingScreen()));
      await tester.pumpAndSettle();
      final name = find.widgetWithText(TextFormField, 'Shop name');
      expect(tester.widget<TextFormField>(name).controller!.text, isEmpty);
      await tester.tap(find.text('Submit for review'));
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsWidgets);
      await tester.enterText(name, 'My actual shop');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(
        jsonDecode(prefs.getString('shop-onboarding::new')!)['name'],
        'My actual shop',
      );
    },
  );
  testWidgets(
    'Saved form retries same request and shows pending after atomic submission',
    (tester) async {
      await _largeScreen(tester);
      SharedPreferences.setMockInitialValues({
        'shop-onboarding::new': jsonEncode(_draft()),
      });
      final requests = <http.Request>[];
      final session = _session((request) async {
        if (request.method == 'GET') return _ok({'carWashes': []});
        requests.add(request);
        return requests.length == 1
            ? _failure()
            : _ok({
                'carWash': {
                  'id': 'shop-real',
                  'name': 'Bright Wash',
                  'status': 'pending_review',
                },
              });
      });
      await tester.pumpWidget(_app(session, const VendorOnboardingScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.tap(find.text('Submit for review'));
      await tester.pumpAndSettle();
      expect(find.text('Connection unavailable'), findsWidgets);
      await tester.tap(find.text('Submit for review'));
      await tester.pumpAndSettle();
      expect(requests, hasLength(2));
      expect(
        requests[0].headers['Idempotency-Key'],
        requests[1].headers['Idempotency-Key'],
      );
      final body = jsonDecode(requests.last.body) as Map<String, dynamic>;
      expect(
        body['address']['formattedAddress'],
        '12 Main Road, Centre, Pune, Maharashtra, 411001',
      );
      expect(body['location'], {'latitude': 18.52, 'longitude': 73.85});
      expect(body['services'][0]['priceMinor'], 49950);
      expect(body['services'][0]['durationMinutes'], 45);
      expect(body['availability'], hasLength(2));
      expect(find.text('Application under review'), findsOneWidget);
      expect(find.text('Walk-in'), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).getString(
          'shop-onboarding::new',
        ),
        isNull,
      );
    },
  );
  testWidgets(
    'Lost creation response replays POST and preserves an intervening rejection',
    (tester) async {
      await _largeScreen(tester);
      SharedPreferences.setMockInitialValues({
        'shop-onboarding::new': jsonEncode(_draft()),
      });
      final writes = <http.Request>[];
      var reads = 0;
      final session = _session((request) async {
        if (request.method == 'GET') {
          reads++;
          return _ok({
            'carWashes': writes.isEmpty
                ? []
                : [
                    {'id': 'saved-shop', 'status': 'rejected'},
                  ],
          });
        }
        writes.add(request);
        return writes.length == 1
            ? _failure()
            : _ok({
                'carWash': {
                  'id': 'saved-shop',
                  'name': 'Bright Wash',
                  'status': 'rejected',
                  'review': {'reason': 'Correct the address'},
                },
              });
      });
      await tester.pumpWidget(_app(session, const VendorOnboardingScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.tap(find.text('Submit for review'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit for review'));
      await tester.pumpAndSettle();
      expect(reads, 1);
      expect(writes.map((request) => request.method), ['POST', 'POST']);
      expect(writes.first.url, writes.last.url);
      expect(writes.first.body, writes.last.body);
      expect(
        writes.first.headers['Idempotency-Key'],
        writes.last.headers['Idempotency-Key'],
      );
      expect(find.text('Changes requested'), findsOneWidget);
      expect(find.text('Review feedback: Correct the address'), findsOneWidget);
    },
  );
  testWidgets(
    'Correction preserves existing dates and sends only writable fields with PUT',
    (tester) async {
      await _largeScreen(tester);
      final draft = _draft()..['replaceSchedule'] = false;
      SharedPreferences.setMockInitialValues({
        'shop-onboarding::correct-me': jsonEncode(draft),
      });
      http.Request? write;
      final shop = Shop.fromJson({
        'id': 'correct-me',
        'name': 'Bright Wash',
        'status': 'rejected',
      });
      final session = _session((request) async {
        if (request.method == 'GET') {
          return _ok({
            'carWash': {'name': 'Bright Wash'},
            'services': [],
            'availability': [
              {
                'date': '2030-01-01',
                'updatedAt': {'seconds': 1},
                'slots': [
                  {
                    'startAt': '09:00',
                    'endAt': '10:00',
                    'capacity': 3,
                    'bookedCount': 0,
                    'availableCapacity': 3,
                    'enabled': true,
                  },
                ],
              },
            ],
          });
        }
        write = request;
        return _ok({
          'carWash': {
            'id': 'correct-me',
            'name': 'Bright Wash',
            'status': 'pending_review',
          },
        });
      });
      await tester.pumpWidget(
        _app(session, VendorOnboardingScreen(shop: shop)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.tap(find.text('Correct and resubmit for review'));
      await tester.pumpAndSettle();
      expect(write?.method, 'PUT');
      expect(write?.url.path, endsWith('/correct-me/onboarding'));
      expect(write?.headers['Idempotency-Key'], isNotEmpty);
      final body = jsonDecode(write!.body) as Map<String, dynamic>;
      expect(body['availability'], [
        {
          'date': '2030-01-01',
          'slots': [
            {
              'startAt': '09:00',
              'endAt': '10:00',
              'capacity': 3,
              'enabled': true,
            },
          ],
        },
      ]);
      expect(find.text('Application under review'), findsOneWidget);
    },
  );
  testWidgets('Rejected shop exposes feedback and edits the existing shop', (
    tester,
  ) async {
    await _largeScreen(tester);
    final shop = Shop.fromJson({
      'id': 'rejected-shop',
      'name': 'Bright Wash',
      'status': 'rejected',
      'review': {'reason': 'Correct the shop location'},
    });
    final session =
        _session((request) async {
            expect(request.url.path, endsWith('/rejected-shop/onboarding'));
            return _ok({
              'carWash': {'name': 'Bright Wash'},
              'services': [],
              'availability': [],
            });
          })
          ..ownerShopsLoaded = true
          ..selectedOwnerShop = shop;
    await tester.pumpWidget(_app(session, const VendorShell()));
    await tester.pumpAndSettle();
    expect(
      find.text('Review feedback: Correct the shop location'),
      findsOneWidget,
    );
    await tester.tap(find.text('Edit and resubmit'));
    await tester.pumpAndSettle();
    expect(find.text('Edit shop application'), findsOneWidget);
    expect(find.text('Correct and resubmit for review'), findsOneWidget);
  });
  testWidgets('Shop-load errors block new registration and retry recovers', (
    tester,
  ) async {
    var attempts = 0;
    final session = _session(
      (_) async => ++attempts == 1 ? _failure() : _ok({'carWashes': []}),
    );
    await tester.pumpWidget(_app(session, const VendorShell()));
    await tester.pumpAndSettle();
    expect(find.text('Connection unavailable'), findsOneWidget);
    expect(find.byType(VendorOnboardingScreen), findsNothing);
    await tester.tap(find.text('Retry loading shop'));
    await tester.pumpAndSettle();
    expect(find.text('List your car wash'), findsOneWidget);
    expect(attempts, 2);
  });
  testWidgets('Splash waits for session restoration before routing owner', (
    tester,
  ) async {
    final session = _session((_) async => _ok({'carWashes': []}))
      ..ownerShopsLoaded = true;
    await tester.pumpWidget(_app(session, const SplashScreen()));
    await tester.pump(SplashScreen.loadDuration);
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);
    session.isInitialized = true;
    session.selectRole(UserRole.vendor);
    await tester.pumpAndSettle();
    expect(find.byType(VendorOnboardingScreen), findsOneWidget);
  });
}
