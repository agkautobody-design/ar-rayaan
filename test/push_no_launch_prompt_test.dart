import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Invite, never force: the app must not show the system notification
/// prompt at launch. The prompt belongs to the moment a person switches a
/// prayer bell or a reminder on (the local scheduler asks then).
void main() {
  test('push startup reads the permission, it never asks', () {
    final String src =
        File('lib/app/push_notification_service.dart').readAsStringSync();
    expect(src.contains('requestPermission('), isFalse);
    expect(src.contains('getNotificationSettings()'), isTrue);
  });
}
