/// A small, safe Markdown reader for Hādi's replies. Pure Dart, so it is
/// tested without a widget tree.
///
/// It understands only what a chat reply needs: `**bold**`, `*italic*`,
/// `-`/`*`/`•` bullets, `1.` numbered items and `#` headings (shown bold).
/// Everything else is plain text. It never reads links, images or HTML, so a
/// reply can not carry anything but words.
library;

/// One run of text with its emphasis.
class MdSpan {
  const MdSpan(this.text, {this.bold = false, this.italic = false});

  final String text;
  final bool bold;
  final bool italic;

  @override
  bool operator ==(Object other) =>
      other is MdSpan &&
      other.text == text &&
      other.bold == bold &&
      other.italic == italic;

  @override
  int get hashCode => Object.hash(text, bold, italic);

  @override
  String toString() => 'MdSpan($text${bold ? ', bold' : ''}'
      '${italic ? ', italic' : ''})';
}

enum MdKind { paragraph, bullet, numbered, heading }

/// One line of a reply: a paragraph line, a list item or a heading.
class MdBlock {
  const MdBlock(
    this.kind,
    this.spans, {
    this.marker = '',
    this.blankBefore = false,
  });

  final MdKind kind;
  final List<MdSpan> spans;

  /// `•` for a bullet, `1.` for a numbered item, empty otherwise.
  final String marker;

  /// True when an empty line came before this one in the reply.
  final bool blankBefore;

  /// The block's text without any markers.
  String get plain => spans.map((MdSpan s) => s.text).join();
}

abstract final class HadiMarkdown {
  static final RegExp _heading = RegExp(r'^\s{0,3}#{1,6}\s+(\S.*)$');
  static final RegExp _bullet = RegExp(r'^\s{0,6}[-*•]\s+(\S.*)$');
  static final RegExp _numbered = RegExp(r'^\s{0,6}(\d{1,2})[.)]\s+(\S.*)$');

  /// `**bold**` or `*italic*`. Emphasis must hug its words (no space just
  /// inside the marks), and a lone `*` next to a letter or digit (as in
  /// `2*3`) is left alone.
  static final RegExp _inline = RegExp(
    r'\*\*(?=\S)([^\n]+?)(?<=\S)\*\*|'
    r'(?<![\w*])\*(?=[^\s*])([^*\n]+?)(?<=[^\s*])\*(?![\w*])',
  );

  /// Splits [text] into blocks. Blank lines are not blocks: they set
  /// [MdBlock.blankBefore] on the next one.
  static List<MdBlock> parse(String text) {
    final List<MdBlock> out = <MdBlock>[];
    bool blank = false;
    for (final String raw in text.replaceAll('\r', '').split('\n')) {
      final String line = raw.trimRight();
      if (line.trim().isEmpty) {
        blank = out.isNotEmpty;
        continue;
      }
      final RegExpMatch? h = _heading.firstMatch(line);
      final RegExpMatch? b = _bullet.firstMatch(line);
      final RegExpMatch? n = _numbered.firstMatch(line);
      if (h != null) {
        out.add(MdBlock(
          MdKind.heading,
          <MdSpan>[
            for (final MdSpan s in inline(h.group(1)!))
              MdSpan(s.text, bold: true, italic: s.italic),
          ],
          blankBefore: blank,
        ));
      } else if (b != null) {
        out.add(MdBlock(
          MdKind.bullet,
          inline(b.group(1)!),
          marker: '•',
          blankBefore: blank,
        ));
      } else if (n != null) {
        out.add(MdBlock(
          MdKind.numbered,
          inline(n.group(2)!),
          marker: '${n.group(1)}.',
          blankBefore: blank,
        ));
      } else {
        out.add(MdBlock(
          MdKind.paragraph,
          inline(line.trim()),
          blankBefore: blank,
        ));
      }
      blank = false;
    }
    return out;
  }

  /// [s] as runs of plain, bold and italic text.
  static List<MdSpan> inline(String s) {
    final List<MdSpan> out = <MdSpan>[];
    int at = 0;
    for (final RegExpMatch m in _inline.allMatches(s)) {
      if (m.start > at) out.add(MdSpan(s.substring(at, m.start)));
      final String? bold = m.group(1);
      if (bold != null) {
        out.add(MdSpan(bold, bold: true));
      } else {
        out.add(MdSpan(m.group(2)!, italic: true));
      }
      at = m.end;
    }
    if (at < s.length) out.add(MdSpan(s.substring(at)));
    return out;
  }

  /// [text] with the markup removed and list markers kept, for reading
  /// aloud and for copying.
  static String plain(String text) {
    final StringBuffer b = StringBuffer();
    final List<MdBlock> blocks = parse(text);
    for (int i = 0; i < blocks.length; i++) {
      final MdBlock k = blocks[i];
      if (i > 0) b.write(k.blankBefore ? '\n\n' : '\n');
      if (k.marker.isNotEmpty) b.write('${k.marker} ');
      b.write(k.plain);
    }
    return b.toString();
  }

  static bool _isArabicLetter(int r) =>
      (r >= 0x0600 && r <= 0x06FF) ||
      (r >= 0x0750 && r <= 0x077F) ||
      (r >= 0xFB50 && r <= 0xFDFF) ||
      (r >= 0xFE70 && r <= 0xFEFF);

  static bool _isLatinLetter(int r) =>
      (r >= 0x41 && r <= 0x5A) ||
      (r >= 0x61 && r <= 0x7A) ||
      (r >= 0xC0 && r <= 0x24F);

  /// True when most of the letters in [text] are Arabic-script (Arabic or
  /// Urdu), so it should be laid out right to left. Mixed text with more
  /// Latin letters stays left to right.
  static bool isMostlyRtl(String text) {
    int arabic = 0;
    int latin = 0;
    for (final int r in text.runes) {
      if (_isArabicLetter(r)) {
        arabic++;
      } else if (_isLatinLetter(r)) {
        latin++;
      }
    }
    return arabic > 0 && arabic > latin;
  }
}
