# Planche d'une animation faite main AVEC le sabre (methode « voir son travail », 16/11).
# blender -b 03_retarget/<nom>.blend --python planche_anim.py -- <nom> <dossier_sortie_absolu> [pas_images=3]
# Rendu Workbench, 2 vues (face, 3/4), une image toutes les N images ; assemblage avec ffmpeg (tile) a part.
# La lame est calculee comme dans verif_anim.py (prise commune BLADE_LOCAL, pointe a 3,75 studs de la main),
# puis placee dans la scene Blender par la correspondance Roblox -> Blender mesuree sur les mains (affichee).
import bpy, sys, os, json, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mathutils import Matrix, Vector
from anim_lib import BASE, RIGS, T, BLADE_LOCAL

argv = sys.argv[sys.argv.index("--") + 1:]
nom, sortie = argv[0], argv[1]
pas = int(argv[2]) if len(argv) > 2 else 3
os.makedirs(sortie, exist_ok=True)
F = json.load(open(os.path.join(BASE, "03_retarget", nom + "_frames.json"), encoding="utf-8"))
rig = json.load(open(RIGS[F["rig"]], encoding="utf-8"))


def fk(f):
    W = {"HumanoidRootPart": Matrix.Identity(4)}
    for m in rig["motors"]:
        d = f["motors"][m["name"]]
        r = d["rot"]
        R = Matrix(((r[0], r[1], r[2], d["pos"][0]), (r[3], r[4], r[5], d["pos"][1]), (r[6], r[7], r[8], d["pos"][2]), (0, 0, 0, 1)))
        W[m["part1"]] = W[m["part0"]] @ T(m["c0_pos"]) @ R @ T(m["c1_pos"]).inverted()
    return W


sc = bpy.context.scene
fps = sc.render.fps
frames = F["frames"]
dt = 1.0 / F.get("fps", 30)
# correspondance Roblox -> Blender : x -> -x, y -> z, z -> y (verifiee ci-dessous sur 3 parties)
MAP = Matrix(((-1, 0, 0), (0, 0, 1), (0, 1, 0)))


def bl(obj, f_idx):
    sc.frame_set(f_idx + 1)
    o = bpy.data.objects[obj]
    dg = bpy.context.evaluated_depsgraph_get()
    oe = o.evaluated_get(dg)
    c = sum((Vector(v) for v in oe.bound_box), Vector()) / 8
    return oe.matrix_world @ c


W0 = fk(frames[0])
ref = bl("R15_RightHand", 0)
B0 = {p: bl("R15_" + p, 0) - ref for p in ["LeftHand", "Head", "RightFoot", "LeftFoot"]}
import itertools
K = sum(B0[p].length for p in B0) / sum((W0[p].translation - W0["RightHand"].translation).length for p in B0)
meilleur = None
for perm in itertools.permutations(range(3)):
    for sg in itertools.product((1, -1), repeat=3):
        M = Matrix([[sg[r] if c == perm[r] else 0 for c in range(3)] for r in range(3)])
        e = max((K * M @ (W0[p].translation - W0["RightHand"].translation) - B0[p]).length for p in B0)
        if meilleur is None or e < meilleur[0]:
            meilleur = (e, M)
err, MAP = meilleur
MAP = MAP * K
for p in B0:
    print("PLANCHE dist", p, round((W0[p].translation - W0["RightHand"].translation).length, 2), round(B0[p].length, 2))
print("PLANCHE echelle", round(K, 3), "ecart (m):", round(err, 3), [list(r) for r in MAP])

mat = bpy.data.materials.new("acier")
lame = bpy.data.objects.new("Lame", bpy.data.meshes.new("Lame"))
sc.collection.objects.link(lame)
import bmesh
bm = bmesh.new()
bmesh.ops.create_cube(bm, size=1.0)
bm.to_mesh(lame.data)
lame.color = (0.85, 0.85, 0.95, 1)
poignee = lame.copy(); poignee.data = lame.data.copy(); sc.collection.objects.link(poignee)
poignee.color = (0.5, 0.05, 0.05, 1)
for o in sc.objects:
    if o.type == "MESH" and o.name.startswith("R15_"):
        o.color = (0.75, 0.5, 0.25, 1)


def placer(obj, a, b, ep):
    d = b - a
    obj.location = (a + b) / 2
    obj.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    obj.scale = (ep * K, ep * K * 2.2, d.length)


cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam)
cam.data.type = "ORTHO"; cam.data.ortho_scale = 12 * K
sc.camera = cam
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"; sc.display.shading.color_type = "OBJECT"
sc.render.resolution_x = 300; sc.render.resolution_y = 360
bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, 0))
sol = bpy.context.active_object
# sol de la scene = pieds de la premiere image
pieds = min(bl("R15_LeftFoot", 0).z, bl("R15_RightFoot", 0).z) - 0.2 * K
sol.location.z = pieds
fwd = Vector((0, -1, 0))
vues = {"face": fwd, "persp": (fwd + Vector((-0.9, 0, 0.3))).normalized()}
for i in range(0, len(frames), pas):
    W = fk(frames[i])
    H = W["RightHand"]
    dirl = MAP @ (H.to_3x3() @ BLADE_LOCAL)
    main = bl("R15_RightHand", i)
    placer(lame, main + dirl * 0.45, main + dirl * 3.75, 0.08)
    placer(poignee, main - dirl * 0.35, main + dirl * 0.45, 0.12)
    ctr = (bl("R15_LowerTorso", i) + Vector((0, -1.5 * K, 0)))
    for v, d in vues.items():
        cam.location = ctr + d * 30
        cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
        sc.render.filepath = os.path.join(sortie, "%s_%s_%03d.png" % (nom, v, i))
        bpy.ops.render.render(write_still=True)
print("PLANCHE_OK", nom)
