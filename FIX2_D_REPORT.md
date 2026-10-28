# Fix round 2, pass D: languages (Arabic, Urdu, Bangla)

PR: agkautobody-design/ar-rayaan #154, branch `fix2/d-languages`.

## Fixed
- Coverage: Prayer Times, Qibla, Hadi chrome, Qur'an labels, Faith, Family Trees, You, Settings body, Language & Voice, Support & wellbeing, pathways, Sources, Elder Care, Need help sheet, share preview, handout, Sakina hub labels. Mechanism: `lib/app/core/i18n/ui_phrases*.dart` (644 exact-match rows plus `{}` patterns) shown through the `Text` wrapper in `lib/app/theme/widgets/tr_text.dart`. Unmatched text stays English.
- "Language for support lines": new default "Follow the app language"; the Hadi controller, check-ins, support engine, pathway screens and crisis cards all read it (`resolveSupportLanguage`).
- Browser/device locale: `LocaleController.deviceChoice` preselects ar, ur or bn (not saved until the person picks).
- RTL: Latin text on an RTL screen is laid out left-to-right (full stops and question marks stay at the end); times and Hijri dates are isolated (`4:39 AM`); Hadi bubbles use the same rule; profile month names localised.
- Country contradiction: the Need help sheet no longer pre-selects a device-derived country, and says "no checked line of this kind saved for X" when a country is known but has no line of that kind. `CrisisResponses.regionNote` is kind-aware and localised.
- Crisis cards (7 kinds), follow-ups (5) and country notes in ar/ur/bn (`lib/features/sakina/domain/crisis_l10n.dart`). The verse is replaced by a reference-only pointer; help lines come only from `HelpResources`. A support reply with no wording in the chosen language is shown in English with a note in that language.
- Share footer ("Shared from Ar-Rayaan", "Free to use, no account needed" + link) in the UI language, in the preview and in the text actually sent.
- Sources "What stays on your device" now says Hadi conversations are not saved, matching the Privacy screen and main.
- Labels: visible "Native-speaker review needed" note (`NativeReviewNote`, safety variant on support/Hadi/Sakina/Need help) on every translated screen and at the end of each card; register items `lang.phrases.*` and `lang.crisis.cards-l10n`; `docs/OWNER_ACTIONS.md` item 22.
- Tests: `test/language_pass_d_test.dart` (no missing keys or slots, RTL direction, label present in ar/ur/bn and absent in en/tr, support language, device locale, card digits, country note property over every country and kind, share footer).

## Not fixed (and why)
- Qibla method and fiqh paragraphs, madhhab labels, scripture quotes, subscription text, Hadi's answers, wellbeing tools (check-in, grounding, safety plan): left in English on purpose (religious ruling or clinical text must not be machine-translated). They are listed in item 22.
- Turkish, Indonesian, French, Malay: stay honestly untranslated (the Language screen says so).
- Hadi starter chips stay English (Hadi understands English only).
- No native speaker has read any of it; every string is a machine draft and says so.
- No Flutter SDK was available locally; verification was CI only.
