import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/user_role.dart';
import 'mock_data.dart';

class AppSession extends ChangeNotifier {
  UserRole? role;
  String name = '';
  String phone = '';
  bool loggedIn = false;
  int customerTab = 0;
  int vendorTab = 0;

  final Set<String> favoriteIds = {'shop-sparkle'};
  final List<Booking> bookings = [];

  void selectRole(UserRole value) {
    role = value;
    notifyListeners();
  }

  void setProfile({required String name, required String phone}) {
    this.name = name;
    this.phone = phone;
    notifyListeners();
  }

  void completeLogin() {
    loggedIn = true;
    if (bookings.isEmpty) {
      bookings.addAll(MockData.seedBookings);
    }
    notifyListeners();
  }

  void logout() {
    loggedIn = false;
    role = null;
    customerTab = 0;
    vendorTab = 0;
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

  void toggleFavorite(String shopId) {
    if (!favoriteIds.add(shopId)) {
      favoriteIds.remove(shopId);
    }
    notifyListeners();
  }

  void addBooking(Booking booking) {
    bookings.insert(0, booking);
    notifyListeners();
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
    assert(scope != null, 'SessionScope not found');
    return scope!.notifier!;
  }
}
