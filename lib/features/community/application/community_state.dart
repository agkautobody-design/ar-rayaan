import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/backend/backend_exception.dart';
import '../../../app/core/backend/community_api.dart';
import '../../../app/core/backend/community_providers.dart';
import '../../../app/core/backend/models.dart';

/// State for the community screens. Everything reads the one
/// [communityApiProvider]; with the flag off that is the disabled API and no
/// screen here is reachable from the app.
///
/// Community content is deliberately NOT a source for Hadi: nothing in
/// `features/hadi` imports this file (test/features/community_isolation_test).

/// Whether this build has a community backend at all.
final Provider<bool> communityEnabledProvider = Provider<bool>(
  (Ref ref) => ref.watch(communityApiProvider).enabled,
);

CommunityApi _api(Ref ref) => ref.watch(communityApiProvider);

/// Who I am. Null when not signed in to the community.
final AutoDisposeFutureProvider<MeResponse?> communityMeProvider =
    FutureProvider.autoDispose<MeResponse?>((Ref ref) async {
      try {
        return await _api(ref).me();
      } on BackendException catch (e) {
        if (e.isUnauthorized) return null;
        rethrow;
      }
    });

final AutoDisposeFutureProvider<CommunityRulesStatus> communityRulesProvider =
    FutureProvider.autoDispose<CommunityRulesStatus>(
      (Ref ref) => _api(ref).communityRules(),
    );

final AutoDisposeFutureProvider<List<ForumCategory>> forumCategoriesProvider =
    FutureProvider.autoDispose<List<ForumCategory>>(
      (Ref ref) => _api(ref).forumCategories(),
    );

final AutoDisposeFutureProviderFamily<ThreadList, String> forumThreadsProvider =
    FutureProvider.autoDispose.family<ThreadList, String>(
      (Ref ref, String slug) => _api(ref).forumThreads(slug),
    );

final AutoDisposeFutureProviderFamily<ThreadView, String> forumThreadProvider =
    FutureProvider.autoDispose.family<ThreadView, String>(
      (Ref ref, String id) => _api(ref).forumThread(id),
    );

/// Meet-up list filter: a city (may be empty) and an audience (may be null).
typedef MeetupFilter = ({String city, MeetupAudience? audience});

final AutoDisposeFutureProviderFamily<MeetupList, MeetupFilter>
meetupsProvider = FutureProvider.autoDispose.family<MeetupList, MeetupFilter>(
  (Ref ref, MeetupFilter f) =>
      _api(ref).meetups(city: f.city, audience: f.audience),
);

final AutoDisposeFutureProviderFamily<MeetupDetail, String> meetupProvider =
    FutureProvider.autoDispose.family<MeetupDetail, String>(
      (Ref ref, String id) => _api(ref).meetup(id),
    );

final AutoDisposeFutureProvider<List<Meetup>> myMeetupsProvider =
    FutureProvider.autoDispose<List<Meetup>>((Ref ref) => _api(ref).myMeetups());

final AutoDisposeFutureProvider<List<MeetupReminder>> meetupRemindersProvider =
    FutureProvider.autoDispose<List<MeetupReminder>>(
      (Ref ref) => _api(ref).meetupReminders(),
    );

final AutoDisposeFutureProvider<FriendLists> friendListsProvider =
    FutureProvider.autoDispose<FriendLists>((Ref ref) => _api(ref).friends());

final AutoDisposeFutureProvider<List<InviteSummary>> myInvitesProvider =
    FutureProvider.autoDispose<List<InviteSummary>>(
      (Ref ref) => _api(ref).myInvites(),
    );

final AutoDisposeFutureProvider<List<BlockedProfile>> blockedProvider =
    FutureProvider.autoDispose<List<BlockedProfile>>(
      (Ref ref) => _api(ref).blocks(),
    );

final AutoDisposeFutureProvider<NotificationPage> notificationsProvider =
    FutureProvider.autoDispose<NotificationPage>(
      (Ref ref) => _api(ref).notifications(),
    );

final AutoDisposeFutureProvider<ModerationInfo> myModerationProvider =
    FutureProvider.autoDispose<ModerationInfo>(
      (Ref ref) => _api(ref).myModeration(),
    );

/// A message that is safe to show for any failure.
String friendlyError(Object e) {
  if (e is BackendException) return e.message;
  return 'Something went wrong. Please try again.';
}
