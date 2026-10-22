/// Validation for addresses that come from data the app does not control
/// (free-text OpenStreetMap tags, content packs) before they are handed to
/// the operating system or browser to open.
///
/// Only absolute http and https web addresses with a real host are ever
/// returned. `javascript:`, `data:`, `file:`, `intent:` and every other
/// scheme are refused, and an address typed without a scheme (`www.x.org`)
/// gets `https://`, so it can not resolve relative to the app's own origin.
class SafeUrl {
  const SafeUrl._();

  static const int _maxLength = 2048;

  static final RegExp _bareScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+\-]*:');

  /// A safe web address for [raw], or null when there is none.
  static Uri? web(String? raw) {
    if (raw == null) return null;
    final String t = raw.trim();
    if (t.isEmpty || t.length > _maxLength) return null;
    for (final int c in t.runes) {
      // No spaces, tabs, newlines or other control characters anywhere.
      if (c <= 0x20 || c == 0x7f) return null;
    }
    final String candidate;
    if (t.startsWith('//')) {
      candidate = 'https:$t';
    } else if (t.contains('://')) {
      candidate = t;
    } else if (_bareScheme.hasMatch(t)) {
      // javascript:, data:, mailto:, tel:, intent: ... (a dotted name such
      // as www.x.org:8080 is a host with a port, not a scheme).
      return null;
    } else {
      candidate = 'https://$t';
    }
    final Uri? u = Uri.tryParse(candidate);
    if (u == null) return null;
    final String scheme = u.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    if (u.userInfo.isNotEmpty) return null;
    final String host = u.host;
    if (host.isEmpty || !host.contains('.') || host.endsWith('.')) return null;
    return u;
  }

  /// A `tel:` address for a free-text phone number, or null. Only digits
  /// and a leading plus survive; when several numbers are listed (separated
  /// by `;` or `/`) the first is used.
  static Uri? tel(String? raw) {
    if (raw == null) return null;
    final String first = raw.split(RegExp(r'[;/]')).first.trim();
    final String cleaned = first.replaceAll(RegExp(r'[\s().\-]'), '');
    if (!RegExp(r'^\+?\d{5,16}$').hasMatch(cleaned)) return null;
    return Uri(scheme: 'tel', path: cleaned);
  }
}
