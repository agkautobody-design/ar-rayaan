import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/core/backend/backend_exception.dart';
import '../../../app/core/backend/community_providers.dart';
import '../../../app/core/backend/models.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../application/community_state.dart';
import 'community_actions.dart';
import 'community_widgets.dart';

/// Upcoming meet-ups. Only public venues; the organiser chooses who each one
/// is for. Nobody can message anybody: you sign up, you turn up.
class MeetupsScreen extends ConsumerStatefulWidget {
  const MeetupsScreen({super.key});

  @override
  ConsumerState<MeetupsScreen> createState() => _MeetupsScreenState();
}

class _MeetupsScreenState extends ConsumerState<MeetupsScreen> {
  final TextEditingController _city = TextEditingController();
  String _cityFilter = '';
  MeetupAudience? _audience;
  bool _mine = false;

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommunityGate(
      title: 'Meet-ups',
      builder: (BuildContext c, MeResponse me) {
        final MeetupFilter filter = (city: _cityFilter, audience: _audience);
        final AsyncValue<List<Meetup>> list = _mine
            ? ref.watch(myMeetupsProvider)
            : ref
                  .watch(meetupsProvider(filter))
                  .whenData((MeetupList l) => l.meetups);
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      ChoiceChip(
                        label: const Text('Upcoming'),
                        selected: !_mine,
                        onSelected: (bool _) => setState(() => _mine = false),
                      ),
                      ChoiceChip(
                        label: const Text('Mine'),
                        selected: _mine,
                        onSelected: (bool _) => setState(() => _mine = true),
                      ),
                    ],
                  ),
                  if (!_mine) ...<Widget>[
                    TextField(
                      controller: _city,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (String v) =>
                          setState(() => _cityFilter = v.trim()),
                      decoration: InputDecoration(
                        hintText: 'City (optional)',
                        suffixIcon: IconButton(
                          tooltip: 'Search this city',
                          icon: const Icon(Icons.search),
                          onPressed: () =>
                              setState(() => _cityFilter = _city.text.trim()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: <Widget>[
                        FilterChip(
                          label: const Text('All'),
                          selected: _audience == null,
                          onSelected: (bool _) =>
                              setState(() => _audience = null),
                        ),
                        for (final MeetupAudience a in MeetupAudience.values)
                          FilterChip(
                            label: Text(audienceLabel(a)),
                            selected: _audience == a,
                            onSelected: (bool _) =>
                                setState(() => _audience = a),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: AsyncBody<List<Meetup>>(
                value: list,
                onRetry: () {
                  ref.invalidate(myMeetupsProvider);
                  ref.invalidate(meetupsProvider(filter));
                },
                builder: (BuildContext c, List<Meetup> items) {
                  if (items.isEmpty) {
                    return MessageView(
                      icon: Icons.event_busy_outlined,
                      title: _mine ? 'No meet-ups yet' : 'No meet-ups found',
                      message: _mine
                          ? 'Meet-ups you organise or sign up for appear here.'
                          : 'Try another city, or organise one yourself.',
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    children: <Widget>[
                      for (final Meetup m in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _MeetupCard(meetup: m),
                        ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: GoldButton(
                label: 'Organise a meet-up',
                onPressed: () async {
                  if (!await ensureCanWrite(c, ref, me)) return;
                  if (!c.mounted) return;
                  await c.push(AppRoutes.communityMeetupNew);
                  ref.invalidate(myMeetupsProvider);
                  ref.invalidate(meetupsProvider(filter));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MeetupCard extends StatelessWidget {
  const _MeetupCard({required this.meetup});

  final Meetup meetup;

  @override
  Widget build(BuildContext context) {
    final Meetup m = meetup;
    return GlassCard(
      onTap: () => context.open('${AppRoutes.communityMeetup}/${m.id}'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            m.title,
            style: AppText.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatWhen(m.startsAt)} · ${m.venueName}, ${m.city}',
            style: AppText.bodyMuted.copyWith(fontSize: 12.5),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              LabelChip(venueLabel(m.venueKind), icon: Icons.place_outlined),
              LabelChip(audienceLabel(m.audience), icon: Icons.group_outlined),
              if (m.organiser.verified)
                const LabelChip(
                  'Verified organiser',
                  strong: true,
                  icon: Icons.verified_outlined,
                ),
              if (m.cancelled) const LabelChip('Cancelled'),
              if (m.pendingReview)
                const LabelChip('Waiting for a moderator'),
              if (m.myRsvp == 'going')
                const LabelChip('You are going', icon: Icons.check),
              if (m.myRsvp == 'waitlist')
                const LabelChip('On the waiting list'),
              if (m.isFull && m.myRsvp == null) const LabelChip('Full'),
            ],
          ),
        ],
      ),
    );
  }
}

/// One meet-up: where, when, who it is for, and signing up.
class MeetupDetailScreen extends ConsumerStatefulWidget {
  const MeetupDetailScreen({required this.meetupId, super.key});

  final String meetupId;

  @override
  ConsumerState<MeetupDetailScreen> createState() => _MeetupDetailScreenState();
}

class _MeetupDetailScreenState extends ConsumerState<MeetupDetailScreen> {
  bool _busy = false;

  void _refresh() {
    ref.invalidate(meetupProvider(widget.meetupId));
    ref.invalidate(myMeetupsProvider);
    ref.invalidate(meetupRemindersProvider);
  }

  Future<void> _rsvp(MeetupDetail d, MeResponse me) async {
    final Meetup m = d.meetup;
    if (!await ensureCanWrite(context, ref, me)) return;
    if (!mounted) return;
    final List<BackendProfile> kids = m.guardianRsvpForMinors
        ? me.children.where((BackendProfile p) => p.kind.isMinor).toList()
        : <BackendProfile>[];
    final List<String>? children = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext c) => _RsvpDialog(meetup: m, kids: kids),
    );
    if (children == null) return;
    setState(() => _busy = true);
    try {
      final RsvpResult? r = await runAction<RsvpResult>(
        context,
        () async {
          RsvpResult last = await ref
              .read(communityApiProvider)
              .rsvp(m.id);
          for (final String id in children) {
            last = await ref
                .read(communityApiProvider)
                .rsvp(m.id, childProfileId: id);
          }
          return last;
        },
      );
      if (r != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              r.status == 'waitlist'
                  ? 'It is full. You are on the waiting list.'
                  : 'You are signed up. See you there, in shaa Allah.',
            ),
          ),
        );
      }
      _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelRsvp(Meetup m) async {
    setState(() => _busy = true);
    try {
      await runAction<void>(
        context,
        () => ref.read(communityApiProvider).cancelRsvp(m.id),
        done: 'Your sign-up is cancelled.',
      );
      _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelMeetup(Meetup m) async {
    final ({CancelReason reason, bool series})? pick =
        await showDialog<({CancelReason reason, bool series})>(
          context: context,
          builder: (BuildContext c) => _CancelDialog(meetup: m),
        );
    if (pick == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await runAction<void>(
        context,
        () => ref
            .read(communityApiProvider)
            .cancelMeetup(m.id, pick.reason, wholeSeries: pick.series),
        done: 'Cancelled. Everyone who signed up is told.',
      );
      _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MeetupDetail? loaded = ref
        .watch(meetupProvider(widget.meetupId))
        .asData
        ?.value;
    final bool reportable = loaded != null && !loaded.meetup.mine;
    return CommunityGate(
      title: 'Meet-up',
      actions: <HeaderAction>[
        if (reportable)
          HeaderAction(
            icon: Icons.flag_outlined,
            tooltip: 'Report this meet-up',
            onTap: () => showReportSheet(
              context,
              target: CommunityTarget.meetup,
              targetId: widget.meetupId,
              authorProfileId: loaded.meetup.organiser.profileId,
              authorName: loaded.meetup.organiser.displayName,
            ),
          ),
      ],
      builder: (BuildContext c, MeResponse me) {
        return AsyncBody<MeetupDetail>(
          value: ref.watch(meetupProvider(widget.meetupId)),
          onRetry: _refresh,
          builder: (BuildContext c, MeetupDetail d) => _body(c, d, me),
        );
      },
    );
  }

  Widget _body(BuildContext context, MeetupDetail d, MeResponse me) {
    final Meetup m = d.meetup;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: <Widget>[
        Text(m.title, style: AppText.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            LabelChip(audienceLabel(m.audience), icon: Icons.group_outlined),
            LabelChip(venueLabel(m.venueKind), icon: Icons.place_outlined),
            if (m.halalConfirmed && m.venueKind == MeetupVenueKind.cafe)
              const LabelChip('Halal confirmed by the organiser'),
            if (m.recurrence != MeetupRecurrence.none)
              LabelChip('Repeats ${m.recurrence.name}', icon: Icons.repeat),
          ],
        ),
        if (m.cancelled)
          _Banner(
            'This meet-up is cancelled'
            '${m.cancelReason == null ? '.' : ' (${_reasonText(m.cancelReason!)}).'}',
          ),
        if (m.pendingReview)
          const _Banner(
            'A moderator will read this before it is shown to others. '
            'Only you can see it for now.',
          ),
        const SizedBox(height: 12),
        _Fact(Icons.schedule, formatWhen(m.startsAt)),
        _Fact(
          Icons.place_outlined,
          [
            m.venueName,
            if (m.venueAddress != null) m.venueAddress!,
            '${m.city}, ${m.country}',
          ].join('\n'),
        ),
        _Fact(
          Icons.event_seat_outlined,
          m.capacity == null
              ? '${m.goingCount} going'
              : '${m.goingCount} of ${m.capacity} places taken'
                    '${m.waitlistCount > 0 ? ' · ${m.waitlistCount} waiting' : ''}',
        ),
        _Fact(
          Icons.person_outline,
          m.organiser.verified
              ? 'Organised by ${m.organiser.displayName}'
                    '${m.organiser.orgName == null ? '' : ' (${m.organiser.orgName})'}'
                    ' · verified by a person'
              : 'Organised by ${m.organiser.displayName} · not yet verified',
        ),
        _Fact(
          Icons.child_care_outlined,
          m.guardianRsvpForMinors
              ? 'Children may come with a parent or guardian, who signs them '
                    'up. A child’s name is never shown.'
              : 'Adults only.',
        ),
        if (m.accessibilityNotes != null)
          _Fact(Icons.accessible_forward, m.accessibilityNotes!),
        if (m.description.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(m.description, style: AppText.body),
        ],
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Meet-ups are held in public places only. There are no private '
            'messages: if you have a question, ask at the venue.',
            style: AppText.bodyMuted.copyWith(fontSize: 12.5),
          ),
        ),
        const SizedBox(height: 16),
        if (m.mine) ...<Widget>[
          if (d.attendees != null) _Attendees(d.attendees!),
          const SizedBox(height: 12),
          if (!m.cancelled)
            OutlinedButton(
              onPressed: _busy ? null : () => _cancelMeetup(m),
              child: const Text('Cancel this meet-up'),
            ),
        ] else if (!m.cancelled && m.status == 'published') ...<Widget>[
          if (m.iAmIn)
            OutlinedButton(
              onPressed: _busy ? null : () => _cancelRsvp(m),
              child: Text(
                m.myRsvp == 'waitlist'
                    ? 'Leave the waiting list'
                    : 'Cancel my sign-up',
              ),
            )
          else
            GoldButton(
              label: m.isFull ? 'Join the waiting list' : 'Sign up',
              onPressed: _busy ? null : () => _rsvp(d, me),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await runAction<void>(
                context,
                () => ref
                    .read(communityApiProvider)
                    .hideForMe(CommunityTarget.meetup, m.id),
                done: 'Hidden. You will not see it again.',
              );
              if (context.mounted) context.pop();
            },
            child: const Text('Hide this meet-up for me'),
          ),
        ],
      ],
    );
  }
}

String _reasonText(String wire) {
  for (final CancelReason r in CancelReason.values) {
    if (r.wire == wire) return r.label.toLowerCase();
  }
  return 'no reason given';
}

class _Banner extends StatelessWidget {
  const _Banner(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GlassCard(
        strong: true,
        padding: const EdgeInsets.all(12),
        child: Text(text, style: AppText.body),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.body)),
        ],
      ),
    );
  }
}

class _Attendees extends StatelessWidget {
  const _Attendees(this.a);

  final MeetupAttendees a;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Who is coming',
            style: AppText.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          if (a.adults.isEmpty && a.childrenGoing == 0)
            Text('No one yet.', style: AppText.bodyMuted),
          for (final MeetupAttendee p in a.adults)
            Text(
              p.status == 'waitlist'
                  ? '${p.displayName} (waiting list)'
                  : p.displayName,
              style: AppText.body,
            ),
          if (a.childrenGoing > 0)
            Text(
              '${a.childrenGoing} '
              '${a.childrenGoing == 1 ? 'child' : 'children'} with their '
              'guardians (names are never shown)',
              style: AppText.bodyMuted,
            ),
        ],
      ),
    );
  }
}

