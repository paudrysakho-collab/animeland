# Etape 4 - Donnees de lame pour un lot d'attaques (Blender 4.5, -b ; seul mathutils est utilise)
# Usage : blender -b --python blade_data.py -- <nom1> <nom2> ...
#   (noms = fichiers 03_retarget/<nom>_R15_frames.json ; sans argument : tous les attack/slash/kick/bash)
#
# Espace : HumanoidRootPart, Roblox (Y haut, perso regarde -Z), studs. FK : Part1 = Part0*C0*Transform*C1^-1.
# Epee : poignee 0.8, garde 0.15, lame 3.2 (largeur 0.25, epaisseur 0.08). Repere epee : origine au centre
#   de la poignee (= centre de RightHand), +Y vers la pointe, +X = largeur de lame, +Z = epaisseur.
# Prises testees (la poignee traverse le poing selon l'axe Z de la main ; pouce = -Z bras le long du corps) :
#   cote pouce / cote auriculaire  x  lame perpendiculaire a la paume / dans le plan de la paume.
# grip_offset = CFrame du repere epee dans RightHand (Weld.C0 ; Handle = Part1, C1 = identite).
import sys, os, json, math, glob
from mathutils import Matrix, Vector

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RIG = json.load(open(os.path.join(BASE, "02_extraction", "r15_rig.json"), encoding="utf-8"))
RET = os.path.join(BASE, "03_retarget")
OUT = os.path.join(BASE, "04_roblox")
LOGS = os.path.join(BASE, "logs")
os.makedirs(OUT, exist_ok=True)

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
NAMES = argv or sorted(os.path.basename(p)[:-len("_R15_frames.json")]
                       for p in glob.glob(os.path.join(RET, "*_R15_frames.json"))
                       if any(k in os.path.basename(p) for k in ("attack", "slash", "kick", "bash"))
                       and os.path.basename(p).startswith("sword_and_shield_"))

HANDLE, GUARD, BLADE, WIDTH = 0.8, 0.15, 3.2, 0.25
Y_BASE = HANDLE / 2 + GUARD
Y_TIP = Y_BASE + BLADE
Y_MID = (Y_BASE + Y_TIP) / 2
NS = 24
BODY = ["UpperTorso", "LowerTorso", "Head"]
sizes = {p["name"]: Vector(p["size"]) for p in RIG["parts"]}
motors = RIG["motors"]

GRIPS = [  # (nom, base autour de X, roulis autour de l'axe de la lame)
    ("pouce / lame perpendiculaire a la paume", -90, 0),
    ("pouce / lame dans le plan de la paume", -90, 90),
    ("auriculaire / lame perpendiculaire a la paume", 90, 0),
    ("auriculaire / lame dans le plan de la paume", 90, 90),
]


def grip(base_deg, roll_deg, ax=0, az=0):
    return (Matrix.Rotation(math.radians(az), 4, "Z") @ Matrix.Rotation(math.radians(base_deg + ax), 4, "X")
            @ Matrix.Rotation(math.radians(roll_deg), 4, "Y"))


def T(v):
    return Matrix.Translation(Vector(v))


def load(name):
    fr = json.load(open(os.path.join(RET, name + "_R15_frames.json"), encoding="utf-8"))
    WS = []
    for f in fr["frames"]:
        W = {"HumanoidRootPart": Matrix.Identity(4)}
        for m in motors:
            d = f["motors"][m["name"]]
            r = d["rot"]
            tr = Matrix(((r[0], r[1], r[2], d["pos"][0]), (r[3], r[4], r[5], d["pos"][1]),
                         (r[6], r[7], r[8], d["pos"][2]), (0, 0, 0, 1)))
            W[m["part1"]] = W[m["part0"]] @ T(m["c0_pos"]) @ tr @ T(m["c1_pos"]).inverted()
        WS.append(W)
    inv = [{p: W[p].inverted() for p in BODY} for W in WS]
    return {"name": name, "raw": fr, "WS": WS, "inv": inv, "times": [f["time"] for f in fr["frames"]],
            "frames": [f["frame"] for f in fr["frames"]]}


def runs(idx):
    out, cur = [], []
    for i in idx:
        if cur and i != cur[-1] + 1:
            out.append(cur); cur = []
        cur.append(i)
    if cur:
        out.append(cur)
    return out


