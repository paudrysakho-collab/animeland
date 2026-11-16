# Etape 8b - Sabre (katana generique et original) + fourreau, modelise par script (Blender 4.5, -b)
# Usage : blender -b --python katana.py
# Repere (Blender) : la lame monte selon +Z (= +Y Roblox), largeur selon X (tranchant cote -X, dos cote +X),
# epaisseur selon Y. Origine = centre de la poignee (= centre de la main, meme convention que PIPE_Sword).
# Export FBX (axe haut Y) : X Blender -> X Roblox, Z Blender -> Y Roblox, Y Blender -> -Z Roblox.
# Sorties : 05_vfx/katana/PIPE_katana_{blade,fittings,handle,saya}.fbx + textures PNG + katana_info.json
import bpy, bmesh, os, math, json
import numpy as np
from mathutils import Vector

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(BASE, "05_vfx", "katana")
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)

L_BLADE, Z_BLADE0 = 3.3, 0.5          # lame : de z=0.5 a z=3.8
L_HANDLE = 0.9                        # poignee : z de -0.45 a 0.45
SORI = 0.13                           # courbure (vers le dos, +X)
W0, W1 = 0.20, 0.15                   # largeur de lame (base -> pointe)
TH = 0.07                             # epaisseur au dos


def curve_x(s):  # decalage du dos selon l'avancement s (0 base -> 1 pointe)
    return SORI * s * s


def new_obj(name, bm):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


# ---------- lame : section a 6 points (tranchant, shinogi, dos), pointe effilee ----------
def blade():
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    N = 30
    rings = []
    for i in range(N + 1):
        s = i / N
        z = Z_BLADE0 + L_BLADE * s
        cx = curve_x(s)
        w = W0 + (W1 - W0) * s
        t = TH * (1 - 0.35 * s)
        if s > 0.9:  # kissaki : la largeur se referme en courbe vers le tranchant
            k = (s - 0.9) / 0.1
            w *= max(0.02, math.sqrt(1 - k * k))
            t *= max(0.15, 1 - k)
        # u : 0 = tranchant, 1 = dos ; le profil : tranchant (-x), shinogi (65 %), dos (+x)
        prof = [(-w / 2, 0.0, 0.0), (-w / 2 + 0.62 * w, t / 2, 0.62), (w / 2, t * 0.38, 1.0),
                (w / 2, -t * 0.38, 1.0), (-w / 2 + 0.62 * w, -t / 2, 0.62)]
        ring = []
        for (x, y, u) in prof:
            ring.append((bm.verts.new((cx + x + w / 2 - W0 / 2, y, z)), u, s))
        rings.append(ring)
    for i in range(N):
        a, b = rings[i], rings[i + 1]
        for j in range(5):
            j2 = (j + 1) % 5
            f = bm.faces.new((a[j][0], a[j2][0], b[j2][0], b[j][0]))
            for loop, (u, v) in zip(f.loops, ((a[j][1], a[j][2]), (a[j2][1], a[j2][2]), (b[j2][1], b[j2][2]), (b[j][1], b[j][2]))):
                loop[uv].uv = (u, v)
    # bouchons
    bm.faces.new([r[0] for r in rings[0]][::-1])
    bm.faces.new([r[0] for r in rings[-1]])
    return new_obj("PIPE_katana_blade", bm)


# ---------- poignee : section elliptique, UV pour le tressage en losanges ----------
def handle():
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")
    S, N = 12, 10
    rings = []
    for i in range(N + 1):
        s = i / N
        z = -L_HANDLE / 2 + L_HANDLE * s
        bulge = 1 + 0.06 * math.sin(math.pi * s)  # leger renflement au milieu
        ring = []
        for j in range(S + 1):
            a = 2 * math.pi * j / S
            ring.append((bm.verts.new((0.062 * bulge * math.cos(a), 0.047 * bulge * math.sin(a), z)) if j < S else None, j / S, s))
        ring[S] = (ring[0][0], 1.0, s)
        rings.append(ring)
    for i in range(N):
        for j in range(S):
            a0, a1, b0, b1 = rings[i][j], rings[i][j + 1], rings[i + 1][j], rings[i + 1][j + 1]
            f = bm.faces.new((a0[0], a1[0], b1[0], b0[0]))
            for loop, (u, v) in zip(f.loops, ((a0[1], a0[2] * 2), (a1[1], a1[2] * 2), (b1[1], b1[2] * 2), (b0[1], b0[2] * 2))):
                loop[uv].uv = (u, v)
    return new_obj("PIPE_katana_handle", bm)


