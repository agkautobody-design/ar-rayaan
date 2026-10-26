import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/content/content_sync.dart';
import '../data/local_knowledge.dart';

/// The local index over the Huda guides and the Q&A bank, built once from
/// the same packs the Huda and Q&A screens show. Null when a pack cannot be
/// read: Hādi then simply answers as before.
final FutureProvider<LocalKnowledge?> localKnowledgeProvider =
    FutureProvider<LocalKnowledge?>((ref) async {
  try {
    final List<dynamic> guides = await ContentSync.loadParsed<List<dynamic>>(
      'guides/guides.json',
      (String raw) => json.decode(raw) as List<dynamic>,
    );
    final List<dynamic> qa = await ContentSync.loadParsed<List<dynamic>>(
      'qa/qa_bank.json',
      (String raw) =>
          (json.decode(raw) as Map<String, dynamic>)['questions']
              as List<dynamic>,
    );
    final List<dynamic> stories = <dynamic>[];
    for (final String pack in kHadiKnowledgeStoryPacks) {
      try {
        stories.addAll(
          await ContentSync.loadParsed<List<dynamic>>(
            'stories/$pack.json',
            (String raw) => json.decode(raw) as List<dynamic>,
          ),
        );
      } catch (_) {
        // A pack that cannot be read is left out; the rest still work.
      }
    }
    return LocalKnowledge.fromJson(guides: guides, qa: qa, stories: stories);
  } catch (_) {
    return null;
  }
});
