import 'backend_exception.dart';
import 'community_api.dart';
import 'models.dart';

/// The implementation in every build that has not switched the backend on
/// (the default). Every call fails with [BackendException.disabled]; it does
/// no I/O and keeps no state, so the app behaves exactly as it did before.
class DisabledCommunityApi implements CommunityApi {
  const DisabledCommunityApi();

  @override
  bool get enabled => false;

  Future<T> _off<T>() => Future<T>.error(const BackendException.disabled());

  @override
  Future<void> requestSignInCode(String email) => _off<void>();

  @override
  Future<BackendSession> verifySignInCode({
    required String email,
    required String code,
    bool confirmAdult = false,
    String? deviceLabel,
  }) => _off<BackendSession>();

  @override
  Future<BackendSession> signInWithFirebaseToken({
    required String idToken,
    bool confirmAdult = false,
    String? deviceLabel,
  }) => _off<BackendSession>();

  @override
  Future<void> signOut() => Future<void>.value();

  @override
  Future<MeResponse> me() => _off<MeResponse>();

  @override
  Future<BackendProfile> saveProfile({
    required String displayName,
    String? handle,
    String? bio,
    ProfileVisibility visibility = ProfileVisibility.private,
  }) => _off<BackendProfile>();

  @override
  Future<void> deleteAccount({bool removePosts = false}) => _off<void>();

  @override
  Future<Map<String, dynamic>> exportMyData() => _off<Map<String, dynamic>>();

  @override
  Future<BackendProfile> addChild({
    required String nickname,
    required bool teen,
  }) => _off<BackendProfile>();

  @override
  Future<List<BackendProfile>> children() => _off<List<BackendProfile>>();

  @override
  Future<BackendProfile> renameChild(String childId, String nickname) =>
      _off<BackendProfile>();

  @override
  Future<void> deleteChild(String childId) => _off<void>();

  @override
  Future<FriendLists> friends({String? profileId}) => _off<FriendLists>();

  @override
  Future<void> requestFriend(String handle) => _off<void>();

  @override
  Future<void> acceptRequest(String friendshipId) => _off<void>();

  @override
  Future<void> declineRequest(String friendshipId) => _off<void>();

  @override
  Future<void> removeFriend(String friendshipId, {String? profileId}) =>
      _off<void>();

  @override
  Future<List<BlockedProfile>> blocks({String? profileId}) =>
      _off<List<BlockedProfile>>();

  @override
  Future<void> block(String profileId, {String? asProfileId}) => _off<void>();

  @override
  Future<void> unblock(String profileId, {String? asProfileId}) => _off<void>();

  @override
  Future<InviteCreated> createInvite({
    String? asProfileId,
    int maxUses = 1,
    int ttlHours = 72,
  }) => _off<InviteCreated>();

  @override
  Future<List<InviteSummary>> myInvites() => _off<List<InviteSummary>>();

  @override
  Future<void> revokeInvite(String inviteId) => _off<void>();

  @override
  Future<InvitePreview> previewInvite(String code) => _off<InvitePreview>();

  @override
  Future<RedeemResult> redeemInvite(String code, {String? asProfileId}) =>
      _off<RedeemResult>();

  @override
  Future<CommunityRulesStatus> communityRules() => _off<CommunityRulesStatus>();

  @override
  Future<void> acceptCommunityRules(String version) => _off<void>();

  @override
  Future<List<ForumCategory>> forumCategories() => _off<List<ForumCategory>>();

  @override
  Future<ThreadList> forumThreads(String slug, {DateTime? before}) =>
      _off<ThreadList>();

  @override
  Future<ThreadView> forumThread(String threadId, {String? after}) =>
      _off<ThreadView>();

  @override
  Future<SubmitResult> startThread({
    required String slug,
    required String title,
    required String body,
  }) => _off<SubmitResult>();

  @override
  Future<SubmitResult> replyToThread(
    String threadId,
    String body, {
    String? replyTo,
  }) => _off<SubmitResult>();

  @override
  Future<SubmitResult> editPost(String postId, String body) =>
      _off<SubmitResult>();

  @override
  Future<void> deletePost(String postId) => _off<void>();

  @override
  Future<void> setHelpful(String postId, {required bool helpful}) =>
      _off<void>();

  @override
  Future<void> report({
    required CommunityTarget target,
    required String targetId,
    required ReportReason reason,
    String? details,
  }) => _off<void>();

  @override
  Future<void> hideForMe(CommunityTarget target, String targetId) =>
      _off<void>();

  @override
  Future<void> showAgain(CommunityTarget target, String targetId) =>
      _off<void>();

  @override
  Future<MeetupList> meetups({
    String? city,
    String? country,
    MeetupAudience? audience,
  }) => _off<MeetupList>();

  @override
  Future<List<Meetup>> myMeetups() => _off<List<Meetup>>();

  @override
  Future<List<MeetupReminder>> meetupReminders() =>
      _off<List<MeetupReminder>>();

  @override
  Future<MeetupDetail> meetup(String meetupId) => _off<MeetupDetail>();

  @override
  Future<Meetup> createMeetup(MeetupDraft draft) => _off<Meetup>();

  @override
  Future<void> cancelMeetup(
    String meetupId,
    CancelReason reason, {
    bool wholeSeries = false,
  }) => _off<void>();

  @override
  Future<RsvpResult> rsvp(String meetupId, {String? childProfileId}) =>
      _off<RsvpResult>();

  @override
  Future<void> cancelRsvp(String meetupId, {String? childProfileId}) =>
      _off<void>();

  @override
  Future<NotificationPage> notifications({bool unreadOnly = false}) =>
      _off<NotificationPage>();

  @override
  Future<void> markNotificationsRead({List<String> ids = const <String>[]}) =>
      _off<void>();

  @override
  Future<void> markAllNotificationsRead() => _off<void>();

  @override
  Future<ModerationInfo> myModeration() => _off<ModerationInfo>();

  @override
  Future<void> appeal(String actionId, String statement) => _off<void>();
}
