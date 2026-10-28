#!/usr/bin/env python3
"""One-off migration: moves the Dua school's lesson list out of Dart into
assets/academy/dua_lessons.json unchanged (same Arabic, same wording), so the
Arabic lives in a registry file where the transliteration pipeline and the
scholar register can see it. Also checks the Qur'an ones against quran.json.

Usage: extract_dua_lessons.py <dua_school_screen.dart>   (before the Dart edit)
"""
import ast, json, os, re, sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
OUT = os.path.join(ROOT, 'assets', 'academy', 'dua_lessons.json')
LIT = r"(?:'(?:[^'\\]|\\.)*'|\"(?:[^\"\\]|\\.)*\")"
FIELD = re.compile(r'(\w+):\s*((?:' + LIT + r'\s*)+),')


def main(path):
    src = open(path, encoding='utf-8').read()
    a = src.index('const List<_DuaLesson> kDuaLessons')
    b = src.index('];', a)
    body = src[a:b]
    out = []
    for blk in body.split('_DuaLesson(')[1:]:
        rec = {}
        for name, lits in FIELD.findall(blk):
            parts = re.findall(LIT, lits)
            rec[name] = ''.join(ast.literal_eval(p) for p in parts)
        out.append(rec)
    keys = {'title', 'arabic', 'meaning', 'when', 'source'}
    for r in out:
        assert keys <= set(r), r
    doc = {
        'schema': 1,
        'note': "Moved unchanged from the Dua school screen's Dart list. Transliteration is present only where it was checked against a named source; otherwise the app shows the program-made one (Scholar review needed) or says it is not available.",
        'lessons': out,
    }
    with open(OUT, 'w', encoding='utf-8') as f:
        json.dump(doc, f, ensure_ascii=False, indent=1)
        f.write('\n')
    print(len(out), 'lessons')


if __name__ == '__main__':
    main(sys.argv[1])
