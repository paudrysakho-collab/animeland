# Etape 7 - Ultime 01 "Couronne de l'Aube" : animation creee DE ZERO par poses cles (Blender 4.5, -b)
# Usage : blender -b --python ultime_01.py
# Sorties : 03_retarget/ult_01_R15_frames.json (meme format que le retarget), 03_retarget/ult_01_R15.blend
#
# Conventions (repere Roblox, perso regarde -Z, sa droite = +X, Y en haut) - rotations des Motor6D en degres (X, Y, Z),
# appliquees dans l'ordre CFrame.fromEulerAnglesXYZ :
#   bras / jambes qui pendent : +X = lever vers l'avant ; bras droit +Z = ecarter sur le cote (bras gauche : -Z)
#   buste (Waist) / Root : -X = pencher en avant, +X = se cambrer ; Y = torsion (+Y = tourner vers la gauche)
#   genou : -X = plier (talon vers l'arriere) ; coude : +X = plier ; Neck : -X = baisser la tete
# La lame est orientee par "visee" : pour chaque pose cle on donne la direction voulue de la lame (espace HRP),
# et la rotation du poignet est calculee pour l'obtenir (prise commune figee, 04_roblox/grip_fixed.json).
import bpy, os, json, math, random
from mathutils import Matrix, Vector, Quaternion, Euler

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RIG = json.load(open(os.path.join(BASE, "02_extraction", "r15_rig.json"), encoding="utf-8"))
GF = json.load(open(os.path.join(BASE, "04_roblox", "grip_fixed.json"), encoding="utf-8"))
RET = os.path.join(BASE, "03_retarget")
NAME = "ult_01"
FPS = 30
DUR = 3.5
motors = RIG["motors"]
ORDER = [m["name"] for m in motors]
MOT = {m["name"]: m for m in motors}
M3 = Matrix(((-1, 0, 0), (0, 0, 1), (0, 1, 0)))


def grip(base_deg, roll_deg, ax=0, az=0):
    return (Matrix.Rotation(math.radians(az), 4, "Z") @ Matrix.Rotation(math.radians(base_deg + ax), 4, "X")
            @ Matrix.Rotation(math.radians(roll_deg), 4, "Y"))


G = grip(GF["base_deg"], GF["roll_deg"], GF["tilt_x_deg"], GF["tilt_z_deg"])
BLADE_LOCAL = (G.to_3x3() @ Vector((0, 1, 0))).normalized()


def E(x=0, y=0, z=0):
    return Euler((math.radians(x), math.radians(y), math.radians(z)), "XYZ").to_quaternion()


def V(x, y, z):
    return Vector((x, y, z)).normalized()


# ---------- poses cles ----------
# chaque pose : dict joint -> (x,y,z) degres ; "root_pos" (studs, espace HRP) ; "blade" direction voulue (HRP) ou None
CROUCH_LEGS = {"LeftHip": (55, 0, -5), "LeftKnee": (-75, 0, 0), "LeftAnkle": (20, 0, 0),
               "RightHip": (-25, 0, 8), "RightKnee": (-55, 0, 0), "RightAnkle": (-10, 0, 0)}
KEYS = []


def key(t, joints, root_pos, root_rot=(0, 0, 0), blade=None, ease=4):
    KEYS.append({"t": t, "j": joints, "rp": Vector(root_pos), "rr": root_rot, "blade": blade, "ease": ease})


charge = dict(CROUCH_LEGS)
charge.update({"Root": (-12, 15, 0), "Waist": (-10, 15, 0), "Neck": (8, -20, 0),
               "RightShoulder": (-35, 0, 25), "RightElbow": (20, 0, 0),
               "LeftShoulder": (35, 0, -40), "LeftElbow": (10, 0, 0), "LeftWrist": (-35, 0, 0)})
