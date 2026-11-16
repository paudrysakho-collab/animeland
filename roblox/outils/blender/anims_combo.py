# Mission combat (retours du 16/11) - combo de base au sabre, 5 coups DESSINES A LA MAIN (poses cles sur le rig R15).
# Usage : blender -b --python anims_combo.py -- [nom ...]
# Reference etudiee (planches d'images, fiche mission/fiches/0_combo.md) : combos de jeu de sabre anime : coups tres
# rapides (0,1 a 0,2 s), appuis bas et larges, un pas en avant par coup, rotation des hanches et des epaules, finale en
# rotation. Chaque coup a sa forme : montant, horizontal, descendant, estoc, tourbillon. Animations SUR PLACE : le
# deplacement (racine x, z) est applique au HumanoidRootPart par le jeu (EpeeDonnees.racine).
# Regle verifiee : bras leve au-dela de 90 deg en X -> le signe de Z s'inverse (ordre des rotations) ; tout est
# controle par verif_anim.py (membres et lame dans le corps, pieds, trajectoire de la pointe).
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from anim_lib import Anim, V
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def voulu(nom):
    return not argv or nom in argv


def P(base, **over):
    p = dict(base)
    p.update(over)
    return p


# Garde : pied gauche devant, genoux plies, sabre a droite pointe vers l'avant, main gauche en garde.
G = {"Waist": (-8, 0, 0), "Neck": (5, 0, 0),
     "RightShoulder": (35, 0, 20), "RightElbow": (45, 0, 0), "LeftShoulder": (25, 0, -10), "LeftElbow": (50, 0, 0),
     "LeftHip": (25, 0, -8), "LeftKnee": (-35, 0, 0), "LeftAnkle": (8, 0, 0),
     "RightHip": (-15, 0, 10), "RightKnee": (-30, 0, 0), "RightAnkle": (12, 0, 0)}
LG = V(0.25, 0.35, -0.9)
RG = (0, 0, 0)
HG = -0.35  # hauteur de la racine en garde


def garde(A, t, z, ease=2):
    A.key(t, G, root=(0, HG, z), root_rot=RG, lame=LG, ease=ease)


# ---------- 1. DIAGONAL MONTANT (bas gauche -> haut droite) ----------
if voulu("coup_montant"):
    A = Anim("coup_montant", duree=0.62, priorite="Action4", sur_place=True)
    garde(A, 0.0, 0)
    A.key(0.10, P(G, Waist=(-15, 25, 0), RightShoulder=(20, 0, -45), RightElbow=(30, 0, 0),
                  LeftShoulder=(-10, 0, -25), LeftElbow=(20, 0, 0), LeftHip=(20, 0, -8), LeftKnee=(-40, 0, 0),
                  RightHip=(-20, 0, 10), RightKnee=(-50, 0, 0)),
          root=(0, -0.55, 0.2), root_rot=(-5, 30, 0), lame=V(-0.8, -0.3, -0.5), ease=3)
    A.key(0.20, P(G, Waist=(-10, -15, 0), RightShoulder=(85, 0, 10), RightElbow=(10, 0, 0),
                  LeftShoulder=(10, 0, -35), LeftElbow=(25, 0, 0), LeftHip=(40, 0, -6), LeftKnee=(-45, 0, 0),
                  RightHip=(-25, 0, 8), RightKnee=(-25, 0, 0)),
          root=(0, -0.45, -1.0), root_rot=(-10, -5, 0), lame=V(0.1, 0.45, -0.88), ease=-2)
    A.key(0.28, P(G, Waist=(8, -30, 0), RightShoulder=(140, 0, -35), RightElbow=(20, 0, 0),
                  LeftShoulder=(15, 0, -40), LeftElbow=(30, 0, 0), LeftHip=(40, 0, -6), LeftKnee=(-40, 0, 0),
                  RightHip=(-25, 0, 8), RightKnee=(-20, 0, 0)),
          root=(0, -0.3, -1.4), root_rot=(5, -25, 0), lame=V(0.55, 0.8, -0.2), ease=4)
    garde(A, 0.62, -1.5)
    A.build()

