import 'package:flutter/material.dart';

import '../../../core/models/shop.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/app_session.dart';
import '../../../core/widgets/buttons.dart';
import 'onboarding_draft.dart';

/// Maintains one explicit day at a time so successful writes and retries remain clear.
class VendorAvailabilityScreen extends StatefulWidget {
  const VendorAvailabilityScreen({super.key, required this.shop});
  final Shop shop;
  @override
  State<VendorAvailabilityScreen> createState() =>
      _VendorAvailabilityScreenState();
}

class _VendorAvailabilityScreenState extends State<VendorAvailabilityScreen> {
  final _opens = TextEditingController();
  final _closes = TextEditingController();
  final _capacity = TextEditingController(text: '1');
  final _duration = TextEditingController();
  DateTime? _date;
  bool _busy = false;
  String? _error;
  String? _existing;
  int _longestService = 0;

  @override
  void dispose() {
    for (final field in [_opens, _closes, _capacity, _duration]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now().toUtc().add(
      const Duration(hours: 5, minutes: 30),
    );
    final today = DateTime(now.year, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDate: _date ?? today,
    );
    if (selected == null || !mounted) return;
    final session = SessionScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
      _date = selected;
      _existing = null;
    });
    try {
      final services = await session.ownerApi.getServices(widget.shop.id);
      if (!mounted) return;
      _longestService = services
          .where((service) => service.active)
          .fold<int>(
            0,
            (longest, service) => service.durationMinutes > longest
                ? service.durationMinutes
                : longest,
          );
      _duration.text = _longestService > 0 ? '$_longestService' : '';
      final slots = await session.ownerApi.getAvailability(
        widget.shop.id,
        _day!,
      );
      if (!mounted) return;
      setState(() {
        _existing = slots.isEmpty
            ? 'No slots saved for this date.'
            : slots
                  .map(
                    (slot) =>
                        '${slot.startAt}–${slot.endAt}, capacity ${slot.capacity}',
                  )
                  .join('\n');
        if (slots.isNotEmpty) {
          _opens.text = slots.first.startAt;
          _closes.text = slots.last.endAt;
          _capacity.text = '${slots.first.capacity}';
        } else {
          _opens.clear();
          _closes.clear();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException
              ? e.message
              : 'Unable to load this date. Please choose it again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? get _day => _date?.toIso8601String().split('T').first;

  Future<void> _save() async {
    if (_date == null || _existing == null) return;
    final session = SessionScope.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final length = int.tryParse(_duration.text) ?? 0;
      if (_longestService == 0 || length < _longestService) {
        throw const FormatException(
          'Slots must fit the longest active service.',
        );
      }
      final days = buildOnboardingAvailability(
        firstDate: _date!,
        days: 1,
        opensAt: _opens.text.trim(),
        closesAt: _closes.text.trim(),
        slotMinutes: length,
        capacity: int.tryParse(_capacity.text) ?? 0,
      );
      final slots = await session.ownerApi.setAvailability(
        carWashId: widget.shop.id,
        date: _day!,
        slots: List<Map<String, dynamic>>.from(days.single['slots'] as List),
      );
      if (!mounted) return;
      setState(
        () => _existing = slots
            .map(
              (slot) =>
                  '${slot.startAt}–${slot.endAt}, capacity ${slot.capacity}',
            )
            .join('\n'),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Availability saved for $_day.')));
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiException
              ? e.message
              : e is FormatException
              ? e.message
              : 'Unable to save availability. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Manage booking dates')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(widget.shop.name, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const Text(
          'Add or update one day at a time. All times are India time (Asia/Kolkata). Saving replaces that day’s schedule. Existing bookings are protected; conflicting changes will be rejected.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _chooseDate,
          icon: const Icon(Icons.calendar_month),
          label: Text(_day ?? 'Choose booking date'),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_existing != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_existing!),
          ),
        for (final field in [
          (_opens, 'Opens at (HH:mm)'),
          (_closes, 'Closes at (HH:mm)'),
          (_duration, 'Slot duration (minutes)'),
          (_capacity, 'Simultaneous bookings per slot'),
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextField(
              enabled: !_busy,
              controller: field.$1,
              decoration: InputDecoration(labelText: field.$2),
            ),
          ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 20),
        AppPrimaryButton(
          label: _busy ? 'Please wait…' : 'Save availability',
          onPressed: _busy || _existing == null ? null : _save,
        ),
      ],
    ),
  );
}
