
import 'package:ar_rayaan/features/haramain/application/journey_stamp_provider.dart';
import 'package:ar_rayaan/features/haramain/domain/journey_stamp.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // RULE (§8.15): mock-reset lives in setUp ONLY.
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('json round-trip preserves type and date', () {
    final JourneyStamp s = JourneyStamp(
      id: 'j1',
      type: JourneyType.hajj,
      completedAt: DateTime(2026, 6, 15),
    );
    final JourneyStamp back = JourneyStamp.fromJson(s.toJson());
    expect(back.id, 'j1');
    expect(back.type, JourneyType.hajj);
    expect(back.completedAt, s.completedAt);
  });

  test('unknown type falls back to umrah', () {
    final JourneyStamp s = JourneyStamp.fromJson(<String, Object?>{
      'id': 'x',
      'type': 'hajj-1449',
      'completedAt': '2026-06-15T00:00:00.000',
    });
    expect(s.type, JourneyType.umrah);
  });

  test('stamps persist through a fresh notifier instance', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // ignore: invalid_use_of_visible_for_testing_member
    final n = JourneyStampNotifier(prefs);
    expect(n.state, isEmpty);
    await n.add(type: JourneyType.umrah, completedAt: DateTime(2026, 3, 1));
    await n.add(type: JourneyType.hajj, completedAt: DateTime(2026, 6, 15));
    expect(n.state, hasLength(2));
    expect(n.state.first.type, JourneyType.hajj); // newest first
    // ignore: invalid_use_of_visible_for_testing_member
    final n2 = JourneyStampNotifier(prefs);
    expect(n2.state, hasLength(2));
    expect(n2.state.first.completedAt, DateTime(2026, 6, 15));
  });

  test('remove persists', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // ignore: invalid_use_of_visible_for_testing_member
    final n = JourneyStampNotifier(prefs);
    final JourneyStamp s = await n.add(
        type: JourneyType.umrah, completedAt: DateTime(2026, 3, 1));
    await n.add(type: JourneyType.umrah, completedAt: DateTime(2027, 3, 1));
    await n.remove(s.id);
    // ignore: invalid_use_of_visible_for_testing_member
    final n2 = JourneyStampNotifier(prefs);
    expect(n2.state, hasLength(1));
    expect(n2.state.single.completedAt, DateTime(2027, 3, 1));
  });
}
