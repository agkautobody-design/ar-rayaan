import '../../../app/core/scholar_review.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/core/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../quran/application/quran_providers.dart';
import '../../quran/domain/quran_models.dart';
import '../application/share_service.dart';
import 'share_actions.dart';
import '../../../app/theme/widgets/focus_ring.dart';

class ShareCard {
  final String id, kind, arabic, text, ref;
  const ShareCard({required this.id, required this.kind, required this.arabic,
      required this.text, required this.ref});
  factory ShareCard.fromJson(Map<String, dynamic> j) => ShareCard(
      id: j['id'] as String, kind: j['kind'] as String, arabic: j['arabic'] as String? ?? '',
      text: j['text'] as String, ref: j['ref'] as String);
}


/// VERSE CARDS - shareable light. A Qur'anic verse or hadith, framed in
/// gold, one tap to send it down any road a message can travel.
class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});
  @override
  State<ShareScreen> createState() => _ShareState();
}

class _ShareState extends State<ShareScreen> {
  List<ShareCard>? _cards;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/share/cards.json');
    final d = json.decode(raw) as Map<String, dynamic>;
    setState(() => _cards = (d['cards'] as List<dynamic>)
        .map((e) => ShareCard.fromJson(e as Map<String, dynamic>)).toList());
  }

  static final RegExp _quranRef = RegExp(r'^Qur.an (\d+):(\d+)(?:-(\d+))?$');

  /// The share for [c]. A Qur'an card is shared as its Arabic from the
  /// Qur'an registry plus its reference (no translation); the card's own
  /// Arabic is not used. A hadith card keeps its English, source and the
  /// review label. Null while the registry loads or if the reference is
  /// not a real ayah.
  ShareDoc? _docFor(ShareCard c, AsyncValue<List<Surah>> registry) {
    if (c.kind == 'Hadith') {
      return ShareDoc.hadith(
        english: '\u201c${c.text}\u201d',
        source: c.ref,
        reviewKey: 'noor.card',
      );
    }
    final RegExpMatch? m = _quranRef.firstMatch(c.ref);
    final List<Surah>? all = registry.valueOrNull;
    if (m == null || all == null) return null;
    return ShareService.ayahFromRegistry(
      all,
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      m.group(3) == null ? null : int.parse(m.group(3)!),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cards == null) {
      return const Scaffold(backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator(color: AppColors.gold)));
    }
    final c = _cards![_i];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              const ScreenHeader(title: 'Verse Cards', close: true),
              const ScholarReviewNote(
                reviewKey: 'noor.card',
                padding: EdgeInsets.only(bottom: 8),
              ),
              Consumer(builder: (c, ref, _) {
                final url = ref.watch(appUrlProvider);
                return GlassCard(
                  child: Column(children: [
                    Text('BETA \u00b7 INVITE A TESTER', style: AppText.eyebrow),
                    const SizedBox(height: 6),
                    Text(url, style: AppText.body.copyWith(color: AppColors.goldLight, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: QrImageView(data: url, size: 96),
                    ),
                    const SizedBox(height: 4),
                    Text('ADD TO ANY HOME SCREEN',
                        style: AppText.bodyMuted.copyWith(fontSize: 12)),
                    Text('From a browser\'s menu: Add to Home Screen — it becomes a real app.',
                        style: AppText.bodyMuted.copyWith(fontSize: 12)),
                  ]),
                );
              }),

              const SizedBox(height: 12),
              GlassCard(
                child: Column(children: [
                  Text('INVITE A FRIEND', style: AppText.eyebrow),
                  const SizedBox(height: 6),
                  Text(
                    'See exactly what would be sent first. Nothing is posted '
                    'for you.',
                    style: AppText.bodyMuted.copyWith(fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: FilledButton.icon(
                      key: const Key('invite-friend'),
                      onPressed: () => showSharePreview(
                        context,
                        doc: ShareDoc.invite(),
                        subject: 'this invitation',
                      ),
                      icon: const Icon(Icons.ios_share, size: 18),
                      label: const Text('Invite a friend'),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Center(child: Text('LIGHT, SHARED', style: AppText.eyebrow)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1.4),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 18)],
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0x1405090F), Color(0xFF070C14)]),
                ),
                child: Column(children: [
                  if (c.arabic.isNotEmpty)
                    Text(c.arabic, textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'Amiri', fontSize: 28,
                            height: 1.9, color: Color(0xFFEAD9A8))),
                  if (c.arabic.isNotEmpty) const SizedBox(height: 14),
                  Text('\u201c${c.text}\u201d', textAlign: TextAlign.center,
                      style: AppText.body.copyWith(fontSize: 16.5, height: 1.6)),
                  const SizedBox(height: 10),
                  Text('— ${c.ref}', style: AppText.eyebrow),
                ]),
              ),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < _cards!.length; i++)
                  Semantics(
                    button: true,
                    selected: i == _i,
                    label: 'Card ${i + 1} of ${_cards!.length}',
                    excludeSemantics: true,
                    child: FocusableTap(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() { _i = i; }),
                      // Padding makes the touch area 48 high; the dot stays small.
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 21),
                        child: Container(
                          width: i == _i ? 18 : 6, height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: i == _i ? AppColors.gold
                                : AppColors.sand.withValues(alpha: 0.2)),
                        ),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 18),
              Center(
                child: Consumer(
                  builder: (BuildContext context, WidgetRef ref, Widget? _) {
                    final ShareDoc? doc =
                        _docFor(c, ref.watch(quranAllProvider));
                    return ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: FilledButton.icon(
                        key: const Key('verse-card-share'),
                        onPressed: doc == null
                            ? null
                            : () => showSharePreview(
                                  context,
                                  doc: doc,
                                  subject: 'this card',
                                ),
                        icon: const Icon(Icons.ios_share, size: 18),
                        label: const Text('Share this card'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Center(child: Text('Swipe the dots \u00b7 send one to someone tonight',
                  style: AppText.bodyMuted.copyWith(fontSize: 12))),
            ],
          ),
        ),
      ),
    );
  }
}
