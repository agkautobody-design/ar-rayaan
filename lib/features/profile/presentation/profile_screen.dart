import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/icon_tile.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../application/profile_providers.dart';
import '../domain/user_profile.dart';
import '../../haramain/application/journey_stamp_provider.dart';
import '../../haramain/domain/journey_stamp.dart';

/// Screen 10 · Profile — user card (live session data) + profile shortcuts.
/// Visuals are LOCKED; only the card's text is data-driven.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const List<(IconData, String, String?)> _items = [
    (Icons.account_circle_outlined, 'My Profile', null),
    (Icons.trending_up, 'My Journey', AppRoutes.journey),
    (Icons.bookmark_outline, 'Bookmarks', null),
    (Icons.sticky_note_2_outlined, 'Notes', null),
    (Icons.settings_outlined, 'Settings', AppRoutes.settings),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UserProfile?> profileState = ref.watch(
      userProfileProvider,
    );
    final UserProfile? profile = profileState.valueOrNull;
    final bool signedIn = profile != null;
    final String name = signedIn ? profile.displayName : 'Guest';
    final String subtitle = signedIn
        ? 'View your profile'
        : 'Sign in to save your journey';

    return ScenicScaffold.pattern(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ScreenHeader(title: ''),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  GlassCard(
                    onTap: signedIn ? () {} : () => context.go(AppRoutes.login),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.4),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x40D4AF37),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/avatar.png',
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: AppText.titleMedium.copyWith(
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                subtitle,
                                style: AppText.bodyMuted.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Column(
                      children: [
                        for (int i = 0; i < _items.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              color: AppColors.gold.withValues(alpha: 0.1),
                              indent: 64,
                            ),
                          Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              onTap: _items[i].$3 == null
                                  ? null
                                  : () => context.go(_items[i].$3!),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    IconTile(icon: _items[i].$1),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _items[i].$2,
                                        style: AppText.body.copyWith(
                                          color: AppColors.sand.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: AppColors.gold.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const _JourneyStampsSection(),
                  const SizedBox(height: 28),
                  Text(
                    'INVITE. NEVER FORCE.',
                    style: AppText.eyebrow.copyWith(
                      color: AppColors.gold.withValues(alpha: 0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyStampsSection extends ConsumerWidget {
  const _JourneyStampsSection();

  static const List<String> _months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _fmt(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<JourneyStamp> stamps = ref.watch(journeyStampsProvider);
    return Column(
      children: <Widget>[
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.luggage_outlined, color: AppColors.gold),
                  const SizedBox(width: 12),
                  Text('Journeys', style: AppText.titleMedium),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Your own record of Umrah and Hajj — self-recorded, '
                'on this device only. No counts, no comparisons.',
                style: AppText.bodyMuted.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (stamps.isEmpty)
                Text('No journeys recorded yet.', style: AppText.bodyMuted)
              else
                ...stamps.map(
                  (JourneyStamp s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          s.type == JourneyType.umrah
                              ? Icons.mosque_outlined
                              : Icons.star_outline,
                          color: AppColors.gold,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${s.type == JourneyType.umrah ? 'Umrah' : 'Hajj'} — ${_fmt(s.completedAt)}',
                            style: AppText.body,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('self-recorded',
                              style: AppText.bodyMuted.copyWith(fontSize: 11)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.gold, size: 20),
                          onPressed: () => ref
                              .read(journeyStampsProvider.notifier)
                              .remove(s.id),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const _RecordJourneyDialog(),
                ),
                icon: const Icon(Icons.add, color: AppColors.gold),
                label: Text('Record journey',
                    style: AppText.body.copyWith(color: AppColors.gold)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecordJourneyDialog extends ConsumerStatefulWidget {
  const _RecordJourneyDialog();

  @override
  ConsumerState<_RecordJourneyDialog> createState() =>
      _RecordJourneyDialogState();
}

class _RecordJourneyDialogState extends ConsumerState<_RecordJourneyDialog> {
  JourneyType _type = JourneyType.umrah;
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.navy,
      title: Text('Record a journey', style: AppText.titleMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: 8,
            children: JourneyType.values
                .map(
                  (JourneyType t) => ChoiceChip(
                    label: Text(t == JourneyType.umrah ? 'Umrah' : 'Hajj'),
                    selected: _type == t,
                    selectedColor: AppColors.gold,
                    onSelected: (_) => setState(() => _type = t),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _date = picked);
            },
            icon: const Icon(Icons.calendar_month_outlined,
                color: AppColors.gold),
            label: Text(
              'Completed: ${_JourneyStampsSection._fmt(_date)}',
              style: AppText.body.copyWith(color: AppColors.sand),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.gold),
          onPressed: () async {
            await ref.read(journeyStampsProvider.notifier).add(
                  type: _type,
                  completedAt: _date,
                );
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text('Save',
              style: AppText.titleMedium.copyWith(color: AppColors.navy)),
        ),
      ],
    );
  }
}
