#!/usr/bin/env python3
"""Hadi's learning pipeline: turns questions that two or more different people
asked and the library could not answer into checked answers in the content pack
assets/qa/hadi_learned.json (installed with no app release, via Content Sync).

Modelled on Noor's brain: nothing is trusted because a model said it. A
candidate answer is installed only if EVERY deterministic gate passes, else it
goes to docs/hadi_learning_queue.json with the reasons, for a person.

Gates (all must pass):
  G1 evidence    asked by at least MIN_USERS different anonymous users
  G2 grounding   at least one Qur'an reference, every one exists in the bundled
                 Saheeh text, and the answer cites no reference that is not in
                 its own list; any text in double quotes must be a verbatim
                 piece of a cited verse (so a model cannot invent a quote)
  G3 no hadith   a hadith number is never auto-installed (needs a verdict from a
                 person); neither is a ruling word (halal, haram, must ...)
  G4 injection   no URL, no instruction to an assistant, no hidden characters
  G5 stable      no date, time-sensitive wording, personal data, or "earlier"
  G6 provenance  created_by and created are recorded; entries expire after
                 TTL_DAYS and leave the pack unless asked again (forgetting)

Usage:
  learn.py --misses misses.json [--answers answers.json] [--gen]
  misses.json   [{"q": "...", "uid": "<anonymous id>"}, ...]  (from Firestore)
  answers.json  {"<normalised question>": {"answer": "...", "refs": ["2:255"]}}
  --gen         ask the model once per qualifying question (needs GROQ_API_KEY);
                the model only drafts, the gates decide.
Without --answers or --gen nothing is installed and the queue lists what is
waiting for an answer.
"""
import argparse, datetime, hashlib, json, os, re, sys, urllib.request

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
PACK = os.path.join(ROOT, 'assets', 'qa', 'hadi_learned.json')
QUEUE = os.path.join(ROOT, 'docs', 'hadi_learning_queue.json')
QURAN = os.path.join(ROOT, 'assets', 'quran', 'quran.json')
VERSIONS = os.path.join(ROOT, 'assets', 'content_version.json')
PACK_KEY = 'qa/hadi_learned.json'

MIN_USERS = 2
TTL_DAYS = 90
MAX_ANSWER = 900
MAX_ENTRIES = 300
NOTE = ('Learned from questions people asked and checked against the Qur’an '
        'text in the app. Scholar review needed.')

RULING = re.compile(r'\b(?:halal|haram|forbidden|prohibited|permissible|impermissible|'
                    r'lawful|unlawful|obligatory|compulsory|fatwa|ruling|sinful|sin|'
                    r'must|invalid|valid|allowed|not allowed|bida)\b', re.I)
INJECT = re.compile(r'https?://|www\.|ignore (?:all|previous|the above)|system prompt|'
                    r'as an ai|you are (?:now|a)|assistant:|<[a-z/]|\[GO:|\[DO:', re.I)
UNSTABLE = re.compile(r'\b(?:today|tonight|tomorrow|yesterday|this (?:week|month|year)|'
                      r'currently|right now|latest|recent(?:ly)?|20\d\d|earlier|'
                      r'as i said|you asked)\b', re.I)
PERSONAL = re.compile(r'[\w.+-]+@[\w-]+\.\w+|\b\d{6,}\b')
HADITH = re.compile(r'\b(?:bukhari|muslim|tirmidhi|abu dawud|nasa.?i|ibn majah|sunan|'
                    r'sahih|hadith)\b', re.I)
CRISIS = re.compile(r'\b(?:suicid\w*|kill (?:my|him|her|them)self|self.?harm|abus\w+|'
                    r'rape\w*|overdose|want to die|end my life|hurt myself)\b', re.I)
REF = re.compile(r"(?:Qur.an|Quran)\s+(\d{1,3}):(\d{1,3})(?:-(\d{1,3}))?", re.I)


def normalise(q):
    """Same as normaliseQuestion in lib/features/hadi/data/hosted_cache.dart."""
    s = q.lower()
    s = re.sub(r'[^\w\s]', ' ', s, flags=re.U).replace('_', ' ')
    s = re.sub(r'\s+', ' ', s).strip()
    s = re.sub(r'^(?:(?:please|hadi|salam|salaam|assalamu alaikum|tell me|can you tell me|'
               r'i want to know|i would like to know)\s+)+', '', s)
    return s[:200]


def load_quran():
    d = json.load(open(QURAN, encoding='utf-8'))
    return {(s['n'], v[0]): v[2] for s in d for v in s['v']}


def strip_marks(t):
    return re.sub(r'[^a-z0-9]+', ' ', t.lower()).strip()


def gates(answer, refs, quran):
    """Returns a list of failure reasons (empty = installable)."""
    why = []
    if not answer or len(answer) > MAX_ANSWER:
        why.append('G5 answer empty or over %d characters' % MAX_ANSWER)
        return why
    if INJECT.search(answer) or any(ord(c) in (0x200b, 0x200e, 0x200f, 0x202e) for c in answer):
        why.append('G4 looks like an instruction, link or hidden text')
    if UNSTABLE.search(answer) or PERSONAL.search(answer):
        why.append('G5 time-sensitive or personal wording')
    if HADITH.search(answer):
        why.append('G3 mentions a hadith: a person must verify it')
    if RULING.search(answer):
        why.append('G3 contains a ruling word: a person must review it')
    if not refs:
        why.append('G2 no Qur’an reference')
    texts = []
    for r in refs:
        m = re.fullmatch(r'(\d{1,3}):(\d{1,3})', r)
        if not m or (int(m.group(1)), int(m.group(2))) not in quran:
            why.append('G2 reference %s does not exist' % r)
        else:
            texts.append(strip_marks(quran[(int(m.group(1)), int(m.group(2)))]))
    cited = set()
    for m in REF.finditer(answer):
        a, b = int(m.group(1)), int(m.group(2))
        end = int(m.group(3) or b)
        for v in range(b, end + 1):
            cited.add('%d:%d' % (a, v))
    for c in cited:
        if c not in refs:
            why.append('G2 cites %s but it is not in the reference list' % c)
    for quoted in re.findall(r'"([^"]{6,})"|“([^”]{6,})”', answer):
        q = strip_marks(''.join(quoted))
        if q and not any(q in t for t in texts):
            why.append('G2 a quotation is not a verbatim piece of a cited verse')
    return why


