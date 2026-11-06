from .lib import Pack
from .sources import H, Q, bg, clin


def build():
    p = Pack('money_hardship', 'support', 'money', 'hadi',
             'Money hardship: debt, job loss, rent and bills, providing for a family, shame around money. Listen first; never judge; pair practical small steps with the Qur\'anic promise of provision.',
             base_tags=['distress'])
    A = p.add
    G = bg('RES_H1 10.1', 'Emotional support: listening, validation and small steps help; persistent or disabling distress should go to a clinician. General teaching; no source opened; clinician to confirm.')
    MH = clin('who_mhgap')

    A('orient', "Money worry sits in the body — the chest, the sleep, the appetite. However heavy it is tonight, you can set it down here for a moment.", tags=['opening'])
    A('orient', "I am glad you said it out loud. Money is one of the hardest things to say out loud, and you just did.", tags=['opening'])
    A('orient', "There is no shame in this room. Tell me plainly how it is, and we will look at it together.", tags=['opening'])

    A('reflect', "Debt does not just sit on paper — it sits on your chest, and it sounds like it has been there a while.", tags=['debt'], trig=['debt', 'debts', 'loan', 'loans', 'owe', 'owed'])
    A('reflect', "Losing work is not only losing income. It can feel like losing footing, and you sound shaken by it.", tags=['job'], trig=['fired', 'redundant', 'job', 'jobless', 'work'])
    A('reflect', "It sounds like the basics themselves — rent, bills, food — have become a source of fear. That is real fear, not exaggeration.", tags=['essentials'], trig=['rent', 'bills', 'food', 'groceries', 'evicted'])
    A('reflect', "Carrying a family's needs on your back and feeling the ground shake is a lonely kind of pressure.", tags=['providing'], trig=['provide', 'providing', 'family', 'children', 'mouths'])
    A('reflect', "It sounds like shame is part of it too — like you feel you should have prevented this somehow.", tags=['shame-money'], trig=['ashamed', 'shame', 'embarrassed', 'failure'])
    A('reflect', "It sounds like you have been hiding how bad it is, even from people close to you. Hiding it doubles the weight.", tags=['hiding'], trig=['hiding', 'secret', 'pretend', 'pretending'])
    A('reflect', "Watching everyone else seem fine while you count coins is a particular kind of loneliness.", tags=['comparison'], trig=['everyone', 'comparing', 'behind', 'others'])
    A('reflect', "It sounds like the uncertainty is the hardest part — not knowing how next month looks at all.", tags=['uncertainty'], trig=['uncertain', 'unknown', 'month', 'future'])
    A('reflect', "It sounds like money strain has reached into your home and your relationships too. That happens, and it hurts.", tags=['strain'], trig=['marriage', 'arguments', 'home', 'spouse'])

    A('ask', "What is the number that frightens you most — and have you said it aloud to anyone yet?", tags=['priority'])
    A('ask', "How did it get here — slowly, or all at once?", tags=['story'])
    A('ask', "Who else depends on your income right now?", tags=['dependents'])
    A('ask', "How are you sleeping with all this on your mind?", tags=['self-care'], risk='medium')
    A('ask', "Is there anyone who could stand with you practically — family, community, your masjid?", tags=['support'])
    A('ask', "What would breathing room look like — not riches, just room?", tags=['goal'])
    A('ask', "Has it ever got so dark that you felt you could not go on?", tags=['safety-check'], risk='high', ask=True, src=[MH], dns=['If yes or unclear, ask directly about suicide and go to the crisis flow.'])

    A('affirm', "Struggling with money says nothing about your worth. Some of the finest people who ever lived knew hunger.", tags=['worth'])
    A('affirm', "Facing the numbers honestly, which you are doing right now, is the bravest financial move there is.", tags=['courage'])
    A('affirm', "You are carrying responsibility for others. That weight exists because you care.", tags=['care'])
    A('affirm', "Asking for help with money is not failure. The community you have given to is allowed to hold you too.", tags=['help'])

    A('explain', "Money fear narrows thinking — it is a known effect of scarcity, not a flaw in you. That is why small written steps work better than big worried plans.", tags=['scarcity'], src=[G], ev='C', trig=['think', 'focus', 'cant', 'mind'])
    A('explain', "Unopened letters and unchecked balances grow scarier in the dark. Writing the real numbers down almost always shrinks them to a size you can work with.", tags=['numbers'], src=[G], ev='C', trig=['letters', 'balance', 'bank', 'scared'])
    A('explain', "Creditors and landlords respond better to early, honest contact than to silence. Asking for time is a normal, expected request — they have processes for it.", tags=['creditors'], src=[G], ev='C', trig=['creditors', 'landlord', 'owe', 'payment'])
    A('explain', "Questions about loans, interest and what is permissible belong to a qualified scholar who knows your situation. The worry itself, though — that we can carry together here.", tags=['ruling'], trig=['interest', 'riba', 'loan', 'permissible', 'allowed'])
    A('explain', "Zakat and charity exist precisely for seasons like this. Receiving in a hard season is part of the design, not a humiliation.", tags=['zakat'], trig=['zakat', 'charity', 'accept', 'help'])
    A('explain', "Job loss grief is real grief. You are allowed to mourn a job, a business, a plan — and then, gently, to start again.", tags=['grief'], src=[G], ev='C', trig=['fired', 'redundant', 'business', 'lost'])

    A('plan-step', "One small step: write down every debt and every bill, plainly, on one page. Not to solve tonight — just to see it in the light.", tags=['clarity'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: choose the loudest debt and ask that one creditor for time or a plan. One call, one letter. That is all today needs.", tags=['creditor'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: tell one trusted person the truth about how tight it is. Money shame dies in daylight.", tags=['support'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: list three things you can do that someone would pay for, then send one message or one application. Just one.", tags=['income'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: ask your masjid or a local charity what support exists. You may be surprised how much is built for exactly this.", tags=['community'], ask=True, src=[G], ev='C')

    A('safety', "If money despair ever turns into thoughts of ending your life, please contact your emergency number or a crisis line now. Debts can be renegotiated; you cannot be replaced.", tags=['suicide', 'crisis'], src=[clin('who_suicide'), MH], risk='high', fixed=True, trig=['ending', 'hopeless', 'pointless'], dns=['Join with helplines.json scope suicide.'], stage=['crisis'])

    A('referral', "Free debt advice services exist in many countries and will negotiate with creditors on your behalf. A quick search for free debt advice in your country, or a call to a listening line below, can start that today.", tags=['debt-advice'], src=[G], ev='C', fixed=True, trig=['advice', 'service', 'help'])
    A('referral', "If this weight has sat on you for weeks and nothing lifts it, a doctor or counsellor can genuinely help you carry it. You can say: \"Money stress is crushing me and I need support.\"", tags=['counsellor'], src=[G, MH], ev='C', fixed=True, trig=['weeks', 'months', 'always', 'worse'])

    A('islamic', "Allah promises in the Qur'an that whoever is mindful of Him, He will make a way out and provide for him from where he never expected. Doors you cannot see yet are still doors.", src=[Q('65:2-3', 'RES_H2 2.2')], tags=['provision', 'hope'], trig=['provision', 'rizq', 'door', 'hope'])
    A('islamic', "The Qur'an says there is no creature on earth whose provision is not upon Allah. Yours is written and on its way; your job is the step, His is the arrival.", src=[Q('11:6', 'RES_H2 2.2')], tags=['provision'], trig=['provision', 'rizq', 'written'])
    A('islamic', "The Prophet himself used to seek Allah's protection from worry and grief, and from the weight of debt. If he taught that prayer, he knew this fear — you are not alone in it.", src=[H('bukhari:6369', 'RES_H2 4.2')], tags=['debt', 'dua'], trig=['debt', 'worry', 'grief'])
    A('islamic', "The Prophet taught a dua for debt: \"O Allah, suffice me with Your lawful against Your unlawful, and enrich me by Your bounty from all besides You.\" You can say it tonight, slowly.", src=[H('tirmidhi:3563', 'RES_H2 4.2')], tags=['dua', 'debt'], trig=['dua', 'debt', 'words'])
    A('islamic', "The Prophet taught that whoever takes people's wealth intending to repay it, Allah will repay on his behalf. An honest intention is already half the road.", src=[H('bukhari:2387', 'RES_H2 4.2')], tags=['intention', 'repay'], trig=['repay', 'intention', 'intend'])
    A('islamic', "The Prophet taught that whoever gives respite to someone in difficulty, Allah will give him respite in this world and the next. Allah's gentleness with the hard-pressed is the measure of all gentleness.", src=[H('muslim:1563', 'RES_H2 4.2')], tags=['respite', 'mercy'], trig=['time', 'respite', 'gentle'])
    A('islamic', "The Qur'an promises that with hardship comes ease — not after it, with it. Some part of the ease is already here, even if you cannot feel it yet.", src=[Q('94:5-6', 'RES_H2 2.2')], tags=['ease'], trig=['ease', 'hardship', 'hard'])

    A('family', "If someone you love is drowning in money worry, do not open with advice or blame. Feed them, sit with them, and help them face one number at a time.", tags=['friend', 'family-of'], src=[G], ev='C', trig=['friend', 'husband', 'wife', 'son', 'father'])
    A('summary', "What I've heard: {topic} is pressing hard, and you want room to breathe again. One honest number, one honest conversation, one step — that is the road.", tags=['summary'], slots=['topic'])
    return [p]
