import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/core/backend/backend_exception.dart';
import '../../../app/core/backend/community_providers.dart';
import '../../../app/core/backend/models.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/gold_button.dart';

/// Sign in to the community with an e-mailed one-time code. Accounts are for
/// adults; a child is a profile under a parent in the Family Wing.
class JoinPanel extends ConsumerStatefulWidget {
  const JoinPanel({required this.onDone, super.key});

  final VoidCallback onDone;

  @override
  ConsumerState<JoinPanel> createState() => _JoinPanelState();
}

class _JoinPanelState extends ConsumerState<JoinPanel> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _code = TextEditingController();
  bool _codeSent = false;
  bool _adult = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() step) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await step();
    } on BackendException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() => _run(() async {
    await ref.read(communityApiProvider).requestSignInCode(_email.text.trim());
    if (mounted) setState(() => _codeSent = true);
  });

  Future<void> _verify() => _run(() async {
    await ref
        .read(communityApiProvider)
        .verifySignInCode(
          email: _email.text.trim(),
          code: _code.text.trim(),
          confirmAdult: _adult,
        );
    widget.onDone();
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: <Widget>[
        Text('Join the community', style: AppText.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Forums, meet-ups and friends are for adults aged 18 and over. '
          'We send a one-time code to your e-mail. We do not use it for '
          'anything else.',
          style: AppText.bodyMuted,
        ),
        const SizedBox(height: 16),
        Semantics(label: 'Your e-mail', child: TextField(
          controller: _email,
          enabled: !_codeSent,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const <String>[AutofillHints.email],
          decoration: const InputDecoration(hintText: 'Your e-mail'),
        )),
        if (_codeSent) ...<Widget>[
          const SizedBox(height: 12),
          Semantics(label: 'The 6-digit code', child: TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'The 6-digit code'),
          )),
          CheckboxListTile(
            value: _adult,
            onChanged: (bool? v) => setState(() => _adult = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'I am 18 or over.',
              style: AppText.body,
            ),
          ),
        ],
        if (_error != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppColors.destructive)),
        ],
        const SizedBox(height: 16),
        GoldButton(
          label: _codeSent ? 'Sign in' : 'Send me a code',
          onPressed: _busy ? null : (_codeSent ? _verify : _sendCode),
        ),
      ],
    );
  }
}

/// The first-time profile: a display name, and how findable the person is.
/// Nothing is public until the person says so.
class ProfilePanel extends ConsumerStatefulWidget {
  const ProfilePanel({required this.onDone, super.key});

  final VoidCallback onDone;

  @override
  ConsumerState<ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends ConsumerState<ProfilePanel> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _handle = TextEditingController();
  ProfileVisibility _visibility = ProfileVisibility.community;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _handle.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final String handle = _handle.text.trim().toLowerCase();
      await ref
          .read(communityApiProvider)
          .saveProfile(
            displayName: _name.text.trim(),
            handle: handle.isEmpty ? null : handle,
            visibility: _visibility,
          );
      widget.onDone();
    } on BackendException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: <Widget>[
        Text('Your community name', style: AppText.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Choose a name other members will see. Please do not use your full '
          'name. You can change this at any time.',
          style: AppText.bodyMuted,
        ),
        const SizedBox(height: 16),
        Semantics(label: 'Display name', child: TextField(
          controller: _name,
          maxLength: 30,
          decoration: const InputDecoration(hintText: 'Display name'),
        )),
        Semantics(label: 'Handle for friends to find you (optional)', child: TextField(
          controller: _handle,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: 'Handle for friends to find you (optional)',
          ),
        )),
        const SizedBox(height: 8),
        RadioGroup<ProfileVisibility>(
          groupValue: _visibility,
          onChanged: (ProfileVisibility? v) =>
              setState(() => _visibility = v ?? _visibility),
          child: Column(
            children: <Widget>[
              _choice(
                ProfileVisibility.community,
                'Visible in the community',
                'Your display name shows on your posts and meet-ups. '
                    'Needed to write in the forums.',
              ),
              _choice(
                ProfileVisibility.handle,
                'Findable by handle',
                'Friends who know your exact handle can find you.',
              ),
              _choice(
                ProfileVisibility.private,
                'Private',
                'Only people you invite can reach you.',
              ),
            ],
          ),
        ),
        if (_error != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: AppColors.destructive)),
        ],
        const SizedBox(height: 16),
        GoldButton(label: 'Save', onPressed: _busy ? null : _save),
      ],
    );
  }

  Widget _choice(ProfileVisibility v, String title, String sub) {
    return RadioListTile<ProfileVisibility>(
      value: v,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: AppText.body),
      subtitle: Text(sub, style: AppText.bodyMuted.copyWith(fontSize: 12)),
    );
  }
}
