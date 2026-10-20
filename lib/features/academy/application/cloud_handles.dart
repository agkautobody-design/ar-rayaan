import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Live Firebase handles for the family wing and the online hall, or null
/// handles when Firebase was not initialised for this build (no dart-defines,
/// init failed, tests). `FirebaseBootstrap.maybeInit()` in `main.dart` is the
/// only place that initialises Firebase; this merely *reads* the result, so
/// the services can use the cloud when it exists and stay on-device when it
/// does not. It never throws and never initialises anything itself.
class CloudHandles {
  const CloudHandles({this.db, this.auth});

  final FirebaseFirestore? db;
  final FirebaseAuth? auth;

  bool get live => db != null && auth != null;

  /// Handles if (and only if) a Firebase app has been initialised.
  static CloudHandles current() {
    try {
      if (Firebase.apps.isEmpty) return const CloudHandles();
      return CloudHandles(
        db: FirebaseFirestore.instance,
        auth: FirebaseAuth.instance,
      );
    } catch (_) {
      return const CloudHandles();
    }
  }
}
