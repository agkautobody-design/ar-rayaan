from .lib import Pack
from .sources import app

NAV = app('lib/app/theme/widgets/app_bottom_nav.dart (bottom bar: Home, Faith, Family, Hadi, You)')
MENU = app('lib/features/menu/presentation/menu_screen.dart (menu sections and entries)')
REG = app('assets/system/module_registry.json (module names and live/gated/unbuilt status)')


def build():
    p = Pack('app_help', 'knowledge', 'app_help', 'both',
             'How to use every part of Ar-Rayaan, written from the menu, bottom bar and module registry. Status words (live, gated, coming soon) follow the registry.',
             ages=('all',), base_tags=['app-help'])
    A = p.add

    def H(text, trig, tags=(), src=None, code=None, sub=None, dns=()):
        A('app-help', text, code=code or 'help', trig=trig, tags=list(tags), src=src or [REG], age=['all'], sub=sub, dns=list(dns), scholar=False, clinician=False)

    H("The bar at the bottom has five places: Home, Faith, Family, Hadi and You. Home is your starting page, Faith holds worship and learning, Family is for family life, Hadi is the guide you can ask anything, and You is your own page.",
      ['bottom bar', 'navigation', 'where is', 'how do i navigate', 'tabs'], ['navigation'], [NAV], 'nav')
    H("The Menu lists everything in four groups: Faith and Worship, Healing and Guidance, Family and Community, and Tools and Resources. Settings, Your Journey and Share Ar-Rayaan sit at the bottom of the Menu.",
      ['menu', 'where is everything', 'all features', 'what can this app do'], ['navigation', 'menu'], [MENU], 'nav')
    H("To find something fast, use Search. Type a word, a topic or a question and it looks across the content in the app.",
      ['search', 'find something', 'looking for'], ['search'], [REG], 'search')
    H("Hadi is the guide inside the app. You can ask about worship, the Qur'an, daily life or how to use a screen. Hadi is an app, not a scholar or a doctor, and for rulings on your own situation it will point you to a qualified scholar.",
      ['what is hadi', 'who is hadi', 'ask hadi', 'chatbot'], ['hadi'], [REG], 'hadi',
      dns=['Say plainly that Hadi is an app; never imply it can give a personal fatwa or medical advice.'])
    H("Wasia is the teacher in the Academy. She guides lessons, quizzes and questions, with a gentler voice for children. Like Hadi, Wasia is an app and hands bigger questions to a teacher.",
      ['what is wasia', 'who is wasia', 'academy teacher'], ['wasia', 'academy'], [REG], 'wasia')
    H("Prayer Times shows the five daily prayers for where you are, with a choice of calculation methods. The Islamic Calendar shows the Hijri date and special days.",
      ['prayer times', 'adhan', 'when is fajr', 'hijri date', 'calendar'], ['prayer-times', 'calendar'], [MENU, REG], 'prayer')
    H("The Qibla Finder points toward the Kaaba from where you stand. Keep the phone flat and away from metal so the compass can settle.",
      ['qibla', 'direction of prayer', 'which way to pray'], ['qibla'], [MENU, REG], 'qibla')
    H("The Qur'an reader lets you read, bookmark and keep notes. You can save bookmarks into collections so that you can return to the verses that matter to you.",
      ['quran', 'read quran', 'bookmark', 'quran notes'], ['quran'], [MENU, REG], 'quran')
    H("Hadith holds the Forty Hadith of Imam an-Nawawi and a daily hadith. Each hadith shows its source and grade where one is on file, and the app labels anything that still needs scholar review.",
      ['hadith', 'daily hadith', 'forty hadith', 'nawawi'], ['hadith'], [MENU, REG], 'hadith')
    H("Dhikr and Du'a holds supplications for morning and evening and other moments of the day, including the Hisn al-Muslim collection. A tasbeeh counter is there for keeping count.",
      ['dua', 'dhikr', 'adhkar', 'tasbeeh', 'morning evening'], ['dua', 'dhikr'], [MENU, REG], 'dua')
    H("The Zakat Calculator helps you work out what you may owe. It is a tool, not a ruling. The Huda guide on zakat explains how it works, and a scholar can answer questions about your own wealth.",
      ['zakat calculator', 'calculate zakat', 'how much zakat'], ['zakat'], [MENU, REG], 'zakat',
      dns=['Never state a nisab figure or a ruling from memory; send to the calculator and the guide.'])
    H("Huda is the library of worship guides. It covers prayer, wudu, fasting, zakat, hajj, funerals and everyday manners, with notes on where the four schools differ.",
      ['huda', 'guides', 'how to guides', 'worship guide'], ['huda', 'guides'], [REG], 'huda')
    H("Islamic Courses is the Wasia Academy. It has structured courses with lessons, quizzes and exams. Pick a course and read one step at a time.",
      ['academy', 'courses', 'lessons', 'islamic courses', 'learn islam'], ['academy'], [MENU, REG], 'academy')
    H("The New Muslim path is a gentle thirty-day journey for people who are new to Islam or returning to it. It starts with the basics and goes at your pace, with no test and no pressure.",
      ['new muslim', 'revert', 'convert', 'just became muslim', 'thirty day'], ['new-muslim'], [REG], 'new-muslim')
    H("Sakina is the Healing for the Heart area. It offers calming tools, comfort cards, a mood check-in and a safety plan. It is not a clinic, and if you are in danger it shows help lines for your country.",
      ['sakina', 'healing', 'anxiety help', 'feeling low', 'calm'], ['sakina'], [MENU, REG], 'sakina',
      dns=['Never present Sakina as treatment; if risk is present, go to the support pack and helplines.json.'])
    H("For Your Heart helps you find a verse, a dua and a story that match what you feel right now. Pick a feeling and it opens a few things to read.",
      ['feelings', 'for your heart', 'i feel sad', 'comfort'], ['feelings'], [REG], 'feelings')
    H("Need help now opens a list of help lines for your country. It is there for emergencies and hard moments, and it is available from the Sakina area.",
      ['need help now', 'help lines', 'helpline', 'crisis', 'emergency'], ['help-lines', 'safety'], [REG], 'help',
      dns=['Never type a number here; join with helplines.json by country.'])
    H("Stories is the Library. It has collections on the prophets, the seerah, the companions, women of faith and more. Each story names its sources, and some carry a note when scholar review is still needed.",
      ['stories', 'library', 'prophet stories', 'seerah'], ['stories', 'library'], [MENU, REG], 'stories')
    H("The Messengers' Tree shows how the prophets are connected, as a family tree you can explore.",
      ['family tree', 'messengers tree', 'prophets tree'], ['family-tree'], [REG], 'tree')
    H("Khutbahs holds Friday sermons you can read or reuse for reflection. They are teaching texts and carry the same source labels as the rest of the app.",
      ['khutbah', 'friday sermon', 'jumuah'], ['khutbahs'], [REG], 'khutbah')
    H("Noor is a short piece of daily wisdom. Open it each day for a small reminder, and share it as a card if you wish.",
      ['noor', 'daily wisdom', 'daily reminder'], ['noor'], [REG], 'noor')
    H("Verse cards let you turn a verse into a picture and share it. Use Share Ar-Rayaan in the Menu to invite a friend with a link or a QR code.",
      ['verse card', 'share a verse', 'share app', 'invite a friend', 'qr code'], ['share'], [MENU, REG], 'share')
    H("The Player plays the adhan, naats and nasheeds. The Downloads page shows what is saved on your device.",
      ['adhan audio', 'nasheed', 'naat', 'player', 'audio'], ['player', 'audio'], [MENU, REG], 'player')
    H("Downloads shows what you have saved to use without a connection.",
      ['download', 'offline', 'storage', 'no internet', 'save for later'], ['downloads', 'offline'], [MENU, REG], 'downloads')
    H("Notes and Bookmarks keeps your own notes and the places you saved. They are stored on your device.",
      ['notes', 'bookmarks', 'my notes', 'saved'], ['notes'], [MENU, REG], 'notes',
      dns=['Do not claim notes are encrypted or backed up unless the app says so.'])
    H("My log adds up the days and prayers you write down. It has no streaks, nothing resets when a day is empty, and an empty day is just empty space on the calendar.",
      ['my log', 'tracking', 'habit', 'prayer log'], ['tracking'], [MENU], 'log')
    H("Games has Shatranj, Ludo, trivia, the 99 Names, Lineage, Ayah and Hijrah. They are for learning and fun, and the games with religious content carry the same review labels as the lessons.",
      ['games', 'play', 'shatranj', 'ludo', 'trivia', '99 names'], ['games'], [REG], 'games')
    H("Tayyib Finance covers zakat, sadaqah and halal investing basics, and Rayaan Stocks teaches halal financial learning. They teach; they do not give personal financial advice.",
      ['finance', 'sadaqah', 'halal stocks', 'invest', 'rayaan stocks'], ['finance'], [REG], 'finance',
      dns=['Never give investment advice or say a stock is halal for the person.'])
    H("The Masjid Finder helps you find mosques, and Tayyib Food helps you find halal food.",
      ['masjid finder', 'mosque near me', 'halal food', 'nearby'], ['masjid', 'food'], [REG], 'masjid')
    H("Ramadan Mode counts down to Ramadan, then shows a theme and a dua for each day. Set your location in Prayer Times to see suhoor and iftar countdowns. It also has a fasting-day tracker and a Qur'an juz tracker.",
      ['ramadan', 'ramadan mode', 'suhoor time', 'iftar time'], ['ramadan'], [REG], 'ramadan')
    H("Hajj and Umrah guides walk you through the rites step by step, from ihram to the day of Arafah. They sit inside Huda.",
      ['hajj guide', 'umrah guide', 'ihram', 'arafah'], ['hajj', 'umrah'], [REG], 'hajj')
    H("Elder Mode makes the app simpler for older users. With it on, the Home tab opens a simple home with three big doors. Elder Care has resources for looking after older family members.",
      ['elder mode', 'older person', 'simple mode', 'big buttons', 'grandparent'], ['elder'], [NAV, MENU, REG], 'elder')
    H("The Family Wing is for parents. Add your children, follow their lessons and ask Wasia. It sits behind a parent check, and a child's progress is stored on the device. It is not parenting advice.",
      ['family wing', 'add child', 'parent', 'kids', 'children progress'], ['family-wing', 'kids'], [MENU, REG], 'family')
    H("Marriage and Family Life opens the Family Life school in the Academy, starting with marriage. It is teaching material, not counselling.",
      ['marriage', 'family life', 'nikah course'], ['family-life'], [MENU], 'family')
    H("Community is the courtyard forum. It is not open yet, because it waits for moderation and review. When it opens it will carry clear rules for what can be posted.",
      ['community', 'forum', 'majlis', 'courtyard'], ['community'], [REG, MENU], 'community',
      dns=['Say honestly that it is not open yet; never promise a date.'])
    H("Language and Voice in Settings lets you change the app language and the voice. Text size is there too, in case you want bigger words.",
      ['language', 'change language', 'text size', 'bigger text', 'arabic', 'urdu', 'bangla', 'voice'], ['settings', 'language'], [MENU, REG], 'settings')
    H("You can sign up or sign in with an email, verify it, and reset your password if you forget it. Log out is in the Menu, and the app asks you to confirm so that you do not log out by accident.",
      ['sign in', 'log in', 'log out', 'account', 'sign up'], ['account'], [MENU, REG], 'account')
    H("Some screens say Scholar review needed. It means a named scholar has not yet reviewed that item. The content is shown with its sources, and the label goes away only when a named reviewer signs off.",
      ['scholar review needed', 'what does the label mean', 'reviewed', 'is this verified'], ['review', 'trust'], [REG], 'review')
    H("A tile marked Coming soon is not built yet. The app does not open features that are still being reviewed or built, and the true status of each feature is kept in one list.",
      ['coming soon', 'not available', 'greyed out', 'locked'], ['status'], [MENU, REG], 'status')
    H("The page on how we handle religious content explains how sources, grades and reviews work in Ar-Rayaan, and why something is labelled the way it is.",
      ['content policy', 'how do you check', 'sources policy', 'who wrote this'], ['policy', 'trust'], [REG], 'policy')
    H("Quick Access is a second home page with shortcuts to the things you use most.",
      ['quick access', 'shortcuts', 'second home'], ['quick-access'], [REG], 'quick')
    H("Daily Duas and the Hadiths for Our Times collections bring short, practical teachings to everyday situations. Open them from the Library or Search.",
      ['daily duas', 'modern hadith', 'hadiths for our times'], ['daily-duas'], [REG], 'daily')
    return [p]
