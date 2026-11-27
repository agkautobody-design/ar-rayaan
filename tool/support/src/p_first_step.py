from .p_everyday_four import _pack
from .sources import Q

FIRST = dict(
    bg="Reluctance to seek help: privacy, fear of judgement and shame are common; a small first step and a ready script make contact easier; talking to an app can be a stepping stone. General teaching; clinician to confirm.",
    orient=["You're welcome to start here, with me. There's no pressure to talk to a person until you're ready. What's on your mind?",
            "Plenty of people find it easier to say it to an app first. I won't judge, and you set the pace."],
    reflect=[("It sounds like you're afraid of how people would look at you if they knew.", ['judge', 'embarrass', 'ashamed']),
             ("It sounds like you've been carrying this alone because telling someone feels risky.", ['alone', 'tell', 'secret']),
             ("It sounds like you don't know who is safe to tell.", ['trust', 'safe', 'who']),
             ("It sounds like you want help, just not face to face yet.", ['face', 'person', 'phone'])],
    ask=["What worries you most about telling someone?", "Is it about being judged, about privacy, or about not knowing what to say?", "Would a message be easier than a call or a visit?", "Who is the safest person you can think of, even if you wouldn't tell them yet?"],
    affirm=["Wanting to be careful about who you tell is sensible, not cowardly.", "Saying anything at all, even here, is a real first step."],
    explain=[("Most people who finally tell someone say they wish they had done it sooner, and that the reaction was kinder than expected. It's still okay to go slowly.", ['afraid', 'scared', 'judge']),
             ("Doctors, counsellors and helplines keep what you say private, with narrow exceptions around serious danger. You can ask them about it at the start.", ['privacy', 'private', 'confidential']),
             ("You can start small: write a message and don't send it, practise it with me, then send it by text or email. Contact doesn't have to start with a conversation.", ['what to say', 'how to start', 'script'])],
    step=["One small step: tell me the first sentence you'd want to say to someone, and we'll make it as easy as possible.", "One small step: we can write a short message together that you can send to one safe person or a service.", "One small step: choose which feels easiest, text, email, a phone line, or an in-person visit, and we'll plan that one."],
    faith_step="One small step: tell Allah first, in your own words. He already knows, and it can make saying it to a person lighter.",
    referral="When you're ready, a doctor, counsellor or helpline can listen. You can start with: \"I'm finding something hard to talk about, and I'd like help with how to begin.\" Many services let you start by text or chat.",
    islamic=[("You are not obliged to broadcast your struggles. Choosing carefully who to tell is allowed; start with Allah and with one safe person.", [Q('2:286', 'RES_H2 2.2')], ['secret', 'private', 'conceal']),
             ("Allah says He is near and answers the one who calls. You can speak to Him before anyone, and He is never shocked.", [Q('2:186', 'RES_H2 2.2')], ['allah', 'dua', 'near']),
             ("Allah's mercy encompasses all things, and He says not to despair of it. Nothing you tell Him closes the door.", [Q('39:53', 'RES_H2 2.2')], ['shame', 'sin', 'despair'])],
    family="If someone you love finds it hard to open up, don't push for details. Say you're there whenever they're ready and keep inviting them gently.")


def build():
    return [_pack('first_step', 'first_step', 'Not ready to talk to a person: privacy, fear of judgement, first small steps and scripts, Allah first.', 'first-step', FIRST)]
