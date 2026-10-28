# FIX ROUND 3, pass C report

No Flutter SDK was available; nothing here was compiled or run locally. CI is the only check.

## Fixed (code)
- Quick exit: history entry replaced with cleared inner state (serialCount kept) and `#/home`. Entries before it (e.g. Menu) cannot be deleted by a page; Back may still land on those.
- Lesson-check result: focusable labelled live-region node plus Announce.
- Offline banner: explicit labelled status-role semantics node.
- Dialog role: NamedRoute carries SemanticsRole.dialog; new `showNamedSheet` replaces every showModalBottomSheet site (26 files), each labelled.
- Escape closes the top dismissible sheet/dialog (KeyboardBackScope).
- Tab to an off-screen control scrolls it into view (FocusSafeSemantics).
- Home: no Back node in Home semantics; Quick Access always kept at 150% zoom; Elder card shows On/Off.
- Hadi: icon-only pill now has a text label; header height capped when squeezed.
- Try again: auto-retry when the connection returns.
- web/index.html: guard against the `reading 'active'` error (likely test-harness stub; defensive only).
- Languages: native-language crisis follow-ups and repeats (ar/ur/bn) always carry the emergency line; English fallback carries a note in the user's language; Qur'an 93:3 quote mark kept in RTL via per-line LTR isolates; "Native-speaker review needed" shown in the page's own language; Hadi welcome text translated; text-size labels and first Family Wing strings added (group `pass3c`). Scholar register regenerated.
- Downloads copy checked: no stale lines.

## Not fixed (reason)
- Back needing repeated taps on RTL pages: no cause found in code, not reproducible without a browser.
- Full Family Wing (about 70 strings), Hadi chips, Settings/Qur'an/Sources blocks, Hijri month names: not translated in this pass; they still show English. Needs a follow-up.
- Bangla Prayer Times/Qibla/Family Wing coverage: not re-audited.
- Real screen-reader and real-device behaviour untested. All ar/ur/bn text remains machine-drafted and needs native-speaker review.