key(0.0, charge, (0, -0.7, 0), blade=V(0.35, -0.55, 0.75))
charge2 = dict(charge); charge2.update({"LeftKnee": (-90, 0, 0), "LeftHip": (65, 0, -5), "RightKnee": (-70, 0, 0), "Root": (-18, 18, 0)})
key(0.8, charge2, (0, -1.1, 0), blade=V(0.3, -0.5, 0.8), ease=2)

# DASH : pose etiree (flou de mouvement) puis arrivee
dash = {"Root": (-48, 0, 0), "Waist": (-10, 0, 0), "Neck": (25, 0, 0),
        "LeftHip": (70, 0, 0), "LeftKnee": (-35, 0, 0), "LeftAnkle": (10, 0, 0),
        "RightHip": (-50, 0, 0), "RightKnee": (-15, 0, 0), "RightAnkle": (-25, 0, 0),
        "RightShoulder": (-75, 0, 15), "RightElbow": (5, 0, 0), "LeftShoulder": (-65, 0, -15), "LeftElbow": (5, 0, 0)}
key(0.88, dash, (0, -0.6, -6.5), blade=V(0.1, 0.05, 1.0), ease=2)
# sortie du dash : la lame passe par le cote droit (loin du bassin)
side = dict(dash); side.update({"Root": (-30, -10, 0), "RightShoulder": (10, 0, 70), "RightElbow": (10, 0, 0)})
key(0.95, side, (0, -0.75, -10.5), blade=V(0.85, -0.35, -0.4), ease=3)
land = dict(CROUCH_LEGS)
land.update({"Root": (-20, -35, 0), "Waist": (-15, -30, 0), "Neck": (5, 30, 0),
             "RightShoulder": (75, -20, -35), "RightElbow": (0, 0, 0), "LeftShoulder": (20, 0, -30), "LeftElbow": (40, 0, 0)})
key(1.0, land, (0, -0.9, -12), blade=V(-0.65, -0.35, -0.7), ease=3)

# TAILLE MONTANTE + petit saut
tuck = {"LeftHip": (70, 0, -5), "LeftKnee": (-95, 0, 0), "RightHip": (40, 0, 5), "RightKnee": (-100, 0, 0),
        "LeftAnkle": (-15, 0, 0), "RightAnkle": (-15, 0, 0)}
up = dict(tuck); up.update({"Root": (8, 30, 0), "Waist": (10, 35, 0), "Neck": (-5, -25, 0),
                            "RightShoulder": (150, 0, 35), "RightElbow": (15, 0, 0), "LeftShoulder": (40, 0, -60), "LeftElbow": (20, 0, 0)})
key(1.3, up, (0, 2.2, -13.2), blade=V(0.5, 0.85, -0.15), ease=5)
key(1.6, up, (0, 3.2, -13.8), blade=V(0.55, 0.8, 0.1), ease=2)

# EN L'AIR : 3 coups en eventail (droite-haut -> gauche, gauche -> droite bas, centre vers l'avant)
# pose intermediaire : l'epee passe DEVANT le corps (bras tendu vers l'avant) avant le 1er coup
mid = dict(tuck); mid.update({"Root": (0, 0, 0), "Waist": (0, 5, 0), "RightShoulder": (125, 0, 15), "RightElbow": (0, 0, 0),
                              "LeftShoulder": (35, 0, -65)})
key(1.68, mid, (0, 3.35, -14.1), blade=V(0.25, 0.45, -0.85), ease=4)
f1 = dict(tuck); f1.update({"Root": (-5, -15, 0), "Waist": (-10, -15, 0), "RightShoulder": (100, 0, -5), "RightElbow": (0, 0, 0),
                            "LeftShoulder": (30, 0, -70), "Neck": (0, 30, 0)})
key(1.78, f1, (0, 3.4, -14.4), blade=V(-0.75, 0.05, -0.65), ease=6)
f2 = dict(tuck); f2.update({"Root": (-10, 30, 0), "Waist": (-5, 35, 0), "RightShoulder": (55, 0, 60), "RightElbow": (10, 0, 0),
                            "LeftShoulder": (40, 0, -40), "Neck": (0, -30, 0)})
