from .p_everyday_four import _pack
from .sources import H, Q

WORK = dict(
    bg="Work stress and burnout: workload limits, rest, boundaries and talking to a manager or doctor help; persistent exhaustion should be assessed by a doctor. General teaching; clinician to confirm.",
    orient=["I'm glad you said it. Work can swallow a life without anyone noticing. What's been happening?", "No judgment. Tell me what a normal work day looks like right now."],
    reflect=[("It sounds like you're giving everything and getting nothing back.", ['burnout', 'tired', 'exhausted']),
             ("It sounds like you can't switch off even when you're home.", ['home', 'weekend', 'switch']),
             ("Losing a job can shake your sense of who you are, not only your income.", ['fired', 'laid off', 'lost my job', 'unemployed']),
             ("It sounds like you're afraid to say no.", ['boss', 'manager', 'afraid'])],
    ask=["What part of the work is heaviest: hours, people, pressure, or the feeling it's pointless?", "Is there anyone at work you can be honest with?", "If you could change one thing about it this month, what would it be?", "How is it affecting your sleep, prayer and family time?"],
    affirm=["You are more than your output, and you're allowed to be tired.", "Wanting a sustainable life is not laziness."],
    explain=[("Burnout is what happens when demands outrun rest for a long time. It is a response to the situation, not a flaw in you.", ['burnout', 'exhausted', 'drained']),
             ("A job loss is a loss. Grief, fear and anger around it are normal. Structure, a small daily routine and telling a few trusted people make the weeks easier.", ['fired', 'laid off', 'lost my job', 'unemployed']),
             ("Boundaries work best when they are specific: finish time, one day fully off, no work messages during prayer and family meals.", ['boundary', 'overtime', 'say no'])],
    step=["One small step: choose a finishing time tonight and keep it, even if only today.", "One small step: write the three tasks that really matter tomorrow and let the rest wait.", "One small step: tell one trusted person how heavy it is."],
    faith_step="One small step: protect one prayer time at work today, even five minutes, as a break that belongs to you.",
    referral="If exhaustion, poor sleep or low mood have lasted weeks, see a doctor; work-related stress is a real health matter. You can say: \"Work is wearing me down and my health is suffering.\"",
    islamic=[("The Prophet taught that your body has a right over you. Rest is part of caring for the trust Allah gave you.", [H('bukhari:6134', 'RES_H2 knowledge')], ['rest', 'tired', 'sleep']),
             ("Allah says provision is in His hands, and He opens ways for the one who is mindful of Him. Looking for work and trusting Him go together.", [Q('65:2-3', 'RES_H2 2.2')], ['job', 'provision', 'rizq', 'income']),
             ("Allah does not burden a soul beyond its capacity. Being stretched past yours is a reason to change something.", [Q('2:286', 'RES_H2 2.2')], ['too much', 'cant', 'overwhelm'])],
    family="If someone you love is burning out, take small things off their plate and ask what would help. Don't push them to just push through.")

DIVORCE = dict(
    bg="Separation and divorce: practical support, legal advice and emotional care for adults and children; safety first if there is abuse. General teaching; clinician to confirm.",
    orient=["I'm sorry you're facing this. I'm here to listen, whatever stage it's at. What's been going on?", "No judgment. Tell me where things stand."],
    reflect=[("It sounds like grief, even if you're the one who chose it.", ['divorce', 'separat', 'ended']),
             ("It sounds like you're afraid of what people will say.", ['family', 'community', 'people', 'judge']),
             ("It sounds like you're worried about the children above everything.", ['kids', 'children', 'custody']),
             ("It sounds like you're tired of trying and of not being heard.", ['tried', 'tired', 'fight'])],
    ask=["Where are things right now: deciding, in process, or already apart?", "Are you safe at home?", "What worries you most about the next month?", "Who is on your side right now?"],
    affirm=["Whatever the reason, ending a marriage is hard, and you're allowed to feel all of it.", "You're still the same person with worth, whatever a court or a community says."],
    explain=[("Divorce brings waves: relief, grief, anger, fear. They tend to come and go and ease with time and support.", ['divorce', 'separat']),
             ("Children cope best when they are not put in the middle: no carrying messages, no criticising the other parent to them, and clear routines.", ['kids', 'children', 'custody']),
             ("A lawyer who knows your local law and, if you wish, a scholar who knows the Islamic rulings can each help. They answer different questions.", ['khula', 'talaq', 'lawyer', 'ruling'])],
    step=["One small step: write the three practical things you most need to sort, and pick the first.", "One small step: tell one safe person where you are, so you're not alone with it.", "One small step: keep the children's routine steady this week, the same bedtime, the same meals."],
    faith_step="One small step: pray two rak'ahs and ask Allah for clarity and the best outcome, in your own words.",
    referral="A family lawyer, a counsellor and, for rulings, a scholar can each help. You can say: \"I'm going through a separation and I need guidance.\" If you aren't safe, call your emergency number.",
    islamic=[("Allah says to part, if it comes to it, with kindness and fairness. Even at the hardest end, dignity is part of the deen.", [Q('2:229', 'RES_H2 2.2')], ['dignity', 'fair', 'talaq']),
             ("Allah says that if they separate, Allah will enrich each of them from His bounty. A door closing is not the end of provision or happiness.", [Q('4:130', 'RES_H2 2.2')], ['future', 'alone', 'hope']),
             ("Allah says not to forget graciousness between you. Staying decent through the process matters.", [Q('2:237', 'RES_H2 2.2')], ['bitter', 'revenge', 'angry'])],
    family="If a loved one is divorcing, don't take sides loudly. Offer meals, a room, rides and listening, and ask what they need.")

