import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../../auth/application/auth_providers.dart';
import '../legal_routes.dart';

/// Shown at the top of both documents so nobody mistakes a draft for a
/// reviewed legal text.
const String kLegalDraftNotice =
    'DRAFT — this text has not yet been reviewed by a lawyer. It '
    'describes honestly what the app does today and will be replaced by a '
    'reviewed version before a public store release.';

class LegalSection {
  const LegalSection(this.heading, this.body);
  final String heading;
  final String body;
}

const List<LegalSection> kTermsSections = <LegalSection>[
  LegalSection(
    'What Ar-Rayaan is',
    'Ar-Rayaan is a study and reflection companion: Qur\'an, hadith, '
        'supplications, prayer-time tools, learning material and stories. '
        'It is not a religious authority.',
  ),
  LegalSection(
    'Not a source of fatwa',
    'Nothing in the app, including answers from Hadi, the Majlis or any '
        'calculator, is a fatwa or a ruling for your situation. For rulings '
        'on worship, family, finance, health or any personal matter, ask a '
        'qualified scholar. Calculated prayer times and Zakat amounts are '
        'aids; check them against your local mosque or scholar.',
  ),
  LegalSection(
    'Not medical, mental-health or emergency help',
    'The app is not a medical or counselling service. If you or someone '
        'else is in danger, contact your local emergency number or a crisis '
        'line straight away. Sakina lists help lines by country, but the app '
        'cannot call for help on your behalf.',
  ),
  LegalSection(
    'Your account',
    'You are responsible for what you do with your account and for keeping '
        'your password private. You can delete your account at any time '
        'from the Delete account screen.',
  ),
  LegalSection(
    'The Majlis (community)',
    'Posts in the Majlis are public and shown with the display name you '
        'choose. They are not reviewed before they appear. Do not post '
        'anything unlawful, abusive, hateful, deceptive, or that shares '
        'private information about other people, and do not claim to be '
        'Ar-Rayaan, its staff or a scholar. Posts can be reported and may '
        'be removed. You are responsible for what you post.',
  ),
  LegalSection(
    'Content and accuracy',
    'We work to keep Qur\'an, hadith and other religious content accurate '
        'and to cite sources, but errors can occur. If you find one, please '
        'tell us so it can be corrected.',
  ),
  LegalSection(
    'Changes and contact',
    'These terms may change; the version shown here is the one that '
        'applies. Contact address: [to be added by the app owner before public release].',
  ),
];

const List<LegalSection> kPrivacySections = <LegalSection>[
  LegalSection(
    'What stays on your device',
    'Your settings, bookmarks, progress, reflections, saved Hadi '
        'conversations and any AI key you enter are stored on your device. '
        'You can clear them by clearing the app\'s data or by removing the '
        'key in Hadi settings.',
  ),
  LegalSection(
    'Hadi and AI providers',
    'Hadi can answer from an offline library that never leaves your device. '
        'If you add your own key for an AI provider (for example Groq, '
        'OpenRouter or xAI), your key and the messages in your conversation '
        'are sent to that provider to produce an answer, under their terms '
        'and privacy policy. Messages that look like a personal crisis are '
        'answered on the device and are not sent to any provider or saved.',
  ),
  LegalSection(
    'Your account',
    'If you create an account we use Firebase Authentication (Google) to '
        'store your name, email address and sign-in method. Deleting your '
        'account removes the sign-in record and the account data we keep '
        'about you.',
  ),
  LegalSection(
    'The Majlis',
    'What you post in the Majlis (title, text, display name and an '
        'identifier for your account) is stored in Firebase Firestore and '
        'is public. Deleting your account does not automatically remove '
        'posts already published; contact us to ask for a post to be '
        'removed.',
  ),
  LegalSection(
    'Location and other services',
    'Prayer times, Qibla and the mosque finder use the location you give '
        'or allow. The app contacts third-party services to work: prayer '
        'time and map services, audio servers for recitation, and GitHub to '
        'download updated content (this reveals your IP address to that '
        'service). Each has its own privacy policy.',
  ),
  LegalSection(
    'We do not sell your data',
    'We do not sell personal data or show advertising based on it.',
  ),
  LegalSection(
    'Your choices',
    'You can delete your account from the Delete account screen, clear '
        'local data from your device settings, and ask us about any data '
        'we hold about you at the contact address [to be added by the app owner before public release].',
  ),
];

