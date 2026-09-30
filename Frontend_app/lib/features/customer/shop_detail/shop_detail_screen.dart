import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/models/availability_slot.dart';
import '../../../core/models/shop.dart';
import '../../../core/models/shop_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/buttons.dart';

class ShopDetailScreen extends StatefulWidget {
  const ShopDetailScreen({super.key, required this.shop});

  static const route = '/shop';

  final Shop shop;

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  late Shop _shop;
  bool _bookingInProgress = false;

  ShopService? _selectedService;
  String _selectedDate = '';
  AvailabilitySlot? _selectedSlot;
  List<AvailabilitySlot> _slots = [];
  bool _loadingSlots = false;
  bool _loadingShop = true;
  String? _shopError;
  String? _slotsError;
  int _slotsRequest = 0;
  String? _bookingKey;
  String? _bookingPayload;

  final List<DateTime> _dates = List.generate(
    5,
    (index) => DateTime.now().add(Duration(days: index)),
  );

  @override
  void initState() {
    super.initState();
    _shop = widget.shop;
    _selectedDate = DateFormat('yyyy-MM-dd').format(_dates.first);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadFreshShopDetails();
      _loadSlotsForDate(_selectedDate);
    });
  }

  Future<void> _loadFreshShopDetails() async {
    final session = SessionScope.of(context);
    setState(() {
      _loadingShop = true;
      _shopError = null;
    });
    try {
      final fresh = await session.getShopDetail(_shop.id);
      if (mounted) {
        setState(() {
          _shop = fresh;
          _selectedService = _shop.serviceDetails
              .where((s) => s.active)
              .firstOrNull;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _shopError = e is ApiException
              ? e.message
              : 'Unable to load shop details.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingShop = false);
    }
  }

  Future<void> _loadSlotsForDate(String date) async {
    final session = SessionScope.of(context);
    final request = ++_slotsRequest;
    setState(() {
      _loadingSlots = true;
      _slotsError = null;
      _slots = [];
      _selectedSlot = null;
    });
    try {
      final slots = await session.getAvailability(_shop.id, date);
      if (mounted && request == _slotsRequest) {
        setState(() {
          _slots = slots;
          _selectedSlot = slots.where((s) => s.isAvailable).firstOrNull;
          _loadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted && request == _slotsRequest) {
        setState(() {
          _loadingSlots = false;
          _slotsError = e is ApiException
              ? e.message
              : 'Unable to load availability.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final fav = session.isFavorite(_shop.id);

    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 11,
                child: Image.asset(AppAssets.carWashCard, fit: BoxFit.cover),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const AppBackCircle(),
                      const Spacer(),
                      _round(
                        icon: fav ? Icons.favorite : Icons.favorite_border,
                        color: fav ? AppColors.heart : AppColors.ink,
                        onTap: () => session.toggleFavorite(_shop.id),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(_shop.name, style: AppText.display(size: 24)),
                    ),
                    Text(
                      _shop.isOpen ? 'Open' : 'Closed',
                      style: GoogleFonts.figtree(
                        color: _shop.isOpen ? AppColors.open : AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _shop.address,
                  style: GoogleFonts.figtree(color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF5B400), size: 18),
                    Text(
                      '  ${_shop.rating.toStringAsFixed(1)}  (${_shop.reviewCount})',
                      style: GoogleFonts.figtree(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '  ·  ${_shop.distanceLabel(fromLat: session.location?.latitude, fromLng: session.location?.longitude)}',
                      style: GoogleFonts.figtree(color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_loadingShop) const LinearProgressIndicator(),
                if (_shopError != null) ...[
                  Text(
                    _shopError!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  TextButton(
                    onPressed: _loadFreshShopDetails,
                    child: const Text('Retry shop details'),
                  ),
                ],
                if (session.loadErrors['favourites'] != null)
                  Text(
                    session.loadErrors['favourites']!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                // Services Section
                Text(
                  'Select Service',
                  style: GoogleFonts.figtree(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                if (_shop.serviceDetails.isNotEmpty)
                  Column(
                    children: _shop.serviceDetails.where((s) => s.active).map((
                      service,
                    ) {
                      final isSelected = _selectedService?.id == service.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () =>
                              setState(() => _selectedService = service),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primarySoft
                                  : AppColors.canvas,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.muted,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service.name,
                                        style: GoogleFonts.figtree(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        '${service.formattedDuration} · ${service.category.toUpperCase()}',
                                        style: GoogleFonts.figtree(
                                          color: AppColors.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  service.formattedPrice,
                                  style: GoogleFonts.figtree(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.primaryDeep,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _shop.services
                        .map(
                          (service) => Chip(
                            label: Text(service),
                            backgroundColor: AppColors.primarySoft,
                            side: BorderSide.none,
                          ),
                        )
                        .toList(),
                  ),

                const SizedBox(height: 20),

                // Date Selection
                Text(
                  'Select Date',
                  style: GoogleFonts.figtree(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _dates.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final d = _dates[index];
                      final dateStr = DateFormat('yyyy-MM-dd').format(d);
                      final isSelected = _selectedDate == dateStr;
                      final dayName = index == 0
                          ? 'Today'
                          : (index == 1
                                ? 'Tomorrow'
                                : DateFormat('EEE').format(d));
                      final dayNum = DateFormat('d MMM').format(d);

                      return InkWell(
                        onTap: () {
                          setState(() => _selectedDate = dateStr);
                          _loadSlotsForDate(dateStr);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 84,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.canvas,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayName,
                                style: GoogleFonts.figtree(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dayNum,
                                style: GoogleFonts.figtree(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Available Time Slots
                Text(
                  'Available Time Slots',
                  style: GoogleFonts.figtree(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                if (_loadingSlots)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_slotsError != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _slotsError!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      TextButton(
                        onPressed: () => _loadSlotsForDate(_selectedDate),
                        child: const Text('Retry availability'),
                      ),
                    ],
                  )
                else if (_slots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No available slots for this date.',
                      style: GoogleFonts.figtree(color: AppColors.muted),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _slots.map((slot) {
                      final isSelected = _selectedSlot?.startAt == slot.startAt;
                      final isAvailable = slot.isAvailable;

                      return ChoiceChip(
                        label: Text(slot.startAt),
                        selected: isSelected,
                        onSelected: isAvailable
                            ? (val) => setState(() => _selectedSlot = slot)
                            : null,
                        selectedColor: AppColors.primary,
                        labelStyle: GoogleFonts.figtree(
                          color: !isAvailable
                              ? AppColors.muted
                              : (isSelected ? Colors.white : AppColors.ink),
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: isAvailable
                            ? AppColors.canvas
                            : const Color(0xFFF0F0F0),
                        side: BorderSide.none,
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 20),
                Text(
                  'About',
                  style: GoogleFonts.figtree(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _shop.about,
                  style: GoogleFonts.figtree(
                    color: AppColors.muted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),

                // Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Slot',
                            style: GoogleFonts.figtree(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _selectedSlot != null
                                ? '$_selectedDate · ${_selectedSlot!.startAt}'
                                : 'Choose a time slot',
                            style: GoogleFonts.figtree(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        _selectedService != null
                            ? _selectedService!.formattedPrice
                            : 'From ₹${_shop.priceFrom}',
                        style: GoogleFonts.figtree(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.primaryDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: AppPrimaryButton(
              label: _bookingInProgress ? 'Reserving slot...' : 'Book now',
              onPressed:
                  _bookingInProgress ||
                      _loadingSlots ||
                      _loadingShop ||
                      _shopError != null ||
                      _selectedService == null ||
                      _selectedSlot == null
                  ? null
                  : () => _book(context, session),
            ),
          ),
        ],
      ),
    );
  }

  Widget _round({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Ink(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
    );
  }

  Future<void> _book(BuildContext context, AppSession session) async {
    final service = _selectedService;
    if (service == null || !service.active || _loadingSlots) return;
    final serviceId = service.id;
    final slot = _selectedSlot;

    if (slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available time slot.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final payload = '${_shop.id}|$serviceId|$_selectedDate|${slot.startAt}';
    if (_bookingPayload != payload) {
      _bookingPayload = payload;
      _bookingKey = session.bookingApi.generateIdempotencyKey();
    }
    setState(() => _bookingInProgress = true);
    try {
      await session.createBooking(
        carWashId: _shop.id,
        serviceId: serviceId,
        date: _selectedDate,
        startAt: slot.startAt,
        shopSnapshot: _shop,
        serviceSnapshot: service,
        idempotencyKey: _bookingKey,
      );

      if (!mounted) return;

      session.setCustomerTab(2); // Navigate to Bookings tab
      nav.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Booking requested for ${_shop.name} at ${slot.startAt} · Awaiting confirmation',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _bookingInProgress = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException
                ? e.message
                : 'Unable to create booking. Please try again.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
