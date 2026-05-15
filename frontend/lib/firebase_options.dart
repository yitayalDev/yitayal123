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
    apiKey: 'AIzaSyAYLKIGK_T1il6ZLUVGUXip8IMfrVJCOgQ',
    appId: '1:691735027883:web:your-web-id-placeholder',
    messagingSenderId: '691735027883',
    projectId: 'university-appointments',
    authDomain: 'university-appointments.firebaseapp.com',
    storageBucket: 'university-appointments.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAYLKIGK_T1il6ZLUVGUXip8IMfrVJCOgQ',
    appId: '1:691735027883:android:47758d517118e0a9e897ee',
    messagingSenderId: '691735027883',
    projectId: 'university-appointments',
    storageBucket: 'university-appointments.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAYLKIGK_T1il6ZLUVGUXip8IMfrVJCOgQ',
    appId: '1:691735027883:ios:your-ios-id-placeholder',
    messagingSenderId: '691735027883',
    projectId: 'university-appointments',
    storageBucket: 'university-appointments.firebasestorage.app',
    iosBundleId: 'com.university.appointments',
  );
}
