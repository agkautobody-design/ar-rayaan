/// Compile-time switch for the community backend (friends, invites, family
/// links, later forums and meet-ups).
///
/// DEFAULT: OFF. With no `--dart-define`, [BackendConfig.mode] is
/// [BackendMode.off] and the app behaves exactly as it did before the
/// backend existed. Nothing in the app calls the backend yet; this is the
/// foundation that screens will use once the owner has deployed the service
/// (docs/product/backend_community_plan.md).
///
///   --dart-define=COMMUNITY_BACKEND=fake   in-memory fake (UI work, tests)
///   --dart-define=COMMUNITY_BACKEND=http   the real service; also needs
///   --dart-define=COMMUNITY_API_URL=https://...   (no trailing path)
library;

enum BackendMode { off, fake, http }

abstract final class BackendConfig {
  static const String _modeDefine = String.fromEnvironment(
    'COMMUNITY_BACKEND',
    defaultValue: 'off',
  );
  static const String apiUrl = String.fromEnvironment('COMMUNITY_API_URL');

  /// The mode this build was compiled with.
  static BackendMode get mode => parse(_modeDefine, apiUrl);

  /// Pure for tests. Anything unrecognised, and `http` without a URL, is off:
  /// a half-configured build must never talk to a server.
  static BackendMode parse(String mode, String url) {
    switch (mode.trim().toLowerCase()) {
      case 'fake':
        return BackendMode.fake;
      case 'http':
        return Uri.tryParse(url)?.hasAuthority ?? false
            ? BackendMode.http
            : BackendMode.off;
      default:
        return BackendMode.off;
    }
  }
}

/// Versions of the texts a person agrees to when the server records consent.
/// They must equal backend/src/versions.ts; bump both together. DRAFTS until a
/// lawyer has reviewed the texts.
const String kCommunityTermsVersion = '2026-10-draft-1';
const String kCommunityPrivacyVersion = '2026-10-draft-1';
const String kCommunityParentConsentVersion = '2026-10-draft-1';

/// Version of the community rules a person accepts before their first post.
/// Must equal COMMUNITY_RULES_VERSION in backend/src/versions.ts. DRAFT until
/// the owner and a scholar have reviewed the rules text.
const String kCommunityRulesVersion = '2026-10-draft-1';
