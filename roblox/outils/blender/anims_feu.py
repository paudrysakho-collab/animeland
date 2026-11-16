# Mission combat, etape 4 - animations des competences du feu (joueur, rig R15, sabre en main droite).
# Usage : blender -b --python anims_feu.py -- [nom ...]   (sans nom : toutes)
# Chaque competence : anticipation, acceleration, impact (marqueur « Contact »), recuperation. Poses verifiees par verif_pose.py.
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from anim_lib import Anim, V

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def voulu(nom):
    return not argv or nom in argv


GARDE = {"RightShoulder": (25, 0, 15), "RightElbow": (40, 0, 0), "LeftShoulder": (15, 0, -15), "LeftElbow": (30, 0, 0),
         "LeftHip": (15, 0, -4), "LeftKnee": (-20, 0, 0), "RightHip": (-8, 0, 5), "RightKnee": (-15, 0, 0)}
LAME_GARDE = V(0.2, 0.6, -0.75)


def deux_mains(A, joints, root, root_rot, lame):
    """Prise a deux mains : cherche LeftShoulder / LeftElbow pour poser la main gauche sur la poignee
    (0,5 stud sous la main droite, le long de la lame). Renvoie la pose completee et l'ecart (studs)."""
    from anim_lib import E
    from mathutils import Vector
    rot = {k: E(*v) for k, v in joints.items()}
    if root_rot is not None:
        rot["Root"] = E(*root_rot)
    rp = Vector(root)
    rot["RightWrist"] = A.solve_wrist(rot, rp, lame)
    W = A.fk(rot, rp)
    cible = W["RightHand"].translation - lame * 0.5
    best = None
    for x in range(-60, 211, 10):
        for z in range(-90, 91, 10):
            for y in (-30, 0, 30):
                rot["LeftShoulder"] = E(x, y, z)
                for c in range(0, 136, 15):
                    rot["LeftElbow"] = E(c, 0, 0)
                    Wl = A.fk(rot, rp)
                    e = (Wl["LeftHand"].translation - cible).length
                    for mb in ("LeftLowerArm", "LeftHand"):  # jamais dans la tete ni le torse
                        if (Wl[mb].translation - W["Head"].translation).length < 1.35:
                            e += 5
                        if (Wl[mb].translation - W["UpperTorso"].translation).length < 1.2:
                            e += 5
                    if best is None or e < best[0]:
                        best = (e, (x, y, z), (c, 0, 0))
    out = dict(joints)
    out["LeftShoulder"], out["LeftElbow"] = best[1], best[2]
    print("DEUX_MAINS ecart %.2f stud" % best[0], best[1], best[2])
    return out


def cle2(A, t, joints, root, root_rot, lame, ease):
    A.key(t, deux_mains(A, joints, root, root_rot, lame), root=root, root_rot=root_rot, lame=lame, ease=ease)


def pose(base, **over):
    p = dict(base)
    p.update(over)
    return p


