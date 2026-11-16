# Mission combat, etape 3 - Monstre « Rodeur de cendre » (design original), Blender 4.5 -b
# Usage : blender -b --python rodeur.py
# Silhouette : 1,6 x un avatar (~8,5 studs), tres mince, bras jusqu'aux genoux, griffes ~1,2 stud (40 cm),
# longs cheveux noirs qui cachent le visage, yeux rouges entre les meches, peau noir charbon.
# Construit en pieces rigides aux noms R15 (une piece par membre) : le rig Roblox est un Humanoid R15 standard
# (Motor6D aux noms R15), donc les animations faites par poses cles et la reaction de choc existante marchent.
# Repere de modelisation = ROBLOX (x droite, y haut, le monstre regarde -z), converti en Blender (X=x, Y=-z, Z=y).
# Sorties : 05_vfx/rodeur/PIPE_rodeur.fbx (toutes les pieces), rodeur_rig.json (pieces, articulations, moteurs),
#           03_retarget/rodeur_rig.blend (armature + pieces parentees aux os, pour animer)
import bpy, bmesh, os, math, json, random
from mathutils import Vector

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(BASE, "05_vfx", "rodeur")
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(4)


def B(p):  # Roblox -> Blender
    return Vector((p[0], -p[2], p[1]))


# ---------- articulations (repere Roblox, pieds au sol y = 0) ----------
J = {
    "Root": (0, 4.6, 0), "Waist": (0, 5.0, 0), "Neck": (0, 7.22, -0.12),
    "LeftShoulder": (-0.82, 6.92, 0.02), "RightShoulder": (0.82, 6.92, 0.02),
    "LeftElbow": (-0.95, 4.98, 0.05), "RightElbow": (0.95, 4.98, 0.05),
    "LeftWrist": (-1.0, 3.12, -0.02), "RightWrist": (1.0, 3.12, -0.02),
    "LeftHip": (-0.36, 4.45, 0), "RightHip": (0.36, 4.45, 0),
    "LeftKnee": (-0.39, 2.38, -0.06), "RightKnee": (0.39, 2.38, -0.06),
    "LeftAnkle": (-0.4, 0.42, 0.04), "RightAnkle": (0.4, 0.42, 0.04),
}
MOTORS = [("Root", "HumanoidRootPart", "LowerTorso"), ("Waist", "LowerTorso", "UpperTorso"), ("Neck", "UpperTorso", "Head"),
          ("LeftShoulder", "UpperTorso", "LeftUpperArm"), ("LeftElbow", "LeftUpperArm", "LeftLowerArm"),
          ("LeftWrist", "LeftLowerArm", "LeftHand"),
          ("RightShoulder", "UpperTorso", "RightUpperArm"), ("RightElbow", "RightUpperArm", "RightLowerArm"),
          ("RightWrist", "RightLowerArm", "RightHand"),
          ("LeftHip", "LowerTorso", "LeftUpperLeg"), ("LeftKnee", "LeftUpperLeg", "LeftLowerLeg"),
          ("LeftAnkle", "LeftLowerLeg", "LeftFoot"),
          ("RightHip", "LowerTorso", "RightUpperLeg"), ("RightKnee", "RightUpperLeg", "RightLowerLeg"),
          ("RightAnkle", "RightLowerLeg", "RightFoot")]
HRP_CENTER = (0, 5.6, 0)
HRP_SIZE = (2.0, 2.0, 1.0)


# ---------- outils de modelisation ----------
def frame_axes(d):
    d = d.normalized()
    up = Vector((0, 0, 1)) if abs(d.z) < 0.9 else Vector((0, -1, 0))
    a = d.cross(up).normalized()
    b = a.cross(d).normalized()
    return a, b


def tube(bm, path, S=8, cap=True, jitter=0.0, flat=None):
    """path : liste de (point Roblox, rayon_a, rayon_b). Section elliptique orientee selon la direction locale."""
    pts = [B(p) for (p, _, _) in path]
    rings = []
    for i, (p, ra, rb) in enumerate(path):
        d = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)])
        a, b = frame_axes(d)
        if flat is not None:  # orientation imposee de l'axe a (ex. meches plates)
            a = (flat - d.normalized() * flat.dot(d.normalized())).normalized(); b = d.normalized().cross(a).normalized()
        ring = []
        for k in range(S):
            t = 2 * math.pi * k / S
            j = 1 + random.uniform(-jitter, jitter)
            ring.append(bm.verts.new(pts[i] + (a * math.cos(t) * ra + b * math.sin(t) * rb) * j))
        rings.append(ring)
    for i in range(len(rings) - 1):
        for k in range(S):
            k2 = (k + 1) % S
            bm.faces.new((rings[i][k], rings[i][k2], rings[i + 1][k2], rings[i + 1][k]))
    if cap:
        bm.faces.new(rings[0][::-1]); bm.faces.new(rings[-1])


