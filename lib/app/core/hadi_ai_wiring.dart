import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/hadi/data/hosted_ai.dart';
import '../../features/hadi/data/http_hosted_ai.dart';
import 'backend/backend_config.dart';
import 'backend/prefs_token_store.dart';
import 'providers.dart';

/// Connects Hādi's live-answer seam to the owner's service, only in a build
/// compiled for it (`COMMUNITY_BACKEND=http` with `COMMUNITY_API_URL`). It
/// lives here, outside the Hādi feature, so Hādi code never reaches the
/// community service. In every other build this list is empty and nothing
/// changes. The server answers 503 until the owner has put a provider key on
/// it, and the app then keeps using the built-in library.
List<Override> hadiAiOverrides() {
  if (BackendConfig.mode != BackendMode.http) return const <Override>[];
  return <Override>[
    hostedAiProvider.overrideWith((Ref ref) {
      final PrefsTokenStore tokens =
          PrefsTokenStore(ref.watch(sharedPreferencesProvider));
      final HttpHostedAi api = HttpHostedAi(
        baseUrl: BackendConfig.apiUrl,
        readToken: tokens.read,
      );
      ref.onDispose(api.close);
      return api;
    }),
  ];
}
