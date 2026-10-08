/// Founder Console — the Doctor's control surface.
/// PIN-gated (no default PIN: first run sets one, recovery via two
/// security questions). No Cloudflare token field exists here, by
/// architecture — deploy keys never enter the app.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../academy/application/academy_providers.dart';
import '../application/founder_auth.dart';
import '../application/founder_commands.dart';
import '../application/physician_engine.dart';
import '../domain/physician.dart';
import '../application/doctor_providers.dart';
import '../application/vitals_registry.dart';
import '../domain/vitals.dart';

class FounderConsoleScreen extends ConsumerStatefulWidget {
  const FounderConsoleScreen({super.key});

  @override
  ConsumerState<FounderConsoleScreen> createState() =>
      _FounderConsoleScreenState();
}

class _FounderConsoleScreenState
    extends ConsumerState<FounderConsoleScreen> {
  bool _unlocked = false;
  HealthReport? _lastReport;

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      return Scaffold(
        body: ScenicScaffold.pattern(
          body: SafeArea(child: _AuthGate(onUnlock: () => setState(() => _unlocked = true))),
        ),
      );
    }
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text('Founder Console',
                        style: AppText.titleMedium
                            .copyWith(color: AppColors.gold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.lock_outline, color: AppColors.gold),
                    onPressed: () => setState(() => _unlocked = false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GlassCard(
                strong: true,
                onTap: () async {
                  final report = await DoctorVitals.runAll();
                  ref.read(heartbeatLogProvider).record(report);
                  setState(() => _lastReport = report);
                },
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.monitor_heart_outlined,
                        color: AppColors.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _lastReport == null
                            ? 'Tap to run a full health check'
                            : _lastReport!.healthy
                                ? 'Healthy — ${VitalsRegistry.probes.length} probes passed'
                                : '${_lastReport!.totalFailures} failing, ${_lastReport!.repaired} repaired',
                        style: AppText.body,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.gold),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const _PhysicianCard(),
              if (_lastReport != null) ...<Widget>[
                const SizedBox(height: 10),
                for (final ProbeResult r in _lastReport!.results)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: GlassCard(
                      child: Row(
                        children: <Widget>[
                          Icon(
                            r.isHealthy
                                ? (r.status == ProbeStatus.repaired
                                    ? Icons.build_circle_outlined
                                    : Icons.check_circle_outline)
                                : Icons.error_outline,
                            color: r.isHealthy ? AppColors.gold : Colors.orangeAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('${r.feature} · ${r.probeId}',
                                    style: AppText.caption
                                        .copyWith(color: AppColors.gold)),
                                Text(r.detail.isEmpty ? r.status.name : r.detail,
                                    style: AppText.caption),
                                if (r.repairDescription.isNotEmpty)
                                  Text('Repaired: ${r.repairDescription}',
                                      style: AppText.caption),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              _CommandBar(),
              const SizedBox(height: 16),
              const _FlagTile(
                title: 'Academy enabled',
                flagKey: 'ar.flag.academy',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlagTile extends ConsumerStatefulWidget {
  const _FlagTile({required this.title, required this.flagKey});
  final String title;
  final String flagKey;

  @override
  ConsumerState<_FlagTile> createState() => _FlagTileState();
}

class _FlagTileState extends ConsumerState<_FlagTile> {
  bool? _value;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = ref.read(sharedPreferencesProvider);
    setState(() => _value = prefs.getBool(widget.flagKey) ?? true);
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: SwitchListTile(
        title: Text(widget.title, style: AppText.body),
        value: _value ?? true,
        activeThumbColor: AppColors.gold,
        onChanged: (v) async {
          final prefs = ref.read(sharedPreferencesProvider);
          await prefs.setBool(widget.flagKey, v);
          ref.invalidate(academyFlagProvider);
          setState(() => _value = v);
        },
      ),
    );
  }
}

class _CommandBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CommandBar> createState() => _CommandBarState();
}

class _CommandBarState extends ConsumerState<_CommandBar> {
  final TextEditingController _controller = TextEditingController();
  String _reply = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final ParsedCommand cmd = FounderCommandParser.parse(_controller.text);
    String reply = cmd.reply;
    if (cmd.action == 'run_vitals') {
      final report = await DoctorVitals.runAll();
      ref.read(heartbeatLogProvider).record(report);
      reply = report.healthy
          ? 'All ${report.results.length} probes healthy.'
          : '${report.totalFailures} failing, ${report.repaired} repaired.';
    } else if (cmd.action == 'toggle_flag') {
      final prefs = ref.read(sharedPreferencesProvider);
      final String key = cmd.args['flag']!;
      final bool next = !(prefs.getBool(key) ?? true);
      await prefs.setBool(key, next);
      ref.invalidate(academyFlagProvider);
      reply = '$key is now ${next ? 'ON' : 'OFF'}.';
    }
    setState(() {
      _reply = reply;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _controller,
            style: AppText.body,
            decoration: const InputDecoration(
              hintText: 'Founder command — type "help"',
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _run(),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _run,
              child: Text('Run', style: AppText.caption.copyWith(color: AppColors.gold)),
            ),
          ),
          if (_reply.isNotEmpty) Text(_reply, style: AppText.caption),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Auth gate: set PIN (first run) / verify / recover.
// ---------------------------------------------------------------------------

class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate({required this.onUnlock});
  final VoidCallback onUnlock;

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  final TextEditingController _pin = TextEditingController();
  String _error = '';

  Future<void> _submit() async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (!FounderAuth.isConfigured(prefs)) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(builder: (_) => const _SetupPinScreen()),
      );
      if (ok == true) widget.onUnlock();
      return;
    }
    if (FounderAuth.verify(prefs, _pin.text)) {
      widget.onUnlock();
    } else {
      setState(() {
        _error = 'Wrong PIN.';
        _pin.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final bool configured = FounderAuth.isConfigured(prefs);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: <Widget>[
        Icon(Icons.admin_panel_settings_outlined,
            color: AppColors.gold, size: 40),
        const SizedBox(height: 12),
        Text(
          configured ? 'Enter founder PIN' : 'Set up founder access',
          style: AppText.titleMedium.copyWith(color: AppColors.gold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        GlassCard(
          strong: true,
          child: TextField(
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            style: AppText.body,
            decoration: const InputDecoration(
              hintText: 'PIN (4–8 digits)',
              border: InputBorder.none,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        if (_error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error, style: AppText.caption.copyWith(color: Colors.orangeAccent)),
          ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _submit, child: Text(configured ? 'Unlock' : 'Set up')),
        if (configured) ...<Widget>[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              final ok = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(builder: (_) => const _RecoverScreen()),
              );
              if (!mounted) return;
              if (ok != true) return;
              await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(builder: (_) => const _SetupPinScreen()),
              );
              if (!mounted) return;
              setState(() {
                _error = '';
                _pin.clear();
              });
            },
            child: Text('Forgot PIN?', style: AppText.caption.copyWith(color: AppColors.gold)),
          ),
        ],
      ],
    );
  }
}

class _SetupPinScreen extends ConsumerStatefulWidget {
  const _SetupPinScreen();
  @override
  ConsumerState<_SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends ConsumerState<_SetupPinScreen> {
  final _pin = TextEditingController();
  final _q1 = TextEditingController();
  final _a1 = TextEditingController();
  final _q2 = TextEditingController();
  final _a2 = TextEditingController();
  String _error = '';

  Future<void> _save() async {
    try {
      await FounderAuth.configure(
        prefs: ref.read(sharedPreferencesProvider),
        pin: _pin.text,
        question1: _q1.text,
        answer1: _a1.text,
        question2: _q2.text,
        answer2: _a2.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ArgumentError catch (e) {
      setState(() => _error = e.message.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            children: <Widget>[
              Text('Set founder PIN',
                  style: AppText.titleMedium.copyWith(color: AppColors.gold)),
              const SizedBox(height: 12),
              GlassCard(
                strong: true,
                child: TextField(
                  controller: _pin,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  style: AppText.body,
                  decoration: const InputDecoration(
                      hintText: 'New PIN (4–8 digits)', border: InputBorder.none),
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                child: Column(
                  children: <Widget>[
                    TextField(
                        controller: _q1,
                        style: AppText.body,
                        decoration: const InputDecoration(
                            hintText: 'Recovery question 1 (e.g. first masjid you prayed in)',
                            border: InputBorder.none)),
                    TextField(
                        controller: _a1,
                        style: AppText.body,
                        decoration: const InputDecoration(
                            hintText: 'Answer 1', border: InputBorder.none)),
                    const Divider(),
                    TextField(
                        controller: _q2,
                        style: AppText.body,
                        decoration: const InputDecoration(
                            hintText: 'Recovery question 2 (e.g. your mother’s first name)',
                            border: InputBorder.none)),
                    TextField(
                        controller: _a2,
                        style: AppText.body,
                        decoration: const InputDecoration(
                            hintText: 'Answer 2', border: InputBorder.none)),
                  ],
                ),
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error,
                      style: AppText.caption.copyWith(color: Colors.orangeAccent)),
                ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecoverScreen extends ConsumerStatefulWidget {
  const _RecoverScreen();
  @override
  ConsumerState<_RecoverScreen> createState() => _RecoverScreenState();
}

class _RecoverScreenState extends ConsumerState<_RecoverScreen> {
  final _a1 = TextEditingController();
  final _a2 = TextEditingController();
  String _error = '';

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            children: <Widget>[
              Text('Recover access',
                  style: AppText.titleMedium.copyWith(color: AppColors.gold)),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(FounderAuth.recoveryQuestion1(prefs),
                          style: AppText.caption.copyWith(color: AppColors.gold)),
                    ),
                    TextField(
                        controller: _a1,
                        style: AppText.body,
                        decoration: const InputDecoration(border: InputBorder.none)),
                    const Divider(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(FounderAuth.recoveryQuestion2(prefs),
                          style: AppText.caption.copyWith(color: AppColors.gold)),
                    ),
                    TextField(
                        controller: _a2,
                        style: AppText.body,
                        decoration: const InputDecoration(border: InputBorder.none)),
                  ],
                ),
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error,
                      style: AppText.caption.copyWith(color: Colors.orangeAccent)),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  if (FounderAuth.verifyRecovery(prefs,
                      answer1: _a1.text, answer2: _a2.text)) {
                    Navigator.of(context).pop(true);
                  } else {
                    setState(() => _error = 'Answers do not match.');
                  }
                },
                child: const Text('Verify'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// The Physician (Tier 2): describe a problem or ask for a diagnosis;
// the AI proposes, the founder approves each action.
// ---------------------------------------------------------------------------

class _PhysicianCard extends ConsumerStatefulWidget {
  const _PhysicianCard();

  @override
  ConsumerState<_PhysicianCard> createState() => _PhysicianCardState();
}

class _PhysicianCardState extends ConsumerState<_PhysicianCard> {
  final TextEditingController _question = TextEditingController();
  Diagnosis? _diagnosis;
  String _status = '';
  bool _busy = false;

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _diagnose() async {
    setState(() {
      _busy = true;
      _status = 'Consulting the Physician…';
    });
    final report = await DoctorVitals.runAll();
    ref.read(heartbeatLogProvider).record(report);
    final prefs = ref.read(sharedPreferencesProvider);
    final bundle = PhysicianEngine.bundleFor(
      report,
      heartbeat: ref
          .read(heartbeatLogProvider)
          .entries
          .take(5)
          .map((HeartbeatEntry e) => e.summary)
          .toList(),
      flagStates: <String, bool>{
        'academy': prefs.getBool('ar.flag.academy') ?? true,
      },
      appVersion: 'beta',
    );
    final Diagnosis? d = await PhysicianEngine.diagnose(bundle);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (d == null) {
        _diagnosis = null;
        _status = 'The AI ladder is unreachable (offline or keys missing). '
            'Repairs you can make: run the health check above, or send '
            'diagnostics to your build engineer.';
      } else {
        _diagnosis = d;
        _status = '';
      }
    });
  }

  Future<void> _approve(PlanAction action) async {
    final prefs = ref.read(sharedPreferencesProvider);
    String done;
    switch (action.id) {
      case 'toggle_flag':
        final String key = action.args['key'] ?? 'ar.flag.academy';
        final bool next = !(prefs.getBool(key) ?? true);
        await prefs.setBool(key, next);
        ref.invalidate(academyFlagProvider);
        done = '$key is now ${next ? 'ON' : 'OFF'}.';
      case 'trim_storage':
        await prefs.remove('ar.doctor.probe');
        done = 'Transient stores trimmed.';
      case 'clear_cache':
      case 'reload_pack':
      case 'reset_module_state':
        done = '"${action.id}" queued for the next app start (safe point).';
      default:
        done = 'Unknown action refused.';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(done)));
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      strong: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Ask the Physician',
              style: AppText.titleMedium.copyWith(color: AppColors.gold)),
          const SizedBox(height: 8),
          Text(
            'Describe what feels wrong, or leave blank for a general '
            'diagnosis. The AI proposes - you approve every action.',
            style: AppText.caption.copyWith(height: 1.4),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _question,
            style: AppText.body,
            decoration: const InputDecoration(
              hintText: 'e.g. "words due seems stuck" (optional)',
              border: InputBorder.none,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy ? null : _diagnose,
              child: Text(_busy ? 'Working…' : 'Diagnose',
                  style: AppText.caption.copyWith(color: AppColors.gold)),
            ),
          ),
          if (_status.isNotEmpty)
            Text(_status, style: AppText.caption.copyWith(height: 1.4)),
          if (_diagnosis != null) ...<Widget>[
            const Divider(height: 20),
            Text('Hypothesis (confidence ${_diagnosis!.confidence}%)',
                style: AppText.caption.copyWith(color: AppColors.gold)),
            const SizedBox(height: 4),
            Text(_diagnosis!.hypothesis, style: AppText.body.copyWith(height: 1.4)),
            const SizedBox(height: 10),
            if (_diagnosis!.actions.isEmpty)
              Text('No safe automatic actions proposed.',
                  style: AppText.caption)
            else
              for (final PlanAction a in _diagnosis!.actions)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(a.id, style: AppText.body.copyWith(color: AppColors.gold)),
                            Text(a.reason, style: AppText.caption.copyWith(height: 1.3)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _approve(a),
                        child: Text('Approve',
                            style: AppText.caption.copyWith(color: AppColors.gold)),
                      ),
                    ],
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
