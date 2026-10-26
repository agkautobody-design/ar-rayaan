import 'dart:convert';

import 'package:ar_rayaan/app/core/backend/backend_exception.dart';
import 'package:ar_rayaan/app/core/backend/http_community_api.dart';
import 'package:ar_rayaan/app/core/backend/models.dart';
import 'package:ar_rayaan/app/core/backend/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: <String, String>{'content-type': 'application/json'},
);

Matcher failsWith(String code, {int? status}) => throwsA(
  isA<BackendException>()
      .having((BackendException e) => e.code, 'code', code)
      .having((BackendException e) => e.status, 'status', status ?? isNull),
);

void main() {
  late List<http.Request> seen;
  late MemoryTokenStore tokens;

  HttpCommunityApi make(Future<http.Response> Function(http.Request) handler) {
    seen = <http.Request>[];
    return HttpCommunityApi(
      baseUrl: 'https://api.example.test/',
      tokens: tokens,
      client: MockClient((http.Request r) async {
        seen.add(r);
        return handler(r);
      }),
    );
  }

  setUp(() {
    tokens = MemoryTokenStore();
  });

  const Map<String, dynamic> sessionBody = <String, dynamic>{
    'token': 'ar_secret',
    'expiresAt': '2026-12-01T00:00:00Z',
    'isNewAccount': true,
    'user': <String, dynamic>{'id': 'u1', 'role': 'member'},
  };

  test('sign-in stores the token and later calls send it', () async {
    final HttpCommunityApi api = make((http.Request r) async {
      if (r.url.path == '/v1/auth/verify-code') return json(sessionBody);
      return json(<String, dynamic>{
        'user': <String, dynamic>{'id': 'u1', 'role': 'member'},
        'profile': null,
        'children': <dynamic>[],
      });
    });
    final BackendSession s = await api.verifySignInCode(
      email: 'a@b.co',
      code: '123456',
      confirmAdult: true,
      deviceLabel: 'Pixel',
    );
    expect(s.user.id, 'u1');
    expect(await tokens.read(), 'ar_secret');

    final Map<String, dynamic> sent =
        jsonDecode(seen.single.body) as Map<String, dynamic>;
    expect(sent['confirmAdult'], isTrue);
    expect(sent['termsVersion'], isNotNull);
    expect(seen.single.headers.containsKey('authorization'), isFalse);
    expect(seen.single.url.toString(), 'https://api.example.test/v1/auth/verify-code');

    final MeResponse me = await api.me();
    expect(me.profile, isNull);
    expect(seen.last.headers['authorization'], 'Bearer ar_secret');
  });

  test('without a token, authenticated calls fail locally with 401', () async {
    final HttpCommunityApi api = make((http.Request r) async => json(<String, dynamic>{}));
    await expectLater(api.me(), failsWith('unauthorized', status: 401));
    expect(seen, isEmpty, reason: 'nothing was sent');
  });

  test('server errors keep their code and message; 401 clears the token', () async {
    await tokens.write('ar_old');
    final HttpCommunityApi api = make(
      (http.Request r) async => json(<String, dynamic>{
        'error': <String, dynamic>{'code': 'unauthorized', 'message': 'Please sign in again.'},
      }, 401),
    );
    await expectLater(api.me(), failsWith('unauthorized', status: 401));
    expect(await tokens.read(), isNull);

    final HttpCommunityApi api2 = make(
      (http.Request r) async => json(<String, dynamic>{
        'error': <String, dynamic>{'code': 'handle_taken', 'message': 'That handle is already taken.'},
      }, 409),
    );
    await tokens.write('ar_new');
    try {
      await api2.saveProfile(displayName: 'A');
      fail('should throw');
    } on BackendException catch (e) {
      expect(e.code, 'handle_taken');
      expect(e.message, 'That handle is already taken.');
      expect(await tokens.read(), 'ar_new', reason: '409 does not sign out');
    }
  });

  test('unreadable and failed connections become a friendly network error', () async {
    await tokens.write('ar_t');
    final HttpCommunityApi down = make((http.Request r) async => throw http.ClientException('down'));
    await expectLater(down.me(), failsWith('network'));
    final HttpCommunityApi junk = make((http.Request r) async => http.Response('<html>', 502));
    await expectLater(junk.me(), failsWith('http_502', status: 502));
    final HttpCommunityApi badBody = make((http.Request r) async => http.Response('[1]', 200));
    await expectLater(badBody.me(), failsWith('network'));
  });

  test('requests have the documented shape', () async {
    await tokens.write('ar_t');
    final HttpCommunityApi api = make((http.Request r) async {
      switch ('${r.method} ${r.url.path}') {
        case 'POST /v1/guardian/children':
          return json(<String, dynamic>{
            'child': <String, dynamic>{
              'id': 'c1',
              'kind': 'child',
              'displayName': 'Yusuf',
              'visibility': 'private',
              'createdAt': '2026-11-01T12:00:00Z',
            },
          }, 201);
        case 'GET /v1/friends':
          return json(<String, dynamic>{
            'profileId': 'c1',
            'friends': <dynamic>[],
            'incoming': <dynamic>[],
            'outgoing': <dynamic>[],
          });
        case 'POST /v1/invites':
          return json(<String, dynamic>{
            'invite': <String, dynamic>{
              'id': 'i1',
              'code': 'ABCDE-FGHJK',
              'link': 'https://x/#/join/ABCDE-FGHJK',
              'maxUses': 1,
              'expiresAt': '2026-11-04T00:00:00Z',
            },
          }, 201);
        case 'POST /v1/invites/redeem':
          return json(<String, dynamic>{
            'friendship': <String, dynamic>{'id': 'f1', 'status': 'accepted'},
            'friend': <String, dynamic>{'id': 'p', 'displayName': 'M', 'kind': 'child'},
          });
        default:
          return http.Response('', 204);
      }
    });
    final BackendProfile kid = await api.addChild(nickname: 'Yusuf', teen: true);
    expect(kid.id, 'c1');
    final Map<String, dynamic> body = jsonDecode(seen.last.body) as Map<String, dynamic>;
    expect(body['ageBand'], 'teen13to17');
    expect((body['consent'] as Map<String, dynamic>)['isParentOrGuardian'], isTrue);

    await api.friends(profileId: 'c1');
    expect(seen.last.url.query, 'profileId=c1');

    final InviteCreated inv = await api.createInvite(asProfileId: 'c1');
    expect(inv.code, 'ABCDE-FGHJK');
    expect((jsonDecode(seen.last.body) as Map<String, dynamic>)['asProfileId'], 'c1');

    final RedeemResult r = await api.redeemInvite('abcde-fghjk', asProfileId: 'c2');
    expect(r.friendKind, ProfileKind.child);

    await api.removeFriend('f1', profileId: 'c2');
    expect(seen.last.method, 'DELETE');
    expect(seen.last.url.path, '/v1/friends/f1');
    expect(seen.last.url.query, 'profileId=c2');

    await api.acceptRequest('f9');
    expect(seen.last.url.path, '/v1/friends/requests/f9/accept');
  });

  test('deleting the account and signing out clear the token, even if the call fails', () async {
    await tokens.write('ar_t');
    final HttpCommunityApi api = make((http.Request r) async => http.Response('', 204));
    await api.deleteAccount(removePosts: true);
    expect(
      (jsonDecode(seen.last.body) as Map<String, dynamic>)['content'],
      'remove',
    );
    expect(await tokens.read(), isNull);

    await tokens.write('ar_t2');
    final HttpCommunityApi offline = make((http.Request r) async => throw http.ClientException('x'));
    await offline.signOut();
    expect(await tokens.read(), isNull);
  });
}
