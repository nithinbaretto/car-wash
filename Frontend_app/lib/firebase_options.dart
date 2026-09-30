import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public Firebase client configuration. No server credentials belong here.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
        'Phone sign-in supports Android, iOS and web.',
      ),
    };
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyDCNoy0nebG4tpaO01bO4pnjot0eqtfWDM',
    appId: '1:653869969705:web:0da4bd3a19133638bf8738',
    messagingSenderId: '653869969705',
    projectId: 'car-wash-5d9ce',
    authDomain: 'car-wash-5d9ce.firebaseapp.com',
    storageBucket: 'car-wash-5d9ce.firebasestorage.app',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyA1kRSOQubl-zPMw9R63rWIZf-GtJAsJmo',
    appId: '1:653869969705:android:cd9f808644526be5bf8738',
    messagingSenderId: '653869969705',
    projectId: 'car-wash-5d9ce',
    storageBucket: 'car-wash-5d9ce.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyAM23Q-rGf3V-vbb2FV86qHWliiW5cy3Jk',
    appId: '1:653869969705:ios:e786171d14ccfdf3bf8738',
    messagingSenderId: '653869969705',
    projectId: 'car-wash-5d9ce',
    storageBucket: 'car-wash-5d9ce.firebasestorage.app',
    iosBundleId: 'com.carwash.carwash',
  );
}
