import 'package:ar_rayaan/app/core/backend/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a profile round-trips and unknown values fall back safely', () {
    final BackendProfile p = BackendProfile.fromJson(<String, dynamic>{
      'id': 'p1',
      'kind': 'child',
      'displayName': 'Yusuf',
      'handle': null,
      'bio': null,
      'visibility': 'private',
      'createdAt': '2026-11-01T12:00:00.000Z',
    });
    expect(p.kind, ProfileKind.child);
    expect(p.kind.isMinor, isTrue);
    expect(p.handle, isNull);
    expect(BackendProfile.fromJson(p.toJson()).displayName, 'Yusuf');

    final BackendProfile odd = BackendProfile.fromJson(<String, dynamic>{
      'id': 'p2',
      'kind': 'martian',
      'displayName': 'X',
      'visibility': 'everyone',
      'createdAt': '2026-11-01T12:00:00.000Z',
    });
    expect(odd.kind, ProfileKind.adult);
    expect(odd.visibility, ProfileVisibility.private, reason: 'least public');
  });

  test('malformed data throws FormatException, not a cast error', () {
    expect(
      () => BackendProfile.fromJson(<String, dynamic>{'id': 3}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => decodeObject('[1,2]'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => InviteCreated.fromJson(<String, dynamic>{
        'id': 'i',
        'code': 'c',
        'link': 'l',
        'expiresAt': 'yesterday',
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('friend lists, session and preview parse', () {
    final FriendLists l = FriendLists.fromJson(<String, dynamic>{
      'profileId': 'me',
      'friends': <dynamic>[
        <String, dynamic>{
          'friendshipId': 'f1',
          'since': '2026-11-01T12:00:00Z',
          'profile': <String, dynamic>{
            'id': 'p9',
            'displayName': 'Amina',
            'kind': 'adult',
          },
        },
      ],
      'incoming': <dynamic>[],
      'outgoing': <dynamic>[],
    });
    expect(l.friends.single.displayName, 'Amina');
    expect(l.incoming, isEmpty);

    final BackendSession s = BackendSession.fromJson(<String, dynamic>{
      'token': 'ar_x',
      'expiresAt': '2026-12-01T00:00:00Z',
      'isNewAccount': true,
      'user': <String, dynamic>{'id': 'u1', 'role': 'member'},
    });
    expect(s.isNewAccount, isTrue);
    expect(s.user.email, isNull);

    final InvitePreview v = InvitePreview.fromJson(<String, dynamic>{
      'familyInvite': true,
      'inviterDisplayName': null,
      'expiresAt': '2026-11-04T00:00:00Z',
    });
    expect(v.inviterDisplayName, isNull);

    final RedeemResult r = RedeemResult.fromJson(<String, dynamic>{
      'friendship': <String, dynamic>{'id': 'f2', 'status': 'accepted'},
      'friend': <String, dynamic>{
        'id': 'p3',
        'displayName': 'Maryam',
        'kind': 'child',
      },
    });
    expect(r.friendKind, ProfileKind.child);
  });

  test('forum, meet-up and notification models read snake_case names', () {
    final ForumCategory c = ForumCategory.fromJson(<String, dynamic>{
      'id': 'c',
      'slug': 'ask',
      'title': 'Ask a scholar',
      'kind': 'ask_scholar',
      'strictModeration': true,
    });
    expect(c.kind, ForumCategoryKind.askScholar);
    expect(c.strictModeration, isTrue);

    final ForumPost post = ForumPost.fromJson(<String, dynamic>{
      'id': 'p',
      'threadId': 't',
      'authorName': 'A',
      'body': 'b',
      'label': 'community_opinion',
      'createdAt': '2026-11-01T12:00:00Z',
    });
    expect(post.label, ForumLabel.communityOpinion);

    final ForumPost unknown = ForumPost.fromJson(<String, dynamic>{
      'id': 'p',
      'threadId': 't',
      'authorName': 'A',
      'body': 'b',
      'label': 'something_else',
      'createdAt': '2026-11-01T12:00:00Z',
    });
    expect(
      unknown.label,
      ForumLabel.communityOpinion,
      reason: 'an unknown label can never read as scholar guidance',
    );

    final Meetup m = Meetup.fromJson(<String, dynamic>{
      'id': 'm',
      'title': 'Tea after Jumuah',
      'venueKind': 'community_centre',
      'venueName': 'Local centre',
      'city': 'Toronto',
      'country': 'CA',
      'startsAt': '2026-11-20T18:00:00Z',
      'audience': 'sisters',
      'minorsPolicy': 'adults_only',
      'capacity': 20,
      'organiser': <String, dynamic>{
        'profileId': 'o',
        'displayName': 'Imam',
        'verified': true,
      },
    });
    expect(m.venueKind, MeetupVenueKind.communityCentre);
    expect(m.audience, MeetupAudience.sisters);
    expect(m.guardianRsvpForMinors, isFalse);
    expect(m.capacity, 20);

    final AppNotification n = AppNotification.fromJson(<String, dynamic>{
      'id': 'n',
      'kind': 'friend_request',
      'payload': <String, dynamic>{'friendshipId': 'f'},
      'createdAt': '2026-11-01T12:00:00Z',
    });
    expect(n.readAt, isNull);
    expect(n.payload['friendshipId'], 'f');
  });
}
