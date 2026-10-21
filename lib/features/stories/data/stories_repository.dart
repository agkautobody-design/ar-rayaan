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

  /// Loads every pack concurrently (one slow or offline pack no longer
  /// delays the next ten) and returns the stories in pack order.
  Future<List<Story>> loadAll() async {
    final List<List<Story>> perPack =
        await Future.wait(_packs.map(_loadPack));
    return <Story>[for (final List<Story> p in perPack) ...p];
  }

  Future<List<Story>> _loadPack(String pack) async {
    final stories = <Story>[];
    List<dynamic>? list;
    try {
      list = json.decode(await ContentSync.load('stories/$pack.json'))
          as List<dynamic>;
    } catch (_) {}
    if (list == null) {
      // The synced copy failed (a poisoned cache, a filtered network) —
      // the bundled pack is always the floor. A shelf may never die.
      try {
        list = json.decode(
                await rootBundle.loadString('assets/stories/$pack.json'))
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
        stories.clear();
        for (final e in list) {
          try {
            stories.add(Story.fromJson(e as Map<String, dynamic>));
          } catch (_) {}
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
