# Mission combat, etape 3 - animations du Rodeur de cendre, poses cles faites a la main (Blender 4.5 -b)
# Usage : blender -b --python anims_rodeur.py
# Caractere : voute, tete penchee sur le cote, bras ballants qui trainent en retard sur le corps,
# mouvements lents puis brusques (a-coups). Le visage reste cache.
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from anim_lib import Anim


def base(**over):
    p = {"Waist": (-16, 0, 0), "Neck": (8, 0, 12),
         "RightShoulder": (6, 0, 6), "RightElbow": (12, 0, 0), "RightWrist": (8, 0, 0),
         "LeftShoulder": (6, 0, -6), "LeftElbow": (12, 0, 0), "LeftWrist": (8, 0, 0),
         "LeftHip": (6, 0, -3), "LeftKnee": (-14, 0, 0), "LeftAnkle": (6, 0, 0),
         "RightHip": (6, 0, 3), "RightKnee": (-14, 0, 0), "RightAnkle": (6, 0, 0)}
    p.update(over)
    return p


R0 = (-6, 0, 0)  # Root : leger penche en avant
DOWN = (0, -0.18, 0)

# ---------- ATTENTE (boucle 2,4 s) : respiration, balancement, a-coup de la tete ----------
A = Anim("rodeur_attente", rig="rodeur", duree=2.4, boucle=True, priorite="Idle")
A.key(0.0, base(), root=DOWN, root_rot=R0, ease=2)
A.key(1.15, base(Waist=(-20, 4, 0), Neck=(10, -4, 14), RightShoulder=(9, 0, 4), LeftShoulder=(3, 0, -8)),
      root=(0.04, -0.24, 0), root_rot=(-7, 3, 1), ease=2)
A.key(1.25, base(Waist=(-20, 4, 0), Neck=(2, 10, -14), RightShoulder=(9, 0, 4), LeftShoulder=(3, 0, -8)),
      root=(0.04, -0.24, 0), root_rot=(-7, 3, 1), ease=6)     # a-coup : la tete bascule de l'autre cote
A.key(1.9, base(Neck=(4, 6, -10)), root=(0, -0.2, 0), root_rot=R0, ease=2)
A.key(2.4, base(), root=DOWN, root_rot=R0, ease=3)
A.build()

# ---------- MARCHE (boucle 1,2 s) : grande foulee lente, bras qui trainent ----------
W = Anim("rodeur_marche", rig="rodeur", duree=1.2, boucle=True, priorite="Movement")
def pas(t, cote, phase):
    av, ar = ("Right", "Left") if cote == "R" else ("Left", "Right")
    s = 1 if cote == "R" else -1
    if phase == "contact":
        j = {av + "Hip": (30, 0, 0), av + "Knee": (-6, 0, 0), av + "Ankle": (-12, 0, 0),
             ar + "Hip": (-20, 0, 0), ar + "Knee": (-22, 0, 0), ar + "Ankle": (18, 0, 0),
             # bras opposes, en retard : le bras du cote de la jambe avant est encore en arriere
             av + "Shoulder": (-14, 0, 6 * s), av + "Elbow": (8, 0, 0),
             ar + "Shoulder": (20, 0, -6 * s), ar + "Elbow": (22, 0, 0)}
        return base(Waist=(-18, -6 * s, 0), Neck=(10, 6 * s, 12), **j), (0.06 * s, -0.32, 0), (-7, 6 * s, 0)
    j = {av + "Hip": (8, 0, 0), av + "Knee": (-12, 0, 0), av + "Ankle": (4, 0, 0),
         ar + "Hip": (18, 0, 0), ar + "Knee": (-62, 0, 0), ar + "Ankle": (14, 0, 0),
         av + "Shoulder": (2, 0, 6 * s), av + "Elbow": (12, 0, 0), ar + "Shoulder": (6, 0, -6 * s), ar + "Elbow": (14, 0, 0)}
    return base(Waist=(-15, 0, 0), Neck=(8, 0, 12), **j), (0.03 * s, -0.08, 0), (-5, 0, 0)
for (t, c, ph) in ((0.0, "R", "contact"), (0.3, "R", "passage"), (0.6, "L", "contact"), (0.9, "L", "passage"), (1.2, "R", "contact")):
    j, rp, rr = pas(t, c, ph)
    W.key(t, j, root=rp, root_rot=rr, ease=2)
W.build()

# ---------- COURSE (boucle 0,66 s) : tres penche, bras qui trainent derriere, foulee enorme ----------
C = Anim("rodeur_course", rig="rodeur", duree=0.66, boucle=True, priorite="Movement")
def foulee(cote, phase):
    av, ar = ("Right", "Left") if cote == "R" else ("Left", "Right")
    s = 1 if cote == "R" else -1
    arms = {"RightShoulder": (-50, 0, 18), "RightElbow": (10, 0, 0), "LeftShoulder": (-50, 0, -18), "LeftElbow": (10, 0, 0),
            "RightWrist": (-20, 0, 0), "LeftWrist": (-20, 0, 0)}
    if phase == "contact":
        j = {av + "Hip": (55, 0, 0), av + "Knee": (-18, 0, 0), av + "Ankle": (-15, 0, 0),
             ar + "Hip": (-35, 0, 0), ar + "Knee": (-35, 0, 0), ar + "Ankle": (25, 0, 0)}
        arms[av + "Shoulder"] = (-62, 0, 14 * s); arms[ar + "Shoulder"] = (-38, 0, -14 * s)
        return dict(base(Waist=(-22, -8 * s, 0), Neck=(28, 8 * s, 6), **arms), **j), (0, -0.55, 0), (-28, 8 * s, 0)
    j = {av + "Hip": (10, 0, 0), av + "Knee": (-25, 0, 0), ar + "Hip": (40, 0, 0), ar + "Knee": (-110, 0, 0), ar + "Ankle": (20, 0, 0)}
    return dict(base(Waist=(-24, 0, 0), Neck=(30, 0, 6), **arms), **j), (0, -0.15, 0), (-30, 0, 0)
