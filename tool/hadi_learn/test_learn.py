import sys, os, datetime
sys.path.insert(0, os.path.dirname(__file__))
import learn
Q = learn.load_quran()
ok = 0
def check(name, cond):
    global ok
    assert cond, name
    ok += 1

# normalise matches the app's rule
check('norm', learn.normalise('Please, tell me: What is Taqwa?!') == 'what is taqwa')
# G1 needs two different people
m = [{'q': 'What does the Quran say about patience in hardship', 'uid': 'a'},
     {'q': 'what does the quran say about patience in hardship?', 'uid': 'a'}]
check('one user twice is one', list(learn.aggregate(m).values()) == [1])
m.append({'q': 'what does the Quran say about patience in hardship', 'uid': 'b'})
check('two users', list(learn.aggregate(m).values()) == [2])
check('crisis dropped', learn.aggregate([{'q': 'I want to die and end my life', 'uid': 'x'}]) == {})
good = 'Patience is praised. Allah says in Qur’an 2:153 that He is with the patient.'
check('good answer passes', learn.gates(good, ['2:153'], Q) == [])
check('no refs fails', learn.gates('Patience is good.', [], Q))
check('fake ref fails', learn.gates('See Qur’an 2:999.', ['2:999'], Q))
check('uncited ref fails', learn.gates('See Qur’an 2:153 and Qur’an 2:155.', ['2:153'], Q))
check('hadith fails', learn.gates('The Prophet said in Bukhari 1 ... Qur’an 2:153', ['2:153'], Q))
check('ruling fails', learn.gates('This is haram. Qur’an 2:153', ['2:153'], Q))
check('link fails', learn.gates('See https://x.com Qur’an 2:153', ['2:153'], Q))
check('date fails', learn.gates('In 2024 Qur’an 2:153', ['2:153'], Q))
check('invented quote fails', learn.gates('Allah says "be very very happy always" (Qur’an 2:153)', ['2:153'], Q))
check('real quote passes', learn.gates('Allah says "Indeed, Allah is with the patient" (Qur’an 2:153)', ['2:153'], Q) == [])
# end to end with an answers file in a temp pack
import tempfile, json
learn.PACK = os.path.join(tempfile.mkdtemp(), 'p.json')
learn.QUEUE = learn.PACK + '.q'
key = 'what does the quran say about patience in hardship'
new, queue, added, dropped, _ = learn.run(m, {key: {'answer': good, 'refs': ['2:153']}}, False, datetime.date(2026, 11, 19))
check('installed', added == 1 and new['entries'][0]['expires'] == '2027-02-17')
check('review note', 'Scholar review needed' in new['entries'][0]['answer'])
json.dump(new, open(learn.PACK, 'w'))
new2, _, added2, dropped2, _ = learn.run(m, {}, False, datetime.date(2027, 3, 1))
check('forgotten after ttl', dropped2 == 1 and new2['entries'] == [])
_, queue, added, _, _ = learn.run(m[:2], {}, False)
check('one user: not asked yet', added == 0 and queue == [])
print('learn.py: %d checks ok' % ok)
