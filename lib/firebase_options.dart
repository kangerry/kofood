import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get web => const FirebaseOptions(
        apiKey: 'AIzaSyCSzqKbgCr886_zNmSfPjo-SlopSu27el0',
        authDomain: 'komera-b218d.firebaseapp.com',
        projectId: 'komera-b218d',
        storageBucket: 'komera-b218d.appspot.com',
        messagingSenderId: '826178948682',
        appId: '1:826178948682:web:3ebe98919551a91d13e0b3',
        measurementId: 'G-4CK7YXXTZ5',
      );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return const FirebaseOptions(
      apiKey: 'AIzaSyCSzqKbgCr886_zNmSfPjo-SlopSu27el0',
      projectId: 'komera-b218d',
      storageBucket: 'komera-b218d.appspot.com',
      messagingSenderId: '826178948682',
      appId: '1:826178948682:web:3ebe98919551a91d13e0b3',
    );
  }
}
