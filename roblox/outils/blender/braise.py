# Mission combat, etape 3 - Sabre « Braise » (design original), Blender 4.5 -b
# Usage : blender -b --python braise.py
# Part du katana (scripts/katana.py) : meme lame et meme poignee (geometrie deja dans Roblox),
# NOUVELLE garde en volutes de flamme stylisees, asymetriques (orange-or patine), nouvelles textures :
#   lame acier sombre + fines gravures rouge braise pres de la garde ; poignee tressee rouge sombre ; garde patinee.
# Meme repere que katana.py : +Z Blender = +Y Roblox (le long de la lame), origine = centre de la poignee.
# Sorties : 05_vfx/braise/PIPE_braise_fittings.fbx, textures PNG, braise_info.json
import bpy, bmesh, os, math, json
import numpy as np
from mathutils import Vector

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(BASE, "05_vfx", "braise")
os.makedirs(OUT, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)


def new_obj(name, bm):
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me); bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    return ob


# ---------- contour de la garde : langues de flamme qui s'enroulent ----------
# r(a) = rayon de base + langues de flamme ; chaque langue est decalee en angle selon sa hauteur (enroulement),
# 7 langues de tailles differentes, plus grandes du cote du dos de la lame (+X) : asymetrie voulue.
TONGUES = [  # (angle centre en degres, hauteur, largeur en degres, enroulement en degres)
    (8, 0.105, 34, 16), (58, 0.070, 28, -12), (104, 0.050, 24, 10), (152, 0.082, 30, -14),
    (205, 0.045, 22, 9), (252, 0.064, 26, -11), (306, 0.092, 32, 15)]
R0 = 0.185


def flame_r(a_deg):
    r = R0
    for (c, h, w, sw) in TONGUES:
        d = ((a_deg - c + 180) % 360) - 180
        u = d / (w / 2)
        if abs(u) < 1:
            # profil de langue pointue et dissymetrique (un flanc raide, un flanc doux, selon le sens d'enroulement)
            k = (1 - abs(u)) ** (1.6 if (u * sw) > 0 else 0.9)
            r = max(r, R0 + h * k)
    return r


def guard_outline(n=180):
    pts = []
    for i in range(n):
        a = 360 * i / n
        r = flame_r(a)
        # enroulement : plus on s'eloigne du centre, plus le point tourne (volute)
        twist = 0.0
        for (c, h, w, sw) in TONGUES:
            d = ((a - c + 180) % 360) - 180
            if abs(d) < w / 2:
                twist += sw * max(0, (r - R0) / h) ** 2 * (1 - abs(d) / (w / 2))
        aa = math.radians(a + twist)
        pts.append((r * math.cos(aa), r * math.sin(aa) * 0.92))
    return pts


def plate(bm, outline, r_in, z0, z1, inner_scale=None):
    """Anneau plein entre un trou elliptique (r_in) et le contour ; extrude de z0 a z1."""
    n = len(outline)
    top_o, top_i, bot_o, bot_i = [], [], [], []
    for i, (x, y) in enumerate(outline):
        a = math.atan2(y / 0.92, x)
        xi, yi = r_in * math.cos(a), r_in * math.sin(a) * 0.92
        bot_o.append(bm.verts.new((x, y, z0))); top_o.append(bm.verts.new((x, y, z1)))
        bot_i.append(bm.verts.new((xi, yi, z0))); top_i.append(bm.verts.new((xi, yi, z1)))
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((top_i[i], top_o[i], top_o[j], top_i[j]))       # dessus
        bm.faces.new((bot_i[j], bot_o[j], bot_o[i], bot_i[i]))       # dessous
        bm.faces.new((bot_o[i], bot_o[j], top_o[j], top_o[i]))       # bord exterieur
        bm.faces.new((top_i[i], top_i[j], bot_i[j], bot_i[i]))       # bord du trou


def band(bm, outline, thick, z0, z1):
    """Bandeau qui suit le contour (largeur thick vers l'interieur) : la garde est ajouree."""
    n = len(outline)
    top_o, top_i, bot_o, bot_i = [], [], [], []
    for (x, y) in outline:
        r = math.hypot(x, y); k = max(0.2, (r - thick) / r)
        bot_o.append(bm.verts.new((x, y, z0))); top_o.append(bm.verts.new((x, y, z1)))
        bot_i.append(bm.verts.new((x * k, y * k, z0))); top_i.append(bm.verts.new((x * k, y * k, z1)))
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((top_i[i], top_o[i], top_o[j], top_i[j]))
        bm.faces.new((bot_i[j], bot_o[j], bot_o[i], bot_i[i]))
        bm.faces.new((bot_o[i], bot_o[j], top_o[j], top_o[i]))
        bm.faces.new((top_i[i], top_i[j], bot_i[j], bot_i[i]))


