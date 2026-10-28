import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../share/presentation/share_actions.dart' show copyWithFeedback;

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/switch_row.dart';
import '../../academy/application/family_service.dart';
import '../../academy/presentation/widgets/parent_gate.dart';
import '../application/support_settings.dart';
import '../data/secret_store.dart';
import '../domain/checkin_scheduler.dart';
import '../domain/user_memory.dart';

/// Settings > Support & wellbeing. Plain wording, every control a labelled
/// row of at least 48 dp, so a screen reader reads it as a list of choices.
/// Every default is the private one.
class SupportWellbeingScreen extends ConsumerWidget {
  const SupportWellbeingScreen({super.key});

  static const Map<String, String> _languageNames = <String, String>{
    'en': 'English',
    'ar': 'Arabic',
    'ur': 'Urdu',
    'bn': 'Bangla',
  };

  Widget _head(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8, top: 20),
        child: Text(t, style: AppText.eyebrow),
      );

  Widget _note(String t) => Padding(
        padding: const EdgeInsets.only(top: 6, left: 4),
        child: Text(t, style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5)),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SupportSettings s = ref.watch(supportSettingsProvider);
    final SupportSettingsNotifier n = ref.read(supportSettingsProvider.notifier);
    final CheckinFrequency f = s.checkin.off ? CheckinFrequency.off : s.checkin.frequency;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          const ScenicBackground.pattern(),
          SafeArea(
            child: Column(
              children: <Widget>[
                const ScreenHeader(title: 'Support & wellbeing', showSettings: false),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: <Widget>[
                      Text(
                        'Everything here is private by default and stays on this '
                        'device. Nothing is sent to analytics. The support wording '
                        'is not yet reviewed by a named clinician or scholar, and '
                        'is marked as such.',
                        style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
                      ),
                      _head('GENTLE CHECK-IN'),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('How often Hadi and Wasia ask how you are really doing',
                                style: AppText.body.copyWith(fontSize: 14)),
                            const SizedBox(height: 8),
                            Semantics(
                              label: 'Check-in frequency',
                              child: DropdownButton<CheckinFrequency>(
                                key: const Key('support-checkin-frequency'),
                                isExpanded: true,
                                dropdownColor: AppColors.night,
                                value: f,
                                items: const <DropdownMenuItem<CheckinFrequency>>[
                                  DropdownMenuItem<CheckinFrequency>(
                                      value: CheckinFrequency.off, child: Text('Off')),
                                  DropdownMenuItem<CheckinFrequency>(
                                      value: CheckinFrequency.weekly, child: Text('Weekly')),
                                  DropdownMenuItem<CheckinFrequency>(
                                      value: CheckinFrequency.fortnightly,
                                      child: Text('Every 2 weeks (default)')),
                                  DropdownMenuItem<CheckinFrequency>(
                                      value: CheckinFrequency.monthly, child: Text('Monthly')),
                                ],
                                onChanged: (CheckinFrequency? v) {
                                  if (v != null) n.setFrequency(v);
                                },
                              ),
                            ),
                            _note('It only appears when you open Hadi or Wasia. It is never a '
                                'notification, and it is never tied to activity. '
                                'Only the day it was last asked and this setting are stored.'),
                          ],
                        ),
                      ),
                      _head('WHAT HADI REMEMBERS'),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: SwitchRow(
                          icon: Icons.memory_outlined,
                          title: 'Let Hadi remember things I tell it',
                          subtitle: 'Off by default. Only what you ask it to remember, '
                              'kept encrypted on this device.',
                          value: s.remember,
                          onChanged: (bool v) async {
                            if (!v && n.memory.isNotEmpty) {
                              final bool? wipe = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext c) => AlertDialog(
                                  title: const Text('Delete what Hadi knows?'),
                                  content: const Text(
                                      'You can keep what is saved, or delete it now.'),
                                  actions: <Widget>[
                                    TextButton(
                                        onPressed: () => Navigator.pop(c, false),
                                        child: const Text('Keep it')),
                                    TextButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Delete it')),
                                  ],
                                ),
                              );
                              if (wipe == true) await n.deleteAllMemory();
                            }
                            await n.setRemember(v);
                          },
                        ),
                      ),
                      GlassCard(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => const WhatHadiKnowsScreen())),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(children: <Widget>[
                          const Icon(Icons.visibility_outlined, size: 18, color: AppColors.gold),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text('What Hadi knows about me',
                                  style: AppText.body.copyWith(fontSize: 14))),
                          const Icon(Icons.chevron_right, size: 16),
                        ]),
                      ),
                      _note('View, edit, delete one item, delete all, or export. Hadi never '
                          'keeps anything about safety, health or substances, even if asked.'),
                      _head('ONLINE MODEL'),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: SwitchRow(
                          icon: Icons.cloud_outlined,
                          title: 'Use the online model for support chats',
                          subtitle: 'Off by default. Support chats are answered on this '
                              'device.',
                          value: s.onlineModel,
                          onChanged: (bool v) async {
                            if (v) {
                              final bool? ok = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext c) => AlertDialog(
                                  title: const Text('Before you turn this on'),
                                  content: const Text(
                                      'If you turn this on, what you type in a support '
                                      'chat can be sent to the online model Ar-Rayaan '
                                      'is connected to, so it can write a longer reply. '
                                      'Your name is not sent, and nothing is sent '
                                      'if your message looks like an emergency, '
                                      'abuse, or a child speaking. Your own AI key is '
                                      'never used for this. The model company may keep '
                                      'what it receives for a time. You can turn this '
                                      'off again at any time.'),
                                  actions: <Widget>[
                                    TextButton(
                                        onPressed: () => Navigator.pop(c, false),
                                        child: const Text('Keep it off')),
                                    TextButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Turn it on')),
                                  ],
                                ),
                              );
                              if (ok != true) return;
                            }
                            await n.setOnlineModel(v);
                          },
                        ),
                      ),
                      _head('PRIVACY WHEN SOMEONE ELSE MAY SEE'),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Column(children: <Widget>[
                          SwitchRow(
                            icon: Icons.visibility_off_outlined,
                            title: 'Private mode',
                            subtitle: 'A plain cover when the app is left or '
                                'switched, the Hādi and Wasia conversations '
                                'cleared when you leave, no message text in '
                                'notifications, and no support screen when '
                                'the app opens. It does not hide the browser\u2019s '
                                'own history or the address bar on the web.',
                            value: s.privateMode,
                            onChanged: (bool v) => n.setPrivateMode(v),
                          ),
                          SwitchRow(
                            icon: Icons.exit_to_app,
                            title: 'Quick exit button',
                            subtitle: 'Shown on support screens. Clears the conversation '
                                'and leaves at once.',
                            value: s.quickExit,
                            onChanged: (bool v) => n.setQuickExit(v),
                          ),
                          SwitchRow(
                            icon: Icons.swap_horiz,
                            title: 'Quick exit button on the left',
                            subtitle: 'Off puts it on the right.',
                            value: s.quickExitLeft,
                            onChanged: s.quickExit ? (bool v) => n.setQuickExitLeft(v) : null,
                          ),
                        ]),
                      ),
                      GlassCard(
                        key: const Key('support-safe-word'),
                        onTap: () => _editSafeWord(context, n),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(children: <Widget>[
                          const Icon(Icons.key_outlined, size: 18, color: AppColors.gold),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('Safe word', style: AppText.body.copyWith(fontSize: 14)),
                                Text(
                                  n.safeWord == null
                                      ? 'Not set. Type your word in Hadi to clear the chat and leave at once.'
                                      : (kIsWeb
                                          ? 'Set for this visit only. On the web it is forgotten when the page is closed or reloaded, so set it again next time. Typing it in Hadi clears the chat and leaves at once.'
                                          : 'Set. Typing it in Hadi clears the chat and leaves at once.'),
                                  style: AppText.bodyMuted.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 16),
                        ]),
                      ),
                      _note('The name of the app on your home screen cannot be changed from '
                          'inside the app. That is a limit of the phone.'),
                      _head('LANGUAGE'),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Language for support lines',
                                style: AppText.body.copyWith(fontSize: 14)),
                            DropdownButton<String>(
                              key: const Key('support-language'),
                              isExpanded: true,
                              dropdownColor: AppColors.night,
                              value: s.language,
                              items: <DropdownMenuItem<String>>[
                                for (final String l in kSupportLanguages)
                                  DropdownMenuItem<String>(
                                      value: l, child: Text(_languageNames[l] ?? l)),
                              ],
                              onChanged: (String? v) {
                                if (v != null) n.setLanguage(v);
                              },
                            ),
                            _note('Arabic, Urdu and Bangla wording for emergencies and help '
                                'lines was written for coverage and has not been read by a '
                                'native-speaking clinician yet. English has the most.'),
                          ],
                        ),
                      ),
                      _head('SAKINA'),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: SwitchRow(
                          icon: Icons.self_improvement,
                          title: 'Show Sakina support rooms',
                          subtitle: 'Shows or hides the support entry points in Sakina.',
                          value: s.showSakina,
                          onChanged: (bool v) => n.setShowSakina(v),
                        ),
                      ),
                      _head('TONE'),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: DropdownButton<String>(
                          key: const Key('support-tone'),
                          isExpanded: true,
                          dropdownColor: AppColors.night,
                          value: s.tone,
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem<String>(value: 'auto', child: Text('Follow my pace (default)')),
                            DropdownMenuItem<String>(value: 'warm', child: Text('Warm')),
                            DropdownMenuItem<String>(value: 'brief', child: Text('Brief')),
                            DropdownMenuItem<String>(value: 'formal', child: Text('Formal')),
                          ],
                          onChanged: (String? v) {
                            if (v != null) n.setTone(v);
                          },
                        ),
                      ),
                      _head('PARENT CONTROLS'),
                      const _ParentBands(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editSafeWord(BuildContext context, SupportSettingsNotifier n) async {
    final TextEditingController c = TextEditingController();
    final String? word = await showDialog<String>(
      context: context,
      builder: (BuildContext d) => AlertDialog(
        title: const Text('Safe word'),
        content: TextField(
          key: const Key('safe-word-field'),
          controller: c,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'A word you will remember'),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(d, ''), child: const Text('Remove it')),
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(d, c.text), child: const Text('Save')),
        ],
      ),
    );
    c.dispose();
    if (word == null) return;
    await n.setSafeWord(word);
  }
}

