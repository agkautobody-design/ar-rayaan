from .know import kpack, K
from .sources import Q, HV, guide, xg

S = "Qur'an text"


def build():
    p = kpack('etiquette', 'etiquette',
              'Everyday Islamic manners (adab): eating, greetings, speech, sleep, home, neighbours, parents, visiting the sick, condolence, gratitude and seeking knowledge. Drawn from the Huda guides in the app.',
              ['etiquette', 'adab'])
    E = lambda *a, **k: K(p, 'etiquette', *a, **k)

    E("Begin eating by mentioning Allah's name, and if you forget, say it when you remember. Eat with the right hand and from the part of the dish nearest to you.",
      [guide('huda-food'), HV('bukhari:5376')], cross=[xg('huda-food')], tags=['eating'], trig=['eating manners', 'bismillah before eating', 'right hand eating', 'how to eat islamic'])
    E("Do not overfill the stomach. The guide gives the saying that a few mouthfuls are enough to keep the back straight, and that if one must, a third is for food, a third for drink and a third for air.",
      [guide('huda-food')], cross=[xg('huda-food')], tags=['eating', 'moderation'], trig=['overeating', 'third of stomach', 'eat less'])
    E("Eat together. The Prophet said the food of two is enough for three, and the food of three is enough for four.",
      [guide('huda-food'), HV('bukhari:5392')], cross=[xg('huda-food')], tags=['eating', 'sharing'], trig=['eating together', 'sharing food', 'food for two'])
    E("Thank Allah while eating. The Prophet said Allah is pleased with a servant who says alhamdulillah after a morsel of food and a sip of drink.",
      [guide('huda-food'), HV('muslim:2734')], cross=[xg('huda-food')], tags=['eating', 'gratitude'], trig=['dua after eating', 'thank allah for food'])
    E("Greet people you know and people you do not know. A man asked the Prophet which part of Islam is best, and he said to feed the poor and greet those you know and those you do not know.",
      [guide('huda-greeting'), HV('bukhari:12')], cross=[xg('huda-greeting')], tags=['greeting', 'salam'], trig=['salam', 'how to greet', 'assalamu alaykum', 'greet strangers'])
    E("Spread the salam among yourselves, because it builds love. The Prophet taught that you will not believe until you love one another, and spreading the greeting fosters that love.",
      [guide('huda-greeting'), HV('muslim:54')], cross=[xg('huda-greeting')], tags=['greeting', 'salam'], trig=['spread salam', 'importance of salam'])
    E("The younger person greets the elder, the passer-by greets the one sitting, and the small group greets the large group. If someone greets you, reply with a better greeting or at least the same.",
      [guide('huda-greeting'), HV('bukhari:6231'), Q('4:86', S)], cross=[xg('huda-greeting')], tags=['greeting'], trig=['who greets first', 'reply to salam'])
    E("When you sneeze, say alhamdulillah. The one who hears it says yarhamukallah, and you reply with the dua that Allah guide them and set their affairs right.",
      [guide('huda-greeting'), HV('bukhari:6224')], cross=[xg('huda-greeting')], tags=['sneezing'], trig=['sneezing', 'what to say when sneezing', 'yarhamukallah'])
    E("Whether to start the salam to a non-Muslim, and how to return their greeting, is a question that scholars treat in detail. Scholars differ, so ask a qualified scholar.",
      [guide('huda-greeting')], cross=[xg('huda-greeting')], tags=['greeting', 'non-muslim'], schools=['other'], trig=['salam to non muslim', 'greet christians', 'greet a non-muslim'])
    E("Five rights a Muslim has over another: return their greeting, visit them when ill, follow their funeral, accept their invitation, and say yarhamukallah when they sneeze.",
      [guide('huda-greeting'), HV('muslim:2162')], cross=[xg('huda-greeting')], tags=['rights', 'brotherhood'], trig=['rights of a muslim', 'rights of brother'])
    E("Speak good or keep quiet. The Prophet said whoever believes in Allah and the Last Day should say what is good or be silent.",
      [guide('huda-speech'), HV('bukhari:6475')], cross=[xg('huda-speech')], tags=['speech'], trig=['good speech', 'speak good or be silent', 'watch your tongue'])
    E("Do not backbite. The Qur'an compares it to eating the flesh of your dead brother. Scholars allow naming a wrong only for a need, such as seeking justice, warning someone of harm, or asking a scholar for a ruling.",
      [guide('huda-speech'), Q('49:12', S), Q('4:148', S)], cross=[xg('huda-speech')], tags=['speech', 'backbiting'], trig=['backbiting', 'gheebah', 'talking behind someone'])
    E("Avoid arguing even when you are right. The Prophet promised a house in the surroundings of Paradise for a man who leaves quarrelling even when he is right.",
      [guide('huda-speech')], cross=[xg('huda-speech')], tags=['speech', 'arguing'], trig=['arguing', 'quarrelling', 'debate manners'])
    E("Before sleep, make wudu as for prayer, lie on your right side, and say the words the Prophet taught. He also used to cup his hands, recite the last three surahs, blow into them and wipe over his body.",
      [guide('huda-sleep'), HV('bukhari:247'), HV('bukhari:5017')], cross=[xg('huda-sleep')], tags=['sleep'], trig=['sleeping manners', 'before sleep', 'sunnah of sleeping', 'right side sleeping'])
    E("Enter the home with the right foot and mention Allah's name, and greet the people of the house with peace. The Qur'an tells us to give greetings of peace upon each other when we enter houses.",
      [guide('huda-home'), Q('24:61', S)], cross=[xg('huda-home')], tags=['home'], trig=['entering home', 'dua entering house', 'leaving home dua'])
    E("The neighbour has a great right. The Prophet said that Jibril kept advising him about the neighbour so much that he thought the neighbour would be made an heir. Someone whose neighbour is not safe from their harm does not truly believe.",
      [guide('huda-neighbors'), HV('bukhari:6014'), HV('bukhari:6016'), Q('4:36', S)], cross=[xg('huda-neighbors')], tags=['neighbours'], trig=['rights of neighbours', 'neighbor', 'neighbour manners'])
    E("Share food with your neighbour, and give gifts first to the one whose door is nearer to you.",
      [guide('huda-neighbors'), HV('bukhari:6020')], cross=[xg('huda-neighbors')], tags=['neighbours', 'sharing'], trig=['gift to neighbour', 'share food neighbours'])
    E("Treat your parents with good companionship and never say a word of impatience to them. The Prophet said the mother has the first claim on your good company, then again the mother, then again the mother, then the father.",
      [guide('huda-parents'), Q('17:23-24', S), HV('bukhari:5971')], cross=[xg('huda-parents')], tags=['parents'], trig=['rights of parents', 'respect parents', 'honour mother', 'say uff to parents'])
    E("Your parents are to be followed in what is lawful. No one is to be followed in something that disobeys Allah.",
      [guide('huda-parents'), HV('bukhari:7257')], cross=[xg('huda-parents')], tags=['parents', 'limits'], trig=['obey parents', 'parents ask me to do wrong', 'limit of obedience'],
      dns=['If a young person describes harm from a parent, move to the support pack; never use this to press obedience.'])
    E("After your parents die you can still do good for them. The Prophet said that a man's deeds end except for continuing charity, knowledge that helps others, and a righteous child who prays for him.",
      [guide('huda-parents'), HV('muslim:1631')], cross=[xg('huda-parents')], tags=['parents', 'dua'], trig=['dua for deceased parents', 'help parents after death'])
    E("Visit the sick and ask Allah for their healing. The Prophet used to say: take away the disease, Lord of the people, cure him, for You are the One who cures.",
      [guide('huda-illness'), HV('bukhari:5675'), HV('muslim:2162')], cross=[xg('huda-illness')], tags=['illness', 'visiting'], trig=['visit the sick', 'dua for sick', 'ill person'])
    E("Seek treatment when you are ill. The Prophet said Allah has not created a disease except that He has also created its treatment, and illness can be a means of forgiveness for a believer.",
      [guide('huda-illness'), HV('bukhari:5678'), HV('bukhari:5641')], cross=[xg('huda-illness')], tags=['illness', 'treatment'], trig=['is it okay to take medicine', 'tawakkul and medicine', 'seeing a doctor'])
    E("When someone is bereaved, say words of comfort and bring food. The Prophet taught that what Allah takes is His and what He gives is His, and told the community to prepare food for the family of Jafar.",
      [guide('huda-condolence'), HV('bukhari:1284')], cross=[xg('huda-condolence')], tags=['condolence', 'death'], trig=['condolence', 'what to say when someone dies', 'comfort the bereaved', 'inna lillahi'])
    E("Crying at a death is allowed. The Prophet wept and said the eyes shed tears and the heart grieves, and we say only what pleases our Lord.",
      [guide('huda-condolence'), HV('bukhari:1303')], cross=[xg('huda-condolence')], tags=['grief', 'condolence'], trig=['is it wrong to cry', 'crying at funeral', 'grief'],
      dns=['Warm and brief; for deep grief, also offer the grief support pack.'])
    E("The believer thanks Allah in ease and is patient in hardship, and both are good. Allah promises more to those who are grateful.",
      [guide('huda-gratitude'), Q('14:7', S), HV('muslim:2999')], cross=[xg('huda-gratitude')], tags=['gratitude', 'patience'], trig=['gratitude', 'shukr', 'be thankful', 'patience and thanks'])
    E("Seek knowledge with the right intention. The Prophet said that whoever treads a path to knowledge, Allah makes easy for him a path to Paradise, and the best of you are those who learn the Qur'an and teach it.",
      [guide('huda-knowledge'), HV('muslim:2699'), HV('bukhari:5027')], cross=[xg('huda-knowledge')], tags=['knowledge'], trig=['seeking knowledge', 'learn islam', 'study religion'])
    E("Start with the obligatory knowledge: how to pray and how to purify for it. The guide suggests beginning with the Prayer and Wudu guides.",
      [guide('huda-knowledge')], cross=[xg('huda-knowledge'), xg('huda-prayer'), xg('huda-wudu')], tags=['knowledge', 'beginner'], trig=['where to start learning islam', 'what to learn first'])
    E("Keep a small, regular portion of Qur'an each day. The guide gives the saying that the most beloved deeds are the most regular, even if little, and reciting with measured pace is encouraged.",
      [guide('huda-quran-daily'), Q('73:4', S)], cross=[xg('huda-quran-daily')], tags=['quran', 'routine'], trig=['daily quran', 'how much quran per day', 'quran routine'])
    E("Most scholars require wudu to touch the printed mushaf, while some, including the Zahiri school, do not. Scholars differ, so follow your school or ask a teacher. Reciting from memory without wudu is permitted.",
      [guide('huda-quran-daily'), Q('56:79', S)], cross=[xg('huda-quran-daily')], tags=['quran', 'mushaf', 'madhhab'], schools=['hanafi', 'maliki', 'shafii', 'hanbali', 'other'],
      trig=['touch quran without wudu', 'wudu to hold quran'])
    E("Travel with the dua the Prophet said on mounting: glory to Him who subjected this to us. Appoint a leader if three travel together, and return to your family quickly once your business is done.",
      [guide('huda-travel')], cross=[xg('huda-travel')], tags=['travel'], trig=['travel dua', 'safar dua', 'travelling manners'])
    E("Be careful with ordinary things: keep food clean and good, and eat what is lawful and wholesome. The Qur'an tells believers to eat of the good things provided and to be grateful.",
      [guide('huda-food'), Q('2:172', S), Q('2:168', S)], cross=[xg('huda-food'), xg('huda-halal-food')], tags=['halal', 'eating'], trig=['halal food', 'what can i eat', 'tayyib'])
    return [p]
