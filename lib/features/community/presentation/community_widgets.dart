import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/backend/backend_exception.dart';
import '../../../app/core/backend/community_providers.dart';
import '../../../app/core/backend/models.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/community_state.dart';
import 'join_panel.dart';

/// The frame every community screen shares: the app's dark pattern
/// background, the usual header, and a body that never runs under it.
class CommunityPage extends StatelessWidget {
  const CommunityPage({
    required this.title,
    required this.child,
    super.key,
    this.actions = const <HeaderAction>[],
  });

  final String title;
  final Widget child;
  final List<HeaderAction> actions;

  @override
  Widget build(BuildContext context) {
    return ScenicScaffold.pattern(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            ScreenHeader(title: title, showSettings: false, actions: actions),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// Wraps a community screen so it is only ever shown when it can work:
/// the build has the backend, the person has signed in, and has a profile.
/// Anything else is replaced by a plain explanation or the sign-in panel.
class CommunityGate extends ConsumerWidget {
  const CommunityGate({
    required this.title,
    required this.builder,
    super.key,
    this.actions = const <HeaderAction>[],
    this.needsProfile = true,
  });

  final String title;
  final List<HeaderAction> actions;

  /// Forums, meet-ups and friends need a profile. Notices and appeals do not.
  final bool needsProfile;
  final Widget Function(BuildContext context, MeResponse me) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool enabled = ref.watch(communityEnabledProvider);
    if (!enabled) {
      return CommunityPage(
        title: title,
        child: const MessageView(
          icon: Icons.groups_2_outlined,
          title: 'Not available yet',
          message:
              'Forums, meet-ups and friends are not switched on in this '
              'version of the app.',
        ),
      );
    }
    final AsyncValue<MeResponse?> me = ref.watch(communityMeProvider);
    return CommunityPage(
      title: title,
      actions: actions,
      child: AsyncBody<MeResponse?>(
        value: me,
        onRetry: () => ref.invalidate(communityMeProvider),
        builder: (BuildContext c, MeResponse? m) {
          if (m == null) {
            return JoinPanel(onDone: () => ref.invalidate(communityMeProvider));
          }
          if (needsProfile && m.profile == null) {
            return ProfilePanel(
              onDone: () => ref.invalidate(communityMeProvider),
            );
          }
          return builder(c, m);
        },
      ),
    );
  }
}

/// Loading, error (with retry) or data.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    required this.value,
    required this.builder,
    required this.onRetry,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (T d) => builder(context, d),
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
      error: (Object e, StackTrace _) => MessageView(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load this',
        message: friendlyError(e),
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
    );
  }
}

/// A calm full-area message with an optional single action.
class MessageView extends StatelessWidget {
  const MessageView({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 40, color: AppColors.gold),
            const SizedBox(height: 14),
            Text(title, style: AppText.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: AppText.bodyMuted, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 20),
              GoldButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small pill: "Community opinion", "Scholar answer", "Verified organiser".
class LabelChip extends StatelessWidget {
  const LabelChip(this.text, {super.key, this.strong = false, this.icon});

  final String text;

  /// Gold fill: used for things a person checked (scholar, verified).
  final bool strong;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final Color fg = strong ? AppColors.night : AppColors.sand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: strong ? AppColors.gold : AppColors.glassFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: strong ? 1 : 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: AppText.caption.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The label a forum post always carries.
LabelChip labelFor(ForumLabel l, {String? org}) {
  switch (l) {
    case ForumLabel.communityOpinion:
      return const LabelChip(
        'Community opinion',
        icon: Icons.forum_outlined,
      );
    case ForumLabel.scholarAnswer:
      return LabelChip(
        org == null || org.isEmpty
            ? 'Scholar answer'
            : 'Scholar answer · $org',
        strong: true,
        icon: Icons.verified_outlined,
      );
    case ForumLabel.question:
      return const LabelChip('Question', icon: Icons.help_outline);
    case ForumLabel.announcement:
      return const LabelChip(
        'Announcement',
        strong: true,
        icon: Icons.campaign_outlined,
      );
  }
}

/// The reminder under every forum screen. Not a warning: a boundary.
class OpinionNotice extends StatelessWidget {
  const OpinionNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.info_outline, size: 18, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'What members write is their own opinion. It is not a ruling '
              'and not religious guidance. For a ruling, use Ask a scholar.',
              style: AppText.bodyMuted.copyWith(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Runs [action], shows [done] (if given) on success and the server's
/// message on failure. Returns null on failure.
Future<T?> runAction<T>(
  BuildContext context,
  Future<T> Function() action, {
  String? done,
}) async {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  try {
    final T r = await action();
    if (done != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(done)));
    }
    return r;
  } on BackendException catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.message)));
    return null;
  }
}

