from .lib import Pack
from .sources import bg


def build():
    p = Pack('checkin', 'support', 'checkin', 'both',
             'Gentle check-in lines after about two weeks, or after a gap: three tones, four age bands. No shaming for absence, no streaks, one open question, easy to ignore.',
             ages=('adult', '13-17', '9-12', '5-8'), base_tags=['checkin'])
    A = p.add
    CI = bg('RES_H3', 'Check-in design from the Hadi companion design brief: optional, never pushy, never a streak; no clinical claim.')

    def add(en, tone, age, tags=(), slots=(), tr=None, trig=()):
        A('checkin', en, tone=tone, age=[age], stage=['checkin'], tags=['checkin', age] + list(tags), slots=slots, src=[CI], ev='X', code='checkin-' + age.replace('_', '-'), tr=tr, trig=trig)

    # adult warm
    add("It's been a little while. No pressure at all. How have you been?", 'warm', 'adult', ['gap'])
    add("Hello again. I was thinking of you. How are things going for you?", 'warm', 'adult', ['gap'])
    add("It's been about {days_away} days since we spoke. I'm glad to see you. How are you doing?", 'warm', 'adult', ['gap', 'days'], slots=['days_away'])
    add("Welcome back. There's no need to explain where you've been. What's on your mind today?", 'warm', 'adult', ['gap', 'no-shame'])
    add("Good to see you. If today has been a hard one, we can start there. How are you?", 'warm', 'adult', ['gap'])
    add("I hope the last couple of weeks have been kind to you. How have they been?", 'warm', 'adult', ['gap'])
    # adult brief
    add("Checking in. How are you doing?", 'brief', 'adult', ['gap'])
    add("It's been a while. How have things been?", 'brief', 'adult', ['gap'])
    add("Hello. How's it going?", 'brief', 'adult', ['gap'])
    add("A quick hello. How are you today?", 'brief', 'adult', ['gap'])
    add("Welcome back. How are you?", 'brief', 'adult', ['gap'])
    add("Thinking of you. How are things?", 'brief', 'adult', ['gap'])
    # adult formal
    add("Peace be with you. I wanted to check in after some time. How have you been?", 'formal', 'adult', ['gap', 'salam'])
    add("Good day. It has been {days_away} days since we last spoke. How are you keeping?", 'formal', 'adult', ['gap', 'days'], slots=['days_away'])
    add("Welcome back. I hope you are well. Is there anything you would like to talk about today?", 'formal', 'adult', ['gap'])
    add("I am glad you are here. How have things been since we last spoke?", 'formal', 'adult', ['gap'])
    add("It is good to hear from you again. How have you been?", 'formal', 'adult', ['gap'])
    add("Greetings. I hope this finds you well. What would you like to talk about?", 'formal', 'adult', ['gap'])
    # teen
    add("Hey. It's been a bit. How have things been going?", 'warm', '13-17', ['gap'])
    add("Good to see you again. No need to explain anything. How are you doing?", 'warm', '13-17', ['gap', 'no-shame'])
    add("Hi. Just checking in. How's it going?", 'brief', '13-17', ['gap'])
    add("Welcome back. How are you today?", 'brief', '13-17', ['gap'])
    add("Hello. I hope you've been well. How have you been?", 'formal', '13-17', ['gap'])
    add("Welcome back. Is there anything you'd like to talk about?", 'formal', '13-17', ['gap'])
    # 9-12
    add("Hi! Good to see you again. How have you been?", 'warm', '9-12', ['gap'])
    add("I'm happy you're back. What's been going on?", 'warm', '9-12', ['gap'])
    add("Hello! How are you today?", 'brief', '9-12', ['gap'])
    add("Hi again. How's your week been?", 'brief', '9-12', ['gap'])
    add("Hello. I hope you are well. How are you?", 'formal', '9-12', ['gap'])
    add("Welcome back. What would you like to do today?", 'formal', '9-12', ['gap'])
    # 5-8
    add("Hello! I'm happy to see you. How are you?", 'warm', '5-8', ['gap'])
    add("Hi! What did you do today?", 'brief', '5-8', ['gap'])
    add("Hello. Welcome back. How are you?", 'formal', '5-8', ['gap'])
    return [p]
