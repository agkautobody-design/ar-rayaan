/// Add a poem or naat of your own: the words, optionally their meaning in
/// another language, and optionally a direct link to audio. Kept on this
/// phone only.
library;

import 'package:flutter/material.dart' hide Text;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/widgets/glass_card.dart';
import '../../../app/theme/widgets/scenic_background.dart';
import '../../../app/theme/widgets/screen_header.dart';
import '../../../app/theme/widgets/tr_text.dart';
import '../application/user_poems_provider.dart';
import '../domain/user_poem.dart';

class AddPoemScreen extends ConsumerStatefulWidget {
  const AddPoemScreen({super.key});

  @override
  ConsumerState<AddPoemScreen> createState() => _AddPoemScreenState();
}

class _AddPoemScreenState extends ConsumerState<AddPoemScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _words = TextEditingController();
  final TextEditingController _meaning = TextEditingController();
  final TextEditingController _audio = TextEditingController();
  String _lang = 'ar';
  String _mLang = 'en';
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _words.dispose();
    _meaning.dispose();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final List<String> lines = parsePoemLines(_words.text);
    final List<String> meanings = parsePoemLines(_meaning.text);
    final String audio = _audio.text.trim();
    String? error;
    if (_title.text.trim().isEmpty) {
      error = 'Give it a title.';
    } else if (lines.isEmpty) {
      error = 'Write the words, one line on each row.';
    } else if (meanings.length > lines.length) {
      error = 'There are more meaning lines than lines of words.';
    } else if (audio.isNotEmpty && !audio.startsWith('http')) {
      error = 'An audio link starts with https://';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final String id = await ref
        .read(userPoemsProvider.notifier)
        .add(
          title: _title.text,
          lang: _lang,
          lines: lines,
          meaningLang: _mLang,
          meanings: meanings,
          audioUrl: audio.isEmpty ? null : audio,
        );
    if (!mounted) return;
    context.pushReplacement('${AppRoutes.naatWords}/$id');
  }

  Widget _langChips(String selected, String prefix, void Function(String) on) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final MapEntry<String, String> e in kUserPoemLanguages.entries)
          ChoiceChip(
            key: Key('$prefix-${e.key}'),
            label: Text(e.value),
            selected: selected == e.key,
            onSelected: (_) => setState(() => on(e.key)),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScenicScaffold.pattern(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: <Widget>[
              const ScreenHeader(title: 'Add a poem'),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Add a poem or naat of your own. It stays on this '
                        'phone, is marked as yours, and the app does not '
                        'check it. Only add words you have the right to use.',
                        style: AppText.bodyMuted.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('poem-title'),
                        controller: _title,
                        style: AppText.body,
                        decoration: const InputDecoration(labelText: 'Title *'),
                      ),
                      const SizedBox(height: 12),
                      Text('The words are in', style: AppText.label),
                      const SizedBox(height: 6),
                      _langChips(_lang, 'poem-lang', (String k) => _lang = k),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('poem-words'),
                        controller: _words,
                        style: AppText.body,
                        minLines: 4,
                        maxLines: 12,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          labelText: 'The words * (one line on each row)',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('The meaning is in', style: AppText.label),
                      const SizedBox(height: 6),
                      _langChips(_mLang, 'poem-mlang', (String k) => _mLang = k),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('poem-meaning'),
                        controller: _meaning,
                        style: AppText.body,
                        minLines: 3,
                        maxLines: 12,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          labelText: 'The meaning, line for line (optional)',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('poem-audio'),
                        controller: _audio,
                        style: AppText.body,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Link to your own audio (https://…)',
                          hintText: 'optional',
                        ),
                      ),
                      if (_error != null) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(
                          _error!,
                          key: const Key('poem-error'),
                          style: AppText.body.copyWith(color: AppColors.gold),
                        ),
                      ],
                      const SizedBox(height: 14),
                      FilledButton(
                        key: const Key('poem-save'),
                        onPressed: _save,
                        child: Text('Save poem'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
