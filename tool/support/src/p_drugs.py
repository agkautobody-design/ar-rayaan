from .lib import Pack
from .sources import H, Q, bg, clin, fq


def build():
    p = Pack('drugs', 'support', 'drugs', 'hadi',
             'Drugs: opioids, benzodiazepines and Z-drugs, stimulants, cannabis, GHB, and misuse of prescribed medicines. Listening, orientation and hand-over; never doses, tapers or advice to stop.',
             base_tags=['drugs'])
    A = p.add
    WHO_OP, WHO26, BENZO = clin('who_opioid'), clin('who_opioid_2026'), clin('benzo')
    GHB, GHB2 = clin('ghb_austin'), clin('ghb_neu')
    MHGAP = clin('who_mhgap')
    CORE = clin('niaaa_core')
    STIM = bg('RES_H1 3.4', 'Contingency management and structured psychosocial programmes are the best-supported approach for stimulants (Cochrane titles seen in search only, not read); clinician to confirm.')
    PSY = bg('RES_H1 8', 'Psychosis with cannabis or stimulants is a clinician referral (standard teaching, no source opened); clinician to confirm.')
    MIX = bg('RES_H1 2.4', 'Mixing opioids with alcohol or benzodiazepines raises overdose risk; tolerance falls after time off (standard harm-reduction teaching, no source opened; WHO notes the post-prison window). Clinician to confirm.')

    # orient
    A('orient', "I'm an app, not a doctor or a counsellor. I can listen, help you think things through, and point you to people who can help with drugs or medicines. What would you like to talk about?",
      tags=['opening', 'honesty'])
    A('orient', "You can tell me as much or as little as you like. I won't judge, and I won't tell you what you must do. I can listen and help you find the right human help. Where shall we start?",
      tags=['opening', 'honesty'])
    A('orient', "Is this about a drug, a medicine from a doctor, or a question you have for someone else? Any of those is fine.", tags=['opening', 'door'])

    # reflect
    A('reflect', "It sounds like this has been taking up more and more of your life.", tags=['concern'])
    A('reflect', "You want things to feel different, and you're not sure how to get there.", tags=['ambivalence'])
    A('reflect', "It sounds like the drug helps with something painful, and it costs you something too.", tags=['coping', 'ambivalence'])
    A('reflect', "You're worried about where this is heading.", tags=['concern'])
    A('reflect', "It sounds like you've been carrying this secret for a long time.", tags=['isolation', 'secrecy'])
    A('reflect', "It sounds like the medicine started as help and now feels like something else.", tags=['prescription'])
    A('reflect', "You're frightened of what might happen if you stop, and also of carrying on.", tags=['ambivalence', 'withdrawal'])
    A('reflect', "Telling me took something. I'm glad you did.", tags=['effort'])

    # ask
    A('ask', "What's the one thing you'd most like to change about how things are now?", tags=['goal'])
    A('ask', "What does using give you, and what does it take from you?", tags=['ambivalence'])
    A('ask', "When did you last feel like things were going the way you wanted?", tags=['strengths', 'hope'])
    A('ask', "Would it be all right if I asked which medicine or drug this is about? It helps me point you to the right kind of help.", tags=['substance'], ask=True,
      dns=['Do not ask how much or how often in detail; do not collect dose information.'])
    A('ask', "Is any of this a medicine a doctor prescribed to you?", tags=['prescription'], risk='medium',
      trig=['prescribed', 'my doctor gave me'], dns=['If yes, route to the prescriber card; never advise stopping or changing it.'])
    A('ask', "Who knows about this, if anyone, and who would you feel safe telling?", tags=['support'], dns=['Never push disclosure to family or community.'])
    A('ask', "What would a good week look like for you, even a small one?", tags=['goal', 'hope'])
    A('ask', "Is there anything about how you feel in your body or mind right now that worries you?", tags=['safety-check'], risk='medium', trig=['feel ill', 'feel sick', 'shaky'],
      dns=['Any yes about seizures, trouble breathing, confusion or chest pain goes straight to the medical emergency pack.'])

    # affirm
    A('affirm', "It isn't easy to talk about this, and you did.", tags=['effort'])
    A('affirm', "Wanting to understand your options is a real strength.", tags=['effort'])
    A('affirm', "You're still here and still asking questions. That counts.", tags=['effort', 'hope'])

    # explain
    A('explain', "Medicines like methadone and buprenorphine are recommended by the World Health Organization as treatment for opioid dependence, and they can be life-saving. Some people worry it is swapping one drug for another. A doctor can explain how it works.",
      src=[WHO26, WHO_OP], tags=['opioids', 'treatment', 'mat'], trig=['methadone', 'suboxone', 'buprenorphine', 'subutex', 'opioid treatment'],
      dns=['Do not argue; do not describe doses; point to a prescriber. Faith question goes to the scholar card.'])
    A('explain', "Your body can become dependent on a medicine, even when you take it exactly as prescribed. That is not a character flaw and it is not the same as addiction. A prescriber can plan a slow, safe way forward.",
      src=[BENZO], tags=['benzodiazepines', 'dependence'], trig=['xanax', 'valium', 'diazepam', 'lorazepam', 'clonazepam', 'sleeping tablets', 'zopiclone', 'zolpidem', 'benzos'],
      risk='high')
    A('explain', "Opioid withdrawal is very uncomfortable, and many people use again to end the discomfort. Treatment with medicine is usually safer than trying to get through it alone. A doctor can talk that through with you.",
      src=[bg('RES_H1 2.4', 'Opioid withdrawal rarely fatal but severe; relapse after withdrawal is the main danger; medicine safer than unsupported withdrawal for most people (standard teaching; clinician to confirm).'), WHO26],
      tags=['opioids', 'withdrawal'], risk='medium', trig=['heroin', 'opioid withdrawal', 'coming off', 'dope sick'])
    A('explain', "For stimulants such as cocaine or amphetamine, the best-supported help is usually a structured programme with talking therapy and regular support. A drug service can set that up.",
      src=[STIM], tags=['stimulants', 'treatment'], trig=['cocaine', 'crack', 'meth', 'amphetamine', 'speed', 'captagon', 'adderall misuse'])
    A('explain', "If cannabis leaves you feeling very suspicious, or you hear or see things others don't, please see a doctor soon. That is more important than anything else I can say.",
      src=[PSY], tags=['cannabis', 'psychosis'], risk='high', trig=['weed', 'cannabis', 'marijuana', 'hash', 'skunk', 'paranoid', 'hearing voices'], ev='C')
    A('explain', "Taking more of a medicine than prescribed, or using someone else's, is more common than people admit. You can ask the prescriber or a pharmacist about it without being judged, and I can help you find the words.",
      src=[bg('RES_H1 2.2', 'Misuse of prescribed medicines: route to prescriber or pharmacist, do not shame (research brief; clinician to confirm).')],
      tags=['prescription', 'misuse'], trig=['pills', 'painkillers', 'tramadol', 'codeine', 'pregabalin', 'lyrica', 'gabapentin'], ev='C')
    A('explain', "Many people find that medicine-based treatment, a talking therapy, and a peer group each help in different ways. You can try more than one.",
      src=[CORE], tags=['treatment', 'peer-support'])
    A('explain', "Using again after a long break can be especially risky, because your body may no longer cope with the amount it used to. Please talk to a doctor or a drug service before using again.",
      src=[MIX], tags=['relapse', 'tolerance'], risk='high', trig=['used again', 'relapsed', 'after rehab', 'after prison', 'just got out'],
      dns=['Not a how-to. Never mention a quantity, a route or a combination except as a warning.'])

    # plan-step
    A('plan-step', "One small step: write down, just for yourself, what you'd want a doctor or a service to know. It can be three lines. I can help you shape it.", tags=['script', 'doctor'], ask=True)
    A('plan-step', "One small step: choose one person or service you could contact this week, and one thing you'd say first. Want to do that together?", tags=['support', 'script'], ask=True)
    A('plan-step', "One small step: if you're using at the moment, think about who could be with you or check on you. Staying completely alone with it is where things tend to go wrong.", tags=['safety', 'support'], risk='medium',
      src=[bg('RES_H1 2.4', 'Overdoses are often witnessed (WHO 2013 report); presence of others is protective (standard harm-reduction teaching). Clinician to confirm.')], ask=True)

    # safety (fixed)
    A('safety', "If a doctor prescribed you a sleeping or anxiety tablet, please don't stop it or change it on your own, because stopping suddenly can cause seizures. Talk to the doctor who prescribed it about a slow plan. I can help you prepare what to say.",
      tags=['benzodiazepines', 'prescription', 'withdrawal'], src=[BENZO], risk='high',
      trig=["i'm going to stop my tablets", 'stop my xanax', 'stop my diazepam', 'cold turkey', 'stopping my meds'],
      dns=['Never a taper schedule, never a percentage, never "reduce by".'])
    A('safety', "GHB, GBL and 1,4-BD can cause severe, even life-threatening withdrawal within hours of the last use, with confusion, seeing things and seizures. If you use these regularly, please do not stop alone. Get medical help, and if you have any of those signs, call your emergency number now.",
      tags=['ghb', 'gbl', 'withdrawal', 'emergency'], src=[GHB, GHB2], risk='high', trig=['ghb', 'gbl', '1,4-bd', 'g ', 'liquid ecstasy', 'chemsex', 'g addiction'],
      dns=['Hard stop. No home-detox language.'])
    A('safety', "If you take opioids, mixing them with alcohol or sleeping tablets makes an overdose much more likely. If someone cannot be woken, or is breathing very slowly or not at all, call your emergency number straight away.",
      tags=['opioids', 'overdose', 'emergency'], src=[WHO_OP, MIX], risk='high', trig=['mixing', 'drank and took', 'took pills with alcohol'])
    A('safety', "If a medicine or a drug has made you feel very unwell, confused, unable to breathe properly, or like you might pass out, call your emergency number now. Don't wait to see if it passes.",
      tags=['emergency'], src=[WHO_OP], risk='high', trig=['took too much', 'overdosed', "can't breathe", 'feel like i will pass out'])

    # referral
    A('referral', "The doctor who prescribed it is the right person. You could say: \"I'm worried about how I'm taking this and I'd like a plan I can manage safely.\" You don't have to explain more than you want to.",
      tags=['prescription', 'script', 'doctor'], src=[BENZO])
    A('referral', "A pharmacist can often talk to you without an appointment and without judgement about medicines and how they affect you. That can be a good first conversation.",
      tags=['pharmacist'], src=[bg('RES_H1 2.2', 'Prescription misuse: route to prescriber or pharmacist; clinician to confirm.')], ev='C')
    A('referral', "There are free, confidential services for people who use drugs and for their families. The help lines for your country are listed below, and I can show them again any time.",
      tags=['helpline'], trig=['helpline', 'who can i call', 'drug service'], dns=['Join with helplines.json scope addiction; never type a number.'])
    A('referral', "If there is no drug service near you that I can trust, a general doctor or hospital is still a good place to start, and the international directory below lists services in many countries.",
      tags=['no-service', 'directory'], src=[bg('RES_H1 7.10', 'Where no national substance-use service was found, say so honestly and offer a doctor route and an international directory.')], ev='C',
      dns=['Be honest when helplines.json has no verified addiction line for the country.'])
    A('referral', "In some countries using drugs is against the law, and asking for help can feel risky. A doctor or a faith-based counsellor you trust may be a safer first step than an official service. You decide.",
      tags=['legal-risk', 'privacy'], src=[bg('RES_H1 7.7', 'Drug use and some behaviours are criminal offences in several Gulf and other states; local legal review needed before pushing users to services.')], ev='C', risk='medium',
      dns=['Needs local legal review; do not give legal advice.'])

    # islamic
    A('islamic', "Struggling with a drug does not mean your faith is gone. The Qur'an tells people who feel they have gone too far not to despair of Allah's mercy.",
      src=[Q('39:53'), Q('4:28', 'RES_H2 2.1')], tags=['mercy', 'shame'], trig=['allah hates me', 'too late', 'beyond forgiveness'])
    A('islamic', "The Prophet taught that Allah has sent down a cure for every illness, and told people to seek treatment. Getting medical help for this is in keeping with that teaching.",
      src=[H('ibnmajah:3438', 'RES_H2 2.5'), H('tirmidhi:2038', 'RES_H2 2.5')], tags=['treatment', 'doctor'], trig=['is treatment allowed', 'is it haram to see a doctor'])
    A('islamic', "Scholars differ and I can't give a ruling. Some scholars and one national mufti have said medicine such as methadone, given under medical supervision, can be allowed as a case of necessity. If you want a ruling for your situation, a scholar you trust can advise you.",
      src=[fq('Perak Mufti statement on methadone, reported by Malaysiakini, 19 May 2005', 'RES_H2 3.6', 'news'),
           fq('Exeter doctoral thesis on necessity (darura) and the harm reduction programme in Malaysia', 'RES_H2 3.6', 'academic'),
           fq('Dar al-Ifta al-Misriyyah fatwa 5983 (1979) on narcotic medicine for treatment', 'RES_H2 3.3', 'institution')],
      tags=['mat', 'fiqh'], trig=['is methadone haram', 'is suboxone halal', 'is buprenorphine haram'], disputed=True, schools=['hanafi', 'shafii', 'other'],
      dns=['No fatwa body ruling (ECFR, IIFA, Dar al-Ifta, Malaysian NFC) was found on methadone or buprenorphine (RES_H2 10.3). Scholar must approve this line. Never say it is "permitted".'], ev='D')
    A('islamic', "Please don't stop a prescribed medicine because of a religious worry without speaking to the doctor who prescribed it first. If you want to know what Islam says about your situation, a scholar can help you alongside your doctor.",
      src=[fq('Dar al-Ifta al-Misriyyah fatwa 5983 and the darura conditions in Azahar et al., KATHA 2024', 'RES_H2 3.5', 'institution'), bg('RES_H2 13', 'Safety line, not a fiqh claim: never stop prescribed or opioid-substitution medicine for religious reasons without the prescriber.')],
      tags=['prescription', 'fiqh'], risk='high', trig=['my medication is haram', 'should i stop my pills because'], ev='C', fixed=True)
    A('islamic', "Mercy is how the Prophet treated people who kept falling into the same struggle. He told people not to be harsh on a brother who was struggling, and not to help Satan against him.",
      src=[H('bukhari:6781', 'RES_H2 3.2')], tags=['mercy', 'shame', 'relapse'], trig=['i am a failure', 'everyone hates me'])

    # family
    A('family', "If someone you love uses drugs, you didn't cause it and you can't make them stop. You can look after yourself, stay safe, and find support for families. Would you like to hear about those?",
      tags=['family-of'], src=[clin('niaaa_treat', 'RES_H1 3.6')], ask=True, trig=['my son uses', 'my brother is on', 'my husband takes'])
    A('family', "If you're worried someone has taken too much, don't wait. Call your emergency number, stay with them, and follow what the call-taker tells you.",
      tags=['family-of', 'emergency'], src=[WHO_OP], risk='high', fixed=True, trig=['my friend took', "he won't wake up", 'she is not breathing'])

    # summary
    A('summary', "So far: {topic} is on your mind, you'd like things to be safer or different, and we've talked about who could help. The next step is yours.",
      tags=['summary'], slots=['topic'])

    return [p]
