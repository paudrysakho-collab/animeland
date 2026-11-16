# Applique un fichier de consignes JSON {chemin: [[ancien, nouveau], ...]} au depot (toutes les occurrences),
# remet les fins de ligne en LF et affiche la somme Adler « taille:somme » de chaque fichier (a comparer avec Studio).
# Usage : python appliquer.py consignes.json [--sommes-seulement]
import json, sys, os
RACINE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "roblox", "src")


def adler(b):
    a, s = 1, 0
    for x in b:
        a = (a + x) % 65521
        s = (s + a) % 65521
    return "%d:%d" % (len(b), (s << 16) | a)


cons = json.load(open(sys.argv[1], encoding="utf-8"))
for chemin, reps in cons.items():
    f = os.path.join(RACINE, chemin)
    t = open(f, encoding="utf-8", newline="").read().replace("\r\n", "\n")
    if "--sommes-seulement" not in sys.argv:
        for old, new in reps:
            n = t.count(old)
            if n == 0:
                raise SystemExit("INTROUVABLE dans %s : %r" % (chemin, old[:80]))
            t = t.replace(old, new)
        open(f, "w", encoding="utf-8", newline="").write(t)
    print(chemin, adler(t.encode("utf-8")))