def aggregate(misses):
    seen = {}
    for m in misses:
        q = (m.get('q') or '').strip()
        if CRISIS.search(q) or len(q) < 6:
            continue
        key = normalise(q)
        if len(key.split()) < 3:
            continue
        seen.setdefault(key, set()).add(str(m.get('uid', '')))
    return {k: len(v) for k, v in seen.items()}


def draft_with_model(question, quran):
    """One model call per qualifying question. The model drafts; gates decide."""
    key = os.environ.get('GROQ_API_KEY')
    if not key:
        return None
    prompt = (
        'You answer a question about Islam for a careful app. Use ONLY the Qur’an. '
        'Reply as JSON {"answer": "...", "refs": ["2:255"]}. Under 120 words, plain words. '
        'Cite each verse in the text as "Qur’an 2:255". Do not give rulings, do not '
        'mention hadith, do not give dates. If you cannot answer from the Qur’an alone, '
        'reply {"answer": "", "refs": []}.\nQuestion: ' + question)
    body = json.dumps({'model': 'llama-3.3-70b-versatile', 'temperature': 0,
                       'response_format': {'type': 'json_object'},
                       'messages': [{'role': 'user', 'content': prompt}]}).encode()
    req = urllib.request.Request('https://api.groq.com/openai/v1/chat/completions', body,
                                 {'Authorization': 'Bearer ' + key, 'Content-Type': 'application/json'})
    try:
        out = json.load(urllib.request.urlopen(req, timeout=60))
        return json.loads(out['choices'][0]['message']['content'])
    except Exception as e:  # a failed draft is simply not installed
        print('model draft failed:', e, file=sys.stderr)
        return None


def run(misses, answers, gen, today=None):
    today = today or datetime.date.today()
    quran = load_quran()
    pack = json.load(open(PACK, encoding='utf-8')) if os.path.exists(PACK) else {'schema': 1, 'entries': []}
    entries = pack.get('entries', [])
    # forgetting: expired entries leave
    live = [e for e in entries if e.get('expires', '9999') >= today.isoformat()]
    dropped = len(entries) - len(live)
    have = {k for e in live for k in e['keys']}
    counts = aggregate(misses)
    queue, added = [], 0
    for key, n in sorted(counts.items(), key=lambda kv: -kv[1]):
        if key in have:
            continue
        if n < MIN_USERS:
            continue  # G1: not asked by enough different people yet
        cand = answers.get(key)
        if cand is None and gen:
            cand = draft_with_model(key, quran)
        if cand is None:
            queue.append({'q': key, 'users': n, 'status': 'waiting for an answer'})
            continue
        ans = (cand.get('answer') or '').strip()
        refs = [str(r) for r in cand.get('refs', [])]
        why = gates(ans, refs, quran)
        if why:
            queue.append({'q': key, 'users': n, 'status': 'held', 'why': why, 'draft': ans[:300]})
            continue
        if len(live) >= MAX_ENTRIES:
            queue.append({'q': key, 'users': n, 'status': 'pack full'})
            continue
        live.append({
            'id': 'l-' + hashlib.sha256(key.encode()).hexdigest()[:10],
            'keys': [key], 'answer': ans + '\n\n' + NOTE, 'refs': refs,
            'created': today.isoformat(),
            'expires': (today + datetime.timedelta(days=TTL_DAYS)).isoformat(),
            'created_by': 'model:groq' if not answers.get(key) else 'answers-file',
        })
        added += 1
    return {'schema': 1, 'entries': live}, queue, added, dropped, pack


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--misses', required=True)
    ap.add_argument('--answers')
    ap.add_argument('--gen', action='store_true')
    a = ap.parse_args()
    misses = json.load(open(a.misses, encoding='utf-8'))
    answers = json.load(open(a.answers, encoding='utf-8')) if a.answers else {}
    new, queue, added, dropped, old = run(misses, answers, a.gen)
    os.makedirs(os.path.dirname(PACK), exist_ok=True)
    if new != old:
        json.dump(new, open(PACK, 'w', encoding='utf-8'), indent=1, ensure_ascii=False, sort_keys=True)
        open(PACK, 'a').write('\n')
        v = json.load(open(VERSIONS))
        v[PACK_KEY] = int(v.get(PACK_KEY, 0)) + 1
        json.dump(v, open(VERSIONS, 'w'), indent=2)
        open(VERSIONS, 'a').write('\n')
    json.dump({'queue': queue}, open(QUEUE, 'w', encoding='utf-8'), indent=1, ensure_ascii=False)
    open(QUEUE, 'a').write('\n')
    print('installed %d, expired %d, in queue %d' % (added, dropped, len(queue)))


if __name__ == '__main__':
    main()
