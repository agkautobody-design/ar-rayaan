import 'package:ar_rayaan/features/academy/application/family_service.dart';
import 'package:ar_rayaan/features/games/data/online_access.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('a device with no child profiles may play online', () async {
    final OnlineVerdict v = await OnlineAccess().check();
    expect(v.blocked, isFalse);
    expect(v.needsParent, isFalse);
  });

  test('the guardian switch is off by default and per child', () async {
    final FamilyService f = FamilyService();
    final String a = await f.addChild('Amal');
    final String b = await f.addChild('Bilal');
    expect(await f.onlineGamesAllowed(a), isFalse);
    await f.setOnlineGamesAllowed(a, true);
    expect(await f.onlineGamesAllowed(a), isTrue);
    expect(await f.onlineGamesAllowed(b), isFalse);
  });

  test('an active child is blocked, even with an old guardian switch', () async {
    final FamilyService f = FamilyService();
    final String id = await f.addChild('Amal');
    await f.setActiveChild(id);
    final OnlineVerdict off = await OnlineAccess(family: f).check();
    expect(off.blocked, isTrue);
    expect(off.message, contains('Amal'));
    await f.setOnlineGamesAllowed(id, true);
    final OnlineVerdict still = await OnlineAccess(family: f).check();
    expect(still.blocked, isTrue);
  });

  test('children on the device but nobody chosen asks the parent', () async {
    final FamilyService f = FamilyService();
    await f.addChild('Amal');
    await f.clearActiveChild();
    final OnlineVerdict v = await OnlineAccess(family: f).check();
    expect(v.needsParent, isTrue);
    expect(v.blocked, isFalse);
  });

  test('deleting a child clears the switch', () async {
    final FamilyService f = FamilyService();
    final String id = await f.addChild('Amal');
    await f.setOnlineGamesAllowed(id, true);
    await f.deleteChild(id);
    expect(await f.onlineGamesAllowed(id), isFalse);
  });
}