class _LegalPage extends StatelessWidget {
  const _LegalPage({required this.title, required this.sections});

  final String title;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.night,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/home'),
                      icon: const Icon(Icons.arrow_back, size: 20),
                      color: AppColors.sand.withValues(alpha: 0.8),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        style: AppText.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  key: const Key('legal-draft-notice'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    kLegalDraftNotice,
                    style: AppText.caption.copyWith(
                      color: AppColors.goldLight,
                      height: 1.4,
                    ),
                  ),
                ),
                for (final s in sections) ...[
                  const SizedBox(height: 18),
                  Text(
                    s.heading,
                    style: AppText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.body,
                    style: AppText.body.copyWith(
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const _LegalPage(title: 'Terms of Service', sections: kTermsSections);
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const _LegalPage(title: 'Privacy Policy', sections: kPrivacySections);
}

/// Permanent account deletion with re-authentication.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  bool _confirmed = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final String? problem = await ref
        .read(authControllerProvider.notifier)
        .deleteAccount(password: _password.text);
    if (!mounted) return;
    if (problem != null) {
      setState(() {
        _busy = false;
        _error = problem;
      });
      return;
    }
    context.go('/auth/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    return Scaffold(
      backgroundColor: AppColors.night,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/home'),
                      icon: const Icon(Icons.arrow_back, size: 20),
                      color: AppColors.sand.withValues(alpha: 0.8),
                    ),
                    Expanded(
                      child: Text(
                        'Delete account',
                        style: AppText.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 16),
                if (user == null)
                  Text(
                    'You are not signed in, so there is no account to delete. '
                    'Data kept only on this device can be cleared from your '
                    'device settings.',
                    key: const Key('delete-signed-out'),
                    style: AppText.body.copyWith(height: 1.5),
                  )
                else ...[
                  Text(
                    'This permanently deletes the account ${user.email}.',
                    style: AppText.body.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'What happens: your sign-in and the account data we keep '
                    'about you are removed and cannot be recovered. Posts you '
                    'already made in the Majlis are public and are not removed '
                    'automatically; contact the app owner to have one removed. '
                    'Bookmarks and progress stored only on this device stay '
                    'until you clear the app\'s data.',
                    style: AppText.caption.copyWith(
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (user.usesPassword)
                    TextField(
                      key: const Key('delete-password'),
                      controller: _password,
                      obscureText: true,
                      style: AppText.body,
                      decoration: const InputDecoration(
                        hintText: 'Enter your password to confirm',
                      ),
                    )
                  else
                    Text(
                      'You signed in with Google or Apple, so you will be '
                      'asked to sign in with it again to confirm.',
                      style: AppText.caption,
                    ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    key: const Key('delete-confirm'),
                    value: _confirmed,
                    onChanged: (v) => setState(() => _confirmed = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'I understand this cannot be undone.',
                      style: AppText.caption,
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _error!,
                        key: const Key('delete-error'),
                        style: AppText.caption.copyWith(
                          color: const Color(0xFFF3A9A9),
                        ),
                      ),
                    ),
                  GoldButton(
                    key: const Key('delete-submit'),
                    label: _busy ? 'Deleting…' : 'Delete my account',
                    onPressed: (_busy || !_confirmed) ? null : _delete,
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => context.push(LegalRoutes.privacy),
                      child: const Text('Privacy Policy'),
                    ),
                    TextButton(
                      onPressed: () => context.push(LegalRoutes.terms),
                      child: const Text('Terms of Service'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
