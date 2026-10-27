from .lib import Pack
from .sources import H, Q, bg, clin, fq


def build():
    p = Pack('smoking_vaping', 'support', 'smoking', 'hadi',
             'Smoking, vaping, shisha and chewing tobacco: quitting support, pharmacist and quitline hand-over, with the faith position shown as a scholars-differ matter.',
             base_tags=['smoking'])
    A = p.add
    EV = bg('RES_H1 3.11', 'Behavioural support plus pharmacotherapy roughly doubles quit rates and quitlines work: brief gives this as general knowledge, no source opened; clinician to supply the source.')
    CBT = bg('RES_H1 3.11', 'Triggers, delay and routines: standard cessation content; clinician to confirm.')
    TOB = fq('Saudi Permanent Committee, Malaysia NFC 2015 and Dar al-Ifta al-Misriyyah fatwa 21455 (29 Sep 2024): smoking forbidden on harm grounds; Indonesia MUI 2009 and some South Asian Hanafi opinions: makruh', 'RES_H2 3.4', 'institution', schools=['hanafi'])

    A('orient', "I'm an app, not a doctor. I can listen, share what is known about quitting, and point you to quit services. Is this about cigarettes, vaping, shisha or something else?", tags=['opening', 'honesty'])
    A('orient', "Wanting to cut down or stop is a good thing to be thinking about, whatever you've tried before. What's on your mind?", tags=['opening'])
    A('orient', "You can talk about this at your own pace. I won't lecture you. Where would you like to begin?", tags=['opening', 'honesty'])

    A('reflect', "It sounds like you want to stop, and it hasn't been easy.", tags=['ambivalence'])
    A('reflect', "Smoking helps you cope, and you're tired of what it costs.", tags=['coping', 'ambivalence'])
    A('reflect', "You're worried about your health, your money or the people around you.", tags=['concern'])
    A('reflect', "It sounds like you've tried before and it didn't last.", tags=['relapse'])
    A('reflect', "You'd like to be free of it, and it also feels like a comfort.", tags=['ambivalence'])
    A('reflect', "Vaping feels like a smaller thing, and it is still hard to put down.", tags=['vaping'])

    A('ask', "What would you like to be different about smoking or vaping?", tags=['goal'])
    A('ask', "When do you reach for it most?", tags=['trigger'])
    A('ask', "What have you tried before, and what helped even a little?", tags=['strengths'])
    A('ask', "What would be the best thing about being free of it?", tags=['goal', 'hope'])
    A('ask', "Who around you smokes, and would anyone support you in stopping?", tags=['support'])
    A('ask', "Are you pregnant, or planning to be, or do you have a health condition you take medicine for?", tags=['medical-screen'], risk='medium', ask=True,
      dns=['If yes, route to a doctor or midwife before any advice about quit medicines.'])

    A('affirm', "Thinking about quitting is already a step.", tags=['effort'])
    A('affirm', "Every attempt teaches you something, and many people need several tries.", tags=['effort', 'hope'])
    A('affirm', "You came here to talk about it, and that counts.", tags=['effort'])

    A('explain', "Quitting is easier with support. Talking help from a quitline, together with medicine that a pharmacist or doctor can advise on, helps many people quit. You can also do it with only one of these.", src=[EV], tags=['treatment', 'support'], ev='C', trig=['best way to quit', 'how do i quit'])
    A('explain', "Nicotine replacement products, like patches or gum, are available at many pharmacies. A pharmacist can tell you what suits you and how to use it.", src=[EV], tags=['nrt', 'pharmacist'], ev='C', risk='medium', trig=['patches', 'gum', 'nicotine replacement'],
      dns=['Never doses or schedules; hand over to the pharmacist.'])
    A('explain', "Some people stop all at once and some cut down first. Both can work. What matters is picking a plan you can stick with and getting support.", src=[EV], tags=['approach'], ev='C', trig=['cold turkey', 'cut down first'])
    A('explain', "Cravings pass, usually within a few minutes. Delaying and doing something else gets you through many of them.", src=[CBT], tags=['craving', 'delay'], ev='C', trig=['craving', 'urge'])
    A('explain', "Vaping is not risk-free, and it can keep you dependent on nicotine. If you want to stop, the same kinds of support help.", src=[bg('RES_H1 3.11', 'Vaping evidence not researched in this session; clinician to supply source.')], tags=['vaping'], ev='C', trig=['vape', 'e-cigarette', 'juul'])
    A('explain', "Smoking shisha is still smoking tobacco. If you want to cut down, the same support applies.", src=[bg('RES_H1 3.11', 'Shisha not researched; clinician to confirm.')], tags=['shisha'], ev='C', trig=['shisha', 'hookah', 'argileh'])
    A('explain', "Slips are common when quitting. A slip is not the end of the road. It's information about what to plan for next time.", src=[CBT], tags=['relapse', 'hope'], ev='C', trig=['slipped', 'relapsed', 'started again'])
    A('explain', "If you smoke while pregnant, or are around a pregnant woman who smokes, please speak to a doctor or midwife. Quitting is worth doing, and they can support you in a safe way.", src=[bg('RES_H1 8', 'Smoking in pregnancy needs a clinician (brief section 8).')], tags=['pregnancy'], risk='high', ev='C', trig=['pregnant', 'smoke while pregnant'])

    A('plan-step', "One small step: choose a quit day, even a few weeks away, and tell one person you trust. Want to pick one together?", tags=['quit-date'], src=[CBT], ask=True, ev='C')
    A('plan-step', "One small step: when a craving comes, wait fifteen minutes and do one other thing, like a drink of water, a walk or wudu. Shall we choose your thing now?", tags=['craving', 'delay'], src=[CBT], ask=True, ev='C')
    A('plan-step', "One small step: ask a pharmacist what could help you. You could say: \"I want to stop smoking. What are my options?\"", tags=['pharmacist', 'script'], src=[EV], ask=True, ev='C')

    A('safety', "If you ever feel chest pain, trouble breathing, or a cough with blood, please see a doctor today, or call your emergency number if it is severe.", tags=['red-flag', 'emergency'], src=[bg('RES_H1 3.11', 'Chest pain, breathlessness and haemoptysis are standard red flags; clinician to confirm wording.')], risk='high', ev='C',
      trig=['chest pain', 'coughing blood', "can't breathe"])

    A('referral', "A quitline can give free advice and support to quit. The numbers for your country are listed below if one exists, and I can show them again whenever you like.", tags=['quitline'], dns=['Join with helplines.json; mark honestly where none is verified.'], trig=['quitline', 'who can i call'])
    A('referral', "A pharmacist or a doctor can help you plan to quit and talk about medicines that make it easier.", tags=['pharmacist', 'doctor'], src=[EV], ev='C')
    A('referral', "If you're a young person, a school nurse or a doctor can talk about this in private. You don't have to tell anyone else first.", tags=['teen', 'private'], age=['13-17'], src=[bg('RES_H1 10.6', 'Teen vaping: direct to a doctor or school nurse; not researched further.')], ev='C', clinician=True, safeguard=True)

    A('islamic', "Many scholars today say smoking is forbidden because of its proven harm, while others, including some older and South Asian Hanafi opinions, call it disliked. Scholars differ, and I can't give you a ruling. If you want to ask, a scholar you trust can help.", src=[TOB], tags=['fiqh'], disputed=True, schools=['hanafi', 'maliki', 'shafii', 'hanbali'], ev='D', trig=['is smoking haram', 'is vaping haram', 'is shisha haram'],
      dns=['Neither "definitely haram" nor "definitely fine". Scholar to approve.'])
    A('islamic', "The Prophet taught that there should be no harm and no harming. Many people find that a good reason to look after their body and their family's air.", src=[H('ibnmajah:2340', 'RES_H2 3.4')], tags=['harm', 'health'],
      dns=['Do not cite as a ruling on tobacco; it is a general principle that scholars apply differently.'])
    A('islamic', "The Prophet encouraged seeking treatment, saying Allah has not sent down a disease without sending down its cure. Getting help to quit fits that.", src=[H('ibnmajah:3438', 'RES_H2 2.5'), H('tirmidhi:2038', 'RES_H2 2.5')], tags=['treatment'], trig=['is it okay to use patches', 'is medication allowed'])
    A('islamic', "Struggling with this does not mean your faith is weak. Allah asks for effort, not perfection, and the Prophet said the religion is easy.", src=[H('bukhari:39', 'RES_H2 2.2')], tags=['mercy', 'ease'], trig=['i am weak', 'bad muslim'])
    A('islamic', "During Ramadan many people find it a natural time to begin, since they already go many hours without. If you would like a plan for before and after the fast, I can help.", src=[bg('RES_H2 13', 'Authored suggestion; no source claims it; clinician to confirm no safety issue.')], tags=['ramadan'], ev='C', clinician=True, trig=['ramadan', 'fasting and smoking'])

    A('family', "If someone you love smokes, you can tell them calmly that you care and offer support. You can't make them stop, and you can keep your home smoke-free.", tags=['family-of'], src=[EV], ev='C', trig=['my father smokes', 'my husband vapes'])
    A('summary', "What I've heard: you'd like to be free of smoking, {topic} makes it hard, and you're thinking about a plan. The next step is yours.", tags=['summary'], slots=['topic'])
    return [p]
