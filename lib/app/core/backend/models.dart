import 'dart:convert';

part 'community_models.dart';

/// Wire models for the community backend (backend/openapi.yaml). Pure Dart.
/// Forum, meet-up, notification and moderation models live in
/// `community_models.dart` (same library, so they share these helpers).

String _str(Map<String, dynamic> j, String k) {
  final Object? v = j[k];
  if (v is String) return v;
  throw FormatException('"$k" is not a string');
}

String? _strOrNull(Map<String, dynamic> j, String k) {
  final Object? v = j[k];
  return v is String ? v : null;
}

int _int(Map<String, dynamic> j, String k, {int fallback = 0}) {
  final Object? v = j[k];
  return v is num ? v.toInt() : fallback;
}

bool _bool(Map<String, dynamic> j, String k, {bool fallback = false}) {
  final Object? v = j[k];
  return v is bool ? v : fallback;
}

DateTime _time(Map<String, dynamic> j, String k) {
  final DateTime? t = DateTime.tryParse(_str(j, k));
  if (t == null) throw FormatException('"$k" is not a time');
  return t;
}

DateTime? _timeOrNull(Map<String, dynamic> j, String k) {
  final String? s = _strOrNull(j, k);
  return s == null ? null : DateTime.tryParse(s);
}

Map<String, dynamic> _map(Object? v) {
  if (v is Map<String, dynamic>) return v;
  throw const FormatException('expected an object');
}

List<Map<String, dynamic>> _list(Object? v) {
  if (v is List<dynamic>) return v.map<Map<String, dynamic>>(_map).toList();
  return <Map<String, dynamic>>[];
}

T _enum<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final T v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

/// Decodes a JSON object, or throws [FormatException].
Map<String, dynamic> decodeObject(String body) => _map(jsonDecode(body));

/// `adult` has a login. `teen` and `child` profiles are managed by a guardian
/// and are never public.
enum ProfileKind { adult, teen, child }

extension ProfileKindX on ProfileKind {
  bool get isMinor => this != ProfileKind.adult;
}

/// private: reachable only by invite. handle: findable by exact handle.
/// community: display name may appear on forum posts and meet-ups.
enum ProfileVisibility { private, handle, community }

class BackendProfile {
  const BackendProfile({
    required this.id,
    required this.kind,
    required this.displayName,
    required this.visibility,
    required this.createdAt,
    this.handle,
    this.bio,
  });

  factory BackendProfile.fromJson(Map<String, dynamic> j) => BackendProfile(
    id: _str(j, 'id'),
    kind: _enum(ProfileKind.values, _strOrNull(j, 'kind'), ProfileKind.adult),
    displayName: _str(j, 'displayName'),
    handle: _strOrNull(j, 'handle'),
    bio: _strOrNull(j, 'bio'),
    visibility: _enum(
      ProfileVisibility.values,
      _strOrNull(j, 'visibility'),
      ProfileVisibility.private,
    ),
    createdAt: _time(j, 'createdAt'),
  );

  final String id;
  final ProfileKind kind;
  final String displayName;
  final String? handle;
  final String? bio;
  final ProfileVisibility visibility;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'kind': kind.name,
    'displayName': displayName,
    'handle': handle,
    'bio': bio,
    'visibility': visibility.name,
    'createdAt': createdAt.toIso8601String(),
  };
}

class BackendUser {
  const BackendUser({
    required this.id,
    required this.role,
    this.email,
    this.createdAt,
  });

  factory BackendUser.fromJson(Map<String, dynamic> j) => BackendUser(
    id: _str(j, 'id'),
    role: _strOrNull(j, 'role') ?? 'member',
    email: _strOrNull(j, 'email'),
    createdAt: _timeOrNull(j, 'createdAt'),
  );

  final String id;

  /// member, moderator or admin.
  final String role;
  final String? email;
  final DateTime? createdAt;
}

/// The result of a sign-in. The token is a secret: never log it.
class BackendSession {
  const BackendSession({
    required this.token,
    required this.expiresAt,
    required this.isNewAccount,
    required this.user,
  });

  factory BackendSession.fromJson(Map<String, dynamic> j) => BackendSession(
    token: _str(j, 'token'),
    expiresAt: _time(j, 'expiresAt'),
    isNewAccount: _bool(j, 'isNewAccount'),
    user: BackendUser.fromJson(_map(j['user'])),
  );

  final String token;
  final DateTime expiresAt;
  final bool isNewAccount;
  final BackendUser user;
}

/// `GET /v1/me`.
class MeResponse {
  const MeResponse({required this.user, required this.children, this.profile});

  factory MeResponse.fromJson(Map<String, dynamic> j) => MeResponse(
    user: BackendUser.fromJson(_map(j['user'])),
    profile: j['profile'] == null
        ? null
        : BackendProfile.fromJson(_map(j['profile'])),
    children: _list(j['children']).map(BackendProfile.fromJson).toList(),
  );