def evaluate(A, G):
    WS, inv, times = A["WS"], A["inv"], A["times"]
    n = len(WS)
    base, mid, tip, clip = [], [], [], []
    for i, W in enumerate(WS):
        H = W["RightHand"] @ G
        b, m_, t = H @ Vector((0, Y_BASE, 0)), H @ Vector((0, Y_MID, 0)), H @ Vector((0, Y_TIP, 0))
        base.append(b); mid.append(m_); tip.append(t)
        side = (H.to_3x3() @ Vector((1, 0, 0))) * (WIDTH / 2)
        depth, hit = 0.0, set()
        for off in (-side, Vector((0, 0, 0)), side):
            for k in range(NS + 1):
                p = b.lerp(t, k / NS) + off
                for part in BODY:
                    loc = inv[i][part] @ p
                    h = sizes[part] / 2
                    d = min(h.x - abs(loc.x), h.y - abs(loc.y), h.z - abs(loc.z))
                    if d > 0:
                        depth = max(depth, d); hit.add(part)
        if depth > 0:
            clip.append({"frame": A["frames"][i], "t": times[i], "depth": round(depth, 4), "parts": sorted(hit)})

    def spd(pts):
        s = []
        for i in range(n):
            a, c = max(0, i - 1), min(n - 1, i + 1)
            dt = times[c] - times[a]
            s.append((pts[c] - pts[a]).length / dt if dt > 0 else 0.0)
        return s
    smid, stip = spd(mid), spd(tip)
    vmax = max(smid)
    fast = [i for i in range(n) if smid[i] > 0.5 * vmax]
    front_pct = 100.0 * sum(1 for i in fast if tip[i].z < 0) / len(fast) if fast else 0.0
    cand = [i for i in fast if tip[i].z < 0]
    note = ""
    if cand:
        win = max(runs(cand), key=len)
    else:
        win = max(runs(fast), key=len)
        note = "pointe jamais devant le torse pendant la frappe : fenetre = vitesse seule"
    if len(win) < 3:
        win = list(range(max(0, win[0] - 1), min(n - 1, win[-1] + 1) + 1))
        note = (note + " ; " if note else "") + "fenetre elargie d'une image de chaque cote"
    return {"base": base, "mid": mid, "tip": tip, "clip": clip, "smid": smid, "stip": stip,
            "front_pct": front_pct, "win": win, "note": note, "vmax": vmax}


ANIMS = []
skipped = []
for nm in NAMES:
    try:
        ANIMS.append(load(nm))
    except Exception as e:
        skipped.append("%s : %r" % (nm, e))

# ---------- B. classement des 4 prises sur tout le lot ----------
log = ["Etape 4 (lot) - " + ", ".join(a["name"] for a in ANIMS), ""]
ranking = []
for gname, bdeg, roll in GRIPS:
    G = grip(bdeg, roll)
    res = [evaluate(A, G) for A in ANIMS]
    clip_total = sum(len(r["clip"]) for r in res)
    front = sum(r["front_pct"] for r in res) / len(res)
    ranking.append((-front, clip_total, gname, bdeg, roll, res))
ranking.sort(key=lambda x: (round(x[0], 1), x[1]))
log.append("B. Classement des prises (moyenne sur %d attaques) :" % len(ANIMS))
log.append("   % devant = part des images de frappe (milieu de lame > 50 % de sa vitesse max) ou la pointe est devant le torse (z < 0)")
for k, (nf, ct, gname, _, _, res) in enumerate(ranking, 1):
    log.append("  %d. %-48s pointe devant %5.1f %% | images ou la lame traverse le corps : %d" % (k, gname, -nf, ct))
    log.append("     detail : " + ", ".join("%s %.0f%%/%d" % (A["name"].replace("sword_and_shield_", ""), r["front_pct"], len(r["clip"]))
                                           for A, r in zip(ANIMS, res)))
nf, ct, gname, bdeg, roll, res = ranking[0]