for (t, c, ph) in ((0.0, "R", "contact"), (0.165, "R", "passage"), (0.33, "L", "contact"), (0.495, "L", "passage"), (0.66, "R", "contact")):
    j, rp, rr = foulee(c, ph)
    C.key(t, j, root=rp, root_rot=rr, ease=2)
C.build()

# ---------- GRIFFE (1,3 s) : 0,6 s d'anticipation (= alerte du serveur), coup en diagonale, recuperation ----------
G = Anim("rodeur_griffe", rig="rodeur", duree=1.3, priorite="Action", tremble=(0.15, 0.6, 2.5))
stance = {"LeftHip": (28, 0, -6), "LeftKnee": (-38, 0, 0), "LeftAnkle": (10, 0, 0),
          "RightHip": (-14, 0, 8), "RightKnee": (-26, 0, 0), "RightAnkle": (8, 0, 0)}
G.key(0.0, base(), root=DOWN, root_rot=R0, ease=2)
arme = base(Waist=(8, -32, 0), Neck=(-4, 30, 14), RightShoulder=(195, 0, -30), RightElbow=(42, 0, 0), RightWrist=(-30, 0, 0),
            LeftShoulder=(42, 0, -22), LeftElbow=(28, 0, 0), **stance)
G.key(0.45, arme, root=(0.1, -0.45, 0.25), root_rot=(-4, -16, 0), ease=3)          # anticipation : se replie, bras tres haut derriere
arme2 = dict(arme); arme2.update({"RightShoulder": (205, 0, -34), "Waist": (10, -36, 0)})
G.key(0.6, arme2, root=(0.12, -0.5, 0.3), root_rot=(-3, -18, 0), ease=2)             # tension maximale (tient)
frappe = base(Waist=(-18, 18, 0), Neck=(12, -12, 10), RightShoulder=(75, 0, -10), RightElbow=(6, 0, 0), RightWrist=(10, 0, 0),
              LeftShoulder=(-20, 0, -30), LeftElbow=(20, 0, 0), **stance)
G.key(0.7, frappe, root=(-0.1, -0.6, -0.9), root_rot=(-10, 10, 0), ease=-2)        # acceleration vers l'impact (fente)
suite = dict(frappe); suite.update({"RightShoulder": (20, 0, -30), "Waist": (-26, 36, 0), "RightElbow": (14, 0, 0)})
G.key(0.88, suite, root=(-0.15, -0.62, -1.1), root_rot=(-16, 20, 0), ease=4)         # suivi du geste
G.key(1.3, base(), root=DOWN, root_rot=R0, ease=2)                                    # recuperation
G.marker("Depart", 0.6)
G.marker("Contact", 0.7)
G.build()

# ---------- CHOC (0,45 s) : la tete part en arriere, le buste se tord ----------
H = Anim("rodeur_choc", rig="rodeur", duree=0.45, priorite="Action2")
H.key(0.0, base(), root=DOWN, root_rot=R0, ease=2)
pic = base(Waist=(12, 12, 6), Neck=(26, -10, -14), RightShoulder=(-20, 0, 34), LeftShoulder=(-14, 0, -38),
           RightElbow=(30, 0, 0), LeftElbow=(34, 0, 0))
H.key(0.07, pic, root=(0, -0.25, 0.35), root_rot=(6, 8, 0), ease=6)
H.key(0.2, base(Waist=(0, 6, 3), Neck=(14, -4, -4)), root=(0, -0.22, 0.25), root_rot=(0, 4, 0), ease=3)
H.key(0.45, base(), root=DOWN, root_rot=R0, ease=2)
H.build()

# ---------- PROJETE (boucle 0,8 s) : en l'air, cambre, membres qui battent ----------
P = Anim("rodeur_projete", rig="rodeur", duree=0.8, boucle=True, priorite="Action3")
air1 = {"Waist": (24, 0, 6), "Neck": (32, 0, -10), "RightShoulder": (-70, 0, 60), "LeftShoulder": (-60, 0, -70),
        "RightElbow": (30, 0, 0), "LeftElbow": (45, 0, 0), "LeftHip": (-18, 0, -10), "LeftKnee": (-55, 0, 0),
        "RightHip": (12, 0, 8), "RightKnee": (-80, 0, 0)}
air2 = {"Waist": (14, 0, -6), "Neck": (22, 0, 12), "RightShoulder": (-40, 0, 80), "LeftShoulder": (-85, 0, -50),
        "RightElbow": (55, 0, 0), "LeftElbow": (20, 0, 0), "LeftHip": (10, 0, -6), "LeftKnee": (-85, 0, 0),
        "RightHip": (-14, 0, 10), "RightKnee": (-45, 0, 0)}
P.key(0.0, air1, root=(0, 0, 0), root_rot=(18, 0, 0), ease=2)
P.key(0.4, air2, root=(0, 0, 0), root_rot=(24, 0, 4), ease=2)
P.key(0.8, air1, root=(0, 0, 0), root_rot=(18, 0, 0), ease=2)
P.build()
print("RODEUR_ANIMS_OK")
