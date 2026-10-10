import 'dart:convert';

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
      try {
        final raw = await ContentSync.load('stories/\$pack.json');
        final list = json.decode(raw) as List<dynamic>;
        stories.addAll(
          list.map((e) => Story.fromJson(e as Map<String, dynamic>)),
        );
      } catch (_) {
        // Pack not shipped yet — library grows pack by pack.
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
