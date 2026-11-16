# Bibliotheque d'animation par poses cles (mission combat). Generalise scripts/ultime_01.py.
# Un script d'animation (ex. anims_rodeur.py) fait :
#   A = Anim("rodeur_marche", rig="rodeur", duree=1.0, boucle=True)
#   A.key(t, {"LeftHip": (x, y, z), ...}, root=(x, y, z), root_rot=(x, y, z), ease=3, lame=None)
#   A.marker("Contact", t)
#   A.build()  -> 03_retarget/<nom>_frames.json, 04_roblox/seq/<nom>.json (compact, pour Studio), 03_retarget/<nom>.blend
# Conventions (repere Roblox, rotations des Motor6D en degres X, Y, Z, ordre CFrame.fromEulerAnglesXYZ) :
#   bras / jambes qui pendent : +X = lever vers l'avant ; bras droit +Z = ecarter sur le cote (bras gauche : -Z)
#   buste (Waist) / Root : -X = pencher en avant, +X = se cambrer ; Y = torsion (+Y = tourner vers la gauche)
#   genou : -X = plier ; coude : +X = plier ; Neck : -X = baisser la tete
# Interpolation entre deux cles : u -> 1 - (1 - u)^ease (ease = 1 lineaire, 3-7 = depart brusque, fin amortie),
# ou ease negatif : u^|ease| (depart lent = anticipation, fin brusque = acceleration vers l'impact).
import bpy, os, json, math, random
from mathutils import Matrix, Vector, Quaternion, Euler

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RIGS = {
    "r15": os.path.join(BASE, "02_extraction", "r15_rig.json"),
    "rodeur": os.path.join(BASE, "05_vfx", "rodeur", "rodeur_rig.json"),
}
BLENDS = {
    "r15": os.path.join(BASE, "03_retarget", "sword_and_shield_attack_4_R15.blend"),
    "rodeur": os.path.join(BASE, "03_retarget", "rodeur_rig.blend"),
}
GF = json.load(open(os.path.join(BASE, "04_roblox", "grip_fixed.json"), encoding="utf-8"))
SEQ_OUT = os.path.join(BASE, "04_roblox", "seq")
os.makedirs(SEQ_OUT, exist_ok=True)


def E(x=0, y=0, z=0):
    return Euler((math.radians(x), math.radians(y), math.radians(z)), "XYZ").to_quaternion()


def V(x, y, z):
    return Vector((x, y, z)).normalized()


def T(v):
    return Matrix.Translation(Vector(v))


def _grip():
    g = (Matrix.Rotation(math.radians(GF["tilt_z_deg"]), 4, "Z") @ Matrix.Rotation(math.radians(GF["base_deg"] + GF["tilt_x_deg"]), 4, "X")
         @ Matrix.Rotation(math.radians(GF["roll_deg"]), 4, "Y"))
    return (g.to_3x3() @ Vector((0, 1, 0))).normalized()


BLADE_LOCAL = _grip()


