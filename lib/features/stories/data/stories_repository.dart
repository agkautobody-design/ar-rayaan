import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/story.dart';
import '../../../app/core/content/content_sync.dart';

/// Bundled, fully offline story library. Collections arrive as JSON
/// packs under assets/stories/ so content ships with the app.
class StoriesRepository {
  static const _packs = [
    'prophets',
    'women',
    'seerah',
    'companions',
    'ghayb',
    'signs',
    'tales',
    'khutbahs',
    'modernhadith',
    'dailyduas',
    'newmuslim',
  ];

  Future<List<Story>> loadAll() async {
    final stories = <Story>[];
    for (final pack in _packs) {
      List<dynamic>? list;
      try {
        list = json.decode(await ContentSync.load('stories/\$pack.json'))
            as List<dynamic>;
      } catch (_) {}
      if (list == null) {
        // The synced copy failed (a poisoned cache, a filtered network) —
        // the bundled pack is always the floor. A shelf may never die.
        try {
          list = json.decode(
                  await rootBundle.loadString('assets/stories/\$pack.json'))
              as List<dynamic>;
        } catch (_) {}
      }
      if (list != null) {
        try {
          stories.addAll(
            list.map((e) => Story.fromJson(e as Map<String, dynamic>)),
          );
        } catch (_) {
          // One malformed entry must not sink the whole shelf:
          // load every healthy story in the pack.
          for (final e in list) {
            try {
              stories.add(Story.fromJson(e as Map<String, dynamic>));
            } catch (_) {}
          }
        }
      }
    }
    return stories;
  }

  List<Story> byCollection(List<Story> all, String collection) =>
      all.where((s) => s.collection == collection).toList();
}

final storiesRepositoryProvider = Provider<StoriesRepository>((ref) {
  return StoriesRepository();
});

final storiesProvider = FutureProvider<List<Story>>((ref) {
  return ref.watch(storiesRepositoryProvider).loadAll();
});
