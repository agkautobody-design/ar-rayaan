import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/gold_button.dart';
import '../../academy/domain/children_privacy.dart';
import '../../auth/application/auth_providers.dart';
import '../legal_routes.dart';

/// Shown at the top of both documents so nobody mistakes a draft for a
/// reviewed legal text.
const String kLegalDraftNotice =
    'DRAFT — two things are still pending before a public store release: '
    'a lawyer has not reviewed this text, and the contact address below is '
    'not published yet. Until then, this describes honestly what the app '
    'does today.';

/// What the contact address says until the owner publishes a real one
/// (docs/OWNER_ACTIONS.md, item 6). Never invent an address here.
const String kLegalContactPending =
    'not published yet (pending before the public release)';

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
    'Who may use the app',
    'Ar-Rayaan is for people aged 13 or over (or the age of digital '
        'consent where you live) who create an account themselves. Younger '
        'children use the app only through a parent or guardian, who sets '
        'up a child\u2019s learning profile in the Family Wing; a child never '
        'needs an account.',
  ),
  LegalSection(
    'Google services at start-up',
    'When this version of the app is connected to our Firebase project '
        '(Google), the Firebase software starts every time the app opens, '
        'before you sign in or send anything. We do not send your reading, '
        'progress or messages at that point, but Google can see your IP '
        'address if the software contacts its servers. Firebase is used for '
        'accounts, Hadi answer reports, online game tables (only when a '
        'grown-up switches them on) and, once it opens, the Majlis.',
  ),
  LegalSection(
    'Your account',
    'You are responsible for what you do with your account and for keeping '
        'your password private. You can delete your account at any time '
        'from the Delete account screen. An account only identifies you '
        'when you sign in: your progress, bookmarks and settings are kept on '
        'your device and are not backed up to the account, so clearing the '
        'app\u2019s data removes them.',
  ),
  LegalSection(
    'The Majlis (community)',
    'The Majlis is not open yet. Once it opens, posts in it are public and '
        'shown with the display name you '
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
        'applies. Contact address: $kLegalContactPending.',
  ),
];

const List<LegalSection> kPrivacySections = <LegalSection>[
  LegalSection(
    'What stays on your device',
    'Your settings, bookmarks, progress, reflections and any AI key you '
        'enter are stored on your device. Hadi does not save your '
        'conversations: they stay on screen for this visit only and are gone '
        'when you leave, clear them or close the app. You can clear what is '
        'stored by clearing the app\'s data or by removing the key in Hadi '
        'settings.',
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
        'about you. The account does not back up your progress or '
        'bookmarks: those stay on your device.',
  ),
  LegalSection(
    'Reports about a Hadi answer',
    'If you choose \u201cReport this answer\u201d, the text of that answer '
        '(shortened to 1,200 characters), the reason you pick, the passages '
        'it showed, whether it came from the offline library or an AI '
        'provider, and your question only if you tick \u201cInclude my '
        'question\u201d, are sent to our Firebase Firestore database '
        '(Google), using an anonymous sign-in number that is not linked to '
        'your name or email. We use reports only to correct Hadi. If you '
        'are offline the report is kept on your device and sent the next '
        'time the app opens with a connection; reports are never sent '
        'unless you press Send.',
  ),
  LegalSection(
    'The Majlis',
    'The Majlis is not open yet. Once it opens, what you post in it (title, text, display name and an '
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
        'service). When you play a YouTube or Spotify track in the Player, '
        'that service\u2019s player loads inside the app, receives your IP '
        'address, may set cookies and may show its own advertising; it '
        'loads only when you press play. '
        'The fonts for English, Arabic and Bangla are part of the app. '
        'Only for a rare character none of them contains (an emoji, or a '
        'script such as Chinese), your browser may fetch a fallback font '
        'from Google (fonts.gstatic.com), which reveals your IP address to '
        'Google. Each has its own privacy policy.',
  ),
  LegalSection(
    'Sharing',
    'You can share a verse, hadith, du\u2019a, story, lesson text, guide, '
        'calendar occasion or a mosque or restaurant listing. You always see '
        'exactly what will be sent first, and nothing is sent until you '
        'choose an app to send it with. A share contains only that public '
        'content and a link to the app: never your name, your location, '
        'your notes, your progress, your saved items or anything from a '
        'conversation, and nothing about children. The link is the same for '
        'everyone and carries no code, so we receive nothing about who you '
        'send it to. Once a share leaves the app, the app you send it with '
        'handles it under its own policy.',
  ),
  LegalSection(
    'We do not sell your data',
    'We do not sell personal data or show advertising based on it.',
  ),
  LegalSection(
    'Your choices',
    'You can delete your account from the Delete account screen, clear '
        'local data from your device settings, and ask us about any data '
        'we hold about you. Contact address: $kLegalContactPending.',
  ),
  LegalSection(kChildrenPrivacyTitle, kChildrenPrivacyBody),
  LegalSection(
    'Kids Corner',
    'Kids Corner is a page of big buttons for a child to use with a grown-up '
        'beside them. It asks for no name and no account. While it is open '
        'the Settings button and the Ask Hadi button are not shown, and '
        'leaving it, opening the games, or leaving the Child track of the '
        'Academy asks for the parent PIN. The PIN is 4 to 6 digits that a '
        'parent chooses the first time it is asked for. Only a scrambled '
        '(salted SHA-256) form of it is kept, on this device; it is never '
        'sent anywhere. Five wrong tries lock it for five minutes, and once '
        'entered it stays open for two minutes.\n\n'
        'Child mode, which a parent can turn on from Kids Corner or the '
        'Family Wing, goes further: the rest of the app (menus, Settings, '
        'Ask Hadi, marriage and family life, finance, community, the Qur\u2019an '
        'and hadith readers, games and the other Academy schools) cannot be '
        'opened, and every other address leads back to Kids Corner. Only the '
        'Arabic letters and the stories school remain. The PIN turns it off. '
        'The PIN is a barrier for a child, not a vault against a determined '
        'adult with the device: clearing the browser\u2019s site data for '
        'Ar-Rayaan removes it, along with everything else stored on the device.',
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
                    IconButton(tooltip: 'Back',
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
                    IconButton(tooltip: 'Back',
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
                    Semantics(label: 'Enter your password to confirm', child: TextField(
                      key: const Key('delete-password'),
                      controller: _password,
                      obscureText: true,
                      style: AppText.body,
                      decoration: const InputDecoration(
                        hintText: 'Enter your password to confirm',
                      ),
                    ))
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
