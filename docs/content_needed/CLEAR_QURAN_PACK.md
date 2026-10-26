# The Clear Quran (Dr. Mustafa Khattab): what to supply

Status: the app is built to use The Clear Quran as the default English translation. Its text is NOT in the repo. Until the pack file exists, the reader shows the interim translation (Saheeh International) and every credit says "interim" and "The Clear Quran text is being added". Claude does not type, copy or fetch the text from any source.

## The one file

One of these two, from the publisher (or from a source the publisher authorises in writing):

1. A plain text file, UTF-8, 6,236 lines, one verse per line, in order, as `surah|ayah|text` (for example `1|1|<verse text>`). No blank verses, no line breaks inside a verse, text exactly as the publisher issues it (including footnote markers if the publisher wants them kept or removed: say which).
2. Or a finished pack JSON (format in `lib/features/quran/domain/translation_pack.dart`).

## The one command

```
python3 tool/translation_pack.py import clear_quran.txt --preset clear-quran \
  --license-id "<reference of the publisher's written permission>" \
  --attribution "<the exact credit/copyright line the publisher requires>"
```

It checks 114 surahs, 6,236 ayahs, order, no empty verses, schema and checksum; refuses a placeholder licence id; writes `assets/quran/translations/en.clear-quran.json` and updates `manifest.json`. Then commit those two files, open a PR, let CI pass, merge. No code change. Check any file first with `python3 tool/translation_pack.py validate FILE`.

The reader, search, copy/share text, bookmark export, story layers, Settings > Qur'an translation and Our Sources switch to the pack's own attribution and licence reference automatically.

## What the publisher's authorisation must cover

Get all of these in writing and quote the reference as `--license-id`:

- Distribution inside the app (web, Android, iPhone) as a bundled data file.
- Offline use, including the browser copy and a downloaded copy on the device.
- Sharing and copying excerpts (single ayahs, bookmark collections, handouts, share cards), with the credit line the publisher requires.
- Search over the text inside the app.
- Derived-language translations, if the owner wants Urdu, Bangla or other languages made from it (who may translate, who checks, how they are credited). If not covered, those languages must come from their own licensed sources.
- Use of the text by Hadi (the AI guide) when it quotes ayahs: allowed or not.
- The exact wording of the attribution and copyright line, and whether the publisher's name/logo may be shown.
- Duration, territories, updates (new editions replace the pack by version).

## Other languages (Urdu, Bangla, Arabic tafsir-free)

Same mechanism: one pack per translation, each with its own `licenseId`, `attribution` and `rtl` (true for Urdu and Arabic). Import with `tool/translation_pack.py import FILE --id ur.<slug> --language ur --rtl --title ... --translator ... --publisher ... --url ... --license-id ... --attribution ...`. Nothing is bundled without a licence id; the CI test fails if a bundled pack lacks a granted licence. "Arabic, tafsir-free" means plain Arabic wording of the meaning with no commentary; the owner must name the source and licence.

## Not switched yet (needs an owner decision)

These carry their own fixed Saheeh wording and credit and do not follow the pack: Sakina verses, the daily verse on Academy Home, static share cards (`assets/share/cards.json`), the Qur'an games, and Hadi's Qur'an passages. They stay interim until the owner says to re-source them.

## Does the publisher offer an official data route? (checked 24 Oct 2026)

What I could find. I could not read the terms themselves (the pages render with JavaScript and the fetch returned only metadata), so nothing below is a statement of permission.

- Official site: https://theclearquran.org . Its machine-readable index https://theclearquran.org/llms.txt lists: Copyright (`/copyright`, "Copyright and licensing information"), Organizations (`/organizations`, "Partnership and API program"), Contact (`/contact`, "Contact Al-Furqaan Foundation"), Apps (`/the-clear-quran-series-apps/all`). Open `/organizations` and `/copyright` in a browser and read them: the Organizations page is the likely route to an API or app licence.
- Official apps: https://apps.theclearquran.org .
- Publisher named on the site: Al-Furqaan Foundation.
- Third parties list the translation (for example https://qul.tarteel.ai/resources/translation/426), which is not permission to use it.
- No public developer or API terms were found. Ask Al-Furqaan Foundation through the Organizations or Contact page for: an API or data licence, or an app licence, covering the list above.

Do not use data from unofficial sites or third-party APIs without the publisher's written permission.
