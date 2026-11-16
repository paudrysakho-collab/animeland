# Compte rendu : étapes 0, 1 et 2 de la mission combat (16/11/2026)

Légende : **conçu** (sur le papier), **implémenté** (code écrit), **importé** (dans Studio), **testé** (en Play avec le MCP),
**validé** (accepté par l'utilisateur). Rien n'est « validé » : c'est à l'utilisateur de le faire.

## Étape 0 : audit — fait

Détail dans `AUDIT.md`. Points clés :
- Higgsfield : CLI installée et connectée (368,85 crédits). **Pas de « Character Animation »** ni d'extension Blender. Il y a :
  3D Model (Meshy, Hunyuan, Tripo), 3D Rigging (animations toutes faites), 3D Body (image → corps 3D), Motion Control et
  Cinema Studio (en **vidéo** seulement). Une vidéo n'est pas une animation jouable : Higgsfield servira aux storyboards, aux bases 3D et aux sons.
- yt-dlp, ffmpeg, Blender 4.5 et le MCP Studio marchent. Les captures d'écran de Studio restent blanches (je vérifie par les valeurs).
- Cause probable du « dash une fois sur deux » : 3 s de recharge pour le dash avant, sans signal visible.

## Étape 1 : recherche et direction artistique — conçu

Détail dans `PROPOSITIONS.md` : 10 vidéos regardées en planches d'images (`refs/`), une fiche par compétence avec les temps,
3 options (l'idée de l'utilisateur + 2 alternatives) pour chacune des 6 compétences, la méthode Higgsfield / Blender / Roblox
pour le slash à distance et le projectile, **17 questions prêtes** (A, B, C) pour la session cloud.

## Étape 2 : nettoyage — implémenté, importé, testé

| Changement | État |
|---|---|
| Copie de secours : branche Git `sauvegarde/avant-mission-combat` (= place version 81) | fait, poussée |
| Transformation (T), Éveil (G), jauge, aura, cristaux, épuisement : supprimés du serveur, du client, de l'interface, des sons et des données | implémenté, importé, testé |
| Barre d'ultime, sabre doré, ultime « Couronne de l'Aube » : retirés du jeu jouable (animation et module gardés comme matière) | implémenté, importé, testé |
| Dash : une recharge de 1,2 s, mémoire d'appui de 0,15 s, signal clair en recharge (jauge qui clignote + son sourd), préchargement | implémenté, importé, testé |
| Attaques de base : 1,3 fois plus rapides (1,45 et 1,6 pour les deux coups à longue préparation), clic gardé 0,2 s, serveur synchronisé | implémenté, importé, testé |
| Traînée blanche et éclairs bleus des coups : supprimés. Feu discret : braises et petites flammes au geste, étincelles chaudes et bouffée de flammes à la touche | implémenté, importé, testé (par les valeurs, pas à l'œil) |
| Impact frames du 5e coup : gardées (éclairs retirés, flammes ajoutées) | implémenté, importé |
| Préparation des 3 systèmes (style, élément, capacité innée) : module `ProfilCombat` | conçu, implémenté (pas branché au gameplay) |

Fichiers : `roblox/src` : Combat, Principal, Epee, EpeeReglages, ProfilCombat (nouveau), FX, EpeeClient, Client, Attaques, Animations,
Sons, Donnees ; `roblox/COMBAT.md`. Place sauvegardée (version 85), jamais publiée.

### Tests (Play dans Studio, vraies touches)

- Démarrage : aucune erreur ; plus aucun bouton ni jauge de transformation, d'éveil ou d'ultime ; les commandes réseau
  Transformer, Eveiller, UltimeEpee et EclairEpee n'existent plus.
- **Dash** : 8 appuis espacés de 1,35 s → **8 dashs** de 12 studs, départ 24 à 28 ms après l'appui. 10 appuis toutes les 0,53 s →
  un dash toutes les 1,2 à 1,4 s ; 2 appuis faits juste avant la fin de la recharge sont partis tout seuls (157 ms après l'appui).
  Avant la correction, le tout premier dash partait 293 ms après l'appui et ne faisait que 5 studs (chargement des animations) :
  corrigé, maintenant 24 ms et 12,3 studs.
- **Combo A** : 7 touches sur 7. Chaque coup touche environ 23 % plus tôt (1er coup : 0,41 s au lieu de 0,55 s ; coup final : 0,25 s au lieu de 0,34 s).
- **Combo B** : les 2 coups portés avant la mort du golem ont touché (les 4 passes précédentes de l'étape 10 : 5 sur 5).
- Nettoyage : 4 objets d'effets (des sons) encore présents juste après le combo, 0 après 3 s.
- Sortie : aucune erreur des scripts. **1 avertissement** : la texture « cristal » (ancien lot Higgsfield) ne se charge pas ; elle n'est pas liée à cette étape.

### Ce qui reste à corriger ou à voir

- Je ne vois pas l'écran de Studio : le rendu des braises et des flammes est à juger à l'œil par l'utilisateur.
- Les anciens sorts 1 à 6 sont gardés en provisoire (question Q11). Le bloc et la parade aussi (question Q12).
- Pas de vraie machine d'états, pas de rangement en dossiers `Shared / Combat`, pas de pooling des effets (voir `roblox/COMBAT.md`).
- La texture « cristal » à remplacer ou à retéléverser.
- Test à 2 joueurs non fait (l'outil ne lance qu'un joueur).

### Décisions à prendre (avant les étapes 3 et 4)

Les 17 questions de `PROPOSITIONS.md` : le choix de chaque compétence, le coût de l'explosion, la transformation, les anciens sorts,
le bloc, les touches, le sabre, le monstre, l'option de confort et les éléments. Budget Higgsfield proposé pour la suite : environ 30 crédits
de storyboards, 25 à 50 pour une base 3D du monstre, 10 de sons (au-delà de 50 par jour : accord de l'utilisateur). Aujourd'hui : 0 crédit dépensé.

---

# Compte rendu : étape 3 de la mission combat (16/11/2026, session locale)

Légende : conçu / implémenté / importé / testé / validé (validé = par l'utilisateur ; rien ne l'est encore).

## Sabre « Braise » (Q14 = A) — implémenté, importé, testé (par les valeurs)
- Blender (`roblox/outils/blender/braise.py`) : **nouvelle garde** ajourée en volutes de flamme stylisées et asymétriques
  (7 langues de tailles différentes, 5 branches courbes enroulées dans le même sens, 2 440 triangles), or-orange patiné
  (bords plus clairs, creux brunis). **Lame** : géométrie du katana gardée, texture neuve acier sombre + 4 fines gravures
  rouge braise qui montent depuis la garde (22 % de la lame au plus). **Poignée** : tressage rouge sombre sur sous-couche noire.
  Fourreau laqué noir rougeâtre. Pas d'aura ni de flamme permanente.
- Roblox : 1 maillage + 5 textures téléversés (Open Cloud, modération « Approved »), gabarit `PIPE_BraiseTemplate`
  (l'ancien `PIPE_KatanaTemplate` reste en secours). `Epee.equiper` prend Braise en premier.
- Test Play : le sabre équipé a bien la garde 71653886900972 et la lame 120875195409331. **Je ne vois pas l'image du jeu**
  (captures blanches) : l'aspect est vérifié sur les aperçus Blender seulement ; à regarder par l'utilisateur.

## Monstre « Rôdeur de cendre » (Q15 = A) — implémenté, importé, testé
- Higgsfield 3D **pas utilisé** : un maillage IA d'un seul bloc aurait dû être redécoupé membre par membre ; la modélisation
  directe était plus propre et plus légère. **0 crédit dépensé.**
- Blender (`rodeur.py`) : 19 pièces rigides aux noms R15 + griffes, cheveux (46 mèches plates, deux fentes pour les yeux), yeux.
  **4 732 triangles** en tout. Hauteur mesurée dans Roblox : **8,0 studs** (≈ 1,5 fois le joueur), bras jusqu'aux genoux,
  griffes de 1,15 à 1,27 stud, courbées vers l'avant. Peau noir charbon (Slate), cheveux noirs, yeux néon rouge + lumière.
- Rig : Humanoid R15, HumanoidRootPart, 15 Motor6D (positions tirées de `rodeur_rig.json`), HipHeight 4,75
  (corrigé après mesure : les pieds étaient 0,17 stud sous le sol).
- Animations par **poses clés** (`anim_lib.py`, `anims_rodeur.py`), vérifiées par planches d'images et **par le calcul**
  (`verif_pose.py`) : attente (2,4 s, à-coup de la tête), marche (1,2 s), course (0,66 s, très penché, bras qui traînent),
  griffe (1,3 s : 0,6 s d'anticipation avec tremblement, fente, contact à 0,7 s, suivi, retour), choc (0,45 s), projeté (0,8 s, boucle).
  Une erreur trouvée et corrigée par le calcul : le bras armé passait de l'autre côté de la tête (ordre des rotations).
- Serveur (`Ennemis/Rodeur.lua`) : mêmes règles que le golem (vie 140, dégâts 8, portée 7, alerte 0,6 s) ; les dégâts tombent
  au **marqueur « Contact »** de l'animation (sécurité 0,25 s plus tard). Le monstre court au-delà de 16 studs.
  `Combat` utilise le Rôdeur à la place du golem (le module Golem reste dans le code).

### Tests Play (vrais chemins : Commencer, touche E, barre de vie, Animator)
- Apparition, attente, marche et course : OK. Aucune erreur de script (seul l'ancien avertissement « cristal »).
- **Synchro griffe** : 3 attaques mesurées : marqueur Contact 0,716 à 0,717 s après le début, **dégâts au même instant**
  (écart 0 ms à la précision du journal).
- **Réactions** : 4 coups sur 4 du combo → 4 fois l'animation de choc + barre de vie qui baisse ; un coup pendant l'alerte
  annule la griffe (0,14 s après son début). Coup final : projection (65 studs/s) avec l'animation « projeté » ; défaut trouvé
  (la marche se lançait pendant le vol), corrigé, retesté. Mort : effondrement en rotules, OK.
- Non testé : projection **en l'air** (combo avancé) et combos aériens sur le monstre (viendront avec la compétence 3).

## Ce qui reste / limites
- Pièces rigides (pas de peau déformée) : des petites cassures aux coudes et genoux sont possibles à l'œil. À juger en jeu.
- Les séquences sont enregistrées à la volée (Studio seulement) : pour le jeu publié, il faudra publier les animations
  (`pipeline-anim/04_roblox/a_publier.txt`).
- Q18 (extension Higgsfield pour Blender, demande Blender 5.1) : dans `QUESTIONS.md`.
- Place sauvegardée version 90 (jamais publiée). Commits poussés sur `claude/dazzling-bardeen-uao49i`.
