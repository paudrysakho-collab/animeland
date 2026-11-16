# Combat au sabre : comment c'est fait

Jeu : « From Nothing: Reborn » (Roblox). État après l'étape 2 de la mission de refonte (`MISSION_COMBAT.md`, 16/11/2026).
Le serveur décide de tout (dégâts, recharges, garde, invulnérabilité). Le client demande, prédit et affiche.

**Retiré (étape 2)** : transformation (T), Éveil (G), jauge de transformation, barre d'ultime, mode « sabre doré », ultime
« Couronne de l'Aube » (son animation `PIPE_ult_01` et le module `Ultime01` restent comme matière), traînée blanche et éclairs bleus
des coups de base. Le « Pas de l'Éclair » n'a jamais été dans le jeu.

**Structure visée par la mission** : attaques de base au sabre, 3 attaques physiques, 2 magies offensives, 1 transformation
(la 3e magie) et le dash. Les 6 compétences ne sont pas encore faites (étapes 3 et 4, après les choix de l'utilisateur).

## Où est quoi

| Fichier (dans `roblox/src`) | Rôle |
|---|---|
| `ReplicatedStorage/Magicaland/EpeeReglages.lua` | **Tous les réglages** du sabre (durées, distances, vitesses, dash). Partagé client / serveur. |
| `ReplicatedStorage/Magicaland/EpeeDonnees.lua` | Données de chaque coup : animation, fenêtre de touche, lame image par image, dégâts. **Généré** par `pipeline-anim/scripts/gen_epee_donnees.py`. |
| `ReplicatedStorage/Magicaland/ProfilCombat.lua` | **Préparation** des 3 systèmes : style de combat, élément, capacité innée. Seule la palette du feu sert pour l'instant. |
| `ServerScriptService/Magicaland/Epee.lua` | Serveur : rythme du combo, balayage de la lame avec rembobinage, étourdissement, projections, bloc / parade, dash. |
| `ServerScriptService/Magicaland/Combat.lua` | Règles communes (dégâts, énergie, victoire, IA des ennemis), coups lourds signalés en rouge. |
| `StarterPlayerScripts/Magicaland/EpeeClient.lua` | Client : entrées, prédiction, animations, caméra, effets, interface du dash et de la garde, boutons tactiles. |
| `ReplicatedStorage/PIPE_Epee/FX.lua`, `RealFX.lua` | Effets réalistes (sans contour dessiné). Le ciel n'est jamais modifié. |

Commandes réseau (dossier `Remotes`) pour le sabre : `AttaquerEpee(k)`, `BlocEpee(vrai/faux)`, `DashEpee("avant"/"cote")`, et `EpeeFx`
(serveur → clients : effets). Chaque commande est vérifiée (type, état du joueur, rythme, distance) ; une demande invalide est ignorée.
Attributs posés par le serveur : `PIPE_Garde` (0 à 100), `PIPE_Bloc`, `PIPE_Combo`, `PIPE_Epee`.

## Touches

| Action | Clavier | Téléphone |
|---|---|---|
| Combo (5 coups) | clic ou E | bouton ATTAQUE |
| Bloc (maintenu) / parade parfaite | F | bouton BLOC |
| Dash (avant, ou dans la direction du déplacement) | Q | bouton DASH |
| Anciens sorts, **provisoires** jusqu'aux nouvelles compétences | 1 à 6 (R = 2) | boutons en arc |

## Ce que fait un coup

1. Clic : le client lance l'animation tout de suite (à 1,3 fois la vitesse de la source, 1,45 à 1,6 pour les coups à longue préparation)
   et envoie « coup n° k ». Un clic fait jusqu'à 0,2 s avant l'ouverture de la fenêtre enchaîne quand même ; plus tôt, il est oublié.
2. Le client teste la lame à chaque image de la fenêtre de touche. S'il touche : arrêt sur image (0,03 s), flash blanc de la cible (0,05 s),
   étincelles chaudes, petite bouffée de flammes, 3 couches de son. Au début du geste, quelques braises et petites flammes partent de la lame
   (rien en permanence sur le sabre).
3. Le serveur refait le même test (balayage en sphère, cible replacée là où le joueur la voyait 100 à 150 ms plus tôt), avec la même vitesse
   de lecture, puis applique dégâts, étourdissement et animation de choc. Une seule touche par coup.
4. 5e coup : impact frame (noir et blanc, inversion, 0,38 s), l'étourdissement est rompu, la cible est projetée (combo A : en arrière,
   contre un mur s'il y en a un ; combo B : en l'air) puis ralentie. Le coup final ne peut pas être coupé par un nouveau clic avant sa frappe.

