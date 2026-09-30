import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/models/availability_slot.dart';
import '../../../core/models/shop_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';

class WalkInScreen extends StatefulWidget {
  const WalkInScreen({super.key});

  @override
  State<WalkInScreen> createState() => _WalkInScreenState();
}

class _WalkInScreenState extends State<WalkInScreen> {
  final _name = TextEditingController();
  final _vehicle = TextEditingController();
  final _form = GlobalKey<FormState>();
  List<ShopService> _services = [];
  List<AvailabilitySlot> _slots = [];
  String? _serviceId;
  String? _startAt;
  String? _shopId;
  String? _error;
  String? _attemptPayload;
  String? _attemptKey;
  bool _loading = true;
  bool _saving = false;
  String get _today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final session = SessionScope.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (session.selectedOwnerShop == null) await session.loadOwnerShops();
      final shop = session.selectedOwnerShop;
      if (shop == null) {
        throw StateError(
          session.loadErrors['owner'] ??
              'Create a shop before adding walk-ins.',
        );
      }
      final services = await session.ownerApi.getServices(shop.id);
      final slots = await session.ownerApi.getAvailability(shop.id, _today);
      if (!mounted) return;
      setState(() {
        _shopId = shop.id;
        _services = services.where((s) => s.active).toList();
        _slots = slots.where((s) => s.isAvailable).toList();
        _serviceId = _services.firstOrNull?.id;
        _startAt = _slots.firstOrNull?.startAt;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException ? e.message : e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() ||
        _shopId == null ||
        _serviceId == null ||
        _startAt == null) {
      return;
    }
    final session = SessionScope.of(context);
    final date = _today;
    final payload =
        '$_shopId|$_serviceId|${_name.text.trim()}|${_vehicle.text.trim()}|$date|$_startAt';
    if (_attemptPayload != payload) {
      _attemptPayload = payload;
      _attemptKey = session.bookingApi.generateIdempotencyKey();
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await session.ownerApi.createWalkIn(
        carWashId: _shopId!,
        serviceId: _serviceId!,
        customerName: _name.text.trim(),
        vehicle: _vehicle.text.trim(),
        date: date,
        startAt: _startAt!,
        idempotencyKey: _attemptKey!,
      );
      await session.loadOwnerTodayBookings(_shopId!, date);
      if (!mounted) return;
      _name.clear();
      _vehicle.clear();
      _attemptKey = null;
      _attemptPayload = null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Walk-in added to the queue.')),
      );
      await _load();
      session.setVendorTab(0);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException
              ? e.message
              : 'Unable to add walk-in. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _vehicle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: RefreshIndicator(
      onRefresh: _saving ? () async {} : _load,
      child: Form(
        key: _form,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Walk-in', style: AppText.display()),
            const SizedBox(height: 4),
            Text(
              'Add a customer to an available bay today.',
              style: GoogleFonts.figtree(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                TextButton(
                  onPressed: _saving ? null : _load,
                  child: const Text('Refresh availability'),
                ),
              ],
              TextFormField(
                controller: _name,
                enabled: !_saving,
                decoration: const InputDecoration(labelText: 'Customer name'),
                maxLength: 80,
                validator: (value) => (value?.trim().length ?? 0) < 2
                    ? 'Enter the customer name.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vehicle,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Vehicle registration',
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 40,
                validator: (value) => ((value?.trim().length ?? 0) < 2)
                    ? 'Enter the vehicle registration.'
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Service',
                style: GoogleFonts.figtree(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_services.isEmpty)
                const Text(
                  'Add an active service to your shop to accept walk-ins.',
                ),
              Wrap(
                spacing: 8,
                children: _services
                    .map(
                      (service) => ChoiceChip(
                        label: Text(
                          '${service.name} · ${service.formattedPrice}',
                        ),
                        selected: _serviceId == service.id,
                        selectedColor: AppColors.primarySoft,
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => _serviceId = service.id),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Available bays today',
                style: GoogleFonts.figtree(fontWeight: FontWeight.w600),
              ),
              if (_slots.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No available slots today. Configure availability for this shop.',
                  ),
                ),
              Wrap(
                spacing: 8,
                children: _slots
                    .map(
                      (slot) => ChoiceChip(
                        label: Text(slot.label),
                        selected: _startAt == slot.startAt,
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => _startAt = slot.startAt),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: _saving ? 'Adding walk-in...' : 'Add to queue',
                onPressed: _saving || _serviceId == null || _startAt == null
                    ? null
                    : _save,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
