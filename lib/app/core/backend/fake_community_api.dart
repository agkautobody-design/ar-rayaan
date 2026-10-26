import 'dart:math';

import '../../../features/majlis/domain/majlis_policy.dart';
import 'backend_exception.dart';
import 'community_api.dart';
import 'models.dart';

/// An in-memory community backend for UI work and tests. It mirrors the rules
/// of the real service (backend/) closely enough that a screen built on it
/// behaves the same against the server:
///
///  * accounts are adults; a first sign-in needs `confirmAdult`;
///  * the sign-in code is always [fixedCode] (this is a fake);
///  * names follow the Majlis name rules (reserved words, look-alikes);
///  * children are private, have no handle, and cannot be found;
///  * adults and children never become friends; two children become friends
///    only through an invite one guardian made and the other redeemed;
///  * invite codes work once for a child, expire, and can be revoked.
///
/// It keeps ONE signed-in person at a time (this device), plus a small
/// "directory" of other people the test can plant with [seedAdult].
class FakeCommunityApi implements CommunityApi {
  FakeCommunityApi({DateTime Function()? clock, Random? random})
    : _now = clock ?? DateTime.now,
      _random = random ?? Random(7);

  /// The code every sign-in accepts.
  static const String fixedCode = '000000';

  final DateTime Function() _now;
  final Random _random;
  int _seq = 0;

  String _id(String prefix) => '$prefix-${++_seq}';

  final Map<String, _Account> _accounts = <String, _Account>{}; // by user id
  final Map<String, String> _userByEmail = <String, String>{};
  final Map<String, _Profile> _profiles = <String, _Profile>{};
  final List<_Friendship> _friendships = <_Friendship>[];
  final List<_Block> _blocks = <_Block>[];
  final Map<String, _Invite> _invites = <String, _Invite>{}; // by code
  final Set<String> _codesRequested = <String>{};
  String? _me; // signed-in user id

  @override
  bool get enabled => true;

  // ---- test helpers --------------------------------------------------------
  /// Adds another adult (with a profile) to the directory. Returns the
  /// profile id.
  String seedAdult(
    String displayName, {
    String? handle,
    ProfileVisibility visibility = ProfileVisibility.handle,
  }) {
    final String userId = _id('user');
    _accounts[userId] = _Account(userId, '$userId@fake.invalid');
    final _Profile p = _Profile(
      id: _id('profile'),
      kind: ProfileKind.adult,
      userId: userId,
      displayName: displayName,
      handle: handle,
      visibility: visibility,
      createdAt: _now(),
    );
    _profiles[p.id] = p;
    return p.id;
  }

  // ---- internals -----------------------------------------------------------
  _Account get _account {
    final String? id = _me;
    final _Account? a = id == null ? null : _accounts[id];
    if (a == null) {
      throw const BackendException(
        'unauthorized',
        'Please sign in first.',
        status: 401,
      );
    }
    return a;
  }

  _Profile? _ownAdult(String userId) {
    for (final _Profile p in _profiles.values) {
      if (p.userId == userId && p.erasedAt == null) return p;
    }
    return null;
  }

  _Profile _acting(String? profileId) {
    final _Account a = _account;
    if (profileId == null) {
      final _Profile? own = _ownAdult(a.id);
      if (own == null) {
        throw const BackendException(
          'profile_required',
          'Create your profile first.',
          status: 403,
        );
      }
      return own;
    }
    final _Profile? p = _profiles[profileId];
    if (p == null || (p.userId != a.id && p.managedBy != a.id)) {
      throw const BackendException('not_found', 'Not found.', status: 404);
    }
    return p;
  }

  Never _fail(String code, String message, [int status = 409]) =>
      throw BackendException(code, message, status: status);

  Future<T> _async<T>(T Function() body) async => body();

  BackendSession _session(_Account a, {required bool isNew}) {
    _me = a.id;
    return BackendSession(
      token: 'fake-token-${a.id}',
      expiresAt: _now().add(const Duration(days: 30)),
      isNewAccount: isNew,
      user: BackendUser(id: a.id, role: 'member', email: a.email),
    );
  }

  BackendProfile _view(_Profile p) => BackendProfile(
    id: p.id,
    kind: p.kind,
    displayName: p.displayName,
    handle: p.handle,
    bio: p.bio,
    visibility: p.visibility,
    createdAt: p.createdAt,
  );

