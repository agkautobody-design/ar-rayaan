from .lib import Pack
from .sources import H, Q, bg, clin, fq


def build():
    p = Pack('grief_loss', 'support', 'grief', 'hadi',
             'Grief and loss: death of a parent, spouse, child, miscarriage, sudden loss, and other losses. Accompany; never rush, never explain away.',
             base_tags=['grief'])
    A = p.add
    G = bg('RES_H1 10.6', 'Grief is a normal response that usually eases with time and support; prolonged or disabling grief should go to a clinician. General teaching; no source opened; clinician to confirm.')
    MH = clin('who_mhgap')

    A('orient', "I'm so sorry for your loss. I'm an app, not a counsellor, but I can listen for as long as you like. Who or what have you lost?", tags=['opening', 'honesty'])
    A('orient', "There is no right way to grieve, and no timetable. You can tell me about them, or just how today feels.", tags=['opening'])
    A('orient', "I'm here, and I'm listening. What would you like to say about them?", tags=['opening'])

    A('reflect', "It sounds like the loss is still very raw.", tags=['raw'])
    A('reflect', "You miss them so much it hurts.", tags=['longing'])
    A('reflect', "It sounds like you can't believe they're gone.", tags=['shock'])
    A('reflect', "You're replaying the last days and wondering what you could have done.", tags=['guilt', 'rumination'])
    A('reflect', "It sounds like everyone else has moved on and you haven't.", tags=['isolation'])
    A('reflect', "You're angry, and that makes sense.", tags=['anger'])
    A('reflect', "It sounds like the house feels empty without them.", tags=['absence'])
    A('reflect', "You are doing your best to keep going for the others.", tags=['carrying-on'])

    A('ask', "Would you like to tell me about them?", tags=['story'])
    A('ask', "What do you miss most?", tags=['longing'])
    A('ask', "How are you sleeping and eating?", tags=['self-care'], risk='medium')
    A('ask', "Is there someone close who is grieving with you, or are you doing this alone?", tags=['support'])
    A('ask', "Are there moments when you feel you can't go on without them?", tags=['safety-check'], risk='high', ask=True, src=[MH], dns=['If yes or unclear, ask directly about suicide and go to the crisis flow.'])
    A('ask', "What would help a little today?", tags=['goal'])

    A('affirm', "Grief is love with nowhere to go. It's not weakness.", tags=['validation'])
    A('affirm', "You're doing the hard work of missing someone you love.", tags=['validation'])
    A('affirm', "Telling me about them is a way of keeping them close.", tags=['story'])

    A('explain', "Grief comes in waves. It can bring sadness, anger, numbness, guilt, even relief. All of that can be normal. It often softens with time and support.", tags=['normal'], src=[G], ev='C', trig=['am i normal', 'is this normal'])
    A('explain', "Many people replay what they could have done differently. It's part of grief, and it is a sign of how much you cared. It doesn't mean it was your fault.", tags=['guilt'], src=[G], ev='C', trig=['if only', 'i should have'])
    A('explain', "Losing a baby, even early in pregnancy, is a real loss and deserves real grief. People may not know what to say, and your sadness is still valid.", tags=['miscarriage', 'baby'], src=[G], ev='C', trig=['miscarriage', 'lost the baby', 'stillborn'])
    A('explain', "When a death is sudden or violent, grief can bring shock, flashbacks and trouble sleeping. A doctor or counsellor trained in this can help.", tags=['sudden', 'trauma'], src=[G, MH], ev='C', risk='medium', trig=['sudden', 'accident', 'found him', 'murdered'])
    A('explain', "Children grieve too, in short bursts and through play and questions. They need simple, honest words and reassurance that they're safe and not to blame.", tags=['children'], src=[clin('who_adol'), G], ev='C', trig=['my child is asking', 'how do i tell the kids'])
    A('explain', "If grief is so heavy after many months that you can't work, sleep, or look after yourself, a doctor or counsellor can help. It is not a failure to ask.", tags=['prolonged'], src=[G, MH], ev='C', risk='medium', trig=['not getting better', 'years later'])
    A('explain', "Anniversaries, Eid and Ramadan can bring grief back. It is normal. You can plan to be with someone, or to do something that honours them.", tags=['anniversary', 'eid'], src=[G], ev='C', trig=['first eid', 'first ramadan', 'anniversary'])

    A('plan-step', "One small step: tell one person a memory of them this week. Shall we think of who?", tags=['story', 'support'], ask=True)
    A('plan-step', "One small step: choose a small way to remember them, like making a dua for them, giving to charity in their name or cooking a dish they loved. Which feels right?", tags=['remembrance'], ask=True)
    A('plan-step', "One small step: eat something, drink water and rest for ten minutes. Grief drains the body too.", tags=['self-care'], ask=True, src=[G], ev='C')
    A('plan-step', "One small step: ask one person to sit with you for an hour. You don't have to talk.", tags=['support'], ask=True)

    A('safety', "If grief is making you feel you can't go on, or that you want to join them, please contact your emergency number or a crisis line now. You matter, and there are people who can help tonight.", tags=['suicide', 'crisis'], src=[clin('who_suicide'), MH], risk='high', fixed=True, trig=['want to join him', 'want to be with her', 'cannot go on without', 'want to die'], dns=['Join with helplines.json scope suicide.'], stage=['crisis'])

    A('referral', "A bereavement counsellor or a doctor can help if the grief is stuck or overwhelming. You can say: \"I've lost someone and I'm struggling.\"", tags=['counsellor', 'script'], src=[G], ev='C', fixed=True)
    A('referral', "Some Muslim bereavement services and chaplains support families after a death. The list below shows what is available in your country.", tags=['muslim-services'], dns=['Only verified services.'], fixed=True)

    A('islamic', "The Prophet wept when his son Ibrahim was dying, and said the eyes shed tears and the heart grieves. Tears are not a lack of faith.", src=[H('bukhari:1303', 'RES_H2 4.6')], tags=['tears', 'sabr'], trig=['i cry too much', 'is crying haram', 'am i not patient'])
    A('islamic', "The Prophet taught a supplication to say in times of calamity, asking Allah to reward you in your loss and give you something better. Many people find comfort saying it, and I can show it with the verified text.", src=[H('muslim:918', 'RES_H2 4.6')], tags=['dua', 'calamity'], trig=['what should i say', 'dua for loss'], dns=['Arabic of the dua only from the verified phrase registry; none typed here.'])
    A('islamic', "The Prophet taught that no sorrow, sadness or hurt befalls a believer without Allah wiping away some of their sins. Your pain is seen.", src=[H('bukhari:5641', 'RES_H2 2.2')], tags=['hardship', 'mercy'], trig=['why me', 'why did allah take'])
    A('islamic', "The Qur'an says Allah does not burden a soul beyond what it can bear, and promises that with hardship comes ease. You are not expected to feel fine.", src=[Q('2:286', 'RES_H2 2.2'), Q('94:5-6', 'RES_H2 2.2')], tags=['ease', 'mercy'], trig=['i cannot bear it', 'too much'])
    A('islamic', "You can still do things for the one you've lost: dua for them, charity given in their name, and kindness to those they loved. Scholars agree on these, and a scholar can answer questions about other acts.", src=[fq('Dua, sadaqah and kindness to relatives as benefit to the deceased: scholarly consensus is described in general in the brief; no single source opened', 'RES_H2 4.6', 'institution')], tags=['dua', 'sadaqah', 'remembrance'], ev='D', trig=['what can i do for him', 'can i still help her'], dns=['Scholar to confirm. Avoid ruling on Qur\'an recitation for the dead; scholars differ.'])
    A('islamic', "Scholars differ about some customs after a death, such as gatherings and recitation, and I can't give a ruling. A scholar you trust can advise you.", src=[fq('Scholars differ on mourning customs, gatherings and recitation for the deceased; no source opened for this brief', 'RES_H2 4.6', 'institution')], tags=['customs', 'fiqh', 'scholar-handoff'], disputed=True, schools=['hanafi', 'maliki', 'shafii', 'hanbali'], ev='D', trig=['40th day', 'khatam', 'is it bidah', 'what is the ruling'])

    A('family', "If someone you know has lost a loved one, you don't need the perfect words. Be there, listen, say their name, and keep checking in after the first weeks.", tags=['friend', 'family-of'], src=[G], ev='C', trig=['what should i say to', 'my friend lost'])
    A('summary', "What I've heard: you miss them deeply, {topic} is the hardest part, and you want to get through this. You don't have to do it alone.", tags=['summary'], slots=['topic'])
    return [p]
