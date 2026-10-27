"""Shared pieces of the scholar-review register builder.

Reviewer types, area labels and the Item record. Pure data, no I/O.
"""

# Reviewer types (exact strings used in register.json and the markdown).
HADITH = "Hadith / aqidah scholar"
FIQH = "Fiqh scholar (per madhab)"
WOMEN = "Women's scholar"
ARABIC = "Arabic / tajweed / qira'at specialist"
CLIN = "Clinician (Sakina and health content)"
NATIVE = "Native speaker (ar / bn / ur)"
LAWYER = "Privacy lawyer"
RIGHTS = "Rights holder / licensing (not a scholar)"

REVIEWER_TYPES = [HADITH, FIQH, WOMEN, ARABIC, CLIN, NATIVE, LAWYER, RIGHTS]

MADHABS = ["Hanafi", "Maliki", "Shafi'i", "Hanbali"]

# Areas: key -> (title, surfaces note)
AREAS = [
    ("academy-lessons", "Academy v3 lessons and steps"),
    ("academy-phrases", "Academy phrase registry (transliteration, meaning, word glosses)"),
    ("academy-glosses", "Academy word glosses (300)"),
    ("academy-schools", "Academy schools, Path lessons and static course screens"),
    ("arabic-tajweed", "Arabic, tajweed, Hifz and Qur'an recitation teaching"),
    ("huda", "Huda guides and their madhhab notes"),
    ("qa", "Q&A bank rulings"),
    ("hadi", "Hadi built-in answers"),
    ("hadith", "Hadith: Forty Nawawi, Daily Hadith, grades, Hadi grounding corpus"),
    ("stories-prophets", "Stories: prophets, layers and earlier accounts"),
    ("stories-seerah", "Stories: seerah, companions, women"),
    ("stories-unseen", "Stories: the unseen, signs, tales, khutbahs"),
    ("stories-modern", "Stories: modern hadith"),
    ("dua-dhikr", "Dua, dhikr, Hisn, adhkar, Ramadan duas, daily duas"),
    ("new-muslim", "New Muslim 30-day path"),
    ("sakina", "Sakina rooms, feelings, safety copy, health"),
    ("money", "Zakat, will and estate, halal finance"),
    ("prayer-calendar", "Prayer times, qibla, Hijri calendar, observances"),
    ("quran-text", "Qur'an text, translation, transliteration, licences"),
    ("games", "Games and quizzes with religious content"),
    ("languages", "UI labels and crisis phrases in Arabic, Bangla, Urdu"),
    ("legal", "Privacy, terms, children's privacy, community rules"),
    ("noor-cards", "Noor, share cards, Home daily cards"),
    ("nasheeds", "Nasheeds and audio"),
]
AREA_TITLE = dict(AREAS)

PRIORITIES = ("high", "normal", "low")
