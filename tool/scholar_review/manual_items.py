"""Items that exist in the audit and fix reports (or in owner decisions) and
have no single data record to mine. Each carries the report that raised it.
Nothing here changes any religious content.
"""
import re

from rg import ARABIC, CLIN, FIQH, HADITH, LAWYER, NATIVE, RIGHTS, WOMEN


def add_all(R):
    def add(id, area, where, file, key, what, why, rev, src, pr='normal', also=(), sub='', surf=''):
        R.add(id=id, area=area, subarea=sub, where_app=where, file=file, key=key, what=what, why=why,
              reviewer=rev, also=also, source=src, priority=pr, label_surface=surf)

    # ------------------------------------------------ Qur'an text and licences
    add('quran.saheeh-licence', 'quran-text', "Qur'an reader > English translation; Our Sources; share and copy",
        'assets/quran/translations/en.*.json; docs/content_needed/CLEAR_QURAN_PACK.md', 'Saheeh International licence',
        "Whether the bundled Saheeh International English text may be distributed, copied and shared inside the app.",
        'FIX_QURAN_HADITH_REPORT: licence UNCONFIRMED (Tanzil terms: translations non-commercial, permission from the translator or publisher needed). '
        'No permission statement in the repo. This is a rights question, not a scholar question.',
        RIGHTS, ['FIX_QURAN_HADITH_REPORT (Saheeh licence unconfirmed)', 'docs/OWNER_ACTIONS.md item 5'], 'high', sub='licence',
        surf='Sources screen and translation credit')
    add('quran.clear-quran-pack', 'quran-text', "Qur'an reader > default English translation",
        'docs/content_needed/CLEAR_QURAN_PACK.md', 'The Clear Quran pack',
        "The publisher's written authorisation for The Clear Quran (distribution, offline use, sharing, credit line), and the text file itself, which is not in the repo.",
        'The app is built to use The Clear Quran by default but ships the interim translation until the file and the authorisation exist.',
        RIGHTS, ['docs/content_needed/CLEAR_QURAN_PACK.md', 'docs/OWNER_ACTIONS.md item 5'], 'high', sub='licence')
    add('quran.foundation-terms', 'quran-text', "Qur'an reader; translations fetched online",
        'docs/OWNER_ACTIONS.md', 'Quran Foundation terms (11 Oct 2026)',
        'Quran Foundation terms forbid bundling their content: confirm which translations may be bundled or fetched.',
        'OWNER_ACTIONS item 5 offers three options (ask permission, switch to Pickthall 1930, accept risk).',
        RIGHTS, ['docs/OWNER_ACTIONS.md item 5'], 'normal', sub='licence')
    add('quran.translit-59', 'quran-text', "Qur'an reader > transliteration, and search",
        'assets/quran (transliteration)', 'transliteration 59 of 6,236 ayahs',
        "The transliteration that exists covers only 59 of 6,236 ayahs; its source licence and accuracy.",
        'FIX_QURAN_HADITH_REPORT: no verified, properly licensed source; needs a written licence or a CC0/CC-BY dataset, then a check by an Arabic specialist.',
        RIGHTS, ['FIX_QURAN_HADITH_REPORT (transliteration 59/6236)'], 'high', also=[ARABIC], sub='transliteration')
    add('quran.translit-accuracy', 'quran-text', "Qur'an reader > transliteration; lesson say-steps",
        'assets/academy/phrases/*.json; assets/adhkar/adhkar.json; assets/finance/ramadan.json', 'all transliterations',
        'Every transliteration in the app (131 phrases, adhkar, Ramadan duas, daily duas) is the author\'s own learning aid.',
        'FIX_WORSHIP_REPORT and phrases files: "all transliterations and meanings are learning aids"; docs/content_needed/dua_transliteration.md lists the gaps.',
        ARABIC, ['FIX_WORSHIP_REPORT', 'docs/content_needed/dua_transliteration.md'], 'high', sub='transliteration')
    add('quran.arabic-diacritics', 'quran-text', "Qur'an reader (Arabic text)",
        'assets/quran/quran.json', 'diacritics against the reference Uthmani text',
        'Arabic diacritics were compared with a reference Uthmani text; differences were reported in the pass and no text was changed.',
        'FIX_QURAN_HADITH_REPORT: consonantal skeleton matched; diacritic differences exist and are unreviewed.',
        ARABIC, ['FIX_QURAN_HADITH_REPORT (diacritics vs Uthmani)'], 'high', sub='arabic-text')
    add('quran.riwaya', 'quran-text', "Qur'an reader; recitation audio",
        'assets/quran; lib/features/quran', 'riwaya (Hafs) and mushaf layout',
        'Confirm the text edition (Hafs an Asim, Madinah mushaf pagination of 604 pages) and any claim about it.',
        'Qira\'at are a specialist matter; no qira\'at specialist has reviewed the choice.',
        ARABIC, ['Reviewer list: Arabic / tajweed / qira\'at'], 'normal', sub='arabic-text')
    add('quran.word-meanings-source', 'quran-text', "Academy word deck (hidden)",
        'docs/OWNER_ACTIONS.md', 'Quranic word meanings and roots',
        'The 300-word deck is hidden because no licence-checked source of meanings and roots is in place.',
        'OWNER_ACTIONS item 7: the sources found carry GPL or unstated data terms.',
        RIGHTS, ['docs/OWNER_ACTIONS.md item 7'], 'normal', also=[ARABIC], sub='licence')
    add('quran.tafsir-absent', 'quran-text', "Story 'Go deeper' scholarly cards; Hadi",
        'assets/stories/layers', 'tafsir, tajweed and word-by-word data absent',
        'No licensed tafsir, tajweed or word-by-word dataset is bundled; the scholarly cards quote single classical works.',
        'FIX_QURAN_HADITH_REPORT: absent, no licensed source. Page numbers for tafsir quotations were not available (FACT_S1).',
        HADITH, ['FIX_QURAN_HADITH_REPORT', 'FACT_S1_prophets'], 'low', sub='tafsir')

    # ------------------------------------------------ hadith grades and sources
    add('hadith.grade-mismatches', 'hadith', 'Stories, Academy, Games, Hadi: hadith grade labels',
        'assets/stories; assets/academy; assets/games; lib/features/hadi', 'Tirmidhi 3513, 3404; Ibn Majah 1565, 4080, 3663',
        'Grade labels in stories, academy, games and Hadi that differed from the corpus (examples: Tirmidhi 3513, 3404; Ibn Majah 1565, 4080, 3663).',
        'FIX_QURAN_HADITH_REPORT "Out of scope": mismatches listed for owners; C_knowledge audit. Graders differ on several of these.',
        HADITH, ['FIX_QURAN_HADITH_REPORT', 'C_knowledge audit'], 'high', sub='grades')
    for key, what, why, src in [
        ('tirmidhi-3513', 'Tirmidhi 3513 (du\'a for Laylat al-Qadr)', 'Graders disagree: Zubair Ali Za\'i da\'if; al-Albani sahih.', 'FIX_HADI_REPORT; FIX_QURAN_HADITH_REPORT'),
        ('tirmidhi-3153', 'Tirmidhi 3153 (Gog and Magog, Dhul-Qarnayn)', 'Shakir sahih, al-Albani sahih, Bashar hasan, Zubair Ali Za\'i da\'if; shown as "graders differ".', 'FACT_S1_prophets'),
        ('ibnmajah-4080', 'Ibn Majah 4080 (Gog and Magog)', 'al-Albani sahih; Zubair Ali Za\'i da\'if; shown as "graders differ".', 'FACT_S1_prophets'),
        ('tirmidhi-2317', 'Tirmidhi 2317 (leaving what does not concern you)', 'al-Albani sahih; Darussalam da\'if; An-Nawawi hasan. Also Nawawi #12 and the Daily Hadith rebuild.', 'FIX_QURAN_HADITH_REPORT; FACT_S4'),
        ('tirmidhi-2416', 'Tirmidhi 2416 (feet on the Day)', 'Darussalam da\'if; al-Albani hasan. Page says hold as a reminder.', 'FACT_S4 (mh-youth-feet)'),
        ('abudawud-2380', 'Abu Dawud 2380 (vomiting and the fast)', 'Darussalam da\'if; al-Albani sahih.', 'FACT_S4 (Q&A 1)'),
        ('abudawud-3641', 'Abu Dawud 3641 (the scholars are the heirs of the prophets)', 'al-Albani sahih; Zubair and Shu\'ayb al-Arna\'ut da\'if. The page said "seekers", the hadith says "the scholars".', 'FACT_S4 (New Muslim day 27)'),
        ('tirmidhi-3431', 'Tirmidhi 3431 (dua on seeing someone afflicted)', 'al-Albani hasan; Zubair da\'if; the text said only "daif per Darussalam".', 'FACT_S4 (dua-seeing-afflicted)'),
        ('ibnmajah-1753', 'Ibn Majah 1753 (dua of the fasting person)', 'al-Albani da\'if; Zubair hasan.', 'FACT_S4 (dua-iftar-full)'),
        ('ibnmajah-224', 'Ibn Majah 224 ("seek knowledge even in China" neighbour)', 'Grade "very weak per Darussalam" unverified; the app must not imply the China wording is authentic.', 'E_games_hadi audit #83; FIX_HADI_REPORT'),
        ('ibnmajah-4252', 'Ibn Majah 4252 (tawbah)', 'hasan per Darussalam; sahih per al-Albani.', 'FACT_S4 (Q&A 12)'),
        ('tirmidhi-3892', 'Tirmidhi 3892 (Safiyya taunted)', 'Weak per Shakir, al-Albani and Zubair Ali Za\'i: named as not used.', 'S2_eol_hlth_wmns_char'),
        ('abudawud-2214', 'Abu Dawud 2214 (Khawlah report)', 'Graders differ; named as not used.', 'S2_eol_hlth_wmns_char'),
        ('muslim-2759', 'Muslim 2759 (mh-reflection-023)', 'Not found in the corpus: the story owner must verify or mark unverified.', 'FIX_QURAN_HADITH_REPORT'),
        ('muslim-2693', 'Muslim 2693 (an adhkar source)', 'Not in the corpus.', 'FIX_WORSHIP_REPORT'),
        ('nasai-kubra-ayat-kursi', 'Ayat al-Kursi after prayer: Nasa\'i Kubra number', 'The number could not be confirmed.', 'FIX_WORSHIP_REPORT'),
        ('tirmidhi-1071', 'Munkar and Nakir wording (Tirmidhi 1071)', 'Wording dropped as unverified from Games.', 'FIX_GAMES_REPORT'),
        ('tirmidhi-3604-muslim-2709', 'Evening refuge in Allah\'s perfect words (Tirmidhi 3604 vs Muslim 2709)', 'The evening-scorpion report is Muslim 2709; Tirmidhi 3604 is a different hadith in the corpus.', 'FACT_S4 (dua-morning-master)'),
    ]:
        add('hadith.grade.' + key, 'hadith', 'Where %s is cited' % what.split(' (')[0], 'various', key, what, why, HADITH, src, 'high', sub='grades')
    add('hadith.removed-daily', 'hadith', 'Home > Daily Hadith (history)', 'lib/features/hadith/domain/daily_hadith.dart', 'removed rotation entries',
        'Entries removed from the Daily Hadith rotation: weak Tirmidhi 2317, 2499; Abu Dawud 5090; an unverified Tabarani; a numberless al-Hakim; Muslim 2559 (text unverifiable).',
        'FIX_QURAN_HADITH_REPORT: a scholar should confirm they stay out (or return with a named grader).',
        HADITH, ['FIX_QURAN_HADITH_REPORT'], 'normal', sub='daily')
    add('hadith.verification-corpus', 'hadith', 'Every hadith card and Hadi source card', 'assets/noor/hadi_corpus.json; tool/hadith_check.py',
        'verification source',
        'Hadith were verified against the fawazahmed0 corpus (sunnah.com-derived), not against sunnah.com itself, which was unreachable.',
        'FIX_QURAN_HADITH_REPORT; OWNER_ACTIONS item 3 (sunnah.com API key not yet issued). Grader names (Darussalam, al-Albani, Zubair Ali Za\'i) come from that corpus.',
        HADITH, ['FIX_QURAN_HADITH_REPORT', 'docs/OWNER_ACTIONS.md item 3'], 'high', sub='verification')
    for fam in ['newmuslim', 'women', 'signs', 'seerah', 'modernhadith', 'ghayb', 'khutbahs', 'dailyduas', 'companions', 'qa', 'guides', 'adhkar', 'layers']:
        add('hadith.editor-notes.' + fam, 'hadith', 'Source lines in %s' % fam, 'assets (%s)' % fam, 'editor notes',
            'Source lines in the %s data that carried editor notes such as "number not re-checked" or "number to be verified".' % fam,
            'C_knowledge audit and FIX_QURAN_HADITH_REPORT list this family as carrying (or having carried) editor notes. Each cited number needs a scholar or a hadith specialist to confirm it.',
            HADITH, ['C_knowledge audit (editor notes leaked)', 'FIX_QURAN_HADITH_REPORT'], 'normal', sub='editor-notes')

    # ------------------------------------------------ dua / dhikr
    for key, what, why, src in [
        ('eid-takbir', 'Eid greeting and takbir: no Arabic shown', 'Left out as unverified.', 'FIX_WORSHIP_REPORT'),
        ('translit-gaps', 'Adhkar morning 15 and evening 15 duas lack transliteration; 12 daily duas lack transliteration', 'Gaps listed rather than filled with unreviewed text.', 'FIX_WORSHIP_REPORT; B_worship audit'),
        ('small-sitting', '"Small sitting" label for the sitting between sajdahs', 'The label has no source (Ibn Majah 897 is sahih per al-Albani for the dua).', 'FACT_S4 (dua-between-sajdah)'),
        ('names-duas-log', 'Names of Allah and dua verification log', 'docs/content_needed/VERIFICATION_LOG_NAMES_DUAS.md records what was and was not verified.', 'VERIFICATION_LOG_NAMES_DUAS'),
        ('hisn-source', 'Hisn al-Muslim gates: authorship and numbering', 'The app\'s Hisn screens present gates in the app author\'s order with source lines; no named scholar confirmed the grading of each dua.', 'Academy Hisn screen'),
        ('fatiha-linked', 'Prayer guide recitations (takbir, Fatihah, tashahhud, salawat) in Arabic with transliteration', 'R9_T1: absent from the guide at the time; a scholar should confirm wording when added.', 'R9_T1_children'),
    ]:
        add('dua.' + key, 'dua-dhikr', 'Dhikr / Dua screens', 'assets/adhkar; assets/stories/dailyduas.json', key, what, why, HADITH, src, 'normal', also=[ARABIC], sub='dua')
    add('dua.dhikr-session', 'dua-dhikr', 'Dhikr session screen (counts, targets)', 'lib/features/academy/presentation/dhikr_session_screen.dart', 'counts and targets',
        'Counts and targets (33/33/34, 100, 10) offered in the dhikr session.', 'Counts come from sourced reports; the screen is not reviewed by a named scholar.',
        HADITH, ['Surface list (dhikr screens)'], 'normal', sub='dhikr')

    # ------------------------------------------------ arabic / tajweed / hifz
    for key, what, why, src in [
        ('tarteel-definition', 'Ali\'s definition of tarteel', 'Quoted from works on tajweed; chain not checked.', 'S2_arabic_hfz'),
        ('tajweed-jali-khafi', 'Jali / Khafi labels for ikhfa and ghunnah on tajweed cards', 'The app\'s own claim (unverified); marked pending scholar review.', 'A_academy audit D24'),
        ('sun-moon-letters', 'Sun and moon letters (lesson arabic.u1.l3 and cards)', 'Letter grouping and the assimilation rule are taught from general knowledge.', 'Arabic course'),
        ('hifz-method', 'The Hifz method: lanes, daily plan, revision cycle, choosing a teacher', 'Method content is the author\'s own; a hafiz teacher should review it.', 'S2_arabic_hfz'),
        ('colored-examples', 'Tajweed cards: examples and the promise of colour', 'colorKey unused though the header promised colour examples (A_academy D24).', 'A_academy audit'),
        ('arabic-script-lessons', 'Arabic letter-shape and sound teaching', 'Letter names and sounds are taught from general knowledge; a tajweed specialist should confirm makhraj descriptions.', 'Arabic course'),
    ]:
        add('arabic.' + key, 'arabic-tajweed', 'Academy > Arabic / Hifz / Tajweed', 'assets/academy/lessons_v3; lib/features/academy/presentation/tajweed_cards_screen.dart', key, what, why,
            ARABIC, src, 'high' if key in ('tarteel-definition', 'tajweed-jali-khafi', 'hifz-method') else 'normal', also=[HADITH], sub='method')

    # ------------------------------------------------ will, estate, janazah
    add('eol.janazah', 'academy-schools', 'End of Life > janazah lessons and phrases', 'assets/academy/lessons_v3/eol.json; assets/academy/phrases/eol_hlth_wmns_char.json',
        'janazah lessons',
        'Janazah teaching: washing, shrouding, the four takbirs, the dua, burial, women attending, condolence; the rulings differ by school.',
        'S2_eol_hlth_wmns_char: janazah prayer details by school (Hadi janazah answers also flagged in FIX_HADI_REPORT).',
        FIQH, ['S2_eol_hlth_wmns_char', 'FIX_HADI_REPORT'], 'high', also=[WOMEN], sub='janazah')
    add('eol.will-estate', 'money', 'End of Life > will and estate lessons', 'assets/academy/lessons_v3/eol.json; lib/features/academy/presentation/end_of_life_school_screen.dart',
        'will and estate (bequest limits, shares)',
        'The will and estate lessons (Bukhari 2738, 4:11), shares and guardianship.',
        'A_academy: "Teach heirs/shares properly or defer to scholar"; R9_T2: thin and over-absolute.',
        FIQH, ['A_academy audit (eol.u1.l3)', 'R9_T2_parent_wasia'], 'high', also=[LAWYER], sub='will-estate')

    # ------------------------------------------------ lessons: audit-specific
    add('lesson.wmns.asiya-house', 'academy-lessons', 'Academy > Women > Asiya lesson', 'assets/academy/lessons_v3/wmns.json', 'wmns.u1.l2',
        '"Allah showed her her house" is not in 66:11 (she asks for a house; the showing is hadith/tafsir).', 'A_academy audit: unverified.',
        HADITH, ['A_academy audit (wmns.u1.l2)'], 'normal', also=[WOMEN], sub='wmns')
    add('lesson.wmns.aisha-narration', 'academy-lessons', 'Academy > Women > Aisha lesson', 'assets/academy/lessons_v3/wmns.json', 'wmns.u2.l1',
        'Aisha/Urwa narration was unsourced in the audit.', 'A_academy audit: cite.', HADITH, ['A_academy audit (wmns.u2.l1)'], 'normal', also=[WOMEN], sub='wmns')
    add('lesson.wasia-claim', 'academy-lessons', 'Wasia (lesson helper)', 'lib/features/academy', 'scope and refusals',
        'Wasia answers only from the words of the lesson and refuses rulings; the claim "he said, as a teacher made easy" was uncited in one lesson.',
        'R9_T2_parent_wasia.', HADITH, ['R9_T2_parent_wasia'], 'low', sub='wasia')
    add('lesson.path-established', 'academy-lessons', 'The Path (new Muslim) > Established tag', 'assets/academy/lessons_v3/the-path.json', '[Established] on thin lessons',
        '[Established] on a thin lesson implies completeness; a card says "pray as you have seen" with no school stated.', 'R9_T3_new_muslim.',
        FIQH, ['R9_T3_new_muslim'], 'normal', also=[HADITH], sub='the-path')

    # ------------------------------------------------ Hadi / Sakina routing
    add('hadi.routing', 'hadi', 'Hadi chat > choosing which answer to show', 'lib/features/hadi/data/hadi_routing.dart', 'routing rules',
        'Which question gets which answer (for example prepaid funeral plan, combining prayers answer leading with shortening, ibuprofen while fasting).',
        'FIX_HADI_REPORT and E_games_hadi list wrong-topic answers in a confident frame; the routing is the app\'s own.',
        HADITH, ['FIX_HADI_REPORT (known gaps)', 'E_games_hadi audit'], 'normal', also=[FIQH], sub='routing')
    add('hadi.explain', 'hadi', 'Hadi > "Hadi checked this reply" and how-it-works text', 'lib/features/hadi/data/hadi_explain.dart', 'explain text',
        'The wording that says what Hadi checked and what a scholar has not.', 'Honesty copy; the "checked" claim must stay accurate.',
        HADITH, ['E_games_hadi audit'], 'normal', sub='explain')
    add('hadi.ai-tier', 'hadi', 'Hadi optional AI tier (own key)', 'lib/features/hadi', 'AI-generated answers',
        'Any answer generated by an AI model with the user\'s own key is not from the built-in library and carries no review.',
        'R9_T1 / R9_T4: "optionally your own AI key"; the Qur\'an is never produced from memory.', HADITH, ['R9_T4_everyday_skeptic'], 'high', sub='ai')

    # ------------------------------------------------ legal
    for key, where, file, what, why in [
        ('terms', 'You > Settings > Terms of Use', 'lib/features/legal/presentation/legal_screens.dart', 'The Terms of Use text.', 'OWNER_ACTIONS item 6: draft; lawyer review and the contact address are pending.'),
        ('privacy', 'You > Settings > Privacy Policy', 'lib/features/legal/presentation/legal_screens.dart', 'The Privacy Policy text.', 'OWNER_ACTIONS item 6: draft; "Contact address: not published yet".'),
        ('children-privacy', 'Family Wing; Kids Corner', 'lib/features/academy/domain/children_privacy.dart', 'The children\'s privacy section (COPPA and PIPEDA wording).', 'OWNER_ACTIONS items 6 and 17(d): the privacy text still needs a lawyer\'s review for COPPA/PIPEDA wording.'),
        ('parent-pin', 'Family Wing > parent PIN and child mode', 'lib/features/family', 'Parent PIN (salted hash on device), five wrong tries lock for five minutes, child mode.', 'OWNER_ACTIONS item 17: caveats (PIN can be set by a child first; no recovery; Games left out of child mode).'),
        ('contact-address', 'Terms and Privacy screens', 'lib/features/legal/presentation/legal_screens.dart', 'kLegalContactPending: no real contact address exists.', 'OWNER_ACTIONS items 6 and 18: stores require a reachable privacy contact.'),
        ('community-rules', 'Majlis / community rules', 'lib/features/community; lib/features/majlis', 'Community rules, reporting and moderation wording.', 'Not reviewed by a lawyer; needed before public launch.'),
        ('data-sync', 'Sign-in, sync, notes, Firestore rules', 'firestore.rules; lib/features/auth', 'Data collection and deletion promises on the privacy screens.', 'OWNER_ACTIONS item 2: rules reviewed by reading, not executed.'),
        ('religious-disclaimer', 'Sources > How we handle religious content; "not a mufti"', 'lib/features/sources/presentation/content_policy_screen.dart', 'The disclaimers about rulings and scholars.', 'Needs a lawyer to confirm the disclaimers are enough for store review.'),
        ('rights-streaks-ads', 'What is free; ads and paid plan wording', 'lib/features/sources/presentation', 'Free and paid plan wording; ads.', 'R9_T2 / R9_T4 noted a "paid plan planned" line; confirm with a lawyer before billing.'),
    ]:
        add('legal.' + key, 'legal', where, file, key, what, why, LAWYER, ['docs/OWNER_ACTIONS.md items 2, 6, 17, 18'], 'high', sub='legal')

    # ------------------------------------------------ nasheeds and audio
    add('nasheed.catalogue', 'nasheeds', 'Nasheeds / Player > verified catalogue (200 entries)', 'assets/academy/player_catalog_verified.json',
        'family-friendly judgement for 200 entries',
        'The "family-friendly" label for 200 verified nasheeds is a judgement from artist and title, not a scholar\'s review.',
        'NASHEED_VERIFICATION_LOG: instrument use was NOT checked for entries marked unknown; target of 600 not reached.',
        FIQH, ['docs/content_needed/NASHEED_VERIFICATION_LOG.md'], 'high', also=[HADITH], sub='catalogue')
    add('nasheed.music-view', 'nasheeds', 'Nasheeds > audio style (vocals / duff / music / unknown)', 'tool/nasheed_verified/verified.tsv', 'audio style',
        'Whether a user who avoids instruments is served correctly by the vocals-only / duff / music / unknown classes. Scholars differ on music (the Q&A bank says so).',
        'The app has no vocals-only guarantee; classes come from the uploader\'s own titles.', FIQH, ['NASHEED_VERIFICATION_LOG', 'FACT_S4 (Q&A music)'], 'high', sub='catalogue')
    add('nasheed.channels', 'nasheeds', 'Nasheeds > official channel claims', 'docs/content_needed/NASHEED_VERIFICATION_LOG.md', 'channel officialness',
        'Officialness of the uploading channels (labels, artist channels) for entries beyond Awakening Music.',
        'Not independently corroborated beyond the artist/label name; the owner is asked to spot-check.', RIGHTS, ['NASHEED_VERIFICATION_LOG'], 'normal', sub='rights')
    add('nasheed.lyrics', 'nasheeds', 'Nasheed lyrics and titles', 'assets/academy/player_catalog_verified.json', 'lyrics content',
        'Whether the lyrics of the listed nasheeds contain anything contrary to aqidah; titles were checked, lyrics were not heard.',
        'Only title, channel and embeddability were fetched.', HADITH, ['NASHEED_VERIFICATION_LOG'], 'normal', sub='catalogue')
    add('nasheed.audio-stubs', 'nasheeds', 'Recitation and Listen buttons', 'assets/audio', 'audio sources',
        'Recitation and Listen audio: which reciters are offered and the audio files themselves (stub or silent files were found in test).',
        'R9_T1: Listen, recitation and speaker buttons UNVERIFIED; OWNER_ACTIONS audio CORS note.', ARABIC, ['R9_T1_children', 'docs/audio_cors.md'], 'normal', also=[RIGHTS], sub='audio')

    # ------------------------------------------------ prayer: extra
    add('prayer.method-defaults', 'prayer-calendar', 'Prayer Times > default method on first run', 'lib/features/prayer/application/prayer_settings.dart', 'autoMethodFor',
        'The method chosen automatically for a user who has not picked one.', 'FIX_WORSHIP_REPORT: verified maths, not the choice.', FIQH, ['FIX_WORSHIP_REPORT'], 'high', sub='method')
    add('prayer.approx-times-label', 'prayer-calendar', 'Prayer Times > "approximate, confirm locally"', 'lib/features/prayer', 'approximate label',
        'The wording that says times are approximate and to confirm with the local mosque.', 'R9_T4 praised it; wording is the app\'s.', FIQH, ['R9_T4_everyday_skeptic'], 'low', sub='method')

    # ------------------------------------------------ Sakina extras
    add('sakina.help-unverified', 'sakina', 'Need help now > "Not re-checked recently" help lines', 'lib/features/sakina/domain/sakina_content.dart', 'HelpResources unverified',
        'Help lines marked unverified or not re-checked, and US-centric coverage outside the US.', 'B_worship audit; FACT_S4 re-verification dated 2026-10-20.',
        CLIN, ['B_worship audit', 'FACT_S4'], 'high', also=[NATIVE], sub='help-lines')
    add('sakina.child-loss-grief', 'sakina', 'Hadi / Sakina > grief and child loss replies', 'lib/features/hadi/data/offline_hadi_provider.dart', 'grief replies',
        'Replies for bereavement, miscarriage and child loss.', 'Sensitive copy with no clinician or scholar review.', CLIN, ['E_games_hadi audit'], 'high', also=[HADITH], sub='grief')
    add('health.ruqya-medicine', 'sakina', 'Health school; Hadi on fasting and medicine; ruqya', 'assets/academy/lessons_v3/hlth.json', 'health claims',
        'Health teaching (Prophetic medicine, dhikr and mental health, fasting and medicine, ibuprofen while fasting).', 'S2_eol_hlth_wmns_char: health content needs a clinician; Hadi refuses ibuprofen question with no doctor line (E_games_hadi #79).',
        CLIN, ['S2_eol_hlth_wmns_char', 'E_games_hadi audit #79'], 'high', also=[HADITH], sub='health')

    # ------------------------------------------------ languages
    add('lang.elder-rtl', 'languages', 'Arabic and Urdu UI direction and font', 'lib/app', 'RTL layout, fonts',
        'Right-to-left layout and fonts for Arabic and Urdu; Bangla glyphs rendered as empty boxes in headless test.', 'R9_T4 D5, R9_T6_elder_languages: unverified on a real device.', NATIVE, ['R9_T6_elder_languages', 'R9_T4_everyday_skeptic'], 'normal', sub='layout')

    # ------------------------------------------------ support module (Phase 1)
    add('support.hadi-replies', 'sakina', 'Hadi > a reply to someone who talks about drinking, drugs, gambling, pornography, smoking or a relapse',
        'lib/features/hadi/grounding/support_signal.dart', 'SupportReplies (bodies, safetyNote, verdictNote, appNote)',
        'Listening replies (three per topic), the safety note about not stopping heavy use suddenly, and the word lists that decide a person from a question.',
        'RES_H3: a ruling card is the wrong answer to someone in relapse. Written for coverage; no clinician has read them. Shown with both "Scholar review needed" and "Clinician review needed" until signed.',
        CLIN, ['RES_H3_hadi_companion_design', 'RES_H1_recovery_evidence'], 'high', also=[FIQH, NATIVE], sub='support',
        surf='Under every support reply in Hadi')
    add('support.crisis-substance', 'sakina', 'Hadi / Wasia > medical emergency card (overdose, withdrawal danger, mixing, drunk driving)',
        'lib/features/sakina/domain/crisis_detector.dart', 'CrisisKind.substanceEmergency (phrases, card text, latch checks)',
        'The new addiction and medical-emergency crisis category: English phrases, the card (emergency number first, no dose, no taper) and the follow-up checks after the card.',
        'RES_H3 R5: no addiction or overdose category existed. Withdrawal from alcohol and sedatives can be fatal, so the wording must be read by a clinician.',
        CLIN, ['RES_H3_hadi_companion_design'], 'high', sub='crisis',
        surf='The crisis card')
    add('support.crisis-substance-lang', 'languages', 'Crisis phrases for the medical-emergency category in Arabic, Urdu (script and Roman) and Bangla',
        'lib/features/sakina/domain/crisis_detector.dart', '_substance (non-English phrases)',
        'Short phrase lists for overdose, seizure and not breathing in Arabic, Urdu and Bangla.',
        'Written for coverage, not read by a native-speaker clinician. English has the full list; other languages are thin and the app must say so.',
        NATIVE, ['RES_H3_hadi_companion_design'], 'high', also=[CLIN], sub='crisis-phrases')
    add('support.latch-checks', 'sakina', 'Hadi / Wasia > the safety check after a crisis card ("ok", "tonight")',
        'lib/features/sakina/domain/crisis_latch.dart', 'CrisisLatch (checkFor, relief, ambiguous words)',
        'The plain questions asked when a short reply follows a crisis card, and the sentence said when the person says they are safe.',
        'RES_H3 D1: follow-ups with no trigger word were treated as normal. The wording and the list of ambiguous words need a clinician.',
        CLIN, ['RES_H3_hadi_companion_design'], 'high', sub='crisis')
    add('support.wasia-child', 'sakina', 'Wasia and Kids > what a child is told when something is wrong',
        'lib/features/academy/application/wasia_controller.dart', 'wasiaCrisisReply; OfflineWasiaProvider.trustedAdult; MinorSignal; CrisisResponses.trustedAdultChoices',
        'Replies now say "a trusted adult (a parent if it feels safe, a teacher, a school counsellor, or a child helpline)", that the child chooses, and that the app cannot call anyone.',
        'RES_H3 R1, D5, D6: "tell a parent" can point a child at the person hurting them. A child-protection specialist and a clinician should read the wording by age band.',
        CLIN, ['RES_H3_hadi_companion_design', 'R9_T1_children'], 'high', also=[LAWYER], sub='children',
        surf='Wasia thread, Kids Corner help button')
    add('support.privacy-storage', 'sakina', 'Hadi > nothing about a conversation is saved; the API key leaves plain text; Report never uploads support text',
        'lib/features/hadi/data/api_key_vault.dart; lib/features/hadi/data/hadi_report_service.dart', 'ApiKeyVault; HadiReportPolicy',
        'The conversation is memory-only. The key is kept in the secure store on a phone and memory-only in a browser. Report drops text from crisis, support and minor exchanges.',
        'RES_H3 D3, D4, D10: health disclosures were stored in plain text and could be uploaded by the Report button.',
        LAWYER, ['RES_H3_hadi_companion_design'], 'high', sub='privacy')

    # ------------------------------------------------ support module (Phase 2)
    add('support.packs', 'sakina', 'Hadi / Wasia > every reply written from a support pack (11 pathways, shame, cravings, grief, relapse)',
        'assets/support/packs/*.json; lib/features/support/domain/support_engine.dart', 'Pack snippets and the reply engine (orient, reflect, ask, plan-step)',
        'Listening wording, reflections, one-question asks and plan steps, rotated so no line repeats. Drafts until each snippet is signed.',
        'Owner approved packs as the source of wording. Shown with "Scholar review needed" and "Clinician review needed" until sign-off.',
        CLIN, ['docs/support/pack_format.md'], 'high', also=[FIQH, NATIVE], sub='support',
        surf='Support pathway screens and under each reply')
    add('support.pathways', 'sakina', 'Support hub and the eleven pathway screens',
        'lib/features/support/presentation/support_pathway_screens.dart', 'kSupportPathways',
        'Page structure, what each pathway promises, the hand-over to people, and the quick-exit placement.',
        'Abuse-in-progress features first: quick exit, private mode, safe word. A safeguarding specialist should read the abuse pathways.',
        CLIN, ['RES_H3_hadi_companion_design'], 'high', also=[LAWYER], sub='support')
    add('support.checkin', 'sakina', 'Hadi / Wasia > the gentle check-in ("how are you really doing?")',
        'lib/features/support/domain/checkin_scheduler.dart; assets/support/packs/checkin.json', 'CheckinScheduler; checkin pack',
        'In-app only, at most every 2 weeks (4 after "rather not say"), permanent off, only the date and the off flag stored. Wasia wording by age band; the answer is never shown to a parent.',
        'Owner decision. The wording and the intervals need a clinician; the child version also a child-protection specialist.',
        CLIN, ['RES_H3_hadi_companion_design'], 'high', also=[LAWYER], sub='support')
    add('support.memory', 'sakina', 'Settings > Let Hadi remember things I tell it; What Hadi knows about me',
        'lib/features/support/domain/user_memory.dart; lib/features/support/application/support_settings.dart', 'UserMemory; SupportSettingsNotifier',
        'Opt-in, encrypted on device, view, edit, delete, export. Crisis, abuse and support content is never remembered.',
        'Privacy by default. A lawyer should confirm the data-protection wording and the export.',
        LAWYER, ['RES_H3_hadi_companion_design'], 'high', sub='privacy')
    add('support.online-consent', 'sakina', 'Settings > Use the online model for support chats',
        'lib/features/support/domain/online_support_policy.dart; lib/features/support/presentation/support_wellbeing_screen.dart', 'SupportOnlinePolicy; consent dialog',
        'Default off, plain consent, managed key only (never the user\'s own key), never in crisis, for a minor or for fixed wording; the reply is checked before use.',
        'Sensitive disclosures leaving the device is a legal and clinical question.',
        LAWYER, ['RES_H3_hadi_companion_design'], 'high', also=[CLIN], sub='privacy')
    add('support.student-routing', 'sakina', 'Wasia > learning worry, bullying, anxiety, teen exposure, disclosure',
        'lib/features/support/domain/student_routing.dart', 'StudentRouting word lists',
        'Which messages go to the student_problems pack. A learning difficulty is referred, never diagnosed. Bullying, exposure and family strain add a trusted-adult line.',
        'English word lists only; written for coverage.',
        CLIN, ['RES_H3_hadi_companion_design', 'R9_T1_children'], 'high', also=[LAWYER, NATIVE], sub='children')
    add('support.children-age-band', 'sakina', 'Parent controls > age band per child; children privacy version 5',
        'lib/features/academy/domain/children_privacy.dart; docs/content_needed/children_privacy_age_band.md', 'kChildrenPrivacyVersion = 5',
        'The parent sets 5-8, 9-12 or 13-17; Wasia keeps no emotional profile; the parent never sees chats or safety events.',
        'A lawyer should confirm this against children\'s privacy law in the markets served.',
        LAWYER, ['docs/content_needed/children_privacy_age_band.md'], 'high', sub='children')
    add('support.helplines', 'sakina', 'Help lines shown in the app',
        'assets/support/helplines.json; lib/features/support/data/helplines_loader.dart; lib/features/sakina/domain/sakina_content.dart', 'HelplinesLoader; HelpResources.shown',
        'Only lines with a verified-on date and an https source are shown. Unconfirmed emergency rows are hidden.',
        'Numbers change. Each needs re-checking on its date.',
        CLIN, ['docs/support/pack_format.md'], 'high', sub='support')

    # ------------------------------------------------ child-safety fixes (round 10, T2)
    add('support.child-distress', 'sakina', 'Wasia > what a child is told when they say they are unhappy, scared, hurt, or ask for a secret to be kept',
        'lib/features/support/domain/child_distress.dart', 'ChildDistress (word lists, replies by age band 5-8, 9-12, 13-17)',
        'Fixed listening replies for school unhappiness, fear at home, general fear and "promise you will keep it secret", with trusted-adult choices and the child helpline button.',
        'Round 10 T2: a bullying sentence got "beyond what I can teach". Written for coverage in English; no clinician or child-protection specialist has read them.',
        CLIN, ['R10_T2'], 'high', also=[LAWYER, NATIVE], sub='children',
        surf='Wasia thread and Kids Corner')
    add('support.parent-listening', 'sakina', 'Family Wing > How to listen to a child who is hurting',
        'lib/features/support/presentation/parent_listening_screen.dart', 'kParentListeningSections',
        'Signs, how to open the conversation, what to say, what not to say, what to do next, harm at home, and one line from the faith.',
        'Round 10 T2: no content told a parent how to listen to a bullied child. A clinician and a child-protection specialist should read it; a scholar should read the faith line.',
        CLIN, ['R10_T2'], 'high', also=[FIQH, LAWYER], sub='children',
        surf='Family Wing and search')
    # ------------------------------------------------ support and safety fixes (round 10, fix pass B)
    add('support.safe-replies', 'sakina', 'Hadi > refused taper schedule; controlling husband; a child who told a parent; a struggling teenager; a quiet student; "are you a therapist?"; "be my only friend"',
        'lib/features/support/domain/safe_replies.dart', 'TaperRequest, CoerciveMarriage, ChildConcern, AboutHadi (word lists and fixed replies)',
        'Fixed on-device replies for moments that are neither a crisis card nor a ruling: no taper schedule (a doctor decides), listening and a safety question before any patience or duty, what a parent does when a child tells them something, how to open a conversation with a withdrawn teenager, what a teacher does about a quiet student, and honest answers that Hadi is an app and not a therapist or a friend.',
        'R10_T9 and R10_T10: a taper request got a ruling card, a controlling-husband question got a patience verse, and "are you a therapist" got a lesson-shelf answer. No clinician, safeguarding specialist or scholar has read them.',
        CLIN, ['R10_T9', 'R10_T10', 'R10_T2'], 'high', also=[LAWYER, FIQH, NATIVE], sub='support',
        surf='Under each of these replies in Hadi and Wasia')
    add('support.crisis-phrases-fixb', 'languages', 'Crisis phrases added in fix pass B (English plus Arabic, Urdu, Bangla)',
        'lib/features/sakina/domain/crisis_detector.dart', '_selfHarm, _abuse, _substance (added phrases)',
        'New phrases: "nobody would notice if I was gone", "I do not want to go home", "someone at home hurts me", "I am scared he will hurt me tonight", pills with alcohol, and short Arabic, Urdu and Bangla lists for the same ideas.',
        'R10_T9, R10_T10, R10_T2: these sentences were missed. The non-English lists were written for coverage and are NOT read by a native speaker: Native-speaker review needed before they are relied on. English wording must be read by a clinician for false alarms and misses.',
        NATIVE, ['R10_T9', 'R10_T10', 'R10_T2'], 'high', also=[CLIN], sub='crisis-phrases')
    add('support.child-disclosure-card', 'sakina', 'Wasia, Kids > the card a child sees when they tell something serious (ages 5-8, 9-12, 13-17); cards for reading difficulty, vaping, pornography',
        'lib/features/support/domain/child_distress.dart; lib/features/academy/application/wasia_controller.dart', 'ChildDistress.disclosureCard; learning, vape, porn replies',
        'Full-sentence, age-banded wording: "I believe you", "it is not your fault", Wasia cannot keep secrets from the grown-ups who help, the child chooses who to tell, the help-line button. A reading-difficulty line goes to a teacher or a doctor, vaping and pornography to a trusted adult, with no shaming and no diagnosis.',
        'R10_T2: the old card was a broken sentence that told a child what to do under pressure. A child-protection specialist and a clinician should read the wording for each age band.',
        CLIN, ['R10_T2'], 'high', also=[LAWYER, NATIVE], sub='children',
        surf='Wasia thread and Kids Corner')
    add('support.help-country-choice', 'sakina', 'Need help now / Hadi crisis card > the country the person picks',
        'lib/features/sakina/application/sakina_providers.dart; lib/features/sakina/domain/crisis_detector.dart', 'pickedHelpCountryProvider; CrisisResponses.regionNote(picked)',
        'The country picked under the help lines now also decides the text of the card, not only the rows. The note says the lines are for the country the person chose.',
        'R10_T10: a Bangladeshi user picked Bangladesh and the card text still named another country. The wording of the note needs a native-speaker read in each supported language.',
        CLIN, ['R10_T10'], 'normal', also=[NATIVE], sub='help-lines')
    add('support.helplines-fixb', 'sakina', 'Help lines added in fix pass B: Egypt child hotline 16000, Egypt women\'s complaints hotline 15115, Saudi child helpline 116111, Canada provincial gender-based-violence directory',
        'assets/support/helplines.json; tool/support/build_helplines.py', 'eg-16000, eg-15115, sa-116111, ca-gbv-provincial',
        'Four rows read on 2026-10-27 on official or UN pages (sources in the file). Canada has no single national line, so the row opens the Government of Canada list. The Egypt women\'s hotline rests on a 2020 UN interview and should be re-checked on an NCW page. Hours are left empty because the pages did not state them.',
        'R10_T9, R10_T10: Canada adult domestic violence, Bangladesh women\'s, Saudi and Egypt coverage were missing. Bangladesh 109 was already verified. Nothing unverified is shown.',
        CLIN, ['R10_T9', 'R10_T10'], 'high', also=[NATIVE], sub='help-lines')
    add('support.wasia-checkin', 'sakina', 'Wasia > the gentle check-in for a child',
        'lib/features/academy/application/wasia_checkin.dart', 'WasiaCheckinNotifier; kWasiaCheckinFallback',
        'Age-banded wording; once per interval per child; only the last-asked day and the off flag are stored on the device; the answer is not stored and no parent screen reads it.',
        'Round 10 T2: the check-in never appeared in Wasia. Wording needs a clinician; storage needs a lawyer (children privacy version 6).',
        CLIN, ['R10_T2'], 'high', also=[LAWYER], sub='children')

    # ------------------------------------------------ fix pass C (child mode, privacy, elder)
    add('kids.child-mode-surahs', 'quran-text', 'Child mode > the short surahs a child can open',
        'lib/app/core/child_mode.dart', 'kChildSurahs',
        'Surahs 1, 103, 105-110 and 112-114 open in locked child mode; other surahs send the child back to Kids Corner.',
        'Round 10: child mode blocked every surah and dua. The set is a first choice made by the developer; a teacher of children should confirm it.',
        FIQH, ['R10_T2'], 'normal', sub='children',
        surf='Kids Corner in child mode')
    add('kids.child-mode-stories', 'stories-prophets', 'Child mode > the stories shown in Stories school',
        'lib/features/academy/presentation/stories_school_screen.dart', 'kChildStoryIds',
        'Seven gentle stories (Adam, Nuh, Yunus, Ayyub, Sulayman, the Sleepers of the Cave, the Two Gardens) show in child mode, with no adult theme text.',
        'The chosen set and the one-line description are the developer\'s; a teacher of children and a scholar should confirm them.',
        FIQH, ['R10_T2'], 'normal', sub='children',
        surf='Stories school in child mode')
    add('legal.firebase-startup', 'legal', 'Privacy Policy > Google services at start-up',
        'lib/features/legal/presentation/legal_screens.dart', 'kPrivacySections',
        'The policy now says the Firebase software starts at launch when the build is connected, and lists what Firebase is used for.',
        'Written from reading the code; a lawyer should confirm the wording.',
        LAWYER, ['R10_T4'], 'high', sub='legal')
    add('i18n.elder-doors', 'languages', 'Home > Elder Mode card wording in Arabic, Bangla and Urdu',
        'lib/app/core/i18n/ui_labels.dart', 'home.elderSub',
        '"A few simple doors" replaces "three doors" in all four languages.',
        'The Arabic, Bangla and Urdu lines were written without a native speaker. Native-speaker review needed.',
        NATIVE, ['R10_T6'], 'normal', sub='languages')
    add('kids.child-duas', 'dua-dhikr', 'Stories > dua reader in child mode; Kids Corner > Duas',
        'lib/features/kids/domain/child_duas.dart', 'kChildDuas',
        'Five duas (waking, before eating, leaving home, for parents, rain) now show a one-line child-level meaning instead of the adult paragraph.',
        'Child meanings were written without a scholar or an educator. Check each for accuracy and age fit.',
        FIQH, ['FIX2_C'], 'high', also=[ARABIC], sub='children', surf='Dua reader in child mode')
    add('kids.child-stories', 'stories-prophets', 'Stories > reader in child mode',
        'lib/features/kids/domain/child_stories.dart', 'kChildStoryText',
        'Seven stories (Adam, Nuh, Yunus, Ayyub, Sulayman, cave, gardens) have short child retellings, shown in child mode in place of the adult text.',
        'Retellings were written without a scholar. Check each against the sourced story and for age fit.',
        FIQH, ['FIX2_C'], 'high', sub='children', surf='Story reader in child mode')
    add('kids.child-games-list', 'games', 'Games hub in child mode',
        'lib/app/core/child_mode.dart', 'kChildGameIds',
        'Child mode shows only five games: Arabic words, Memory, 99 Names, Salah and wudu, Order of the prophets.',
        'The curated list is a product choice; a scholar or educator should confirm each is suitable for children.',
        FIQH, ['FIX2_C'], 'normal', sub='children', surf='Games hub in child mode')
    add('kids.alif-wording', 'academy-schools', 'Ask Wasia > the letter Alif (offline answer)',
        'lib/features/academy/data/offline_wasia_provider.dart', 'alif answer',
        'The Alif answer now describes the letter at child level (tall straight line, open "aaa") without the term al-jawf.',
        'Pronunciation wording was written without an Arabic teacher. Check it.',
        ARABIC, ['FIX2_C'], 'normal', sub='children', surf='Ask Wasia answer')
    add('kids.translit-credit', 'dua-dhikr', 'Dua reader > transliteration credit line',
        'lib/features/kids/domain/child_duas.dart', 'transliterationCreditLine',
        'The credit line now names the open dua-dhikr collection (MIT licence), based on Hisn al-Muslim.',
        'Confirm the credit wording meets the licence.',
        RIGHTS, ['FIX2_C'], 'normal', sub='licence', surf='Dua reader')
