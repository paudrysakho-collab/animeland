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