## Dash

- Une seule recharge : **1,2 s**. Dash vers l'avant (80 studs/s pendant 0,16 s, environ 12 studs) ou de côté / en arrière (66 studs/s, 0,15 s).
- Un appui fait dans les 0,15 s avant la fin de la recharge est gardé et part tout seul quand le dash est prêt.
- Plus tôt : la jauge du dash (en bas de l'écran) clignote en rouge et un son sourd joue. On voit que c'est la recharge, pas un bug.
- Le dash annule le combo et le bloc, et relève après une projection. Les animations sont préchargées dès que le sabre est équipé
  (sinon le tout premier dash partait avec 290 ms de retard).

## Ajouter une attaque ou un combo

1. Convertir l'animation avec le pipeline (`pipeline-anim/scripts`), puis régénérer `EpeeDonnees.lua` avec `gen_epee_donnees.py`.
2. Ajouter la clé du coup dans la liste du combo (`D["MonCombo"] = { ... }`) et la séquence dans `ReplicatedStorage/PIPE_Epee/Sequences`.
   Sa vitesse de lecture se règle dans `EpeeReglages.VITESSE_COUPS`.
3. Rien à changer dans `Epee.lua` ni `EpeeClient.lua`. Pour le jeu publié : publier la séquence (`pipeline-anim/04_roblox/a_publier.txt`).

## Sabre « Braise » et monstre « Rôdeur de cendre » (étape 3)

- Sabre : gabarit `ServerStorage.PipelineAnims.PIPE_BraiseTemplate` (garde en volutes de flamme, lame sombre gravée, poignée
  rouge sombre). `Epee.equiper` le prend en premier ; `PIPE_KatanaTemplate` reste en secours. Script : `roblox/outils/blender/braise.py`.
- Monstre : gabarit `PIPE_RodeurTemplate` (rig R15, 19 pièces), module `Ennemis/Rodeur.lua` (branché sous le type « golem »).
  Séquences `PIPE_rodeur_*` dans `ReplicatedStorage.PIPE_Epee.Sequences`. Dégâts de la griffe au marqueur « Contact ».
  Réaction aux coups : `e.seqChoc` (lu par `Epee.jouerChoc`) ; pendant une projection : `e.ia.projete`.
- Nouvelle animation : écrire les poses dans un script avec `anim_lib.py`, lancer Blender, puis construire la séquence dans
  Studio avec `ServerStorage.PipelineAnims.ConstructeurSequences` à partir de `roblox/outils/blender/donnees/seq/*.json`.

## Ajouter un élément

`ProfilCombat.ELEMENTS` contient le feu (palette utilisée) et les places de l'eau, de la terre et du vent. Chaque élément doit être
**conçu à part** (formes, sons, rythme), pas recolorié. `FX` lit la palette ; quand le système sera branché, il la lira selon le joueur.

## Limites connues (honnêtement)

- Les fichiers ne sont pas rangés en dossiers `Shared / Combat` et ne sont pas en Luau strict (sauf `EpeeReglages` et `ProfilCombat`).
- Pas de vraie machine d'états : les états (attaque, bloc, projeté, sonné) sont des drapeaux avec des délais de secours.
- Les effets ne sont pas réutilisés (pas de « pooling ») ; mesuré : rien ne reste après les tests.
- La pose de garde est une image figée d'une attaque. Les anciens sorts 1 à 6 sont provisoires.
- Une texture plus ancienne (« cristal », `rbxassetid://135532586247910`) ne se charge pas et donne un avertissement dans la sortie.