LOSS = dict(
    bg="Pregnancy loss and infertility: grief is real and often unspoken; partners grieve too; medical follow-up and counselling help. General teaching; clinician to confirm.",
    orient=["I'm so sorry. I'm here and there's no rush. Tell me what you'd like to say.", "Whatever you're carrying, you can say it here without being judged."],
    reflect=[("It sounds like a grief that other people don't know how to see.", ['miscarriage', 'lost the baby', 'stillbirth']),
             ("It sounds like every month is a cycle of hope and loss.", ['trying', 'ivf', 'conceive', 'infertil']),
             ("It sounds like others' news hurts, and you feel guilty for it.", ['pregnant', 'baby', 'everyone']),
             ("It sounds like you're searching for a reason.", ['why', 'my fault', 'because'])],
    ask=["Would you like to tell me about your baby or your journey?", "How are you and your spouse coping, together or apart?", "Who knows, and who has been kind?", "What would help most this week?"],
    affirm=["Your grief is real and it deserves room.", "This is not your fault. Loss in pregnancy is rarely something a person caused."],
    explain=[("Pregnancy loss is a death, and grief can come in waves for a long time. There is no schedule for it.", ['miscarriage', 'lost the baby', 'stillbirth']),
             ("Partners often grieve differently, one quietly and one aloud. Different is not the same as not caring.", ['husband', 'wife', 'spouse']),
             ("Infertility is a medical condition, not a verdict on your worth. A doctor can explain options, and many couples also find counselling helpful.", ['infertil', 'conceive', 'trying', 'ivf'])],
    step=["One small step: choose one person who is gentle with you and tell them how today is.", "One small step: give yourself a small, private way to remember, a du'a, a letter or a name.", "One small step: book the follow-up appointment you've been delaying."],
    faith_step="One small step: make du'a, even briefly, and say exactly what you're feeling to Allah.",
    referral="A doctor can check your health after a loss and discuss fertility, and a counsellor who understands loss can help. You can say: \"I've had a loss and I'm struggling.\"",
    islamic=[("Allah says to give glad tidings to the patient, those who say, we belong to Allah and to Him we return, when hardship strikes.", [Q('2:155-156', 'RES_H2 2.2')], ['patience', 'sabr', 'innalillah']),
             ("When the Prophet's own son died, his eyes shed tears and he said the heart grieves. Crying over a loss is not against faith; it is mercy.", [H('bukhari:1303', 'RES_H2 knowledge')], ['baby', 'child', 'lost']),
             ("Allah gives what He wills, and the Qur'an mentions prophets who asked for a child for years. Your longing is a dua He hears.", [Q('21:89', 'RES_H2 2.2')], ['child', 'dua', 'conceive'])],
    family="If someone near you has lost a pregnancy, say I'm sorry and I'm here, and don't offer reasons. Remember their partner too.")

DISCRIM = dict(
    bg="Discrimination and harassment: validation, documenting incidents, finding allies and reporting channels help; ongoing harassment may need legal or community support. General teaching; clinician to confirm.",
    orient=["I'm sorry that happened. You don't have to justify why it hurt. What happened?", "No judgment. Tell me what you've been facing."],
    reflect=[("It sounds like you're being treated as less than you are.", ['islamophob', 'racist', 'discriminat']),
             ("It sounds like you're tired of constantly being on guard.", ['hijab', 'beard', 'stared', 'afraid']),
             ("It sounds like the pressure to explain yourself never stops.", ['explain', 'justify', 'terror']),
             ("It sounds like it makes you want to hide who you are.", ['hide', 'ashamed', 'avoid'])],
    ask=["Are you safe right now?", "Where is it happening: work, school, online, the street?", "Has anyone seen or supported you?", "What do you most need: to vent, a plan, or a way to report?"],
    affirm=["What happened is about them, not about your worth.", "Standing as who you are takes strength."],
    explain=[("Writing down dates, places, words and witnesses helps if you decide to report, and it also helps you feel less crazy.", ['report', 'work', 'school', 'harass']),
             ("Reporting channels exist at work, school and in law. Community organisations can advise on your rights and sometimes help with the process.", ['report', 'police', 'hr', 'rights']),
             ("Being on guard all the time is tiring. Safe spaces and allies are not a luxury; they are protection.", ['tired', 'guard', 'afraid'])],
    step=["One small step: write down what happened, with date and place, while it's fresh.", "One small step: tell one trusted person and ask them to be a witness.", "One small step: find the reporting channel at your work or school and read it, without committing to use it."],
    faith_step="One small step: make du'a for steadiness and safety, then do something kind for yourself.",
    referral="If you're being threatened or attacked, call your emergency number. For ongoing harassment, a community legal or civil-rights organisation can advise. You can say: \"I'm facing discrimination and want to know my options.\"",
    islamic=[("Allah says the believers are honoured, and not to lose heart. Your dignity does not depend on how others treat you.", [Q('3:139', 'RES_H2 2.2')], ['dignity', 'honour', 'belittle']),
             ("Allah made people into nations and tribes so they would know each other. The best in His sight is the most mindful, not anyone's colour or origin.", [Q('49:13', 'RES_H2 2.2')], ['race', 'colour', 'origin']),
             ("Allah says He is near and answers the one who calls on Him. Asking Him for help is never wasted.", [Q('2:186', 'RES_H2 2.2')], ['dua', 'justice', 'oppress'])],
    family="If someone you love is facing discrimination, believe them first, help them keep notes, and don't tell them to ignore it.")

