import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/user_role.dart';
import '../../core/services/app_session.dart';
import '../../core/services/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/widgets/buttons.dart';
import '../customer/location/location_picker_screen.dart';
import '../vendor/onboarding/vendor_onboarding_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  static const route = '/otp';

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _zwsp = '\u200B';

  final _digits = List.generate(6, (_) => TextEditingController(text: _zwsp));
  final _nodes = List.generate(6, (_) => FocusNode());
  final _filled = List<bool>.filled(6, false);
  int _seconds = 30;
  Timer? _timer;
  String? _error;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    for (final node in _nodes) {
      node.addListener(_onFocusChange);
    }
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nodes.first.requestFocus();
    });
  }

  void _onFocusChange() {
    for (var i = 0; i < 6; i++) {
      if (!_nodes[i].hasFocus) continue;
      final digit = _plain(_digits[i].text);
      _digits[i].value = TextEditingValue(
        text: '$_zwsp$digit',
        selection: TextSelection(
          baseOffset: 0,
          extentOffset: _zwsp.length + digit.length,
        ),
      );
    }
    setState(() {});
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

  String _plain(String value) => value.replaceAll(RegExp(r'\D'), '');

  String get _otp => _digits.map((c) => _plain(c.text)).join();

  bool get _complete => _otp.length == 6;

  void _setBox(int index, String digit) {
    _filled[index] = digit.isNotEmpty;
    _digits[index].value = TextEditingValue(
      text: '$_zwsp$digit',
      selection: TextSelection(
        baseOffset: 0,
        extentOffset: _zwsp.length + digit.length,
      ),
    );
  }

  void _clearFrom(int index) {
    for (var i = index; i < 6; i++) {
      _setBox(i, '');
    }
  }

  void _onChanged(int index, String value) {
    if (_syncing) return;
    _syncing = true;
    _error = null;

    final pasted = _plain(value);

    if (pasted.length > 1) {
      for (var i = 0; i < 6; i++) {
        _setBox(i, i < pasted.length ? pasted[i] : '');
      }
      final next = pasted.length >= 6 ? 5 : pasted.length;
      _nodes[next].requestFocus();
      _syncing = false;
      setState(() {});
      if (pasted.length >= 6) _verify();
      return;
    }

    if (pasted.isEmpty) {
      final wasFilled = _filled[index];
      _clearFrom(index);
      if (!wasFilled && index > 0) {
        _clearFrom(index - 1);
        _nodes[index - 1].requestFocus();
      }
      _syncing = false;
      setState(() {});
      return;
    }

    _setBox(index, pasted);
    if (index < 5) {
      _nodes[index + 1].requestFocus();
    }
    _syncing = false;
    setState(() {});
    if (_otp.length == 6) _verify();
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    final isBack = event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.delete;
    if (event is! KeyDownEvent || !isBack) return KeyEventResult.ignored;

    if (_plain(_digits[index].text).isNotEmpty) {
      _setBox(index, '');
      _clearFrom(index);
      setState(() => _error = null);
      return KeyEventResult.handled;
    }

    if (index > 0) {
      _setBox(index - 1, '');
      _clearFrom(index - 1);
      _nodes[index - 1].requestFocus();
      setState(() => _error = null);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _verify() {
    if (_otp != MockData.otpCode) {
      setState(() => _error = 'Invalid code. Try ${MockData.otpCode}');
      return;
    }
    final session = SessionScope.of(context);
    session.completeLogin();
    final route = session.role == UserRole.vendor
        ? VendorOnboardingScreen.route
        : LocationPickerScreen.route;
    Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _digits) {
      c.dispose();
    }
    for (final n in _nodes) {
      n
        ..removeListener(_onFocusChange)
        ..dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final mm = (_seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (_seconds % 60).toString().padLeft(2, '0');

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
                    'Enter OTP',
                    style: AppText.display(
                      size: 40,
                      height: 1.05,
                      letterSpacing: -1,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'We’ve sent a 6-digit code to',
                    style: AppText.ui(
                      size: 15,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+91 ${session.phone}',
                    style: AppText.ui(
                      size: 16,
                      weight: FontWeight.w700,
                      color: Colors.white,
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
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verification code',
                            style: AppText.ui(
                              size: 13,
                              weight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: List.generate(6, (index) {
                              final filled = _plain(_digits[index].text).isNotEmpty;
                              final focused = _nodes[index].hasFocus;
                              final hasError = _error != null;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: index == 5 ? 0 : 8),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    height: 62,
                                    decoration: BoxDecoration(
                                      color: focused
                                          ? const Color(0xFFF7FBFF)
                                          : AppColors.canvas,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: hasError
                                            ? AppColors.heart
                                            : focused
                                                ? AppColors.primary
                                                : filled
                                                    ? AppColors.primarySoft
                                                    : AppColors.border,
                                        width: focused || hasError ? 1.6 : 1,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Focus(
                                      onKeyEvent: (_, event) => _onKey(index, event),
                                      child: TextField(
                                        controller: _digits[index],
                                        focusNode: _nodes[index],
                                        textAlign: TextAlign.center,
                                        keyboardType: TextInputType.number,
                                        showCursor: false,
                                        style: AppText.ui(
                                          size: 22,
                                          weight: FontWeight.w700,
                                          height: 1,
                                        ),
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(8),
                                        ],
                                        decoration: const InputDecoration(
                                          filled: false,
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          isCollapsed: true,
                                        ),
                                        onTap: () {
                                          final digit = _plain(_digits[index].text);
                                          _digits[index].selection = TextSelection(
                                            baseOffset: 0,
                                            extentOffset: _zwsp.length + digit.length,
                                          );
                                        },
                                        onChanged: (value) => _onChanged(index, value),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 22),
                          if (_error != null) ...[
                            Text(
                              _error!,
                              style: AppText.ui(
                                size: 13,
                                weight: FontWeight.w600,
                                color: AppColors.heart,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Center(
                            child: _seconds > 0
                                ? Text(
                                    'Resend OTP in $mm:$ss',
                                    style: AppText.ui(
                                      size: 14,
                                      color: AppColors.mutedLight,
                                    ),
                                  )
                                : TextButton(
                                    onPressed: _startTimer,
                                    child: Text(
                                      'Resend OTP',
                                      style: AppText.ui(
                                        size: 15,
                                        weight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
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
                          label: 'Verify',
                          trailing: const Icon(Icons.arrow_forward_rounded),
                          onPressed: _complete ? _verify : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Didn’t get it? Check your messages or resend.',
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
