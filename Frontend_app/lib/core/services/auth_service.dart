import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../firebase_options.dart';
import '../network/api_exception.dart';

/// Firebase owns SMS challenges, verification, secure persistence and refresh.
class AuthService extends ChangeNotifier {
  AuthService({FirebaseAuth? firebaseAuth}) : _auth = firebaseAuth;

  FirebaseAuth? _auth;
  Future<void>? _initialization;
  String? _phone;
  String? _verificationId;
  int? _resendToken;
  ConfirmationResult? _confirmation;
  PhoneAuthCredential? _automaticCredential;
  String? _verifiedPhone;
  int _requestGeneration = 0;
  bool _sending = false;

  bool get isAuthenticated => _auth?.currentUser?.phoneNumber != null;
  String? get userId => _auth?.currentUser?.uid;
  bool get hasAutomaticCredential => _automaticCredential != null;

  Future<void> init() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    try {
      if (_auth == null) {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        }
        _auth = FirebaseAuth.instance;
      }
      // Remove sessions issued by the former phone/password placeholder.
      final prefs = await SharedPreferences.getInstance();
      for (final key in [
        'auth_id_token',
        'auth_refresh_token',
        'auth_token_expires_at',
        'auth_user_id',
        'auth_user_email',
        'auth_user_phone',
      ]) {
        await prefs.remove(key);
      }
      await _auth!.authStateChanges().first;
      if (_auth!.currentUser != null && !isAuthenticated) {
        await _auth!.signOut();
      }
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  static String normalizePhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s()\-]'), '');
    if (RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) return '+91$cleaned';
    if (RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(cleaned)) return cleaned;
    throw ApiException(
      statusCode: 400,
      code: 'INVALID_PHONE_NUMBER',
      message: 'Enter a valid mobile number including its country code.',
    );
  }

  Future<void> requestPhoneOtp({
    required String phone,
    bool resend = false,
  }) async {
    if (_sending) {
      throw ApiException(
        statusCode: 409,
        code: 'OTP_IN_PROGRESS',
        message: 'A code is already being requested. Please wait.',
      );
    }
    final normalized = normalizePhone(phone);
    _sending = true;
    final generation = ++_requestGeneration;
    final previousPhone = _phone;
    final resendToken = resend && previousPhone == normalized
        ? _resendToken
        : null;
    _phone = normalized;
    _verificationId = null;
    _confirmation = null;
    _automaticCredential = null;
    _verifiedPhone = null;
    try {
      await init();
      if (kIsWeb) {
        _confirmation = await _auth!.signInWithPhoneNumber(normalized);
        return;
      }
      final sent = Completer<void>();
      final request = _auth!.verifyPhoneNumber(
        phoneNumber: normalized,
        forceResendingToken: resendToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) {
          if (generation != _requestGeneration) return;
          _automaticCredential = credential;
          notifyListeners();
          if (!sent.isCompleted) sent.complete();
        },
        verificationFailed: (error) {
          if (generation != _requestGeneration) return;
          if (!sent.isCompleted) sent.completeError(_friendlyError(error));
        },
        codeSent: (verificationId, token) {
          if (generation != _requestGeneration) return;
          _verificationId = verificationId;
          _resendToken = token;
          if (!sent.isCompleted) sent.complete();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (generation != _requestGeneration) return;
          _verificationId = verificationId;
          if (!sent.isCompleted) {
            sent.completeError(
              ApiException(
                statusCode: 408,
                code: 'OTP_TIMEOUT',
                message: 'SMS request timed out. Please try again.',
              ),
            );
          }
        },
      );
      await Future.wait([
        request,
        sent.future,
      ]).timeout(const Duration(seconds: 90));
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e);
    } on TimeoutException {
      ++_requestGeneration;
      throw ApiException(
        statusCode: 408,
        code: 'OTP_TIMEOUT',
        message: 'SMS request timed out. Please try again.',
      );
    } finally {
      _sending = false;
    }
  }

  Future<Map<String, dynamic>> authenticateWithPhone({
    required String phone,
    required String otp,
    required String name,
  }) async {
    final normalized = normalizePhone(phone);
    if (_phone != normalized) {
      throw ApiException(
        statusCode: 400,
        code: 'OTP_NOT_REQUESTED',
        message: 'Request a verification code for this number first.',
      );
    }
    try {
      await init();
      if (_verifiedPhone != normalized ||
          _auth!.currentUser?.phoneNumber != normalized) {
        UserCredential result;
        if (_automaticCredential != null) {
          result = await _auth!.signInWithCredential(_automaticCredential!);
        } else {
          if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
            throw ApiException(
              statusCode: 400,
              code: 'INVALID_OTP',
              message: 'Enter the six-digit verification code.',
            );
          }
          if (kIsWeb && _confirmation != null) {
            result = await _confirmation!.confirm(otp);
          } else if (_verificationId != null) {
            result = await _auth!.signInWithCredential(
              PhoneAuthProvider.credential(
                verificationId: _verificationId!,
                smsCode: otp,
              ),
            );
          } else {
            throw ApiException(
              statusCode: 400,
              code: 'OTP_NOT_REQUESTED',
              message: 'Request a new verification code.',
            );
          }
        }
        if (result.user?.phoneNumber != normalized) {
          await _auth!.signOut();
          throw ApiException(
            statusCode: 401,
            code: 'PHONE_MISMATCH',
            message: 'Phone verification failed. Request a new code.',
          );
        }
        _verifiedPhone = normalized;
      }
      return {'localId': _auth!.currentUser!.uid, 'phoneNumber': normalized};
    } on FirebaseAuthException catch (e) {
      throw _friendlyError(e);
    }
  }

  Future<String?> getToken() async {
    await init();
    return isAuthenticated ? _auth!.currentUser!.getIdToken() : null;
  }

  Future<String> getInstallationId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('auth_installation_id');
    if (id == null) {
      final random = Random.secure();
      id = List.generate(
        16,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      await prefs.setString('auth_installation_id', id);
    }
    return id;
  }

  Future<void> clearSession() async {
    ++_requestGeneration;
    _phone = null;
    _verificationId = null;
    _resendToken = null;
    _confirmation = null;
    _automaticCredential = null;
    _verifiedPhone = null;
    if (_auth != null) await _auth!.signOut();
  }

  ApiException _friendlyError(FirebaseAuthException error) {
    final message = switch (error.code) {
      'invalid-phone-number' => 'Enter a valid mobile number.',
      'invalid-verification-code' =>
        'Incorrect verification code. Please try again.',
      'session-expired' ||
      'invalid-verification-id' => 'This code has expired. Request a new code.',
      'too-many-requests' =>
        'Too many attempts. Please wait before trying again.',
      'quota-exceeded' =>
        'SMS delivery is temporarily unavailable. Please try later.',
      'operation-not-allowed' =>
        'Phone sign-in is not enabled. Please contact support.',
      'app-not-authorized' ||
      'invalid-app-credential' ||
      'missing-client-identifier' =>
        'Phone verification is not configured for this app. Please contact support.',
      'captcha-check-failed' => 'Verification check failed. Please try again.',
      'network-request-failed' => 'Check your connection and try again.',
      'user-disabled' => 'This account has been suspended.',
      _ => 'Phone verification failed. Please try again.',
    };
    return ApiException(statusCode: 400, code: error.code, message: message);
  }
}
