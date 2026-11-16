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


def pose(base, **over):
    p = dict(base)
    p.update(over)
    return p


# ---------- 1. SLASH A DISTANCE « Sillon de braise » (touche 1), 1,25 s ----------
# Fiche : mission/fiches/1_slash.md. Grand arme au-dessus de la tete (anticipation), tension, coup descendant
# qui accelere jusqu'au sol ; la vague de feu part au marqueur « Contact » (0,60 s).
if voulu("feu_slash"):
    A = Anim("feu_slash", rig="r15", duree=1.25, priorite="Action4", tremble=(0.36, 0.5, 1.5))
    A.key(0.0, GARDE, root=(0, 0, 0), lame=LAME_GARDE, ease=2)
    posture = {"LeftHip": (30, 0, -6), "LeftKnee": (-30, 0, 0), "LeftAnkle": (5, 0, 0),
               "RightHip": (-20, 0, 8), "RightKnee": (-25, 0, 0), "RightAnkle": (10, 0, 0)}
    A.key(0.14, pose(posture, Waist=(0, -15, 0), RightShoulder=(95, 0, 10), RightElbow=(60, 0, 0),
                     LeftShoulder=(75, 0, -5), LeftElbow=(50, 0, 0)),
          root=(0, -0.25, 0.1), root_rot=(0, -10, 0), lame=V(0.1, 0.9, 0.3), ease=3)
    arme = pose(posture, Waist=(12, -10, 0), Neck=(10, 0, 0), RightShoulder=(172, 0, -8), RightElbow=(45, 0, 0),
                LeftShoulder=(160, 0, 8), LeftElbow=(55, 0, 0), RightKnee=(-15, 0, 0), RightAnkle=(25, 0, 0))
    A.key(0.42, arme, root=(0, 0.12, 0.25), root_rot=(6, -8, 0), lame=V(0.05, 0.35, 0.94), ease=3)
    A.key(0.50, pose(arme, Waist=(16, -12, 0)), root=(0, 0.16, 0.3), root_rot=(8, -8, 0), lame=V(0.05, 0.2, 0.98), ease=2)
    frappe = {"Root": (-15, 5, 0), "Waist": (-25, 10, 0), "Neck": (-5, 0, 0),
              "RightShoulder": (70, 0, -5), "RightElbow": (5, 0, 0), "LeftShoulder": (60, 0, 0), "LeftElbow": (15, 0, 0),
              "LeftHip": (70, 0, -6), "LeftKnee": (-85, 0, 0), "LeftAnkle": (15, 0, 0),
              "RightHip": (-25, 0, 8), "RightKnee": (-40, 0, 0), "RightAnkle": (20, 0, 0)}
    A.key(0.60, frappe, root=(0, -0.42, -1.3), lame=V(0, -0.40, -0.92), ease=-3)
    A.key(0.68, pose(frappe, Root=(-18, 5, 0), Waist=(-28, 10, 0)), root=(0, -0.48, -1.35), lame=V(0, -0.43, -0.90), ease=4)
    A.key(0.88, pose(frappe, Root=(-15, 4, 0), Waist=(-25, 8, 0)), root=(0, -0.42, -1.3), lame=V(0, -0.41, -0.91), ease=2)
    A.key(1.25, GARDE, root=(0, 0, 0), lame=LAME_GARDE, ease=2)
    A.marker("Depart", 0.50)
    A.marker("Contact", 0.60)
    A.build()
print("FEU_ANIMS_OK")