  final BackendUser user;
  final BackendProfile? profile;
  final List<BackendProfile> children;
}

class FriendEntry {
  const FriendEntry({
    required this.friendshipId,
    required this.since,
    required this.profileId,
    required this.displayName,
    required this.kind,
  });

  factory FriendEntry.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic> p = _map(j['profile']);
    return FriendEntry(
      friendshipId: _str(j, 'friendshipId'),
      since: _time(j, 'since'),
      profileId: _str(p, 'id'),
      displayName: _str(p, 'displayName'),
      kind: _enum(ProfileKind.values, _strOrNull(p, 'kind'), ProfileKind.adult),
    );
  }

  final String friendshipId;
  final DateTime since;
  final String profileId;
  final String displayName;
  final ProfileKind kind;
}

class FriendLists {
  const FriendLists({
    required this.profileId,
    required this.friends,
    required this.incoming,
    required this.outgoing,
  });

  factory FriendLists.fromJson(Map<String, dynamic> j) => FriendLists(
    profileId: _str(j, 'profileId'),
    friends: _list(j['friends']).map(FriendEntry.fromJson).toList(),
    incoming: _list(j['incoming']).map(FriendEntry.fromJson).toList(),
    outgoing: _list(j['outgoing']).map(FriendEntry.fromJson).toList(),
  );

  final String profileId;
  final List<FriendEntry> friends;
  final List<FriendEntry> incoming;
  final List<FriendEntry> outgoing;
}

/// Returned once, when an invite is created. [code] is not recoverable later.
class InviteCreated {
  const InviteCreated({
    required this.id,
    required this.code,
    required this.link,
    required this.maxUses,
    required this.expiresAt,
  });

  factory InviteCreated.fromJson(Map<String, dynamic> j) => InviteCreated(
    id: _str(j, 'id'),
    code: _str(j, 'code'),
    link: _str(j, 'link'),
    maxUses: _int(j, 'maxUses', fallback: 1),
    expiresAt: _time(j, 'expiresAt'),
  );

  final String id;
  final String code;

  /// A link the app can open (`.../#/join/CODE`); also what a QR code carries.
  final String link;
  final int maxUses;
  final DateTime expiresAt;
}

class InviteSummary {
  const InviteSummary({
    required this.id,
    required this.profileId,
    required this.maxUses,
    required this.uses,
    required this.expiresAt,
    required this.active,
  });

  factory InviteSummary.fromJson(Map<String, dynamic> j) => InviteSummary(
    id: _str(j, 'id'),
    profileId: _str(j, 'profileId'),
    maxUses: _int(j, 'maxUses', fallback: 1),
    uses: _int(j, 'uses'),
    expiresAt: _time(j, 'expiresAt'),
    active: _bool(j, 'active'),
  );

  final String id;
  final String profileId;
  final int maxUses;
  final int uses;
  final DateTime expiresAt;
  final bool active;
}

/// What a person sees before using a code. A child's name is never included:
/// [inviterDisplayName] is null for a family (child) invite.
class InvitePreview {
  const InvitePreview({
    required this.familyInvite,
    required this.expiresAt,
    this.inviterDisplayName,
  });

  factory InvitePreview.fromJson(Map<String, dynamic> j) => InvitePreview(
    familyInvite: _bool(j, 'familyInvite'),
    inviterDisplayName: _strOrNull(j, 'inviterDisplayName'),
    expiresAt: _time(j, 'expiresAt'),
  );

  final bool familyInvite;
  final String? inviterDisplayName;
  final DateTime expiresAt;
}

class RedeemResult {
  const RedeemResult({
    required this.friendshipId,
    required this.friendProfileId,
    required this.friendDisplayName,
    required this.friendKind,
  });

  factory RedeemResult.fromJson(Map<String, dynamic> j) {
    final Map<String, dynamic> f = _map(j['friend']);
    return RedeemResult(
      friendshipId: _str(_map(j['friendship']), 'id'),
      friendProfileId: _str(f, 'id'),
      friendDisplayName: _str(f, 'displayName'),
      friendKind: _enum(
        ProfileKind.values,
        _strOrNull(f, 'kind'),
        ProfileKind.adult,
      ),
    );
  }

  final String friendshipId;
  final String friendProfileId;
  final String friendDisplayName;
  final ProfileKind friendKind;
}

class BlockedProfile {
  const BlockedProfile({required this.profileId, required this.displayName});

  factory BlockedProfile.fromJson(Map<String, dynamic> j) => BlockedProfile(
    profileId: _str(j, 'profileId'),
    displayName: _str(j, 'displayName'),
  );

  final String profileId;
  final String displayName;
}

/// `ask_scholar` -> `askScholar`, `community_opinion` -> `communityOpinion`.
String? _camel(String? snake) {
  if (snake == null) return null;
  final List<String> parts = snake.split('_');
  return parts.first +
      parts
          .skip(1)
          .map((String p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
          .join();
}
