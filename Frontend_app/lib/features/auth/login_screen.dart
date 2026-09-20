import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/user_role.dart';
import '../../core/services/app_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/buttons.dart';
import '../customer/customer_shell.dart';
import '../vendor/onboarding/vendor_onboarding_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const route = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController(text: 'Shamil P');
  final _phone = TextEditingController();
  bool _accepted = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _canSend {
    return _name.text.trim().length >= 2 &&
        _phone.text.trim().length == 10 &&
        _accepted;
  }

  void _sendOtp() {
    final session = SessionScope.of(context);
    session.setProfile(name: _name.text.trim(), phone: _phone.text.trim());
    Navigator.of(context).pushNamed(OtpScreen.route);
  }

  void _socialLogin() {
    final session = SessionScope.of(context);
    session.setProfile(
      name: _name.text.trim().isEmpty ? 'Raghavendra' : _name.text.trim(),
      phone: _phone.text.trim().isEmpty ? '8865745553' : _phone.text.trim(),
    );
    session.completeLogin();
    final route = session.role == UserRole.vendor
        ? VendorOnboardingScreen.route
        : CustomerShell.route;
    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBackCircle(),
              const SizedBox(height: 28),
              Text(
                'Let’s get started',
                style: GoogleFonts.montserrat(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your mobile number to\ncontinue.',
                style: GoogleFonts.montserrat(fontSize: 16, color: AppColors.muted),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _name,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Your name',
                  labelStyle: GoogleFonts.montserrat(color: AppColors.mutedLight, fontSize: 12),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phone,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+91',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 22,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          color: AppColors.fieldBorder,
                        ),
                      ],
                    ),
                  ),
                  hintText: 'Enter mobile number',
                  hintStyle: GoogleFonts.montserrat(color: AppColors.mutedLight),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _accepted,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (value) => setState(() => _accepted = value ?? false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'I have read and accept the\n',
                        style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.ink),
                        children: [
                          TextSpan(
                            text: 'terms and conditions',
                            style: GoogleFonts.montserrat(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' and\n'),
                          TextSpan(
                            text: 'privacy policy.',
                            style: GoogleFonts.montserrat(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 260,
                  child: AppPrimaryButton(
                    label: 'Send OTP',
                    onPressed: _canSend ? _sendOtp : null,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('OR', style: GoogleFonts.montserrat(color: AppColors.muted)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 18),
              AppSocialButton(
                label: 'Sign in with Google',
                icon: const _GoogleMark(),
                onPressed: _socialLogin,
              ),
              const SizedBox(height: 12),
              AppSocialButton(
                label: 'Sign in with Apple',
                icon: const Icon(Icons.apple, size: 22),
                onPressed: _socialLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 10,
      backgroundColor: Colors.white,
      child: Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}
