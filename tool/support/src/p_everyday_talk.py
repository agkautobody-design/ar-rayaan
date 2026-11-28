from .p_everyday_four import _pack
from .sources import Q

SELF = dict(
    bg="Self-worth: harsh self-talk, comparison and perfectionism; noticing the voice, speaking to yourself as to a friend, and valuing effort help; persistent worthlessness with low mood should go to a clinician. General teaching; clinician to confirm.",
    orient=["I'm glad you said it. The way you talk to yourself matters. What does that voice say?", "No judgment. Tell me what makes you feel you're not enough."],
    reflect=[("It sounds like you hold yourself to a standard you'd never hold a friend to.", ['perfect', 'never enough', 'failure']),
             ("It sounds like everyone else seems to be managing and you feel behind.", ['compare', 'everyone else', 'behind']),
             ("It sounds like one mistake outweighs everything you've done right.", ['mistake', 'stupid', 'idiot']),
             ("It sounds like you've heard these things for a long time, maybe from someone else first.", ['always told', 'growing up', 'family'])],
    ask=["When did you first start believing that about yourself?", "What would you say to a friend who said the same thing about themselves?", "Who sees your worth, even when you don't?", "What is one thing you did this week that took effort?"],
    affirm=["Your worth isn't earned by performance; it's a given.", "Being this hard on yourself usually means you care a great deal about doing right."],
    explain=[("Harsh self-talk feels like honesty, but it is mostly habit. Noticing it and answering it, as you would for a friend, weakens it over time.", ['stupid', 'idiot', 'hate myself']),
             ("Social media shows other people's best moments next to your whole life. The comparison is unfair by design.", ['compare', 'everyone else', 'instagram']),
             ("Effort and kindness are things you do, and they count even when the outcome isn't perfect.", ['failure', 'not enough', 'useless'])],
    step=["One small step: write down one thing you did today that took effort, however small.", "One small step: next time the harsh voice speaks, answer it with what you'd tell a friend.", "One small step: ask one person you trust what they value in you."],
    faith_step="One small step: say to Allah what you like about what He made in you, and ask Him to help you see it too.",
    referral="If these feelings are constant, or come with hopelessness or low mood, a counsellor can help and it does get better. You can say: \"I've been very hard on myself and I want help with that.\"",
    islamic=[("Allah says He created the human being in the best form. Your worth began with Him, before any achievement.", [Q('95:4', 'RES_H2 2.2')], ['worth', 'valuable', 'ugly']),
             ("Allah says the most honoured with Him is the one most mindful of Him, not the richest, prettiest or most successful.", [Q('49:13', 'RES_H2 2.2')], ['compare', 'better', 'honour']),
             ("Allah says not to despair of His mercy, however much you have done or feel you are.", [Q('39:53', 'RES_H2 2.2')], ['failure', 'hopeless', 'useless'])],
    family="If someone you love speaks harshly of themselves, don't argue with it. Say what you value in them, specifically, and say it often.")

