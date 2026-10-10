# Ar-Rayaan Voice Relay

One small service, same vault pattern as QF: holds the TTS provider key
server-side, speaks for Wasia and Hadi in a natural, warm, multilingual voice
(Google/Azure neural TTS: 40+ languages, tender-female voices included).

## Why a relay
A website's JavaScript cannot hold a paid TTS key (every visitor would see it).
The relay keeps it secret and speaks on the app's behalf.

## Deploy (founder's evening, 5 min, free tier)
1. dashboard.render.com → New → Web Service → ar-rayaan repo
2. Root: services/voice · Build: pip install -r requirements.txt
   · Start: gunicorn app:app --workers 2 --threads 4 · Free tier
3. Env: TTS_PROVIDER=google (or azure) · TTS_KEY=(your key)
   · TTS_ORIGIN=https://ar-rayaan.onrender.com
4. App build flag: AR_VOICE_URL = the relay's URL

## Voice roles (FOUNDER LAW — fixed, not user-selectable)
- HADI = male voice (the guide)
- WASIA = female voice (the teacher)
The relay requests these genders explicitly from the provider; there is no
setting to swap them — the roles are part of who they are.

## Then
Wasia and Hadi speak aloud in the language the user chose in Settings —
the same engine the big assistants use, but private and on your terms.
A recorded human narrator (the ceiling — a real voice artist, every lesson,
every tongue) is a content project to commission when the community funds it.
