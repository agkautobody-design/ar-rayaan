import 'dart:math';

import '../../../features/majlis/domain/majlis_policy.dart';
import 'backend_config.dart';
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
      _random = random ?? Random(7) {
    _seedCommunity();
  }

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

  // ---- community phase 2 state ---------------------------------------------
  final Set<String> _acceptedRules = <String>{}; // user ids
  final Set<String> _scholars = <String>{}; // user ids
  final Set<String> _organisers = <String>{}; // user ids (verified)
  final List<_Category> _categories = <_Category>[];
  final List<_Thread> _threads = <_Thread>[];
  final List<_Post> _posts = <_Post>[];
  final Set<String> _helpful = <String>{}; // 'profileId|postId'
  final Set<String> _hidden = <String>{}; // 'profileId|type|id'
  final List<_Report> _reports = <_Report>[];
  final List<_Meetup> _meetupList = <_Meetup>[];
  final List<_Rsvp> _rsvps = <_Rsvp>[];
  final List<_Note> _notes = <_Note>[];
  final List<DateTime> _writeTimes = <DateTime>[];
  final Map<String, _Sanction> _mutes = <String, _Sanction>{}; // by user id

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

  // ======================================================================
  // Community phase 2: forums, meet-ups, notifications, moderation.
  // Mirrors backend/src/{forums,meetups,reports,notifications}.ts closely
  // enough that a screen behaves the same against the real service.
  // ======================================================================

  /// Test helper: this user may give scholar answers (a verified credential).
  void makeScholar(String userId) => _scholars.add(userId);

  /// Test helper: this user is a verified organiser (publishes at once).
  void makeVerifiedOrganiser(String userId) => _organisers.add(userId);

  /// Test helper: the signed-in user's id.
  String? get signedInUserId => _me;

  /// Test helper: mutes a user until [until] (null = until lifted).
  void muteUser(String userId, {DateTime? until}) =>
      _mutes[userId] = _Sanction(until);

  /// Test helper: a moderator approves a held post or thread.
  void approvePending(String id) {
    for (final _Post p in _posts) {
      if (p.id == id || p.threadId == id) {
        if (p.status == 'pending_review') p.status = 'visible';
      }
    }
    for (final _Thread t in _threads) {
      if (t.id == id && t.status == 'pending_review') t.status = 'open';
    }
    for (final _Meetup m in _meetupList) {
      if (m.id == id && m.status == 'pending_review') m.status = 'published';
    }
  }

  /// Reports filed so far, for tests.
  List<({String type, String id, ReportReason reason})> get filedReports =>
      _reports
          .map(
            (_Report r) => (type: r.type, id: r.targetId, reason: r.reason),
          )
          .toList();

  void _seedCommunity() {
    void cat(
      String slug,
      String title,
      String description,
      ForumCategoryKind kind, {
      String post = 'member',
      String reply = 'member',
      bool strict = false,
      String note = '',
    }) {
      _categories.add(
        _Category(
          id: 'cat-$slug',
          slug: slug,
          title: title,
          description: description,
          kind: kind,
          whoCanPost: post,
          whoCanReply: reply,
          strict: strict,
          note: note,
        ),
      );
    }
    cat(
      'welcome',
      'Welcome and introductions',
      'Say salam and introduce yourself. Be kind to people who are new.',
      ForumCategoryKind.general,
      note: 'Introductions only. Do not share contact details or where you live.',
    );
    cat(
      'learning',
      'Learning together',
      'Study questions and tips shared as fellow learners.',
      ForumCategoryKind.learning,
      note:
          'Replies here are community opinion, not rulings. Questions that '
          'need a ruling belong in Ask a scholar.',
    );
    cat(
      'daily-life',
      'Daily life and family',
      'Everyday life, family, work and community, with adab.',
      ForumCategoryKind.family,
      note: 'No private information about other people. No photos.',
    );
    cat(
      'ask-scholar',
      'Ask a scholar',
      'Ask a question. Only verified scholars answer here, and their '
          'answers are labelled.',
      ForumCategoryKind.askScholar,
      reply: 'scholar',
      strict: true,
      note:
          'Every question is read by a moderator before it appears. '
          'Community members do not answer here.',
    );
    cat(
      'wellbeing',
      'Wellbeing and support',
      'Gentle support for the heart and mind. Support, not diagnosis.',
      ForumCategoryKind.wellbeing,
      note:
          'If you are in danger, contact local emergency services or a '
          'crisis line now.',
    );
    cat(
      'announcements',
      'Announcements',
      'News from the Ar-Rayaan team.',
      ForumCategoryKind.announcements,
      post: 'moderator',
      reply: 'moderator',
      note: 'Staff only.',
    );
    cat(
      'sensitive',
      'Sensitive topics',
      'Differences between schools of thought and other delicate subjects, '
          'discussed with respect. Every post is reviewed before it appears.',
      ForumCategoryKind.sensitive,
      strict: true,
      note:
          'No takfir (declaring others out of the faith), no fatwa-giving, '
          'no insults. Posts that break this are removed.',
    );

    // A little sample data so a developer can click through. It is plain
    // development text and is never shown by a build without the fake.
    final String hostProfile = seedAdult(
      'Yusuf (sample)',
      handle: 'yusuf_sample',
      visibility: ProfileVisibility.community,
    );
    final String hostUser = _profiles[hostProfile]!.userId!;
    final _Thread t = _Thread(
      id: _id('thread'),
      categoryId: 'cat-welcome',
      authorProfileId: hostProfile,
      title: 'Salam, welcome (sample thread)',
      createdAt: _now(),
    );
    _threads.add(t);
    _posts.add(
      _Post(
        id: _id('post'),
        threadId: t.id,
        authorProfileId: hostProfile,
        body: 'Sample post for development. Say salam and introduce yourself.',
        label: ForumLabel.communityOpinion,
        createdAt: _now(),
      ),
    );
    _organisers.add(hostUser);
    _meetupList.add(
      _Meetup(
        id: _id('meetup'),
        organiserProfileId: hostProfile,
        title: 'Community tea after Jumu’ah (sample)',
        description: 'A sample meet-up for development.',
        venueKind: MeetupVenueKind.communityCentre,
        venueName: 'Sample Community Centre',
        city: 'Leicester',
        country: 'GB',
        startsAt: _now().add(const Duration(days: 3)),
        audience: MeetupAudience.open,
        minorsPolicy: false,
        capacity: 20,
        halal: false,
        status: 'published',
      ),
    );
  }

  _Profile _writer() {
    final _Profile p = _acting(null);
    if (p.visibility != ProfileVisibility.community) {
      _fail(
        'community_visibility_required',
        'To take part, choose “Visible in the community” in your '
            'profile. Your display name will be shown.',
        403,
      );
    }
    if (!_acceptedRules.contains(p.userId)) {
      _fail(
        'rules_not_accepted',
        'Please read and accept the community rules first.',
        403,
      );
    }
    final _Sanction? m = _mutes[p.userId];
    if (m != null && (m.until == null || m.until!.isAfter(_now()))) {
      _fail('muted', 'You cannot post right now.', 403);
    }
    return p;
  }

  void _burst() {
    final DateTime cutoff = _now().subtract(const Duration(seconds: 60));
    _writeTimes.removeWhere((DateTime t) => t.isBefore(cutoff));
    if (_writeTimes.length >= 3) {
      _fail('too_many_requests', 'Please slow down a little.', 429);
    }
    _writeTimes.add(_now());
  }

  static final RegExp _linkRe = RegExp(
    r'(https?://|www\.|\b[a-z0-9-]+\.(com|net|org|io|me|co)\b)',
    caseSensitive: false,
  );
  static final RegExp _homeRe = RegExp(
    r'(come to my (house|home|flat)|my (home|house) address|at my (house|home|flat)\b)',
    caseSensitive: false,
  );
  // A tiny stand-in for the server's lists (which a scholar must review).
  static final RegExp _takfirRe = RegExp(
    r'\b(takfir|kafir|kuffar|murtad)\b',
    caseSensitive: false,
  );

  void _screen(Iterable<String> texts) {
    for (final String t in texts) {
      if (_linkRe.hasMatch(t)) {
        _fail('content_blocked', 'That link cannot be shared here.', 422);
      }
      if (_homeRe.hasMatch(t)) {
        _fail(
          'content_blocked',
          'Meet-ups and conversations happen in public places, never at '
              'someone’s home.',
          422,
        );
      }
      if (_takfirRe.hasMatch(t)) {
        _fail('content_blocked', 'That wording is not allowed here.', 422);
      }
    }
  }

  bool _standing(String need, _Profile p) {
    switch (need) {
      case 'scholar':
        return _scholars.contains(p.userId);
      case 'moderator':
        return false; // the fake has no staff role
      default:
        return true;
    }
  }

  ForumCategory _categoryView(_Category c, _Profile? me) => ForumCategory(
    id: c.id,
    slug: c.slug,
    title: c.title,
    description: c.description,
    rulesNote: c.note,
    kind: c.kind,
    strictModeration: c.strict,
    canStart: me != null && _standing(c.whoCanPost, me),
    canReply: me != null && _standing(c.whoCanReply, me),
    threadCount: _threads
        .where(
          (_Thread t) =>
              t.categoryId == c.id &&
              (t.status == 'open' || t.status == 'locked'),
        )
        .length,
  );

  bool _hiddenFor(String profileId, String type, String id) =>
      _hidden.contains('$profileId|$type|$id');

  ForumThread _threadView(_Thread t, String? meId) {
    final int count = _posts
        .where((_Post p) => p.threadId == t.id && p.status == 'visible')
        .length;
    final _Category c = _categories.firstWhere(
      (_Category x) => x.id == t.categoryId,
    );
    final DateTime last = _posts
        .where((_Post p) => p.threadId == t.id && p.status == 'visible')
        .fold<DateTime>(
          t.createdAt,
          (DateTime a, _Post p) => p.createdAt.isAfter(a) ? p.createdAt : a,
        );
    return ForumThread(
      id: t.id,
      categoryId: t.categoryId,
      categorySlug: c.slug,
      title: t.title,
      authorName: _profiles[t.authorProfileId]?.displayName ?? '',
      authorProfileId: t.authorProfileId,
      postCount: count,
      createdAt: t.createdAt,
      lastPostAt: last,
      pinned: t.pinned,
      locked: t.status == 'locked',
      pendingReview: t.status == 'pending_review',
      answered: _posts.any(
        (_Post p) =>
            p.threadId == t.id &&
            p.label == ForumLabel.scholarAnswer &&
            p.status == 'visible',
      ),
      mine: meId != null && t.authorProfileId == meId,
    );
  }

  ForumPost _postView(_Post p, _Profile me) {
    final bool mine = p.authorProfileId == me.id;
    final bool gone =
        _blockedEitherWay(me.id, p.authorProfileId) ||
        _hiddenFor(me.id, 'post', p.id);
    if (gone) {
      return ForumPost(
        id: p.id,
        threadId: p.threadId,
        label: p.label,
        createdAt: p.createdAt,
        status: 'hidden_by_you',
        replyTo: p.replyTo,
        mine: mine,
      );
    }
    if (!mine && (p.status == 'hidden' || p.status == 'removed')) {
      return ForumPost(
        id: p.id,
        threadId: p.threadId,
        label: p.label,
        createdAt: p.createdAt,
        status: p.status,
        replyTo: p.replyTo,
      );
    }
    final int n = _helpful.where((String h) => h.endsWith('|${p.id}')).length;
    return ForumPost(
      id: p.id,
      threadId: p.threadId,
      replyTo: p.replyTo,
      authorName: _profiles[p.authorProfileId]?.displayName ?? '',
      authorProfileId: p.authorProfileId,
      body: p.body,
      label: p.label,
      status: p.status,
      createdAt: p.createdAt,
      editedAt: p.editedAt,
      helpfulByMe: _helpful.contains('${me.id}|${p.id}'),
      helpfulCount: mine ? n : null,
      scholarOrg: p.label == ForumLabel.scholarAnswer
          ? 'Verified scholar'
          : null,
      mine: mine,
    );
  }

  void _note(String userId, String kind, Map<String, dynamic> payload) {
    _notes.add(
      _Note(
        id: _id('note'),
        userId: userId,
        kind: kind,
        payload: payload,
        createdAt: _now(),
      ),
    );
  }

  // ---- community rules ----------------------------------------------------
  @override
  Future<CommunityRulesStatus> communityRules() => _async(() {
    final _Account a = _account;
    final _Profile? p = _ownAdult(a.id);
    final _Sanction? m = _mutes[a.id];
    final bool muted = m != null && (m.until == null || m.until!.isAfter(_now()));
    return CommunityRulesStatus(
      version: kCommunityRulesVersion,
      accepted: _acceptedRules.contains(a.id),
      hasProfile: p != null,
      communityVisible: p?.visibility == ProfileVisibility.community,
      mutedUntil: muted ? (m.until?.toUtc().toIso8601String() ?? 'indefinite') : null,
    );
  });

  @override
  Future<void> acceptCommunityRules(String version) => _async(() {
    final _Account a = _account;
    if (version != kCommunityRulesVersion) {
      _fail('rules_outdated', 'Please read the current community rules.', 422);
    }
    if (_ownAdult(a.id) == null) {
      _fail('profile_required', 'Create your profile first.', 403);
    }
    _acceptedRules.add(a.id);
  });

  // ---- forums ----------------------------------------------------------------
  @override
  Future<List<ForumCategory>> forumCategories() => _async(() {
    final _Profile? me = _ownAdult(_account.id);
    return _categories.map((_Category c) => _categoryView(c, me)).toList();
  });

  @override
  Future<ThreadList> forumThreads(String slug, {DateTime? before}) =>
      _async(() {
        final _Profile me = _acting(null);
        final _Category c = _categories.firstWhere(
          (_Category x) => x.slug == slug,
          orElse: () => _fail('not_found', 'Not found.', 404),
        );
        final List<ForumThread> out =
            _threads
                .where(
                  (_Thread t) =>
                      t.categoryId == c.id &&
                      (t.status == 'open' ||
                          t.status == 'locked' ||
                          (t.status == 'pending_review' &&
                              t.authorProfileId == me.id)) &&
                      !_blockedEitherWay(me.id, t.authorProfileId) &&
                      !_hiddenFor(me.id, 'thread', t.id),
                )
                .map((_Thread t) => _threadView(t, me.id))
                .where(
                  (ForumThread t) =>
                      before == null || t.pinned || t.lastPostAt.isBefore(before),
                )
                .toList()
              ..sort((ForumThread a, ForumThread b) {
                if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
                return b.lastPostAt.compareTo(a.lastPostAt);
              });
        return ThreadList(threads: out, hasMore: false);
      });

  _Thread _visibleThread(String id, _Profile me) {
    final _Thread t = _threads.firstWhere(
      (_Thread x) => x.id == id,
      orElse: () => _fail('not_found', 'Not found.', 404),
    );
    final bool ok =
        (t.status == 'open' || t.status == 'locked') &&
            !_blockedEitherWay(me.id, t.authorProfileId) ||
        (t.status == 'pending_review' && t.authorProfileId == me.id);
    if (!ok) _fail('not_found', 'Not found.', 404);
    return t;
  }

  @override
  Future<ThreadView> forumThread(String threadId, {String? after}) => _async(() {
    final _Profile me = _acting(null);
    final _Thread t = _visibleThread(threadId, me);
    final List<_Post> posts =
        _posts
            .where(
              (_Post p) =>
                  p.threadId == t.id &&
                  (p.status == 'visible' ||
                      p.status == 'hidden' ||
                      p.status == 'removed' ||
                      (p.status == 'pending_review' &&
                          p.authorProfileId == me.id)),
            )
            .toList()
          ..sort((_Post a, _Post b) => a.createdAt.compareTo(b.createdAt));
    return ThreadView(
      thread: _threadView(t, me.id),
      posts: posts.map((_Post p) => _postView(p, me)).toList(),
      hasMore: false,
    );
  });

  @override
  Future<SubmitResult> startThread({
    required String slug,
    required String title,
    required String body,
  }) => _async(() {
    final _Profile me = _writer();
    final String t = title.trim();
    final String b = body.trim();
    if (t.length < 4 || t.length > 140 || b.isEmpty || b.length > 4000) {
      _fail('validation_failed', 'Some fields are missing or not valid.', 400);
    }
    _burst();
    final _Category c = _categories.firstWhere(
      (_Category x) => x.slug == slug,
      orElse: () => _fail('not_found', 'Not found.', 404),
    );
    if (!_standing(c.whoCanPost, me)) {
      _fail('not_allowed_here', 'You cannot start a thread in this category.', 403);
    }
    _screen(<String>[t, b]);
    final bool pending = c.strict;
    final _Thread th = _Thread(
      id: _id('thread'),
      categoryId: c.id,
      authorProfileId: me.id,
      title: t,
      createdAt: _now(),
      status: pending ? 'pending_review' : 'open',
    );
    _threads.add(th);
    final _Post p = _Post(
      id: _id('post'),
      threadId: th.id,
      authorProfileId: me.id,
      body: b,
      label: c.kind == ForumCategoryKind.askScholar
          ? ForumLabel.question
          : ForumLabel.communityOpinion,
      createdAt: _now(),
      status: pending ? 'pending_review' : 'visible',
    );
    _posts.add(p);
    return SubmitResult(
      threadId: th.id,
      postId: p.id,
      pendingReview: pending,
      showHelp: false,
    );
  });

  @override
  Future<SubmitResult> replyToThread(
    String threadId,
    String body, {
    String? replyTo,
  }) => _async(() {
    final _Profile me = _writer();
    final String b = body.trim();
    if (b.isEmpty || b.length > 4000) {
      _fail('validation_failed', 'Some fields are missing or not valid.', 400);
    }
    _burst();
    final _Thread t = _visibleThread(threadId, me);
    if (t.status == 'locked') _fail('thread_locked', 'This thread is closed.');
    final _Category c = _categories.firstWhere(
      (_Category x) => x.id == t.categoryId,
    );
    if (!_standing(c.whoCanReply, me)) {
      _fail(
        'not_allowed_here',
        c.kind == ForumCategoryKind.askScholar
            ? 'Only verified scholars answer in Ask a scholar.'
            : 'You cannot reply in this category.',
        403,
      );
    }
    _screen(<String>[b]);
    final bool scholar =
        c.kind == ForumCategoryKind.askScholar && _scholars.contains(me.userId);
    final bool pending = c.strict && !scholar;
    final _Post p = _Post(
      id: _id('post'),
      threadId: t.id,
      authorProfileId: me.id,
      body: b,
      label: scholar ? ForumLabel.scholarAnswer : ForumLabel.communityOpinion,
      createdAt: _now(),
      replyTo: replyTo,
      status: pending ? 'pending_review' : 'visible',
    );
    _posts.add(p);
    if (!pending && t.authorProfileId != me.id) {
      final String? owner = _profiles[t.authorProfileId]?.userId;
      if (owner != null) {
        _note(owner, 'forum_reply', <String, dynamic>{'threadId': t.id, 'postId': p.id});
      }
    }
    return SubmitResult(
      threadId: t.id,
      postId: p.id,
      pendingReview: pending,
      showHelp: false,
    );
  });

  @override
  Future<SubmitResult> editPost(String postId, String body) => _async(() {
    final _Profile me = _writer();
    final _Post p = _posts.firstWhere(
      (_Post x) => x.id == postId && x.authorProfileId == me.id,
      orElse: () => _fail('not_found', 'Not found.', 404),
    );
    if (_now().difference(p.createdAt) > const Duration(minutes: 15)) {
      _fail('edit_window_closed', 'Posts can be edited for 15 minutes.');
    }
    final String b = body.trim();
    if (b.isEmpty || b.length > 4000) {
      _fail('validation_failed', 'Some fields are missing or not valid.', 400);
    }
    _screen(<String>[b]);
    p
      ..body = b
      ..editedAt = _now();
    final _Thread t = _threads.firstWhere((_Thread x) => x.id == p.threadId);
    final _Category c = _categories.firstWhere(
      (_Category x) => x.id == t.categoryId,
    );
    if (c.strict && p.label != ForumLabel.scholarAnswer) {
      p.status = 'pending_review';
    }
    return SubmitResult(
      threadId: p.threadId,
      postId: p.id,
      pendingReview: p.status == 'pending_review',
      showHelp: false,
    );
  });

  @override
  Future<void> deletePost(String postId) => _async(() {
    final _Profile me = _acting(null);
    final _Post p = _posts.firstWhere(
      (_Post x) => x.id == postId && x.authorProfileId == me.id,
      orElse: () => _fail('not_found', 'Not found.', 404),
    );
    final _Post? first = _posts
        .where((_Post x) => x.threadId == p.threadId)
        .fold<_Post?>(
          null,
          (_Post? a, _Post x) =>
              a == null || x.createdAt.isBefore(a.createdAt) ? x : a,
        );
    if (first?.id == p.id) {
      _threads.removeWhere((_Thread t) => t.id == p.threadId);
      _posts.removeWhere((_Post x) => x.threadId == p.threadId);
    } else {
      p
        ..status = 'removed'
        ..body = '';
    }
  });

  @override
  Future<void> setHelpful(String postId, {required bool helpful}) => _async(() {
    final _Profile me = _acting(null);
    final _Post p = _posts.firstWhere(
      (_Post x) => x.id == postId && x.status == 'visible',
      orElse: () => _fail('not_found', 'Not found.', 404),
    );
    if (p.authorProfileId == me.id) {
      _fail('own_content', 'You cannot do that to your own content.');
    }
    if (helpful) {
      _helpful.add('${me.id}|$postId');
    } else {
      _helpful.remove('${me.id}|$postId');
    }
  });

  // ---- report, hide ---------------------------------------------------------------
  @override
  Future<void> report({
    required CommunityTarget target,
    required String targetId,
    required ReportReason reason,
    String? details,
  }) => _async(() {
    final _Profile me = _acting(null);
    final String? owner = _ownerProfileOf(target, targetId);
    if (owner == null) _fail('not_found', 'Not found.', 404);
    if (owner == me.id) {
      _fail('own_content', 'You cannot report your own content.');
    }
    final bool dup = _reports.any(
      (_Report r) =>
          r.reporter == me.id && r.type == target.name && r.targetId == targetId,
    );
    if (dup) return;
    _reports.add(
      _Report(me.id, target.name, targetId, reason),
    );
    // Hide-first: a child-safety report, or three independent reports,
    // hides the content until a person reviews it.
    final int n = _reports
        .where((_Report r) => r.type == target.name && r.targetId == targetId)
        .length;
    if (reason == ReportReason.childSafety || n >= 3) {
      for (final _Post p in _posts) {
        if (target == CommunityTarget.post &&
            p.id == targetId &&
            p.status == 'visible') {
          p.status = 'hidden';
        }
      }
      for (final _Thread t in _threads) {
        if (target == CommunityTarget.thread &&
            t.id == targetId &&
            t.status == 'open') {
          t.status = 'hidden';
        }
      }
      for (final _Meetup m in _meetupList) {
        if (target == CommunityTarget.meetup &&
            m.id == targetId &&
            m.status == 'published') {
          m.status = 'hidden';
        }
      }
    }
  });

  String? _ownerProfileOf(CommunityTarget t, String id) {
    switch (t) {
      case CommunityTarget.post:
        for (final _Post p in _posts) {
          if (p.id == id) return p.authorProfileId;
        }
      case CommunityTarget.thread:
        for (final _Thread x in _threads) {
          if (x.id == id) return x.authorProfileId;
        }
      case CommunityTarget.meetup:
        for (final _Meetup m in _meetupList) {
          if (m.id == id) return m.organiserProfileId;
        }
      case CommunityTarget.profile:
        final _Profile? p = _profiles[id];
        if (p != null && !p.kind.isMinor) return p.id;
    }
    return null;
  }

  @override
  Future<void> hideForMe(CommunityTarget target, String targetId) => _async(() {
    final _Profile me = _acting(null);
    if (target == CommunityTarget.profile) {
      _fail('validation_failed', 'Block the person instead.', 400);
    }
    if (_ownerProfileOf(target, targetId) == null) {
      _fail('not_found', 'Not found.', 404);
    }
    _hidden.add('${me.id}|${target.name}|$targetId');
  });

  @override
  Future<void> showAgain(CommunityTarget target, String targetId) => _async(() {
    final _Profile me = _acting(null);
    _hidden.remove('${me.id}|${target.name}|$targetId');
  });

  // ---- meet-ups ----------------------------------------------------------------
  int _going(_Meetup m) => _rsvps
      .where((_Rsvp r) => r.meetupId == m.id && r.status == 'going')
      .length;

  Meetup _meetupView(_Meetup m, String? meId) {
    final int going = _going(m);
    final _Profile org = _profiles[m.organiserProfileId]!;
    final bool verified = _organisers.contains(org.userId);
    String? mine;
    for (final _Rsvp r in _rsvps) {
      if (r.meetupId == m.id && r.profileId == meId && r.status != 'cancelled') {
        mine = r.status;
      }
    }
    return Meetup(
      id: m.id,
      title: m.title,
      description: m.description,
      venueKind: m.venueKind,
      venueName: m.venueName,
      venueAddress: m.venueAddress,
      city: m.city,
      country: m.country,
      startsAt: m.startsAt,
      endsAt: m.endsAt,
      audience: m.audience,
      guardianRsvpForMinors: m.minorsPolicy,
      capacity: m.capacity,
      spotsLeft: m.capacity == null
          ? null
          : (m.capacity! - going).clamp(0, 1 << 30),
      goingCount: going,
      waitlistCount: _rsvps
          .where((_Rsvp r) => r.meetupId == m.id && r.status == 'waitlist')
          .length,
      accessibilityNotes: m.accessibilityNotes,
      halalConfirmed: m.halal,
      status: m.status,
      recurrence: m.recurrence,
      cancelReason: m.cancelReason,
      organiser: MeetupOrganiser(
        profileId: org.id,
        displayName: org.displayName,
        verified: verified,
        orgName: verified ? 'Verified organiser' : null,
      ),
      mine: meId != null && m.organiserProfileId == meId,
      myRsvp: mine,
    );
  }

  @override
  Future<MeetupList> meetups({
    String? city,
    String? country,
    MeetupAudience? audience,
  }) => _async(() {
    final _Profile me = _acting(null);
    final List<Meetup> out =
        _meetupList
            .where(
              (_Meetup m) =>
                  m.status == 'published' &&
                  m.startsAt.isAfter(_now()) &&
                  (city == null ||
                      city.isEmpty ||
                      m.city.toLowerCase() == city.toLowerCase()) &&
                  (country == null ||
                      country.isEmpty ||
                      m.country == country.toUpperCase()) &&
                  (audience == null || m.audience == audience) &&
                  !_blockedEitherWay(me.id, m.organiserProfileId) &&
                  !_hiddenFor(me.id, 'meetup', m.id),
            )
            .map((_Meetup m) => _meetupView(m, me.id))
            .toList()
          ..sort((Meetup a, Meetup b) => a.startsAt.compareTo(b.startsAt));
    return MeetupList(meetups: out);
  });

  @override
  Future<List<Meetup>> myMeetups() => _async(() {
    final _Profile me = _acting(null);
    return _meetupList
        .where(
          (_Meetup m) =>
              m.organiserProfileId == me.id ||
              _rsvps.any(
                (_Rsvp r) =>
                    r.meetupId == m.id &&
                    r.profileId == me.id &&
                    r.status != 'cancelled',
              ),
        )
        .map((_Meetup m) => _meetupView(m, me.id))
        .toList();
  });

  @override
  Future<List<MeetupReminder>> meetupReminders() => _async(() {
    final _Profile me = _acting(null);
    final DateTime horizon = _now().add(const Duration(days: 7));
    return _meetupList
        .where(
          (_Meetup m) =>
              m.status == 'published' &&
              m.startsAt.isAfter(_now()) &&
              m.startsAt.isBefore(horizon) &&
              _rsvps.any(
                (_Rsvp r) =>
                    r.meetupId == m.id &&
                    r.profileId == me.id &&
                    r.status == 'going',
              ),
        )
        .map(
          (_Meetup m) => MeetupReminder(
            meetupId: m.id,
            title: m.title,
            startsAt: m.startsAt,
            venueName: m.venueName,
            city: m.city,
            remindAt: <DateTime>[
              m.startsAt.subtract(const Duration(hours: 24)),
              m.startsAt.subtract(const Duration(hours: 2)),
            ],
          ),
        )
        .toList();
  });

  _Meetup _findMeetup(String id, _Profile me) {
    final _Meetup m = _meetupList.firstWhere(
      (_Meetup x) => x.id == id,
      orElse: () => _fail('not_found', 'Not found.', 404),
    );
    final bool mineOrg = m.organiserProfileId == me.id;
    final bool ok =
        mineOrg ||
        ((m.status == 'published' || m.status == 'cancelled') &&
            !_blockedEitherWay(me.id, m.organiserProfileId));
    if (!ok) _fail('not_found', 'Not found.', 404);
    return m;
  }

  @override
  Future<MeetupDetail> meetup(String meetupId) => _async(() {
    final _Profile me = _acting(null);
    final _Meetup m = _findMeetup(meetupId, me);
    MeetupAttendees? att;
    if (m.organiserProfileId == me.id) {
      final List<MeetupAttendee> adults = <MeetupAttendee>[];
      int kids = 0;
      for (final _Rsvp r in _rsvps) {
        if (r.meetupId != m.id || r.status == 'cancelled') continue;
        final _Profile p = _profiles[r.profileId]!;
        if (p.kind.isMinor) {
          if (r.status == 'going') kids++;
        } else {
          adults.add(
            MeetupAttendee(
              profileId: p.id,
              displayName: p.displayName,
              status: r.status,
            ),
          );
        }
      }
      att = MeetupAttendees(adults: adults, childrenGoing: kids);
    }
    return MeetupDetail(meetup: _meetupView(m, me.id), attendees: att);
  });

  @override
  Future<Meetup> createMeetup(MeetupDraft d) => _async(() {
    final _Profile me = _writer();
    final String title = d.title.trim();
    if (title.length < 4 ||
        d.venueName.trim().length < 2 ||
        d.city.trim().length < 2 ||
        d.country.trim().length != 2) {
      _fail('validation_failed', 'Some fields are missing or not valid.', 400);
    }
    _screen(<String>[title, d.description, d.venueName, d.venueAddress ?? '']);
    final Duration lead = d.startsAt.difference(_now());
    if (lead < const Duration(hours: 2)) {
      _fail('too_soon', 'Meet-ups must be set at least two hours ahead.', 422);
    }
    if (lead > const Duration(days: 180)) {
      _fail('too_far', 'Meet-ups can be set up to 180 days ahead.', 422);
    }
    if (d.venueKind == MeetupVenueKind.cafe && !d.halalConfirmed) {
      _fail(
        'halal_required',
        'A cafe is accepted only when you confirm it is halal.',
        422,
      );
    }
    final bool verified = _organisers.contains(me.userId);
    if (d.guardianRsvpForMinors) {
      if (d.audience != MeetupAudience.families) {
        _fail(
          'minors_need_families',
          'Children can only be included in a families meet-up.',
          422,
        );
      }
      if (!verified) {
        _fail(
          'minors_need_verified_organiser',
          'Only a verified organiser can include children.',
          422,
        );
      }
    }
    final _Meetup m = _Meetup(
      id: _id('meetup'),
      organiserProfileId: me.id,
      title: title,
      description: d.description.trim(),
      venueKind: d.venueKind,
      venueName: d.venueName.trim(),
      venueAddress: d.venueAddress?.trim(),
      city: d.city.trim(),
      country: d.country.trim().toUpperCase(),
      startsAt: d.startsAt,
      endsAt: d.endsAt,
      audience: d.audience,
      minorsPolicy: d.guardianRsvpForMinors,
      capacity: d.capacity,
      accessibilityNotes: d.accessibilityNotes,
      halal: d.halalConfirmed,
      status: verified ? 'published' : 'pending_review',
      recurrence: d.recurrence,
    );
    _meetupList.add(m);
    for (final DateTime later in d.occurrences) {
      _meetupList.add(
        _Meetup(
          id: _id('meetup'),
          organiserProfileId: me.id,
          title: title,
          description: m.description,
          venueKind: m.venueKind,
          venueName: m.venueName,
          venueAddress: m.venueAddress,
          city: m.city,
          country: m.country,
          startsAt: later,
          endsAt: d.endsAt?.add(later.difference(d.startsAt)),
          audience: m.audience,
          minorsPolicy: m.minorsPolicy,
          capacity: m.capacity,
          accessibilityNotes: m.accessibilityNotes,
          halal: m.halal,
          status: m.status,
          recurrence: m.recurrence,
        ),
      );
    }
    return _meetupView(m, me.id);
  });

  @override
  Future<void> cancelMeetup(
    String meetupId,
    CancelReason reason, {
    bool wholeSeries = false,
  }) => _async(() {
    final _Profile me = _acting(null);
    final _Meetup m = _meetupList.firstWhere(
      (_Meetup x) => x.id == meetupId && x.organiserProfileId == me.id,
      orElse: () => _fail('not_found', 'Not found.', 404),
    );
    if (m.status != 'published' && m.status != 'pending_review') {
      _fail('invalid_state', 'This meet-up cannot be cancelled.');
    }
    m
      ..status = 'cancelled'
      ..cancelReason = reason.wire;
    for (final _Rsvp r in _rsvps) {
      if (r.meetupId == m.id && r.status != 'cancelled') {
        r.status = 'cancelled';
        final String? uid = _profiles[r.profileId]?.userId ??
            _profiles[r.profileId]?.managedBy;
        if (uid != null && uid != me.userId) {
          _note(uid, 'meetup_cancelled', <String, dynamic>{
            'meetupId': m.id,
            'reason': reason.wire,
          });
        }
      }
    }
  });

  @override
  Future<RsvpResult> rsvp(String meetupId, {String? childProfileId}) =>
      _async(() {
        final _Profile me = _writer();
        final _Meetup m = _findMeetup(meetupId, me);
        if (m.status != 'published') {
          _fail('not_found', 'Not found.', 404);
        }
        if (!m.startsAt.isAfter(_now())) {
          _fail('already_started', 'This meet-up has started.');
        }
        _Profile? child;
        if (childProfileId != null) {
          child = _profiles[childProfileId];
          if (child == null || child.managedBy != me.userId) {
            _fail('not_found', 'Not found.', 404);
          }
          if (!m.minorsPolicy) {
            _fail('adults_only', 'This meet-up is for adults only.');
          }
        }
        String put(_Profile p) {
          final int going = _going(m);
          final bool full = m.capacity != null && going >= m.capacity!;
          final String status = full ? 'waitlist' : 'going';
          _rsvps.removeWhere(
            (_Rsvp r) => r.meetupId == m.id && r.profileId == p.id,
          );
          _rsvps.add(_Rsvp(m.id, p.id, status));
          return status;
        }

        final String mine = put(me);
        final String? kid = child == null ? null : put(child);
        return RsvpResult(status: mine, childStatus: kid);
      });

  @override
  Future<void> cancelRsvp(String meetupId, {String? childProfileId}) =>
      _async(() {
        final _Profile me = _acting(null);
        final Set<String> who = <String>{
          if (childProfileId == null) me.id,
          ?childProfileId,
          if (childProfileId == null)
            for (final _Profile p in _profiles.values)
              if (p.managedBy == me.userId) p.id,
        };
        for (final _Rsvp r in _rsvps) {
          if (r.meetupId == meetupId && who.contains(r.profileId)) {
            r.status = 'cancelled';
          }
        }
        // The next person on the waiting list moves up.
        final _Meetup? m = _meetupList
            .where((_Meetup x) => x.id == meetupId)
            .firstOrNull;
        if (m != null && m.capacity != null) {
          for (final _Rsvp r in _rsvps) {
            if (_going(m) >= m.capacity!) break;
            if (r.meetupId == meetupId && r.status == 'waitlist') {
              r.status = 'going';
              final String? uid = _profiles[r.profileId]?.userId;
              if (uid != null) {
                _note(uid, 'meetup_waitlist_promoted', <String, dynamic>{
                  'meetupId': meetupId,
                });
              }
            }
          }
        }
      });

  // ---- notifications --------------------------------------------------------------
  @override
  Future<NotificationPage> notifications({bool unreadOnly = false}) =>
      _async(() {
        final String uid = _account.id;
        final List<_Note> mine = _notes
            .where((_Note n) => n.userId == uid)
            .toList()
            .reversed
            .toList();
        return NotificationPage(
          serverTime: _now(),
          unreadCount: mine.where((_Note n) => n.readAt == null).length,
          notifications: mine
              .where((_Note n) => !unreadOnly || n.readAt == null)
              .map(
                (_Note n) => AppNotification(
                  id: n.id,
                  kind: n.kind,
                  payload: n.payload,
                  readAt: n.readAt,
                  createdAt: n.createdAt,
                ),
              )
              .toList(),
        );
      });

  @override
  Future<void> markNotificationsRead({
    List<String> ids = const <String>[],
  }) => _async(() {
    final String uid = _account.id;
    for (final _Note n in _notes) {
      if (n.userId == uid && ids.contains(n.id)) n.readAt ??= _now();
    }
  });

  @override
  Future<void> markAllNotificationsRead() => _async(() {
    final String uid = _account.id;
    for (final _Note n in _notes) {
      if (n.userId == uid) n.readAt ??= _now();
    }
  });

  // ---- moderation, as the person it is about -----------------------------------------
  @override
  Future<ModerationInfo> myModeration() => _async(() {
    _account;
    return const ModerationInfo(
      accountStatus: 'active',
      strikePoints: 0,
      actions: <ModerationNotice>[],
    );
  });

  @override
  Future<void> appeal(String actionId, String statement) => _async(() {
    _account;
    if (statement.trim().isEmpty) {
      _fail('validation_failed', 'Some fields are missing or not valid.', 400);
    }
    _fail('not_found', 'Not found.', 404);
  });
}