# ---------- 2. HORIZONTAL (droite -> gauche, hauteur de taille) ----------
if voulu("coup_horizontal"):
    A = Anim("coup_horizontal", duree=0.62, priorite="Action4", sur_place=True)
    garde(A, 0.0, 0)
    A.key(0.12, P(G, Waist=(-5, -30, 0), RightShoulder=(60, 0, 75), RightElbow=(35, 0, 0),
                  LeftShoulder=(60, 0, -20), LeftElbow=(20, 0, 0), RightHip=(-25, 0, 12), RightKnee=(-45, 0, 0),
                  LeftHip=(25, 0, -10), LeftKnee=(-35, 0, 0)),
          root=(0.1, -0.5, 0.1), root_rot=(-5, -30, 0), lame=V(0.85, 0.1, 0.5), ease=3)
    A.key(0.22, P(G, Waist=(-10, 20, 0), RightShoulder=(85, 0, 15), RightElbow=(5, 0, 0),
                  LeftShoulder=(20, 0, -40), LeftElbow=(25, 0, 0), LeftHip=(45, 0, -8), LeftKnee=(-50, 0, 0),
                  RightHip=(-30, 0, 10), RightKnee=(-20, 0, 0)),
          root=(0, -0.5, -1.2), root_rot=(-10, 10, 0), lame=V(-0.45, 0.05, -0.9), ease=-2)
    A.key(0.30, P(G, Waist=(-8, 40, 0), RightShoulder=(80, 0, -45), RightElbow=(10, 0, 0),
                  LeftShoulder=(10, 0, -50), LeftElbow=(30, 0, 0), LeftHip=(45, 0, -8), LeftKnee=(-50, 0, 0),
                  RightHip=(-30, 0, 10), RightKnee=(-20, 0, 0)),
          root=(-0.1, -0.5, -1.6), root_rot=(-8, 35, 0), lame=V(-0.95, 0.05, 0.25), ease=4)
    garde(A, 0.62, -1.8)
    A.build()

# ---------- 3. GRAND DIAGONAL DESCENDANT (haut droite -> bas gauche), grand pas, fin accroupie ----------
if voulu("coup_descendant"):
    A = Anim("coup_descendant", duree=0.70, priorite="Action4", sur_place=True)
    garde(A, 0.0, 0)
    A.key(0.14, P(G, Waist=(10, -25, 0), RightShoulder=(150, 0, -25), RightElbow=(60, 0, 0),
                  LeftShoulder=(90, 0, -10), LeftElbow=(10, 0, 0), LeftHip=(15, 0, -8), RightKnee=(-40, 0, 0)),
          root=(0, -0.3, 0.3), root_rot=(8, -20, 0), lame=V(0.45, 0.55, 0.7), ease=3)
    bas = P(G, Waist=(-25, 20, 0), RightShoulder=(70, 0, -20), RightElbow=(10, 0, 0),
            LeftShoulder=(-20, 0, -30), LeftElbow=(20, 0, 0), LeftHip=(70, 0, -8), LeftKnee=(-80, 0, 0), LeftAnkle=(15, 0, 0),
            RightHip=(-30, 0, 10), RightKnee=(-55, 0, 0), RightAnkle=(25, 0, 0))
    A.key(0.25, bas, root=(0, -0.68, -2.0), root_rot=(-20, 15, 0), lame=V(-0.4, 0.0, -0.91), ease=-2)
    A.key(0.34, P(bas, Waist=(-30, 30, 0), RightShoulder=(40, 0, -50)),
          root=(0, -0.74, -2.2), root_rot=(-25, 25, 0), lame=V(-0.9, -0.05, 0.1), ease=4)
    garde(A, 0.70, -2.3)
    A.build()