def lerp(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def limb(bm, p0, p1, radii, S=8, bulge=None, jitter=0.04):
    """Membre de p0 a p1, rayons = liste (ra, rb) le long du membre ; bulge = (t, gain) pour une articulation osseuse."""
    n = len(radii)
    path = []
    for i, (ra, rb) in enumerate(radii):
        t = i / (n - 1)
        g = 1.0
        if bulge:
            for (tb, gb) in bulge:
                g += gb * math.exp(-((t - tb) / 0.07) ** 2)
        path.append((lerp(p0, p1, t), ra * g, rb * g))
    tube(bm, path, S=S, jitter=jitter)


PIECES = {}


def piece(name, build):
    bm = bmesh.new()
    build(bm)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me); bm.free()
    for poly in me.polygons:
        poly.use_smooth = True
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    PIECES[name] = ob
    return ob


# ---------- corps ----------
def lower_torso(bm):
    tube(bm, [((0, 4.28, 0.02), 0.30, 0.22), ((0, 4.48, 0.0), 0.36, 0.24), ((0, 4.72, 0.0), 0.33, 0.22),
              ((0, 5.05, 0.02), 0.28, 0.19)], S=10, jitter=0.03)


def upper_torso(bm):
    # buste maigre : taille tres fine, cage thoracique marquee, epaules osseuses, leger dos voute
    tube(bm, [((0, 4.98, 0.03), 0.27, 0.19), ((0, 5.35, 0.04), 0.30, 0.20), ((0, 5.8, 0.02), 0.50, 0.29),
              ((0, 6.25, 0.0), 0.62, 0.33), ((0, 6.7, 0.04), 0.70, 0.32), ((0, 6.98, 0.08), 0.62, 0.26),
              ((0, 7.18, 0.02), 0.24, 0.18), ((0, 7.32, -0.08), 0.16, 0.15)], S=12, jitter=0.03)
    for side in (-1, 1):  # cotes qui saillent (bosses allongees sur les flancs et l'avant)
        for k, y in enumerate((5.75, 6.0, 6.25, 6.5)):
            r = 0.45 + 0.05 * k
            tube(bm, [((side * 0.12, y + 0.05, -0.30), 0.03, 0.02), ((side * r * 0.7, y, -0.24), 0.035, 0.025),
                      ((side * r * 0.98, y - 0.08, 0.0), 0.03, 0.02)], S=5)
        tube(bm, [((side * 0.18, 6.95, 0.0), 0.10, 0.08), ((side * 0.8, 6.98, 0.04), 0.13, 0.11)], S=6)  # clavicule / epaule
    for y in (5.3, 5.55, 5.8, 6.05, 6.3, 6.55, 6.8):  # vertebres
        tube(bm, [((0, y - 0.06, 0.24 + 0.05 * math.sin((y - 5.3) * 2)), 0.05, 0.04),
                  ((0, y + 0.06, 0.25 + 0.05 * math.sin((y - 5.3) * 2)), 0.05, 0.04)], S=5)


def head(bm):
    # crane allonge, machoire etroite (cache par les cheveux)
    c = (0, 7.82, -0.16)
    path = []
    for i in range(9):
        t = i / 8
        y = 7.22 + 1.2 * t
        w = 0.32 * math.sin(math.pi * min(1, t * 1.05 + 0.08)) + 0.02
        d = 0.38 * math.sin(math.pi * min(1, t * 1.0 + 0.1)) + 0.02
        z = -0.1 - 0.12 * math.sin(math.pi * t)
        path.append(((0, y, z), max(w, 0.06), max(d, 0.06)))
    tube(bm, path, S=12, jitter=0.02)


def arm(side, upper):
    s = 1 if side == "Right" else -1
    def build(bm):
        if upper:
            limb(bm, J[side + "Shoulder"], J[side + "Elbow"], [(0.16, 0.15), (0.15, 0.14), (0.12, 0.11), (0.10, 0.10), (0.12, 0.11)],
                 bulge=[(1.0, 0.35)])
        else:
            limb(bm, J[side + "Elbow"], J[side + "Wrist"], [(0.12, 0.11), (0.10, 0.09), (0.085, 0.075), (0.07, 0.065), (0.08, 0.06)],
                 bulge=[(0.0, 0.3)])
    return build