SOCIAL = dict(
    bg="Social anxiety: gradual exposure, dropping safety behaviours and focusing outward help; persistent social fear should be assessed by a clinician. General teaching; clinician to confirm.",
    orient=["I'm glad you're here. Social situations can feel very loud inside. What happens when you're around people?", "No judgment. Tell me which situations are hardest."],
    reflect=[("It sounds like you replay conversations afterwards, looking for what you did wrong.", ['replay', 'afterwards', 'cringe']),
             ("It sounds like you're sure everyone is watching or judging.", ['watching', 'judging', 'stare']),
             ("It sounds like you avoid things you'd actually like to do.", ['avoid', 'skip', 'cancel']),
             ("It sounds like you want connection but dread the effort.", ['friends', 'alone', 'want'])],
    ask=["Which situations are hardest: meeting new people, speaking up, eating in public, the masjid?", "What do you fear will happen?", "What do you do to get through it?", "What have you been missing because of it?"],
    affirm=["Being shy or anxious in company is very common, and it's not a flaw.", "You're still showing up in ways people don't see."],
    explain=[("Most people are thinking about themselves, not judging you. The spotlight feels bigger from the inside.", ['judging', 'watching', 'stare']),
             ("Avoiding situations gives relief now and keeps the fear alive. Small, repeated steps toward them shrink it.", ['avoid', 'cancel', 'skip']),
             ("Focusing on the other person, their words and what they need, takes your attention off yourself and eases the fear.", ['awkward', 'what to say', 'conversation'])],
    step=["One small step: greet one person with salam and one short question, and stop there.", "One small step: arrive somewhere early, when it's quiet, and stay ten minutes.", "One small step: after a social moment, write one thing that went fine."],
    faith_step="One small step: before entering a gathering, say a short du'a and remind yourself that Allah is with you there.",
    referral="If fear of people is limiting your work, study or friendships, a counsellor can teach practical tools and it improves with help. You can say: \"I get very anxious around people and it's limiting my life.\"",
    islamic=[("Allah told Musa not to fear, for He is with them, hearing and seeing. Allah is with you in every room.", [Q('20:46', 'RES_H2 2.2')], ['afraid', 'fear', 'with me']),
             ("Allah says He does not burden a soul beyond its capacity, so you're only asked for what you can manage today.", [Q('2:286', 'RES_H2 2.2')], ['too much', 'cant', 'overwhelm'])],
    family="If someone you love is shy or anxious in company, don't force them or call them rude. Give them a role, a plan and an exit.")

HOME = dict(
    bg="Migration and homesickness: grief for place, routine and community; building routines and connections takes months; persistent low mood should go to a clinician. General teaching; clinician to confirm.",
    orient=["Moving far from home is a real loss, even when it was the right choice. What do you miss most?", "I'm glad you told me. Tell me how it's been since you arrived."],
    reflect=[("It sounds like you're between two places and not fully in either.", ['home', 'abroad', 'new country']),
             ("It sounds like you miss the sound of your own language, the food and the people who knew you.", ['miss', 'language', 'food']),
             ("It sounds like you carry responsibility for people back home as well.", ['family back', 'send money', 'parents']),
             ("It sounds like it's hard to find where you belong.", ['belong', 'fit in', 'community'])],
    ask=["How long have you been away?", "What would make your week feel more like home?", "Have you found a masjid or group you feel comfortable in?", "Who do you speak to back home, and how often?"],
    affirm=["Missing home isn't ingratitude; it's love.", "You've been brave to build a life somewhere new."],
    explain=[("Homesickness often peaks in the first months and eases as routines and friendships form, though some waves come back around holidays.", ['miss', 'homesick', 'eid']),
             ("Familiar things carry comfort: a food, a prayer time, a call at the same hour each week. They give structure while the new place becomes known.", ['routine', 'lonely', 'food']),
             ("Belonging usually grows in small repeated places: a class, the masjid, a neighbour, a workplace friend.", ['fit in', 'belong', 'community'])],
    step=["One small step: schedule a weekly call with someone back home, same time each week.", "One small step: cook one dish from home and invite one person to share it.", "One small step: find one regular local event and go twice before deciding."],
    faith_step="One small step: pray one prayer at the masjid this week and stay a few minutes afterwards.",
    referral="If low mood or loneliness lasts for weeks, a counsellor or a community support service can help. You can say: \"I moved here and I'm finding it hard to settle.\"",
    islamic=[("Allah says the earth is vast and He made people into nations and tribes to know one another. You're allowed to build a home in a new place.", [Q('49:13', 'RES_H2 2.2')], ['new country', 'belong', 'home']),
             ("Allah says He is near and answers the one who calls on Him, in any country and any language.", [Q('2:186', 'RES_H2 2.2')], ['alone', 'dua', 'far'])],
    family="If someone you love has moved, a regular call, a package from home and a visit when possible matter more than advice.")