class _RsvpDialog extends StatefulWidget {
  const _RsvpDialog({required this.meetup, required this.kids});

  final Meetup meetup;
  final List<BackendProfile> kids;

  @override
  State<_RsvpDialog> createState() => _RsvpDialogState();
}

class _RsvpDialogState extends State<_RsvpDialog> {
  final Set<String> _picked = <String>{};
  bool _ack = false;

  @override
  Widget build(BuildContext context) {
    final Meetup m = widget.meetup;
    return AlertDialog(
      title: const Text('Sign up'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${m.title}\n${formatWhen(m.startsAt)}\n${m.venueName}, ${m.city}',
            ),
            const SizedBox(height: 10),
            Text('For: ${audienceLabel(m.audience)}.'),
            if (widget.kids.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              const Text('Bring your children with you:'),
              for (final BackendProfile k in widget.kids)
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _picked.contains(k.id),
                  onChanged: (bool? v) => setState(() {
                    if (v ?? false) {
                      _picked.add(k.id);
                    } else {
                      _picked.remove(k.id);
                    }
                  }),
                  title: Text(k.displayName),
                ),
            ],
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _ack,
              onChanged: (bool? v) => setState(() => _ack = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'I understand this is a public place and I come at my own '
                'responsibility. I am here to meet in person, not to message.',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _ack
              ? () => Navigator.of(context).pop(_picked.toList())
              : null,
          child: const Text('Sign up'),
        ),
      ],
    );
  }
}

