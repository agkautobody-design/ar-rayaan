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
}
