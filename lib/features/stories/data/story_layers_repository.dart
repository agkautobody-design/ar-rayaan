import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/content/content_sync.dart';
import '../domain/story_layers.dart';

/// Loads the layers beneath a story: `assets/stories/layers/<subject>.json`
/// (Qur'an references, hadith, scholarly accounts, disagreements) and
/// `assets/stories/earlier/<subject>.json` (earlier accounts), found through
/// `assets/stories/layers/index.json`.
///
/// Nothing here may break a story: any missing or malformed file simply
/// means "no layers" and the reader shows the story as before.
class StoryLayersRepository {
  Map<String, String>? _storyToSubject;

  /// Subject ids that have an earlier-accounts file.
  Set<String> _withEarlier = <String>{};

  /// Reads the index once. Maps every story id to its subject id.
  Future<Map<String, String>> _index() async {
    final Map<String, String>? cached = _storyToSubject;
    if (cached != null) return cached;
    final Map<String, String> out = <String, String>{};
    final Set<String> earlier = <String>{};
    try {
      final Map<String, dynamic> j = json.decode(
        await ContentSync.load('stories/layers/index.json'),
      ) as Map<String, dynamic>;
      for (final dynamic raw in (j['subjects'] as List<dynamic>)) {
        final Map<String, dynamic> s = raw as Map<String, dynamic>;
        final String id = s['id'] as String;
        for (final dynamic st in (s['stories'] as List<dynamic>)) {
          out[st as String] = id;
        }
        if (s['earlier'] == true) earlier.add(id);
      }
    } catch (_) {
      // No index: no layers.
    }
    _withEarlier = earlier;
    _storyToSubject = out;
    return out;
  }

  /// Subject id for a story id, or null when the story has no layers.
  Future<String?> subjectFor(String storyId) async =>
      (await _index())[storyId];

  /// The layers for [storyId], or null.
  Future<StoryLayers?> loadFor(String storyId) async {
    final String? subject = await subjectFor(storyId);
    if (subject == null) return null;
    return loadSubject(subject);
  }

  Future<StoryLayers?> loadSubject(String subject) async {
    try {
      final Map<String, dynamic> layers = json.decode(
        await ContentSync.load('stories/layers/$subject.json'),
      ) as Map<String, dynamic>;
      Map<String, dynamic>? earlier;
      if (_withEarlier.contains(subject)) {
        try {
          earlier = json.decode(
            await ContentSync.load('stories/earlier/$subject.json'),
          ) as Map<String, dynamic>;
        } catch (_) {
          earlier = null;
        }
      }
      final StoryLayers parsed = StoryLayers.fromJson(layers, earlier);
      return parsed.isEmpty ? null : parsed;
    } catch (_) {
      return null;
    }
  }
}

final Provider<StoryLayersRepository> storyLayersRepositoryProvider =
    Provider<StoryLayersRepository>((ref) => StoryLayersRepository());

/// Layers for a story id (null when there are none).
final FutureProviderFamily<StoryLayers?, String> storyLayersProvider =
    FutureProvider.family<StoryLayers?, String>((ref, String storyId) {
  return ref.watch(storyLayersRepositoryProvider).loadFor(storyId);
});
