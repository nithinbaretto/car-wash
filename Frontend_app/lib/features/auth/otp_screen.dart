import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/user_role.dart';
import '../../core/services/app_session.dart';
import '../../core/services/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/buttons.dart';
import '../customer/customer_shell.dart';
import '../vendor/onboarding/vendor_onboarding_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  static const route = '/otp';

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _digits = List.generate(6, (_) => TextEditingController());
  final _focus = List.generate(6, (_) => FocusNode());
  int _seconds = 30;
  Timer? _timer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        timer.cancel();
        setState(() {});
        return;
      }
      setState(() => _seconds--);
    });
  }

  String get _code => _digits.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    _error = null;
    if (value.isNotEmpty && index < 5) {
      _focus[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focus[index - 1].requestFocus();
    }
    if (_code.length == 6) {
      _verify();
    }
    setState(() {});
  }

  void _verify() {
    if (_code != MockData.otpCode) {
      setState(() => _error = 'Use mock OTP ${MockData.otpCode}');
      return;
    }
    final session = SessionScope.of(context);
    session.completeLogin();
    final route = session.role == UserRole.vendor
        ? VendorOnboardingScreen.route
        : CustomerShell.route;
    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _digits) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final mm = (_seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (_seconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBackCircle(),
              const SizedBox(height: 28),
              Text(
                'Enter OTP',
                style: GoogleFonts.montserrat(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We’ve sent a 6-digit code to\n+91 ${session.phone}',
                style: GoogleFonts.montserrat(fontSize: 16, color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 46,
                    height: 54,
                    child: TextField(
                      controller: _digits[index],
                      focusNode: _focus[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.fieldBorder),
                        ),
                      ),
                      onChanged: (value) => _onChanged(index, value),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 22),
              Center(
                child: _seconds > 0
                    ? Text(
                        'Resend OTP in $mm:${ss}s',
                        style: GoogleFonts.montserrat(color: AppColors.mutedLight),
                      )
                    : TextButton(
                        onPressed: _startTimer,
                        child: Text(
                          'Resend OTP',
                          style: GoogleFonts.montserrat(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    _error!,
                    style: GoogleFonts.montserrat(color: AppColors.heart),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