const List<String> _days = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];
const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// `Sat 7 Nov, 18:30` in the person's own time zone.
String formatWhen(DateTime t) {
  final DateTime l = t.toLocal();
  return '${_days[l.weekday - 1]} ${l.day} ${_months[l.month - 1]}, '
      '${_two(l.hour)}:${_two(l.minute)}';
}

/// `just now`, `5 min ago`, `3 h ago`, `2 days ago`, otherwise a date.
String timeAgo(DateTime t, {DateTime? now}) {
  final Duration d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  if (d.inDays < 7) return '${d.inDays} days ago';
  final DateTime l = t.toLocal();
  return '${l.day} ${_months[l.month - 1]} ${l.year}';
}

String audienceLabel(MeetupAudience a) {
  switch (a) {
    case MeetupAudience.open:
      return 'Everyone (adults)';
    case MeetupAudience.brothers:
      return 'Brothers only';
    case MeetupAudience.sisters:
      return 'Sisters only';
    case MeetupAudience.families:
      return 'Families';
  }
}

String venueLabel(MeetupVenueKind k) {
  switch (k) {
    case MeetupVenueKind.mosque:
      return 'Mosque';
    case MeetupVenueKind.communityCentre:
      return 'Community centre';
    case MeetupVenueKind.library:
      return 'Library';
    case MeetupVenueKind.cafe:
      return 'Halal cafe';
    case MeetupVenueKind.park:
      return 'Park';
    case MeetupVenueKind.schoolHall:
      return 'School hall';
    case MeetupVenueKind.otherPublic:
      return 'Other public place';
  }
}

/// Shows the report sheet. After a report it offers to hide the item or block
/// its author, because a person who reports usually wants it gone as well.
Future<void> showReportSheet(
  BuildContext context, {
  required CommunityTarget target,
  required String targetId,
  String? authorProfileId,
  String? authorName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.navy,
    builder: (BuildContext c) => _ReportSheet(
      target: target,
      targetId: targetId,
      authorProfileId: authorProfileId,
      authorName: authorName,
    ),
  );
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({
    required this.target,
    required this.targetId,
    this.authorProfileId,
    this.authorName,
  });

  final CommunityTarget target;
  final String targetId;
  final String? authorProfileId;
  final String? authorName;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  ReportReason? _reason;
  final TextEditingController _details = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final ReportReason? r = _reason;
    if (r == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(communityApiProvider)
          .report(
            target: widget.target,
            targetId: widget.targetId,
            reason: r,
            details: _details.text,
          );
      if (mounted) setState(() => _sent = true);
    } on BackendException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _hide() async {
    final NavigatorState nav = Navigator.of(context);
    final BuildContext outer = context;
    if (widget.target != CommunityTarget.profile) {
      await runAction<void>(
        outer,
        () => ref
            .read(communityApiProvider)
            .hideForMe(widget.target, widget.targetId),
        done: 'Hidden. You will not see it again.',
      );
    }
    nav.pop();
  }

  Future<void> _block() async {
    final String? id = widget.authorProfileId;
    final NavigatorState nav = Navigator.of(context);
    if (id != null) {
      await runAction<void>(
        context,
        () => ref.read(communityApiProvider).block(id),
        done: 'Blocked. You will not see each other.',
      );
    }
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final double inset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + inset),
        child: SingleChildScrollView(
          child: _sent ? _thanks(context) : _form(context),
        ),
      ),
    );
  }

  Widget _thanks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Thank you', style: AppText.titleMedium),
        const SizedBox(height: 8),
        Text(
          'A person will look at this. They will not tell anyone who '
          'reported it.',
          style: AppText.bodyMuted,
        ),
        const SizedBox(height: 16),
        if (widget.target != CommunityTarget.profile)
          GoldButton(label: 'Hide this for me', onPressed: _hide),
        if (widget.authorProfileId != null) ...<Widget>[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _block,
            child: Text(
              widget.authorName == null || widget.authorName!.isEmpty
                  ? 'Block this person'
                  : 'Block ${widget.authorName}',
            ),
          ),
        ],
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _form(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Report', style: AppText.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Choose what is wrong. If a child may be at risk, say so: it is '
          'hidden straight away.',
          style: AppText.bodyMuted.copyWith(fontSize: 12.5),
        ),
        const SizedBox(height: 8),
        RadioGroup<ReportReason>(
          groupValue: _reason,
          onChanged: (ReportReason? v) => setState(() => _reason = v),
          child: Column(
            children: <Widget>[
              for (final ReportReason r in ReportReason.values)
                RadioListTile<ReportReason>(
                  value: r,
                  title: Text(r.label, style: AppText.body),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        Semantics(label: 'Anything else we should know (optional)', child: TextField(
          controller: _details,
          maxLength: 1000,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Anything else we should know (optional)',
          ),
        )),
        if (_error != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppColors.destructive)),
        ],
        const SizedBox(height: 12),
        GoldButton(
          label: _busy ? 'Sending...' : 'Send report',
          onPressed: _reason == null || _busy ? null : _send,
        ),
      ],
    );
  }
}