key(2.03, f2, (0, 3.3, -15.0), blade=V(0.85, -0.25, -0.45), ease=6)
f3 = dict(tuck); f3.update({"Root": (-20, 0, 0), "Waist": (-15, 0, 0), "RightShoulder": (90, 0, 5), "RightElbow": (0, 0, 0),
                            "LeftShoulder": (60, 0, -20), "Neck": (5, 0, 0)})
key(2.27, f3, (0, 3.4, -15.6), blade=V(0.0, 0.0, -1.0), ease=6)

# POSE SUSPENDUE : epee levee a deux mains, corps cambre (tenue)
susp = {"Root": (18, 0, 0), "Waist": (22, 0, 0), "Neck": (18, 0, 0),
        "LeftHip": (25, 0, -8), "LeftKnee": (-70, 0, 0), "RightHip": (-10, 0, 8), "RightKnee": (-80, 0, 0),
        "LeftAnkle": (-25, 0, 0), "RightAnkle": (-25, 0, 0),
        "RightShoulder": (170, 0, 12), "RightElbow": (30, 0, 0), "LeftShoulder": (170, 0, -12), "LeftElbow": (30, 0, 0)}
key(2.45, susp, (0, 4.2, -16.0), blade=V(0.0, 0.85, 0.5), ease=5)
key(2.9, susp, (0, 4.4, -16.1), blade=V(0.0, 0.88, 0.45), ease=2)

# FRAPPE DESCENDANTE : chute, epee plantee, un genou a terre, pose tenue
kneel = {"Root": (-15, 0, 0), "Waist": (-28, 0, 0), "Neck": (-12, 0, 0),
         "LeftHip": (85, 0, -5), "LeftKnee": (-95, 0, 0), "LeftAnkle": (10, 0, 0),
         "RightHip": (-5, 0, 6), "RightKnee": (-105, 0, 0), "RightAnkle": (-40, 0, 0),
         "RightShoulder": (65, 0, 5), "RightElbow": (15, 0, 0), "LeftShoulder": (60, 0, -5), "LeftElbow": (25, 0, 0)}
key(3.1, kneel, (0, -1.35, -17.0), blade=V(0.0, -0.95, -0.3), ease=7)
key(3.5, kneel, (0, -1.4, -17.0), blade=V(0.0, -0.96, -0.28), ease=2)


# ---------- cinematique directe (Roblox) ----------
def T(v):
    return Matrix.Translation(Vector(v))


def fk(rot, root_pos):
    """rot : nom moteur -> Quaternion ; renvoie W (part -> Matrix 4x4)"""
    W = {"HumanoidRootPart": Matrix.Identity(4)}
    for m in motors:
        q = rot.get(m["name"], Quaternion())
        tr = q.to_matrix().to_4x4()
        if m["name"] == "Root":
            tr = T(root_pos) @ tr
        W[m["part1"]] = W[m["part0"]] @ T(m["c0_pos"]) @ tr @ T(m["c1_pos"]).inverted()
    return W


def solve_wrist(rot, root_pos, blade_dir):
    W = fk(rot, root_pos)
    me = MOT["RightWrist"]
    parent = W["RightLowerArm"] @ T(me["c0_pos"])
    target = parent.to_3x3().inverted() @ blade_dir
    return BLADE_LOCAL.rotation_difference(target.normalized())


for k in KEYS:
    rot = {n: E(*v) for n, v in k["j"].items()}
    k["q"] = rot
    if k["blade"] is not None:
        rot["RightWrist"] = solve_wrist(rot, k["rp"], k["blade"])


# ---------- interpolation : transitions rapides (ease-out marque), tremblement pendant la charge ----------
def ease(u, p):
    return 1 - (1 - u) ** p