  bool _blockedEitherWay(String a, String b) => _blocks.any(
    (_Block x) =>
        (x.blocker == a && x.blocked == b) ||
        (x.blocker == b && x.blocked == a),
  );

  _Friendship? _pair(String a, String b) {
    for (final _Friendship f in _friendships) {
      if ((f.a == a && f.b == b) || (f.a == b && f.b == a)) return f;
    }
    return null;
  }

  // ---- sign-in ---------------------------------------------------------
  @override
  Future<void> requestSignInCode(String email) => _async(() {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _fail('validation_failed', 'Some fields are missing or not valid.', 400);
    }
    _codesRequested.add(email.trim().toLowerCase());
  });

  @override
  Future<BackendSession> verifySignInCode({
    required String email,
    required String code,
    bool confirmAdult = false,
    String? deviceLabel,
  }) => _async(() {
    final String e = email.trim().toLowerCase();
    if (!_codesRequested.contains(e) || code != fixedCode) {
      _fail('unauthorized', 'That code is not valid. Ask for a new one.', 401);
    }
    final String? existing = _userByEmail[e];
    if (existing != null) return _session(_accounts[existing]!, isNew: false);
    if (!confirmAdult) {
      _fail(
        'adult_confirmation_required',
        'Accounts are for people aged 18 or over.',
        422,
      );
    }
    final _Account a = _Account(_id('user'), e);
    _accounts[a.id] = a;
    _userByEmail[e] = a.id;
    return _session(a, isNew: true);
  });

  @override
  Future<BackendSession> signInWithFirebaseToken({
    required String idToken,
    bool confirmAdult = false,
    String? deviceLabel,
  }) => _async(() {
    if (idToken.length < 20) {
      _fail('unauthorized', 'Please sign in again.', 401);
    }
    // The fake derives a stable e-mail from the token.
    final String e = 'fb-${idToken.hashCode.abs()}@fake.invalid';
    final String? existing = _userByEmail[e];
    if (existing != null) return _session(_accounts[existing]!, isNew: false);
    if (!confirmAdult) {
      _fail(
        'adult_confirmation_required',
        'Accounts are for people aged 18 or over.',
        422,
      );
    }
    final _Account a = _Account(_id('user'), e);
    _accounts[a.id] = a;
    _userByEmail[e] = a.id;
    return _session(a, isNew: true);
  });

  @override
  Future<void> signOut() async {
    _me = null;
  }

  // ---- me, profile, guardian -------------------------------------------
  @override
  Future<MeResponse> me() => _async(() {
    final _Account a = _account;
    final _Profile? p = _ownAdult(a.id);
    return MeResponse(
      user: BackendUser(id: a.id, role: 'member', email: a.email),
      profile: p == null ? null : _view(p),
      children: _children(a.id),
    );
  });

  List<BackendProfile> _children(String userId) => _profiles.values
      .where((_Profile p) => p.managedBy == userId)
      .map(_view)
      .toList();

  @override
  Future<BackendProfile> saveProfile({
    required String displayName,
    String? handle,
    String? bio,
    ProfileVisibility visibility = ProfileVisibility.private,
  }) => _async(() {
    final _Account a = _account;
    final String? problem = MajlisPolicy.validateName(displayName);
    if (problem != null) _fail('display_name_invalid', problem, 422);
    if (handle != null && !RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(handle)) {
      _fail('handle_invalid', 'A handle is 3 to 20 lower-case letters.', 422);
    }
    if (visibility == ProfileVisibility.handle && handle == null) {
      _fail('handle_required', 'Choose a handle to be found by it.', 422);
    }
    final bool taken = _profiles.values.any(
      (_Profile p) =>
          p.handle == handle && handle != null && p.userId != a.id,
    );
    if (taken) _fail('handle_taken', 'That handle is already taken.');
    final _Profile? own = _ownAdult(a.id);
    if (own != null) {
      own
        ..displayName = displayName.trim()
        ..handle = handle
        ..bio = bio
        ..visibility = visibility;
      return _view(own);
    }
    final _Profile p = _Profile(
      id: _id('profile'),
      kind: ProfileKind.adult,
      userId: a.id,
      displayName: displayName.trim(),
      handle: handle,
      bio: bio,
      visibility: visibility,
      createdAt: _now(),
    );
    _profiles[p.id] = p;
    return _view(p);
  });

  @override
  Future<void> deleteAccount({bool removePosts = false}) => _async(() {
    final _Account a = _account;
    _profiles.removeWhere((String _, _Profile p) => p.managedBy == a.id);
    final _Profile? own = _ownAdult(a.id);
    if (own != null) {
      _friendships.removeWhere((_Friendship f) => f.a == own.id || f.b == own.id);
      own
        ..displayName = 'Deleted member'
        ..handle = null
        ..bio = null
        ..visibility = ProfileVisibility.private
        ..erasedAt = _now();
    }
    _invites.removeWhere((String _, _Invite i) => i.createdByUser == a.id);
    _userByEmail.removeWhere((String _, String id) => id == a.id);
    _accounts.remove(a.id);
    _me = null;
  });

  @override
  Future<Map<String, dynamic>> exportMyData() => _async(() {
    final _Account a = _account;
    return <String, dynamic>{
      'user': <String, dynamic>{'id': a.id, 'email': a.email},
      'profiles': _profiles.values
          .where((_Profile p) => p.userId == a.id || p.managedBy == a.id)
          .map((_Profile p) => _view(p).toJson())
          .toList(),
    };
  });

  @override
  Future<BackendProfile> addChild({
    required String nickname,
    required bool teen,
  }) => _async(() {
    final _Account a = _account;
    final String? problem = MajlisPolicy.validateName(nickname);
    if (problem != null) _fail('nickname_invalid', problem, 422);
    if (_children(a.id).length >= 8) {
      _fail(
        'child_limit_reached',
        'You have reached the number of child profiles allowed.',
      );
    }
    final _Profile p = _Profile(
      id: _id('profile'),
      kind: teen ? ProfileKind.teen : ProfileKind.child,
      managedBy: a.id,
      displayName: nickname.trim(),
      visibility: ProfileVisibility.private,
      createdAt: _now(),
    );
    _profiles[p.id] = p;
    return _view(p);
  });

  @override
  Future<List<BackendProfile>> children() =>
      _async(() => _children(_account.id));

  _Profile _child(String id) {
    final _Profile? p = _profiles[id];
    if (p == null || p.managedBy != _account.id) {
      _fail('not_found', 'Not found.', 404);
    }
    return p;
  }

  @override
  Future<BackendProfile> renameChild(String childId, String nickname) =>
      _async(() {
        final _Profile p = _child(childId);
        final String? problem = MajlisPolicy.validateName(nickname);
        if (problem != null) _fail('nickname_invalid', problem, 422);
        p.displayName = nickname.trim();
        return _view(p);
      });

  @override
  Future<void> deleteChild(String childId) => _async(() {
    final _Profile p = _child(childId);
    _friendships.removeWhere((_Friendship f) => f.a == p.id || f.b == p.id);
    _profiles.remove(p.id);
  });

  // ---- friends -----------------------------------------------------------
  @override
  Future<FriendLists> friends({String? profileId}) => _async(() {
    final _Profile me = _acting(profileId);
    final List<FriendEntry> friends = <FriendEntry>[];
    final List<FriendEntry> incoming = <FriendEntry>[];
    final List<FriendEntry> outgoing = <FriendEntry>[];
    for (final _Friendship f in _friendships) {
      if (f.a != me.id && f.b != me.id) continue;
      if (f.status != 'accepted' && f.status != 'pending') continue;
      final _Profile other = _profiles[f.a == me.id ? f.b : f.a]!;
      if (other.erasedAt != null) continue;
      final FriendEntry entry = FriendEntry(
        friendshipId: f.id,
        since: f.at,
        profileId: other.id,
        displayName: other.displayName,
        kind: other.kind,
      );
      if (f.status == 'accepted') {
        friends.add(entry);
      } else if (f.requestedBy == me.id) {
        outgoing.add(entry);
      } else {
        incoming.add(entry);
      }
    }
    return FriendLists(
      profileId: me.id,
      friends: friends,
      incoming: incoming,
      outgoing: outgoing,
    );
  });

  @override
  Future<void> requestFriend(String handle) => _async(() {
    final _Profile me = _acting(null);
    _Profile? target;
    for (final _Profile p in _profiles.values) {
      if (p.handle == handle &&
          p.kind == ProfileKind.adult &&
          p.erasedAt == null &&
          p.visibility != ProfileVisibility.private) {
        target = p;
      }
    }
    if (target == null || _blockedEitherWay(me.id, target.id)) {
      _fail('not_found', 'Not found.', 404);
    }
    if (target.id == me.id) {
      _fail('cannot_friend_self', 'That is your own handle.');
    }
    final _Friendship? old = _pair(me.id, target.id);
    if (old != null && old.status == 'accepted') {
      _fail('already_friends', 'You are already friends.');
    }
    if (old != null && old.status == 'pending') {
      _fail('request_pending', 'A request is already waiting.');
    }
    _friendships.remove(old);
    _friendships.add(
      _Friendship(
        id: _id('friendship'),
        a: me.id,
        b: target.id,
        requestedBy: me.id,
        status: 'pending',
        at: _now(),
      ),
    );
  });

  _Friendship _pendingForMe(String id) {
    final _Profile me = _acting(null);
    for (final _Friendship f in _friendships) {
      if (f.id == id &&
          f.status == 'pending' &&
          (f.a == me.id || f.b == me.id) &&
          f.requestedBy != me.id) {
        return f;
      }
    }
    return _fail('not_found', 'Not found.', 404);
  }

  @override
  Future<void> acceptRequest(String friendshipId) => _async(() {
    _pendingForMe(friendshipId)
      ..status = 'accepted'
      ..at = _now();
  });

  @override
  Future<void> declineRequest(String friendshipId) => _async(() {
    _pendingForMe(friendshipId)
      ..status = 'declined'
      ..at = _now();
  });

  @override
  Future<void> removeFriend(String friendshipId, {String? profileId}) =>
      _async(() {
        final _Profile me = _acting(profileId);
        for (final _Friendship f in _friendships) {
          if (f.id == friendshipId &&
              (f.a == me.id || f.b == me.id) &&
              (f.status == 'accepted' || f.status == 'pending')) {
            f.status = 'removed';
            return;
          }
        }
        _fail('not_found', 'Not found.', 404);
      });

  @override
  Future<List<BlockedProfile>> blocks({String? profileId}) => _async(() {
    final _Profile me = _acting(profileId);
    return _blocks
        .where((_Block b) => b.blocker == me.id)
        .map(
          (_Block b) => BlockedProfile(
            profileId: b.blocked,
            displayName: _profiles[b.blocked]?.displayName ?? '',
          ),
        )
        .toList();
  });

  @override
  Future<void> block(String profileId, {String? asProfileId}) => _async(() {
    final _Profile me = _acting(asProfileId);
    if (profileId == me.id) {
      _fail('cannot_block_self', 'You cannot block yourself.');
    }
    if (!_profiles.containsKey(profileId)) _fail('not_found', 'Not found.', 404);
    if (!_blocks.any((_Block b) => b.blocker == me.id && b.blocked == profileId)) {
      _blocks.add(_Block(me.id, profileId));
    }
    _pair(me.id, profileId)?.status = 'removed';
  });

  @override
  Future<void> unblock(String profileId, {String? asProfileId}) => _async(() {
    final _Profile me = _acting(asProfileId);
    _blocks.removeWhere((_Block b) => b.blocker == me.id && b.blocked == profileId);
  });

  // ---- invites -------------------------------------------------------------
  static const String _alphabet = '23456789ABCDEFGHJKMNPQRSTVWXYZ';

  String _newCode() {
    final String s = List<String>.generate(
      10,
      (int _) => _alphabet[_random.nextInt(_alphabet.length)],
    ).join();
    return '${s.substring(0, 5)}-${s.substring(5)}';
  }

  String _normal(String code) => code.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

  _Invite _findInvite(String code) {
    final String n = _normal(code);
    for (final MapEntry<String, _Invite> e in _invites.entries) {
      final _Invite i = e.value;
      if (_normal(e.key) == n &&
          i.revokedAt == null &&
          i.uses < i.maxUses &&
          i.expiresAt.isAfter(_now())) {
        return i;
      }
    }
    return _fail('not_found', 'That invite is not valid any more.', 404);
  }

  @override
  Future<InviteCreated> createInvite({
    String? asProfileId,
    int maxUses = 1,
    int ttlHours = 72,
  }) => _async(() {
    final _Account a = _account;
    final _Profile me = _acting(asProfileId);
    final String code = _newCode();
    final _Invite i = _Invite(
      id: _id('invite'),
      createdByUser: a.id,
      profileId: me.id,
      maxUses: me.kind.isMinor ? 1 : max(1, min(10, maxUses)),
      expiresAt: _now().add(Duration(hours: max(1, min(720, ttlHours)))),
    );
    _invites[code] = i;
    return InviteCreated(
      id: i.id,
      code: code,
      link: 'https://fake.invalid/#/join/$code',
      maxUses: i.maxUses,
      expiresAt: i.expiresAt,
    );
  });

  @override
  Future<List<InviteSummary>> myInvites() => _async(() {
    final _Account a = _account;
    return _invites.values
        .where((_Invite i) => i.createdByUser == a.id)
        .map(
          (_Invite i) => InviteSummary(
            id: i.id,
            profileId: i.profileId,
            maxUses: i.maxUses,
            uses: i.uses,
            expiresAt: i.expiresAt,
            active:
                i.revokedAt == null &&
                i.uses < i.maxUses &&
                i.expiresAt.isAfter(_now()),
          ),
        )
        .toList();
  });

  @override
  Future<void> revokeInvite(String inviteId) => _async(() {
    final _Account a = _account;
    for (final _Invite i in _invites.values) {
      if (i.id == inviteId && i.createdByUser == a.id) {
        i.revokedAt = _now();
        return;
      }
    }
    _fail('not_found', 'Not found.', 404);
  });

  @override
  Future<InvitePreview> previewInvite(String code) => _async(() {
    final _Account _ = _account;
    final _Invite i = _findInvite(code);
    final _Profile creator = _profiles[i.profileId]!;
    final bool family = creator.kind.isMinor;
    return InvitePreview(
      familyInvite: family,
      inviterDisplayName: family ? null : creator.displayName,
      expiresAt: i.expiresAt,
    );
  });

  @override
  Future<RedeemResult> redeemInvite(String code, {String? asProfileId}) =>
      _async(() {
        final _Account a = _account;
        final _Invite i = _findInvite(code);
        final _Profile me = _acting(asProfileId);
        final _Profile creator = _profiles[i.profileId]!;
        if (me.kind.isMinor != creator.kind.isMinor) {
          _fail(
            'not_allowed',
            'This invite cannot be used for that profile.',
            403,
          );
        }
        if (me.id == creator.id ||
            (!me.kind.isMinor && i.createdByUser == a.id)) {
          _fail('own_invite', 'That is your own invite.');
        }
        if (_blockedEitherWay(me.id, creator.id)) {
          _fail('not_found', 'That invite is not valid any more.', 404);
        }
        if (i.redeemedBy.contains(me.id)) {
          _fail('already_redeemed', 'You already used this invite.');
        }
        final _Friendship? old = _pair(me.id, creator.id);
        if (old != null && old.status == 'accepted') {
          _fail('already_friends', 'You are already friends.');
        }
        _friendships.remove(old);
        final _Friendship f = _Friendship(
          id: _id('friendship'),
          a: creator.id,
          b: me.id,
          requestedBy: creator.id,
          status: 'accepted',
          at: _now(),
        );
        _friendships.add(f);
        i.redeemedBy.add(me.id);
        i.uses += 1;
        return RedeemResult(
          friendshipId: f.id,
          friendProfileId: creator.id,
          friendDisplayName: creator.displayName,
          friendKind: creator.kind,
        );
      });
}

