from .lib import Pack
from .sources import H, Q, bg, clin


def build():
    p = Pack('illness_pain', 'support', 'illness', 'hadi',
             'Illness and pain: a new diagnosis, chronic pain, hospital and treatment, fear about the body. Listen first; never advise medically; hold the fear and pair treatment with trust in Allah.',
             base_tags=['distress'])
    A = p.add
    G = bg('RES_H1 10.1', 'Emotional support: listening, validation and small steps help; persistent or disabling distress should go to a clinician. General teaching; no source opened; clinician to confirm.')
    MH = clin('who_mhgap')

    A('orient', "Illness changes everything at once — the body, the plans, the future. I am here, and I am not in a hurry.", tags=['opening'])
    A('orient', "Thank you for telling me. You do not have to be brave about this here.", tags=['opening'])
    A('orient', "However your body is failing or frightening you right now, you can say it plainly. I will stay with it.", tags=['opening'])

    A('reflect', "It sounds like the diagnosis landed like a stone, and life has not felt level since.", tags=['diagnosis'], trig=['diagnosis', 'diagnosed', 'results', 'scan'])
    A('reflect', "Pain that does not clock out wears a person down in ways nobody sees from outside.", tags=['pain'], trig=['pain', 'hurts', 'ache', 'aching'])
    A('reflect', "It sounds like hospitals and appointments have become a second home, and you are so tired of it.", tags=['hospital'], trig=['hospital', 'appointment', 'appointments', 'ward'])
    A('reflect', "It sounds like part of the pain is that you look fine — and nobody believes how unwell you actually are.", tags=['invisible'], trig=['invisible', 'believe', 'believes', 'looks'])
    A('reflect', "It sounds like treatment is its own battle — the side effects, the waiting, the not knowing if it works.", tags=['treatment'], trig=['treatment', 'chemo', 'medication', 'tablets', 'operation'])
    A('reflect', "It sounds like you miss the body you used to have, and grieving that is real grief.", tags=['grief-body'], trig=['miss', 'before', 'used', 'anymore'])
    A('reflect', "It sounds like fear about the future — what happens to you, and to the people you love — sits under everything.", tags=['fear'], trig=['scared', 'afraid', 'fear', 'terrified'])
    A('reflect', "It sounds like you are tired of being the strong one for everyone around you.", tags=['strong'], trig=['strong', 'brave', 'everyone'])
    A('reflect', "Being sick for a long time changes how the whole world looks. Your weariness makes sense.", tags=['chronic'], trig=['chronic', 'years', 'months', 'long'])

    A('ask', "What did the doctors actually say — in plain words, as you understood it?", tags=['story'])
    A('ask', "Where is the pain worst — in the body, or somewhere else?", tags=['locate'])
    A('ask', "Who is going through this with you — is anyone?", tags=['support'])
    A('ask', "What do you miss most from before?", tags=['loss'])
    A('ask', "What are you most afraid of right now?", tags=['fear'])
    A('ask', "How are your nights — are fear and pain letting you sleep at all?", tags=['self-care'], risk='medium')
    A('ask', "Has it ever got so heavy that you wished you would not wake up?", tags=['safety-check'], risk='high', ask=True, src=[MH], dns=['If yes or unclear, ask directly about suicide and go to the crisis flow.'])

    A('affirm', "Being frightened by illness is not a failure of faith. It is a human nervous system doing what it does.", tags=['validation'])
    A('affirm', "You have already survived every hard day so far, including the day you first heard the news.", tags=['strength'])
    A('affirm', "Resting is not giving up. For a body in battle, rest is part of the fight.", tags=['rest'])
    A('affirm', "You are allowed to be tired of being positive. You do not owe anyone a performance.", tags=['permission'])

    A('explain', "Fear after a diagnosis comes in waves, and the waves are worst at night. Naming the fear out loud — even here — takes some of its size away.", tags=['fear'], src=[G], ev='C', trig=['fear', 'scared', 'night', 'afraid'])
    A('explain', "I will never advise you on medicine — your doctors carry that, and they should. What I can carry with you is the fear, the waiting, and the nights.", tags=['scope'], trig=['medicine', 'treatment', 'doctor', 'should'])
    A('explain', "Questions for the doctor are easy to forget in the moment. Writing them down before appointments — even on your phone — gets you real answers.", tags=['questions'], src=[G], ev='C', trig=['doctor', 'appointment', 'ask', 'questions'])
    A('explain', "Pain is easier to bear at some hours than others. Notice your better window and give the hardest things to that window.", tags=['pacing'], src=[G], ev='C', trig=['pain', 'window', 'worse', 'morning'])
    A('explain', "People who are ill often end up comforting everyone else. You are allowed to hand that job back and simply be the one who is held.", tags=['held'], src=[G], ev='C', trig=['strong', 'comfort', 'everyone', 'brave'])

    A('plan-step', "One small step: write three questions for your doctor — the real ones, including the one you are embarrassed to ask.", tags=['doctor'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: ask one specific person for one specific thing — a lift, a meal, an hour of company. People help better when the task is clear.", tags=['help'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: give your body one gentle thing today — water, air at a window, a slow short walk if you are able. Kindness to the body counts.", tags=['body'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: the Prophet taught a beautiful dua for the sick. Say the word and I will share it with you.", tags=['dua'], ask=True)
    A('plan-step', "One small step: tonight, one slow breath in and out, and hand the fear to Allah in your own words. Then tell me how the night went.", tags=['night'], ask=True)

    A('safety', "If this is a medical emergency — severe symptoms, chest pain, trouble breathing — please call your local emergency number now, before we talk further. And if illness ever makes you feel you cannot go on, a crisis line is below.", tags=['emergency', 'crisis'], src=[clin('who_suicide'), MH], risk='high', fixed=True, trig=['emergency', 'breathing', 'ending', 'hopeless'], dns=['Join with helplines.json scope suicide.'], stage=['crisis'])

    A('referral', "Tell your doctor honestly how much this is affecting your sleep, your mood and your days — that is medical information, not complaining, and it changes what they can offer.", tags=['doctor'], src=[G, MH], ev='C', fixed=True, trig=['doctor', 'tell', 'honestly'])
    A('referral', "Support groups for your condition — online or local — put you beside people who understand without explanation. Your doctor or hospital can point you to one.", tags=['group'], src=[G], ev='C', fixed=True)

    A('islamic', "The Prophet taught that there is no disease for which Allah has not also sent a cure. Treatment and trust belong together — take the medicine and hold the hope.", src=[H('bukhari:5678', 'RES_H2 2.5'), H('ibnmajah:3438', 'RES_H2 2.5')], tags=['cure', 'hope'], trig=['cure', 'treatment', 'hope'])
    A('islamic', "The Prophet taught plainly: seek treatment. Medicine is not a lack of trust in Allah; it is part of trusting Him, because He is the One who made the cure.", src=[H('ibnmajah:3436', 'RES_H2 2.5'), H('tirmidhi:2038', 'RES_H2 2.5')], tags=['treatment'], trig=['treatment', 'medicine', 'doctor'])
    A('islamic', "A woman with falling sickness asked the Prophet for a cure, and chose patience when he promised her Paradise for it. Endurance through illness is seen, and it is not small in His sight.", src=[H('muslim:2576', 'RES_H2 4.8'), H('bukhari:5652', 'RES_H2 4.8')], tags=['patience', 'reward'], trig=['patience', 'reward', 'why'])
    A('islamic', "The Prophet taught that no worry, sickness or sorrow reaches a believer without Allah wiping away some of their sins through it — even the prick of a thorn. None of this is wasted.", src=[H('bukhari:5642', 'RES_H2 4.8'), H('muslim:2573', 'RES_H2 4.8')], tags=['expiation', 'mercy'], trig=['sins', 'why', 'pain', 'suffering'])
    A('islamic', "The Prophet said the affair of the believer is amazing: ease comes and he is grateful, harm comes and he is patient, and both are good for him. You are inside that promise right now.", src=[H('bukhari:5641', 'RES_H2 knowledge')], tags=['amazing', 'patience'], trig=['grateful', 'patient', 'amazing'])
    A('islamic', "Ayyub called out in his illness, \"Harm has touched me, and You are the Most Merciful of the merciful\" — and Allah answered and removed the harm. His dua is yours to borrow.", src=[Q('21:83', 'RES_H2 knowledge')], tags=['ayyub', 'dua'], trig=['ayyub', 'dua', 'merciful'])
    A('islamic', "Allah does not burden a soul beyond what it can bear. The measure of this illness was taken by the One who made you — you will not be given what you cannot carry.", src=[Q('2:286', 'RES_H2 2.2')], tags=['bear', 'mercy'], trig=['bear', 'much', 'carry'])

    A('family', "If someone you love is ill, do not disappear because you have no words. Bring food, sit quietly, and keep coming back after the first week, when everyone else has stopped.", tags=['friend', 'family-of'], src=[G], ev='C', trig=['friend', 'mother', 'father', 'husband', 'wife'])
    A('summary', "What I've heard: {topic} is asking a lot of you, body and heart. You do not have to carry the fear alone, and you do not have to perform strength here.", tags=['summary'], slots=['topic'])
    return [p]