# ---------- garde ajouree (tsuba) + habaki + pommeau (kashira) : metal sombre ----------
def fittings():
    bm = bmesh.new()
    zt0, zt1 = 0.45, 0.49
    R_OUT, R_IN, R_HUB = 0.27, 0.215, 0.10
    S = 32
    def ring(r_in, r_out, z0, z1, segs, a0=0.0, a1=2 * math.pi):
        vs = []
        for k in range(segs + 1):
            a = a0 + (a1 - a0) * k / segs
            c, s_ = math.cos(a), math.sin(a)
            vs.append([bm.verts.new((r_in * c, r_in * s_ * 0.92, z0)), bm.verts.new((r_out * c, r_out * s_ * 0.92, z0)),
                       bm.verts.new((r_out * c, r_out * s_ * 0.92, z1)), bm.verts.new((r_in * c, r_in * s_ * 0.92, z1))])
        for k in range(segs):
            A, B = vs[k], vs[k + 1]
            for q in range(4):
                q2 = (q + 1) % 4
                bm.faces.new((A[q], B[q], B[q2], A[q2]))
        if a1 - a0 < 2 * math.pi - 1e-3:
            bm.faces.new(vs[0][::-1]); bm.faces.new(vs[-1])
    ring(R_IN, R_OUT, zt0, zt1, S)                 # bord exterieur
    ring(0.075, R_HUB, zt0, zt1, 16)               # moyeu (passage de la soie)
    for k in range(6):                             # 6 rayons en arc : ajourage
        a = k * math.pi / 3
        ring(R_HUB - 0.005, R_IN + 0.005, zt0 + 0.005, zt1 - 0.005, 3, a - 0.13, a + 0.13)
    # habaki (collier de lame)
    hb = bmesh.ops.create_cube(bm, size=1.0)
    for v in hb["verts"]:
        v.co = Vector((v.co.x * 0.22, v.co.y * 0.085, 0.49 + (v.co.z + 0.5) * 0.11))
    # fuchi (bague de poignee) + kashira (pommeau arrondi)
    for (z0, z1, sx, sy) in ((0.40, 0.45, 0.07, 0.055), (-0.52, -0.45, 0.068, 0.053)):
        cyl = bmesh.ops.create_cone(bm, cap_ends=True, segments=12, radius1=1, radius2=1 if z0 > 0 else 0.8, depth=1)
        for v in cyl["verts"]:
            v.co = Vector((v.co.x * sx, v.co.y * sy, (z0 + z1) / 2 + v.co.z * (z1 - z0)))
    return new_obj("PIPE_katana_fittings", bm)


# ---------- fourreau (saya) laque noir : tube courbe qui suit la lame ----------
def saya():
    bm = bmesh.new()
    S, N = 10, 24
    L = L_BLADE + 0.12
    rings = []
    for i in range(N + 1):
        s = i / N
        z = 0.49 + L * s
        cx = curve_x(min(1, s * L / L_BLADE)) + 0.0
        sc = 1 - 0.18 * s
        ring = [bm.verts.new((cx + 0.115 * sc * math.cos(2 * math.pi * j / S), 0.062 * sc * math.sin(2 * math.pi * j / S), z)) for j in range(S)]
        rings.append(ring)
    for i in range(N):
        for j in range(S):
            j2 = (j + 1) % S
            bm.faces.new((rings[i][j], rings[i][j2], rings[i + 1][j2], rings[i + 1][j]))
    bm.faces.new(rings[0][::-1]); bm.faces.new(rings[-1])
    # kojiri (embout) et koiguchi (bague d'entree) legerement plus larges
    return new_obj("PIPE_katana_saya", bm)


objs = [blade(), handle(), fittings(), saya()]
info = {"note": "centres de boite englobante en repere ROBLOX (x, y, z) par rapport au centre de la poignee ; "
                "Roblox recentre chaque MeshPart sur sa boite englobante.", "parts": {}}