class _Sanction {
  _Sanction(this.until);
  final DateTime? until;
}

class _Category {
  _Category({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.kind,
    required this.whoCanPost,
    required this.whoCanReply,
    required this.strict,
    required this.note,
  });
  final String id;
  final String slug;
  final String title;
  final String description;
  final ForumCategoryKind kind;
  final String whoCanPost;
  final String whoCanReply;
  final bool strict;
  final String note;
}

class _Thread {
  _Thread({
    required this.id,
    required this.categoryId,
    required this.authorProfileId,
    required this.title,
    required this.createdAt,
    this.status = 'open',
  });
  final String id;
  final String categoryId;
  final String authorProfileId;
  final String title;
  final DateTime createdAt;
  String status;
  bool pinned = false;
}

class _Post {
  _Post({
    required this.id,
    required this.threadId,
    required this.authorProfileId,
    required this.body,
    required this.label,
    required this.createdAt,
    this.replyTo,
    this.status = 'visible',
  });
  final String id;
  final String threadId;
  final String authorProfileId;
  String body;
  final ForumLabel label;
  final DateTime createdAt;
  final String? replyTo;
  String status;
  DateTime? editedAt;
}

class _Report {
  _Report(this.reporter, this.type, this.targetId, this.reason);
  final String reporter;
  final String type;
  final String targetId;
  final ReportReason reason;
}

