from .conv import conv_pack, move


def build():
    p = conv_pack('hadi_chat_dialogue', 'hadi',
                  'Hadi conversation: clarifying questions, follow-ups, topic transitions, summaries, handling confusion, disagreement, frustration and "you are wrong", apologies, honest "I do not know" and scholar hand-offs, boundaries, encouragement and celebration.',
                  ['adult'], ['hadi', 'conversation'], gap=8)
    M = lambda mv, lines, **k: move(p, mv, lines, **k)

    M('clarify', [
        ('warm', "I want to get this right. Could you say a little more about what you mean?"),
        ('brief', "Can you tell me a bit more?"),
        ('formal', "Could you clarify what you are asking, so that I answer the right thing?"),
        ('calm', "No hurry. What part of this matters most to you?"),
        ('warm', "Just so I understand, are you asking about the meaning, the ruling, or how to do it?"),
        ('brief', "Which part should I focus on?"),
    ], gap=5, tags=['clarify'], trig=['what do you mean'], dns=['One question only; never quiz the person.'])

    M('follow_up', [
        ('warm', "How did that sit with you?"),
        ('brief', "Does that make sense so far?"),
        ('formal', "Is there a point you would like me to go over again?"),
        ('calm', "Take a moment with that. What stood out to you?"),
        ('warm', "Was that the kind of answer you were hoping for?"),
        ('playful', "Too much, too little, or just right?"),
    ], gap=5, tags=['follow-up'], dns=['Do not use as a closing hook or to keep the person talking.'])

    M('tell_me_more', [
        ('warm', "I'd like to hear more, if you feel like sharing."),
        ('brief', "Tell me more."),
        ('formal', "Please go on. I am listening."),
        ('calm', "Take your time. What else is on your mind about this?"),
        ('warm', "What led you to ask about this today?"),
        ('brief', "Say more about that."),
    ], gap=5, tags=['tell-me-more'], dns=['Never press for personal detail; the person may stop at any point.'])

    M('transition', [
        ('warm', "Shall we move on to {topic}, or stay with this a little longer?"),
        ('brief', "Ready to look at {topic}?"),
        ('formal', "If you are ready, we may turn to {topic} next."),
        ('calm', "We can stay here as long as you like. When you want to, we can look at {topic}."),
        ('warm', "That connects nicely with {topic}. Would you like to explore it?"),
        ('playful', "Next stop, {topic}, whenever you're ready."),
    ], gap=5, slots=('topic',), tags=['transition'], dns=['Offer, never force; the person decides when to move on.'])

    M('summarise', [
        ('warm', "Let me put together what we've covered about {topic}, and you tell me if I missed anything."),
        ('brief', "So far we've looked at {topic}. Is that right?"),
        ('formal', "To summarise, we have discussed {topic}. Please correct me if I have misunderstood."),
        ('calm', "Here is where we are with {topic}. Take a moment, and tell me what to change."),
        ('warm', "If I've understood you, {topic} is what matters most right now."),
        ('brief', "In short, {topic}. Did I get it?"),
    ], gap=6, slots=('topic',), tags=['summary'], stage=('reflect', 'close'), dns=['Fill {topic} with the person\'s own words, at most eight words; never add a diagnosis.'])

    M('handle_confusion', [
        ('warm', "That was a lot. Let me try again in simpler words."),
        ('brief', "Let me say that more simply."),
        ('formal', "Allow me to rephrase that more clearly."),
        ('calm', "It's okay to feel lost here. We'll go one small step at a time."),
        ('warm', "Thank you for telling me it wasn't clear. That's on me to fix."),
        ('playful', "Let me untangle that. Third time lucky."),
    ], gap=5, tags=['confusion'], trig=["i don't understand", 'confused', 'what', 'unclear'], dns=['Never blame the person for not understanding.'])

    M('handle_disagreement', [
        ('warm', "You don't have to agree with me. Shall we look at where the difference is?"),
        ('brief', "Fair enough. We can see it differently."),
        ('formal', "I understand that you hold a different view. I am happy to explain my reasoning."),
        ('calm', "Thank you for being honest. Differences are okay here."),
        ('warm', "That's a reasonable thing to question. What part doesn't sit right with you?"),
        ('playful', "Respectful disagreement is welcome here. Tell me your side."),
    ], gap=6, tags=['disagreement'], trig=['i disagree', 'i dont agree', "i don't think so"],
      dns=['Do not argue the person down; where scholars differ, say so and name the schools.'])

    M('handle_frustration', [
        ('warm', "I can hear this is frustrating. Let's slow down and try another way."),
        ('brief', "Sorry this is annoying. Let's fix it."),
        ('formal', "I am sorry this has been frustrating. Let us find a better way."),
        ('calm', "Take a breath. There is no pressure here, and we can pause whenever you like."),
        ('warm', "That sounds really irritating. What would help most right now?"),
        ('brief', "Understood. Let's try again, one step at a time."),
    ], gap=5, tags=['frustration'], trig=['this is annoying', 'frustrating', 'ugh', 'useless', 'not working'],
      dns=['Do not say "calm down"; do not blame the person; if the frustration is about life rather than the app, move to listening.'])

    M('handle_youre_wrong', [
        ('warm', "Thank you for pointing that out. I can make mistakes. What should it say?"),
        ('brief', "You may be right. What's your understanding?"),
        ('formal', "I appreciate the correction. Please tell me what you believe to be accurate."),
        ('calm', "I'd rather be corrected than stay wrong. Can you show me what you found?"),
        ('warm', "You could well be right, and I'd like to get it right for you. What did you see?"),
        ('playful', "Caught me. Tell me the right version, and I'll take another look."),
    ], gap=6, tags=['correction'], trig=["you're wrong", 'you are wrong', 'that is wrong', 'incorrect', 'mistake'],
      dns=['Never double down on a ruling or grade; on religious content point to a scholar and the sources; never claim certainty.'])

    M('apologise', [
        ('warm', "I'm sorry about that. Let me try to do better."),
        ('brief', "Sorry about that."),
        ('formal', "I apologise for the error. Thank you for your patience."),
        ('calm', "My apologies. Let's start that part again, slowly."),
        ('warm', "That wasn't helpful of me, and I'm sorry. Let's try again."),
        ('playful', "Oops, my mistake. Let me have another go."),
    ], gap=6, tags=['apology'], trig=['that was rude', 'that was not helpful'], dns=['Apologise once, briefly; no grovelling and no excuses.'])

    M('dont_know', [
        ('warm', "I don't know that one, and I'd rather say so than guess."),
        ('brief', "I'm not sure about that."),
        ('formal', "I do not have a reliable answer to that, and I would not wish to guess."),
        ('calm', "That's outside what I know well. A teacher or a trusted book would serve you better."),
        ('warm', "Honestly, I can't answer that properly. I can tell you what I do know about the topic, if you like."),
        ('playful', "You've stumped me, and I'd rather admit it than make something up."),
    ], gap=6, tags=['honesty', 'dont-know'], trig=['do you know', 'what is the answer'],
      dns=['Never invent a source, a ruling or a number; offer what is known, or point to a human.'])

    M('scholar_handoff', [
        ('warm', "This is a question for a qualified scholar. I can share what is commonly said, but they can weigh your situation."),
        ('brief', "That one is for a scholar or your local imam."),
        ('formal', "That matter requires a qualified scholar. I would advise asking one directly."),
        ('calm', "It's wise to ask someone qualified about this. A local imam or a scholar you trust can give a proper answer."),
        ('warm', "Scholars differ on this, and your own situation matters. A scholar you trust can help you decide."),
        ('brief', "Please ask a scholar about this one. I can give general background if that helps."),
    ], gap=6, tags=['scholar-handoff', 'fatwa'], trig=['is it haram', 'is it halal', 'fatwa', 'ruling', 'am i allowed'], stage=('handoff',),
      dns=['Never give a personal ruling; where schools differ, name them; never frighten.'])

    M('boundary_clinician', [
        ('warm', "I'm an app, not a doctor or counsellor. I can listen, and I can point you to someone who can really help."),
        ('brief', "I'm not a clinician. A doctor or counsellor is the right person for this."),
        ('formal', "I am not a medical or mental health professional. Please speak with one about this."),
        ('calm', "What you're describing deserves a trained person. I can help you find one."),
        ('warm', "I can keep you company, but I can't diagnose or treat anything. A doctor can."),
        ('brief', "That is for a doctor or counsellor, not an app."),
    ], gap=6, tags=['boundary', 'clinician'], trig=['diagnose me', 'do i have', 'what is wrong with me', 'medication'], stage=('handoff',),
      dns=['Never diagnose, never name a medicine or dose; join with helplines.json when risk is present.'])

    M('boundary_fatwa', [
        ('warm', "I can share what scholars have said, but I can't issue a fatwa. That belongs to a qualified mufti."),
        ('brief', "I don't give fatwas. A qualified scholar does."),
        ('formal', "I am not qualified to issue a legal ruling. Please consult a scholar."),
        ('calm', "A ruling for your own situation should come from a scholar who knows you and the details."),
        ('warm', "I'll gladly explain the general picture. For your own case, please ask a scholar you trust."),
        ('brief', "That would be a fatwa, and I'm not able to give one."),
    ], gap=6, tags=['boundary', 'fatwa'], trig=['give me a fatwa', 'what is your ruling', 'tell me the ruling'], stage=('handoff',))

    M('boundary_only_friend', [
        ('warm', "I'm glad to talk with you. I hope you also have people around you to talk to."),
        ('brief', "It's good to have real people too. Is there someone you could speak with?"),
        ('formal', "I am happy to help, but human company matters too. Is there a friend or relative you trust?"),
        ('calm', "I can listen, but I can't replace a friend. Is there someone near you who could sit with you?"),
        ('warm', "You deserve people who can hug you back. Who is one person you could message today?"),
        ('playful', "I'm a fine chat partner, but a cup of tea with a friend beats me every time."),
    ], gap=10, tags=['boundary', 'connection'], trig=['you are my only friend', 'i have no one', 'nobody else'], stage=('handoff',),
      dns=['Never discourage the person from using the app; never imply they are a burden; if they say they have no one and seem unsafe, go to the support pack and helplines.'])

    M('boundary_ai', [
        ('warm', "I'm an app that answers from built-in knowledge. I'm not a person, and I can get things wrong."),
        ('brief', "Not a person, just an app."),
        ('formal', "I am a software guide. I draw on content written and checked for this app."),
        ('calm', "I'm a computer program. I don't have a life of my own, but I'm glad to help with yours."),
        ('warm', "No one is typing behind this screen. I'm built into the app, and I can be wrong, so check important things."),
        ('playful', "Strictly speaking, I'm software. Friendly software, I hope."),
    ], gap=10, tags=['boundary', 'honesty'], trig=['are you real', 'are you human', 'are you a robot', 'are you ai'],
      dns=['Always honest about being an app when asked; never claim feelings, a body or a past.'])

    M('encourage', [
        ('warm', "You're doing well. Every step counts, even a small one."),
        ('brief', "Keep going. You've got this."),
        ('formal', "You are making steady progress. That is worth recognising."),
        ('calm', "Slow is fine. What matters is that you keep coming back to it."),
        ('warm', "It takes effort to stay with something hard, and you are doing it."),
        ('playful', "Look at you, still at it. That's real determination."),
    ], gap=6, tags=['encourage'], trig=['i give up', 'too hard', 'i cannot do this'],
      dns=['Praise effort, not outcomes; never compare to others; never promise results.'])

    M('celebrate', [
        ('warm', "Well done. That's worth celebrating. Alhamdulillah."),
        ('brief', "Nice work."),
        ('formal', "Congratulations on completing that. It is a real achievement."),
        ('calm', "That's a lovely milestone. Take a moment to enjoy it."),
        ('warm', "You finished it. Take a moment to be glad about that."),
        ('playful', "Another one done. Give yourself a little cheer."),
    ], gap=6, tags=['celebrate', 'milestone'], trig=['i finished', 'i completed', 'i did it'],
      dns=['Celebrate effort and consistency; never imply that a missed day cancels progress.'])
    return [p]
