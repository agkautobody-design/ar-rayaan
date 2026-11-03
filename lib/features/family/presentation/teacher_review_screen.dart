import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../../auth/application/auth_providers.dart';
import '../application/teacher_providers.dart';
import '../domain/teacher_models.dart';

class TeacherReviewScreen extends ConsumerWidget {
  const TeacherReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final submissionsAsync = user != null
        ? ref.watch(pendingSubmissionsProvider(user.uid))
        : const AsyncData<List<Submission>>([]);

    return Scaffold(
      backgroundColor: AppColors.night,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Review Work', style: AppText.displayMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back',
          onPressed: () => context.pop(),
        ),
      ),
      body: submissionsAsync.when(
        data: (submissions) {
          if (submissions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_turned_in, size: 64, color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    const Text(
                      'No pending submissions.\nWhen your students complete '
                      'lessons or tests, they will appear here for review.',
                      style: AppText.body,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: submissions.length,
            itemBuilder: (ctx, i) => _SubmissionCard(submission: submissions[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, _) => Center(child: Text('Error: $e', style: AppText.body.copyWith(color: Colors.red))),
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.submission});
  final Submission submission;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showReviewDialog(context, submission),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                    child: Text(
                      submission.childName.isNotEmpty ? submission.childName[0] : '?',
                      style: AppText.label.copyWith(color: AppColors.gold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(submission.childName, style: AppText.label.copyWith(color: Colors.white)),
                        Text(submission.lessonTitle, style: AppText.caption.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('PENDING', style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (submission.timeSpentMinutes != null)
                Text(
                  'Time spent: ${submission.timeSpentMinutes} min',
                  style: AppText.caption.copyWith(color: Colors.white54),
                ),
              Text(
                'Submitted: ${_formatDate(submission.submittedAt)}',
                style: AppText.caption.copyWith(color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReviewDialog(BuildContext context, Submission submission) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.night,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ReviewSheet(submission: submission),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} at ${dt.hour % 12 == 0 ? 12 : dt.hour % 12}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({required this.submission});
  final Submission submission;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  final _score = TextEditingController();
  final _feedback = TextEditingController();
  final _strengths = TextEditingController();
  final _improvements = TextEditingController();

  @override
  void dispose() {
    _score.dispose();
    _feedback.dispose();
    _strengths.dispose();
    _improvements.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final review = TeacherReview(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      submissionId: widget.submission.id,
      childUid: widget.submission.childUid,
      teacherUid: user.uid,
      teacherName: user.name ?? 'Teacher',
      reviewedAt: DateTime.now(),
      score: int.tryParse(_score.text),
      feedback: _feedback.text.trim().isEmpty ? null : _feedback.text.trim(),
      strengths: _strengths.text.trim().isEmpty ? null : _strengths.text.trim().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      improvements: _improvements.text.trim().isEmpty ? null : _improvements.text.trim().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
    );

    await ref.read(teacherRepositoryProvider).submitReview(review);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Review: ${widget.submission.lessonTitle}', style: AppText.titleMedium),
          const SizedBox(height: 4),
          Text('Student: ${widget.submission.childName}', style: AppText.caption.copyWith(color: Colors.white70)),
          const SizedBox(height: 24),
          TextField(
            controller: _score,
            style: AppText.body.copyWith(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Score (0-100)',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _feedback,
            style: AppText.body.copyWith(color: Colors.white),
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Feedback',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _strengths,
            style: AppText.body.copyWith(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Strengths (comma separated)',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _improvements,
            style: AppText.body.copyWith(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Areas to Improve (comma separated)',
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
            ),
          ),
          const SizedBox(height: 32),
          GoldButton(
            onPressed: _submit,
            label: 'Submit Review',
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