FRIEND = dict(
    bg="Betrayal and friendship breakdown: hurt, trust, boundaries and repair; set boundaries and decide on repair or distance. General teaching; clinician to confirm.",
    orient=["I'm sorry. Being hurt by someone close is painful. What happened?", "No judgment, and you don't have to decide anything today. Tell me what's going on."],
    reflect=[("It sounds like you trusted them and it was broken.", ['betray', 'lied', 'trusted']),
             ("It sounds like you're replaying what you could have done differently.", ['my fault', 'should have', 'replay']),
             ("It sounds like you're angry and sad at once.", ['angry', 'hurt', 'sad']),
             ("It sounds like you lost more than a person; you lost a part of your routine and your circle.", ['friends', 'group', 'lost'])],
    ask=["What hurt most about it?", "Would you like it repaired, or do you want distance?", "Have you told them how it affected you?", "Who else is on your side right now?"],
    affirm=["Being hurt shows you cared and trusted.", "You don't have to forgive on anyone's schedule."],
    explain=[("Forgiving someone does not mean going back to how it was. You can forgive and still keep distance or new boundaries.", ['forgive', 'again', 'trust']),
             ("A calm, specific message works better than a long argument: what happened, how it affected you, what you need.", ['talk to them', 'confront', 'message']),
             ("Trust returns slowly and with changed behaviour, not only with an apology.", ['trust', 'sorry', 'apolog'])],
    step=["One small step: write what you'd say, without sending it, and see how it reads tomorrow.", "One small step: spend time this week with someone who steadies you.", "One small step: decide one boundary you need, and write it in one line."],
    faith_step="One small step: pray two rak'ahs and ask Allah for a clear heart and good judgement about this person.",
    referral="If this is affecting your sleep, work or mood for weeks, a counsellor can help you work through it. You can say: \"A friendship ended badly and I'm struggling with it.\"",
    islamic=[("Allah says to repel evil with what is better, and the one who was an enemy may become a close friend. Repair is possible, but it's not an obligation to reopen every door.", [Q('41:34', 'RES_H2 2.2')], ['enemy', 'forgive', 'repair']),
             ("Allah praises those who pardon and make things right, and He promises their reward. Pardon is a choice at your own pace.", [Q('42:40', 'RES_H2 2.2')], ['forgive', 'pardon', 'revenge'])],
    family="If someone you love has been betrayed, listen first. Don't tell them to forgive quickly or to cut off quickly.")

CARER = dict(
    bg="Caregiver strain: sustained care for a parent, spouse or child with illness is exhausting; respite, sharing tasks and support groups reduce strain. General teaching; clinician to confirm.",
    orient=["Caring for someone you love is a lot. I'm glad you told me. How have you been holding up?", "No judgment. Tell me what a normal day looks like for you."],
    reflect=[("It sounds like you've been putting yourself last for a long time.", ['tired', 'last', 'myself']),
             ("It sounds like you love them and you're also exhausted, and both are true.", ['love', 'exhausted', 'resent']),
             ("It sounds like you feel guilty for wanting a break.", ['guilty', 'break', 'selfish']),
             ("It sounds like most of it falls on you.", ['alone', 'no help', 'siblings'])],
    ask=["Who are you caring for, and for how long?", "Who else could share even one task?", "When did you last rest properly?", "What would one hour of relief look like?"],
    affirm=["Caring this way is a form of worship, and you're allowed to be tired.", "Needing rest does not mean you love them less."],
    explain=[("Carers who rest, share tasks and accept help last longer and give better care. Respite is part of the care, not a betrayal.", ['guilty', 'break', 'selfish']),
             ("Resentment alongside love is normal and does not make you a bad person. It is a sign you need support.", ['resent', 'angry', 'tired']),
             ("Local carer services, community groups and the masjid can often help with respite, transport or paperwork.", ['help', 'support', 'alone'])],
    step=["One small step: ask one family member or friend to take one specific task this week.", "One small step: block one hour that's yours and protect it.", "One small step: find one local carer service and write down its number."],
    faith_step="One small step: pray a short prayer for strength and read about the reward of caring for parents, then rest without guilt.",
    referral="Your own health matters too. If you're worn out, low or struggling to cope, a doctor or counsellor can help. You can say: \"I'm caring for someone and I'm exhausted.\"",
    islamic=[("Allah commands kindness to parents, and He knows the effort you give. He also does not burden a soul beyond what it can bear.", [Q('17:23', 'RES_H2 2.2'), Q('2:286', 'RES_H2 2.2')], ['parents', 'mother', 'father']),
             ("Allah says with hardship comes ease. Seek help; it is part of how ease arrives.", [Q('94:5-6', 'RES_H2 2.2')], ['tired', 'hardship', 'ease'])],
    family="If someone you know is a carer, offer a specific hour, a meal or a lift, not a general offer. Ask what they need.")

