import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:carwash/core/models/app_notification.dart';
import 'package:carwash/core/models/booking.dart';
import 'package:carwash/core/models/shop.dart';
import 'package:carwash/core/models/user_profile.dart';
import 'package:carwash/core/network/api_client.dart';
import 'package:carwash/core/services/booking_api_service.dart';
import 'package:carwash/core/services/discovery_api_service.dart';
import 'package:carwash/core/services/owner_api_service.dart';

void main() {
  group('Model Serialization Tests', () {
    test('UserProfile fromJson and toJson', () {
      final json = {
        'uid': 'test_uid_123',
        'displayName': 'John Doe',
        'phoneNumber': '+919876543210',
        'email': 'john@test.com',
        'roles': ['customer', 'owner'],
        'activeRole': 'customer',
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.uid, 'test_uid_123');
      expect(profile.displayName, 'John Doe');
      expect(profile.isCustomer, isTrue);
      expect(profile.isOwner, isTrue);
      expect(profile.isActiveOwner, isFalse);

      final exported = profile.toJson();
      expect(exported['uid'], 'test_uid_123');
      expect(exported['displayName'], 'John Doe');
    });

    test('Shop fromJson with backend publicShopCard shape', () {
      final json = {
        'id': 'shop_1',
        'name': 'Sparkle Wash',
        'address': {
          'line1': '100 Feet Rd',
          'area': 'Indiranagar',
          'city': 'Bengaluru',
          'formattedAddress': '100 Feet Rd, Indiranagar, Bengaluru',
        },
        'location': {'latitude': 12.9784, 'longitude': 77.6408},
        'categories': ['quick', 'interior'],
        'coverImageUrl': 'https://example.com/cover.jpg',
        'rating': {'average': 4.8, 'count': 120},
        'startingPriceMinor': 29900,
        'currency': 'INR',
        'distanceKm': 2.3,
        'isFavourite': true,
        'services': [
          {
            'id': 'svc_1',
            'name': 'Quick Wash',
            'category': 'quick',
            'priceMinor': 29900,
            'durationMinutes': 30,
            'active': true,
          }
        ],
      };

      final shop = Shop.fromJson(json);
      expect(shop.id, 'shop_1');
      expect(shop.name, 'Sparkle Wash');
      expect(shop.rating, 4.8);
      expect(shop.reviewCount, 120);
      expect(shop.priceFrom, 299);
      expect(shop.displayPrice, '₹299');
      expect(shop.distanceKm, 2.3);
      expect(shop.isFavourite, isTrue);
      expect(shop.serviceDetails.length, 1);
      expect(shop.serviceDetails.first.name, 'Quick Wash');
      expect(shop.matchesService('Quick'), isTrue);
    });

    test('Booking fromJson with backend bookingSummary shape', () {
      final json = {
        'id': 'bk_1',
        'carWashId': 'shop_1',
        'status': 'pending',
        'scheduledDate': '2026-09-26',
        'startAt': '15:30',
        'endAt': '16:00',
        'priceMinor': 25000,
        'currency': 'INR',
        'carWash': {
          'name': 'Sparkle Wash',
          'address': {'formattedAddress': 'Koramangala, Bengaluru'},
        },
        'service': {
          'name': 'Complete Wash',
          'category': 'complete',
          'durationMinutes': 45,
        },
      };

      final booking = Booking.fromJson(json);
      expect(booking.id, 'bk_1');
      expect(booking.shopId, 'shop_1');
      expect(booking.status, BookingStatus.pending);
      expect(booking.status.label, 'Pending Approval');
      expect(booking.canCancel, isTrue);
      expect(booking.price, 250);
      expect(booking.displayPrice, '₹250');
      expect(booking.shopName, 'Sparkle Wash');
      expect(booking.service, 'Complete Wash');
    });

    test('AppNotification fromJson and filtering', () {
      final json = {
        'id': 'notif_1',
        'type': 'booking',
        'title': 'Booking accepted',
        'body': 'Your appointment has been confirmed',
        'isRead': false,
      };

      final notif = AppNotification.fromJson(json);
      expect(notif.id, 'notif_1');
      expect(notif.type, 'booking');
      expect(notif.isRead, isFalse);
      expect(notif.matches(NotificationFilter.bookings), isTrue);
      expect(notif.matches(NotificationFilter.offers), isFalse);
    });
  });

  group('API Services Mock Tests', () {
    test('DiscoveryApiService.getCategories returns category list', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/v1/categories'));
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'categories': [
                {'id': 'quick', 'label': 'Quick'},
                {'id': 'interior', 'label': 'Interior'},
              ]
            },
            'requestId': 'req_1',
          }),
          200,
        );
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final discovery = DiscoveryApiService(apiClient: apiClient);

      final categories = await discovery.getCategories();
      expect(categories.length, 2);
      expect(categories[0]['id'], 'quick');
      expect(categories[1]['id'], 'interior');
    });

    test('BookingApiService.createBooking sends Idempotency-Key and creates booking', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/v1/bookings'));
        expect(request.headers.containsKey('Idempotency-Key'), isTrue);

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['carWashId'], 'shop_1');
        expect(body['serviceId'], 'svc_1');
        expect(body['date'], '2026-09-26');
        expect(body['startAt'], '14:00');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'booking': {
                'id': 'new_booking_1',
                'carWashId': 'shop_1',
                'status': 'pending',
                'scheduledDate': '2026-09-26',
                'startAt': '14:00',
                'endAt': '14:30',
                'priceMinor': 25000,
                'carWash': {'name': 'Sparkle Auto Spa'},
                'service': {'name': 'Quick Wash'},
              }
            },
            'requestId': 'req_2',
          }),
          201,
        );
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final bookingService = BookingApiService(apiClient: apiClient);

      final result = await bookingService.createBooking(
        carWashId: 'shop_1',
        serviceId: 'svc_1',
        date: '2026-09-26',
        startAt: '14:00',
      );

      expect(result.id, 'new_booking_1');
      expect(result.status, BookingStatus.pending);
      expect(result.price, 250);
    });

    test('BookingApiService.cancelBooking calls cancel endpoint', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/v1/bookings/bk_123/cancel'));
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'booking': {
                'id': 'bk_123',
                'carWashId': 'shop_1',
                'status': 'cancelled',
              }
            },
            'requestId': 'req_3',
          }),
          200,
        );
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final bookingService = BookingApiService(apiClient: apiClient);

      final result = await bookingService.cancelBooking('bk_123');
      expect(result.id, 'bk_123');
      expect(result.status, BookingStatus.cancelled);
    });

    test('OwnerApiService.updateBookingStatus calls status transition', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/v1/owner/bookings/bk_456/status'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['status'], 'accepted');

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'booking': {
                'id': 'bk_456',
                'carWashId': 'shop_1',
                'status': 'accepted',
              }
            },
            'requestId': 'req_4',
          }),
          200,
        );
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final ownerService = OwnerApiService(apiClient: apiClient);

      final result = await ownerService.updateBookingStatus(
        bookingId: 'bk_456',
        status: 'accepted',
      );
      expect(result.status, BookingStatus.accepted);
    });
  });
}
