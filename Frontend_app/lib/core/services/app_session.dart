import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../models/availability_slot.dart';
import '../models/booking.dart';
import '../models/shop.dart';
import '../models/shop_service.dart';
import '../models/user_location.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../network/api_client.dart';
import '../network/api_config.dart';
import '../network/api_exception.dart';
import 'auth_service.dart';
import 'booking_api_service.dart';
import 'discovery_api_service.dart';
import 'favourites_api_service.dart';
import 'notification_api_service.dart';
import 'owner_api_service.dart';
import 'user_api_service.dart';

class AppSession extends ChangeNotifier {
  AppSession({AuthService? authService, ApiClient? apiClient})
    : authService = authService ?? AuthService(),
      apiClient = apiClient ?? ApiClient() {
    this.apiClient.tokenProvider = this.authService.getToken;
    userApi = UserApiService(apiClient: this.apiClient);
    discoveryApi = DiscoveryApiService(apiClient: this.apiClient);
    favouritesApi = FavouritesApiService(apiClient: this.apiClient);
    bookingApi = BookingApiService(apiClient: this.apiClient);
    notificationApi = NotificationApiService(apiClient: this.apiClient);
    ownerApi = OwnerApiService(apiClient: this.apiClient);
  }

  final AuthService authService;
  final ApiClient apiClient;

  late final UserApiService userApi;
  late final DiscoveryApiService discoveryApi;
  late final FavouritesApiService favouritesApi;
  late final BookingApiService bookingApi;
  late final NotificationApiService notificationApi;
  late final OwnerApiService ownerApi;

  UserProfile? user;
  UserRole? role;
  String name = '';
  String phone = '';
  bool loggedIn = false;
  UserLocation? location;
  int customerTab = 0;
  int vendorTab = 0;

  final Set<String> favoriteIds = {};
  final List<Shop> nearbyShops = [];
  final List<Shop> favouriteShops = [];
  final List<Map<String, String>> categories = [];
  final List<Booking> bookings = [];
  final List<Booking> pastBookings = [];
  final List<AppNotification> notifications = [];

  final List<Shop> ownerShops = [];
  Shop? selectedOwnerShop;
  bool ownerShopsLoaded = false;
  bool loadingOwnerShops = false;
  final List<Booking> ownerTodayBookings = [];

  bool isLoading = false;
  String? errorMessage;
  bool isInitialized = false;
  bool loadingShops = false;
  String? shopsError;
  final Map<String, String> loadErrors = {};
  int _shopRequest = 0;

  String _errorText(Object error) => error is ApiException
      ? error.message
      : 'Unable to load data. Please try again.';

  void _requireLogin() {
    if (!loggedIn) {
      throw ApiException(
        statusCode: 401,
        code: 'UNAUTHENTICATED',
        message: 'Please sign in to continue.',
      );
    }
  }

  int get unreadNotificationCount =>
      notifications.where((n) => !n.isRead).length;

  Future<void> init() async {
    if (isInitialized) return;
    try {
      await ApiConfig.init();
      await authService.init();

      if (authService.isAuthenticated) {
        try {
          user = await userApi.getProfile();
          name = user?.displayName ?? '';
          phone = user?.phoneNumber ?? '';
          role = user?.activeRole == 'owner'
              ? UserRole.vendor
              : UserRole.customer;
          loggedIn = true;
          await _loadInitialData();
        } on ApiException catch (e) {
          if (e.isUnauthorized || e.isProfileNotFound) {
            await authService.clearSession();
            loggedIn = false;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppSession init error]: $e');
      }
    } finally {
      isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      loadCategories(),
      loadFavourites(),
      loadBookings(),
      loadNotifications(),
      if (role == UserRole.vendor || (user?.isOwner ?? false)) loadOwnerShops(),
    ]);
  }

  void selectRole(UserRole value) {
    role = value;
    notifyListeners();
  }

  void setProfile({required String name, required String phone}) {
    this.name = name;
    this.phone = phone;
    notifyListeners();
  }

  void setLocation(UserLocation value) {
    location = value;
    loadNearbyShops(refresh: true);
    notifyListeners();
  }

  void setCustomerTab(int index) {
    customerTab = index;
    notifyListeners();
  }

  void setVendorTab(int index) {
    vendorTab = index;
    notifyListeners();
  }

  bool isFavorite(String shopId) => favoriteIds.contains(shopId);

  // ---------------------------------------------------------------------------
  // AUTH & ONBOARDING
  // ---------------------------------------------------------------------------

