import 'package:ar_rayaan/app/core/backend/backend_exception.dart';
import 'package:ar_rayaan/app/core/backend/disabled_community_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const DisabledCommunityApi api = DisabledCommunityApi();

  test('says it is disabled', () {
    expect(api.enabled, isFalse);
  });

  test('every call fails with backend_disabled and does nothing else', () async {
    final List<Future<Object?> Function()> calls =
        <Future<Object?> Function()>[
          () => api.requestSignInCode('a@b.co'),
          () => api.verifySignInCode(email: 'a@b.co', code: '000000'),
          () => api.signInWithFirebaseToken(idToken: 'x'),
          api.me,
          () => api.saveProfile(displayName: 'A'),
          api.deleteAccount,
          api.exportMyData,
          () => api.addChild(nickname: 'K', teen: false),
          api.children,
          () => api.renameChild('c', 'K'),
          () => api.deleteChild('c'),
          api.friends,
          () => api.requestFriend('h'),
          () => api.acceptRequest('f'),
          () => api.declineRequest('f'),
          () => api.removeFriend('f'),
          api.blocks,
          () => api.block('p'),
          () => api.unblock('p'),
          api.createInvite,
          api.myInvites,
          () => api.revokeInvite('i'),
          () => api.previewInvite('c'),
          () => api.redeemInvite('c'),
        ];
    for (final Future<Object?> Function() call in calls) {
      await expectLater(
        call(),
        throwsA(
          isA<BackendException>().having(
            (BackendException e) => e.code,
            'code',
            'backend_disabled',
          ),
        ),
      );
    }
  });

  test('signing out is harmless', () async {
    await api.signOut();
  });
}
