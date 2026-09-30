import 'package:carwash/core/network/api_exception.dart';
import 'package:carwash/core/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestUser extends Fake implements User {
  @override
  String get uid => 'phone-user';
  @override
  String get phoneNumber => '+919876543210';
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async =>
      'verified-token';
}

class TestCredential extends Fake implements UserCredential {
  @override
  User get user => TestUser();
}

class TestAuth extends Fake implements FirebaseAuth {
  User? signedIn;
  int sendCount = 0;
  int? resendToken;
  String? lastPhone;
  String? failCode;
  PhoneVerificationCompleted? automatic;
  @override
  User? get currentUser => signedIn;
  @override
  Stream<User?> authStateChanges() => Stream.value(signedIn);
  @override
  Future<void> signOut() async {
    signedIn = null;
  }

  @override
  Future<void> verifyPhoneNumber({
    String? phoneNumber,
    PhoneMultiFactorInfo? multiFactorInfo,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    String? autoRetrievedSmsCodeForTesting,
    Duration timeout = const Duration(seconds: 30),
    int? forceResendingToken,
    MultiFactorSession? multiFactorSession,
  }) async {
    sendCount++;
    lastPhone = phoneNumber;
    resendToken = forceResendingToken;
    automatic = verificationCompleted;
    if (failCode != null) {
      verificationFailed(FirebaseAuthException(code: failCode!));
    } else {
      codeSent('challenge-$sendCount', 42);
    }
  }

  @override
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    if ((credential as PhoneAuthCredential).smsCode != '123456') {
      throw FirebaseAuthException(code: 'invalid-verification-code');
    }
    signedIn = TestUser();
    return TestCredential();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestAuth firebase;
  late AuthService service;
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_id_token': 'legacy-unsafe-token',
    });
    firebase = TestAuth();
    service = AuthService(firebaseAuth: firebase);
  });
  test('normalizes phones and rejects invalid input before SMS', () async {
    expect(AuthService.normalizePhone('98765 43210'), '+919876543210');
    expect(AuthService.normalizePhone('+91 98765 43210'), '+919876543210');
    await expectLater(
      service.requestPhoneOtp(phone: '123'),
      throwsA(isA<ApiException>()),
    );
    expect(firebase.sendCount, 0);
  });
  test('cannot sign in without requesting an SMS challenge', () async {
    await expectLater(
      service.authenticateWithPhone(
        phone: '9876543210',
        otp: '123456',
        name: 'Customer',
      ),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'OTP_NOT_REQUESTED'),
      ),
    );
    expect(service.isAuthenticated, isFalse);
  });
  test(
    'rejects wrong code, accepts verified credential and clears tokens on logout',
    () async {
      await service.requestPhoneOtp(phone: '9876543210');
      expect(firebase.lastPhone, '+919876543210');
      expect(
        (await SharedPreferences.getInstance()).getString('auth_id_token'),
        isNull,
      );
      await expectLater(
        service.authenticateWithPhone(
          phone: '9876543210',
          otp: '000000',
          name: 'Customer',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'invalid-verification-code',
          ),
        ),
      );
      expect(service.isAuthenticated, isFalse);
      await service.authenticateWithPhone(
        phone: '9876543210',
        otp: '123456',
        name: 'Customer',
      );
      expect(await service.getToken(), 'verified-token');
      await service.clearSession();
      expect(await service.getToken(), isNull);
    },
  );
  test(
    'resend requests fresh SMS and verification is bound to requested phone',
    () async {
      await service.requestPhoneOtp(phone: '9876543210');
      await service.requestPhoneOtp(phone: '9876543210', resend: true);
      expect(firebase.sendCount, 2);
      expect(firebase.resendToken, 42);
      await expectLater(
        service.authenticateWithPhone(
          phone: '9876543211',
          otp: '123456',
          name: 'Customer',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'OTP_NOT_REQUESTED',
          ),
        ),
      );
    },
  );
  test('SMS delivery errors propagate without authenticating', () async {
    firebase.failCode = 'quota-exceeded';
    await expectLater(
      service.requestPhoneOtp(phone: '9876543210'),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'quota-exceeded'),
      ),
    );
    expect(service.isAuthenticated, isFalse);
  });
  test(
    'automatic verification notifies UI and ignores stale callbacks',
    () async {
      var notifications = 0;
      service.addListener(() => notifications++);
      await service.requestPhoneOtp(phone: '9876543210');
      final oldCallback = firebase.automatic!;
      await service.requestPhoneOtp(phone: '9876543210', resend: true);
      final credential = PhoneAuthProvider.credential(
        verificationId: 'challenge',
        smsCode: '123456',
      );
      oldCallback(credential);
      expect(notifications, 0);
      firebase.automatic!(credential);
      expect(notifications, 1);
      await service.authenticateWithPhone(
        phone: '9876543210',
        otp: '',
        name: 'Customer',
      );
      expect(service.isAuthenticated, isTrue);
    },
  );
}
