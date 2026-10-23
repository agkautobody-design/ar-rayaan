# First-time user study (50 simulated personas)

Simulated users, not real people. Each ran the live app in a headless browser with no prior knowledge, one persona and 1-3 goals each. No sound; YouTube/Spotify, Firebase and other outside services were stubbed. Three prayer-time runs hit a rig timezone bug and were re-run.

## Totals
- Goals: 44 achieved, 41 partial, 15 failed (100 goals).
- Average satisfaction 3.0/5, frustration 2.7/5. 35 of 50 would keep using it; 4 felt it was a waste of time.
- Issues logged: 11 P0, 106 P1, 113 P2 (many duplicates).

## Ranked problems (count = personas who hit it)
1. **Home tiles shift when the hadith banner loads late** (9+). First tap opens Elder Mode (which saves a setting), Quick Access or Stories. Fixed in PR #53.
2. **Hidden features** (12+): Qibla, How to Pray, Arabic letters, 99 Names, Masajid, Jumu'ah time, Nikah guide. Found only by luck; search does not surface them.
3. **Search ranks Qur'an verses first and misses obvious terms** (8): "mulk", "qibla", "tasbih", "99 names", "madhab", "marriage", "charity", "tajweed".
4. **Hadi answers the wrong question or refuses vaguely** (10): "What is Islam?", madhabs, anxiety medication, Ramadan, sleep dua, dating.
5. **Qur'an reader**: audio bar takes ~40% of the screen, no surah search or jump-to-ayah, no memorise mode (6).
6. **Large text breaks layout**: words split mid-word, Prayer Times and Settings rows one letter per line (4).
7. **Elder Mode links into normal small screens** and back goes to the normal home (2).
8. **Jargon in prayer/fasting guides, "AI key" wording, no pictures** (7); pricing note buried (1).
9. **Dead-looking taps**: Hadi source card, Stories School cards, the share icon (3).
10. **Back navigation oddities**: onboarding slide after Steady yourself, "Something went wrong" after double back (3).
11. **Bookmarks/notes not visible under You** (2, one may be a test-rig storage artifact; unverified).
12. **Missing**: charity, family tree, Hijri-to-Gregorian, Ramadan planner, Bangla/Urdu translation, kids filter on stories, trivia vs a friend.

## Not verified yet
Items 2-12 come from single simulated runs. Ludo dice "?" (1 of 2 testers) and the bookmarks issue need checking before a fix.
