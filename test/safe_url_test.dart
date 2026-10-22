import 'package:ar_rayaan/app/core/safe_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SafeUrl.web', () {
    test('keeps http and https addresses', () {
      expect(SafeUrl.web('https://masjid.example.org/events')?.toString(),
          'https://masjid.example.org/events');
      expect(SafeUrl.web('http://masjid.example.org')?.toString(),
          'http://masjid.example.org');
      expect(SafeUrl.web('  HTTPS://Masjid.example.org  ')?.host,
          'masjid.example.org');
    });

    test('adds https to an address typed without a scheme', () {
      expect(SafeUrl.web('www.masjid.org')?.toString(), 'https://www.masjid.org');
      expect(SafeUrl.web('masjid.org/prayer')?.toString(),
          'https://masjid.org/prayer');
      expect(SafeUrl.web('www.masjid.org:8080/x')?.toString(),
          'https://www.masjid.org:8080/x');
      expect(SafeUrl.web('//cdn.masjid.org/a')?.toString(),
          'https://cdn.masjid.org/a');
    });

    test('refuses every other scheme', () {
      for (final String bad in <String>[
        'javascript:alert(1)',
        'JavaScript:alert(1)',
        'java\tscript:alert(1)',
        'javascript://%0aalert(1)',
        'data:text/html,<script>alert(1)</script>',
        'file:///etc/passwd',
        'intent://x#Intent;scheme=http;end',
        'mailto:imam@masjid.org',
        'tel:+15551234567',
        'ftp://files.example.org/a',
        'vbscript:msgbox(1)',
        'blob:https://masjid.org/uuid',
      ]) {
        expect(SafeUrl.web(bad), isNull, reason: bad);
      }
    });

    test('refuses junk, spaces, credentials and hostless addresses', () {
      for (final String? bad in <String?>[
        null,
        '',
        '   ',
        'not a url',
        'https://',
        'https:///path',
        'https://localhost/x',
        'https://good.org@evil.example/',
        'https://bad host.org',
        'https://masjid.org/\nx',
        'http://[::1',
      ]) {
        expect(SafeUrl.web(bad), isNull, reason: '$bad');
      }
      expect(SafeUrl.web('https://a.org/${'x' * 3000}'), isNull);
    });
  });

  group('SafeUrl.tel', () {
    test('keeps digits and a leading plus', () {
      expect(SafeUrl.tel('+1 (555) 123-4567')?.toString(), 'tel:+15551234567');
      expect(SafeUrl.tel('020 7946 0958')?.toString(), 'tel:02079460958');
    });

    test('uses the first of several numbers', () {
      expect(SafeUrl.tel('+44 20 7946 0958; +44 20 7946 0000')?.toString(),
          'tel:+442079460958');
    });

    test('refuses anything that is not a phone number', () {
      for (final String? bad in <String?>[
        null,
        '',
        'call us',
        'javascript:alert(1)',
        '12',
        '+1 555 123 4567 ext #9;DROP',
      ]) {
        expect(SafeUrl.tel(bad), isNull, reason: '$bad');
      }
    });
  });
}