# Ajustement +-30 deg autour du poignet si la lame traverse le corps (sans perdre plus de 5 points de % devant)
ax = az = 0
if ct > 0:
    best = (ct, 0, 0, 0, res)
    for tx in range(-30, 31, 10):
        for tz in range(-30, 31, 10):
            if (tx, tz) == (0, 0):
                continue
            r2 = [evaluate(A, grip(bdeg, roll, tx, tz)) for A in ANIMS]
            c2 = sum(len(r["clip"]) for r in r2)
            f2 = sum(r["front_pct"] for r in r2) / len(r2)
            if f2 >= -nf - 5 and (c2, abs(tx) + abs(tz)) < (best[0], abs(best[1]) + abs(best[2])):
                best = (c2, tx, tz, f2, r2)
    if best[0] < ct:
        ct, ax, az, res = best[0], best[1], best[2], best[4]
        log.append("Ajustement poignet retenu : X=%d deg, Z=%d deg -> %d images ou la lame traverse le corps" % (ax, az, ct))
    else:
        log.append("Ajustement poignet (+-30 deg) : aucune amelioration, prise gardee telle quelle")
# Prise figee (04_roblox/grip_fixed.json) : elle remplace le resultat de la recherche ci-dessus (garde pour info)
_fixed = os.path.join(OUT, "grip_fixed.json")
if os.path.exists(_fixed):
    _g = json.load(open(_fixed, encoding="utf-8"))
    gname, bdeg, roll, ax, az = _g["name"], _g["base_deg"], _g["roll_deg"], _g["tilt_x_deg"], _g["tilt_z_deg"]
    res = [evaluate(A, grip(bdeg, roll, ax, az)) for A in ANIMS]
    log.append("PRISE FIGEE utilisee (grip_fixed.json) : %s (X=%d, Z=%d) -> %d images ou la lame traverse le corps" % (
        gname, ax, az, sum(len(r["clip"]) for r in res)))
G = grip(bdeg, roll, ax, az)
r3 = G.to_3x3()
GRIP_LIST = [round(x, 6) for x in G.translation] + [round(r3[i][j], 6) for i in range(3) for j in range(3)]
log.append("Prise commune retenue : %s (X=%d, Z=%d) ; grip_offset CFrame = %s" % (gname, ax, az, GRIP_LIST))
log.append("")

# ---------- encodage compact pour Studio ----------
B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"


def enc(v, lo, hi, nchar):
    m = 64 ** nchar - 1
    q = int(round((min(max(v, lo), hi) - lo) / (hi - lo) * m))
    s = ""
    for _ in range(nchar):
        s = B64[q % 64] + s; q //= 64
    return s


def encode_anim(A):
    order = A["raw"]["motors_order"]
    out = []
    for f in A["raw"]["frames"]:
        s = ""
        for nm in order:
            d = f["motors"][nm]
            r = d["rot"]
            q = Matrix(((r[0], r[1], r[2]), (r[3], r[4], r[5]), (r[6], r[7], r[8]))).to_quaternion()
            if q.w < 0:
                q.negate()
            if nm == "Root":
                s += "".join(enc(x, -12, 12, 3) for x in d["pos"])
            s += "".join(enc(x, -1, 1, 2) for x in (q.x, q.y, q.z))
        out.append(s)
    return out


# ---------- sorties par attaque + recapitulatif ----------
def r4(v):
    return [round(x, 4) for x in v]


summary = []
for A, R in zip(ANIMS, res):
    n = len(A["times"])
    rootp = [Vector(f["motors"]["Root"]["pos"]) for f in A["raw"]["frames"]]
    amp = max((p - rootp[0]).length for p in rootp)
    net = rootp[-1] - rootp[0]
    w0, w1 = R["win"][0], R["win"][-1]
    hw = {"start": A["times"][w0], "end": A["times"][w1], "frames": [A["frames"][w0], A["frames"][w1]],
          "rule": "milieu de lame > 50 % vitesse max ET pointe devant (z<0), plus longue plage continue",
          "note": R["note"], "mid_speed_max_studs_s": round(R["vmax"], 3)}
    out = {"source": A["name"], "space": "HumanoidRootPart (Roblox, Y haut, perso regarde -Z), studs",
           "sword": {"handle": HANDLE, "guard": GUARD, "blade": BLADE, "blade_width": WIDTH, "blade_thickness": 0.08,
                     "local_axis": "+Y vers la pointe, origine au centre de la poignee",
                     "blade_base_y": Y_BASE, "tip_y": Y_TIP},
           "grip_offset": {"cframe": GRIP_LIST, "grip": gname, "tilt_x_deg": ax, "tilt_z_deg": az},
           "frames": [[A["times"][i], r4(R["base"][i]), r4(R["tip"][i]), round(R["stip"][i], 3), round(R["smid"][i], 3)]
                      for i in range(n)],
           "frames_format": "[t, base, tip, vitesse pointe, vitesse milieu de lame]",
           "hit_window": hw, "clipping_frames": R["clip"], "front_pct_during_strike": round(R["front_pct"], 1),
           "root_motion": {"amplitude_max": round(amp, 4), "net": r4(net)},
           "studio_encoded": {"fps": A["raw"]["fps"], "order": A["raw"]["motors_order"],
                              "format": "par image : Root pos 3x3 car. [-12,12] puis 15 x quaternion xyz 2 car. [-1,1] (w>=0)",
                              "frames": encode_anim(A)}}
    with open(os.path.join(OUT, A["name"] + "_blade.json"), "w", encoding="utf-8") as fh:
        json.dump(out, fh, indent=1)
    dur = A["times"][-1]
    summary.append({"name": A["name"], "dur": dur, "n": n, "win": (hw["start"], hw["end"], hw["frames"]),
                    "clip": [c["frame"] for c in R["clip"]], "depth": max([c["depth"] for c in R["clip"]], default=0),
                    "front": R["front_pct"], "amp": amp, "net": net, "note": R["note"]})

