import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/screen_header.dart';

/// On-device notes — private by design, nothing ever leaves the device.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  static const _pref = 'ar.notes';
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pref);
    if (raw != null && raw.isNotEmpty) {
      setState(() {
        _notes = (json.decode(raw) as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pref, json.encode(_notes));
  }

  Future<void> _add() async {
    final title = TextEditingController();
    final body = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0F18),
        title: Text('New note', style: AppText.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              style: AppText.body,
              decoration: const InputDecoration(hintText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: body,
              style: AppText.body,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Your note…'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save',
                style: TextStyle(color: AppColors.goldLight)),
          ),
        ],
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty) {
      setState(() {
        _notes.insert(0, {
          'title': title.text.trim(),
          'body': body.text.trim(),
          'at': DateTime.now().toIso8601String(),
        });
      });
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.gold,
        foregroundColor: const Color(0xFF0A0F18),
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const ScreenHeader(title: 'Notes', close: true),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('ON THIS DEVICE ONLY', style: AppText.eyebrow),
          ),
          if (_notes.isEmpty)
            GlassCard(
              child: Text(
                'No notes yet. Tap + to write your first — an ayah that moved you, a dua to remember, a lesson from a story.',
                style: AppText.bodyMuted,
              ),
            )
          else
            for (final n in _notes)
              Padding(
                key: ValueKey(n['at'] as String),
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(n['title'] as String,
                                style: AppText.titleMedium),
                          ),
                          GestureDetector(
                            onTap: () async {
                              setState(() => _notes.remove(n));
                              await _save();
                            },
                            child: const Icon(Icons.delete_outline,
                                size: 16, color: AppColors.sand),
                          ),
                        ],
                      ),
                      if ((n['body'] as String).isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(n['body'] as String,
                            style: AppText.bodyMuted.copyWith(height: 1.5)),
                      ],
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Offline content aboard the device — and what's coming.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  static const _packs = [
    ('The Qur\u2019an — complete text', 'assets/quran/quran.json'),
    ('Stories library — all collections', 'assets/stories/'),
    ('Prophet lineage — the Messengers\u2019 Tree', 'assets/family/tree.json'),
    ('Huda — 40 worship guides', 'assets/guides/guides.json'),
    ('Daily Duas — 18 with Arabic', 'assets/stories/dailyduas.json'),
    ('Games — trivia bank + the 99 Names', 'assets/games/'),
    ('Hadiths for Our Times', 'assets/stories/modernhadith.json'),
    ('Feelings — the guided paths', 'assets/feelings/feelings.json'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          const ScreenHeader(title: 'Downloads', close: true),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('ALREADY ABOARD — WORKS OFFLINE', style: AppText.eyebrow),
          ),
          for (final p in _packs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.gold, size: 18),
                    const SizedBox(width: 12),
                    Expanded(child: Text(p.$1, style: AppText.body)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 10),
          GlassCard(
            strong: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('COMING WITH THE VAULT', style: AppText.eyebrow),
                const SizedBox(height: 6),
                Text(
                  'Recitation audio packs (multiple reciters) and tafsir depth arrive with the Quran Foundation vault — the keys are already collected.',
                  style: AppText.bodyMuted.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
