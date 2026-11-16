# Planche d'images d'une animation (.blend de anim_lib) : blender -b fichier.blend --python apercu_anim.py -- sortie_prefixe vue t1 t2 ...
# vue : face | side | persp ; une image PNG par temps (secondes), a assembler ensuite (ffmpeg tile)
import bpy, sys, math
from mathutils import Vector
argv = sys.argv[sys.argv.index("--") + 1:]
pref, view, times = argv[0], argv[1], [float(x) for x in argv[2:]]
sc = bpy.context.scene
fps = sc.render.fps
arm = [o for o in sc.objects if o.type == "ARMATURE"][0]
meshes = [o for o in sc.objects if o.type == "MESH"]
print("MESHES", [o.name for o in meshes])
for o in meshes:
    o.color = (0.75, 0.5, 0.25, 1)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam)
cam.data.type = "ORTHO"; cam.data.ortho_scale = 11
# le rig regarde +Y Blender (rodeur) ; R15 importe : -Y
fwd = Vector((0, 1, 0)) if arm.name == "Rodeur" else Vector((0, -1, 0))
d = {"face": fwd, "side": Vector((1, 0, 0)), "persp": (fwd * 1.0 + Vector((0.9, 0, 0.35))).normalized()}[view]
ctr = Vector((0, 0, 4.2)) if arm.name == "Rodeur" else Vector((0, 0, 2.5))
if arm.name != "Rodeur":
    cam.data.ortho_scale = 10
    ctr = Vector((0, -1.5, 2.2))  # R15 : le coup avance vers -Y
cam.location = ctr + d * 30
cam.rotation_euler = (-d).to_track_quat("-Z", "Y").to_euler()
sc.camera = cam
sc.render.engine = "BLENDER_WORKBENCH"
sc.display.shading.light = "STUDIO"; sc.display.shading.color_type = "OBJECT"
sc.render.resolution_x = 320; sc.render.resolution_y = 400
# sol
bpy.ops.mesh.primitive_plane_add(size=30, location=(0, 0, 0))
for i, t in enumerate(times):
    sc.frame_set(int(round(t * fps)) + 1)
    sc.render.filepath = "%s_%02d.png" % (pref, i)
    bpy.ops.render.render(write_still=True)
print("PLANCHE_OK", len(times))
