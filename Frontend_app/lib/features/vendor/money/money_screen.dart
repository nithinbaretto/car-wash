import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/services/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  Map<String, dynamic>? _earnings;
  String? _error;
  bool _loading = true;

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
          session.loadErrors['owner'] ?? 'Create a shop to view earnings.',
        );
      }
      final data = await session.ownerApi.getEarnings(
        shop.id,
        DateFormat('yyyy-MM-dd').format(DateTime.now()),
      );
      if (mounted) setState(() => _earnings = data);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException ? e.message : e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _amount(String key) => NumberFormat.currency(
    name: _earnings?['currency']?.toString() ?? 'INR',
    decimalDigits: 2,
  ).format(((_earnings?[key] as num?) ?? 0) / 100);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Money', style: AppText.display()),
            const SizedBox(height: 4),
            Text(
              'Revenue from completed washes',
              style: GoogleFonts.figtree(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null) ...[
              Text(_error!),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today',
                      style: GoogleFonts.figtree(color: Colors.white70),
                    ),
                    Text(
                      _amount('todayMinor'),
                      style: AppText.display(size: 32, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _row('Last 7 days', _amount('weekMinor')),
              _row('Completed today', '${_earnings?['completedToday'] ?? 0}'),
              _row(
                'Completed in 7 days',
                '${_earnings?['completedWeek'] ?? 0}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.figtree(color: AppColors.muted),
          ),
        ),
        Text(value, style: GoogleFonts.figtree(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
