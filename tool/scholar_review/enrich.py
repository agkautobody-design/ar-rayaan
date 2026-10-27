"""Adds the cross-report reasons to items that the extractors already made.

Each rule names ids (or a text pattern) and the report that raised the
point. A rule that matches nothing raises, so a renamed id cannot silently
drop a flagged topic.
"""
import re


def apply(R):
    def ids(*names):
        for n in names:
            R.by_id[n]  # KeyError if missing

    def by_pattern(pattern, min_hits=1, area=None):
        hits = [i['id'] for i in R.find(pattern) if area is None or i['area'] == area]
        assert len(hits) >= min_hits, 'no register item matches %r' % pattern
        return hits

    # --- Hadith gradings the reports call out
    for n, why, src in [
        (12, 'Tirmidhi 2317: al-Albani sahih, Darussalam da\'if, An-Nawawi hasan. Shown to users as a disagreement, not a ruling.',
         'FIX_QURAN_HADITH_REPORT "Needs scholar review" (Nawawi #12)'),
        (41, 'Some later scholars question the chain; shown as a note.', 'FIX_QURAN_HADITH_REPORT "Needs scholar review" (Nawawi #41)'),
        (42, 'Tirmidhi calls it gharib; al-Albani sahih; shown as a caveat.', 'FIX_QURAN_HADITH_REPORT "Needs scholar review" (Nawawi #42)'),
    ]:
        R.enrich('hadith.nawawi.%02d' % n, why=why, source=src, priority='high')

    # Tirmidhi 3153 / Ibn Majah 4080 (Gog and Magog, Dhul-Qarnayn), Tirmidhi 3513 (Laylat al-Qadr du'a)
    for pid in by_pattern(r'3153|4080', 1):
        R.enrich(pid, why='Tirmidhi 3153 and Ibn Majah 4080: repo said "Darussalam (sahih)"; the corpus has al-Albani sahih, Bashar hasan, Zubair Ali Za\'i da\'if. Now "graders differ".',
                 source='FACT_S1_prophets (SCHOLAR REVIEW: Tirmidhi 3153, Ibn Majah 4080)', priority='high')
    for pid in by_pattern(r'3513|laylat', 1):
        R.enrich(pid, why='Tirmidhi 3513 (du\'a for Laylat al-Qadr): graders disagree (Zubair Ali Za\'i da\'if, al-Albani sahih).',
                 source='FIX_HADI_REPORT (Laylat al-Qadr du\'a, graders disagree)', priority='high')

    # 7:143 little-finger report
    R.enrich('story.prophets.prophet-musa', why='Ibn Kathir cites a report that the mountain crumbled at the Lord\'s "little finger" (7:143); the report was not checked.',
             source='FACT_S1_prophets "Unverified / needs scholar review" (7:143 report)', priority='high')
    R.enrich('story.prophets.prophet-ismail', why='Which son was sacrificed: the Qur\'an leaves him unnamed; scholars differ. Subtitle "son of the dream" removed.',
             source=['FACT_S1_prophets (Ismail)', 'docs/OWNER_ACTIONS.md item 4'], priority='high')
    R.enrich('story.prophets.prophet-ibrahim', why='Ibrahim\'s place in heaven (Bukhari 349 vs 3207) is an open question; the sacrificed son is not named.',
             source='docs/OWNER_ACTIONS.md item 4', priority='high')
    R.enrich('story.prophets.prophet-dhul-kifl', why='Whether Dhul-Kifl was a prophet: identification not given (scholars differ).',
             source=['FACT_S1_prophets (Dhul-Kifl)', 'docs/OWNER_ACTIONS.md item 4'], priority='high')
    R.enrich('story.tales.tale-dhul-qarnayn', why='Who Dhul-Qarnayn was is open; Gog and Magog grading (Tirmidhi 3153, Ibn Majah 4080).',
             source=['docs/OWNER_ACTIONS.md item 4', 'FACT_S1_prophets'], priority='high')

    # Seerah-book-only details and Juwayriyya
    R.enrich('story.women.woman-juwayriyya', why='Two Juwayriyya accounts that are not harmonised (FACT_S2); also dropped from Games as unverified.',
             source=['FACT_S2_seerah (two Juwayriyya accounts)', 'FIX_GAMES_REPORT (Juwayriyya dropped)'], priority='high')
    for pid in by_pattern(r'Ibn Sa.d', 1):
        R.enrich(pid, why='Contains details sourced only to Ibn Sa\'d (for example Sumayyah\'s death, Zaynab bint Jahsh\'s funeral, Umm Ayman, Umm Umara).',
                 source='FACT_S2_seerah (Ibn Sa\'d-only details left for scholar review)', priority='high')
    for pid in by_pattern(r'Ibn Hisham', 1):
        R.enrich(pid, why='Chapters sourced only to Ibn Hisham\'s Sira; the app labels these "Seerah report".',
                 source='FACT_S2_seerah (Ibn Hisham-only chapters)', priority='high')

    # Unseen: Mahdi, Iblis, hell duration
    ids('story.ghayb.ghayb-2am-mahdi-jesus', 'story.ghayb.ghayb-iblis-refuses', 'story.ghayb.ghayb-2am-hell', 'hadi.core.mahdi')
    R.enrich('story.ghayb.ghayb-2am-mahdi-jesus', why='The Mahdi and who leads Isa in prayer: the reports and their grading are disputed.',
             source='docs/OWNER_ACTIONS.md item 4 (the Mahdi and Isa\'s prayer leader)', priority='high')
    R.enrich('hadi.core.mahdi', why='The Mahdi reports (grading disputed). Hadi states the disagreement.',
             source=['FIX_HADI_REPORT (the Mahdi)', 'docs/OWNER_ACTIONS.md item 4'], priority='high')
    R.enrich('story.ghayb.ghayb-iblis-refuses', why='Whether Iblis was a jinn or an angel (18:50 says he was of the jinn; some tafsir say otherwise).',
             source='docs/OWNER_ACTIONS.md item 4 / unseen stories (Iblis jinn or angel)', priority='high')
    R.enrich('story.ghayb.ghayb-2am-hell', why='How long the Fire lasts: scholars differ on the duration for those who enter it.',
             source='docs/OWNER_ACTIONS.md item 4 (how long the Fire lasts)', priority='high')
    R.enrich('lesson.char.u2.l3', why='Iblis in the Character course (jinn or angel; the whisper).', source='S2_eol_hlth_wmns_char', priority='high')
    for pid in by_pattern(r'istiwa', 1):
        R.enrich(pid, why='Istiwa ("rose over the Throne") and the "with you" ayat: three positions (Athari, Ashari, Maturidi) summarised in a madhab-style contrast. Written from general knowledge, not a quoted source.',
                 source=['S2_aqid_und_daw (every contrast step)', 'docs/OWNER_ACTIONS.md item 4 (istiwa)'], priority='high', also=['Fiqh scholar (per madhab)'])
    for pid in ('lesson.char.u2.l3', 'lesson.aqid.u1.l1', 'lesson.aqid.u1.l2'):
        R.enrich(pid, why='Teaches or mentions the Fire / eternity; scholars differ on how long the Fire lasts.',
                 source='docs/OWNER_ACTIONS.md item 4 (how long the Fire lasts)')

    # Hadi rulings on music/games/dating/credit cards/mahr/iddah
    for cid, topic in [('music', 'music'), ('games-ruling', 'games (nardashir, chess, dice, video games)'), ('dating-relationships', 'dating and relationships'),
                       ('credit-card', 'credit-card positions'), ('mahr', 'mahr minimum'), ('iddah', 'iddah and widow conduct'),
                       ('spouse-rights', 'spouse rights'), ('other-religions', 'other religions'), ('sunni-shia', 'Sunni/Shia wording'),
                       ('china-knowledge', '"seek knowledge in China" saying'), ('knowledge-importance', 'knowledge as fard'),
                       ('fast-medicine', 'fasting and medicine'), ('madhhab-which', 'madhhab-neutral wording'),
                       ('janazah-prayer', 'janazah prayer'), ('janazah-care', 'janazah care')]:
        R.enrich('hadi.core.' + cid, why='Named in FIX_HADI_REPORT "Scholar review needed": %s.' % topic, source='FIX_HADI_REPORT', priority='high')

    # Q&A and zihar / neglecting prayer / Abu Talib
    for pid in by_pattern(r'zihar', 1):
        R.enrich(pid, why='Zihar is on the owner list of open scholar questions.', source='docs/OWNER_ACTIONS.md item 4 (zihar)', priority='high')
    for pid in by_pattern(r'neglect|abandon.*prayer|leaving (the )?prayer|skipping prayer', 1):
        R.enrich(pid, why='The ruling on neglecting prayer is on the owner list of open scholar questions.', source='docs/OWNER_ACTIONS.md item 4', priority='high')

    # New Muslim days named in FACT_S4
    nm = {5: 'Start with two rak\'ahs must not read as permission to omit the five prayers (new Muslim: the five are obligatory).',
          9: 'Schools differ on the meat of the People of the Book (5:5).',
          11: 'Hanafis and others differ on whether the Fatihah is a pillar for every worshipper and for one praying behind an imam.',
          12: 'As day 5: state the obligation of all five prayers honestly beside the gentle ramp (Bukhari 1395).',
          15: 'Arithmetic fixed (a standard mushaf is 604 pages; two pages a day finish it in about a year); "revealed over 23 years" is the standard account.',
          18: 'Jumu\'ah is obligatory on adult resident men, which the page does not say.',
          21: '"Pray when you remember" applies to forgetting or oversleeping (Bukhari 597, Muslim 684), not deliberate delay; "Wasia suggests Fajr or Isha" is an app claim.',
          27: 'The hadith says the scholars (ulama) are the heirs of the prophets; graders differ (Abu Dawud 3641).',
          28: 'App feature claim ("Hadi with a scholar\'s channel") to check.'}
    for d, why in nm.items():
        R.enrich('new-muslim.newmuslim-%02d' % d, why='FACT_S4 day %d: %s' % (d, why), source='FACT_S4_modern_qa_feelings (New Muslim path scholar-review items)', priority='high')
    for pid in [i['id'] for i in R.items if i['area'] == 'new-muslim']:
        R.enrich(pid, why='New Muslim path: the whole 30-day path is untested with a new Muslim and unreviewed (R9_T3).', source='R9_T3_new_muslim')