  Future<bool> loginWithPhoneOtp({
    required String name,
    required String phone,
    required String otp,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // 1. Authenticate against Firebase Auth to obtain ID token
      await authService.authenticateWithPhone(
        phone: phone,
        otp: otp,
        name: name,
      );

      // Existing profiles must not be overwritten by another login.
      final initialRoleStr = role == UserRole.vendor ? 'owner' : 'customer';
      try {
        user = await userApi.getProfile();
      } on ApiException catch (e) {
        if (!e.isProfileNotFound) rethrow;
        user = await userApi.onboard(
          displayName: name.trim().isEmpty ? 'Customer' : name.trim(),
          initialRole: initialRoleStr,
          acceptedTermsVersion: 'v1',
          acceptedPrivacyVersion: 'v1',
        );
      }

      this.name = user?.displayName ?? name;
      this.phone = user?.phoneNumber ?? phone;
      role = user?.activeRole == 'owner' ? UserRole.vendor : UserRole.customer;
      loggedIn = true;

      await _loadInitialData();

      isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      isLoading = false;
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      isLoading = false;
      errorMessage = 'Failed to sign in. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final installationId = await authService.getInstallationId();
      await userApi.removeDevice(installationId);
    } catch (_) {}

    await authService.clearSession();
    apiClient.setAuthToken(null);
    name = '';
    phone = '';
    _shopRequest++;
    loadingShops = false;
    favoriteIds.clear();
    notifications.clear();
    nearbyShops.clear();
    categories.clear();
    loadErrors.clear();
    shopsError = null;
    errorMessage = null;
    user = null;
    loggedIn = false;
    role = null;
    location = null;
    customerTab = 0;
    vendorTab = 0;
    bookings.clear();
    pastBookings.clear();
    favouriteShops.clear();
    ownerShopsLoaded = false;
    ownerShops.clear();
    selectedOwnerShop = null;
    ownerTodayBookings.clear();
    notifyListeners();
  }

  void updateCurrentUser(UserProfile updated) {
    user = updated;
    name = updated.displayName;
    if (updated.phoneNumber != null) phone = updated.phoneNumber!;
    notifyListeners();
  }

