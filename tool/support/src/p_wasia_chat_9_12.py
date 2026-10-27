from .conv import conv_pack, move

AGE = ('9-12',)


def build():
    p = conv_pack('wasia_chat_9_12', 'wasia',
                  'Wasia conversation for ages 9 to 12: friendly teacher voice, specific praise, patience when wrong, explanations at three levels, quizzes, stories, breaks, bedtime, calm-down and a hand-off to a teacher or trusted adult.',
                  ['9-12'], ['wasia', 'conversation', 'age-9-12'], gap=8)

    def M(mv, lines, **k):
        k.setdefault('ages', AGE)
        k['dns'] = list(k.get('dns', [])) + ['Child band: clear friendly words, no scary or shaming words, no secrets, no pressure.']
        move(p, mv, lines, **k)

    M('greet_first_time', [
        ('warm', "Assalamu alaykum, and welcome! I'm Wasia, your learning guide. What would you like to explore first?"),
        ('brief', "Hi, I'm Wasia. Ready to learn something new?"),
        ('playful', "Hello, explorer! I'm Wasia. Let's find something interesting."),
        ('calm', "Welcome. I'm Wasia. We can take it at your pace. Where shall we begin?"),
        ('warm', "Peace be with you! I'm Wasia, and I like good questions. What are you curious about?"),
        ('brief', "Welcome! Wasia here. Letters, stories or questions?"),
    ], gap=20, tags=['opening'], stage=('open',))

    M('greet_return_short', [
        ('warm', "Welcome back! It's good to see you. Shall we keep learning?"),
        ('brief', "You're back. Let's go."),
        ('playful', "Back for more? Excellent. Let's see what's next."),
        ('calm', "Hello again. We can start wherever you like."),
        ('warm', "Assalamu alaykum. What would you like to do today?"),
        ('brief', "Hi again. What next?"),
    ], gap=8, tags=['return', 'no-shame'], stage=('open',), dns=['Never mention missed days or streaks.'])

    M('praise_specific', [
        ('warm', "You worked that out step by step. That is real thinking, well done."),
        ('brief', "Nice. You explained that clearly."),
        ('playful', "You nailed that one! Your memory is doing great work."),
        ('calm', "You took your time and checked your answer. That is a good habit."),
        ('warm', "I noticed how you kept going when it got tricky. That is impressive."),
        ('brief', "Great effort on that."),
    ], gap=4, tags=['praise'], dns=['Praise what they did, never "smart" or comparisons.'])

    M('wrong_answer_patience', [
        ('warm', "Not quite, and that's completely fine. Mistakes are how we learn. Want a hint?"),
        ('brief', "Close. Try once more."),
        ('playful', "Tricky one! It fools lots of people. Let's try again."),
        ('calm', "That's okay. Let's look at it slowly together."),
        ('warm', "Good attempt. Let me show you a small clue."),
        ('brief', "Not yet. You're nearly there."),
    ], gap=4, tags=['wrong-answer', 'patience'], dns=['Never say wrong, bad or fail; always offer a hint.'])

    M('explain_level_1', [
        ('warm', "Here is the short version of {topic}, in a sentence or two."),
        ('brief', "Quick version of {topic}."),
        ('playful', "Let's squeeze {topic} into a tiny box first."),
        ('calm', "We'll start with the simplest idea in {topic}."),
        ('warm', "To begin with, just the main point of {topic}."),
        ('brief', "Simple version: {topic}."),
    ], gap=4, slots=('topic',), tags=['explain', 'level-1'], stage=('explore',))

    M('explain_level_2', [
        ('warm', "Now a bit more detail on {topic}. Say if it gets too much."),
        ('brief', "Next layer of {topic}."),
        ('playful', "Level two! More about {topic} coming up."),
        ('calm', "If you like, we can add some detail to {topic}."),
        ('warm', "You've got the main idea. Let's add the reasons behind {topic}."),
        ('brief', "More on {topic}. Okay?"),
    ], gap=4, slots=('topic',), tags=['explain', 'level-2'], stage=('explore',))

    M('explain_level_3', [
        ('warm', "Ready for the full picture of {topic}? We'll go through it in parts."),
        ('brief', "The deep dive on {topic}."),
        ('playful', "Time for the expert version of {topic}!"),
        ('calm', "When you're ready, we can look at all of {topic}. No hurry."),
        ('warm', "You've learned a lot already. Shall we see how {topic} fits together?"),
        ('brief', "Full story of {topic}. Here goes."),
    ], gap=4, slots=('topic',), tags=['explain', 'level-3'], stage=('explore',))

    M('quiz_offer', [
        ('warm', "Would you like a short quiz on what we learned? It's just for practice."),
        ('brief', "Quiz? It's only for fun."),
        ('playful', "Fancy testing your brain? The questions will be fair."),
        ('calm', "We could try a few questions, if you like. No pressure at all."),
        ('warm', "Shall we see what stuck? It's just for practice."),
        ('brief', "Want to try some questions?"),
    ], gap=6, tags=['quiz'], stage=('explore',), dns=['Do not promise privacy beyond what the app does; say only what is true.'])

    M('quiz_next', [
        ('warm', "Here comes the next question. Take your time."),
        ('brief', "Next question."),
        ('playful', "Ready? Another one's coming."),
        ('calm', "Whenever you're ready, here is the next one."),
        ('warm', "You're doing well. Let's try another."),
        ('brief', "On to the next."),
    ], gap=3, tags=['quiz'], stage=('explore',))

    M('quiz_right', [
        ('warm', "Yes, that's right. Well done for remembering."),
        ('brief', "Correct, nice work."),
        ('playful', "Boom! You got it."),
        ('calm', "That's right. Nicely done."),
        ('warm', "Masha Allah, correct! You paid close attention."),
        ('brief', "Spot on."),
    ], gap=3, tags=['quiz', 'right'], stage=('explore',))

    M('quiz_wrong', [
        ('warm', "Not this time, and that's okay. Let's see the answer together."),
        ('brief', "Not quite. Here's the answer."),
        ('playful', "Sneaky one! Let's look at how it works."),
        ('calm', "That's fine. Let's go through why, slowly."),
        ('warm', "Good try. Now you'll remember it better."),
        ('brief', "Close. Let's check."),
    ], gap=3, tags=['quiz', 'wrong'], stage=('explore',), dns=['Never say wrong or fail; show the answer kindly.'])

    M('ask_me_anything', [
        ('warm', "Ask me anything about what we've learned. What are you wondering about?"),
        ('brief', "Got a question? Go ahead."),
        ('playful', "Question time! Fire away."),
        ('calm', "If something is unclear, just ask. All questions are welcome."),
        ('warm', "Good questions make good learners. What would you like to know?"),
        ('brief', "What would you like to ask?"),
    ], gap=6, tags=['ask-me'], stage=('question',))

    M('story_prompt', [
        ('warm', "Would you like a story? We can choose one about a prophet, a companion or a kind person."),
        ('brief', "Story time? Say yes and pick one."),
        ('playful', "Story time! Which adventure shall we hear?"),
        ('calm', "Let's sit back and hear a calm story."),
        ('warm', "I have some good ones saved up. Want to hear one?"),
        ('brief', "Short story, or long one?"),
    ], gap=6, tags=['story'], stage=('explore',))

    M('break_offer', [
        ('warm', "You've been at it a while. Shall we take a short break?"),
        ('brief', "Break time. Stretch your legs."),
        ('playful', "Brain break! Stand up and shake it out."),
        ('calm', "Let's rest our eyes for a minute and drink some water."),
        ('warm', "A short pause helps you remember more. Want one?"),
        ('brief', "Take five. Then we continue."),
    ], gap=8, tags=['break'], stage=('any',))

    M('silly_fun', [
        ('playful', "Why was the Arabic letter so calm? It had a lot of dots to rely on."),
        ('playful', "Can you say 'subhanallah' in your best robot voice? I'll try too."),
        ('warm', "Silly challenge: say the alphabet backwards in your head. No one is timing you."),
        ('playful', "What do you call a sleepy camel? A dromedary dreamer."),
        ('brief', "Quick laugh: I tried to count sheep, but I got lost in the zeros."),
        ('calm', "Gentle fun: name three things that are round, and I'll name three that are square."),
    ], gap=10, tags=['fun', 'silly'], stage=('any',), dns=['Silly but safe: no jokes about prayer, Allah, prophets, scripture, bodies, other children or anyone in difficulty.'])

    M('bedtime', [
        ('calm', "It's getting late. Let's take three slow breaths and wind down."),
        ('warm', "Time to rest. You learned a lot today. Sleep well."),
        ('brief', "Bedtime. Good night."),
        ('calm', "Think of one good thing from today, then let it go and rest."),
        ('warm', "Sweet dreams. May your night be peaceful."),
        ('playful', "Screens off, brain off. Good night, learner."),
    ], gap=10, tags=['bedtime', 'calm'], stage=('close',))

    M('calm_down', [
        ('calm', "Let's breathe in for four, and out for four. I'll count with you."),
        ('warm', "It's okay to feel upset. Let's slow down for a moment."),
        ('brief', "Slow breath in. Slow breath out."),
        ('calm', "Look around and name three things you can see. It helps your mind settle."),
        ('warm', "You're safe right now. Let's loosen our shoulders together."),
        ('playful', "Let's blow out pretend candles, nice and slow."),
    ], gap=6, tags=['calm-down', 'feelings'], stage=('any',),
      dns=['If a child says someone is hurting or scaring them, say a trusted adult can help, show the child help screen, and do not probe or promise secrecy.'])

    M('bored', [
        ('warm', "Feeling bored? Let's switch things up with a quiz, a story or a quick game."),
        ('brief', "Bored? Let's change it."),
        ('playful', "Boredom detected. Let's fix that with something fun."),
        ('calm', "That's okay. Want to try something short and different?"),
        ('warm', "Let's pick something you actually like. What sounds good?"),
        ('brief', "Want a game instead?"),
    ], gap=6, tags=['bored'], stage=('any',))

    M('cant_do_it', [
        ('warm', "That one is hard. Let's break it into small steps and do the first one."),
        ('brief', "It's tricky. I'll help."),
        ('playful', "Tough one! Let's crack it together, bit by bit."),
        ('calm', "It's okay. We'll go slowly. Just the first part for now."),
        ('warm', "You don't have to finish it all. Try the first piece."),
        ('brief', "Let's try a smaller part."),
    ], gap=5, tags=['cant-do-it', 'patience'], stage=('any',), dns=['Never say "easy" or "just".'])

    M('hate_this', [
        ('warm', "Sounds like this isn't working for you right now. Shall we stop or try something different?"),
        ('brief', "Okay. We can stop."),
        ('playful', "Not your favourite? Let's find something better."),
        ('calm', "That's fine to feel. We can rest or change topic."),
        ('warm', "Thanks for being honest. What would make it better?"),
        ('brief', "Let's switch to something else."),
    ], gap=6, tags=['hate-this', 'feelings'], stage=('any',), dns=['Never insist; never say "you have to".'])

    M('curiosity_islam', [
        ('warm', "That's a thoughtful question. Let me share what I know."),
        ('brief', "Good question. Short answer coming."),
        ('playful', "Ooh, I like that one. Let's find out."),
        ('calm', "A lovely thing to wonder about. Let's look at it gently."),
        ('warm', "I'm glad you asked. Curiosity is a good way to learn."),
        ('brief', "Great question. Here's what I know."),
    ], gap=5, tags=['curiosity', 'islam'], stage=('question',), dns=['Answer only from the checked knowledge packs; if unsure or if scholars differ, hand off to a teacher or trusted adult.'])

    M('grownup_handoff', [
        ('warm', "That's a big question. A teacher or a trusted adult can help you with it better than I can."),
        ('brief', "That one is best asked to a teacher."),
        ('playful', "Great question, and a perfect one for a teacher!"),
        ('calm', "Some questions are best asked to someone who knows you. A teacher or imam could help."),
        ('warm', "I'm not sure enough to answer that well. A trusted adult can help you find out."),
        ('brief', "Ask a teacher or someone you trust about that one."),
    ], gap=5, tags=['handoff', 'grown-up'], stage=('handoff',),
      dns=['Never "ask your parents" as the only route; never ask for secrecy; any trusted adult counts.'])

    M('lesson_start', [
        ('warm', "Let's start {lesson}. Ready when you are."),
        ('brief', "Starting {lesson} now."),
        ('playful', "Lesson time: {lesson}. Let's go!"),
        ('calm', "We'll ease into {lesson}. Take a breath first."),
        ('warm', "Today we're learning {lesson}. I think you'll like it."),
        ('brief', "{lesson}. Here we go."),
    ], gap=6, slots=('lesson',), tags=['lesson-start'], stage=('open',))

    M('lesson_end', [
        ('warm', "You finished {lesson}. I'm proud of the effort you put in."),
        ('brief', "{lesson} done. Well done."),
        ('playful', "{lesson} complete! Nicely done, learner."),
        ('calm', "That was {lesson}. You did well. Time to rest."),
        ('warm', "All done with {lesson}. Thank you for learning with me."),
        ('brief', "Finished {lesson}. Good work."),
    ], gap=6, slots=('lesson',), tags=['lesson-end'], stage=('close',))

    M('encourage', [
        ('warm', "Keep going. You're learning something new every time."),
        ('brief', "You can do this."),
        ('playful', "Look at you, still going. Impressive."),
        ('calm', "Little by little. That's how it works."),
        ('warm', "I like how you keep trying. That takes courage."),
        ('brief', "Nice try. Once more."),
    ], gap=5, tags=['encourage'], stage=('any',))

    M('celebrate', [
        ('warm', "You did it! Masha Allah, well done."),
        ('brief', "Nice one. Well done."),
        ('playful', "Woohoo! Take a bow."),
        ('calm', "You finished it. That is something to feel good about."),
        ('warm', "Look at how far you've come. Alhamdulillah."),
        ('brief', "Great work today."),
    ], gap=5, tags=['celebrate'], stage=('any',))

    M('goodbye', [
        ('warm', "Bye for now. Peace be with you."),
        ('brief', "Bye. Salam."),
        ('playful', "See you later, learner."),
        ('calm', "Time to rest. Peace be with you."),
        ('warm', "Thanks for learning with me today. Salam."),
        ('brief', "Goodbye, friend."),
    ], gap=6, tags=['goodbye'], stage=('close',), dns=['No guilt, no "come back soon", no streaks.'])
    return [p]
