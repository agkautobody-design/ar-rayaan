import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/backend/backend_config.dart';
import 'package:ar_rayaan/app/core/backend/backend_exception.dart';
import 'package:ar_rayaan/app/core/backend/fake_community_api.dart';
import 'package:ar_rayaan/app/core/backend/http_community_api.dart';
import 'package:ar_rayaan/app/core/backend/models.dart';
import 'package:ar_rayaan/app/core/backend/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Matcher failsWith(String code) => throwsA(
  isA<BackendException>().having((BackendException e) => e.code, 'code', code),
);

void main() {
  late DateTime now;
  late FakeCommunityApi api;

  setUp(() {
    now = DateTime.utc(2026, 11, 1, 12);
    api = FakeCommunityApi(clock: () => now);
  });

  Future<void> signIn(
    FakeCommunityApi a,
    String email, {
    ProfileVisibility v = ProfileVisibility.community,
    bool rules = true,
  }) async {
    await a.requestSignInCode(email);
    await a.verifySignInCode(
      email: email,
      code: FakeCommunityApi.fixedCode,
      confirmAdult: true,
    );
    await a.saveProfile(displayName: 'Amina K', visibility: v);
    if (rules) await a.acceptCommunityRules(kCommunityRulesVersion);
  }

  test('rules version matches the backend', () {
    final String src = File('backend/src/versions.ts').readAsStringSync();
    expect(src, contains("COMMUNITY_RULES_VERSION = '$kCommunityRulesVersion'"));
  });

  test('report reasons match the backend list', () {
    final String src = File('backend/src/policy/moderation.ts').readAsStringSync();
    for (final ReportReason r in ReportReason.values) {
      expect(src, contains("'${r.wire}'"));
    }
  });

  group('forums', () {
    test('writing needs community visibility and accepted rules', () async {
      await signIn(api, 'a@b.co', v: ProfileVisibility.private, rules: false);
      await expectLater(
        api.startThread(slug: 'welcome', title: 'Salam all', body: 'Hello'),
        failsWith('community_visibility_required'),
      );
      await api.saveProfile(
        displayName: 'Amina K',
        visibility: ProfileVisibility.community,
      );
      await expectLater(
        api.startThread(slug: 'welcome', title: 'Salam all', body: 'Hello'),
        failsWith('rules_not_accepted'),
      );
      await api.acceptCommunityRules(kCommunityRulesVersion);
      final SubmitResult r = await api.startThread(
        slug: 'welcome',
        title: 'Salam all',
        body: 'Hello',
      );
      expect(r.pendingReview, isFalse);
    });

    test('posts are labelled community opinion; helpful count is private', () async {
      await signIn(api, 'a@b.co');
      final SubmitResult r = await api.startThread(
        slug: 'learning',
        title: 'Tajweed tips',
        body: 'My own tips',
      );
      final ThreadView v = await api.forumThread(r.threadId!);
      expect(v.posts.single.label, ForumLabel.communityOpinion);
      expect(v.posts.single.mine, isTrue);
    });

    test('Ask a scholar: members ask, only scholars answer', () async {
      await signIn(api, 'a@b.co');
      final SubmitResult q = await api.startThread(
        slug: 'ask-scholar',
        title: 'A question',
        body: 'What about this?',
      );
      expect(q.pendingReview, isTrue, reason: 'read by a moderator first');
      api.approvePending(q.threadId!);
      await expectLater(
        api.replyToThread(q.threadId!, 'I think so'),
        failsWith('not_allowed_here'),
      );
      api.makeScholar(api.signedInUserId!);
      final SubmitResult a = await api.replyToThread(q.threadId!, 'Answer');
      expect(a.pendingReview, isFalse);
      final ThreadView v = await api.forumThread(q.threadId!);
      expect(v.posts.last.label, ForumLabel.scholarAnswer);
      expect(v.thread.answered, isTrue);
    });

    test('links, takfir wording and home invitations are refused', () async {
      await signIn(api, 'a@b.co');
      for (final String bad in <String>[
        'see https://example.com',
        'he is a kafir',
        'come to my house tonight',
      ]) {
        await expectLater(
          api.startThread(slug: 'welcome', title: 'A title', body: bad),
          failsWith('content_blocked'),
        );
      }
    });

    test('sensitive topics are held for review', () async {
      await signIn(api, 'a@b.co');
      final SubmitResult r = await api.startThread(
        slug: 'sensitive',
        title: 'A calm topic',
        body: 'Respectfully',
      );
      expect(r.pendingReview, isTrue);
    });

    test('a child-safety report hides content; blocking hides the author', () async {
      await signIn(api, 'a@b.co');
      final ThreadList l = await api.forumThreads('welcome');
      final ThreadView v = await api.forumThread(l.threads.first.id);
      final ForumPost p = v.posts.first;
      await api.report(
        target: CommunityTarget.post,
        targetId: p.id,
        reason: ReportReason.childSafety,
      );
      final ForumPost after =
          (await api.forumThread(l.threads.first.id)).posts.first;
      expect(after.status, 'hidden');
      expect(after.body, isEmpty);
      await api.block(p.authorProfileId!);
      expect((await api.forumThreads('welcome')).threads, isEmpty);
    });
  });

  group('meet-ups', () {
    MeetupDraft draft({
      MeetupVenueKind kind = MeetupVenueKind.mosque,
      bool minors = false,
      MeetupAudience audience = MeetupAudience.open,
      bool halal = false,
      int? capacity,
    }) => MeetupDraft(
      title: 'Tea together',
      venueKind: kind,
      venueName: 'Local venue',
      city: 'Leicester',
      country: 'GB',
      startsAt: now.add(const Duration(days: 5)),
      audience: audience,
      guardianRsvpForMinors: minors,
      halalConfirmed: halal,
      capacity: capacity,
    );

    test('venue rules, halal cafe, minors only with verified families', () async {
      await signIn(api, 'a@b.co');
      await expectLater(
        api.createMeetup(draft(kind: MeetupVenueKind.cafe)),
        failsWith('halal_required'),
      );
      await expectLater(
        api.createMeetup(draft(minors: true)),
        failsWith('minors_need_families'),
      );
      await expectLater(
        api.createMeetup(draft(minors: true, audience: MeetupAudience.families)),
        failsWith('minors_need_verified_organiser'),
      );
      final Meetup m = await api.createMeetup(draft());
      expect(m.pendingReview, isTrue, reason: 'unverified organiser');
      api.makeVerifiedOrganiser(api.signedInUserId!);
      final Meetup v = await api.createMeetup(draft());
      expect(v.status, 'published');
      expect(v.organiser.verified, isTrue);
    });

    test('capacity, waiting list and promotion', () async {
      await signIn(api, 'org@b.co');
      api.makeVerifiedOrganiser(api.signedInUserId!);
      final Meetup m = await api.createMeetup(draft(capacity: 2));
      await api.signOut();
      await signIn(api, 'x@b.co');
      expect((await api.rsvp(m.id)).status, 'going');
      await api.signOut();
      await signIn(api, 'y@b.co');
      expect((await api.rsvp(m.id)).status, 'going');
      await api.signOut();
      await signIn(api, 'z@b.co');
      expect((await api.rsvp(m.id)).status, 'waitlist');
      await api.signOut();
      await api.requestSignInCode('x@b.co');
      await api.verifySignInCode(email: 'x@b.co', code: '000000');
      await api.cancelRsvp(m.id);
      await api.signOut();
      await api.requestSignInCode('z@b.co');
      await api.verifySignInCode(email: 'z@b.co', code: '000000');
      expect((await api.meetup(m.id)).meetup.myRsvp, 'going');
      expect(
        (await api.notifications()).notifications.map((AppNotification n) => n.kind),
        contains('meetup_waitlist_promoted'),
      );
    });

    test('children cannot be added unless the organiser allows it', () async {
      await signIn(api, 'org@b.co');
      api.makeVerifiedOrganiser(api.signedInUserId!);
      final Meetup adults = await api.createMeetup(draft());
      await api.signOut();
      await signIn(api, 'p@b.co');
      final BackendProfile kid = await api.addChild(nickname: 'Kid', teen: false);
      await expectLater(
        api.rsvp(adults.id, childProfileId: kid.id),
        failsWith('adults_only'),
      );
    });
  });

  test('disabled-by-default config', () {
    expect(BackendConfig.parse('', ''), BackendMode.off);
  });

  test('draft JSON has no home address field and repeats keep clock time', () {
    final MeetupDraft d = MeetupDraft(
      title: 'Weekly circle',
      venueKind: MeetupVenueKind.communityCentre,
      venueName: 'Centre',
      city: 'Leeds',
      country: 'GB',
      startsAt: DateTime.utc(2026, 12, 1, 18, 30),
      audience: MeetupAudience.sisters,
      recurrence: MeetupRecurrence.weekly,
      repeatTimes: 2,
    );
    final Map<String, dynamic> j = d.toJson();
    expect(j['venueKind'], 'community_centre');
    expect(j['occurrences'], <String>[
      '2026-12-08T18:30:00.000Z',
      '2026-12-15T18:30:00.000Z',
    ]);
    expect(j['acknowledgeOrganiserRules'], isTrue);
    expect(j.containsKey('homeAddress'), isFalse);
  });

  test('http: rsvp, report and notifications requests', () async {
    final MemoryTokenStore tokens = MemoryTokenStore();
    await tokens.write('t');
    final List<http.Request> seen = <http.Request>[];
    final HttpCommunityApi h = HttpCommunityApi(
      baseUrl: 'https://api.example.test',
      tokens: tokens,
      client: MockClient((http.Request r) async {
        seen.add(r);
        if (r.url.path.endsWith('/rsvp')) {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'rsvp': <String, dynamic>{'status': 'going'},
            }),
            200,
          );
        }
        if (r.url.path == '/v1/notifications') {
          return http.Response(
            jsonEncode(<String, dynamic>{
              'unreadCount': 1,
              'notifications': <dynamic>[],
            }),
            200,
          );
        }
        return http.Response('', 204);
      }),
    );
    expect((await h.rsvp('m1')).status, 'going');
    expect(jsonDecode(seen.last.body), <String, dynamic>{'acknowledge': true});
    await h.report(
      target: CommunityTarget.post,
      targetId: 'p1',
      reason: ReportReason.sectarian,
    );
    expect(jsonDecode(seen.last.body)['reason'], 'sectarian');
    await h.setHelpful('p1', helpful: false);
    expect(seen.last.method, 'DELETE');
    expect((await h.notifications()).unreadCount, 1);
  });
}