/// Age band per child, behind the parent check.
class _ParentBands extends ConsumerStatefulWidget {
  const _ParentBands();

  @override
  ConsumerState<_ParentBands> createState() => _ParentBandsState();
}

class _ParentBandsState extends ConsumerState<_ParentBands> {
  List<Map<String, dynamic>> _children = <Map<String, dynamic>>[];
  final Map<String, String> _bands = <String, String>{};
  bool _open = false;

  Future<void> _unlock() async {
    if (!await requireParent(context, ref)) return;
    final FamilyService fs = ref.read(familyServiceProvider);
    final List<Map<String, dynamic>> kids = await fs.children();
    for (final Map<String, dynamic> k in kids) {
      _bands[k['id'] as String] = await fs.ageBand(k['id'] as String);
    }
    if (!mounted) return;
    setState(() {
      _children = kids;
      _open = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_open) {
      return GlassCard(
        onTap: _unlock,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: <Widget>[
          const Icon(Icons.lock_outline, size: 18, color: AppColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Age band for each child (needs the parent check)',
                style: AppText.body.copyWith(fontSize: 14)),
          ),
        ]),
      );
    }
    if (_children.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        child: Text('No children have been added in the Family Wing.',
            style: AppText.bodyMuted.copyWith(fontSize: 13)),
      );
    }
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final Map<String, dynamic> k in _children) ...<Widget>[
            Text(k['name'] as String, style: AppText.body.copyWith(fontSize: 14)),
            DropdownButton<String>(
              isExpanded: true,
              dropdownColor: AppColors.night,
              value: _bands[k['id'] as String],
              items: <DropdownMenuItem<String>>[
                for (final String b in FamilyService.ageBands)
                  DropdownMenuItem<String>(value: b, child: Text('Age $b')),
              ],
              onChanged: (String? v) async {
                if (v == null) return;
                await ref.read(familyServiceProvider).setAgeBand(k['id'] as String, v);
                setState(() => _bands[k['id'] as String] = v);
              },
            ),
          ],
          Text(
            'Wasia uses this to choose suitable words. A child’s chats and feelings '
            'are never shown to you, and Wasia keeps no record of them.',
            style: AppText.bodyMuted.copyWith(fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// View, edit, delete and export what Hadi was asked to remember.
class WhatHadiKnowsScreen extends ConsumerWidget {
  const WhatHadiKnowsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(supportSettingsProvider);
    final SupportSettingsNotifier n = ref.read(supportSettingsProvider.notifier);
    final List<MemoryItem> items = n.memory;
    return Scaffold(
      body: Stack(children: <Widget>[
        const ScenicBackground.pattern(),
        SafeArea(
          child: Column(children: <Widget>[
            const ScreenHeader(title: 'What Hadi knows about me', showSettings: false),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: <Widget>[
                  Text(
                    SecretStore.persistsAcrossVisits
                        ? 'Saved only because you asked, and encrypted on this device.'
                        : 'Saved only because you asked. In a browser it is kept for this visit only.',
                    style: AppText.bodyMuted.copyWith(fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  if (items.isEmpty)
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Text('Hadi knows nothing about you.',
                          key: const Key('memory-empty'),
                          style: AppText.body.copyWith(fontSize: 14)),
                    ),
                  for (final MemoryItem i in items)
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(children: <Widget>[
                        Expanded(child: Text(i.text, style: AppText.body.copyWith(fontSize: 14))),
                        IconButton(
                          tooltip: 'Edit',
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _edit(context, n, i),
                        ),
                        IconButton(
                          tooltip: 'Delete this one',
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => n.deleteMemory(i.id),
                        ),
                      ]),
                    ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
                    OutlinedButton(
                      key: const Key('memory-export'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                      onPressed: () => copyWithFeedback(
                        context,
                        n.exportMemory(),
                        message: 'Copied. You can paste it anywhere to keep it.',
                      ),
                      child: const Text('Export (copy as text)'),
                    ),
                    OutlinedButton(
                      key: const Key('memory-delete-all'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                      onPressed: items.isEmpty ? null : () => n.deleteAllMemory(),
                      child: const Text('Delete everything'),
                    ),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Future<void> _edit(BuildContext context, SupportSettingsNotifier n, MemoryItem i) async {
    final TextEditingController c = TextEditingController(text: i.text);
    final String? t = await showDialog<String>(
      context: context,
      builder: (BuildContext d) => AlertDialog(
        title: const Text('Edit'),
        content: TextField(controller: c, maxLength: UserMemory.maxLength),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(d, c.text), child: const Text('Save')),
        ],
      ),
    );
    c.dispose();
    if (t != null) await n.editMemory(i.id, t);
  }
}
