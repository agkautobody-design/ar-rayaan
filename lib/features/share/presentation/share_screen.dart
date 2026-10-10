import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, Clipboard, ClipboardData;
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/screen_header.dart';

class ShareCard {
  final String id, kind, arabic, text, ref;
  const ShareCard({required this.id, required this.kind, required this.arabic,
      required this.text, required this.ref});
  factory ShareCard.fromJson(Map<String, dynamic> j) => ShareCard(
      id: j['id'], kind: j['kind'], arabic: j['arabic'] ?? '',
      text: j['text'], ref: j['ref']);
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
  bool _copied = false;

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

  String get _message {
    final c = _cards![_i];
    final ar = c.arabic.isNotEmpty ? '${c.arabic}\n\n' : '';
    return '$ar\"${c.text}\"\n— ${c.ref}\n\nShared from Ar-Rayaan (ar-rayaan.onrender.com)';
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
                  GestureDetector(
                    onTap: () => setState(() { _i = i; _copied = false; }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: i == _i ? 18 : 6, height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: i == _i ? AppColors.gold
                            : AppColors.sand.withValues(alpha: 0.2)),
                    ),
                  ),
              ]),
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                ElevatedButton.icon(
                  onPressed: () => launchUrl(
                      Uri.parse('https://wa.me/?text=${Uri.encodeComponent(_message)}'),
                      mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.send_outlined, size: 16),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: const Color(0xFF0A0F18)),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _message));
                    setState(() => _copied = true);
                  },
                  icon: Icon(_copied ? Icons.check : Icons.copy, size: 15,
                      color: AppColors.goldLight),
                  label: Text(_copied ? 'Copied' : 'Copy',
                      style: const TextStyle(color: AppColors.goldLight, fontSize: 13)),
                ),
              ]),
              const SizedBox(height: 8),
              Center(child: Text('Swipe the dots \u00b7 send one to someone tonight',
                  style: AppText.bodyMuted.copyWith(fontSize: 11))),
            ],
          ),
        ),
      ),
    );
  }
}
