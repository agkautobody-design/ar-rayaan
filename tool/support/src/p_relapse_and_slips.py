from .lib import Pack
from .sources import H, Q, bg, clin, fq


def build():
    p = Pack('relapse_and_slips', 'support', 'relapse', 'hadi',
             'After a slip or relapse, any substance or behaviour: no shaming, learn from it, return to the plan, and keep safety front of mind.',
             base_tags=['relapse'])
    A = p.add
    CORE = clin('niaaa_core')
    RP = bg('RES_H1 3.8', 'Relapse is common and a slip is information for the plan: standard relapse-prevention teaching; the NIAAA Core Resource describes relapse as common; clinician to confirm.')
    TOL = bg('RES_H1 2.4', 'After time off, tolerance falls and the same amount can be dangerous (opioids; standard teaching); clinician to confirm.')

    A('orient', "Thank you for telling me. A slip doesn't undo what you've done so far. What happened?", tags=['opening', 'no-shame'])
    A('orient', "I'm glad you came back, even after this. You can tell me as much as you like.", tags=['opening', 'no-shame'])
    A('orient', "Slips happen, and they are not the end. Where are you right now?", tags=['opening'])

    A('reflect', "You feel you've let yourself and others down.", tags=['shame'])
    A('reflect', "It sounds like you were doing well, and this hit hard.", tags=['setback'])
    A('reflect', "You're disappointed, and you're also here, still trying.", tags=['effort'])
    A('reflect', "It sounds like you're afraid it all starts again.", tags=['fear'])
    A('reflect', "You want to hide it, and part of you wants to talk.", tags=['secrecy'])
    A('reflect', "It sounds like it came on suddenly.", tags=['trigger'])
    A('reflect', "You were stressed, and it was the thing you knew.", tags=['coping'])
    A('reflect', "You're angry with yourself.", tags=['self-criticism'])

    A('ask', "What was going on just before it happened?", tags=['trigger'])
    A('ask', "What did you do right, even in the middle of it?", tags=['strengths'])
    A('ask', "Are you safe at this moment?", tags=['safety-check'], risk='high', ask=True)
    A('ask', "What do you need most right now?", tags=['needs'])
    A('ask', "What would you want to do differently if the same moment came again?", tags=['learning'])
    A('ask', "Who could you tell, if you chose to?", tags=['support'], dns=['Never push disclosure.'])

    A('affirm', "Coming back and telling me takes honesty.", tags=['effort'])
    A('affirm', "The days you went without still happened. They count.", tags=['progress'])
    A('affirm', "You didn't give up on yourself. That matters.", tags=['effort'])

    A('explain', "Slips are common on the road away from alcohol, drugs, gambling and other habits. They don't mean treatment has failed. They show what to plan for next time.", tags=['normal', 'learning'], src=[CORE, RP], ev='C', trig=['i failed', 'back to square one', 'i ruined it'])
    A('explain', "The first day after a slip is often the most important. Getting back to your plan, and getting support, tends to matter more than the slip itself.", tags=['recovery', 'plan'], src=[RP], ev='C', trig=['what now', 'what do i do now'])
    A('explain', "If you used drugs after a long break, your body may not cope with what it used to. Please speak to a doctor or a drug service before using again, and don't use alone.", tags=['tolerance', 'overdose-risk'], src=[TOL, clin('who_opioid')], ev='C', risk='high', trig=['used again after', 'after rehab', 'after prison', 'after a long time'],
      dns=['Warning only; no amounts, routes or combinations.'])
    A('explain', "If you have been drinking heavily every day and you want to stop again, please see a doctor first, because stopping suddenly can be dangerous.", tags=['alcohol', 'withdrawal'], src=[clin('niaaa_cut'), clin('nice_cg100')], risk='high', trig=['drinking again', 'back on it'])
    A('explain', "A relapse can feel like proof that you can't change. It's not. Many people who go on to do well had several slips on the way.", tags=['hope'], src=[CORE, RP], ev='C', trig=['can\'t change', 'always do this'])

    A('plan-step', "One small step: write down what led up to this, just the facts, no blaming. It will help the next plan.", tags=['trigger-log'], src=[RP], ev='C', ask=True)
    A('plan-step', "One small step: tell one person today. It could be a counsellor, a peer or a friend. Shall we think about who and what to say?", tags=['support', 'script'], src=[RP], ev='C', ask=True)
    A('plan-step', "One small step: change one thing in the next hour that makes using harder, like leaving a place or putting distance between you and it.", tags=['environment'], src=[RP], ev='C', ask=True)
    A('plan-step', "One small step: book a visit with your doctor or counsellor this week, to restart your plan.", tags=['appointment'], src=[RP], ev='C', ask=True)

    A('safety', "If you have used drugs or taken pills and feel very unwell, can't be woken, or are struggling to breathe, call your emergency number now.", tags=['overdose', 'emergency'], src=[clin('who_opioid')], risk='high', fixed=True, trig=['i overdosed', 'took too much'])
    A('safety', "If shame or despair after a slip is making you think about ending your life, please contact your emergency number or a crisis line now. A slip is not the end.", tags=['suicide', 'crisis'], src=[clin('who_suicide'), clin('who_mhgap')], risk='high', fixed=True, trig=['kill myself', 'end it', 'what is the point'], stage=['crisis'], dns=['Join with helplines.json scope suicide.'])

    A('referral', "Your counsellor or doctor will want to hear about the slip, and they won't judge it. If you don't have one, a drug or alcohol service can help you restart.", tags=['counsellor', 'doctor'], src=[RP], ev='C', fixed=True)
    A('referral', "A peer support group can help the first days after a slip. They have all been there. I can show what exists in your country.", tags=['peer-support'], src=[CORE], ev='C', fixed=True, dns=['Only verified services.'])

    A('islamic', "The Prophet taught that Allah is more pleased with the repentance of a servant than a man who finds his lost camel in the desert. Coming back after a slip is what He loves.", src=[H('bukhari:6308', 'RES_H2 1.1'), H('muslim:2744', 'RES_H2 1.1')], tags=['tawbah', 'mercy'], trig=['again', 'repented and fell'])
    A('islamic', "A man was brought before the Prophet again and again for drinking, and when a man spoke harshly of him the Prophet said not to, for he loves Allah and His Messenger. Mercy is how the Prophet treated repeated slips.", src=[H('bukhari:6780', 'RES_H2 3.2')], tags=['mercy', 'relapse'], trig=['i keep going back', 'again and again'], dns=['Only after repeated relapse is mentioned.'])
    A('islamic', "The Prophet said that Allah accepts repentance, and taught that good deeds wipe out bad ones. You can follow a slip with a good deed.", src=[H('tirmidhi:1987', 'RES_H2 1.2'), H('muslim:2763', 'RES_H2 1.2')], tags=['tawbah', 'good-deeds'], trig=['what can i do to make up', 'how do i make it right'])
    A('islamic', "The Prophet told us about a man who had killed many people, who asked if he could repent, and was told to move to a place of righteous people. Changing your surroundings is part of a fresh start.", src=[H('bukhari:3470', 'RES_H2 1.1'), H('muslim:2766', 'RES_H2 1.1')], tags=['environment', 'tawbah'], trig=['same friends', 'same place'])
    A('islamic', "Scholars differ on some questions after a slip, such as whether prayers must be repeated, and I can't give a ruling. A scholar can advise you, and it is fine to ask without sharing details.", src=[fq('Scholars differ on prayer and purity questions after intoxication; no source opened for this brief', 'RES_H2 3.1', 'institution')], tags=['prayer', 'fiqh', 'scholar-handoff'], disputed=True, schools=['hanafi', 'maliki', 'shafii', 'hanbali'], ev='D', trig=['do i repeat my prayers', 'are my prayers valid', 'ruling'],
      dns=['Never quote the "forty days" report.'])

    A('family', "If someone you love has slipped, try to stay calm, tell them you still care, and ask what would help. Shouting rarely helps, and they may already feel ashamed.", tags=['family-of'], src=[CORE], ev='C', trig=['he relapsed', 'she is using again'])
    A('summary', "What I've heard: you slipped, {topic} was part of it, and you want to get back on track. A slip is one moment, and the next step is yours.", tags=['summary'], slots=['topic'])
    return [p]
