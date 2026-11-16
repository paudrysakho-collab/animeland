# Apercu rapide (Workbench) d'un ou plusieurs FBX : blender -b --python apercu_objet.py -- sortie.png vue fichier1.fbx [fichier2.fbx ...]
# vue : top | front | side | persp
import bpy, sys, math
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
out, view, files = argv[0], argv[1], argv[2:]
bpy.ops.wm.read_factory_settings(use_empty=True)
for f in files:
    bpy.ops.import_scene.fbx(filepath=f)
obs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
mn = Vector((1e9,) * 3); mx = Vector((-1e9,) * 3)
for o in obs:
    for c in o.bound_box:
        w = o.matrix_world @ Vector(c)
        mn = Vector(map(min, mn, w)); mx = Vector(map(max, mx, w))
ctr = (mn + mx) / 2; ext = max(mx - mn)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
bpy.context.scene.collection.objects.link(cam)
cam.data.type = "ORTHO"; cam.data.ortho_scale = ext * 1.15
d = {"top": Vector((0, 0, 1)), "front": Vector((0, -1, 0)), "side": Vector((1, 0, 0)), "persp": Vector((0.8, -1, 0.6)).normalized(), "face": Vector((0, 1, 0)), "face34": Vector((0.7, 1, 0.25)).normalized()}[view]
cam.location = ctr + d * ext * 3
cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
sc = bpy.context.scene; sc.camera = cam
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"; sc.display.shading.color_type = "OBJECT"
sc.render.resolution_x = 700; sc.render.resolution_y = 700
for o in obs:
    o.color = (0.75, 0.5, 0.25, 1)
sc.render.filepath = out
bpy.ops.render.render(write_still=True)
print("APERCU_OK", out, [round(x, 3) for x in (mx - mn)])