class _CancelDialog extends StatefulWidget {
  const _CancelDialog({required this.meetup});

  final Meetup meetup;

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  CancelReason _reason = CancelReason.other;
  bool _series = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel this meet-up?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Everyone who signed up will be told why.'),
            RadioGroup<CancelReason>(
              groupValue: _reason,
              onChanged: (CancelReason? v) =>
                  setState(() => _reason = v ?? _reason),
              child: Column(
                children: <Widget>[
                  for (final CancelReason r in CancelReason.values)
                    RadioListTile<CancelReason>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: r,
                      title: Text(r.label),
                    ),
                ],
              ),
            ),
            if (widget.meetup.recurrence != MeetupRecurrence.none)
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _series,
                onChanged: (bool? v) => setState(() => _series = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Cancel the rest of the series too'),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Keep it'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop((reason: _reason, series: _series)),
          child: const Text('Cancel meet-up'),
        ),
      ],
    );
  }
}

/// Organise a meet-up. Public venues only: there is no field for a home
/// address, a cafe must be confirmed halal, and children can only be included
/// in a families meet-up by a verified organiser.
class MeetupCreateScreen extends ConsumerStatefulWidget {
  const MeetupCreateScreen({super.key});

  @override
  ConsumerState<MeetupCreateScreen> createState() => _MeetupCreateScreenState();
}

