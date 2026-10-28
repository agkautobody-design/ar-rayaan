/// A printable handout made only from content that already exists in the app:
/// its text, its source lines and its reflection questions. Nothing is added.
library;

import '../../../app/core/scholar_review.dart';
import '../application/share_text.dart';

class HandoutSection {
  const HandoutSection({
    this.heading = '',
    this.arabic,
    this.translit,
    this.translitSource,
    required this.body,
  });

  final String heading;
  final String? arabic;

  /// Transliteration of [arabic] and where it came from. The handout prints it
  /// only when it may travel (see `shareableTranslit`); otherwise it says none
  /// is available yet.
  final String? translit;
  final String? translitSource;
  final String body;
}

class HandoutData {
  const HandoutData({
    required this.title,
    this.subtitle = '',
    this.notice,
    required this.sections,
    this.sources = const <String>[],
    this.questions = const <String>[],
    this.reviewKey,
  });

  final String title;
  final String subtitle;

  /// An honesty note that must travel with the content (for example that a
  /// story is unverified).
  final String? notice;
  final List<HandoutSection> sections;
  final List<String> sources;
  final List<String> questions;

  /// Register id of the content, when it has one. The handout then carries
  /// the fixed "Scholar review needed" label (or the sign-off).
  final String? reviewKey;

  /// Plain text for Copy: same order as the page.
  String toPlainText() {
    final StringBuffer b = StringBuffer(title.trim());
    if (subtitle.trim().isNotEmpty) b.write('\n${subtitle.trim()}');
    if (notice != null && notice!.trim().isNotEmpty) {
      b.write('\n\n${notice!.trim()}');
    }
    for (final HandoutSection s in sections) {
      b.write('\n');
      if (s.heading.trim().isNotEmpty) b.write('\n${s.heading.trim()}');
      if (s.arabic != null && s.arabic!.trim().isNotEmpty) {
        b.write('\n${s.arabic!.trim()}');
      }
      if (s.body.trim().isNotEmpty) b.write('\n${s.body.trim()}');
    }
    if (sources.isNotEmpty) {
      b.write('\n\nSources');
      for (final String s in sources) {
        b.write('\n- ${s.trim()}');
      }
    }
    if (questions.isNotEmpty) {
      b.write('\n\nTo talk about');
      for (int i = 0; i < questions.length; i++) {
        b.write('\n${i + 1}. ${questions[i].trim()}');
      }
    }
    if (reviewKey != null) b.write('\n\n${scholarReviewText(reviewKey!)}');
    b.write('\n\n${shareFooter()}');
    return b.toString();
  }

  /// A small, self-contained, print-styled HTML page (web print window).
  String toHtml() {
    final StringBuffer b = StringBuffer()
      ..write('<!doctype html><html><head><meta charset="utf-8">')
      ..write('<title>${escapeHtml(title)}</title><style>')
      ..write('body{font-family:Georgia,serif;color:#000;background:#fff;')
      ..write('max-width:42em;margin:2em auto;padding:0 1em;line-height:1.55}')
      ..write('h1{font-size:1.7em;margin:0 0 .2em}')
      ..write('h2{font-size:1.15em;margin:1.2em 0 .3em}')
      ..write('.sub{color:#444;margin:0 0 1em}')
      ..write('.note{border:1px solid #000;padding:.5em .7em;margin:1em 0}')
      ..write('.ar{font-size:1.6em;direction:rtl;text-align:right;')
      ..write('line-height:1.9;margin:.5em 0}')
      ..write('p{margin:.4em 0;white-space:pre-wrap}')
      ..write('ol li{margin:.5em 0}')
      ..write('.lines{border-bottom:1px solid #888;height:1.8em}')
      ..write('.credit{margin-top:2em;color:#555;font-size:.85em}')
      ..write('@media print{body{margin:0}}')
      ..write('</style></head><body>')
      ..write('<h1>${escapeHtml(title)}</h1>');
    if (subtitle.trim().isNotEmpty) {
      b.write('<p class="sub">${escapeHtml(subtitle)}</p>');
    }
    if (notice != null && notice!.trim().isNotEmpty) {
      b.write('<div class="note">${escapeHtml(notice!)}</div>');
    }
    for (final HandoutSection s in sections) {
      if (s.heading.trim().isNotEmpty) {
        b.write('<h2>${escapeHtml(s.heading)}</h2>');
      }
      if (s.arabic != null && s.arabic!.trim().isNotEmpty) {
        b.write('<div class="ar" lang="ar">${escapeHtml(s.arabic!)}</div>');
      }
      if (s.body.trim().isNotEmpty) {
        b.write('<p>${escapeHtml(s.body)}</p>');
      }
    }
    if (sources.isNotEmpty) {
      b.write('<h2>Sources</h2><ul>');
      for (final String s in sources) {
        b.write('<li>${escapeHtml(s)}</li>');
      }
      b.write('</ul>');
    }
    if (questions.isNotEmpty) {
      b.write('<h2>To talk about</h2><ol>');
      for (final String q in questions) {
        b.write('<li>${escapeHtml(q)}<div class="lines"></div></li>');
      }
      b.write('</ol>');
    }
    if (reviewKey != null) {
      b.write('<p class="note">${escapeHtml(scholarReviewText(reviewKey!))}</p>');
    }
    b.write(
      '<p class="credit">${escapeHtml(kSharedFromLine)}. '
      '${escapeHtml(kShareDownloadLine)}: ${escapeHtml(kInviteUrl)}</p>',
    );
    b.write('</body></html>');
    return b.toString();
  }
}

/// Escapes text for HTML so nothing in app content can become markup.
String escapeHtml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
