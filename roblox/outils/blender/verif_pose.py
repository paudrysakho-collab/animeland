# Verifie par le calcul ou sont les membres a des temps donnes (repere Roblox du HRP : avant = -Z, droite = +X).
# blender -b --python verif_pose.py -- nom_anim piece t1 t2 ...
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mathutils import Matrix, Vector, Quaternion
from anim_lib import BASE, RIGS, T
argv = sys.argv[sys.argv.index("--") + 1:]
nom, piece, times = argv[0], argv[1], [float(x) for x in argv[2:]]
F = json.load(open(os.path.join(BASE, "03_retarget", nom + "_frames.json"), encoding="utf-8"))
rig = json.load(open(RIGS[F["rig"]], encoding="utf-8"))
for t in times:
    fr = min(F["frames"], key=lambda f: abs(f["time"] - t))
    W = {"HumanoidRootPart": Matrix.Identity(4)}
    for m in rig["motors"]:
        d = fr["motors"][m["name"]]
        r = d["rot"]
        R = Matrix(((r[0], r[1], r[2]), (r[3], r[4], r[5]), (r[6], r[7], r[8]))).to_4x4()
        tr = T(d["pos"]) @ R
        W[m["part1"]] = W[m["part0"]] @ T(m["c0_pos"]) @ tr @ T(m["c1_pos"]).inverted()
    p = W[piece].translation
    h = W["Head"].translation
    print("POSE t=%.2f %s=(%.2f, %.2f, %.2f) tete=(%.2f, %.2f, %.2f)" % (t, piece, p.x, p.y, p.z, h.x, h.y, h.z))
