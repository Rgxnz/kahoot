import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCTSlgXGTk2vlS-gpYvVABlW-GFi4Qe348',
    appId: '1:701528629325:android:3e68d46c8c6aeac9fabc04',
    messagingSenderId: '701528629325',
    projectId: 'kahoot-oa',
    storageBucket: 'kahoot-oa.firebasestorage.app',
  );
}
