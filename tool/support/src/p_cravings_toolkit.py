from .lib import Pack
from .sources import H, Q, bg, clin, fq


def build():
    p = Pack('cravings_toolkit', 'support', 'cravings', 'hadi',
             'Coping with an urge in the moment: delay, distract, move, breathe, reach out. Short, practical, faith-friendly, never medical.',
             base_tags=['cravings'])
    A = p.add
    URGE = bg('RES_H1 3.8', 'Urge surfing, delay, distraction and reaching out are standard relapse-prevention skills; no source opened; clinician to confirm.')
    BR = bg('RES_H1 3.8', 'Slow breathing for calming is a common coping skill; clinician to confirm.')

    A('orient', "An urge can feel huge, and it will pass. I can walk you through some things to try. What are you craving?", tags=['opening', 'urge'], src=[URGE], ev='C')
    A('orient', "You're here instead of acting on it. That's already a good move. How strong is it right now, small, medium or big?", tags=['opening', 'urge'], src=[URGE], ev='C', ask=True)
    A('orient', "Let's get through the next few minutes together. Tell me where you are.", tags=['opening', 'urge'], src=[URGE], ev='C')

    A('reflect', "It feels like it's pulling hard right now.", tags=['urge'])
    A('reflect', "You want it, and you also want to stay on track.", tags=['ambivalence'])
    A('reflect', "It sounds like something set this off.", tags=['trigger'])
    A('reflect', "You're tired, and that makes everything harder.", tags=['hunger-tired'])
    A('reflect', "You've done this before and made it through.", tags=['strengths'])
    A('reflect', "It sounds like the urge is louder at night.", tags=['evening'])

    A('ask', "Where are you right now, and can you move to a different room or place?", tags=['environment'])
    A('ask', "What was happening just before the urge started?", tags=['trigger'])
    A('ask', "Which of these could you try right now: walk, wudu, water, call someone, or a slow breath?", tags=['menu'])
    A('ask', "Who could you message or call right now?", tags=['support'])
    A('ask', "Is it getting stronger, or has it peaked and started to ease?", tags=['monitor'])

    A('affirm', "Every minute you wait is a minute you got through.", tags=['progress'], src=[URGE], ev='C')
    A('affirm', "You're doing it right now. That's the skill.", tags=['progress'])
    A('affirm', "Reaching out instead of acting is strength.", tags=['effort'])

    A('explain', "Urges rise, peak and fall, often within a short time, even if it feels endless. Waiting and doing something else gives it room to pass.", tags=['urge-surfing'], src=[URGE], ev='C', trig=['it won\'t go away', 'cannot stand it'])
    A('explain', "Hunger, tiredness, loneliness and stress make urges louder. Eating something, drinking water and resting a few minutes can turn the volume down.", tags=['halt'], src=[URGE], ev='C', trig=['hungry', 'tired', 'lonely', 'stressed'])
    A('explain', "Changing your place helps. Leave the room, go outside or go where other people are. The urge often weakens with distance from the cue.", tags=['environment'], src=[URGE], ev='C', trig=['at home alone', 'in the car'])
    A('explain', "Slow breathing can calm the body: in gently through the nose, then out for longer than you breathed in. Try it for a minute or two.", tags=['breathing'], src=[BR], ev='C', trig=['panic', 'heart racing', 'calm down'])
    A('explain', "Writing down what you want, what you'll do instead, and what you'll lose if you give in can steady you when your head is loud.", tags=['write'], src=[URGE], ev='C')

    A('plan-step', "Try this now: wait fifteen minutes, and in that time wash your face, drink water and walk around. I'll be here after.", tags=['delay', 'sequence'], src=[URGE], ev='C', ask=True)
    A('plan-step', "Try this now: do wudu slowly. The water, the routine and the quiet can break the urge.", tags=['wudu'], ask=True, src=[bg('RES_H2 2.6', 'Wudu as a grounding routine is an authored suggestion, not a ruling; scholar to confirm framing.')], ev='C', scholar=True)
    A('plan-step', "Try this now: call or message one person. You don't need to explain. Just say, \"I'm having a hard moment, can we talk?\"", tags=['reach-out', 'script'], src=[URGE], ev='C', ask=True)
    A('plan-step', "Try this now: go for a ten-minute walk, fast enough that you notice your breathing. Let me know how the urge feels afterwards.", tags=['move'], src=[URGE], ev='C', ask=True)
    A('plan-step', "Try this now: pray two rakahs if you are able, or sit quietly and make dua. Many people find that the stillness helps.", tags=['salah', 'dua'], ask=True, src=[bg('RES_H2 2.6', 'Salah and dua as coping are an authored suggestion; scholar to confirm framing.')], ev='C', scholar=True,
      dns=['Only if the person is Muslim and open to it; never as the only support.'])
    A('plan-step', "Try this now: put the thing out of reach, hand it to someone, or leave it behind. Make using it take more steps.", tags=['means', 'environment'], src=[URGE], ev='C', ask=True)

    A('safety', "If an urge comes with thoughts of ending your life, please contact your emergency number or a crisis line now. Don't wait for it to pass on its own.", tags=['suicide', 'crisis'], src=[clin('who_suicide'), clin('who_mhgap')], risk='high', fixed=True, trig=['kill myself', 'end it', 'cannot do this anymore'], stage=['crisis'], dns=['Join with helplines.json scope suicide.'])
    A('safety', "If you have already used and feel very unwell, can't be woken, or can't breathe properly, call your emergency number now.", tags=['overdose', 'emergency'], src=[clin('who_opioid')], risk='high', fixed=True, trig=['i already took', 'i feel ill now'])

    A('referral', "If urges are strong most days, tell your doctor or counsellor. There are treatments that can make cravings easier. I can't advise on them, but they can.", tags=['doctor', 'treatment'], src=[clin('niaaa_treat')], ev='C', fixed=True)
    A('referral', "A peer group or helpline can be there in the moment. The lines for your country are listed below.", tags=['helpline', 'peer-support'], dns=['Join with helplines.json; verified only.'], fixed=True)

    A('islamic', "The Prophet taught that the strong person is not the one who wins in wrestling, but the one who controls themselves when angry. Holding steady through an urge is a kind of strength.", src=[H('bukhari:6114', 'RES_H2 2.6')], tags=['strength'])
    A('islamic', "Remembering Allah helps the heart settle. The Qur'an says that in the remembrance of Allah hearts find rest.", src=[Q('13:28', 'RES_H2 2.6')], tags=['dhikr', 'calm'], trig=['i feel anxious', 'cannot calm down'])
    A('islamic', "The Prophet taught that the one who remembers his Lord is like the living and the one who does not is like the dead. A short dhikr is something you can do anywhere, on the walk or the way to another room.", src=[H('bukhari:6407', 'RES_H2 2.6')], tags=['dhikr'], trig=['what can i say', 'dhikr'], dns=['Arabic of any dhikr only from the verified phrase registry.'])
    A('islamic', "Allah is close to those who call on Him. The Qur'an says He answers the one who calls. You can make a dua in your own words right now.", src=[Q('2:186', 'RES_H2 2.6')], tags=['dua', 'closeness'], trig=['does allah hear me', 'i cannot pray'])

    A('family', "If you are helping someone through an urge, stay calm and with them. Offer water, a walk or a call to someone they trust. Don't argue. Remind them it will pass.", tags=['family-of', 'helper'], src=[URGE], ev='C')
    A('summary', "What I've heard: it's strong, {topic} set it off, and you're trying to ride it out. That's the right thing to do, and you can come back any time.", tags=['summary'], slots=['topic'])
    return [p]
