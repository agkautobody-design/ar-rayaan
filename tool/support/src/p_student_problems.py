from .lib import Pack
from .sources import H, Q, bg, clin, fq


def build():
    p = Pack('student_problems', 'support', 'student', 'both',
             'School-age problems: finding learning hard, bullying, worry and not wanting to go to school, and teen exposure to vaping, porn, gambling and alcohol. Child bands are short and safe; adult lines are for parents and teachers.',
             ages=('adult', '5-8', '9-12', '13-17'), base_tags=['student'])
    A = p.add
    AD = clin('who_adol')
    LD = bg('RES_H1 10.6', 'Learning difficulties, bullying and school refusal were not researched beyond the WHO adolescent page; clinician and safeguarding to supply sources and confirm.')

    # 5-8
    A('reflect', "That sounds hard. I'm glad you told me.", tags=['child', 'validation'], age=['5-8'], src=[AD, LD], ev='C')
    A('reflect', "School can feel big and scary sometimes.", tags=['child', 'school'], age=['5-8'], src=[AD, LD], ev='C')
    A('affirm', "You are trying, and that is brave.", tags=['child', 'effort'], age=['5-8'], src=[LD], ev='C')
    A('explain', "Everyone finds some things hard. Reading is hard for some kids, and maths is hard for others. A teacher can help you.", tags=['child', 'learning'], age=['5-8'], src=[LD], ev='C', trig=["i can't read", 'i am stupid'])
    A('explain', "It is not okay when someone is mean to you again and again. It is not your fault. Tell a teacher you trust.", tags=['child', 'bullying'], age=['5-8'], src=[LD, AD], ev='C', risk='medium', trig=['they are mean to me', 'nobody plays with me', 'hit me at school'])
    A('plan-step', "Let's take one small step. Which grown-up at school feels kind to you?", tags=['child', 'trusted-adult'], age=['5-8'], src=[LD], ev='C', ask=True)

    # 9-12
    A('reflect', "That sounds really hard. Thank you for telling me.", tags=['child', 'validation'], age=['9-12'], src=[AD, LD], ev='C')
    A('reflect', "It sounds like school is making you feel worried or sad.", tags=['child', 'school'], age=['9-12'], src=[AD, LD], ev='C')
    A('reflect', "It sounds like you feel left out.", tags=['child', 'bullying'], age=['9-12'], src=[AD, LD], ev='C')
    A('ask', "What is the hardest part of school right now?", tags=['child', 'explore'], age=['9-12'], src=[LD], ev='C')
    A('ask', "Is there a grown-up at school who you feel safe with?", tags=['child', 'trusted-adult'], age=['9-12'], src=[LD], ev='C')
    A('explain', "Some people learn in different ways. Finding reading or maths hard does not mean you are not clever. A teacher can find the way that works for you.", tags=['child', 'learning'], age=['9-12'], src=[LD], ev='C', trig=["i'm stupid", "can't read", "can't do maths"])
    A('explain', "Being picked on again and again is bullying. It is never your fault. Telling a teacher or a trusted grown-up is the right thing to do.", tags=['child', 'bullying'], age=['9-12'], src=[LD, AD], ev='C', risk='medium', trig=['they pick on me', 'bullied', 'cyberbullying'])
    A('explain', "Feeling worried about school is common. Your tummy may hurt or your heart may race. A school nurse or doctor can help.", tags=['child', 'anxiety'], age=['9-12'], src=[LD], ev='C', trig=['stomach ache', 'scared to go to school', "don't want to go"])
    A('plan-step', "Here is a small step. Think of one kind grown-up you could tell, and one sentence to start with. Want to practise it together?", tags=['child', 'script'], age=['9-12'], src=[LD], ev='C', ask=True)
    A('safety', "If someone is hurting you or you feel unsafe, tell a teacher or a grown-up you trust right now. You can also call a children's helpline. It is free.", tags=['child', 'safety'], age=['9-12'], src=[LD, clin('childhelp')], risk='high', ev='C', fixed=True, trig=['he hits me', 'she threatens me', 'i am scared'])

    # 13-17
    A('reflect', "It sounds like a lot is going on at school.", tags=['teen', 'school'], age=['13-17'], src=[AD, LD], ev='C')
    A('reflect', "It sounds like you feel on your own with this.", tags=['teen', 'isolation'], age=['13-17'], src=[AD, LD], ev='C')
    A('reflect', "You want to do well, and the pressure is huge.", tags=['teen', 'pressure'], age=['13-17'], src=[AD, LD], ev='C')
    A('ask', "What would make school feel a bit easier right now?", tags=['teen', 'goal'], age=['13-17'], src=[LD], ev='C')
    A('ask', "Is there a teacher, counsellor or nurse you trust?", tags=['teen', 'trusted-adult'], age=['13-17'], src=[LD], ev='C')
    A('explain', "Finding it hard to read, focus or keep up does not mean you are not smart. A school can look at what's getting in the way and offer support. A doctor can help too.", tags=['teen', 'learning'], age=['13-17'], src=[LD], ev='C', trig=['cannot focus', 'dyslexia', 'adhd', 'cannot concentrate'], dns=['Never label or diagnose.'])
    A('explain', "Being bullied, in person or online, is never your fault. You can keep copies of messages, block the person and tell someone you trust. A school counsellor can help you decide what's next.", tags=['teen', 'bullying'], age=['13-17'], src=[LD, AD], ev='C', risk='medium', trig=['bullied', 'cyberbullying', 'screenshots', 'group chat'])
    A('explain', "Not wanting to go to school because of worry is common, and it can be helped. It's best not to avoid it for long, because it usually gets harder. A doctor or counsellor can help you plan a gentle return.", tags=['teen', 'school-refusal'], age=['13-17'], src=[LD, AD], ev='C', risk='medium', trig=['cannot go to school', 'school refusal', 'panic at school'])
    A('explain', "Vaping, alcohol, porn and betting are all around teens. Curiosity is normal, and the pressure is real. A doctor or school nurse can talk it through without judging you, and you can ask for it to stay private.", tags=['teen', 'exposure'], age=['13-17'], src=[AD, bg('RES_H1 10.6', 'Teen vaping, alcohol, porn and gambling: honest, non-shaming information; clinician to approve; local law needed.')], ev='C', risk='medium', trig=['vaping at school', 'everyone is drinking', 'saw porn', 'sports betting'])
    A('plan-step', "One small step: pick one person to tell and write down what you want to say. Want to practise it with me?", tags=['teen', 'script'], age=['13-17'], src=[LD], ev='C', ask=True)
    A('safety', "If someone is hurting you, or you feel unsafe or hopeless, please tell a trusted adult now and call a helpline or your emergency number. You deserve help.", tags=['teen', 'safety'], age=['13-17'], src=[LD, clin('who_suicide'), clin('childhelp')], risk='high', ev='C', fixed=True, trig=['want to die', 'hurt myself', 'he hurts me'], stage=['crisis'], dns=['Join with helplines.json scope child and suicide.'])

    # adults: parents and teachers
    A('orient', "I'm an app, not a school psychologist or a doctor. I can listen and help you work out who to talk to about your child or student. What's worrying you?", tags=['parent', 'teacher', 'opening'], src=[LD], ev='C')
    A('reflect', "It sounds like you're worried and want the best for them.", tags=['parent', 'validation'], src=[LD], ev='C')
    A('explain', "If a child is finding reading, writing, maths or focus hard, start with the teacher, then the school's support team, and a doctor if you have worries about health, hearing or vision. A label is not needed to ask for help.", tags=['parent', 'learning'], src=[LD], ev='C', trig=['my child cannot read', 'falling behind'], dns=['Do not suggest a diagnosis.'])
    A('explain', "If your child is being bullied, listen, stay calm, and thank them for telling you. Keep a record, and talk to the school. If they feel unsafe, take it seriously.", tags=['parent', 'bullying'], src=[LD, AD], ev='C', risk='medium', trig=['my son is being bullied', 'my daughter is bullied'])
    A('explain', "If a child refuses school, treat the worry as real and speak to the school and a doctor early. Long absence tends to make it harder, so small gentle steps work best.", tags=['parent', 'school-refusal'], src=[LD], ev='C', risk='medium', trig=['refuses to go to school', 'cries every morning'])
    A('explain', "If you find out your teen has been looking at porn, vaping or betting, stay calm. Shouting can drive it underground. Talk about it as a health and safety matter, and ask a doctor if you need help.", tags=['parent', 'teen', 'exposure'], src=[AD], ev='C', risk='medium', trig=['found porn on his phone', 'vape in her bag', 'betting app'], dns=['No spying or punishment advice; clinician to confirm.'])
    A('referral', "A school counsellor, the school nurse or a doctor can be the first stop. If safety is at risk, a child-protection service can advise. The lines for your country are listed below.", tags=['parent', 'teacher', 'helpline'], src=[LD], ev='C', fixed=True, dns=['Join with helplines.json scope child.'])

    A('islamic', "Allah is kind, and the Qur'an says that with hardship comes ease. Hard days at school do not last forever. You can talk to a grown-up or a teacher about it.", src=[Q('94:5-6', 'RES_H2 2.2')], tags=['child', 'ease'], age=['9-12'], trig=['allah does not love me', 'i am a bad student'])
    A('islamic', "The Prophet said the best of you are the best to their families, and told us to be gentle with children. Kindness matters at school, too. If you want to learn more, ask a teacher or a grown-up.", src=[H('tirmidhi:3895', 'RES_H2 5.3'), H('tirmidhi:1919', 'RES_H2 5.3')], tags=['child', 'kindness', 'bullying'], age=['13-17'], trig=['is it okay to fight back', 'revenge'])
    A('islamic', "The Prophet taught that mercy is for the young, and that no one who is not merciful will be shown mercy. Bullying is the opposite of that. Parents and teachers can protect a child without shame.", src=[H('tirmidhi:1922', 'RES_H2 5.3'), H('bukhari:5997', 'RES_H2 5.3')], tags=['parent', 'bullying', 'mercy'], trig=['they said it is the way to toughen'])
    A('summary', "What I've heard: school is hard right now, {topic} is part of it, and you want help. The next step is to tell a trusted grown-up.", tags=['child', 'summary'], age=['13-17'], slots=['topic'], src=[LD], ev='C')
    return [p]