DOUBT = dict(
    bg="Religious doubt: questions are normal; space to ask, reading with trusted teachers and patience help; doubt with distress may benefit from counselling. General teaching; clinician to confirm.",
    orient=["I'm glad you brought it here. Questions are not a crime. What's on your mind?", "No judgment at all. Tell me what you're wondering about."],
    reflect=[("It sounds like you're afraid even to ask.", ['afraid', 'scared', 'allowed']),
             ("It sounds like something doesn't add up, and you want to be honest about it.", ['doubt', 'dont understand', 'confus']),
             ("It sounds like you feel far from what you used to feel.", ['far', 'faith', 'iman']),
             ("It sounds like people around you expect certainty that you don't have.", ['family', 'expect', 'pressure'])],
    ask=["What's the question, in your own words?", "Is it about God, about the Qur'an, about a rule, or about people who practise?", "When did it begin?", "Who could you ask without fear?"],
    affirm=["Asking is a sign you're taking it seriously.", "You can bring this to Allah honestly, and He already knows."],
    explain=[("Many sincere people, including students of knowledge, go through seasons of doubt. Doubt is a question waiting for a good answer, not an exit.", ['doubt', 'question', 'confus']),
             ("Sometimes the problem is how a rule was presented, or how a person behaved, rather than the faith itself. Separating them can help.", ['hypocri', 'people', 'rule', 'strict']),
             ("A good scholar or teacher can answer hard questions. If one is dismissive, try another; the tradition has long welcomed questions.", ['ask', 'scholar', 'imam'])],
    step=["One small step: write your question down in one clear sentence.", "One small step: choose one trusted person or teacher to ask, and send them the sentence.", "One small step: keep praying while you ask, as a thread to hold."],
    faith_step="One small step: say to Allah, in your own words, I am confused, guide me, and then pray as usual.",
    referral="If doubt comes with distress, hopelessness or fear, a counsellor can help alongside a teacher. You can say: \"I'm struggling with doubts and I want to talk.\"",
    islamic=[("Ibrahim asked Allah to show him how He gives life to the dead, so that his heart would be at ease. Asking for reassurance is part of the story of prophets.", [Q('2:260', 'RES_H2 2.2')], ['proof', 'sure', 'certain']),
             ("Allah says that those who strive for Him, He guides to His paths. Searching sincerely is itself a way He may open.", [Q('29:69', 'RES_H2 2.2')], ['guide', 'search', 'path']),
             ("Allah calls us to reflect on the heavens and the earth. Thinking is part of belief, not its enemy.", [Q('3:190-191', 'RES_H2 2.2')], ['think', 'reflect', 'reason'])],
    family="If someone you love has doubts, listen without panic. Ask what they are wondering and offer to find answers together.")


def build():
    return [
        _pack('work_burnout', 'work_burnout', 'Work stress, burnout and job loss: limits, rest, provision and trust in Allah, without shame.', 'work', WORK),
        _pack('divorce_separation', 'divorce_separation', 'Separation and divorce: grief, children, safety, practical and scholarly help, dignity.', 'divorce', DIVORCE),
        _pack('pregnancy_loss_infertility', 'pregnancy_loss_infertility', 'Miscarriage, stillbirth and infertility: grief, partners, patience, medical follow-up.', 'loss', LOSS),
        _pack('discrimination', 'discrimination', 'Islamophobia, racism and harassment: validation, documenting, reporting, dignity and du\'a.', 'discrimination', DISCRIM),
        _pack('faith_doubts', 'faith_doubts', 'Doubts and questions about faith: welcome, honest asking, teachers, patience.', 'doubt', DOUBT),
    ]