def volute(bm, a0, curl, r0, r1, w0, w1, z0, z1, n=14):
    """Branche courbe (flamme qui s'enroule) du moyeu vers le bandeau."""
    L = []
    for i in range(n + 1):
        t = i / n
        r = r0 + (r1 - r0) * t
        a = math.radians(a0 + curl * t ** 1.5)
        w = w0 + (w1 - w0) * t
        c = Vector((r * math.cos(a), r * math.sin(a) * 0.92, 0))
        tg = Vector((-math.sin(a), math.cos(a), 0))
        L.append([bm.verts.new((c + tg * s * w / 2).to_tuple()[:2] + (z,)) for (s, z) in ((-1, z0), (1, z0), (1, z1), (-1, z1))])
    for i in range(n):
        A, B = L[i], L[i + 1]
        for q in range(4):
            q2 = (q + 1) % 4
            bm.faces.new((A[q], B[q], B[q2], A[q2]))
    bm.faces.new(L[0][::-1]); bm.faces.new(L[-1])


def fittings():
    bm = bmesh.new()
    zt0, zt1 = 0.45, 0.49
    outline = guard_outline()
    band(bm, outline, 0.042, zt0, zt1)                            # bandeau en langues de flamme
    plate(bm, [(0.112 * math.cos(2 * math.pi * i / 40), 0.112 * math.sin(2 * math.pi * i / 40) * 0.92) for i in range(40)],
          0.075, zt0 - 0.004, zt1 + 0.004)                       # moyeu
    # 5 branches en volute, espacements inegaux (asymetrie), toutes enroulees dans le meme sens
    for (a0, curl) in ((20, 70), (95, 55), (160, 75), (230, 60), (300, 65)):
        volute(bm, a0, curl, 0.105, R0 - 0.015, 0.034, 0.016, zt0 + 0.004, zt1 - 0.004)
    # habaki (collier de lame), fuchi (bague), kashira (pommeau) : comme le katana
    hb = bmesh.ops.create_cube(bm, size=1.0)
    for v in hb["verts"]:
        v.co = Vector((v.co.x * 0.22, v.co.y * 0.085, 0.49 + (v.co.z + 0.5) * 0.11))
    for (z0, z1, sx, sy) in ((0.40, 0.45, 0.07, 0.055), (-0.52, -0.45, 0.068, 0.053)):
        cyl = bmesh.ops.create_cone(bm, cap_ends=True, segments=12, radius1=1, radius2=1 if z0 > 0 else 0.8, depth=1)
        for v in cyl["verts"]:
            v.co = Vector((v.co.x * sx, v.co.y * sy, (z0 + z1) / 2 + v.co.z * (z1 - z0)))
    # UV : projection a plat (x, y) -> la patine suit le dessin de la garde
    uv = bm.loops.layers.uv.new("UVMap")
    for f in bm.faces:
        for lp in f.loops:
            co = lp.vert.co
            lp[uv].uv = (co.x / 0.62 + 0.5, co.y / 0.62 + 0.5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return new_obj("PIPE_braise_fittings", bm)


ob = fittings()
me = ob.data
me.calc_loop_triangles()
xs = [v.co.x for v in me.vertices]; ys = [v.co.y for v in me.vertices]; zs = [v.co.z for v in me.vertices]
c = ((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2, (min(zs) + max(zs)) / 2)
size = (max(xs) - min(xs), max(ys) - min(ys), max(zs) - min(zs))
info = {"note": "repere ROBLOX, par rapport au centre de la poignee (meme convention que katana_info.json)",
        "fittings": {"tris": len(me.loop_triangles), "center_roblox": [round(c[0], 4), round(c[2], 4), round(-c[1], 4)],
                     "size_roblox": [round(size[0], 4), round(size[2], 4), round(size[1], 4)]}}
bpy.ops.object.select_all(action="DESELECT")
ob.select_set(True)
bpy.context.view_layer.objects.active = ob
bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, ob.name + ".fbx"), use_selection=True,
                         axis_forward="-Z", axis_up="Y", apply_scale_options="FBX_SCALE_ALL")


# ---------- textures ----------
def save(name, rgb):
    h, w, _ = rgb.shape
    img = np.concatenate([np.clip(rgb, 0, 1), np.ones((h, w, 1))], -1)
    im = bpy.data.images.new(name, w, h, alpha=True)
    im.pixels = np.flipud(img).astype(np.float32).ravel()
    im.filepath_raw = os.path.join(OUT, name + ".png"); im.file_format = "PNG"; im.save()


