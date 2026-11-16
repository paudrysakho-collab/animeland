# Etape 9 - Genere ReplicatedStorage/Magicaland/EpeeDonnees.lua (donnees partagees client/serveur du style epee)
# Usage : python gen_epee_donnees.py   (ou blender -b --python gen_epee_donnees.py)
# Animations "sur place" : le deplacement horizontal de la racine (x, z) est retire de l'animation et applique au
# HumanoidRootPart par le client ; la lame est donc exprimee dans le repere du HRP SANS ce deplacement.
import json, os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO = os.path.join(os.path.dirname(BASE), "animeland", "roblox", "src", "ReplicatedStorage", "Magicaland", "EpeeDonnees.lua")
# Retours du 16/11 : les coups Mixamo sont remplaces par 5 coups DESSINES A LA MAIN (anims_combo.py), un par forme.
# Les deux combos utilisent les memes 5 coups ; seule la fin change (Epeiste : projete en arriere, avance : en l'air).
COUPS_MAIN = ["coup_montant", "coup_horizontal", "coup_descendant", "coup_estoc", "coup_tourbillon"]
COMBOS = {
    "Epeiste": COUPS_MAIN,
    "EpeisteAvance": COUPS_MAIN,
}
# Fenetre de touche imposee quand celle trouvee par blade_data ne tombe pas sur le vrai coup (finale : coupe face a la cible)
FENETRES = {"coup_tourbillon": {"start": 0.400, "end": 0.500}}
MULTS = {"Epeiste": [0.8, 0.9, 1.0, 1.1, 1.7], "EpeisteAvance": [0.95, 1.05, 1.15, 1.25, 2.0]}
TAIL, CHAIN_EXTRA = 0.15, 0.25


def load(name):
    full = name if name.startswith(("ult_", "coup_")) else "sword_and_shield_" + name
    fr = json.load(open(os.path.join(BASE, "03_retarget", full + "_R15_frames.json"), encoding="utf-8"))
    bl = json.load(open(os.path.join(BASE, "04_roblox", full + "_blade.json"), encoding="utf-8"))
    root = [f["motors"]["Root"]["pos"] for f in fr["frames"]]
    return fr, bl, root


def r3(v):
    return "%.3f" % v


lines = ["-- GENERE par pipeline-anim/scripts/gen_epee_donnees.py : ne pas modifier a la main.",
         "-- Style epee (combos Epeiste / Epeiste avance + ultime Couronne de l'Aube), partage client / serveur.",
         "-- lame : images de la fenetre de touche {t, base x,y,z, pointe x,y,z} dans le repere du HumanoidRootPart (studs),",
         "--        animation SUR PLACE (le deplacement horizontal de la racine est applique au HRP par le client).",
         "-- racine : deplacement horizontal cumule de la racine, une paire (x, z) par image a 30 i/s (repere du HRP de depart).",
         "local D = {}", "D.fps = 30", "D.FONDU = 0.08", "D.RESET = 1.2", "D.coups = {}", ""]
for combo, moves in COMBOS.items():
    for i, mv in enumerate(moves):
        fr, bl, root = load(mv)
        n = len(fr["frames"])
        length = (n - 1) / 30
        hw = FENETRES.get(mv, bl["hit_window"])
        final = (i == len(moves) - 1)
        cut = length if final else min(length, hw["end"] + TAIL)
        key = "%s_%d" % (combo, i + 1)
        r0 = root[0]
        lame = []
        for f, rp in zip(bl["frames"], root):
            t = f[0]
            if hw["start"] - 1e-6 <= t <= hw["end"] + 1e-6:
                b, p = f[1], f[2]
                dx, dz = rp[0] - r0[0], rp[2] - r0[2]
                lame.append("{%s, %s,%s,%s, %s,%s,%s}" % (r3(t), r3(b[0] - dx), r3(b[1]), r3(b[2] - dz), r3(p[0] - dx), r3(p[1]), r3(p[2] - dz)))
        nr = int(round(cut * 30)) + 1
        rac = []
        for rp in root[:nr]:
            rac += [r3(rp[0] - r0[0]), r3(rp[2] - r0[2])]
        lines.append('D.coups["%s"] = {seq = "%s", nom = "%s", longueur = %s, touche = {%s, %s}, coupe = %s, enchainement = {%s, %s}, mult = %s, final = %s, contact = %s,'
                     % (key, ("PIPE_" + mv) if mv.startswith("coup_") else ("PIPE_sword_" + mv), mv, r3(length), r3(hw["start"]), r3(hw["end"]), r3(cut), r3(hw["end"]), r3(cut + CHAIN_EXTRA),
                        MULTS[combo][i], "true" if final else "false", "true" if mv == "kick" else "false"))
        lines.append("\tlame = {" + ", ".join(lame) + "},")
        lines.append("\tracine = {" + ", ".join(rac) + "}}")
    lines.append('D["%s"] = {%s}' % (combo, ", ".join('"%s_%d"' % (combo, k + 1) for k in range(len(moves)))))
    lines.append("")

# ultime : coups en eventail (images de lame autour de chaque instant) + frappe au sol
fr, bl, root = load("ult_01")
n = len(fr["frames"])
r0 = root[0]
FAN = [1.78, 2.03, 2.27]
lame = []
for f, rp in zip(bl["frames"], root):
    t = f[0]
    if any(abs(t - x) <= 0.07 for x in FAN):
        b, p = f[1], f[2]
        dx, dz = rp[0] - r0[0], rp[2] - r0[2]
        lame.append("{%s, %s,%s,%s, %s,%s,%s}" % (r3(t), r3(b[0] - dx), r3(b[1]), r3(b[2] - dz), r3(p[0] - dx), r3(p[1]), r3(p[2] - dz)))
rac = []
for rp in root:
    rac += [r3(rp[0] - r0[0]), r3(rp[2] - r0[2])]
lines.append('D.ultime = {seq = "PIPE_ult_01", longueur = %s, eventail = {%s}, multEventail = 1.0, sol = 3.1, multSol = 6.0, rayonSol = 14,'
             % (r3((n - 1) / 30), ", ".join(r3(x) for x in FAN)))
lines.append("\tlame = {" + ", ".join(lame) + "},")
lines.append("\tracine = {" + ", ".join(rac) + "}}")
lines.append("")
lines.append("return D")
os.makedirs(os.path.dirname(REPO), exist_ok=True)
with open(REPO, "w", encoding="utf-8", newline="\n") as fh:
    fh.write("\n".join(lines) + "\n")
print("EPEE_DONNEES_OK", REPO, os.path.getsize(REPO))