class _MeetupCreateScreenState extends ConsumerState<MeetupCreateScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _venue = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _country = TextEditingController();
  final TextEditingController _capacity = TextEditingController();
  final TextEditingController _access = TextEditingController();
  MeetupVenueKind _kind = MeetupVenueKind.mosque;
  MeetupAudience _audience = MeetupAudience.open;
  MeetupRecurrence _recurrence = MeetupRecurrence.none;
  bool _minors = false;
  bool _halal = false;
  bool _ack = false;
  DateTime? _when;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _title,
      _description,
      _venue,
      _address,
      _city,
      _country,
      _capacity,
      _access,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final DateTime now = DateTime.now();
    final DateTime? day = await showDatePicker(
      context: context,
      initialDate: _when ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (day == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    if (time == null) return;
    setState(
      () => _when = DateTime(day.year, day.month, day.day, time.hour, time.minute),
    );
  }

  Future<void> _create() async {
    final DateTime? when = _when;
    if (when == null) {
      setState(() => _error = 'Choose a date and time.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final Meetup m = await ref
          .read(communityApiProvider)
          .createMeetup(
            MeetupDraft(
              title: _title.text.trim(),
              description: _description.text.trim(),
              venueKind: _kind,
              venueName: _venue.text.trim(),
              venueAddress: _address.text.trim(),
              city: _city.text.trim(),
              country: _country.text.trim(),
              startsAt: when,
              audience: _audience,
              guardianRsvpForMinors:
                  _minors && _audience == MeetupAudience.families,
              capacity: int.tryParse(_capacity.text.trim()),
              accessibilityNotes: _access.text.trim(),
              halalConfirmed: _halal,
              recurrence: _recurrence,
              repeatTimes: _recurrence == MeetupRecurrence.none ? 0 : 3,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            m.pendingReview
                ? 'Thank you. A moderator will read it before it is shown.'
                : 'Your meet-up is published.',
          ),
        ),
      );
      context.pop();
    } on BackendException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommunityGate(
      title: 'Organise a meet-up',
      builder: (BuildContext c, MeResponse me) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: <Widget>[
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Choose a public place: a mosque, community centre, library, '
                'halal cafe, park or school hall. Never a home. A verified '
                'organiser’s meet-up is published at once; otherwise a '
                'moderator reads it first.',
                style: AppText.bodyMuted.copyWith(fontSize: 12.5),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              maxLength: 120,
              decoration: const InputDecoration(hintText: 'Title'),
            ),
            TextField(
              controller: _description,
              minLines: 2,
              maxLines: 5,
              maxLength: 2000,
              decoration: const InputDecoration(hintText: 'What is it?'),
            ),
            const SizedBox(height: 8),
            Text('Where', style: AppText.label),
            DropdownButton<MeetupVenueKind>(
              value: _kind,
              isExpanded: true,
              dropdownColor: AppColors.navy,
              items: <DropdownMenuItem<MeetupVenueKind>>[
                for (final MeetupVenueKind k in MeetupVenueKind.values)
                  DropdownMenuItem<MeetupVenueKind>(
                    value: k,
                    child: Text(venueLabel(k)),
                  ),
              ],
              onChanged: (MeetupVenueKind? v) =>
                  setState(() => _kind = v ?? _kind),
            ),
            TextField(
              controller: _venue,
              maxLength: 120,
              decoration: const InputDecoration(
                hintText: 'Name of the place (not a home)',
              ),
            ),
            TextField(
              controller: _address,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Street address of that public place (optional)',
              ),
            ),
            TextField(
              controller: _city,
              maxLength: 80,
              decoration: const InputDecoration(hintText: 'City'),
            ),
            TextField(
              controller: _country,
              maxLength: 2,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Country code, for example GB',
              ),
            ),
            if (_kind == MeetupVenueKind.cafe)
              CheckboxListTile(
                value: _halal,
                onChanged: (bool? v) => setState(() => _halal = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'I have confirmed this cafe serves halal food.',
                  style: AppText.body,
                ),
              ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: _pickWhen,
              icon: const Icon(Icons.schedule),
              label: Text(
                _when == null ? 'Choose date and time' : formatWhen(_when!),
              ),
            ),
            const SizedBox(height: 8),
            Text('Who is it for?', style: AppText.label),
            RadioGroup<MeetupAudience>(
              groupValue: _audience,
              onChanged: (MeetupAudience? v) =>
                  setState(() => _audience = v ?? _audience),
              child: Column(
                children: <Widget>[
                  for (final MeetupAudience a in MeetupAudience.values)
                    RadioListTile<MeetupAudience>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: a,
                      title: Text(audienceLabel(a), style: AppText.body),
                    ),
                ],
              ),
            ),
            if (_audience == MeetupAudience.families)
              SwitchListTile(
                value: _minors,
                onChanged: (bool v) => setState(() => _minors = v),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Children may come with a parent or guardian',
                  style: AppText.body,
                ),
                subtitle: Text(
                  'Only verified organisers can include children.',
                  style: AppText.bodyMuted.copyWith(fontSize: 12),
                ),
              ),
            TextField(
              controller: _capacity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Places available (optional)',
              ),
            ),
            TextField(
              controller: _access,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: 'Access notes, for example step-free (optional)',
              ),
            ),
            const SizedBox(height: 8),
            Text('Repeats', style: AppText.label),
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final MeetupRecurrence r in MeetupRecurrence.values)
                  ChoiceChip(
                    label: Text(
                      r == MeetupRecurrence.none ? 'Once' : r.name,
                    ),
                    selected: _recurrence == r,
                    onSelected: (bool _) => setState(() => _recurrence = r),
                  ),
              ],
            ),
            if (_recurrence != MeetupRecurrence.none)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'It will be created four times in all.',
                  style: AppText.bodyMuted.copyWith(fontSize: 12),
                ),
              ),
            CheckboxListTile(
              value: _ack,
              onChanged: (bool? v) => setState(() => _ack = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'I will hold this in a public place, follow the community '
                'rules, and cancel in good time if I cannot come.',
                style: AppText.body,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.destructive),
                ),
              ),
            GoldButton(
              label: _busy ? 'Saving...' : 'Create meet-up',
              onPressed: _busy || !_ack ? null : _create,
            ),
          ],
        );
      },
    );
  }
}
