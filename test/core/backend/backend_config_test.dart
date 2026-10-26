import 'package:ar_rayaan/app/core/backend/backend_config.dart';
import 'package:ar_rayaan/app/core/backend/community_api.dart';
import 'package:ar_rayaan/app/core/backend/community_providers.dart';
import 'package:ar_rayaan/app/core/backend/disabled_community_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackendConfig.parse', () {
    test('is off by default and for anything unrecognised', () {
      expect(BackendConfig.parse('', ''), BackendMode.off);
      expect(BackendConfig.parse('off', ''), BackendMode.off);
      expect(BackendConfig.parse('on', 'https://x.example'), BackendMode.off);
      expect(BackendConfig.parse('true', 'https://x.example'), BackendMode.off);
    });

    test('fake needs no URL', () {
      expect(BackendConfig.parse('fake', ''), BackendMode.fake);
      expect(BackendConfig.parse(' FAKE ', ''), BackendMode.fake);
    });

    test('http needs a real URL, otherwise it stays off', () {
      expect(
        BackendConfig.parse('http', 'https://api.example.test'),
        BackendMode.http,
      );
      expect(BackendConfig.parse('http', ''), BackendMode.off);
      expect(BackendConfig.parse('http', 'not a url'), BackendMode.off);
    });
  });

  test('this build has the backend OFF and the provider is the disabled one', () {
    // Tests run with no --dart-define, like the shipped app today.
    expect(BackendConfig.mode, BackendMode.off);
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    final CommunityApi api = c.read(communityApiProvider);
    expect(api, isA<DisabledCommunityApi>());
    expect(api.enabled, isFalse);
  });
}
