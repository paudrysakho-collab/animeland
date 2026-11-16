# Verifie une animation faite main (images 03_retarget/<nom>_frames.json), repere Roblox du HRP (avant = -Z, droite = +X).
# blender -b --python verif_anim.py -- nom [nom ...]
# Signale : mains / avant-bras / pieds DANS le corps (torse, bassin, tete), pieds sous le sol (> 0,2 stud), jambes croisees,
# lame dans le corps (prise commune) ; affiche la trajectoire de la pointe (forme du coup) et le deplacement de la racine.
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mathutils import Matrix, Vector
from anim_lib import BASE, RIGS, T, BLADE_LOCAL

argv = sys.argv[sys.argv.index("--") + 1:]
BODY = ["UpperTorso", "LowerTorso", "Head"]
MEMBRES = ["RightHand", "LeftHand", "RightLowerArm", "LeftLowerArm"]


def fk(rig, f):
    W = {"HumanoidRootPart": Matrix.Identity(4)}
    for m in rig["motors"]:
        d = f["motors"][m["name"]]
        r = d["rot"]
        R = Matrix(((r[0], r[1], r[2], d["pos"][0]), (r[3], r[4], r[5], d["pos"][1]), (r[6], r[7], r[8], d["pos"][2]), (0, 0, 0, 1)))
        W[m["part1"]] = W[m["part0"]] @ T(m["c0_pos"]) @ R @ T(m["c1_pos"]).inverted()
    return W


for nom in argv:
    F = json.load(open(os.path.join(BASE, "03_retarget", nom + "_frames.json"), encoding="utf-8"))
    rig = json.load(open(RIGS[F["rig"]], encoding="utf-8"))
    sizes = {p["name"]: Vector(p["size"]) for p in rig["parts"]} if "parts" in rig and isinstance(rig["parts"], list) else \
        {k: Vector(v["size"]) for k, v in rig["parts"].items()}
    pb = []
    sol0 = None
    pointes = []
    for f in F["frames"]:
        W = fk(rig, f)
        t = f["time"]
        inv = {p: W[p].inverted() for p in BODY}
        # membres dans le corps (centre du membre dans la boite du torse / bassin / tete, reduite de 10 %)
        for mb in MEMBRES:
            c = W[mb].translation
            for p in BODY:
                loc = inv[p] @ c
                h = sizes[p] / 2 * 0.9
                if abs(loc.x) < h.x and abs(loc.y) < h.y and abs(loc.z) < h.z:
                    pb.append("t=%.2f %s dans %s" % (t, mb, p))
        # lame dans le corps (11 points de la garde a la pointe)
        H = W["RightHand"]
        dirl = H.to_3x3() @ BLADE_LOCAL
        for k in range(11):
            pt = H.translation + dirl * (0.55 + 3.2 * k / 10)
            for p in BODY:
                loc = inv[p] @ pt
                h = sizes[p] / 2
                if abs(loc.x) < h.x and abs(loc.y) < h.y and abs(loc.z) < h.z:
                    pb.append("t=%.2f lame dans %s (%.0f %% de la lame)" % (t, p, 100 * k / 10))
                    break
        pointes.append((t, H.translation + dirl * 3.75, W["LowerTorso"].translation))
        if sol0 is not None and (H.translation + dirl * 3.75).y < sol0 + 0.05:
            pb.append("t=%.2f pointe de la lame sous le sol de %.2f" % (t, sol0 + 0.05 - (H.translation + dirl * 3.75).y))
        # pieds : sol et croisement (dans le repere du bassin)
        pieds = [W["LeftFoot"].translation, W["RightFoot"].translation]
        bas = min(p.y for p in pieds) - 0.2
        if sol0 is None:
            sol0 = bas
        for nomp, p in zip(("pied gauche", "pied droit"), pieds):
            if p.y - 0.2 < sol0 - 0.2:
                pb.append("t=%.2f %s sous le sol de %.2f" % (t, nomp, sol0 - (p.y - 0.2)))
        lt = W["LowerTorso"].inverted()
        gx, dx = (lt @ pieds[0]).x, (lt @ pieds[1]).x
        if gx > dx - 0.15:
            pb.append("t=%.2f jambes croisees (gauche x=%.2f, droite x=%.2f)" % (t, gx, dx))
    # resume : on ne garde que la premiere et la derniere image de chaque probleme continu
    vus, resume = {}, []
    for ligne in pb:
        cle = ligne.split(" ", 1)[1].split(" (")[0].split(" de ")[0]
        vus.setdefault(cle, []).append(ligne.split(" ")[0])
    for cle, ts in vus.items():
        resume.append("%s : %s (%d images)" % (cle, ts[0] if len(ts) == 1 else ts[0] + " -> " + ts[-1], len(ts)))
    print("VERIF %s : %d images, %s" % (nom, len(F["frames"]), "AUCUN PROBLEME" if not resume else "%d problemes" % len(resume)))
    for r in resume:
        print("VERIF   " + r)
    marques = [m["t"] for m in F.get("markers", [])]
    for (t, p, lt) in pointes:
        if any(abs(t - x) < 0.017 for x in marques) or round(t * 30) % 3 == 0:
            print("VERIF   pointe t=%.2f (x=%5.2f y=%5.2f z=%5.2f)  bassin z=%5.2f" % (t, p.x, p.y, p.z, lt.z))
