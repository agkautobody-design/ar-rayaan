from .know import kpack, K
from .sources import Q, HV, guide, lesson, xg, xl

S = "Qur'an text"
FAM = 'family'


def build():
    p = kpack('family_parenting', 'family_parenting',
              'Marriage, home life, parents and raising children, written from the Family Life school and the Huda guides in the app. Teaching material and prophetic examples, not counselling or a ruling for a particular case.',
              ['family', 'parenting'], audience='hadi')
    F = lambda *a, **k: K(p, 'fact', *a, age=('adult',), **k)
    Hw = lambda *a, **k: K(p, 'howto', *a, age=('adult',), **k)
    Fq = lambda *a, **k: K(p, 'faq', *a, age=('adult',), **k)

    F("In Islam marriage is a solemn promise before Allah, not just a celebration or a paper. The Qur'an says spouses are signs of calm, affection and mercy, and calls the marriage bond a solemn covenant.",
      [lesson(FAM, 'fam.u1.l1'), Q('30:21', S), Q('4:21', S)], cross=[xl(FAM, 'fam.u1.l1')], tags=['marriage'], trig=['purpose of marriage', 'why marry', 'what is marriage in islam', 'marriage in islam'])
    F("Islam encourages marriage and does not ask believers to give up family life in order to worship more. The Prophet told young people who can marry to marry, since it helps them lower the gaze and guard their modesty.",
      [lesson(FAM, 'fam.u1.l1'), HV('bukhari:5066'), HV('bukhari:5063'), Q('24:32', S)], cross=[xl(FAM, 'fam.u1.l1'), xg('huda-nikah')], tags=['marriage'], trig=['should i marry', 'encouraged to marry', 'celibacy in islam'])
    F("Consent matters in marriage. The Prophet said a previously married woman should not be married without being consulted, and a woman who has not been married should not be married without her permission, which her silence can show.",
      [guide('huda-nikah'), HV('bukhari:5136')], cross=[xg('huda-nikah')], tags=['marriage', 'consent'], trig=['forced marriage', 'consent in marriage', 'does a woman have to agree'],
      dns=['If a person describes being forced into marriage or fearing it, move to the support pack and helplines; never counsel obedience.'])
    F("The mahr is the bride's right, and even something small can be a mahr. The Prophet told a man to look for something, even an iron ring. A wedding feast, the walimah, is encouraged, even if simple.",
      [guide('huda-nikah'), Q('4:4', S), HV('bukhari:5167')], cross=[xg('huda-nikah')], tags=['marriage', 'mahr'], trig=['mahr', 'dowry', 'walimah', 'wedding feast'])
    F("The role of the guardian in the marriage contract differs by school. Scholars differ: the Maliki, Shafi'i and Hanbali schools say the contract is not valid without a guardian, while the Hanafi school lets an adult woman contract her own marriage, though the guardian may object in some cases.",
      [guide('huda-nikah')], cross=[xg('huda-nikah')], tags=['marriage', 'madhhab', 'wali'], schools=['hanafi', 'maliki', 'shafii', 'hanbali'], trig=['wali', 'guardian in marriage', 'can a woman marry herself'])
    F("The best of you is the one who is best to his family. The Prophet said it and added that he was the best of them to his family. This is a measure of goodness that cannot be faked, because family sees you when you are not performing.",
      [lesson(FAM, 'fam.u1.l2'), HV('tirmidhi:3895')], cross=[xl(FAM, 'fam.u1.l2')], tags=['marriage', 'character'], trig=['best to his family', 'treat family well', 'be good to my wife'])
    F("The Prophet was playful and attentive at home. He once raced Aisha on foot, and he noticed her moods and said so kindly. A good home has laughter and attention in it.",
      [lesson(FAM, 'fam.u1.l2'), HV('abudawud:2578'), HV('bukhari:5228')], cross=[xl(FAM, 'fam.u1.l2')], tags=['marriage', 'sunnah'], trig=['prophet with his wife', 'romance in islam', 'play with spouse'])
    F("The Prophet never struck anyone with his hand, neither a woman nor a servant. He also told people who quarrel to avoid the face. Harsh treatment at home has no support in his example.",
      [lesson(FAM, 'fam.u1.l2'), HV('muslim:2328'), HV('muslim:2612')], cross=[xl(FAM, 'fam.u1.l2')], tags=['marriage', 'safety'], trig=['hitting wife', 'is it allowed to hit', 'violence at home'],
      dns=['If someone is being hurt, move to the domestic abuse support pack; never quote or interpret 4:34.'], clinician=True, risk='medium')
    F("Spouses are described as garments for each other, which scholars take to mean covering and protecting one another's faults. The Prophet said Allah conceals the faults of one who conceals the faults of others, so do not use a spouse's faults as stories for friends or posts.",
      [lesson(FAM, 'fam.u1.l3'), Q('2:187', S), HV('muslim:2590')], cross=[xl(FAM, 'fam.u1.l3')], tags=['marriage', 'privacy'], trig=['talk about spouse faults', 'covering faults', 'privacy in marriage'])
    Fq("If a couple cannot settle a quarrel alone, the Qur'an points to a step between silence and separation: send a fair person from each family. If both want peace, Allah will bring it about between them.",
       [lesson(FAM, 'fam.u1.l3'), Q('4:35', S), Q('4:128', S)], cross=[xl(FAM, 'fam.u1.l3')], tags=['marriage', 'conflict'], trig=['marriage problems', 'we keep fighting', 'arguments at home', 'mediation'])
    Fq("Divorce is allowed in Islam but it is a serious matter with detailed rules, and the schools differ in some of them. Ask a qualified imam rather than social media. A spouse must not be kept in order to harm them, and a person who is being hurt should be protected.",
       [lesson(FAM, 'fam.u1.l3'), Q('2:231', S)], cross=[xl(FAM, 'fam.u1.l3')], tags=['marriage', 'divorce'], trig=['divorce', 'talaq', 'should i leave my marriage', 'marriage in trouble'],
       dns=['No ruling; if safety is an issue go to the support pack and helplines.json.'])
    F("A Muslim marriage is a partnership at home too. Aisha said that the Prophet kept himself busy serving his family, and when the prayer was called, he went out for it. Work at home and worship were not enemies.",
      [lesson(FAM, 'fam.u3.l1')], cross=[xl(FAM, 'fam.u3.l1')], tags=['marriage', 'housework'], trig=['housework', 'who does the dishes', 'prophet helped at home'])

    # parents
    F("Kindness to parents comes straight after worship of Allah in the Qur'an. Even a word of impatience is discouraged, and speech to them should be gentle and generous.",
      [lesson(FAM, 'fam.u2.l1'), guide('huda-parents'), Q('17:23', S), Q('31:14', S)], cross=[xl(FAM, 'fam.u2.l1'), xg('huda-parents')], tags=['parents'], trig=['honour parents', 'respect parents', 'treat parents well'])
    F("A man asked the Prophet who deserved his best company most. He said your mother, then your mother, then your mother, then your father.",
      [guide('huda-parents'), HV('bukhari:5971')], cross=[xg('huda-parents')], tags=['parents', 'mother'], trig=['rights of mother', 'who first mother or father'])
    F("Kindness to parents has limits. The Qur'an says that if they press you to join others with Allah, do not follow them in that, yet still keep good company with them in worldly matters.",
      [guide('huda-parents'), Q('31:15', S)], cross=[xg('huda-parents')], tags=['parents', 'limits'], trig=['parents ask me to do wrong', 'disobey parents', 'parents against islam'],
      dns=['Do not tell a person in an unsafe home to stay or obey; move to support pack if there is harm.'])
    F("Caring for elderly parents is a duty and an opportunity. The Qur'an asks for humility toward them and a prayer for mercy on them as they cared for you when you were small.",
      [lesson(FAM, 'fam.u2.l2'), Q('17:24', S)], cross=[xl(FAM, 'fam.u2.l2')], tags=['parents', 'elderly'], trig=['old parents', 'looking after parents', 'nursing home'])
    Fq("Keeping family ties matters even when relatives are hard to be around. The Family Life school teaches that cutting ties is a serious matter, and that the aim is to keep whatever contact is safe and healthy, with kindness and boundaries.",
       [lesson(FAM, 'fam.u2.l3')], cross=[xl(FAM, 'fam.u2.l3')], tags=['kinship'], trig=['family ties', 'toxic family', 'cut off family', 'silat al rahim'],
       dns=['Never push contact with someone abusive; safety first.'])

    # children
    F("A child is a trust. The Qur'an asks believers to guard themselves and their families, and the Prophet said each of you is a shepherd and answerable for his flock, including the people of the home.",
      [lesson(FAM, 'fam.u3.l1'), Q('66:6', S), HV('bukhari:893')], cross=[xl(FAM, 'fam.u3.l1')], tags=['parenting'], trig=['responsibility for children', 'raising children in islam', 'parenting islam'])
    F("The Prophet was gentle and affectionate with children. He kissed his grandsons, and when a man said he had ten children and had never kissed one, the Prophet said that whoever shows no mercy will be shown none.",
      [lesson(FAM, 'fam.u3.l2'), guide('huda-children-deen'), HV('bukhari:5997')], cross=[xl(FAM, 'fam.u3.l2'), xg('huda-children-deen')], tags=['parenting', 'mercy'], trig=['kiss children', 'affection to children', 'prophet with children'])
    F("Be fair between your children. The Prophet told a father who gave one son a gift to fear Allah and treat his children with justice, and asked him to take the gift back.",
      [lesson(FAM, 'fam.u3.l2'), HV('bukhari:2587')], cross=[xl(FAM, 'fam.u3.l2')], tags=['parenting', 'fairness'], trig=['favourite child', 'treating kids equally', 'gift one child'])
    F("Teach prayer gently and early. Let children see you pray, invite them to join, praise their effort and keep it light. The guide in the app stresses patience, routine and example over pressure.",
      [guide('huda-children-deen')], cross=[xg('huda-children-deen')], tags=['parenting', 'salah'], trig=['teach child to pray', 'age to pray', 'child prayer age'],
      dns=['Never cite the seven/ten hadith or any striking wording; present calm routine and example.'], risk='medium', clinician=True)
    F("Begin teaching a child about Allah with love, not fear. Let them see you pray, thank Allah and be kind, and answer their questions simply and honestly. Habits at home teach more than lectures.",
      [lesson(FAM, 'fam.u3.l3'), guide('huda-children-deen')], cross=[xl(FAM, 'fam.u3.l3'), xg('huda-children-deen')], tags=['parenting', 'tarbiyah'], trig=['teach child about allah', 'my child asks about god', 'islamic upbringing'])
    F("The Qur'an records Luqman advising his son with tenderness: do not associate others with Allah, be grateful, be steady in prayer and walk humbly. It is a model of how advice sounds when it comes from love.",
      [lesson(FAM, 'fam.u3.l3'), Q('31:13', S), Q('31:17-19', S)], cross=[xl(FAM, 'fam.u3.l3')], tags=['parenting', 'luqman'], trig=['luqman advice', 'advice to my son'])
    Fq("What if a teenager stops praying or pulls away from the faith? Stay close rather than lecturing. Listen first, keep the door open, pray for them as the prophets did, and set an example. If you worry they are unsafe, a trusted imam, counsellor or doctor can help.",
       [guide('huda-children-deen'), Q('20:132', S)], cross=[xg('huda-children-deen')], tags=['parenting', 'teens'], trig=['teen not praying', 'my son stopped praying', 'my daughter left islam'],
       dns=['If the teen is at risk of self-harm, move to the support pack; no blame wording.'], clinician=True, risk='medium')
    return [p]