class _Meetup {
  _Meetup({
    required this.id,
    required this.organiserProfileId,
    required this.title,
    required this.venueKind,
    required this.venueName,
    required this.city,
    required this.country,
    required this.startsAt,
    required this.audience,
    required this.minorsPolicy,
    required this.halal,
    required this.status,
    this.description = '',
    this.venueAddress,
    this.endsAt,
    this.capacity,
    this.accessibilityNotes,
    this.recurrence = MeetupRecurrence.none,
  });
  final String id;
  final String organiserProfileId;
  final String title;
  final String description;
  final MeetupVenueKind venueKind;
  final String venueName;
  final String? venueAddress;
  final String city;
  final String country;
  final DateTime startsAt;
  final DateTime? endsAt;
  final MeetupAudience audience;
  final bool minorsPolicy;
  final int? capacity;
  final String? accessibilityNotes;
  final bool halal;
  final MeetupRecurrence recurrence;
  String status;
  String? cancelReason;
}

class _Rsvp {
  _Rsvp(this.meetupId, this.profileId, this.status);
  final String meetupId;
  final String profileId;
  String status;
}

class _Note {
  _Note({
    required this.id,
    required this.userId,
    required this.kind,
    required this.payload,
    required this.createdAt,
  });
  final String id;
  final String userId;
  final String kind;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  DateTime? readAt;
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
