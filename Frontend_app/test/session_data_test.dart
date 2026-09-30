import 'dart:convert';

import 'package:carwash/core/models/booking.dart';
import 'package:carwash/core/models/shop.dart';
import 'package:carwash/core/network/api_client.dart';
import 'package:carwash/core/network/api_exception.dart';
import 'package:carwash/core/services/app_session.dart';
import 'package:carwash/core/services/auth_service.dart';
import 'package:carwash/core/services/owner_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Auth extends AuthService {
  @override
  Future<String?> getToken() async => 'verified-token';
}

http.Response _ok(Map<String, dynamic> data) =>
    http.Response(jsonEncode({'success': true, 'data': data}), 200);

void main() {
  test('Valid empty backend lists stay empty without sample data', () async {
    final session = AppSession(
      authService: _Auth(),
      apiClient: ApiClient(
        httpClient: MockClient(
          (request) async => _ok({
            'carWashes': [],
            'bookings': [],
            'notifications': [],
            'favourites': [],
          }),
        ),
      ),
    )..loggedIn = true;
    await session.loadNearbyShops();
    await session.loadBookings();
    await session.loadNotifications();
    await session.loadFavourites();
    expect(session.nearbyShops, isEmpty);
    expect(session.bookings, isEmpty);
    expect(session.pastBookings, isEmpty);
    expect(session.notifications, isEmpty);
    expect(session.favoriteIds, isEmpty);
  });

  test(
    'Unavailable backend reports errors and never invents slots or shops',
    () async {
      final session = AppSession(
        authService: _Auth(),
        apiClient: ApiClient(
          httpClient: MockClient(
            (request) async => http.Response(
              jsonEncode({
                'success': false,
                'error': {'code': 'UNAVAILABLE', 'message': 'Try later'},
              }),
              503,
            ),
          ),
        ),
      )..loggedIn = true;
      await session.loadNearbyShops();
      await session.loadBookings();
      expect(session.nearbyShops, isEmpty);
      expect(session.shopsError, 'Try later');
      expect(session.bookings, isEmpty);
      expect(session.loadErrors['bookings'], 'Try later');
      await expectLater(
        session.getAvailability('shop_1', '2026-09-30'),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        session.getShopDetail('shop_1'),
        throwsA(isA<ApiException>()),
      );
    },
  );

  test('Guest booking cannot fabricate a successful reservation', () async {
    final session = AppSession(authService: _Auth());
    await expectLater(
      session.createBooking(
        carWashId: 'shop',
        serviceId: 'service',
        date: '2026-09-30',
        startAt: '10:00',
      ),
      throwsA(isA<ApiException>()),
    );
    expect(session.bookings, isEmpty);
  });

  test(
    'Walk-in preserves retry key and decodes customer and vehicle',
    () async {
      final api = OwnerApiService(
        apiClient: ApiClient(
          httpClient: MockClient((request) async {
            expect(
              request.url.path,
              endsWith('/v1/owner/car-washes/shop_1/walk-ins'),
            );
            expect(request.headers['Idempotency-Key'], 'walk-in-retry-key');
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['vehicle'], 'KA01AB1234');
            expect(body['serviceId'], 'svc_1');
            return _ok({
              'booking': {
                'id': 'walk_1',
                'carWashId': 'shop_1',
                'status': 'accepted',
                'customer': {'displayName': 'Asha', 'phoneNumber': null},
                'vehicle': {'registrationNumber': 'KA01AB1234'},
              },
            });
          }),
        ),
      );
      final booking = await api.createWalkIn(
        carWashId: 'shop_1',
        serviceId: 'svc_1',
        customerName: 'Asha',
        vehicle: 'KA01AB1234',
        date: '2026-09-30',
        startAt: '10:00',
        idempotencyKey: 'walk-in-retry-key',
      );
      expect(booking.status, BookingStatus.accepted);
      expect(booking.customerName, 'Asha');
      expect(booking.vehicleRegistration, 'KA01AB1234');
    },
  );

  test('Owner availability and earnings use selected shop and date', () async {
    final api = OwnerApiService(
      apiClient: ApiClient(
        httpClient: MockClient((request) async {
          expect(request.url.queryParameters['date'], '2026-09-30');
          if (request.url.path.endsWith('/availability')) {
            return _ok({
              'date': '2026-09-30',
              'slots': [
                {
                  'startAt': '10:00',
                  'endAt': '10:30',
                  'capacity': 2,
                  'availableCapacity': 1,
                  'bookedCount': 1,
                  'enabled': true,
                },
              ],
            });
          }
          expect(
            request.url.path,
            endsWith('/v1/owner/car-washes/shop_1/earnings'),
          );
          return _ok({
            'earnings': {
              'todayMinor': 15050,
              'weekMinor': 35050,
              'completedToday': 1,
              'completedWeek': 2,
              'currency': 'INR',
            },
          });
        }),
      ),
    );
    final slots = await api.getAvailability('shop_1', '2026-09-30');
    expect(slots.single.availableCapacity, 1);
    expect(slots.single.isAvailable, isTrue);
    final earnings = await api.getEarnings('shop_1', '2026-09-30');
    expect(earnings['todayMinor'], 15050);
    expect(earnings['completedWeek'], 2);
  });

  test('Empty ratings and service catalog do not invent offerings', () {
    final shop = Shop.fromJson({'id': 'shop', 'rating': <String, dynamic>{}});
    expect(shop.rating, 0);
    expect(shop.services, isEmpty);
  });
}
