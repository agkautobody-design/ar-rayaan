import 'package:ar_rayaan/app/core/firebase/firebase_bootstrap.dart';
import 'package:ar_rayaan/features/auth/application/auth_repository.dart';
import 'package:ar_rayaan/features/auth/data/firebase_auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('firebase bootstrap (O-4)', () {
    test('no defines → not configured, local mode, never throws', () async {
      // The test build carries no FIREBASE_* defines.
      expect(FirebaseBootstrap.configured, isFalse);
      expect(await FirebaseBootstrap.maybeInit(), isFalse);
    });
  });

  group('firebase error mapping (O-4)', () {
    test('known codes map to human messages', () {
      expect(
        FirebaseAuthRepository.mapError(
          fb.FirebaseAuthException(code: 'wrong-password'),
        ).message,
        contains('incorrect'),
      );
      expect(
        FirebaseAuthRepository.mapError(
          fb.FirebaseAuthException(code: 'email-already-in-use'),
        ).message,
        contains('already exists'),
      );
      expect(
        FirebaseAuthRepository.mapError(
          fb.FirebaseAuthException(code: 'network-request-failed'),
        ).message,
        contains('internet'),
      );
      expect(
        FirebaseAuthRepository.mapError(
          fb.FirebaseAuthException(code: 'weak-password'),
        ).message,
        contains('stronger'),
      );
    });

    test('unknown errors degrade to a generic message', () {
      expect(
        FirebaseAuthRepository.mapError(
          fb.FirebaseAuthException(code: 'some-future-code'),
        ).message,
        contains('Something went wrong'),
      );
      expect(
        FirebaseAuthRepository.mapError(StateError('x')).message,
        contains('Something went wrong'),
      );
    });

    test('mapped errors are the domain AuthException type', () {
      expect(
        FirebaseAuthRepository.mapError(
          fb.FirebaseAuthException(code: 'user-not-found'),
        ),
        isA<AuthException>(),
      );
    });
  });
}