# ---------- 1. SLASH A DISTANCE « Sillon de braise » (touche 1), 1,50 s - FAIT MAIN (retours du 16/11) ----------
# Reference : Demon Slayer: The Hinokami Chronicles, video SIAivrO6KlA, 12,2 -> 14,0 s (finale au sabre de Kyojuro),
# images a 10 i/s (mission/refs/slash_hinokami.jpg). 4 poses relevees : 12,2 s arme tres haut, debout, lame vers
# l'arriere ; 12,4 s grand pas, lame au sommet de l'arc ; 12,5 s contact : fente extreme, jambe arriere tendue,
# buste couche vers l'avant, lame au sol ; 12,7 -> 13,6 s longue tenue basse pendant l'explosion, puis on se releve.
# SUR PLACE : le grand pas (3 studs) est applique au HumanoidRootPart par le jeu (CompetencesFeu.pas).
if voulu("feu_slash"):
    A = Anim("feu_slash", rig="r15", duree=1.50, priorite="Action4", tremble=(0.30, 0.40, 1.2), sur_place=True)
    G = {"Waist": (-8, 0, 0), "Neck": (5, 0, 0),
         "RightShoulder": (35, 0, 20), "RightElbow": (45, 0, 0), "LeftShoulder": (25, 0, -10), "LeftElbow": (50, 0, 0),
         "LeftHip": (25, 0, -8), "LeftKnee": (-35, 0, 0), "LeftAnkle": (8, 0, 0),
         "RightHip": (-15, 0, 10), "RightKnee": (-30, 0, 0), "RightAnkle": (12, 0, 0)}
    LG = V(0.25, 0.35, -0.9)
    A.key(0.0, G, root=(0, -0.35, 0), lame=LG, ease=2)
    # ramene : le poids passe en arriere, les bras montent
    A.key(0.10, pose(G, Waist=(-5, -15, 0), RightShoulder=(100, 0, 15), RightElbow=(70, 0, 0),
                     LeftShoulder=(95, 0, -10), LeftElbow=(70, 0, 0), LeftHip=(20, 0, -6), LeftKnee=(-30, 0, 0),
                     RightHip=(-10, 0, 8), RightKnee=(-40, 0, 0)),
          root=(0, -0.45, 0.25), root_rot=(-3, -15, 0), lame=V(0.2, 0.8, 0.55), ease=3)
    # P1 (12,2 s) : ARME tres haut, corps grand et cambre, sur la pointe du pied arriere, lame vers l'arriere
    arme = pose(G, Waist=(14, -10, 0), Neck=(-8, 0, 0), RightShoulder=(170, 0, -5), RightElbow=(40, 0, 0),
                LeftShoulder=(165, 0, 5), LeftElbow=(45, 0, 0), LeftHip=(30, 0, -6), LeftKnee=(-20, 0, 0),
                LeftAnkle=(0, 0, 0), RightHip=(-12, 0, 8), RightKnee=(-10, 0, 0), RightAnkle=(30, 0, 0))
    cle2(A, 0.28, arme, (0, 0.05, 0.3), (8, -12, 0), V(0.08, 0.40, 0.91), 3)
    cle2(A, 0.38, pose(arme, Waist=(18, -12, 0)), (0, 0.10, 0.35), (10, -12, 0), V(0.08, 0.28, 0.96), 2)
    # P2 (12,4 s) : grand pas, la lame passe au sommet de l'arc, devant
    cle2(A, 0.46, pose(G, Waist=(-5, 0, 0), RightShoulder=(160, 0, 0), RightElbow=(15, 0, 0),
                       LeftHip=(55, 0, -6), LeftKnee=(-45, 0, 0),
                       RightHip=(-30, 0, 8), RightKnee=(-20, 0, 0), RightAnkle=(25, 0, 0)),
         (0, -0.3, -1.5), (-5, -4, 0), V(0.02, 0.92, -0.38), -3)
    # P3 (12,5 s) : CONTACT - fente extreme, jambe arriere tendue, buste couche, pointe au sol devant
    frappe = {"Waist": (-24, 8, 0), "Neck": (28, 0, 0),
              "RightShoulder": (75, 0, -5), "RightElbow": (5, 0, 0), "LeftShoulder": (65, 0, 5), "LeftElbow": (15, 0, 0),
              "LeftHip": (80, 0, -6), "LeftKnee": (-95, 0, 0), "LeftAnkle": (15, 0, 0),
              "RightHip": (-38, 0, 8), "RightKnee": (-18, 0, 0), "RightAnkle": (35, 0, 0)}
    LC = V(0.02, -0.30, -0.95)
    cle2(A, 0.54, frappe, (0, -0.8, -3.0), (-12, 6, 0), LC, -3)
    # P4 (12,7 -> 13,6 s) : tassement puis longue tenue basse (raccourcie pour le jeu)
    cle2(A, 0.62, pose(frappe, Waist=(-28, 10, 0)), (0, -0.82, -3.0), (-14, 6, 0), LC, 4)
    cle2(A, 1.05, frappe, (0, -0.8, -3.0), (-12, 5, 0), LC, 2)
    # on se releve (13,7 s) : le buste remonte d'abord, le sabre sort du sol en arc vers la garde
    A.key(1.25, pose(G, Waist=(-12, 4, 0), LeftHip=(50, 0, -8), LeftKnee=(-60, 0, 0), RightHip=(-25, 0, 10),
                     RightKnee=(-35, 0, 0)), root=(0, -0.55, -3.0), root_rot=(-5, 3, 0), lame=V(0.2, 0.05, -0.98), ease=2)
    # recuperation (13,7 -> 14,0 s) : on se releve, retour en garde
    A.key(1.50, G, root=(0, -0.35, -3.0), lame=LG, ease=2)
    A.marker("Depart", 0.38)
    A.marker("Contact", 0.54)
    A.build()
print("FEU_ANIMS_OK")