SLEEP = dict(
    bg="Sleep trouble: regular times, light, caffeine, screens and winding down help; persistent insomnia or loud snoring should be assessed by a doctor. General teaching; clinician to confirm.",
    orient=["Not sleeping is miserable. I'm glad you mentioned it. What does your night look like?", "No judgment. Tell me when it started and what happens when you lie down."],
    reflect=[("It sounds like your mind gets busy the moment the lights go out.", ['mind', 'racing', 'thinking']),
             ("It sounds like you dread bedtime now.", ['dread', 'afraid', 'nights']),
             ("It sounds like you wake in the night and can't get back.", ['wake', 'middle of the night', '3am']),
             ("It sounds like the tiredness is affecting your whole day.", ['tired', 'exhausted', 'cant focus'])],
    ask=["What time do you go to bed and wake, usually?", "What do you do in the hour before bed?", "How much caffeine and what time is the last?", "What's on your mind when you can't sleep?"],
    affirm=["Poor sleep makes everything harder, and you're coping through it.", "Asking for help with sleep is sensible."],
    explain=[("A regular wake time, daylight in the morning and less caffeine after midday are the strongest simple supports for sleep.", ['caffeine', 'coffee', 'schedule']),
             ("Lying awake trying to sleep keeps the brain alert. If you've been awake about twenty minutes, get up, do something quiet in low light, and go back when sleepy.", ['awake', 'cant sleep', 'lying']),
             ("A short written list of worries before bed can take them out of your head.", ['racing', 'worry', 'thinking'])],
    step=["One small step: set a fixed wake-up time tomorrow and get daylight within an hour.", "One small step: no screens for thirty minutes before bed, and dim the lights.", "One small step: write tomorrow's worries on paper before you lie down."],
    faith_step="One small step: make wudu, say the bedtime adhkar slowly and lie on your right side, as the Prophet did.",
    referral="If poor sleep has lasted weeks, or you snore loudly, stop breathing at night or feel very low, a doctor should check. You can say: \"I haven't slept properly for weeks and it's affecting me.\"",
    islamic=[("Allah says He made the night for rest. Rest is part of how He designed your body.", [Q('78:9-10', 'RES_H2 2.2')], ['night', 'rest', 'sleep']),
             ("Allah says the remembrance of Him brings hearts rest. A few slow words of dhikr can ease a busy mind.", [Q('13:28', 'RES_H2 2.2')], ['mind', 'racing', 'calm'])],
    family="If someone you love can't sleep, keep the house calm at night, don't lecture, and encourage a regular schedule and a doctor's visit if it persists.")


def build():
    return [
        _pack('self_worth', 'self_worth', 'Self-worth, harsh self-talk, comparison and perfectionism: kindness to yourself, your worth is given.', 'self-worth', SELF),
        _pack('social_anxiety', 'social_anxiety', 'Shyness and fear around people: small steps, outward focus, gentle courage.', 'social', SOCIAL),
        _pack('homesickness', 'homesickness', 'Homesickness and settling in a new country: loss, routine and belonging.', 'homesick', HOME),
        _pack('friendship_betrayal', 'friendship_betrayal', 'A friendship that broke or a betrayal: hurt, boundaries, repair or distance.', 'friendship', FRIEND),
        _pack('caregiver_strain', 'caregiver_strain', 'Looking after a parent, spouse or child: tiredness, guilt, respite, sharing the load.', 'caregiver', CARER),
        _pack('sleep_trouble', 'sleep_trouble', 'Trouble sleeping: calm evening routine, worry-offloading, adhkar, when to see a doctor.', 'sleep', SLEEP),
    ]