def blur(a, n):
    for _ in range(n):
        a = (a + np.roll(a, 1, 0) + np.roll(a, -1, 0) + np.roll(a, 1, 1) + np.roll(a, -1, 1)) / 5
    return a


# Lame : meme UV que katana.py (u : 0 = tranchant, 1 = dos ; v : 0 = garde, 1 = pointe)
H, W = 1024, 256
vv, uu = np.mgrid[0:H, 0:W].astype(np.float32)
u = uu / W; v = 1 - vv / H
rng = np.random.default_rng(11)
noise = blur(rng.normal(0, 1, (H, W)).astype(np.float32), 3)
wave = 0.26 + 0.03 * np.sin(v * 55) + 0.015 * np.sin(v * 160 + 0.7)
hamon = 1 / (1 + np.exp((u - wave - noise * 0.03) * 70))
steel = 0.20 + 0.035 * noise + 0.02 * np.sin(v * 700) * 0.3        # acier sombre (bleui)
col = steel * (1 - hamon) + (0.40 + 0.03 * noise) * hamon           # zone trempee un peu plus claire
col = np.where(u < 0.03, 0.62, col)                                  # fil du tranchant
rgb = np.stack([col * 0.95, col * 0.98, col * 1.06], -1)
# gravures : fines lignes de flamme qui montent depuis la garde (v < 0.24), sur le plat du dos (u 0.45 a 0.95)
eng = np.zeros((H, W), np.float32)
for k, (u0, amp, fr, ph, top) in enumerate([(0.58, 0.05, 38, 0.0, 0.22), (0.72, 0.04, 44, 1.7, 0.18),
                                           (0.86, 0.03, 52, 3.1, 0.13), (0.65, 0.025, 70, 4.4, 0.10)]):
    cu = u0 + amp * np.sin(v * fr + ph) * (v / top)                 # ligne qui ondule de plus en plus
    width = 0.010 * (1 - np.clip(v / top, 0, 1)) + 0.002
    line = np.exp(-((u - cu) / width) ** 2) * (v < top) * (v > 0.012)
    eng = np.maximum(eng, line)
eng = np.clip(eng * 1.4, 0, 1)
ember = np.stack([0.62 + 0 * u, 0.10 + 0 * u, 0.04 + 0 * u], -1)   # rouge braise
rgb = rgb * (1 - eng[..., None]) + ember * eng[..., None]
save("PIPE_braise_blade_color", rgb)
rough = np.clip(0.22 + 0.10 * (1 - hamon) + 0.03 * noise + 0.35 * eng, 0, 1)
save("PIPE_braise_blade_rough", np.repeat(rough[..., None], 3, -1))

# Poignee : meme UV que katana.py ; cordon rouge sombre sur sous-couche noire
HS = 512
yy, xx = np.mgrid[0:HS, 0:HS].astype(np.float32) / HS
d1 = np.abs(((xx * 4 + yy * 8) % 1) - 0.5)
d2 = np.abs(((xx * 4 - yy * 8) % 1) - 0.5)
band = np.minimum(d1, d2)
ito = 1 / (1 + np.exp((band - 0.30) * 40))
grain = np.random.default_rng(5).normal(0, 0.02, (HS, HS))
under = np.stack([0.06 + grain, 0.05 + grain, 0.05 + grain], -1)
cord = np.stack([0.36 + grain + 0.05 * np.sin(xx * 220), 0.06 + grain, 0.05 + grain], -1)
save("PIPE_braise_handle_color", under * (1 - ito[..., None]) + cord * ito[..., None])

# Garde : or orange patine ; plus sombre et brunie dans le creux (pres du centre et entre les langues)
G = 512
gy, gx = np.mgrid[0:G, 0:G].astype(np.float32)
px = (gx / G - 0.5) * 0.62; py = (0.5 - gy / G) * 0.62
rr = np.sqrt(px ** 2 + (py / 0.92) ** 2)
gn = blur(np.random.default_rng(8).normal(0, 1, (G, G)).astype(np.float32), 4)
edge = np.clip((rr - 0.15) / 0.12, 0, 1)                          # bords des langues plus brillants (usure)
patina = 0.55 + 0.25 * edge + 0.08 * gn
gold = np.stack([0.80 * patina, 0.46 * patina, 0.18 * patina], -1)
dark = np.clip(1 - edge * 1.5, 0, 1)[..., None] * 0.25
save("PIPE_braise_fittings_color", gold * (1 - dark))
save("PIPE_braise_fittings_rough", np.repeat(np.clip(0.55 - 0.25 * edge + 0.05 * gn, 0, 1)[..., None], 3, -1))

with open(os.path.join(OUT, "braise_info.json"), "w", encoding="utf-8") as fh:
    json.dump(info, fh, indent=1)
print("BRAISE_DONE", json.dumps(info))
