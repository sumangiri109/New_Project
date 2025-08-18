import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
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
    storageBucket: 'loanapp-63a08.firebasestorage.app',
    measurementId: 'G-7TPMCFNXRW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA6C0aMkf7ftn_TBRqJaS46u-t4vUScEpg',
    appId: '1:338090358950:android:your-android-app-id',
    messagingSenderId: '338090358950',
    projectId: 'loanapp-63a08',
    storageBucket: 'loanapp-63a08.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA6C0aMkf7ftn_TBRqJaS46u-t4vUScEpg',
    appId: '1:338090358950:ios:your-ios-app-id',
    messagingSenderId: '338090358950',
    projectId: 'loanapp-63a08',
    storageBucket: 'loanapp-63a08.firebasestorage.app',
    iosBundleId: 'com.example.loanProject',
  );
}
