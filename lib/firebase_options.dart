import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY_WEB'] ?? '',
    appId: '1:786434805872:web:6ea402427dd2879e6064b5',
    messagingSenderId: '786434805872',
    projectId: 'smartstick2026-6a6ce',
    authDomain: 'smartstick2026-6a6ce.firebaseapp.com',
    storageBucket: 'smartstick2026-6a6ce.firebasestorage.app',
    measurementId: 'G-ZXQJYHET7M',
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY_ANDROID'] ?? '',
    appId: '1:786434805872:android:cdc47d97407c3f4c6064b5',
    messagingSenderId: '786434805872',
    projectId: 'smartstick2026-6a6ce',
    storageBucket: 'smartstick2026-6a6ce.firebasestorage.app',
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY_IOS'] ?? '',
    appId: '1:786434805872:ios:890bfdc8097f868f6064b5',
    messagingSenderId: '786434805872',
    projectId: 'smartstick2026-6a6ce',
    storageBucket: 'smartstick2026-6a6ce.firebasestorage.app',
    iosClientId:
        '786434805872-hf5h348b3hdlmgp5648v514r3rgbppr1.apps.googleusercontent.com',
    iosBundleId: 'com.example.smartstickApp',
  );

  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY_IOS'] ?? '',
    appId: '1:786434805872:ios:890bfdc8097f868f6064b5',
    messagingSenderId: '786434805872',
    projectId: 'smartstick2026-6a6ce',
    storageBucket: 'smartstick2026-6a6ce.firebasestorage.app',
    iosClientId:
        '786434805872-hf5h348b3hdlmgp5648v514r3rgbppr1.apps.googleusercontent.com',
    iosBundleId: 'com.example.smartstickApp',
  );

  static FirebaseOptions get windows => FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY_WEB'] ?? '',
    appId: '1:786434805872:web:6ea402427dd2879e6064b5',
    messagingSenderId: '786434805872',
    projectId: 'smartstick2026-6a6ce',
    authDomain: 'smartstick2026-6a6ce.firebaseapp.com',
    storageBucket: 'smartstick2026-6a6ce.firebasestorage.app',
    measurementId: 'G-ZXQJYHET7M',
  );
}
