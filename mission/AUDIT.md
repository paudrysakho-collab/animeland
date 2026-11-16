# Étape 0 : audit (16/11/2026)

Vérifié concrètement sur le PC, pas de mémoire.

## Outils

| Outil | État réel | Ce qu'il permet pour la mission |
|---|---|---|
| **Higgsfield CLI** | Installé (`higgsfield` 1.2.2, du 16/10/2026), connecté, offre « plus », **368,85 crédits**. | Voir le détail ci-dessous. |
| Higgsfield **Character Animation** | **N'existe pas** dans la liste des modèles (118 modèles listés). | Rien. |
| Higgsfield **3D Model** | Oui : Meshy 6 (texte → 3D, 25 crédits), Meshy 7 (image → 3D, avec option rig + PBR), Hunyuan 3D 3.1 (7 crédits), Tripo (5 crédits), Tripo H3.1 image → 3D, Multi-image → 3D, Remesh, Retexture. | Base du monstre et du sabre, à reprendre dans Blender (topologie, poids, UV). |
| Higgsfield **3D Rigging** | Oui (`3d_rigging`, à partir d'un modèle .glb, avec une option « animation » qui choisit une animation **toute faite** dans une bibliothèque). Coût non estimable par la CLI. | Un rig de départ pour le monstre. Les animations toutes faites ne sont pas nos chorégraphies. |
| Higgsfield **3D Body** | Oui (`sam_3_3d_body`) : une image → un corps 3D + points clés 3D. | Possible aide pour poser une silhouette d'après une image de pose. À tester sur 1 image. |
| Higgsfield **Motion Control** | Oui, mais **en vidéo** (Kling 3.0 Motion Control, Genjutsu) : transfère un mouvement filmé sur une image. | Storyboard animé seulement. **Pas une animation 3D jouable.** |
| Higgsfield **Cinema Studio** | Oui, en vidéo (Cinema Studio 4.0, 3.5, 3.0) et en image. | Storyboards et références de caméra. |
| Higgsfield vidéo (coûts) | 5 s : Wan 2.6 = 7,5 crédits, Kling 3.0 = 10, Seedance 2.0 = 22,5. | Storyboards. |
| Higgsfield image / son | Image (nano banana 2) = 2 crédits. Son (Mirelo) = 0,5 crédit pour 2 s. | Planches de poses, textures, sons. |
| **Extension Blender de Higgsfield** | **Correction du 16/11 (étape 3)** : elle **existe** et elle est officielle (« Higgsfield for Blender », page higgsfield.ai/plugins/blender, éditeur Higgsfield). L'audit avait seulement regardé les modules installés dans Blender, pas le site : c'était une erreur. **Mais la page officielle exige Blender 5.1 ou plus** ; le PC a Blender 4.5.10. Une source tierce parle de 4.2 à 5.1, la page officielle ne cite pas la 4.5. La CLI 1.2.2 n'a aucune commande liée à Blender. **Rien n'a été installé.** Ce qu'elle annonce : une barre de commande dans la vue 3D (Scene Builder, 3D Model, **Character Animation** = « un rig pondéré et des clés sur la timeline », Image, Video, Camera, Asset), calcul en ligne avec les crédits Higgsfield, plus un pont MCP (bridge.higgsfield.ai/mcp). | Possible seulement en installant Blender 5.1 à côté de la 4.5 : décision à l'utilisateur (question posée dans `QUESTIONS.md`). Même alors, une animation générée resterait une base à retravailler : nos compétences demandent des poses clés précises et des marqueurs. |
| **yt-dlp** | Installé (2026.10.26), la recherche et le téléchargement marchent. | Recherche vidéo réelle (étape 1). |
| ffmpeg | Installé (9.0.2). | Extraction d'images. |
| **Blender** | 4.5.10 LTS, lancé en ligne de commande sans problème. Pipeline existant : Mixamo → R15 (`pipeline-anim/scripts`). | Monstre, sabre, toutes les animations. |
| **MCP Roblox Studio** | Connecté à la place 17290180195 (mode édition et Play, clavier, souris). Les captures d'écran restent blanches : je ne vois pas l'image du jeu. | Tests par les valeurs et les événements, pas à l'œil. |

## Le jeu (place 17290180195, version 81, et dépôt `animeland/roblox/src`)

| Partie | État | Pour la nouvelle structure |
|---|---|---|
| Attaques de base au sabre | 2 combos de 5 coups (Épéiste, Épéiste avancé), prédiction, arrêt sur image, impact frame au 5e coup, traînée blanche-bleue, éclairs bleus sur la lame. | À garder, plus rapides ; **retirer la traînée blanche et les éclairs bleus** ; effets de feu discrets. |
| Dash | Touche Q. Avant : 3 s de recharge, côté : 2 s. Quand on reste immobile, c'est toujours le dash avant, donc **un 2e appui dans les 3 s ne fait rien, sans aucun signal visible** (seulement un petit texte en bas). C'est la cause probable du « une fois sur deux ». | Priorité de l'étape 2. |
| Bloc, parade, garde | Faits à l'étape 10 (F). | Pas dans la liste de la mission (« rien de plus ») : **question posée** (Q12). Gardés en attendant. |
| Transformation (T) + jauge de transformation | Code serveur (aura, cristaux, apparence, épuisement) + bouton + jauge. | **À supprimer** (étape 2). |
| Éveil (G) | Code serveur + bouton + repère sur la jauge. | **À supprimer** (étape 2). |
| Barre d'ultime + « sabre doré » | Faits à l'étape 10. | **À supprimer** (étape 2). |
| Ultime « Couronne de l'Aube » (6 / V) | Animation PIPE_ult_01 + module Ultime01. | **Retiré du jeu jouable**, gardé comme matière (animation et effets). |
| Anciens sorts 1 à 6 (Frappe, Lance, Colonnes, Nova, Jugement, Boule suprême) | Système d'énergie (10 cases). Avec le sabre, la touche 6 lançait l'ultime. | Ne font pas partie de la structure finale. **Question** (Q11) : retirer tout de suite ou garder comme provisoires jusqu'à l'étape 4. |
| « Pas de l'Éclair » | Jamais implémenté (l'étape 12 n'a pas été faite). | Rien à retirer. |
| Monstre | Golem en blocs (rig R15 Roblox mis à l'échelle 1,7, pierres soudées) et boss Colosse. | À remplacer (étape 3). |
| Sabre | Katana Blender (lame 3,3 studs, 1 694 triangles), poignée tressée, fourreau. | Base de départ pour le nouveau sabre (étape 3). |
| Animations des coups | 10 attaques Mixamo converties en R15 + 1 ultime fait main. Animations de déplacement : celles de Roblox par défaut. | Les 6 compétences demandent de vraies animations faites dans Blender. |
| Décor | Dossier `Paysage` (1 435 objets, aucun MeshPart), zone de test (45 objets). | Hors de cette mission pour l'instant. |
| Performances | Studio tourne à environ 16 images/s pendant les tests (PC + Studio + outils) : mode allégé automatique. Après 52 coups + 10 ultimes : aucun objet restant. | À mesurer sur un vrai téléphone. |
| Réactivité | Le coup part dès le clic (prédiction). Touches confirmées par le serveur 10 à 40 ms après la fenêtre prévue. | OK. |
