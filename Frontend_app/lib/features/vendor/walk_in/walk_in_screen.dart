import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/buttons.dart';

class WalkInScreen extends StatefulWidget {
  const WalkInScreen({super.key});

  @override
  State<WalkInScreen> createState() => _WalkInScreenState();
}

class _WalkInScreenState extends State<WalkInScreen> {
  final _name = TextEditingController();
  final _vehicle = TextEditingController();
  String _service = 'Quick';

  @override
  void dispose() {
    _name.dispose();
    _vehicle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            'Walk-in',
            style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a customer who arrived without a booking.',
            style: GoogleFonts.montserrat(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Customer name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _vehicle,
            decoration: const InputDecoration(labelText: 'Vehicle'),
          ),
          const SizedBox(height: 16),
          Text('Service', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Quick', 'Interior', 'Complete', 'Premium']
                .map(
                  (service) => ChoiceChip(
                    label: Text(service),
                    selected: _service == service,
                    selectedColor: AppColors.primarySoft,
                    onSelected: (_) => setState(() => _service = service),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),
          AppPrimaryButton(
            label: 'Add to bay',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Added ${_name.text.isEmpty ? 'walk-in' : _name.text} · $_service',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
