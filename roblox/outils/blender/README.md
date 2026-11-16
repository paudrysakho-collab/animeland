# Scripts Blender de la mission combat (copie de `pipeline-anim/scripts`)

Blender 4.5 en ligne de commande : `blender -b --python <script>.py`. Les sorties vont dans `pipeline-anim/` (pas dans ce dépôt) ;
les données utiles au jeu sont copiées dans `donnees/`.

| Script | Rôle |
|---|---|
| `braise.py` | Sabre « Braise » : nouvelle garde en volutes de flamme (ajourée, asymétrique) + textures (lame acier sombre avec gravures rouge braise, poignée tressée rouge sombre, garde or-orange patiné). La lame et la poignée gardent la géométrie du katana (`katana.py`). |
| `rodeur.py` | Monstre « Rôdeur de cendre » : 19 pièces rigides aux noms R15 (+ griffes, cheveux, yeux), 4 732 triangles ; écrit `rodeur_rig.json` (centres, articulations, Motor6D) et un .blend avec armature pour animer. |
| `anim_lib.py` | Bibliothèque de poses clés (anticipation, accélération, impact, récupération) : courbe d'ease, tremblement, visée de la lame, marqueurs. Écrit les images (JSON), le .blend animé et la séquence compacte pour Studio (`donnees/seq`). |
| `anims_rodeur.py` | Les 6 animations du monstre : attente, marche, course, griffe (marqueurs Depart 0,6 s / Contact 0,7 s), choc, projeté. |
| `verif_pose.py` | Vérifie par le calcul où sont les membres (repère du personnage) à des temps donnés. |
| `apercu_objet.py`, `apercu_anim.py` | Rendus d'aperçu (Workbench) d'un modèle ou d'une animation. |

Dans Studio : `ServerStorage.PipelineAnims.ConstructeurSequences` construit une KeyframeSequence (avec ses KeyframeMarker)
à partir d'un fichier de `donnees/seq` ; `ServerStorage.PipelineAnims.AppliquerConsignes` applique les fichiers de
`mission/consignes` (même effet que `appliquer.py` côté dépôt), puis on compare les sommes des deux côtés.