# ---------- 4. ESTOC EN RUEE (le corps traverse la distance) ----------
if voulu("coup_estoc"):
    A = Anim("coup_estoc", duree=0.65, priorite="Action4", sur_place=True)
    garde(A, 0.0, 0)
    A.key(0.12, P(G, Waist=(-10, -15, 0), RightShoulder=(-25, 0, 25), RightElbow=(100, 0, 0),
                  LeftShoulder=(70, 0, -15), LeftElbow=(15, 0, 0), LeftKnee=(-50, 0, 0), RightKnee=(-60, 0, 0)),
          root=(0, -0.6, 0.4), root_rot=(-10, -30, 0), lame=V(0.05, 0.05, -1), ease=3)
    loin = P(G, Waist=(-15, 15, 0), RightShoulder=(88, 0, 5), RightElbow=(0, 0, 0),
             LeftShoulder=(-30, 0, -30), LeftElbow=(10, 0, 0), LeftHip=(75, 0, -6), LeftKnee=(-75, 0, 0),
             RightHip=(-45, 0, 8), RightKnee=(-5, 0, 0), RightAnkle=(30, 0, 0))
    A.key(0.22, loin, root=(0, -0.7, -3.2), root_rot=(-20, 20, 0), lame=V(0, 0.1, -1), ease=-2)
    A.key(0.32, loin, root=(0, -0.72, -3.4), root_rot=(-20, 20, 0), lame=V(0, 0.12, -1), ease=3)
    garde(A, 0.65, -3.4)
    A.build()

# ---------- 5. FINALE : TOURBILLON SAUTE (rotation complete, coupe horizontale en finissant face a la cible) ----------
if voulu("coup_tourbillon"):
    A = Anim("coup_tourbillon", duree=0.85, priorite="Action4", sur_place=True)
    garde(A, 0.0, 0)

    def lame_ext(lacet):  # sabre tendu vers l'exterieur droit du corps, tranchant un peu devant, qui tourne avec lui
        r = Matrix.Rotation(math.radians(lacet), 3, "Y")
        return (r @ Vector((0.95, 0.05, -0.3))).normalized()

    tourne = P(G, Waist=(-5, 0, 0), RightShoulder=(10, 0, 85), RightElbow=(5, 0, 0), LeftShoulder=(10, 0, -60),
               LeftElbow=(40, 0, 0), LeftHip=(40, 0, -8), LeftKnee=(-70, 0, 0), RightHip=(10, 0, 8), RightKnee=(-70, 0, 0))
    A.key(0.12, P(G, Waist=(-10, -20, 0), RightShoulder=(30, 0, 70), RightElbow=(30, 0, 0), LeftKnee=(-55, 0, 0),
                  RightKnee=(-60, 0, 0)),
          root=(0, -0.6, 0.1), root_rot=(0, -45, 0), lame=lame_ext(-60), ease=3)       # arme : tordu a droite, accroupi
    A.key(0.22, tourne, root=(0, 0.2, -0.4), root_rot=(0, 90, 0), lame=lame_ext(90), ease=-2)    # depart du saut
    A.key(0.32, tourne, root=(0, 0.6, -0.8), root_rot=(0, 200, 0), lame=lame_ext(200), ease=1)   # en l'air
    A.key(0.40, tourne, root=(0, 0.2, -1.2), root_rot=(0, 315, 0), lame=lame_ext(315), ease=1)
    fin = P(G, Waist=(-15, 25, 0), RightShoulder=(85, 0, 10), RightElbow=(5, 0, 0), LeftShoulder=(-10, 0, -40),
            LeftHip=(55, 0, -8), LeftKnee=(-75, 0, 0), RightHip=(-30, 0, 10), RightKnee=(-50, 0, 0), RightAnkle=(25, 0, 0))
    A.key(0.46, fin, root=(0, -0.8, -1.5), root_rot=(-10, 360, 0), lame=V(-0.5, 0.05, -0.85), ease=1)  # coupe en face
    A.key(0.56, P(fin, Waist=(-15, 40, 0), RightShoulder=(80, 0, -45)), root=(0, -0.85, -1.6), root_rot=(-12, 380, 0),
          lame=V(-0.9, 0.0, 0.3), ease=4)
    A.key(0.85, G, root=(0, HG, -1.7), root_rot=(0, 360, 0), lame=LG, ease=2)
    A.build()
print("COMBO_OK")
