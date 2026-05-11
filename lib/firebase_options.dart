import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError('Android not configured.');
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS not configured.');
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC8uPklmW7I501rdKf_TAMBIsCfIx6mi1o',
    appId: '1:14636981952:web:4532ce8f83dc72a6dd5725',
    messagingSenderId: '14636981952',
    projectId: 'mukammal-pakistan-party',
    authDomain: 'mukammal-pakistan-party.firebaseapp.com',
    storageBucket: 'mukammal-pakistan-party.firebasestorage.app',
    measurementId: 'G-QQLPTPM6D9',
  );
}