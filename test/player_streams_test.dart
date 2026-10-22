// The in-app YouTube / Spotify player and My Playlists.
//
// Law under test: the app builds an embed address only from a parsed,
// validated link on fixed hosts; a catalogue track plays from the approved
// sources list only; a pasted link is personal and hidden by the household
// filter; corrupt stored data never crashes the screen.
import 'dart:convert';
import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/app/theme/app_theme.dart';
import 'package:ar_rayaan/features/academy/application/stream_player_provider.dart';
import 'package:ar_rayaan/features/academy/application/user_playlist_provider.dart';
import 'package:ar_rayaan/features/academy/data/player_sources_pack.dart';
import 'package:ar_rayaan/features/academy/data/user_playlist_repository.dart';
import 'package:ar_rayaan/features/academy/domain/stream_link.dart';
import 'package:ar_rayaan/features/academy/domain/user_playlist.dart';
import 'package:ar_rayaan/features/academy/presentation/playlists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String yt = 'dQw4w9WgXcQ';
const String sp = '4uLU6hMCjMI75M1A2tKUQC';

void main() {
  group('StreamLink.parse', () {
    test('YouTube addresses', () {
      const Map<String, String> ok = <String, String>{
        'https://www.youtube.com/watch?v=$yt&list=PLabcdefghijk':
            'youtube:video:$yt',
        'youtu.be/$yt?si=abc': 'youtube:video:$yt',
        'https://m.youtube.com/shorts/$yt': 'youtube:video:$yt',
        'https://music.youtube.com/watch?v=$yt': 'youtube:video:$yt',
        'https://www.youtube.com/embed/$yt': 'youtube:video:$yt',
        'https://www.youtube.com/playlist?list=PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf':
            'youtube:playlist:PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf',
      };
      ok.forEach((String raw, String key) {
        expect(StreamLink.parse(raw)?.key, key, reason: raw);
      });
    });

    test('Spotify addresses and URIs', () {
      expect(StreamLink.parse('https://open.spotify.com/track/$sp?si=x')?.key,
          'spotify:track:$sp');
      expect(StreamLink.parse('https://open.spotify.com/intl-fr/album/$sp')?.key,
          'spotify:album:$sp');
      expect(StreamLink.parse('spotify:playlist:$sp')?.key,
          'spotify:playlist:$sp');
    });

    test('everything else is refused', () {
      const List<String> bad = <String>[
        '',
        '   ',
        'javascript:alert(1)',
        'data:text/html,<script>1</script>',
        'https://evil.com/watch?v=$yt',
        'https://youtube.com.evil.com/watch?v=$yt',
        'https://evil.com/?u=https://youtu.be/$yt',
        'https://www.youtube.com/watch?v=short',
        'https://www.youtube.com/watch?v=$yt<script>',
        'https://open.spotify.com/user/abc',
        'https://open.spotify.com/track/short',
        'https://spotify.link/abc',
        'dQw4w9WgXcQ',
        'https://youtu.be/$yt extra',
      ];
      for (final String raw in bad) {
        expect(StreamLink.parse(raw), isNull, reason: raw);
      }
      expect(StreamLink.parse('https://youtu.be/${'a' * 3000}'), isNull);
      expect(StreamLink.parse(null), isNull);
    });

    test('embed and open addresses use fixed hosts only', () {
      final StreamLink v = StreamLink.parse('https://youtu.be/$yt')!;
      expect(v.embedUri.host, 'www.youtube-nocookie.com');
      expect(v.embedUri.path, '/embed/$yt');
      expect(v.openUri.host, 'www.youtube.com');
      final StreamLink s = StreamLink.parse('spotify:track:$sp')!;
      expect(s.embedUri.toString(), 'https://open.spotify.com/embed/track/$sp');
      expect(s.openUri.toString(), 'https://open.spotify.com/track/$sp');
      final StreamLink p = StreamLink.parse(
          'https://www.youtube.com/playlist?list=PLrAXtmErZgOeiKm4sgNOknGvNjby9efdf')!;
      expect(p.embedUri.path, '/embed/videoseries');
    });

    test('JSON round trip; a tampered entry is dropped', () {
      final StreamLink l = StreamLink.parse('https://youtu.be/$yt')!;
      expect(StreamLink.fromJson(l.toJson()), l);
      expect(
          StreamLink.fromJson(<String, dynamic>{
            'service': 'youtube',
            'kind': 'video',
            'id': '"><script>',
          }),
          isNull);
      expect(StreamLink.fromJson('nope'), isNull);
    });
  });

  group('UserPlaylist', () {
    PlaylistItem catalog(String id, String cid) =>
        PlaylistItem(id: id, title: 'T $id', catalogId: cid);

    test('adds, de-duplicates and removes', () {
      UserPlaylist p = const UserPlaylist(id: 'a', name: 'Mine');
      p = p.withItem(catalog('1', 'urdu-001'));
      p = p.withItem(catalog('2', 'urdu-001')); // same catalogue track
      expect(p.items, hasLength(1));
      final StreamLink l = StreamLink.parse('https://youtu.be/$yt')!;
      p = p.withItem(PlaylistItem(id: '3', title: 'L', link: l));
      p = p.withItem(PlaylistItem(id: '4', title: 'L again', link: l));
      expect(p.items, hasLength(2));
      expect(p.items.last.isPersonal, isTrue);
      p = p.withoutItem('1');
      expect(p.items.single.id, '3');
    });

    test('a playlist stops at the item cap', () {
      UserPlaylist p = const UserPlaylist(id: 'a', name: 'Big');
      for (var i = 0; i < kMaxPlaylistItems + 20; i++) {
        p = p.withItem(catalog('$i', 'c$i'));
      }
      expect(p.items, hasLength(kMaxPlaylistItems));
    });

    test('JSON round trip and unusable entries are dropped', () {
      final UserPlaylist p = UserPlaylist(id: 'a', name: 'Mine', items: <PlaylistItem>[
        catalog('1', 'urdu-001'),
        PlaylistItem(
            id: '2', title: 'L', link: StreamLink.parse('https://youtu.be/$yt')),
      ]);
      final UserPlaylist? back = UserPlaylist.fromJson(
          jsonDecode(jsonEncode(p.toJson())) as Object?);
      expect(back!.items, hasLength(2));
      final UserPlaylist? messy = UserPlaylist.fromJson(<String, dynamic>{
        'id': 'a',
        'name': 'x',
        'items': <dynamic>[
          <String, dynamic>{'id': '1', 'title': 't'}, // no source
          <String, dynamic>{
            'id': '2',
            'title': 't',
            'link': <String, dynamic>{
              'service': 'youtube', 'kind': 'video', 'id': 'bad'
            }
          },
          5,
          <String, dynamic>{'id': '3', 'title': 'ok', 'catalogId': 'c'},
        ],
      });
      expect(messy!.items.single.id, '3');
      expect(UserPlaylist.fromJson(<String, dynamic>{'id': 'a', 'name': ' '}),
          isNull);
    });
  });

  group('storage', () {
    test('corrupt stored value loads as empty', () async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{'ar.player.playlists.v1': '{not json'});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(UserPlaylistRepository.load(prefs), isEmpty);
      SharedPreferences.setMockInitialValues(
          <String, Object>{'ar.player.playlists.v1': '{"a":1}'});
      final SharedPreferences prefs2 = await SharedPreferences.getInstance();
      expect(UserPlaylistRepository.load(prefs2), isEmpty);
    });

    test('create, add, persist, reload', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final UserPlaylistsNotifier n = UserPlaylistsNotifier(prefs);
      expect(await n.create('   '), isNull);
      final String id = (await n.create('Morning'))!;
      expect(
          await n.addCatalogTrack(id,
              catalogId: 'urdu-001', title: 'Maula', artist: 'JJ'),
          isTrue);
      expect(
          await n.addCatalogTrack(id,
              catalogId: 'urdu-001', title: 'Maula', artist: 'JJ'),
          isFalse);
      final UserPlaylistsNotifier again = UserPlaylistsNotifier(prefs);
      expect(again.state.single.name, 'Morning');
      expect(again.state.single.items.single.catalogId, 'urdu-001');
      await again.rename(id, 'Fajr');
      await again.delete(id);
      expect(UserPlaylistsNotifier(prefs).state, isEmpty);
    });
  });

  group('approved sources', () {
    test('parse keeps valid entries and drops the rest', () {
      final Map<String, TrackSources> m = PlayerSourcesPack.parse(jsonEncode(
          <String, dynamic>{
        'version': 1,
        'sources': <String, dynamic>{
          'a': <String, dynamic>{'youtube': yt, 'spotify': 'track/$sp'},
          'b': <String, dynamic>{'youtube': 'not-an-id'},
          'c': <String, dynamic>{'spotify': 'track/$sp'},
          'd': 7,
          'e': <String, dynamic>{'youtube': '$yt/../x'},
        },
      }));
      expect(m.keys.toSet(), <String>{'a', 'c'});
      expect(m['a']!.preferred!.service, StreamService.youtube);
      expect(m['c']!.preferred!.service, StreamService.spotify);
      expect(PlayerSourcesPack.parse('[]'), isEmpty);
    });

    test('the shipped file parses and names real catalogue tracks', () {
      final String raw =
          File('assets/academy/player_sources.json').readAsStringSync();
      final Object? doc = jsonDecode(raw);
      final Map<String, dynamic> sources =
          (doc! as Map<String, dynamic>)['sources'] as Map<String, dynamic>;
      final Map<String, TrackSources> parsed = PlayerSourcesPack.parse(raw);
      expect(parsed.length, sources.length,
          reason: 'every entry must be a valid ID');
      final Set<String> ids = <String>{
        for (final dynamic t in (jsonDecode(
                File('assets/academy/player_catalog.json').readAsStringSync())
            as Map<String, dynamic>)['tracks'] as List<dynamic>)
          (t as Map<String, dynamic>)['id'] as String,
      };
      for (final String k in sources.keys) {
        expect(ids.contains(k), isTrue, reason: 'unknown track id $k');
      }
    });
  });

  group('what an item plays from', () {
    final Map<String, TrackSources> sources = PlayerSourcesPack.parse(
        jsonEncode(<String, dynamic>{
      'sources': <String, dynamic>{
        'approved': <String, dynamic>{'youtube': yt},
      },
    }));

    test('catalogue item: approved source only', () {
      final StreamEntry? e = entryForItem(
          const PlaylistItem(id: '1', title: 'A', catalogId: 'approved'),
          sources,
          personalHidden: false);
      expect(e!.link.id, yt);
      expect(e.personal, isFalse);
      expect(
          entryForItem(
              const PlaylistItem(id: '2', title: 'B', catalogId: 'unknown'),
              sources,
              personalHidden: false),
          isNull);
    });

    test('pasted link: personal, and hidden by the household filter', () {
      final PlaylistItem item = PlaylistItem(
          id: '3', title: 'L', link: StreamLink.parse('https://youtu.be/$yt'));
      expect(entryForItem(item, sources, personalHidden: false)!.personal,
          isTrue);
      expect(entryForItem(item, sources, personalHidden: true), isNull);
    });

    test('queue steps and stops', () {
      final StreamQueueNotifier q = StreamQueueNotifier();
      final StreamLink l = StreamLink.parse('https://youtu.be/$yt')!;
      StreamEntry e(String t) => StreamEntry(title: t, artist: '', link: l);
      q.play(<StreamEntry>[e('a'), e('b')], 0);
      expect(q.state.current!.title, 'a');
      q.previous();
      expect(q.state.index, 0);
      q.next();
      q.next();
      expect(q.state.current!.title, 'b');
      q.play(<StreamEntry>[e('x')], 99);
      expect(q.state.current!.title, 'x');
      q.stop();
      expect(q.state.isEmpty, isTrue);
    });
  });

  testWidgets('My Playlists shows its empty state, then a new playlist',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp(
          theme: AppTheme.dark(), home: const PlaylistsScreen()),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('My Playlists'), findsOneWidget);
    expect(find.text('No playlists yet'), findsOneWidget);
    expect(find.text('New playlist'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
