import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_config.dart';
import 'backend_exception.dart';
import 'community_api.dart';
import 'models.dart';
import 'token_store.dart';

/// The real implementation: JSON over HTTPS to the community service
/// (backend/openapi.yaml). Used only when the build says
/// `COMMUNITY_BACKEND=http` and gives `COMMUNITY_API_URL`.
///
/// Nothing is logged. Errors become [BackendException] with the server's
/// stable code and a message that is safe to show.
class HttpCommunityApi implements CommunityApi {
  HttpCommunityApi({
    required String baseUrl,
    required TokenStore tokens,
    http.Client? client,
    Duration timeout = const Duration(seconds: 12),
  }) : _base = baseUrl.replaceAll(RegExp(r'/+$'), ''),
       _tokens = tokens,
       _client = client ?? http.Client(),
       _timeout = timeout;

  final String _base;
  final TokenStore _tokens;
  final http.Client _client;
  final Duration _timeout;

  @override
  bool get enabled => true;

  Future<Map<String, dynamic>?> _call(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final Uri uri = Uri.parse(
      '$_base$path',
    ).replace(queryParameters: query == null || query.isEmpty ? null : query);
    final Map<String, String> headers = <String, String>{
      'accept': 'application/json',
      if (body != null) 'content-type': 'application/json',
    };
    if (auth) {
      final String? token = await _tokens.read();
      if (token == null) {
        throw const BackendException(
          'unauthorized',
          'Please sign in first.',
          status: 401,
        );
      }
      headers['authorization'] = 'Bearer $token';
    }
    final http.Request req = http.Request(method, uri)
      ..headers.addAll(headers);
    if (body != null) req.body = jsonEncode(body);

    final http.Response res;
    try {
      res = await http.Response.fromStream(
        await _client.send(req).timeout(_timeout),
      ).timeout(_timeout);
    } on Object {
      throw const BackendException.network();
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.statusCode == 204 || res.body.isEmpty) return null;
      try {
        return decodeObject(res.body);
      } on FormatException {
        throw const BackendException.network();
      }
    }
    if (res.statusCode == 401 && auth) await _tokens.clear();
    throw _errorFrom(res);
  }

  BackendException _errorFrom(http.Response res) {
    String code = 'http_${res.statusCode}';
    String message = 'Something went wrong. Please try again.';
    try {
      final Map<String, dynamic> j = decodeObject(res.body);
      final Object? e = j['error'];
      if (e is Map<String, dynamic>) {
        final Object? c = e['code'];
        final Object? m = e['message'];
        if (c is String) code = c;
        if (m is String) message = m;
      }
    } on FormatException {
      // Keep the generic message.
    }
    return BackendException(code, message, status: res.statusCode);
  }

  Future<Map<String, dynamic>> _json(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final Map<String, dynamic>? r = await _call(
      method,
      path,
      body: body,
      query: query,
      auth: auth,
    );
    if (r == null) throw const BackendException.network();
    return r;
  }

  Map<String, String>? _profileQuery(String? profileId) =>
      profileId == null ? null : <String, String>{'profileId': profileId};

  Future<BackendSession> _startSession(Map<String, dynamic> json) async {
    final BackendSession s;
    try {
      s = BackendSession.fromJson(json);
    } on FormatException {
      throw const BackendException.network();
    }
    await _tokens.write(s.token);
    return s;
  }

  T _parse<T>(T Function() build) {
    try {
      return build();
    } on FormatException {
      throw const BackendException.network();
    }
  }

  // ---- sign-in ---------------------------------------------------------
  @override
  Future<void> requestSignInCode(String email) async {
    await _call(
      'POST',
      '/v1/auth/request-code',
      body: <String, dynamic>{'email': email},
      auth: false,
    );
  }

  @override
  Future<BackendSession> verifySignInCode({
    required String email,
    required String code,
    bool confirmAdult = false,
    String? deviceLabel,
  }) async => _startSession(
    await _json(
      'POST',
      '/v1/auth/verify-code',
      auth: false,
      body: <String, dynamic>{
        'email': email,
        'code': code,
        if (confirmAdult) 'confirmAdult': true,
        if (confirmAdult) 'termsVersion': kCommunityTermsVersion,
        if (confirmAdult) 'privacyVersion': kCommunityPrivacyVersion,
        if (deviceLabel != null) 'deviceLabel': deviceLabel,
      },
    ),
  );

  @override
  Future<BackendSession> signInWithFirebaseToken({
    required String idToken,
    bool confirmAdult = false,
    String? deviceLabel,
  }) async => _startSession(
    await _json(
      'POST',
      '/v1/auth/firebase',
      auth: false,
      body: <String, dynamic>{
        'idToken': idToken,
        if (confirmAdult) 'confirmAdult': true,
        if (confirmAdult) 'termsVersion': kCommunityTermsVersion,
        if (confirmAdult) 'privacyVersion': kCommunityPrivacyVersion,
        if (deviceLabel != null) 'deviceLabel': deviceLabel,
      },
    ),
  );

  @override
  Future<void> signOut() async {
    try {
      await _call('POST', '/v1/auth/logout');
    } on BackendException {
      // Signing out always works locally, even offline or when the token
      // had already expired.
    } finally {
      await _tokens.clear();
    }
  }

  // ---- me, profile, guardian -------------------------------------------
  @override
  Future<MeResponse> me() async {
    final Map<String, dynamic> j = await _json('GET', '/v1/me');
    return _parse(() => MeResponse.fromJson(j));
  }

  @override
  Future<BackendProfile> saveProfile({
    required String displayName,
    String? handle,
    String? bio,
    ProfileVisibility visibility = ProfileVisibility.private,
  }) async {
    final Map<String, dynamic> j = await _json(
      'PUT',
      '/v1/me/profile',
      body: <String, dynamic>{
        'displayName': displayName,
        'handle': handle,
        'bio': bio,
        'visibility': visibility.name,
      },
    );
    return _parse(() => BackendProfile.fromJson(_object(j['profile'])));
  }

  @override
  Future<void> deleteAccount({bool removePosts = false}) async {
    await _call(
      'DELETE',
      '/v1/me',
      body: <String, dynamic>{
        'confirm': 'DELETE',
        'content': removePosts ? 'remove' : 'keep_anonymous',
      },
    );
    await _tokens.clear();
  }

  @override
  Future<Map<String, dynamic>> exportMyData() => _json('GET', '/v1/me/export');

  @override
  Future<BackendProfile> addChild({
    required String nickname,
    required bool teen,
  }) async {
    final Map<String, dynamic> j = await _json(
      'POST',
      '/v1/guardian/children',
      body: <String, dynamic>{
        'nickname': nickname,
        'ageBand': teen ? 'teen13to17' : 'under13',
        'consent': <String, dynamic>{
          'version': kCommunityParentConsentVersion,
          'isParentOrGuardian': true,
        },
      },
    );
    return _parse(() => BackendProfile.fromJson(_object(j['child'])));
  }

  @override
  Future<List<BackendProfile>> children() async {
    final Map<String, dynamic> j = await _json('GET', '/v1/guardian/children');
    return _parse(
      () => _objects(j['children']).map(BackendProfile.fromJson).toList(),
    );
  }

  @override
  Future<BackendProfile> renameChild(String childId, String nickname) async {
    final Map<String, dynamic> j = await _json(
      'PATCH',
      '/v1/guardian/children/$childId',
      body: <String, dynamic>{'nickname': nickname},
    );
    return _parse(() => BackendProfile.fromJson(_object(j['child'])));
  }

  @override
  Future<void> deleteChild(String childId) async {
    await _call('DELETE', '/v1/guardian/children/$childId');
  }

  // ---- friends -----------------------------------------------------------
  @override
  Future<FriendLists> friends({String? profileId}) async {
    final Map<String, dynamic> j = await _json(
      'GET',
      '/v1/friends',
      query: _profileQuery(profileId),
    );
    return _parse(() => FriendLists.fromJson(j));
  }

  @override
  Future<void> requestFriend(String handle) async {
    await _call(
      'POST',
      '/v1/friends/requests',
      body: <String, dynamic>{'handle': handle},
    );
  }

  @override
  Future<void> acceptRequest(String friendshipId) async {
    await _call('POST', '/v1/friends/requests/$friendshipId/accept');
  }

  @override
  Future<void> declineRequest(String friendshipId) async {
    await _call('POST', '/v1/friends/requests/$friendshipId/decline');
  }

  @override
  Future<void> removeFriend(String friendshipId, {String? profileId}) async {
    await _call(
      'DELETE',
      '/v1/friends/$friendshipId',
      query: _profileQuery(profileId),
    );
  }

  @override
  Future<List<BlockedProfile>> blocks({String? profileId}) async {
    final Map<String, dynamic> j = await _json(
      'GET',
      '/v1/blocks',
      query: _profileQuery(profileId),
    );
    return _parse(
      () => _objects(j['blocks']).map(BlockedProfile.fromJson).toList(),
    );
  }

  @override
  Future<void> block(String profileId, {String? asProfileId}) async {
    await _call(
      'POST',
      '/v1/blocks',
      body: <String, dynamic>{
        'profileId': profileId,
        if (asProfileId != null) 'asProfileId': asProfileId,
      },
    );
  }

  @override
  Future<void> unblock(String profileId, {String? asProfileId}) async {
    await _call(
      'DELETE',
      '/v1/blocks/$profileId',
      query: _profileQuery(asProfileId),
    );
  }

  // ---- invites -------------------------------------------------------------
  @override
  Future<InviteCreated> createInvite({
    String? asProfileId,
    int maxUses = 1,
    int ttlHours = 72,
  }) async {
    final Map<String, dynamic> j = await _json(
      'POST',
      '/v1/invites',
      body: <String, dynamic>{
        'kind': 'friend',
        if (asProfileId != null) 'asProfileId': asProfileId,
        'maxUses': maxUses,
        'ttlHours': ttlHours,
      },
    );
    return _parse(() => InviteCreated.fromJson(_object(j['invite'])));
  }

  @override
  Future<List<InviteSummary>> myInvites() async {
    final Map<String, dynamic> j = await _json('GET', '/v1/invites');
    return _parse(
      () => _objects(j['invites']).map(InviteSummary.fromJson).toList(),
    );
  }

  @override
  Future<void> revokeInvite(String inviteId) async {
    await _call('DELETE', '/v1/invites/$inviteId');
  }

  @override
  Future<InvitePreview> previewInvite(String code) async {
    final Map<String, dynamic> j = await _json(
      'POST',
      '/v1/invites/preview',
      body: <String, dynamic>{'code': code},
    );
    return _parse(() => InvitePreview.fromJson(_object(j['invite'])));
  }

  @override
  Future<RedeemResult> redeemInvite(String code, {String? asProfileId}) async {
    final Map<String, dynamic> j = await _json(
      'POST',
      '/v1/invites/redeem',
      body: <String, dynamic>{
        'code': code,
        if (asProfileId != null) 'asProfileId': asProfileId,
      },
    );
    return _parse(() => RedeemResult.fromJson(j));
  }

  // ---- community rules -----------------------------------------------------
  @override
  Future<CommunityRulesStatus> communityRules() async {
    final Map<String, dynamic> j = await _json('GET', '/v1/community/rules');
    return _parse(() => CommunityRulesStatus.fromJson(j));
  }

  @override
  Future<void> acceptCommunityRules(String version) async {
    await _call(
      'POST',
      '/v1/community/rules/accept',
      body: <String, dynamic>{'version': version},
    );
  }

  // ---- forums ----------------------------------------------------------------
  @override
  Future<List<ForumCategory>> forumCategories() async {
    final Map<String, dynamic> j = await _json('GET', '/v1/forum/categories');
    return _parse(
      () => _objects(j['categories']).map(ForumCategory.fromJson).toList(),
    );
  }

  @override
  Future<ThreadList> forumThreads(String slug, {DateTime? before}) async {
    final Map<String, dynamic> j = await _json(
      'GET',
      '/v1/forum/categories/$slug/threads',
      query: before == null
          ? null
          : <String, String>{'before': before.toUtc().toIso8601String()},
    );
    return _parse(() => ThreadList.fromJson(j));
  }

  @override
  Future<ThreadView> forumThread(String threadId, {String? after}) async {
    final Map<String, dynamic> j = await _json(
      'GET',
      '/v1/forum/threads/$threadId',
      query: after == null ? null : <String, String>{'after': after},
    );
    return _parse(() => ThreadView.fromJson(j));
  }

  @override
  Future<SubmitResult> startThread({
    required String slug,
    required String title,
    required String body,
  }) async {
    final Map<String, dynamic> j = await _json(
      'POST',
      '/v1/forum/categories/$slug/threads',
      body: <String, dynamic>{'title': title, 'body': body},
    );
    return _parse(() => SubmitResult.fromThreadJson(j));
  }

  @override
  Future<SubmitResult> replyToThread(
    String threadId,
    String body, {
    String? replyTo,
  }) async {
    final Map<String, dynamic> j = await _json(
      'POST',
      '/v1/forum/threads/$threadId/posts',
      body: <String, dynamic>{
        'body': body,
        if (replyTo != null) 'replyTo': replyTo,
      },
    );
    return _parse(() => SubmitResult.fromPostJson(j));
  }

  @override
  Future<SubmitResult> editPost(String postId, String body) async {
    final Map<String, dynamic> j = await _json(
      'PATCH',
      '/v1/forum/posts/$postId',
      body: <String, dynamic>{'body': body},
    );
    return _parse(() => SubmitResult.fromPostJson(j));
  }

  @override
  Future<void> deletePost(String postId) async {
    await _call('DELETE', '/v1/forum/posts/$postId');
  }

  @override
  Future<void> setHelpful(String postId, {required bool helpful}) async {
    await _call(helpful ? 'PUT' : 'DELETE', '/v1/forum/posts/$postId/helpful');
  }

  // ---- report, hide ---------------------------------------------------------------
  @override
  Future<void> report({
    required CommunityTarget target,
    required String targetId,
    required ReportReason reason,
    String? details,
  }) async {
    await _call(
      'POST',
      '/v1/reports',
      body: <String, dynamic>{
        'targetType': target.name,
        'targetId': targetId,
        'reason': reason.wire,
        if (details != null && details.trim().isNotEmpty) 'details': details,
      },
    );
  }

  @override
  Future<void> hideForMe(CommunityTarget target, String targetId) async {
    await _call(
      'POST',
      '/v1/hidden',
      body: <String, dynamic>{
        'targetType': target.name,
        'targetId': targetId,
      },
    );
  }

  @override
  Future<void> showAgain(CommunityTarget target, String targetId) async {
    await _call('DELETE', '/v1/hidden/${target.name}/$targetId');
  }

  // ---- meet-ups ----------------------------------------------------------------
  @override
  Future<MeetupList> meetups({
    String? city,
    String? country,
    MeetupAudience? audience,
  }) async {
    final Map<String, String> q = <String, String>{
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (country != null && country.trim().length == 2)
        'country': country.trim().toUpperCase(),
      if (audience != null) 'audience': audience.name,
    };
    final Map<String, dynamic> j = await _json('GET', '/v1/meetups', query: q);
    return _parse(() => MeetupList.fromJson(j));
  }

  @override
  Future<List<Meetup>> myMeetups() async {
    final Map<String, dynamic> j = await _json('GET', '/v1/meetups/mine');
    return _parse(() => MeetupList.fromJson(j).meetups);
  }

  @override
  Future<List<MeetupReminder>> meetupReminders() async {
    final Map<String, dynamic> j = await _json('GET', '/v1/meetups/reminders');
    return _parse(
      () => _objects(j['reminders']).map(MeetupReminder.fromJson).toList(),
    );
  }

  @override
  Future<MeetupDetail> meetup(String meetupId) async {
    final Map<String, dynamic> j = await _json('GET', '/v1/meetups/$meetupId');
    return _parse(() => MeetupDetail.fromJson(j));
  }

  @override
  Future<Meetup> createMeetup(MeetupDraft draft) async {
    final Map<String, dynamic> j = await _json(
      'POST',
      '/v1/meetups',
      body: draft.toJson(),
    );
    return _parse(() => Meetup.fromJson(_object(j['meetup'])));
  }

  @override
  Future<void> cancelMeetup(
    String meetupId,
    CancelReason reason, {
    bool wholeSeries = false,
  }) async {
    await _call(
      'POST',
      '/v1/meetups/$meetupId/cancel',
      body: <String, dynamic>{
        'reason': reason.wire,
        'scope': wholeSeries ? 'series' : 'this',
      },
    );
  }

  @override
  Future<RsvpResult> rsvp(String meetupId, {String? childProfileId}) async {
    final Map<String, dynamic> j = await _json(
      'PUT',
      '/v1/meetups/$meetupId/rsvp',
      body: <String, dynamic>{
        'acknowledge': true,
        if (childProfileId != null) 'childProfileId': childProfileId,
      },
    );
    return _parse(() => RsvpResult.fromJson(j));
  }

  @override
  Future<void> cancelRsvp(String meetupId, {String? childProfileId}) async {
    await _call(
      'DELETE',
      '/v1/meetups/$meetupId/rsvp',
      query: childProfileId == null
          ? null
          : <String, String>{'childProfileId': childProfileId},
    );
  }

  // ---- notifications --------------------------------------------------------------
  @override
  Future<NotificationPage> notifications({bool unreadOnly = false}) async {
    final Map<String, dynamic> j = await _json(
      'GET',
      '/v1/notifications',
      query: unreadOnly ? <String, String>{'unreadOnly': 'true'} : null,
    );
    return _parse(() => NotificationPage.fromJson(j));
  }

  @override
  Future<void> markNotificationsRead({
    List<String> ids = const <String>[],
  }) async {
    if (ids.isEmpty) return;
    await _call(
      'POST',
      '/v1/notifications/read',
      body: <String, dynamic>{'ids': ids},
    );
  }

  @override
  Future<void> markAllNotificationsRead() async {
    await _call(
      'POST',
      '/v1/notifications/read',
      body: <String, dynamic>{'all': true},
    );
  }

  // ---- moderation, as the person it is about -----------------------------------------
  @override
  Future<ModerationInfo> myModeration() async {
    final Map<String, dynamic> j = await _json('GET', '/v1/me/moderation');
    return _parse(() => ModerationInfo.fromJson(j));
  }

  @override
  Future<void> appeal(String actionId, String statement) async {
    await _call(
      'POST',
      '/v1/appeals',
      body: <String, dynamic>{'actionId': actionId, 'statement': statement},
    );
  }

  /// Closes the underlying HTTP client.
  void close() => _client.close();
}

Map<String, dynamic> _object(Object? v) {
  if (v is Map<String, dynamic>) return v;
  throw const FormatException('expected an object');
}

List<Map<String, dynamic>> _objects(Object? v) {
  if (v is List<dynamic>) return v.map<Map<String, dynamic>>(_object).toList();
  throw const FormatException('expected a list');
}