class Anim:
    def __init__(self, nom, rig="r15", duree=1.0, boucle=False, fps=30, priorite="Action", tremble=None, sur_place=False):
        # sur_place : la sequence Roblox garde seulement la hauteur de la racine ; le deplacement horizontal (x, z) est
        # applique au HumanoidRootPart par le jeu (coups du combo : EpeeDonnees.racine). Les images JSON le gardent.
        self.nom, self.rig_name, self.duree, self.boucle, self.fps, self.priorite = nom, rig, duree, boucle, fps, priorite
        self.sur_place = sur_place
        self.rig = json.load(open(RIGS[rig], encoding="utf-8"))
        self.motors = self.rig["motors"]
        self.order = [m["name"] for m in self.motors]
        self.mot = {m["name"]: m for m in self.motors}
        self.keys, self.markers = [], []
        self.tremble = tremble  # (t0, t1, amplitude en degres) : tremblement lisse (charge)

    def key(self, t, joints, root=(0, 0, 0), root_rot=None, ease=3, lame=None):
        j = dict(joints)
        if root_rot is not None:
            j["Root"] = root_rot
        self.keys.append({"t": t, "j": j, "rp": Vector(root), "ease": ease, "blade": lame})

    def marker(self, nom, t, valeur=""):
        self.markers.append({"nom": nom, "t": t, "valeur": valeur})

    # cinematique directe (Roblox) : partie -> matrice monde (espace HRP)
    def fk(self, rot, root_pos):
        W = {"HumanoidRootPart": Matrix.Identity(4)}
        for m in self.motors:
            q = rot.get(m["name"], Quaternion())
            tr = q.to_matrix().to_4x4()
            if m["name"] == "Root":
                tr = T(root_pos) @ tr
            W[m["part1"]] = W[m["part0"]] @ T(m["c0_pos"]) @ tr @ T(m["c1_pos"]).inverted()
        return W

    def solve_wrist(self, rot, root_pos, blade_dir):
        W = self.fk(rot, root_pos)
        me = self.mot["RightWrist"]
        parent = W["RightLowerArm"] @ T(me["c0_pos"])
        target = parent.to_3x3().inverted() @ blade_dir
        return BLADE_LOCAL.rotation_difference(target.normalized())

    def _ease(self, u, p):
        if p < 0:
            return u ** (-p)
        return 1 - (1 - u) ** p

    def build(self, blend=True):
        keys = sorted(self.keys, key=lambda k: k["t"])
        for k in keys:
            rot = {n: E(*v) for n, v in k["j"].items()}
            if k["blade"] is not None:
                rot["RightWrist"] = self.solve_wrist(rot, k["rp"], k["blade"])
            k["q"] = rot
        random.seed(len(self.nom))
        nf = int(round(self.duree * self.fps)) + 1
        noise = {n: [Vector((random.uniform(-1, 1), random.uniform(-1, 1), random.uniform(-1, 1))) for _ in range(nf + 2)] for n in self.order}
        frames = []
        for fi in range(nf):
            t = fi / self.fps
            k1 = max([i for i, k in enumerate(keys) if k["t"] <= t + 1e-9] or [0])
            k2 = min(k1 + 1, len(keys) - 1)
            a, b = keys[k1], keys[k2]
            u = 0 if k2 == k1 else (t - a["t"]) / (b["t"] - a["t"])
            w = self._ease(min(max(u, 0), 1), b["ease"])
            rp = a["rp"].lerp(b["rp"], w)
            mot = {}
            for n in self.order:
                qa, qb = a["q"].get(n, Quaternion()), b["q"].get(n, Quaternion())
                q = qa.slerp(qb, w)
                if self.tremble and self.tremble[0] <= t <= self.tremble[1]:
                    amp = math.radians(self.tremble[2]) * (t - self.tremble[0]) / max(1e-6, self.tremble[1] - self.tremble[0])
                    nv = noise[n][fi] * 0.6 + noise[n][max(0, fi - 1)] * 0.4
                    q = q @ Euler((nv.x * amp, nv.y * amp, nv.z * amp), "XYZ").to_quaternion()
                mot[n] = {"q": q, "pos": rp.copy() if n == "Root" else Vector((0, 0, 0))}
            frames.append({"t": t, "m": mot})
        self.frames = frames
        self._write_json()
        self._write_seq()
        if blend:
            self._write_blend()
        print("ANIM_OK", self.nom, nf, "images", "marqueurs", [(m["nom"], round(m["t"], 3)) for m in self.markers])
        return self

    def _write_json(self):
        out = {"source": "anim_lib.py (poses cles)", "rig": self.rig_name, "fps": float(self.fps), "nb_frames": len(self.frames),
               "motors_order": self.order, "markers": self.markers,
               "frames": [{"frame": i + 1, "time": round(f["t"], 6),
                           "motors": {n: {"pos": [round(x, 5) for x in f["m"][n]["pos"]],
                                          "rot": [round(f["m"][n]["q"].to_matrix()[r][c], 6) for r in range(3) for c in range(3)]}
                                      for n in self.order}} for i, f in enumerate(self.frames)]}
        with open(os.path.join(BASE, "03_retarget", self.nom + "_frames.json"), "w", encoding="utf-8") as fh:
            json.dump(out, fh)
        # meme contenu sous le nom lu par blade_data.py (lame image par image, fenetre de touche, lame dans le corps)
        with open(os.path.join(BASE, "03_retarget", self.nom + "_R15_frames.json"), "w", encoding="utf-8") as fh:
            json.dump(out, fh)

    def _write_seq(self):
        # Format compact pour Studio (module ConstructeurSequences) : les POSES CLES seulement (poignet deja resolu),
        # Studio refait la meme interpolation (slerp + meme courbe d'ease) image par image.
        # cle = [t, ease, qx,qy,qz,qw (x nb moteurs, ordre motors), px,py,pz (Root)]
        keys = []
        for k in sorted(self.keys, key=lambda k: k["t"]):
            row = [round(k["t"], 4), k["ease"]]
            for n in self.order:
                q = k["q"].get(n, Quaternion())
                row += [round(q.x, 4), round(q.y, 4), round(q.z, 4), round(q.w, 4)]
            if self.sur_place:
                row += [0.0, round(k["rp"].y, 3), 0.0]
            else:
                row += [round(k["rp"].x, 3), round(k["rp"].y, 3), round(k["rp"].z, 3)]
            keys.append(row)
        seq = {"nom": "PIPE_" + self.nom, "boucle": self.boucle, "priorite": self.priorite, "fps": self.fps, "duree": self.duree,
               "parts": [[m["part1"], m["part0"]] for m in self.motors], "tremble": self.tremble,
               "markers": [[m["nom"], round(m["t"], 4), m["valeur"]] for m in self.markers], "keys": keys}
        with open(os.path.join(SEQ_OUT, "PIPE_" + self.nom + ".json"), "w", encoding="utf-8") as fh:
            json.dump(seq, fh, separators=(",", ":"))

    def _write_blend(self):
        bpy.ops.wm.open_mainfile(filepath=BLENDS[self.rig_name])
        if self.rig_name == "r15":
            for o in list(bpy.data.objects):
                if o.name != "R15" and not (o.parent and o.parent.name == "R15"):
                    bpy.data.objects.remove(o, do_unlink=True)
            arm = bpy.data.objects["R15"]
            arm.location = (0, 0, arm.location.z)
            C = Matrix(((-1, 0, 0), (0, 0, 1), (0, 1, 0)))
        else:
            arm = bpy.data.objects["Rodeur"]
            C = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
        if arm.animation_data:
            arm.animation_data_clear()
        arm.animation_data_create()
        act = bpy.data.actions.new(self.nom); act.use_fake_user = True
        arm.animation_data.action = act
        sc = bpy.context.scene
        sc.render.fps = self.fps
        sc.frame_start, sc.frame_end = 1, len(self.frames)
        for m in self.markers:  # marqueurs aussi dans la timeline Blender
            sc.timeline_markers.new(m["nom"], frame=int(round(m["t"] * self.fps)) + 1)
        part_of = {m["name"]: m["part1"] for m in self.motors}
        prev = {}
        for fi, f in enumerate(self.frames):
            for n in self.order:
                bone = part_of[n]
                if bone not in arm.pose.bones:
                    continue
                Bm = arm.data.bones[bone].matrix_local.to_3x3()
                Rt = f["m"][n]["q"].to_matrix()
                basis = (Bm.inverted() @ (C @ Rt @ C.transposed()) @ Bm).to_quaternion()
                if bone in prev:
                    basis.make_compatible(prev[bone])
                prev[bone] = basis
                pb = arm.pose.bones[bone]
                pb.rotation_mode = "QUATERNION"
                pb.rotation_quaternion = basis
                pb.keyframe_insert("rotation_quaternion", frame=fi + 1)
                if n == "Root":
                    pb.location = Bm.inverted() @ (C @ f["m"][n]["pos"])
                    pb.keyframe_insert("location", frame=fi + 1)
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(BASE, "03_retarget", self.nom + ".blend"))