def hand(side):
    s = 1 if side == "Right" else -1
    w = J[side + "Wrist"]
    def build(bm):
        tube(bm, [((w[0], w[1] - 0.02, w[2]), 0.09, 0.06), ((w[0] + s * 0.02, w[1] - 0.25, w[2] - 0.02), 0.15, 0.06),
                  ((w[0] + s * 0.02, w[1] - 0.42, w[2] - 0.04), 0.14, 0.05)], S=8)
        for k in range(4):  # doigts longs et noueux, legerement plies vers l'avant
            ox = s * 0.02 + (k - 1.5) * 0.075 * s
            p0 = (w[0] + ox, w[1] - 0.42, w[2] - 0.04)
            p1 = (w[0] + ox * 1.15, w[1] - 0.70, w[2] - 0.10)
            p2 = (w[0] + ox * 1.2, w[1] - 0.92, w[2] - 0.20)
            tube(bm, [(p0, 0.032, 0.028), (lerp(p0, p1, 0.5), 0.026, 0.024), (p1, 0.03, 0.026), (p2, 0.022, 0.02)], S=5)
        tube(bm, [((w[0] - s * 0.1, w[1] - 0.2, w[2] - 0.06), 0.03, 0.03), ((w[0] - s * 0.13, w[1] - 0.45, w[2] - 0.2), 0.022, 0.02)], S=5)
    return build


def claws(side):
    s = 1 if side == "Right" else -1
    w = J[side + "Wrist"]
    def build(bm):
        for k in range(4):  # griffes ~1,2 stud, courbees vers l'avant, tailles un peu differentes
            ox = s * 0.02 + (k - 1.5) * 0.075 * s
            L = 1.15 + 0.12 * math.sin(k * 1.7)
            base = (w[0] + ox * 1.2, w[1] - 0.92, w[2] - 0.20)
            path = []
            for i in range(7):
                t = i / 6
                y = base[1] - L * t
                z = base[2] - 0.55 * t * t            # courbure vers l'avant
                path.append(((base[0] + ox * 0.15 * t, y, z), 0.032 * (1 - t) + 0.003, 0.022 * (1 - t) + 0.003))
            tube(bm, path, S=5)
        # griffe du pouce, plus courte
        tb = (w[0] - s * 0.13, w[1] - 0.45, w[2] - 0.2)
        tube(bm, [(tb, 0.025, 0.02), ((tb[0] - s * 0.04, tb[1] - 0.3, tb[2] - 0.2), 0.012, 0.01), ((tb[0] - s * 0.05, tb[1] - 0.5, tb[2] - 0.38), 0.003, 0.003)], S=5)
    return build


def leg(side, upper):
    def build(bm):
        if upper:
            limb(bm, J[side + "Hip"], J[side + "Knee"], [(0.22, 0.21), (0.19, 0.18), (0.15, 0.14), (0.12, 0.12), (0.14, 0.13)],
                 bulge=[(1.0, 0.3)])
        else:
            limb(bm, J[side + "Knee"], J[side + "Ankle"], [(0.13, 0.13), (0.12, 0.11), (0.09, 0.09), (0.07, 0.065), (0.08, 0.07)],
                 bulge=[(0.0, 0.25)])
    return build


def foot(side):
    a = J[side + "Ankle"]
    def build(bm):
        tube(bm, [((a[0], a[1] + 0.05, a[2] + 0.12), 0.08, 0.08), ((a[0], a[1] - 0.18, a[2] + 0.02), 0.11, 0.1),
                  ((a[0], 0.12, a[2] - 0.32), 0.12, 0.07), ((a[0], 0.07, a[2] - 0.62), 0.10, 0.05),
                  ((a[0], 0.05, a[2] - 0.78), 0.05, 0.03)], S=8)
    return build


def hair(bm):
    # meches plates qui tombent du crane ; devant elles cachent le visage, avec deux interstices pour les yeux
    random.seed(9)
    top = (0, 8.38, -0.16)
    N = 46
    for i in range(N):
        a = 2 * math.pi * i / N
        front = math.cos(a - math.pi / 2)   # devant = -z : a = -pi/2 ... on mesure la face avant
        sx, sz = math.cos(a), math.sin(a)
        root = (sx * 0.28, 8.2 - 0.12 * abs(sz), -0.2 + sz * 0.33)
        is_front = sz < -0.35
        if is_front and any(abs(sx * 0.28 - ex) < 0.035 for ex in (-0.13, 0.13)):
            continue  # passages pour les yeux
        length = (1.7 if is_front else 2.5) + random.uniform(-0.25, 0.3)
        path = []
        for k in range(7):
            t = k / 6
            out = 0.06 + 0.25 * math.sin(min(1, t * 2) * math.pi / 2)  # epouse le crane puis tombe
            y = root[1] - length * t
            wav = 0.04 * math.sin(t * 7 + i)
            p = (root[0] + sx * out * (0.5 if is_front else 1) + wav, y, root[2] + sz * out * (0.5 if is_front else 1))
            path.append((p, (0.085 if is_front else 0.075) * (1 - 0.5 * t) + 0.01, 0.014))
        tube(bm, path, S=4, cap=False, flat=Vector((-sz, 0, 0)).normalized() if abs(sz) > 0.01 else Vector((1, 0, 0)))
    # calotte (le dessus du crane couvert)
    tube(bm, [((0, 7.95, -0.2), 0.30, 0.36), ((0, 8.2, -0.2), 0.28, 0.33), ((0, 8.38, -0.2), 0.17, 0.21),
              ((0, 8.45, -0.2), 0.04, 0.04)], S=12)


