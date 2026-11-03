import 'dart:ui';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

/// Initializes Firebase Crashlytics for error reporting.
/// Call this in main() before runApp().
class CrashlyticsInitializer {
  static void initialize() {
    // Catch Flutter framework errors
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Catch async errors (zones, futures, streams)
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: true,
      );
      return true;
    };

    // Optional: Set user ID for crash reports (call after login)
    // FirebaseCrashlytics.instance.setUserIdentifier(user.uid);
  }
}
