import 'models.dart';

/// Everything the app can ask of the community backend. Screens depend on
/// this interface only; which implementation runs is decided in
/// `community_providers.dart` from a compile-time flag (default: off).
///
/// Rules the server enforces and the fake mirrors (so UI built on the fake
/// behaves like the real thing):
///  * accounts are for adults; a child or teen is a profile under a parent;
///  * a child has no handle, no public profile and cannot be found;
///  * friendships never cross the adult/child line; children connect only
///    through invites that each child's guardian made or used.
abstract interface class CommunityApi {
  /// False for the disabled implementation. UI should hide community entry
  /// points when this is false.
  bool get enabled;

  // ---- sign-in ---------------------------------------------------------
  /// E-mail a one-time code (e-mail-code mode).
  Future<void> requestSignInCode(String email);

  Future<BackendSession> verifySignInCode({
    required String email,
    required String code,
    bool confirmAdult = false,
    String? deviceLabel,
  });

  /// Exchange the app's existing Firebase sign-in (an ID token) for a
  /// community session. Anonymous Firebase users are refused by the server.
  Future<BackendSession> signInWithFirebaseToken({
    required String idToken,
    bool confirmAdult = false,
    String? deviceLabel,
  });

  Future<void> signOut();

  // ---- me, profile, guardian -------------------------------------------
  Future<MeResponse> me();

  Future<BackendProfile> saveProfile({
    required String displayName,
    String? handle,
    String? bio,
    ProfileVisibility visibility = ProfileVisibility.private,
  });

  /// Erases the account and personal data. [removePosts] also removes the
  /// person's forum posts instead of leaving them anonymised.
  Future<void> deleteAccount({bool removePosts = false});

  Future<Map<String, dynamic>> exportMyData();

  Future<BackendProfile> addChild({
    required String nickname,
    required bool teen,
  });

  Future<List<BackendProfile>> children();

  Future<BackendProfile> renameChild(String childId, String nickname);

  Future<void> deleteChild(String childId);

  // ---- friends -----------------------------------------------------------
  /// Lists for me, or for a child I manage when [profileId] is given.
  Future<FriendLists> friends({String? profileId});

  /// Adults only. Children are never found by handle.
  Future<void> requestFriend(String handle);

  Future<void> acceptRequest(String friendshipId);

  Future<void> declineRequest(String friendshipId);

  Future<void> removeFriend(String friendshipId, {String? profileId});

  Future<List<BlockedProfile>> blocks({String? profileId});

  Future<void> block(String profileId, {String? asProfileId});

  Future<void> unblock(String profileId, {String? asProfileId});

  // ---- invites -------------------------------------------------------------
  /// [asProfileId] names a child the caller manages (a guardian-issued invite).
  Future<InviteCreated> createInvite({
    String? asProfileId,
    int maxUses = 1,
    int ttlHours = 72,
  });

  Future<List<InviteSummary>> myInvites();

  Future<void> revokeInvite(String inviteId);

  Future<InvitePreview> previewInvite(String code);

  Future<RedeemResult> redeemInvite(String code, {String? asProfileId});

  // ---- community rules -----------------------------------------------------
  /// Whether I may write yet (profile, community-visible, rules accepted).
  Future<CommunityRulesStatus> communityRules();

  /// Records that I read and accept rules [version]; needed before the first
  /// post, thread or meet-up.
  Future<void> acceptCommunityRules(String version);

  // ---- forums ----------------------------------------------------------------
  /// Adults only. Community answers are opinion; scholar answers are in their
  /// own category and labelled.
  Future<List<ForumCategory>> forumCategories();

  Future<ThreadList> forumThreads(String slug, {DateTime? before});

  Future<ThreadView> forumThread(String threadId, {String? after});

  Future<SubmitResult> startThread({
    required String slug,
    required String title,
    required String body,
  });

  Future<SubmitResult> replyToThread(
    String threadId,
    String body, {
    String? replyTo,
  });

  Future<SubmitResult> editPost(String postId, String body);

  Future<void> deletePost(String postId);

  /// One gentle reaction. There is no dislike and no ranking.
  Future<void> setHelpful(String postId, {required bool helpful});

  // ---- report, hide, block ----------------------------------------------------
  Future<void> report({
    required CommunityTarget target,
    required String targetId,
    required ReportReason reason,
    String? details,
  });

  /// Hides a post, thread or meet-up for me only.
  Future<void> hideForMe(CommunityTarget target, String targetId);

  Future<void> showAgain(CommunityTarget target, String targetId);

  // ---- meet-ups ----------------------------------------------------------------
  Future<MeetupList> meetups({
    String? city,
    String? country,
    MeetupAudience? audience,
  });

  /// Meet-ups I organise or have signed up for.
  Future<List<Meetup>> myMeetups();

  Future<List<MeetupReminder>> meetupReminders();

  Future<MeetupDetail> meetup(String meetupId);

  /// May come back `pendingReview` when the organiser is not yet verified.
  Future<Meetup> createMeetup(MeetupDraft draft);

  Future<void> cancelMeetup(
    String meetupId,
    CancelReason reason, {
    bool wholeSeries = false,
  });

  /// [childProfileId] adds a child the caller is guardian of, only where the
  /// organiser allows guardians to bring children.
  Future<RsvpResult> rsvp(String meetupId, {String? childProfileId});

  Future<void> cancelRsvp(String meetupId, {String? childProfileId});

  // ---- notifications --------------------------------------------------------------
  /// Polled; there is no push in phase 2.
  Future<NotificationPage> notifications({bool unreadOnly = false});

  Future<void> markNotificationsRead({List<String> ids = const <String>[]});

  Future<void> markAllNotificationsRead();

  // ---- moderation, as the person it is about -----------------------------------------
  Future<ModerationInfo> myModeration();

  Future<void> appeal(String actionId, String statement);
}