total = 0
for ob in objs:
    me = ob.data
    me.calc_loop_triangles()
    tris = len(me.loop_triangles)
    total += tris
    xs = [v.co.x for v in me.vertices]; ys = [v.co.y for v in me.vertices]; zs = [v.co.z for v in me.vertices]
    c = ((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, (min(zs) + max(zs)) / 2)
    size = (max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))
    info["parts"][ob.name] = {"tris": tris, "center_roblox": [round(c[0], 4), round(c[2], 4), round(-c[1], 4)],
                              "size_roblox": [round(size[0], 4), round(size[2], 4), round(size[1], 4)]}
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, ob.name + ".fbx"), use_selection=True,
                             axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL")
info["tris_total"] = total

# ---------- textures ----------
def save(name, img):
    h, w, _ = img.shape
    im = bpy.data.images.new(name, w, h, alpha=True)
    im.pixels = np.flipud(img).astype(np.float32).ravel()
    im.filepath_raw = os.path.join(OUT, name + ".png"); im.file_format = "PNG"; im.save()

# lame : u (largeur, 0 = tranchant) en X, v (longueur) en Y ; ligne de trempe (hamon) ondulee
H, W = 1024, 256
vv, uu = np.mgrid[0:H, 0:W].astype(np.float32)
u = uu / W; v = 1 - vv / H
rng = np.random.default_rng(3)
wave = 0.30 + 0.05 * np.sin(v * 70) + 0.025 * np.sin(v * 173 + 1.3) + 0.012 * np.sin(v * 411)
noise = rng.normal(0, 1, (H, W)).astype(np.float32)
for _ in range(3):
    noise = (noise + np.roll(noise, 1, 0) + np.roll(noise, -1, 0) + np.roll(noise, 1, 1) + np.roll(noise, -1, 1)) / 5
hamon = 1 / (1 + np.exp((u - wave - noise * 0.04) * 60))           # 1 = zone trempee (cote tranchant)
steel = 0.66 + 0.06 * noise + 0.04 * np.sin(v * 900) * 0.2
col = steel * (1 - hamon) + (0.88 + 0.04 * noise) * hamon
col = np.where(u < 0.035, 0.95, col)                                 # fil du tranchant brillant
col = np.where(u > 0.97, 0.52, col)                                  # dos plus sombre
blade_rgb = np.stack([col * 0.97, col * 0.99, col * 1.02], -1)
save("PIPE_katana_blade_color", np.concatenate([np.clip(blade_rgb, 0, 1), np.ones((H, W, 1))], -1))
save("PIPE_katana_blade_metal", np.concatenate([np.ones((64, 64, 3)), np.ones((64, 64, 1))], -1))
rough = np.clip(0.18 + 0.12 * (1 - hamon) + 0.03 * noise, 0, 1)
save("PIPE_katana_blade_rough", np.concatenate([np.repeat(rough[..., None], 3, -1), np.ones((H, W, 1))], -1))

# poignee : tressage en losanges (ito sombre) sur peau de raie claire (same)
HS = 512
yy, xx = np.mgrid[0:HS, 0:HS].astype(np.float32) / HS
d1 = np.abs(((xx * 4 + yy * 8) % 1) - 0.5)
d2 = np.abs(((xx * 4 - yy * 8) % 1) - 0.5)
band = np.minimum(d1, d2)
ito = 1 / (1 + np.exp((band - 0.30) * 40))                            # 1 = cordon (losanges clairs entre les croisements)
grain = np.random.default_rng(5).normal(0, 0.03, (HS, HS))
same = np.stack([0.86 + grain, 0.84 + grain, 0.78 + grain], -1)
cord = np.stack([0.10 + grain + 0.04 * np.sin(xx * 200), 0.09 + grain, 0.12 + grain], -1)
hc = same * (1 - ito[..., None]) + cord * ito[..., None]
save("PIPE_katana_handle_color", np.concatenate([np.clip(hc, 0, 1), np.ones((HS, HS, 1))], -1))

with open(os.path.join(OUT, "katana_info.json"), "w", encoding="utf-8") as fh:
    json.dump(info, fh, indent=1)
print("KATANA_DONE", json.dumps(info))