class _Account {
  _Account(this.id, this.email);
  final String id;
  final String email;
}

class _Profile {
  _Profile({
    required this.id,
    required this.kind,
    required this.displayName,
    required this.visibility,
    required this.createdAt,
    this.userId,
    this.managedBy,
    this.handle,
    this.bio,
  });

  final String id;
  final ProfileKind kind;
  final String? userId;
  final String? managedBy;
  String displayName;
  String? handle;
  String? bio;
  ProfileVisibility visibility;
  final DateTime createdAt;
  DateTime? erasedAt;
}

class _Friendship {
  _Friendship({
    required this.id,
    required this.a,
    required this.b,
    required this.requestedBy,
    required this.status,
    required this.at,
  });

  final String id;
  final String a;
  final String b;
  final String requestedBy;
  String status;
  DateTime at;
}

class _Block {
  _Block(this.blocker, this.blocked);
  final String blocker;
  final String blocked;
}

class _Invite {
  _Invite({
    required this.id,
    required this.createdByUser,
    required this.profileId,
    required this.maxUses,
    required this.expiresAt,
  });

  final String id;
  final String createdByUser;
  final String profileId;
  final int maxUses;
  final DateTime expiresAt;
  int uses = 0;
  DateTime? revokedAt;
  final Set<String> redeemedBy = <String>{};
}
