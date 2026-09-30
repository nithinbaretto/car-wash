import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/shop.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/app_session.dart';
import '../../../core/widgets/buttons.dart';
import '../vendor_shell.dart';
import 'onboarding_draft.dart';
import 'shop_pin_picker.dart';
import 'package:latlong2/latlong.dart';

class VendorOnboardingScreen extends StatefulWidget {
  const VendorOnboardingScreen({super.key, this.shop});
  static const route = '/vendor-onboarding';
  final Shop? shop;

  @override
  State<VendorOnboardingScreen> createState() => _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState extends State<VendorOnboardingScreen> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{
    for (final name in [
      'name',
      'contactPhone',
      'line1',
      'area',
      'city',
      'state',
      'postalCode',
      'latitude',
      'longitude',
    ])
      name: TextEditingController(),
  };
  final _services = <_ServiceDraft>[];
  final _opens = TextEditingController();
  final _closes = TextEditingController();
  final _days = TextEditingController(text: '7');
  final _capacity = TextEditingController(text: '1');
  DateTime? _firstDate;
  List<Map<String, dynamic>>? _savedAvailability;
  bool _replaceSchedule = true;
  bool _loading = true;
  bool _submitting = false;
  bool _locating = false;
  bool _confirmed = false;
  String? _error;
  String? _draftKey;
  String? _retryKey;
  String? _retryPayload;
  SharedPreferences? _prefs;
  Timer? _saveTimer;
  bool _seeded = false;
  bool _completed = false;
  bool _hydrated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;
    _load();
  }

  Future<void> _load() async {
    final session = SessionScope.of(context);
    try {
      _prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      _draftKey =
          'shop-onboarding:${session.user?.uid ?? session.phone}:${widget.shop?.id ?? 'new'}';
      Map<String, dynamic>? data;
      if (widget.shop != null) {
        data = await session.ownerApi.getOnboarding(widget.shop!.id);
        if (!mounted) return;
        _fillShop(data['carWash'] as Map<String, dynamic>);
        _savedAvailability = (data['availability'] as List<dynamic>? ?? [])
            .map(
              (item) => <String, dynamic>{
                'date': item['date'],
                'slots': (item['slots'] as List<dynamic>)
                    .map(
                      (slot) => <String, dynamic>{
                        'startAt': slot['startAt'],
                        'endAt': slot['endAt'],
                        'capacity': slot['capacity'],
                        'enabled': slot['enabled'] ?? true,
                      },
                    )
                    .toList(),
              },
            )
            .toList();
        _replaceSchedule = _savedAvailability!.isEmpty;
        for (final service in data['services'] as List<dynamic>? ?? []) {
          _services.add(
            _ServiceDraft.fromJson(Map<String, dynamic>.from(service as Map)),
          );
        }
      }
      final draft = _prefs!.getString(_draftKey!);
      if (draft != null) {
        final saved = jsonDecode(draft) as Map<String, dynamic>;
        for (final field in _fields.entries) {
          field.value.text = saved[field.key]?.toString() ?? field.value.text;
        }
        for (final service in _services) {
          service.dispose();
        }
        _services.clear();
        for (final service in saved['services'] as List<dynamic>? ?? []) {
          _services.add(
            _ServiceDraft.fromDraft(Map<String, dynamic>.from(service as Map)),
          );
        }
        _opens.text = saved['opens']?.toString() ?? '';
        _closes.text = saved['closes']?.toString() ?? '';
        _days.text = saved['days']?.toString() ?? '7';
        _capacity.text = saved['capacity']?.toString() ?? '1';
        _firstDate = DateTime.tryParse(saved['firstDate']?.toString() ?? '');
        _replaceSchedule =
            saved['replaceSchedule'] as bool? ?? _replaceSchedule;
        _retryKey = saved['retryKey'] as String?;
        _retryPayload = saved['retryPayload'] as String?;
      }
      _hydrated = true;
      if (_services.isEmpty) _services.add(_ServiceDraft());
      if (_fields['contactPhone']!.text.isEmpty) {
        _fields['contactPhone']!.text = session.phone;
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _message(e);
        });
      }
    }
  }

  void _fillShop(Map<String, dynamic> shop) {
    _fields['name']!.text = shop['name']?.toString() ?? '';
    _fields['contactPhone']!.text = shop['contactPhone']?.toString() ?? '';
    final address = shop['address'] as Map<String, dynamic>? ?? {};
    final location = shop['location'] as Map<String, dynamic>? ?? {};
    for (final key in ['line1', 'area', 'city', 'state', 'postalCode']) {
      _fields[key]!.text = address[key]?.toString() ?? '';
    }
    for (final key in ['latitude', 'longitude']) {
      _fields[key]!.text = location[key]?.toString() ?? '';
    }
  }

  String _message(Object error) => error is ApiException
      ? error.message
      : error is FormatException
      ? error.message
      : 'Unable to save or load shop setup. Please retry.';

  Map<String, dynamic> _draft() => {
    for (final field in _fields.entries) field.key: field.value.text,
    'services': _services.map((service) => service.draft()).toList(),
    'opens': _opens.text,
    'closes': _closes.text,
    'days': _days.text,
    'capacity': _capacity.text,
    'firstDate': _firstDate?.toIso8601String(),
    'replaceSchedule': _replaceSchedule,
    'retryKey': _retryKey,
    'retryPayload': _retryPayload,
  };

  Future<void> _saveDraft() async {
    if (_hydrated && _prefs != null && _draftKey != null) {
      await _prefs!.setString(_draftKey!, jsonEncode(_draft()));
    }
  }

  void _changed() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 250), _saveDraft);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    if (!_completed) _saveDraft();
    for (final controller in _fields.values) {
      controller.dispose();
    }
    for (final service in _services) {
      service.dispose();
    }
    for (final controller in [_opens, _closes, _days, _capacity]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _gps() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const FormatException(
          'Location permission is unavailable. Enter the shop coordinates manually.',
        );
      }
      final point = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      _fields['latitude']!.text = point.latitude.toStringAsFixed(6);
      _fields['longitude']!.text = point.longitude.toStringAsFixed(6);
      _changed();
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_confirmed) {
      setState(
        () => _error =
            'Confirm that the business details, location, prices and dates are correct.',
      );
      return;
    }
    final session = SessionScope.of(context);
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final services = _services.map((service) => service.payload()).toList();
      if (!services.any((service) => service['active'] == true)) {
        throw const FormatException('Enable at least one service.');
      }
      final longest = services
          .where((service) => service['active'] == true)
          .map((service) => service['durationMinutes'] as int)
          .reduce(max);
      final availability = _replaceSchedule
          ? buildOnboardingAvailability(
              firstDate:
                  _firstDate ??
                  (throw const FormatException(
                    'Choose the first booking date.',
                  )),
              days: int.tryParse(_days.text) ?? 0,
              opensAt: _opens.text.trim(),
              closesAt: _closes.text.trim(),
              slotMinutes: longest,
              capacity: int.tryParse(_capacity.text) ?? 0,
            )
          : _savedAvailability!;
      final body = <String, dynamic>{
        'name': _fields['name']!.text.trim(),
        'contactPhone': _fields['contactPhone']!.text.trim(),
        'address': {
          for (final key in ['line1', 'area', 'city', 'state', 'postalCode'])
            key: _fields[key]!.text.trim(),
          'formattedAddress': [
            'line1',
            'area',
            'city',
            'state',
            'postalCode',
          ].map((key) => _fields[key]!.text.trim()).join(', '),
        },
        'location': {
          for (final key in ['latitude', 'longitude'])
            key: double.parse(_fields[key]!.text),
        },
        'categories': services
            .where((service) => service['active'] == true)
            .map((service) => service['category'] as String)
            .toSet()
            .toList(),
        'services': services,
        'availability': availability,
      };
      final shopId = widget.shop?.id;
      final encoded = jsonEncode({'shopId': shopId, 'body': body});
      // Replay an unchanged uncertain request against its original endpoint/key.
      // This recovers its current state without rewriting an admin's decision.
      if (shopId == null && (_retryPayload != encoded || _retryKey == null)) {
        final existing = await session.ownerApi.getOwnerShops();
        if (existing.isNotEmpty) {
          await session.loadOwnerShops();
          if (!mounted) return;
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(VendorShell.route, (_) => false);
          return;
        }
      }
      if (_retryPayload != encoded || _retryKey == null) {
        _retryKey =
            'onboarding-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
        _retryPayload = encoded;
      }
      _saveTimer?.cancel();
      await _saveDraft();
      await session.submitOwnerOnboarding(
        shopId: shopId,
        body: body,
        idempotencyKey: _retryKey!,
      );
      _completed = true;
      await _prefs?.remove(_draftKey!);
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(VendorShell.route, (_) => false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = _message(e);
        });
      }
    }
  }

  Widget _field(String name, String label, {TextInputType? keyboardType}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: _fields[name],
          keyboardType: keyboardType,
          onChanged: (_) => _changed(),
          decoration: InputDecoration(labelText: label),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Required';
            if (['name', 'line1', 'area', 'city', 'state'].contains(name) &&
                text.length < 2) {
              return 'Enter at least 2 characters';
            }
            if (name == 'postalCode' && (text.length < 4 || text.length > 12)) {
              return 'Enter a valid postal code';
            }
            if (name == 'contactPhone' &&
                !RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(text)) {
              return 'Use international format, e.g. +919876543210';
            }
            if (name == 'latitude' || name == 'longitude') {
              final number = double.tryParse(text);
              final limit = name == 'latitude' ? 90 : 180;
              if (number == null || !number.isFinite || number.abs() > limit) {
                return 'Enter a valid coordinate';
              }
            }
            return null;
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final loaded =
        !_loading && (widget.shop == null || _savedAvailability != null);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.shop == null ? 'List your car wash' : 'Edit shop application',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !loaded
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error ?? 'Unable to load setup'),
                  TextButton(
                    onPressed: () {
                      setState(() => _loading = true);
                      _load();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Form(
              key: _form,
              child: AbsorbPointer(
                absorbing: _submitting,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Complete your business details, services and booking schedule. Your shop becomes visible after admin approval.',
                    ),
                    const SizedBox(height: 12),
                    if (widget.shop?.reviewReason != null)
                      Text('Review feedback: ${widget.shop!.reviewReason}'),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          semanticsLabel: 'Error: $_error',
                        ),
                      ),
                    _heading('1. Business and location'),
                    _field('name', 'Shop name'),
                    _field(
                      'contactPhone',
                      'Contact phone',
                      keyboardType: TextInputType.phone,
                    ),
                    _field('line1', 'Street address'),
                    _field('area', 'Area / neighborhood'),
                    _field('city', 'City'),
                    _field('state', 'State'),
                    _field(
                      'postalCode',
                      'Postal code',
                      keyboardType: TextInputType.number,
                    ),
                    const Text(
                      'Enter the actual shop coordinates or use GPS while at the shop. Check the coordinates before submitting.',
                    ),
                    TextButton.icon(
                      onPressed: _locating ? null : _gps,
                      icon: const Icon(Icons.my_location),
                      label: Text(
                        _locating
                            ? 'Getting location…'
                            : 'Use my current location',
                      ),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Choose shop pin on map'),
                      onPressed: () async {
                        final lat = double.tryParse(_fields['latitude']!.text);
                        final lng = double.tryParse(_fields['longitude']!.text);
                        final valid =
                            lat != null &&
                            lng != null &&
                            lat.isFinite &&
                            lng.isFinite &&
                            lat.abs() <= 90 &&
                            lng.abs() <= 180;
                        final point = await Navigator.of(context).push<LatLng>(
                          MaterialPageRoute(
                            builder: (_) => ShopPinPicker(
                              initial: valid ? LatLng(lat, lng) : null,
                            ),
                          ),
                        );
                        if (point == null || !mounted) return;
                        _fields['latitude']!.text = point.latitude
                            .toStringAsFixed(6);
                        _fields['longitude']!.text = point.longitude
                            .toStringAsFixed(6);
                        _changed();
                      },
                    ),
                    _field(
                      'latitude',
                      'Shop latitude',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                    _field(
                      'longitude',
                      'Shop longitude',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                    _heading('2. Services and prices'),
                    for (var i = 0; i < _services.length; i++) _serviceCard(i),
                    TextButton.icon(
                      onPressed: _services.length >= 20
                          ? null
                          : () {
                              setState(() => _services.add(_ServiceDraft()));
                              _changed();
                            },
                      icon: const Icon(Icons.add),
                      label: const Text('Add service'),
                    ),
                    _heading('3. Booking availability'),
                    const Text(
                      'All booking times are in India time (Asia/Kolkata). Slots are sized to fit your longest enabled service.',
                    ),
                    if (_savedAvailability?.isNotEmpty == true) ...[
                      Text(
                        'Saved dates: ${_savedAvailability!.map((day) => day['date']).join(', ')}',
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Replace future schedule'),
                        value: _replaceSchedule,
                        onChanged: (value) {
                          setState(() => _replaceSchedule = value);
                          _changed();
                        },
                      ),
                    ],
                    if (_replaceSchedule) ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          _firstDate == null
                              ? 'Choose first booking date'
                              : _firstDate!.toIso8601String().split('T').first,
                        ),
                        onPressed: () async {
                          final now = DateTime.now().toUtc().add(
                            const Duration(hours: 5, minutes: 30),
                          );
                          final tomorrow = DateTime(
                            now.year,
                            now.month,
                            now.day + 1,
                          );
                          final date = await showDatePicker(
                            context: context,
                            firstDate: tomorrow,
                            lastDate: tomorrow.add(const Duration(days: 365)),
                            initialDate:
                                _firstDate != null &&
                                    !_firstDate!.isBefore(tomorrow)
                                ? _firstDate
                                : tomorrow,
                          );
                          if (date != null && mounted) {
                            setState(() => _firstDate = date);
                            _changed();
                          }
                        },
                      ),
                      _scheduleField(
                        _days,
                        'Consecutive days (1–31)',
                        number: true,
                      ),
                      _scheduleField(_opens, 'Opens at (HH:mm, e.g. 09:00)'),
                      _scheduleField(_closes, 'Closes at (HH:mm, e.g. 18:00)'),
                      _scheduleField(
                        _capacity,
                        'Simultaneous bookings per slot (1–100)',
                        number: true,
                      ),
                      const Text(
                        'The same hours apply each selected day. Any remaining time shorter than a full service is excluded. You can update dates after approval.',
                      ),
                    ],
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'I confirm these business details, shop coordinates, prices and booking dates are correct.',
                      ),
                      value: _confirmed,
                      onChanged: (value) =>
                          setState(() => _confirmed = value ?? false),
                    ),
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    AppPrimaryButton(
                      label: _submitting
                          ? 'Submitting…'
                          : widget.shop?.status == 'rejected'
                          ? 'Correct and resubmit for review'
                          : 'Submit for review',
                      onPressed: _submitting ? null : _submit,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your draft is saved on this device as you edit.',
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
  Widget _scheduleField(
    TextEditingController controller,
    String label, {
    bool number = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.datetime,
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => _changed(),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Required' : null,
    ),
  );

  Widget _serviceCard(int index) {
    final service = _services[index];
    return Card(
      key: ObjectKey(service),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('Service ${index + 1}')),
                if (_services.length > 1)
                  IconButton(
                    tooltip: 'Remove service ${index + 1}',
                    onPressed: () {
                      setState(() => _services.removeAt(index));
                      service.dispose();
                      _changed();
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            TextFormField(
              controller: service.name,
              decoration: const InputDecoration(labelText: 'Service name'),
              onChanged: (_) => _changed(),
              validator: (value) => (value?.trim().length ?? 0) < 2
                  ? 'Enter a service name'
                  : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: service.category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ['quick', 'interior', 'complete', 'premium']
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                service.category = value!;
                _changed();
              },
            ),
            TextFormField(
              controller: service.price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Price (₹)'),
              onChanged: (_) => _changed(),
              validator: (value) {
                final amount = double.tryParse(value ?? '');
                return amount == null || !amount.isFinite || amount <= 0
                    ? 'Enter a positive price'
                    : null;
              },
            ),
            TextFormField(
              controller: service.duration,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes, 5–480)',
              ),
              onChanged: (_) => _changed(),
              validator: (value) {
                final duration = int.tryParse(value ?? '') ?? 0;
                return duration < 5 || duration > 480
                    ? 'Enter 5–480 minutes'
                    : null;
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available for booking'),
              value: service.active,
              onChanged: (value) {
                setState(() => service.active = value);
                _changed();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceDraft {
  _ServiceDraft();
  final name = TextEditingController();
  final price = TextEditingController();
  final duration = TextEditingController();
  String category = 'quick';
  bool active = true;
  factory _ServiceDraft.fromJson(Map<String, dynamic> data) => _ServiceDraft()
    ..name.text = data['name']?.toString() ?? ''
    ..price.text = ((data['priceMinor'] as num? ?? 0) / 100).toStringAsFixed(2)
    ..duration.text = data['durationMinutes']?.toString() ?? ''
    ..category = data['category']?.toString() ?? 'quick'
    ..active = data['active'] as bool? ?? true;
  factory _ServiceDraft.fromDraft(Map<String, dynamic> data) => _ServiceDraft()
    ..name.text = data['name']?.toString() ?? ''
    ..price.text = data['price']?.toString() ?? ''
    ..duration.text = data['duration']?.toString() ?? ''
    ..category = data['category']?.toString() ?? 'quick'
    ..active = data['active'] as bool? ?? true;
  Map<String, dynamic> draft() => {
    'name': name.text,
    'price': price.text,
    'duration': duration.text,
    'category': category,
    'active': active,
  };
  Map<String, dynamic> payload() => {
    'name': name.text.trim(),
    'priceMinor': (double.parse(price.text) * 100).round(),
    'durationMinutes': int.parse(duration.text),
    'category': category,
    'active': active,
  };
  void dispose() {
    name.dispose();
    price.dispose();
    duration.dispose();
  }
}
