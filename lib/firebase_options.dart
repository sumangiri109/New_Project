import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Automatically generated Firebase configuration.
/// This config only supports WEB since you are not targeting Android/iOS.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions has not been configured for Android.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions has not been configured for iOS.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA6C0aMkf7ftn_TBRqJaS46u-t4vUScEpg',
    appId: '1:338090358950:web:62de67fe6e82e59ee75c67',
    messagingSenderId: '338090358950',
    projectId: 'loanapp-63a08',
    authDomain: 'loanapp-63a08.firebaseapp.com',
    storageBucket: 'loanapp-63a08.firebasestorage.app', // ✅ confirmed correct
    measurementId: 'G-7TPMCFNXRW',
  );
}
