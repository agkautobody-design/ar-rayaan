from .know import kpack, K
from .sources import Q, HV, guide, xg

S = "Qur'an text"


def build():
    p = kpack('fasting_zakat_hajj', 'fasting_zakat_hajj',
              'Ramadan and fasting, the night prayers, Eid, zakat, zakat al-Fitr, sadaqah, hajj and umrah as short how-tos and facts, with where the four schools differ. Drawn from the Huda guides in the app.',
              ['fasting', 'zakat', 'hajj'])
    F = lambda *a, **k: K(p, 'fact', *a, **k)
    Hw = lambda *a, **k: K(p, 'howto', *a, **k)
    Fq = lambda *a, **k: K(p, 'faq', *a, **k)
    Dh = ['hanafi', 'maliki', 'shafii', 'hanbali']

    # ---- fasting
    F("Fasting in Ramadan is a pillar of Islam. The Qur'an decrees it as it was decreed on those before, so that you may become mindful of Allah. It runs from the dawn to the sunset.",
      [guide('huda-fasting'), Q('2:183', S), Q('2:187', S)], cross=[xg('huda-fasting')], tags=['fasting', 'ramadan'],
      trig=['why do we fast', 'what is fasting', 'ramadan fast', 'fasting hours'])
    Hw("Eat suhoor before dawn, for there is a blessing in it, and break the fast promptly at sunset. The Prophet used to break his fast with fresh dates, or dry dates, or water.",
       [guide('huda-fasting'), HV('bukhari:1923'), HV('bukhari:1957')], cross=[xg('huda-fasting')], tags=['fasting', 'suhoor', 'iftar'],
       trig=['suhoor', 'iftar', 'how to break fast', 'sehri'])
    Fq("If you eat or drink by forgetting, complete your fast. The Prophet said that Allah fed you and gave you drink.",
       [guide('huda-fasting'), HV('bukhari:1933')], cross=[xg('huda-fasting'), xg('huda-fasting')][:1], tags=['fasting', 'forgetting'],
       trig=['ate by mistake while fasting', 'forgot i was fasting', 'drank water forgetfully'])
    F("What happens when you eat forgetfully is not agreed by all the schools. Scholars differ: the Hanafi, Shafi'i and Hanbali schools say the fast is not broken, while the Maliki school says the fast is broken and the day is made up.",
      [guide('huda-fasting')], cross=[xg('huda-fasting')], tags=['fasting', 'madhhab'], schools=['hanafi', 'shafii', 'hanbali', 'maliki'],
      trig=['maliki forgetful eating', 'does forgetting break fast'])
    F("People who may break the fast are those who are ill or travelling, who make up the days later. The elderly who cannot fast feed a poor person for each day in most schools, and menstruating women make up the days.",
      [guide('huda-fasting'), Q('2:184', S)], cross=[xg('huda-fasting')], tags=['fasting', 'excused'],
      trig=['can i skip fasting', 'ill and fasting', 'travelling and fasting', 'elderly fasting', 'fidyah'])
    F("The rules for a pregnant or nursing woman who misses fasts differ by school. Scholars differ on whether she makes up the days only or also feeds a poor person for each day, depending on whether she fears for herself or for the child. Ask a scholar for your own case.",
      [guide('huda-fasting')], cross=[xg('huda-fasting')], tags=['fasting', 'pregnancy', 'madhhab'], schools=Dh,
      trig=['pregnant fasting', 'nursing mother fasting', 'breastfeeding fasting', 'fidyah pregnant'])
    F("Deliberate sexual intercourse in Ramadan requires expiation: freeing a slave, and if that is not possible fasting two months in a row, and if not feeding sixty poor people. For deliberate eating or drinking, scholars differ: the Hanafi and Maliki schools also require it, and the Shafi'i and Hanbali schools only for intercourse.",
      [guide('huda-fasting'), HV('bukhari:1936'), HV('muslim:1111')], cross=[xg('huda-fasting')], tags=['fasting', 'kaffarah', 'madhhab'], schools=Dh,
      trig=['kaffarah', 'broke fast on purpose', 'expiation of fast'], age=('adult',))
    F("Eye drops, and injections that do not nourish, do not break the fast in the majority view. Scholars differ on some medical cases, so ask about yours.",
      [guide('huda-fasting')], cross=[xg('huda-fasting')], tags=['fasting', 'medical'], schools=['other'],
      trig=['eye drops fasting', 'injection fasting', 'medicine while fasting', 'does insulin break fast'], dns=['For a medical case, tell the person to ask a doctor and a scholar; no medical advice.'])
    F("In the nights of Ramadan the Prophet prayed, and he said whoever stands in prayer in them out of faith and hope of reward has their past sins forgiven. The extra night prayer in Ramadan is called taraweeh.",
      [guide('huda-taraweeh'), HV('bukhari:37')], cross=[xg('huda-taraweeh')], tags=['taraweeh', 'ramadan'], trig=['taraweeh', 'night prayer ramadan', 'qiyam ramadan'])
    F("The number of rak'ahs in taraweeh differs. Scholars differ: the Hanafi, Shafi'i and Hanbali schools say twenty plus witr, the Maliki practice in Madinah is thirty-six, and all four accept eleven as the Prophet's practice.",
      [guide('huda-taraweeh'), HV('bukhari:1147')], cross=[xg('huda-taraweeh')], tags=['taraweeh', 'madhhab'], schools=Dh, trig=['how many rakat taraweeh', 'taraweeh 8 or 20', 'taraweeh rakah'])
    F("Laylat al-Qadr, the Night of Decree, is better than a thousand months. The Prophet said to seek it in the odd nights of the last ten nights of Ramadan.",
      [guide('huda-taraweeh'), Q('97:3', S), HV('bukhari:2017')], cross=[xg('huda-taraweeh')], tags=['laylat-al-qadr', 'ramadan'], trig=['laylat al qadr', 'night of power', 'night of decree', 'last ten nights'])
    F("I'tikaf is staying in the mosque for worship, and the Prophet did it in the last ten days of Ramadan. Scholars differ on its minimum time: the Hanafi, Shafi'i and Hanbali schools allow a day or less, and the Maliki school requires at least a day and a night.",
      [guide('huda-taraweeh'), HV('bukhari:2026')], cross=[xg('huda-taraweeh')], tags=['itikaf', 'madhhab'], schools=Dh, trig=['itikaf', 'seclusion in mosque'])

    # ---- Eid
    F("Fasting is forbidden on the two Eid days, the day of breaking the fast and the day of the sacrifice. The days of Tashriq, the eleventh to thirteenth of Dhul-Hijjah, are days of eating and drinking.",
      [guide('huda-eid'), HV('bukhari:1990')], cross=[xg('huda-eid')], tags=['eid', 'fasting'], trig=['fasting on eid', 'can i fast on eid', 'days of tashriq'])
    F("The Eid prayer is two rak'ahs with no adhan and no iqamah, and the sermon comes after the prayer. Wash, wear your best clothes and go to the prayer ground.",
      [guide('huda-eid')], cross=[xg('huda-eid')], tags=['eid'], trig=['eid prayer', 'how to pray eid', 'eid khutbah', 'eid adhan'])
    F("The extra takbirs in the Eid prayer differ. Scholars differ: the Hanafi school says three in each rak'ah, the Maliki and Hanbali schools six in the first and five in the second, and the Shafi'i school seven in the first and five in the second.",
      [guide('huda-eid')], cross=[xg('huda-eid')], tags=['eid', 'madhhab'], schools=Dh, trig=['eid takbirs', 'how many takbir eid'])

    # ---- zakat
    F("Zakat is a pillar of Islam. It is owed on wealth that reaches the minimum level, called the nisab, and is held for a year. The rate on savings and cash is one-fortieth, which is two and a half in every hundred.",
      [guide('huda-zakat'), Q('2:43', S), HV('bukhari:1454'), HV('bukhari:1395')], cross=[xg('huda-zakat')], tags=['zakat', 'rate'],
      trig=['what is zakat', 'zakat rate', 'how much is zakat', 'who must pay zakat'], dns=['Never compute the person\'s zakat from memory; send them to the calculator and a scholar.'])
    F("Zakat can be given only to the eight categories the Qur'an names: the poor, the needy, those employed to collect it, those whose hearts are being won, freeing captives, those in debt, in the cause of Allah, and the stranded traveller. It is not a general donation.",
      [guide('huda-zakat'), Q('9:60', S)], cross=[xg('huda-zakat')], tags=['zakat', 'recipients'], trig=['who can receive zakat', 'zakat recipients', 'eight categories', 'can i give zakat to'])
    F("Zakat on women's jewellery worn for adornment is disputed. Scholars differ: the Hanafi school says zakat is due, while the Maliki, Shafi'i and Hanbali schools say it is not due on lawful jewellery in ordinary use.",
      [guide('huda-zakat')], cross=[xg('huda-zakat')], tags=['zakat', 'jewellery', 'madhhab'], schools=Dh, trig=['zakat on jewellery', 'zakat on gold worn', 'wife gold zakat'])
    Fq("The Zakat Calculator in the app can work out an amount, and it states which school's rules it applies. For debts and your own case, ask a scholar.",
       [guide('huda-zakat')], cross=[xg('huda-zakat')], tags=['zakat', 'calculator'], trig=['calculate zakat', 'zakat calculator', 'zakat on debts'])
    F("Zakat al-Fitr is a charity due at the end of Ramadan. It is paid for each person before the Eid prayer, to the poor, as a purification for the fasting person and food for the needy. If it is paid after the prayer it is ordinary charity.",
      [guide('huda-zakat-fitr'), HV('bukhari:1503'), HV('bukhari:1509')], cross=[xg('huda-zakat-fitr')], tags=['zakat-fitr'], trig=['zakat al fitr', 'fitrana', 'sadaqat ul fitr', 'fitra'])
    F("Whether zakat al-Fitr may be paid in money differs. Scholars differ: the Hanafi school allows the value in cash, the Maliki and Shafi'i schools say food only, and the Hanbali relied-upon view is food. Use the figure your local scholars announce.",
      [guide('huda-zakat-fitr')], cross=[xg('huda-zakat-fitr')], tags=['zakat-fitr', 'madhhab'], schools=Dh, trig=['fitra in cash', 'can i pay fitrana in money'])
    F("Sadaqah is voluntary charity with no fixed amount or time. Even a good word is charity, and the Prophet said that charity does not decrease wealth. Giving in secret is praised.",
      [guide('huda-sadaqah'), Q('2:271', S), HV('bukhari:6023'), HV('muslim:2588')], cross=[xg('huda-sadaqah')], tags=['sadaqah'], trig=['sadaqah', 'voluntary charity', 'give charity', 'small charity'])

    # ---- hajj
    F("Hajj is a pillar of Islam, once in a lifetime for those who are able. Ability means the means to go and return, health, a safe road and provision for the family left behind.",
      [guide('huda-hajj-intro'), Q('3:97', S), HV('muslim:1337')], cross=[xg('huda-hajj-intro')], tags=['hajj'], trig=['hajj obligation', 'who must do hajj', 'is hajj obligatory', 'once in a lifetime'])
    F("The rites of Hajj are from the eighth to the thirteenth of Dhul-Hijjah, starting with ihram, then Mina, Arafah, Muzdalifah, stoning the jamarat, the sacrifice, the shaving or shortening, and the tawaf and sa'i.",
      [guide('huda-hajj-overview'), HV('muslim:1218')], cross=[xg('huda-hajj-overview')], tags=['hajj', 'steps'], trig=['hajj steps', 'days of hajj', 'hajj rituals', 'what happens in hajj'])
    F("The pillars of Hajj differ by school. Scholars differ: the Hanafi school counts standing at Arafah and the tawaf of Ifadah, the Maliki and Hanbali schools add ihram and sa'i, and the Shafi'i school also adds shaving or shortening and the order of the rites.",
      [guide('huda-hajj-intro')], cross=[xg('huda-hajj-intro')], tags=['hajj', 'madhhab'], schools=Dh, trig=['pillars of hajj', 'rukn hajj'])
    F("The three ways of doing Hajj are ifrad, hajj only; qiran, hajj and umrah together; and tamattu', umrah first and then hajj. Scholars differ on which is best: the Hanafi school prefers qiran, the Maliki and Shafi'i schools ifrad, and the Hanbali school tamattu'.",
      [guide('huda-hajj-intro'), HV('bukhari:1562')], cross=[xg('huda-hajj-intro')], tags=['hajj', 'madhhab'], schools=Dh, trig=['tamattu', 'qiran', 'ifrad', 'types of hajj'])
    Hw("Ihram: bathe, then men wear two unsewn cloths, make the intention at the miqat and say the talbiyah. The talbiyah continues until you begin the stoning on the tenth for Hajj, or until you begin tawaf for umrah.",
       [guide('huda-ihram')], cross=[xg('huda-ihram')], tags=['ihram', 'talbiyah'], trig=['ihram', 'talbiyah', 'miqat', 'ihram clothes'])
    Hw("Umrah in a day: enter ihram at the miqat, make seven circuits of the Kaaba, pray two rak'ahs behind the Station of Ibrahim, walk seven lengths between Safa and Marwah, then shave or shorten the hair.",
       [guide('huda-umrah'), guide('huda-tawaf'), HV('bukhari:1602'), Q('2:158', S)], cross=[xg('huda-umrah'), xg('huda-tawaf')], tags=['umrah', 'steps'], trig=['how to do umrah', 'umrah steps', 'tawaf', 'saee'])
    F("The ruling on umrah differs. Scholars differ: the Shafi'i and Hanbali schools say it is obligatory once in a lifetime, and the Hanafi and Maliki schools say a confirmed sunnah.",
      [guide('huda-umrah')], cross=[xg('huda-umrah')], tags=['umrah', 'madhhab'], schools=Dh, trig=['is umrah obligatory', 'umrah ruling'])
    F("The day of Arafah is the heart of Hajj. The Prophet said there is no day on which Allah frees more servants from the Fire, and the pilgrim stays at Arafah until sunset. The pilgrim does not fast on that day.",
      [guide('huda-arafat'), HV('muslim:1348')], cross=[xg('huda-arafat')], tags=['arafah', 'hajj'], trig=['day of arafah', 'arafat', 'standing at arafah'])
    return [p]
