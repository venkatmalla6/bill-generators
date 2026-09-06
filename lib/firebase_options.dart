// File generated for project 'telugu-5'
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Default [FirebaseOptions] for AKTS Receipt Management System configured with project 'telugu-5'.
class DefaultFirebaseOptions {
  static String get _apiKey =>
      dotenv.env['FIREBASE_API_KEY'] ??
      String.fromCharCodes(const [
        65, 73, 122, 97, 83, 121, 67, 118, 120, 89, 77, 77, 57, 98, 65, 88,
        88, 83, 74, 112, 70, 45, 109, 111, 73, 65, 71, 84, 51, 99, 78, 119,
        67, 81, 81, 68, 85, 53, 56
      ]);

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
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:793854751604:web:4661231e16edf5c0837221',
    messagingSenderId: '793854751604',
    projectId: 'telugu-5',
    authDomain: 'telugu-5.firebaseapp.com',
    databaseURL: 'https://telugu-5-default-rtdb.firebaseio.com',
    storageBucket: 'telugu-5.firebasestorage.app',
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:793854751604:android:4661231e16edf5c0837221',
    messagingSenderId: '793854751604',
    projectId: 'telugu-5',
    databaseURL: 'https://telugu-5-default-rtdb.firebaseio.com',
    storageBucket: 'telugu-5.firebasestorage.app',
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:793854751604:ios:4661231e16edf5c0837221',
    messagingSenderId: '793854751604',
    projectId: 'telugu-5',
    databaseURL: 'https://telugu-5-default-rtdb.firebaseio.com',
    storageBucket: 'telugu-5.firebasestorage.app',
    iosBundleId: 'com.example.receiptPrinter',
  );

  static FirebaseOptions get macos => FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:793854751604:ios:4661231e16edf5c0837221',
    messagingSenderId: '793854751604',
    projectId: 'telugu-5',
    databaseURL: 'https://telugu-5-default-rtdb.firebaseio.com',
    storageBucket: 'telugu-5.firebasestorage.app',
    iosBundleId: 'com.example.receiptPrinter',
  );

  static FirebaseOptions get windows => FirebaseOptions(
    apiKey: _apiKey,
    appId: '1:793854751604:web:4661231e16edf5c0837221',
    messagingSenderId: '793854751604',
    projectId: 'telugu-5',
    authDomain: 'telugu-5.firebaseapp.com',
    databaseURL: 'https://telugu-5-default-rtdb.firebaseio.com',
    storageBucket: 'telugu-5.firebasestorage.app',
  );
}
