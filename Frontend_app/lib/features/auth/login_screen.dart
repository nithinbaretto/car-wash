import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/app_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/widgets/buttons.dart';
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
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    _nameFocus.addListener(() => setState(() {}));
    _phoneFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
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

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.primaryDeep,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppBackCircle(
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const Spacer(),
                      const BrandMark(size: 36),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Let’s get\nstarted',
                    style: AppText.display(
                      size: 40,
                      height: 1.05,
                      letterSpacing: -1,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Enter your mobile number to continue.',
                    style: AppText.ui(
                      size: 15,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your name',
                            style: AppText.ui(
                              size: 13,
                              weight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _InputShell(
                            focused: _nameFocus.hasFocus,
                            child: TextField(
                              controller: _name,
                              focusNode: _nameFocus,
                              onChanged: (_) => setState(() {}),
                              textCapitalization: TextCapitalization.words,
                              style: AppText.ui(
                                size: 17,
                                weight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintText: 'Your full name',
                                hintStyle: AppText.ui(
                                  size: 17,
                                  color: AppColors.mutedLight,
                                ),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    color: AppColors.mutedLight,
                                    size: 22,
                                  ),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 0,
                                  minHeight: 0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Text(
                                'Mobile number',
                                style: AppText.ui(
                                  size: 13,
                                  weight: FontWeight.w600,
                                  color: AppColors.muted,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_phone.text.length}/10',
                                style: AppText.ui(
                                  size: 12,
                                  weight: FontWeight.w600,
                                  color: _phone.text.length == 10
                                      ? AppColors.open
                                      : AppColors.mutedLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const _CountryChip(),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _InputShell(
                                  focused: _phoneFocus.hasFocus,
                                  child: TextField(
                                    controller: _phone,
                                    focusNode: _phoneFocus,
                                    onChanged: (_) => setState(() {}),
                                    keyboardType: TextInputType.phone,
                                    style: AppText.ui(
                                      size: 18,
                                      weight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    decoration: InputDecoration(
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      hintText: '00000 00000',
                                      hintStyle: AppText.ui(
                                        size: 18,
                                        weight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                        color: AppColors.mutedLight,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _TermsTile(
                            accepted: _accepted,
                            onTap: () => setState(() => _accepted = !_accepted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + inset),
                    child: Column(
                      children: [
                        AppPrimaryButton(
                          label: 'Send OTP',
                          trailing: const Icon(Icons.arrow_forward_rounded),
                          onPressed: _canSend ? _sendOtp : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'We’ll send a 6-digit code to verify your number.',
                          textAlign: TextAlign.center,
                          style: AppText.ui(
                            size: 13,
                            color: AppColors.mutedLight,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputShell extends StatelessWidget {
  const _InputShell({required this.focused, required this.child});

  final bool focused;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: focused ? const Color(0xFFF7FBFF) : AppColors.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: focused ? AppColors.primary : AppColors.border,
          width: focused ? 1.6 : 1,
        ),
      ),
      child: child,
    );
  }
}

class _CountryChip extends StatelessWidget {
  const _CountryChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        '+91',
        style: AppText.ui(size: 16, weight: FontWeight.w700),
      ),
    );
  }
}

class _TermsTile extends StatelessWidget {
  const _TermsTile({required this.accepted, required this.onTap});

  final bool accepted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accepted ? AppColors.primarySoft : AppColors.canvas,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accepted ? AppColors.primary : Colors.white,
                  border: Border.all(
                    color: accepted ? AppColors.primary : AppColors.fieldBorder,
                    width: 1.5,
                  ),
                ),
                child: accepted
                    ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'I have read and accept the ',
                    style: AppText.ui(
                      size: 13,
                      height: 1.4,
                      color: AppColors.ink,
                    ),
                    children: [
                      TextSpan(
                        text: 'terms and conditions',
                        style: AppText.ui(
                          size: 13,
                          height: 1.4,
                          color: AppColors.primary,
                          weight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: ' and ',
                        style: AppText.ui(
                          size: 13,
                          height: 1.4,
                          color: AppColors.ink,
                        ),
                      ),
                      TextSpan(
                        text: 'privacy policy.',
                        style: AppText.ui(
                          size: 13,
                          height: 1.4,
                          color: AppColors.primary,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
