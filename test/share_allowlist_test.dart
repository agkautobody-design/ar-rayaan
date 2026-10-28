import 'dart:io';

import 'package:ar_rayaan/app/core/providers.dart';
import 'package:ar_rayaan/features/share/application/share_service.dart';
import 'package:ar_rayaan/features/share/application/share_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The guard for the public-content share system. Nothing personal may ever
/// leave the app through a share, so the places that can build or start one
/// are listed here, by file. Adding a screen to this list is a decision, and
/// needs the owner's approval of that content kind.
const Set<String> _allowedCallSites = <String>{
  'lib/features/academy/presentation/dua_school_screen.dart',
  'lib/features/academy/presentation/hadith_school_screen.dart',
  'lib/features/academy/presentation/lesson_player_screen.dart',
  'lib/features/academy/presentation/lesson_v3_screen.dart',
  'lib/features/adhkar/presentation/adhkar_screen.dart',
  'lib/features/calendar/presentation/calendar_screen.dart',
  'lib/features/family/presentation/family_tree_screen.dart',
  'lib/features/hadith/presentation/daily_hadith_card.dart',
  'lib/features/hadith/presentation/hadith_screen.dart',
  'lib/features/huda/presentation/huda_screens.dart',
  'lib/features/masjid/presentation/masjid_finder_screen.dart',
  'lib/features/noor/presentation/noor_screen.dart',
  'lib/features/quran/presentation/ayah_actions_sheet.dart',
  'lib/features/stories/presentation/story_reader_screen.dart',
};

/// Folders whose screens are never shareable: the person's own data, family
/// and children, chats, support and crisis, money, tracking, games and the
/// account.
const List<String> _neverShare = <String>[
  'lib/features/academy/presentation/academy_family.dart',
  'lib/features/auth/',
  'lib/features/community/',
  'lib/features/feelings/',
  'lib/features/finance/',
  'lib/features/games/',
  'lib/features/habits/',
  'lib/features/hadi/',
  'lib/features/journey/',
  'lib/features/kids/',
  'lib/features/lamha/',
  'lib/features/majlis/',
  'lib/features/notes/',
  'lib/features/onboarding/',
  'lib/features/prayer/',
  'lib/features/profile/',
  'lib/features/qibla/',
  'lib/features/ramadan/',
  'lib/features/sakina/',
  'lib/features/search/',
  'lib/features/settings/',
  'lib/features/support/',
  'lib/features/tasbeeh/',
  'lib/features/tracking/',
  'lib/features/zakat/',
];

/// Names that start a share or build one. A file that uses any of them must
/// be on [_allowedCallSites] (or be inside lib/features/share/).
final RegExp _shareApi = RegExp(
  r'\b(ShareService|ShareDoc|ShareButton|showSharePreview|SharePreviewSheet)\b',
);

List<File> _dartFiles(String dir) => <File>[
      for (final FileSystemEntity f in Directory(dir).listSync(recursive: true))
        if (f is File && f.path.endsWith('.dart')) f,
    ];

String _p(File f) => f.path.replaceAll('\\', '/');