def eyes(bm):
    for ex in (-0.13, 0.13):
        tube(bm, [((ex - 0.05, 7.86, -0.6), 0.022, 0.016), ((ex + 0.05, 7.84, -0.6), 0.02, 0.015)], S=6)


piece("LowerTorso", lower_torso)
piece("UpperTorso", upper_torso)
piece("Head", head)
for sd in ("Left", "Right"):
    piece(sd + "UpperArm", arm(sd, True)); piece(sd + "LowerArm", arm(sd, False)); piece(sd + "Hand", hand(sd))
    piece(sd + "UpperLeg", leg(sd, True)); piece(sd + "LowerLeg", leg(sd, False)); piece(sd + "Foot", foot(sd))
    piece(sd + "Claws", claws(sd))
piece("Hair", hair)
piece("Eyes", eyes)

# ---------- infos : centres de boite (Roblox recentre chaque MeshPart), tailles, triangles ----------
info = {"parts": {}, "joints": J, "hrp": {"center": HRP_CENTER, "size": HRP_SIZE}, "motors": [], "tris_total": 0}
for name, ob in PIECES.items():
    me = ob.data; me.calc_loop_triangles()
    vs = [v.co for v in me.vertices]
    mn = Vector((min(v.x for v in vs), min(v.y for v in vs), min(v.z for v in vs)))
    mx = Vector((max(v.x for v in vs), max(v.y for v in vs), max(v.z for v in vs)))
    c = (mn + mx) / 2; s = mx - mn
    info["parts"][name] = {"center": [round(c.x, 4), round(c.z, 4), round(-c.y, 4)], "size": [round(s.x, 4), round(s.z, 4), round(s.y, 4)],
                           "tris": len(me.loop_triangles)}
    info["tris_total"] += len(me.loop_triangles)
centers = {k: v["center"] for k, v in info["parts"].items()}
centers["HumanoidRootPart"] = list(HRP_CENTER)
for (n, p0, p1) in MOTORS:
    j = J[n]
    info["motors"].append({"name": n, "part0": p0, "part1": p1,
                           "c0_pos": [round(j[i] - centers[p0][i], 5) for i in range(3)],
                           "c1_pos": [round(j[i] - centers[p1][i], 5) for i in range(3)]})
# pieces soudees (decor) : piece -> membre porteur
info["welds"] = {"LeftClaws": "LeftHand", "RightClaws": "RightHand", "Hair": "Head", "Eyes": "Head"}
info["hip_height"] = round(HRP_CENTER[1] - HRP_SIZE[1] / 2, 4)
with open(os.path.join(OUT, "rodeur_rig.json"), "w", encoding="utf-8") as fh:
    json.dump(info, fh, indent=1)

# ---------- export FBX : chaque piece a son origine au centre de sa boite (comme Roblox) ----------
for name, ob in PIECES.items():
    c = info["parts"][name]["center"]
    off = B(c)
    ob.data.transform(__import__("mathutils").Matrix.Translation(-off))
    ob.location = off
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, "PIPE_rodeur.fbx"), use_selection=True,
                         axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL")

# ---------- .blend d'animation : armature aux noms des pieces, pieces parentees a leur os ----------
arm_data = bpy.data.armatures.new("Rodeur")
rig = bpy.data.objects.new("Rodeur", arm_data)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
child_joint = {}
for (n, p0, p1) in MOTORS:
    child_joint.setdefault(p0, n)
eb = {}
for (n, p0, p1) in MOTORS:
    b = arm_data.edit_bones.new(p1)
    b.head = B(J[n])
    nxt = [m for m in MOTORS if m[1] == p1]
    tail = B(J[nxt[0][0]]) if nxt else B(info["parts"][p1]["center"]) * 2 - B(J[n])
    if (tail - b.head).length < 0.05:
        tail = b.head + Vector((0, 0, 0.3))
    b.tail = tail
    eb[p1] = b
for (n, p0, p1) in MOTORS:
    if p0 in eb:
        eb[p1].parent = eb[p0]
bpy.ops.object.mode_set(mode="OBJECT")
for name, ob in PIECES.items():
    bone = info["welds"].get(name, name)
    mw = ob.matrix_world.copy()
    ob.parent = rig; ob.parent_type = "BONE"; ob.parent_bone = bone
    ob.matrix_world = mw
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE, "03_retarget", "rodeur_rig.blend"))
print("RODEUR_DONE", info["tris_total"], json.dumps({k: v["tris"] for k, v in info["parts"].items()}))
