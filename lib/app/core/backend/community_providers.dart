import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'backend_config.dart';
import 'community_api.dart';
import 'disabled_community_api.dart';
import 'fake_community_api.dart';
import 'http_community_api.dart';
import 'prefs_token_store.dart';

/// The community backend the app talks to. In every build that has not set
/// `--dart-define=COMMUNITY_BACKEND=...` this is [DisabledCommunityApi]: no
/// network, no storage, no behaviour change.
final Provider<CommunityApi> communityApiProvider = Provider<CommunityApi>((
  Ref ref,
) {
  switch (BackendConfig.mode) {
    case BackendMode.off:
      return const DisabledCommunityApi();
    case BackendMode.fake:
      return FakeCommunityApi();
    case BackendMode.http:
      final HttpCommunityApi api = HttpCommunityApi(
        baseUrl: BackendConfig.apiUrl,
        tokens: PrefsTokenStore(ref.watch(sharedPreferencesProvider)),
      );
      ref.onDispose(api.close);
      return api;
  }
});