# propre = pas de traversee du corps, pointe devant pendant la frappe, peu de deplacement de racine, fenetre >= 3 images
for s in summary:
    s["score"] = (len(s["clip"]), -round(s["front"]), round(s["amp"], 1), 0 if s["note"] == "" else 1)
top = sorted(summary, key=lambda s: s["score"])[:5]

rec = ["Recapitulatif du lot d'attaques - prise commune : %s (X=%d, Z=%d)" % (gname, ax, az), ""]
rec.append("%-30s %6s %4s  %-28s %-22s %8s  %s" % ("attaque", "duree", "img", "fenetre de touche (s / img)", "lame dans le corps",
                                                   "devant", "deplacement racine (max / net xyz)"))
for s in summary:
    rec.append("%-30s %5.2fs %4d  %.3f-%.3f (%d-%d)%9s %-22s %6.0f%%  %.2f / %s%s" % (
        s["name"].replace("sword_and_shield_", ""), s["dur"], s["n"], s["win"][0], s["win"][1], s["win"][2][0], s["win"][2][1], "",
        ("aucune" if not s["clip"] else "%d img (max %.2f)" % (len(s["clip"]), s["depth"])), s["front"], s["amp"],
        r4(s["net"]), ("  [" + s["note"] + "]") if s["note"] else ""))
_corr = os.path.join(OUT, "corrections_4c.json")
if os.path.exists(_corr):
    C = json.load(open(_corr, encoding="utf-8"))
    rec += ["", "Correction anti-collision 4c (rotation corrective poignet, puis coude si besoin ; lissee sur 5 images) :",
            "%-12s %-34s %-34s %s" % ("attaque", "lame dans le corps AVANT", "APRES", "correction max (poignet / coude)")]
    for s in summary:
        c = C.get(s["name"])
        if not c:
            continue
        rec.append("%-12s %-34s %-34s %.1f deg / %.1f deg" % (
            s["name"].replace("sword_and_shield_", ""),
            ("%d img %s" % (len(c["before"]), c["before"])) if c["before"] else "aucune",
            ("%d img %s" % (len(s["clip"]), s["clip"])) if s["clip"] else "aucune",
            c["max_wrist_deg"], c["max_elbow_deg"]))
rec += ["", "Les 5 plus propres (pas de lame dans le corps, pointe devant pendant la frappe, peu de deplacement de racine) :"]
for k, s in enumerate(top, 1):
    rec.append("  %d. %s" % (k, s["name"].replace("sword_and_shield_", "")))
if skipped:
    rec += ["", "Sautes : " + " ; ".join(skipped)]

_tag = os.environ.get("PIPE_LOG_TAG")
if _tag:  # analyse ponctuelle (ex. un ultime) : ne pas ecraser les recapitulatifs du lot d'attaques
    with open(os.path.join(LOGS, _tag + ".txt"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(log + rec) + "\n")
else:
    with open(os.path.join(LOGS, "etape4.txt"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(log + rec) + "\n")
    with open(os.path.join(LOGS, "lot_attaques.txt"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(rec) + "\n")
print("BLADE_LOT_DONE")
print("\n".join(log + rec))