void main() {
  test('the allowed kinds are exactly the approved public ones', () {
    expect(
      ShareKind.values.map((ShareKind k) => k.name).toList(),
      <String>[
        'ayah',
        'hadith',
        'dua',
        'dhikr',
        'story',
        'treePerson',
        'lesson',
        'calendarOccasion',
        'mosque',
        'halalPlace',
        'guide',
        'invite',
      ],
    );
  });

  test('ShareService is used only from the allowed screens', () {
    final List<String> bad = <String>[];
    for (final File f in _dartFiles('lib')) {
      final String path = _p(f);
      if (path.startsWith('lib/features/share/')) continue;
      if (_shareApi.hasMatch(f.readAsStringSync()) &&
          !_allowedCallSites.contains(path)) {
        bad.add(path);
      }
    }
    expect(bad, isEmpty, reason: 'not on the allow-list:\n${bad.join('\n')}');
  });

  test('every allowed call site still exists and really shares', () {
    for (final String path in _allowedCallSites) {
      final File f = File(path);
      expect(f.existsSync(), isTrue, reason: path);
      expect(_shareApi.hasMatch(f.readAsStringSync()), isTrue, reason: path);
    }
  });

  test('personal, family, chat, support, money and game screens never share',
      () {
    final List<String> bad = <String>[];
    for (final File f in _dartFiles('lib')) {
      final String path = _p(f);
      if (!_neverShare.any(path.startsWith)) continue;
      final String src = f.readAsStringSync();
      if (_shareApi.hasMatch(src) || src.contains('share_service.dart')) {
        bad.add(path);
      }
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('Hadi keeps Copy only: it never imports the share service', () {
    final String hadi =
        File('lib/features/hadi/presentation/hadi_screen.dart')
            .readAsStringSync();
    expect(_shareApi.hasMatch(hadi), isFalse);
    expect(hadi.contains('share_service.dart'), isFalse);
  });

  test('share code imports nothing about the person, family, chats or place',
      () {
    final List<File> shareCode = <File>[
      File('lib/features/share/application/share_service.dart'),
      File('lib/features/share/application/share_text.dart'),
      File('lib/features/share/presentation/share_actions.dart'),
    ];
    // Only these imports are allowed: public content models, the review
    // label, Flutter and the share package, and the two gates (Elder Mode
    // tap size, child mode off-switch) that read a setting but send nothing.
    final RegExp forbidden = RegExp(
      r'''import\s+['"][^'"]*(shared_preferences|geolocator|firebase|cloud_firestore|'''
      r'''features/(family|kids|hadi|sakina|support|feelings|habits|tracking|'''
      r'''profile|auth|notes|community|majlis|games|journey|finance|zakat|'''
      r'''prayer|qibla|academy|lamha|settings|search|onboarding|downloads)/|'''
      r'''quran_marks|hadith_marks|providers\.dart|memory|conversation|chat)[^'"]*['"]''',
    );
    for (final File f in shareCode) {
      final String src = f.readAsStringSync();
      for (final RegExpMatch m in forbidden.allMatches(src)) {
        fail('${_p(f)} imports ${m.group(0)}');
      }
      expect(src.contains('SharedPreferences'), isFalse, reason: _p(f));
    }
  });

  test('old public paths are gone: milestones, raw strings, direct WhatsApp',
      () {
    final List<String> bad = <String>[];
    for (final File f in _dartFiles('lib')) {
      final String path = _p(f);
      final String src = f.readAsStringSync();
      for (final String gone in <String>[
        'milestoneShareText',
        'composeShareText',
        'ShareCopyButtons',
        'ShareCardButton',
        'shareWithFeedback',
        'inviteShareText',
        'Share this lesson',
        'quiet-done-share',
        'lesson-share',
        'I completed',
      ]) {
        if (src.contains(gone)) bad.add('$path: $gone');
      }
      if (!path.startsWith('lib/features/share/') &&
          (src.contains('wa.me') || src.contains('navigator.share'))) {
        bad.add('$path: direct WhatsApp / web share');
      }
    }
    expect(bad, isEmpty, reason: bad.join('\n'));
  });

  test('no Arabic is typed in the share code', () {
    final RegExp arabic = RegExp('[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]');
    for (final String path in <String>[
      'lib/features/share/application/share_service.dart',
      'lib/features/share/application/share_text.dart',
      'lib/features/share/presentation/share_actions.dart',
    ]) {
      expect(arabic.hasMatch(File(path).readAsStringSync()), isFalse,
          reason: path);
    }
  });

  test('the share code never references an image or a prophet depiction', () {
    for (final String path in <String>[
      'lib/features/share/application/share_service.dart',
      'lib/features/share/presentation/share_actions.dart',
      'lib/features/family/data/family_tree_provider.dart',
    ]) {
      final String src = File(path).readAsStringSync();
      expect(src.contains('assets/images'), isFalse, reason: path);
      expect(src.contains('Image.asset'), isFalse, reason: path);
      expect(src.contains('RepaintBoundary'), isFalse, reason: path);
    }
    final String tree = File(
      'lib/features/family/presentation/family_tree_screen.dart',
    ).readAsStringSync();
    expect(tree.contains('Image.'), isFalse);
    expect(tree.contains('AssetImage'), isFalse);
  });

  test('the shared link is one constant, and the QR default is the same', () {
    expect(kInviteUrl, 'https://ar-rayaan.onrender.com');
    final ProviderContainer c = ProviderContainer();
    addTearDown(c.dispose);
    // Without an APP_URL define (as in CI) the QR and the text agree.
    expect(c.read(appUrlProvider), kInviteUrl);
    // No other file spells the address out.
    final List<String> bad = <String>[];
    for (final File f in _dartFiles('lib')) {
      final String path = _p(f);
      if (path == 'lib/features/share/application/share_text.dart') continue;
      // An HTTP-Referer header for the AI provider, not a shared link.
      if (path == 'lib/features/hadi/data/groq_hadi_provider.dart') continue;
      if (f.readAsStringSync().contains('ar-rayaan.onrender.com')) {
        bad.add(path);
      }
    }
    expect(bad, isEmpty,
        reason: 'the address belongs in share_text.dart only:\n'
            '${bad.join('\n')}');
  });

  test('the checksums of the content packs are untouched', () {
    expect(
      File('lib/features/academy/data/player_catalog_pack.dart')
          .readAsStringSync(),
      contains(
        "const String kCatalogSha256 = "
        "'baae1a1576a7eff5d85adc2054c712424c100dbba2ad54c384992d501f285181';",
      ),
    );
    expect(
      File('lib/features/academy/data/word_deck_repository.dart')
          .readAsStringSync(),
      contains(
        "'0d5cf6ff1fefd072b07d8d2f2ea93a7bde947e4836030f1e83b4883638bf64c7'",
      ),
    );
  });
}
