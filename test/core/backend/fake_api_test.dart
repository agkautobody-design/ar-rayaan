import 'package:ar_rayaan/app/core/backend/backend_exception.dart';
import 'package:ar_rayaan/app/core/backend/community_api.dart';
import 'package:ar_rayaan/app/core/backend/fake_community_api.dart';
import 'package:ar_rayaan/app/core/backend/models.dart';
import 'package:flutter_test/flutter_test.dart';

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
    String name = 'Amina K',
    String? handle,
    ProfileVisibility visibility = ProfileVisibility.private,
  }) async {
    await a.requestSignInCode(email);
    await a.verifySignInCode(
      email: email,
      code: FakeCommunityApi.fixedCode,
      confirmAdult: true,
    );
    await a.saveProfile(
      displayName: name,
      handle: handle,
      visibility: visibility,
    );
  }

  group('sign-in', () {
    test('needs a requested code and the adult confirmation', () async {
      await expectLater(
        api.verifySignInCode(email: 'a@b.co', code: '000000'),
        failsWith('unauthorized'),
      );
      await api.requestSignInCode('a@b.co');
      await expectLater(
        api.verifySignInCode(email: 'a@b.co', code: '123456'),
        failsWith('unauthorized'),
      );
      await expectLater(
        api.verifySignInCode(email: 'a@b.co', code: '000000'),
        failsWith('adult_confirmation_required'),
      );
      final BackendSession s = await api.verifySignInCode(
        email: 'a@b.co',
        code: '000000',
        confirmAdult: true,
      );
      expect(s.isNewAccount, isTrue);
      await api.signOut();
      final BackendSession again = await api.verifySignInCode(
        email: 'a@b.co',
        code: '000000',
      );
      expect(again.isNewAccount, isFalse);
      expect(again.user.id, s.user.id);
    });

    test('calls before sign-in are unauthorized', () async {
      await expectLater(api.me(), failsWith('unauthorized'));
      await expectLater(api.friends(), failsWith('unauthorized'));
    });
  });

  group('profile', () {
    test('refuses reserved names and taken handles', () async {
      await signIn(api, 'a@b.co', handle: 'amina_k');
      await expectLater(
        api.saveProfile(displayName: 'Hadi'),
        failsWith('display_name_invalid'),
      );
      await expectLater(
        api.saveProfile(displayName: 'h4di'),
        failsWith('display_name_invalid'),
      );
      api.seedAdult('Other', handle: 'taken_one');
      await expectLater(
        api.saveProfile(displayName: 'Amina K', handle: 'taken_one'),
        failsWith('handle_taken'),
      );
      await expectLater(
        api.saveProfile(
          displayName: 'Amina K',
          visibility: ProfileVisibility.handle,
        ),
        failsWith('handle_required'),
      );
    });
  });

  group('children', () {
    test('are private, have no handle, and are capped at eight', () async {
      await signIn(api, 'a@b.co');
      final BackendProfile kid = await api.addChild(
        nickname: 'Yusuf',
        teen: false,
      );
      expect(kid.kind, ProfileKind.child);
      expect(kid.handle, isNull);
      expect(kid.visibility, ProfileVisibility.private);
      expect((await api.me()).children.single.id, kid.id);
      for (int i = 1; i < 8; i++) {
        await api.addChild(nickname: 'Kid $i', teen: i.isEven);
      }
      await expectLater(
        api.addChild(nickname: 'Ninth', teen: false),
        failsWith('child_limit_reached'),
      );
      await expectLater(
        api.addChild(nickname: 'Imam', teen: false),
        failsWith('nickname_invalid'),
      );
      await api.deleteChild(kid.id);
      expect((await api.children()).length, 7);
      await expectLater(api.deleteChild(kid.id), failsWith('not_found'));
    });
  });

  group('friends', () {
    test('request by handle works for adults, private profiles are hidden', () async {
      await signIn(api, 'a@b.co');
      api.seedAdult('Findable', handle: 'findable_one');
      api.seedAdult(
        'Hidden',
        handle: 'hidden_one',
        visibility: ProfileVisibility.private,
      );
      await api.requestFriend('findable_one');
      expect((await api.friends()).outgoing.single.displayName, 'Findable');
      await expectLater(
        api.requestFriend('hidden_one'),
        failsWith('not_found'),
      );
      await expectLater(
        api.requestFriend('nobody_here'),
        failsWith('not_found'),
      );
      await expectLater(
        api.requestFriend('findable_one'),
        failsWith('request_pending'),
      );
    });

    test('blocking removes the friendship', () async {
      await signIn(api, 'a@b.co');
      final String other = api.seedAdult('Other', handle: 'other_one');
      await api.requestFriend('other_one');
      await api.block(other);
      expect((await api.friends()).outgoing, isEmpty);
      await expectLater(api.requestFriend('other_one'), failsWith('not_found'));
      expect((await api.blocks()).single.profileId, other);
      await api.unblock(other);
      expect(await api.blocks(), isEmpty);
    });
  });

  group('invites', () {
    test('two adults connect with a code that works once', () async {
      final FakeCommunityApi a = FakeCommunityApi(clock: () => now);
      await signIn(a, 'a@b.co', name: 'Adult A');
      final InviteCreated inv = await a.createInvite(maxUses: 5);
      expect(inv.maxUses, 5);
      expect(inv.code, matches(RegExp(r'^[2-9A-Z]{5}-[2-9A-Z]{5}$')));
      // Same fake instance, second person: sign out and in as someone else.
      await a.signOut();
      await signIn(a, 'b@b.co', name: 'Adult B');
      final InvitePreview pv = await a.previewInvite(inv.code.toLowerCase());
      expect(pv.inviterDisplayName, 'Adult A');
      expect(pv.familyInvite, isFalse);
      final RedeemResult r = await a.redeemInvite(inv.code);
      expect(r.friendDisplayName, 'Adult A');
      expect((await a.friends()).friends.length, 1);
      await expectLater(a.redeemInvite(inv.code), failsWith('already_redeemed'));
    });

    test('refuses your own invite, expired and revoked codes', () async {
      await signIn(api, 'a@b.co');
      final InviteCreated own = await api.createInvite();
      await expectLater(api.redeemInvite(own.code), failsWith('own_invite'));
      final InviteCreated gone = await api.createInvite();
      await api.revokeInvite(gone.id);
      await expectLater(api.previewInvite(gone.code), failsWith('not_found'));
      final InviteCreated short = await api.createInvite(ttlHours: 1);
      now = now.add(const Duration(hours: 2));
      await expectLater(api.previewInvite(short.code), failsWith('not_found'));
      final Map<String, bool> active = <String, bool>{
        for (final InviteSummary i in await api.myInvites()) i.id: i.active,
      };
      expect(active[gone.id], isFalse);
      expect(active[short.id], isFalse);
      expect(active[own.id], isTrue);
    });

    test('children connect only through guardians; never with an adult', () async {
      // Guardian one makes an invite for their child.
      await signIn(api, 'g1@b.co', name: 'Guardian One');
      final BackendProfile k1 = await api.addChild(nickname: 'Yusuf', teen: false);
      final InviteCreated kidInvite = await api.createInvite(
        asProfileId: k1.id,
        maxUses: 5,
      );
      expect(kidInvite.maxUses, 1, reason: "a child's invite works once");
      await api.signOut();

      // An adult with the code cannot use it, and learns nothing.
      await signIn(api, 'stranger@b.co', name: 'Stranger Adult');
      final InvitePreview pv = await api.previewInvite(kidInvite.code);
      expect(pv.familyInvite, isTrue);
      expect(pv.inviterDisplayName, isNull);
      await expectLater(
        api.redeemInvite(kidInvite.code),
        failsWith('not_allowed'),
      );
      final InviteCreated adultInvite = await api.createInvite();
      await api.signOut();

      // Guardian two redeems for their own child.
      await signIn(api, 'g2@b.co', name: 'Guardian Two');
      final BackendProfile k2 = await api.addChild(nickname: 'Maryam', teen: false);
      await expectLater(
        api.redeemInvite(adultInvite.code, asProfileId: k2.id),
        failsWith('not_allowed'),
      );
      final RedeemResult r = await api.redeemInvite(
        kidInvite.code,
        asProfileId: k2.id,
      );
      expect(r.friendKind, ProfileKind.child);
      expect((await api.friends(profileId: k2.id)).friends.single.displayName, 'Yusuf');
      // The guardian's own list does not show the child's friend.
      expect((await api.friends()).friends, isEmpty);
    });

    test("a stranger cannot act as someone else's child", () async {
      await signIn(api, 'g1@b.co');
      final BackendProfile kid = await api.addChild(nickname: 'Mine', teen: false);
      await api.signOut();
      await signIn(api, 'x@b.co', name: 'Someone Else');
      await expectLater(api.friends(profileId: kid.id), failsWith('not_found'));
      await expectLater(
        api.createInvite(asProfileId: kid.id),
        failsWith('not_found'),
      );
    });
  });

  test('deleting the account removes the person and their children', () async {
    await signIn(api, 'a@b.co', handle: 'erase_me', visibility: ProfileVisibility.handle);
    await api.addChild(nickname: 'Kid', teen: false);
    await api.deleteAccount();
    await expectLater(api.me(), failsWith('unauthorized'));
    await api.requestSignInCode('a@b.co');
    final BackendSession fresh = await api.verifySignInCode(
      email: 'a@b.co',
      code: '000000',
      confirmAdult: true,
    );
    expect(fresh.isNewAccount, isTrue);
    expect((await api.me()).children, isEmpty);
  });

  test('exports what it holds', () async {
    await signIn(api, 'a@b.co');
    final Map<String, dynamic> data = await api.exportMyData();
    expect((data['profiles'] as List<dynamic>).length, 1);
  });

  test('implements the whole interface', () {
    expect(api, isA<CommunityApi>());
    expect(api.enabled, isTrue);
  });
}
