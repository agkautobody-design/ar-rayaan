import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../academy/data/academy_progress_repository.dart';

class WasiaMessage {
  const WasiaMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.sentAt,
    this.childId,
  });

  final String id;
  final String sender;
  final String text;
  final DateTime sentAt;
  final String? childId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender': sender,
    'text': text,
    'sentAt': sentAt.toIso8601String(),
    if (childId != null) 'childId': childId,
  };

  factory WasiaMessage.fromJson(Map<String, dynamic> j) => WasiaMessage(
    id: j['id'] as String,
    sender: j['sender'] as String,
    text: j['text'] as String,
    sentAt: DateTime.parse(j['sentAt'] as String),
    childId: j['childId'] as String?,
  );
}

class WasiaParentBridge {
  WasiaParentBridge({
    required this.firestore,
    required this.progressRepo,
  });

  final FirebaseFirestore firestore;
  final AcademyProgressRepository progressRepo;

  CollectionReference<Map<String, dynamic>> _chat(String parentUid) =>
      firestore.collection('wasia_parent_chats').doc(parentUid).collection('messages');

  Stream<List<WasiaMessage>> watchChat(String parentUid) {
    return _chat(parentUid)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WasiaMessage.fromJson(d.data()))
            .toList());
  }

  Future<void> sendParentMessage(String parentUid, String text, {String? childId}) async {
    final msgId = _chat(parentUid).doc().id;
    final parentMsg = WasiaMessage(
      id: msgId,
      sender: 'parent',
      text: text,
      sentAt: DateTime.now(),
      childId: childId,
    );
    await _chat(parentUid).doc(msgId).set(parentMsg.toJson());

    final wasiaResponse = await _generateWasiaResponse(parentUid, childId, text);
    final wasiaMsgId = _chat(parentUid).doc().id;
    await _chat(parentUid).doc(wasiaMsgId).set(WasiaMessage(
      id: wasiaMsgId,
      sender: 'wasia',
      text: wasiaResponse,
      sentAt: DateTime.now(),
      childId: childId,
    ).toJson());
  }

  Future<String> _generateWasiaResponse(String parentUid, String? childId, String parentText) async {
    final lower = parentText.toLowerCase();

    if (lower.contains('hello') || lower.contains('hi') || lower.contains('salam') || lower.contains('how are')) {
      return "Wa alaykum as-salam! I'm Wasia, your child's learning companion. How can I help you today? You can ask about their progress, test scores, or what they're studying.";
    }

    if (lower.contains('progress') || lower.contains('doing') || lower.contains('how is') || lower.contains('how are')) {
      if (childId == null) {
        return "I'd be happy to share progress updates. Please select a child from your family list, or tell me which child you're asking about.";
      }
      final latest = await progressRepo.getLatestProgress(childId);
      if (latest == null) {
        return "Your child hasn't completed any lessons yet. Encourage them to start their first lesson in the Academy — I'll be here to guide them every step of the way.";
      }
      final scoreText = latest.score != null ? " with a score of ${latest.score}/100" : "";
      return "Great news! Your child recently completed '${latest.lessonTitle}'$scoreText. They're making steady progress. Would you like to see their full learning history or discuss any specific area?";
    }

    if (lower.contains('test') || lower.contains('score') || lower.contains('exam') || lower.contains('grade')) {
      if (childId == null) {
        return "Please let me know which child you're asking about, and I'll pull up their latest test results.";
      }
      final latest = await progressRepo.getLatestProgress(childId);
      if (latest?.score == null) {
        return "Your child is working through lessons at their own pace. No graded assessments have been completed yet, but I'll notify you when they finish their first test.";
      }
      return "Your child's most recent assessment scored ${latest!.score}/100 on '${latest.lessonTitle}'. This is solid progress. Is there a specific topic you'd like me to focus on with them?";
    }

    if (lower.contains('learning') || lower.contains('studying') || lower.contains('lesson') || lower.contains('topic')) {
      if (childId == null) {
        return "I can tell you exactly what they're studying. Just let me know which child you're asking about.";
      }
      final latest = await progressRepo.getLatestProgress(childId);
      if (latest == null) {
        return "They're just getting started! The Academy has courses on Quran, Hadith, Dua, Arabic, and more. Once they begin, I'll share detailed updates with you.";
      }
      return "Recently, they've been working on '${latest.lessonTitle}'. The Academy covers Quran, Hadith, Arabic language, Dua, and Islamic history. Would you like me to recommend the next lesson for them?";
    }

    if (lower.contains('encourage') || lower.contains('motivate') || lower.contains('help') || lower.contains('struggling')) {
      return "Every child learns at their own pace. Here are a few things you can do: 1) Ask them to teach YOU what they learned today — teaching reinforces memory. 2) Set a consistent daily time for Academy lessons, even if it's just 10 minutes. 3) Celebrate small wins — every completed lesson is progress. Would you like specific tips for a particular subject?";
    }

    return "I understand. I'm here to help you stay connected with your child's learning journey. You can ask about their progress, test scores, what they're studying, or how to support them at home. What would you like to know?";
  }
}

final Provider<WasiaParentBridge> wasiaParentBridgeProvider = Provider<WasiaParentBridge>((ref) {
  return WasiaParentBridge(
    firestore: FirebaseFirestore.instance,
    progressRepo: ref.watch(academyProgressRepositoryProvider),
  );
});

final StreamProviderFamily<List<WasiaMessage>, String> wasiaChatProvider =
    StreamProvider.family<List<WasiaMessage>, String>((ref, parentUid) {
  return ref.watch(wasiaParentBridgeProvider).watchChat(parentUid);
});
