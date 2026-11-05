import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/feedback_service.dart';

/// Null when this build has no Firebase project (local mode): the feedback
/// screen then says so instead of failing.
final Provider<FeedbackService?> feedbackServiceProvider =
    Provider<FeedbackService?>((ref) {
  if (Firebase.apps.isEmpty) return null;
  return FeedbackService();
});

final Provider<bool> feedbackEnabledProvider =
    Provider<bool>((ref) => ref.watch(feedbackServiceProvider) != null);
