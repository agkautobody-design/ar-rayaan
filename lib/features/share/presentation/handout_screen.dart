/// A plain, paper-style handout page for teachers and parents. It shows only
/// content that already exists in the app (text, sources, questions). On the
/// web it prints on real pages in a new tab; everywhere it can be copied.
library;

import 'package:flutter/material.dart' hide Text;
import '../../../app/theme/widgets/tr_text.dart';
import 'package:go_router/go_router.dart';

import '../application/web_file_save.dart';
import '../application/web_print.dart';
import '../../reading/presentation/arabic_block.dart' show kLatinLocale, kTranslitMissing;
import '../domain/handout.dart';
import 'share_actions.dart';
import '../application/share_service.dart';

/// Opens the handout page for [data].
void openHandout(BuildContext context, HandoutData data) =>
    context.push('/handout', extra: data);

/// A "Make a handout" button for story and lesson pages.
class MakeHandoutButton extends StatelessWidget {
  const MakeHandoutButton({super.key, required this.makeData});

  /// Builds the handout when the button is tapped.
  final HandoutData Function() makeData;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Make a printable handout',
      child: TextButton.icon(
        key: const Key('make-handout'),
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: () => openHandout(context, makeData()),
        icon: const Icon(Icons.print_outlined, size: 18),
        label: const Text('Make a handout'),
      ),
    );
  }
}

/// A safe file name for a handout: letters and digits, dashes, `.html`.
String handoutFileName(String title) {
  final String slug = title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return '${slug.isEmpty ? 'handout' : slug}.html';
}

class HandoutScreen extends StatelessWidget {
  const HandoutScreen({super.key, this.data});

  final HandoutData? data;

  @override
  Widget build(BuildContext context) {
    final HandoutData? d = data;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Handout'),
      ),
      body: d == null
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nothing to print here yet. Open a story or a lesson and tap '
                '“Make a handout”.',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
            )
          : _Page(data: d),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.data});

  final HandoutData data;

  @override
  Widget build(BuildContext context) {
    const TextStyle body =
        TextStyle(color: Colors.black, fontSize: 16, height: 1.55);
    return DefaultTextStyle(
      style: body,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: <Widget>[
          Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
            if (webPrintSupported)
              FilledButton.icon(
                key: const Key('handout-print'),
                style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () {
                  final bool ok = printHtmlDocument(data.toHtml());
                  if (!ok) {
                    ScaffoldMessenger.maybeOf(context)
                      ?..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(
                        content: Text(
                            'The browser blocked the print page. Allow '
                            'pop-ups for this site, or use Copy.'),
                      ));
                  }
                },
                icon: const Icon(Icons.print_outlined),
                label: const Text('Print'),
              ),
            if (webFileSaveSupported)
              OutlinedButton.icon(
                key: const Key('handout-save'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
                onPressed: () {
                  final bool ok = saveTextFile(
                    handoutFileName(data.title),
                    data.toHtml(),
                  );
                  ScaffoldMessenger.maybeOf(context)
                    ?..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text(ok
                          ? 'Saved to your Downloads folder. Open the file '
                              'in any browser.'
                          : 'The browser would not save the file. Use Copy '
                              'instead.'),
                    ));
                },
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Save to device'),
              ),
            OutlinedButton.icon(
              key: const Key('handout-copy'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => copyWithFeedback(
                context,
                data.toPlainText(),
                message: 'Copied. Paste it into a document to print.',
              ),
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copy'),
            ),
          ]),
          if (!webPrintSupported)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Printing, and saving a handout as a file, are available on the '
                'web version. Here, copy the text and paste it into any '
                'document.',
                style: TextStyle(color: Color(0xFF444444), fontSize: 13),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            data.title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (data.subtitle.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(data.subtitle,
                  style: const TextStyle(color: Color(0xFF444444))),
            ),
          if (data.notice != null && data.notice!.trim().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(border: Border.all()),
              child: Text(data.notice!),
            ),
          for (final HandoutSection s in data.sections) ...<Widget>[
            const SizedBox(height: 16),
            if (s.heading.trim().isNotEmpty)
              Text(s.heading,
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            if (s.arabic != null && s.arabic!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  s.arabic!,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'Amiri',
                      fontSize: 24,
                      height: 1.9),
                ),
              ),
            if (s.arabic != null && s.arabic!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  shareableTranslit(s.translit, s.translitSource) ??
                      kTranslitMissing,
                  key: const Key('handout-translit'),
                  textDirection: TextDirection.ltr,
                  locale: kLatinLocale,
                  style: const TextStyle(
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                      fontSize: 14),
                ),
              ),
            if (s.body.trim().isNotEmpty) Text(s.body),
          ],
          if (data.sources.isNotEmpty) ...<Widget>[
            const SizedBox(height: 20),
            const Text('Sources',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            for (final String s in data.sources)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• $s'),
              ),
          ],
          if (data.questions.isNotEmpty) ...<Widget>[
            const SizedBox(height: 20),
            const Text('To talk about',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            for (int i = 0; i < data.questions.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('${i + 1}. ${data.questions[i]}'),
              ),
          ],
          const SizedBox(height: 24),
          const Text('Shared from Ar-Rayaan',
              style: TextStyle(color: Color(0xFF555555), fontSize: 13)),
        ],
      ),
    );
  }
}