random.seed(7)
noise = {n: [Vector((random.uniform(-1, 1), random.uniform(-1, 1), random.uniform(-1, 1))) for _ in range(200)] for n in ORDER}
frames = []
nf = int(round(DUR * FPS)) + 1
for fi in range(nf):
    t = fi / FPS
    k1 = max(i for i, k in enumerate(KEYS) if k["t"] <= t + 1e-9)
    k2 = min(k1 + 1, len(KEYS) - 1)
    a, b = KEYS[k1], KEYS[k2]
    u = 0 if k2 == k1 else (t - a["t"]) / (b["t"] - a["t"])
    w = ease(min(max(u, 0), 1), b["ease"])
    rp = a["rp"].lerp(b["rp"], w)
    mot = {}
    for n in ORDER:
        qa, qb = a["q"].get(n, Quaternion()), b["q"].get(n, Quaternion())
        q = qa.slerp(qb, w)
        if t < 0.8:  # tremblement croissant (0 -> 2 deg), lisse
            amp = math.radians(2.0 * (t / 0.8))
            nv = noise[n][fi] * 0.6 + noise[n][max(0, fi - 1)] * 0.4
            q = q @ Euler((nv.x * amp, nv.y * amp, nv.z * amp), "XYZ").to_quaternion()
        m3 = q.to_matrix()
        pos = rp if n == "Root" else Vector((0, 0, 0))
        mot[n] = {"pos": [round(x, 6) for x in pos], "rot": [round(m3[i][j], 6) for i in range(3) for j in range(3)]}
    frames.append({"frame": fi + 1, "time": round(t, 6), "motors": mot})

out = {"source": "ultime_01.py (poses cles creees de zero)", "fps": float(FPS), "nb_frames": nf,
       "units": "studs, Y vers le haut (Roblox)",
       "format": "Motor6D.Transform local par image : pos [x,y,z] + rot 3x3 (lignes R00..R22)",
       "motors_order": ORDER, "frames": frames,
       "phases": {"charge": [0.0, 0.8], "dash": [0.8, 1.0], "taille_montante": [1.0, 1.6], "air": [1.6, 2.4],
                  "pose_suspendue": [2.4, 2.9], "frappe": [2.9, 3.5]}}
with open(os.path.join(RET, NAME + "_R15_frames.json"), "w", encoding="utf-8") as fh:
    json.dump(out, fh, indent=1)

# ---------- .blend : memes poses sur l'armature R15 (copie d'un .blend du lot, Mixamo retire) ----------
src_blend = os.path.join(RET, "sword_and_shield_attack_4_R15.blend")
bpy.ops.wm.open_mainfile(filepath=src_blend)
for o in list(bpy.data.objects):
    if o.name != "R15" and not (o.parent and o.parent.name == "R15"):
        bpy.data.objects.remove(o, do_unlink=True)
r15 = bpy.data.objects["R15"]
r15.location = (0, 0, r15.location.z)
if r15.animation_data:
    r15.animation_data_clear()
r15.animation_data_create()
act = bpy.data.actions.new(NAME)
r15.animation_data.action = act
sc = bpy.context.scene
sc.frame_start, sc.frame_end = 1, nf
part_of = {m["name"]: m["part1"] for m in motors}
prev = {}
for f in frames:
    for n in ORDER:
        bone = part_of[n]
        B = r15.data.bones[bone].matrix_local.to_3x3()
        r = f["motors"][n]["rot"]
        Rt = Matrix(((r[0], r[1], r[2]), (r[3], r[4], r[5]), (r[6], r[7], r[8])))
        basis_rot = (B.inverted() @ (M3 @ Rt @ M3) @ B).to_quaternion()
        if bone in prev:
            basis_rot.make_compatible(prev[bone])
        prev[bone] = basis_rot
        pb = r15.pose.bones[bone]
        pb.rotation_mode = "QUATERNION"
        pb.rotation_quaternion = basis_rot
        if n == "Root":
            pb.location = B.inverted() @ (M3 @ Vector(f["motors"][n]["pos"]))
            pb.keyframe_insert("location", frame=f["frame"])
        pb.keyframe_insert("rotation_quaternion", frame=f["frame"])
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(RET, NAME + "_R15.blend"))
print("ULT_DONE", nf, "images")
