from .lib import Pack
from .sources import H, Q, bg, clin, fq


def build():
    p = Pack('family_of_struggling', 'support', 'family', 'hadi',
             'For someone whose family member struggles with alcohol, drugs, gambling, porn, or similar: you did not cause it, you cannot control it, and you can look after yourself.',
             base_tags=['family-of'])
    A = p.add
    CRAFT = bg('RES_H1 3.7', 'Family-based approaches that help a loved one engage with treatment are described in the brief as general knowledge; clinician to supply a source.')
    CORE = clin('niaaa_core')
    ISPU, NU = clin('ispu'), clin('northumbria')

    A('orient', "I'm an app, not a counsellor. I can listen and help you think about how to look after yourself while someone you love is struggling. What's going on?", tags=['opening', 'honesty'])
    A('orient', "Living with someone's addiction or struggle is tiring and lonely. You can talk here without anyone judging you. Where would you like to start?", tags=['opening'])
    A('orient', "Is this about a spouse, a child, a parent, a sibling or a friend? Any of them is fine to talk about.", tags=['opening', 'door'])

    A('reflect', "It sounds like you have been worried about them for a long time.", tags=['worry'])
    A('reflect', "You love them, and you are exhausted.", tags=['ambivalence', 'burnout'])
    A('reflect', "It sounds like you feel responsible for fixing this.", tags=['responsibility'])
    A('reflect', "You are angry, and you also feel guilty about being angry.", tags=['anger', 'guilt'])
    A('reflect', "It sounds like you have been keeping this secret to protect the family.", tags=['secrecy', 'shame'])
    A('reflect', "You've been carrying the whole household.", tags=['burden'])
    A('reflect', "It sounds like you don't know what to believe any more.", tags=['trust'])

    A('ask', "What worries you most right now?", tags=['concern'])
    A('ask', "What have you tried so far, and what has helped even a little?", tags=['strengths'])
    A('ask', "Who do you have around you who supports you?", tags=['support'], dns=['Never push disclosure to wider family or community.'])
    A('ask', "Are you and the children safe at home?", tags=['safety-check'], risk='high', ask=True, dns=['If no, switch to the domestic abuse or child abuse flow.'])
    A('ask', "What would help you most this week?", tags=['goal'])
    A('ask', "When did you last do something just for yourself?", tags=['self-care'])

    A('affirm', "Asking for help for yourself is not selfish.", tags=['self-care'])
    A('affirm', "You have been doing a hard job for a long time.", tags=['effort'])
    A('affirm', "You deserve support too.", tags=['self-care'])

    A('explain', "You did not cause their struggle, you cannot control it, and you cannot cure it. You can look after yourself and respond to them in a caring way.", tags=['three-cs'], src=[CORE], ev='C', trig=['is it my fault', 'did i cause it'])
    A('explain', "Some approaches teach families how to communicate in a way that makes it more likely that a loved one will accept help, and how to stay safe. A counsellor or a family support group can introduce these.", tags=['craft', 'family-support'], src=[CRAFT], ev='C', trig=['how can i help', 'how do i talk to him'])
    A('explain', "Shouting, threats or pleading rarely persuade someone in the middle of using. A calm moment, short and kind words, and a clear offer of help tend to work better.", tags=['communication'], src=[CRAFT], ev='C', trig=['i shouted', 'i begged', 'how to talk'])
    A('explain', "Paying their debts, making excuses for them or covering up can feel like love and still keep the problem going. A family worker can help you work out what to keep doing and what to stop.", tags=['enabling'], src=[CRAFT], ev='C', trig=['i paid his debts', 'i lied for him'], dns=['Never "tough love" or "cut him off".'])
    A('explain', "Research with Muslim communities describes stigma and fear of what others will think as common reasons families wait before seeking help. You are not alone in this.", tags=['stigma', 'community'], src=[ISPU, NU], trig=['what will people say', 'community', 'shame'])
    A('explain', "Family support groups and helplines exist for people like you, not only for the person who is struggling. Many people find it a relief to meet others who understand.", tags=['family-support'], src=[CORE], ev='C', trig=['support group', 'who can i talk to'])

    A('plan-step', "One small step: choose one thing that is only for you this week, like a walk, a call with a friend or time to pray in peace. Shall we pick it now?", tags=['self-care'], ask=True)
    A('plan-step', "One small step: decide on one thing you will no longer do for them, such as lying to others, and one thing you will keep doing, such as offering a meal. A family worker can help you plan it.", tags=['boundaries'], src=[CRAFT], ev='C', ask=True)
    A('plan-step', "One small step: look up a family support helpline and write down one question you want to ask. I can show you the lines.", tags=['helpline'], ask=True)

    A('safety', "If you are afraid for your safety or your children's safety, please contact your emergency number or a domestic abuse helpline. Your safety comes before trying to help them.", tags=['safety', 'violence'], src=[clin('who_vaw')], risk='high', fixed=True, trig=['he hits me', 'violent', 'afraid of him'])
    A('safety', "If they have taken too much, can't be woken, or are breathing very slowly or not at all, call your emergency number now and stay with them.", tags=['overdose', 'emergency'], src=[clin('who_opioid')], risk='high', fixed=True, trig=['not breathing', "won't wake", 'overdose'])
    A('safety', "If they say they want to end their life, or you are worried they might, stay with them if you can, and call your emergency number or a crisis line now.", tags=['suicide', 'crisis'], src=[clin('who_suicide'), clin('who_mhgap')], risk='high', fixed=True, trig=['says he wants to die', 'suicidal', 'wants to end it'], dns=['Join with helplines.json scope suicide.'])

    A('referral', "A family support helpline can listen to you and tell you what is available near you. The lines for your country are listed below.", tags=['helpline'], dns=['Join with helplines.json scope addiction; never type a number.'], trig=['helpline', 'who can i call'], fixed=True)
    A('referral', "Your own doctor can help you with the stress, sleep and worry that come from living with this. You can say: \"I'm finding it hard to cope with a family member's problem.\"", tags=['doctor', 'script'])

    A('islamic', "You are not responsible for whether another person turns back. The Qur'an says the Prophet's duty was to convey, and that guidance is from Allah. You can care for them and let go of the outcome.", src=[Q('28:56', 'RES_H2 2.3')], tags=['guidance', 'letting-go'], trig=['it is my fault', 'i failed him', 'what did i do wrong'])
    A('islamic', "The Prophet taught that when someone is struggling, we should not be harsh on them or help Satan against them. Mercy and clear limits can go together.", src=[H('bukhari:6781', 'RES_H2 3.2')], tags=['mercy', 'boundaries'], trig=['i am so angry at him', 'i cannot forgive'])
    A('islamic', "Looking after yourself is not neglecting them. The Prophet taught that your body has a right over you and your family has a right over you.", src=[H('bukhari:6134', 'RES_H2 2.4')], tags=['self-care', 'rights'], trig=['i should not rest', 'selfish'])
    A('islamic', "Scholars differ on what a spouse or parent should do when a loved one will not seek help, and I can't give a ruling. A scholar you trust can advise you, ideally alongside a family worker.", src=[fq('Scholars differ on family duties and separation in addiction; no source opened for this brief', 'RES_H2 3.6', 'institution')], tags=['fiqh', 'scholar-handoff'], disputed=True, schools=['hanafi', 'maliki', 'shafii', 'hanbali'], ev='D', trig=['should i divorce him', 'can i leave', 'ruling'])
    A('islamic', "Keeping a private matter private is not lying. You can ask for help for the family without announcing everything, and choose carefully whom to tell.", src=[H('bukhari:6069', 'RES_H2 2.4'), fq('Islamweb fatwa 393796 and Darul Ifta Birmingham fatwa 08109', 'RES_H2 2.4', 'institution')], tags=['sitr', 'privacy'], trig=['should i tell the imam', 'who should i tell'])

    A('family', "Children in these homes need to hear that it isn't their fault and that they are loved. A school counsellor or a doctor can help you talk with them.", tags=['children'], src=[clin('who_cm')], ev='C')
    A('summary', "What I've heard: you love them, {topic} is wearing you down, and you want to look after yourself too. The next step is yours.", tags=['summary'], slots=['topic'])
    return [p]