  Future<void> enrollAsOwner() async {
    isLoading = true;
    notifyListeners();
    try {
      user = await userApi.enrollOwner();
      role = UserRole.vendor;
      await loadOwnerShops();
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchRole(UserRole targetRole) async {
    final roleStr = targetRole == UserRole.vendor ? 'owner' : 'customer';
    if (user != null && user!.roles.contains(roleStr)) {
      try {
        user = await userApi.switchActiveRole(roleStr);
        role = targetRole;
        notifyListeners();
      } catch (e) {
        rethrow;
      }
    } else if (targetRole == UserRole.vendor) {
      await enrollAsOwner();
    } else {
      role = targetRole;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // DISCOVERY & SHOPS
  // ---------------------------------------------------------------------------

  Future<void> loadCategories() async {
    loadErrors.remove('categories');
    try {
      final list = await discoveryApi.getCategories();
      categories
        ..clear()
        ..addAll(list);
      notifyListeners();
    } catch (e) {
      loadErrors['categories'] = _errorText(e);
      notifyListeners();
    }
  }

  Future<void> loadNearbyShops({String? category, bool refresh = false}) async {
    final request = ++_shopRequest;
    loadingShops = true;
    shopsError = null;
    notifyListeners();
    try {
      final list = await discoveryApi.getNearbyShops(
        latitude: location?.latitude ?? 12.9352,
        longitude: location?.longitude ?? 77.6245,
        radiusKm: 10,
        category: category,
        limit: 30,
      );
      if (request != _shopRequest) return;
      nearbyShops
        ..clear()
        ..addAll(
          list.map((s) => s.copyWith(isFavourite: favoriteIds.contains(s.id))),
        );
    } catch (e) {
      if (request != _shopRequest) return;
      nearbyShops.clear();
      shopsError = _errorText(e);
    } finally {
      if (request == _shopRequest) {
        loadingShops = false;
        notifyListeners();
      }
    }
  }

  Future<Shop> getShopDetail(String shopId) async {
    final shop = await discoveryApi.getShopDetail(shopId);
    return shop.copyWith(isFavourite: favoriteIds.contains(shop.id));
  }

  Future<List<AvailabilitySlot>> getAvailability(String shopId, String date) =>
      discoveryApi.getAvailability(carWashId: shopId, date: date);

  // ---------------------------------------------------------------------------
  // FAVOURITES
  // ---------------------------------------------------------------------------

  Future<void> loadFavourites() async {
    if (!loggedIn) return;
    loadErrors.remove('favourites');
    try {
      final list = await favouritesApi.getFavourites();
      favouriteShops
        ..clear()
        ..addAll(list);
      favoriteIds
        ..clear()
        ..addAll(list.map((s) => s.id));
      notifyListeners();
    } catch (e) {
      loadErrors['favourites'] = _errorText(e);
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String shopId) async {
    if (!loggedIn) return;
    try {
      if (favoriteIds.contains(shopId)) {
        await favouritesApi.removeFavourite(shopId);
        favoriteIds.remove(shopId);
        favouriteShops.removeWhere((s) => s.id == shopId);
      } else {
        await favouritesApi.addFavourite(shopId);
        favoriteIds.add(shopId);
        final shop = nearbyShops.where((s) => s.id == shopId).firstOrNull;
        if (shop != null) favouriteShops.add(shop);
      }
      loadErrors.remove('favourites');
    } catch (e) {
      loadErrors['favourites'] = _errorText(e);
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // BOOKINGS
  // ---------------------------------------------------------------------------

  Future<void> loadBookings() async {
    if (!loggedIn) return;
    try {
      final lists = await Future.wait([
        bookingApi.getMyBookings(tab: 'ongoing'),
        bookingApi.getMyBookings(tab: 'completed'),
      ]);
      bookings
        ..clear()
        ..addAll(lists[0]);
      pastBookings
        ..clear()
        ..addAll(lists[1]);
      loadErrors.remove('bookings');
    } catch (e) {
      loadErrors['bookings'] = _errorText(e);
    }
    notifyListeners();
  }

  Future<Booking> createBooking({
    required String carWashId,
    required String serviceId,
    required String date,
    required String startAt,
    Shop? shopSnapshot,
    ShopService? serviceSnapshot,
    String? idempotencyKey,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      _requireLogin();
      final result = await bookingApi.createBooking(
        carWashId: carWashId,
        serviceId: serviceId,
        date: date,
        startAt: startAt,
        idempotencyKey: idempotencyKey,
      );
      bookings.removeWhere((b) => b.id == result.id);
      bookings.insert(0, result);
      isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      _requireLogin();
      final cancelled = await bookingApi.cancelBooking(bookingId);
      final index = bookings.indexWhere((b) => b.id == bookingId);
      if (index >= 0) {
        final updated = cancelled;
        bookings.removeAt(index);
        pastBookings.insert(0, updated);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Notifications are returned by the API, including a valid empty inbox.
  Future<void> loadNotifications({String type = 'all'}) async {
    if (!loggedIn) return;
    try {
      final list = await notificationApi.getNotifications(type: type);
      notifications
        ..clear()
        ..addAll(list);
      loadErrors.remove('notifications');
    } catch (e) {
      loadErrors['notifications'] = _errorText(e);
    }
    notifyListeners();
  }

  Future<void> markNotificationRead(String id) async {
    try {
      if (loggedIn) {
        await notificationApi.markRead(notificationIds: [id]);
      }
      final index = notifications.indexWhere((n) => n.id == id);
      if (index >= 0) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllNotificationsRead() async {
    try {
      if (loggedIn) {
        await notificationApi.markRead(markAll: true);
      }
      for (var i = 0; i < notifications.length; i++) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }
      notifyListeners();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // VENDOR / OWNER
  // ---------------------------------------------------------------------------

  Future<void> loadOwnerShops() async {
    if (!loggedIn || loadingOwnerShops) return;
    loadingOwnerShops = true;
    loadErrors.remove('ownerShops');
    notifyListeners();
    try {
      final list = await ownerApi.getOwnerShops();
      final selectedId = selectedOwnerShop?.id;
      ownerShops
        ..clear()
        ..addAll(list);
      selectedOwnerShop =
          list.where((shop) => shop.id == selectedId).firstOrNull ??
          list.firstOrNull;
      ownerShopsLoaded = true;
      ownerTodayBookings.clear();
      if (selectedOwnerShop?.status == 'active') {
        final today = DateTime.now().toIso8601String().split('T').first;
        await loadOwnerTodayBookings(selectedOwnerShop!.id, today);
      }
    } catch (e) {
      loadErrors['ownerShops'] = _errorText(e);
    } finally {
      loadingOwnerShops = false;
      notifyListeners();
    }
  }

  Future<Shop> submitOwnerOnboarding({
    String? shopId,
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    _requireLogin();
    final shop = await ownerApi.submitOnboarding(
      shopId: shopId,
      body: body,
      idempotencyKey: idempotencyKey,
    );
    ownerShops.removeWhere((item) => item.id == shop.id);
    ownerShops.insert(0, shop);
    selectedOwnerShop = shop;
    ownerShopsLoaded = true;
    loadErrors.remove('ownerShops');
    notifyListeners();
    return shop;
  }

  Future<void> loadOwnerTodayBookings(String carWashId, String date) async {
    loadErrors.remove('owner');
    try {
      final list = await ownerApi.getOwnerBookings(
        carWashId: carWashId,
        date: date,
      );
      ownerTodayBookings
        ..clear()
        ..addAll(list);
      notifyListeners();
    } catch (e) {
      loadErrors['owner'] = _errorText(e);
      notifyListeners();
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      final updated = await ownerApi.updateBookingStatus(
        bookingId: bookingId,
        status: status,
      );
      final idx = ownerTodayBookings.indexWhere((b) => b.id == bookingId);
      if (idx >= 0) {
        ownerTodayBookings[idx] = updated;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }
}

class SessionScope extends InheritedNotifier<AppSession> {
  const SessionScope({
    super.key,
    required AppSession session,
    required super.child,
  }) : super(notifier: session);

  static AppSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope not found in widget tree');
    return scope!.notifier!;
  }
}
