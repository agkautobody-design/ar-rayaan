
import 'package:ar_rayaan/features/academy/application/nasheed_request_provider.dart';
import 'package:ar_rayaan/features/academy/domain/nasheed_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // RULE (§8.15): mock-reset lives in setUp ONLY — never in helpers.
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('NasheedRequest', () {
    test('json round-trip preserves all fields', () {
      final NasheedRequest r = NasheedRequest(
        id: 'r1',
        title: 'Qasidah Burdah',
        artist: 'Sami Yusuf',
        url: 'https://example.com/burdah.mp3',
        note: 'studio version please',
        createdAt: DateTime(2026, 10, 7),
      );
      final NasheedRequest back = NasheedRequest.fromJson(r.toJson());
      expect(back.id, 'r1');
      expect(back.title, 'Qasidah Burdah');
      expect(back.artist, 'Sami Yusuf');
      expect(back.url, 'https://example.com/burdah.mp3');
      expect(back.note, 'studio version please');
      expect(back.createdAt, r.createdAt);
      expect(back.status, NasheedRequestStatus.pending);
    });

    test('shareText includes only the fields that exist', () {
      final NasheedRequest full = NasheedRequest(
          id: 'a', title: 'T', artist: 'Ar', url: 'https://u', note: 'N',
          createdAt: DateTime(2026));
      expect(full.shareText, contains('Title: T'));
      expect(full.shareText, contains('Artist: Ar'));
      expect(full.shareText, contains('Link: https://u'));
      expect(full.shareText, contains('Note: N'));
      final NasheedRequest bare = NasheedRequest(
          id: 'b', title: 'Only', createdAt: DateTime(2026));
      expect(bare.shareText, contains('Title: Only'));
      expect(bare.shareText, isNot(contains('Artist:')));
      expect(bare.shareText, isNot(contains('Link:')));
    });

    test('unknown status falls back to pending', () {
      final NasheedRequest r = NasheedRequest.fromJson(<String, Object?>{
        'id': 'x', 'title': 'T', 'createdAt': '2026-10-07T00:00:00.000',
        'status': 'shipped',
      });
      expect(r.status, NasheedRequestStatus.pending);
    });
  });

  group('NasheedRequestNotifier', () {
    test('requests start pending and persist through a fresh instance',
        () async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // ignore: invalid_use_of_visible_for_testing_member
      final n = NasheedRequestNotifier(prefs);
      expect(n.state, isEmpty);
      final NasheedRequest r = await n.add(
          title: '  Madinah Moon  ', artist: '  ', url: 'https://x/y.mp3');
      expect(r.title, 'Madinah Moon'); // trimmed
      expect(r.artist, isNull);        // blank -> null
      expect(r.status, NasheedRequestStatus.pending);
      expect(n.state, hasLength(1));
      // ignore: invalid_use_of_visible_for_testing_member
      final n2 = NasheedRequestNotifier(prefs);
      expect(n2.state, hasLength(1));
      expect(n2.state.single.title, 'Madinah Moon');
    });

    test('empty title is rejected', () async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // ignore: invalid_use_of_visible_for_testing_member
      final n = NasheedRequestNotifier(prefs);
      expect(() => n.add(title: '   '), throwsArgumentError);
      expect(n.state, isEmpty);
    });

    test('remove persists', () async {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      // ignore: invalid_use_of_visible_for_testing_member
      final n = NasheedRequestNotifier(prefs);
      final NasheedRequest r = await n.add(title: 'One');
      await n.add(title: 'Two');
      await n.remove(r.id);
      // ignore: invalid_use_of_visible_for_testing_member
      final n2 = NasheedRequestNotifier(prefs);
      expect(n2.state, hasLength(1));
      expect(n2.state.single.title, 'Two');
    });
  });
}
