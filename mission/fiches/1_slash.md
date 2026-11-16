# Compétence 1 (touche 1) : slash à distance de feu, « Sillon de braise »

Choix de l'utilisateur : Q1 = A (son idée) : posture, armé, coup descendant jusqu'au sol ; au contact, une vague de feu
part au ras du sol vers la cible et explose à l'impact.

## Références (vues en planches d'images, étape 1, `mission/refs/`)
- `slash_zoro.jpg` (1zio3FRYQbA) : 0 s, sabre levé très haut au-dessus de la tête (grosse anticipation) ; 1 à 4 s, la ligne
  de coupe traverse le décor **avant** l'explosion ; 18 s, gros plan sur la main qui serre la poignée.
- `slash_roblox_feu.jpg` (wauPbM7qSWE) : 9 à 11 s et 25 à 28 s, traînée de flammes qui court **au ras du sol** ;
  31 à 32 s, explosion avec arcs d'étincelles.
- Retenu : anticipation très haute, vague collée au sol (lisible vue de haut), la vague arrive **après** le geste
  (le retard fait la puissance), explosion courte et lourde. Rien n'est copié (ni forme, ni nom, ni effet dessiné).

## Chorégraphie (animation `PIPE_feu_slash`, 1,25 s, poses clés dans `anims_feu.py`)
| Temps | Phase | Pose |
|---|---|---|
| 0,00 | garde | pose de garde du sabre |
| 0,14 | posture | pied gauche en avant, buste tourné, bras qui montent |
| 0,42 | **anticipation** | armé : bras droit au-dessus et derrière la tête, corps cambré, sur la pointe des pieds |
| 0,50 | tension (marqueur `Depart`) | même pose, un peu plus cambrée, léger tremblement |
| 0,50 → 0,60 | **accélération** | courbe u³ : la lame passe au sommet de l'arc puis plonge |
| 0,60 | **contact** (marqueur `Contact`) | fente basse, buste penché de 40°, pointe au sol 7 studs devant |
| 0,68 → 0,88 | tenue | la lame reste au sol (tenue « vivante ») |
| 1,25 | **récupération** | retour en garde |

Vérifié par le calcul (`verif_pose.py`) : pointe de la lame à −2,99 stud au contact pour un sol à −3,0 (repère du joueur),
7 studs devant ; les pieds restent au sol.

## Jeu
- Serveur : la vague part au moment du contact (0,60 s), du point où la lame touche le sol, vers la cible si elle est
  devant le joueur (± 70°), sinon tout droit. Elle avance de 55 studs/s sur 42 studs au plus, au ras du sol ; le serveur
  teste la cible à chaque image (rayon 2,6 + taille de la cible) et s'arrête contre un mur.
- Impact : dégâts × 2,4 (mêmes règles que les coups : critique, faiblesse au feu), étourdit 0,5 s, recul fort.
- Recharge : 6 s (barre des compétences au-dessus de la jauge du dash). Pendant la compétence : pas de combo, pas de bloc ;
  un dash **avant** le contact annule la compétence (la recharge reste comptée), après le contact la vague part.
- Client : animation jouée tout de suite (prédiction) ; vague et effets lancés au **marqueur Contact** de l'animation ;
  explosion quand le serveur confirme l'impact.

## Tests (Play dans Studio, 16/11/2026, vraies touches) — implémenté, importé, testé
| Mesure | Résultat |
|---|---|
| Appui → début de l'animation | 0,11 s (1er lancement, enregistrement de la séquence compris) |
| Début de l'animation → marqueur Contact | 0,57 à 0,60 s (attendu 0,60) |
| Marqueur Contact → départ de la vague | même image (la vague est créée dans le marqueur) |
| Pointe de la lame / départ de la vague (image suivant le marqueur) | **0,01 stud** d'écart ; pointe à 0,15 stud du sol |
| Contact → explosion confirmée par le serveur | 0,083 s (cible à 5 studs), 0,118 s (18 studs), 0,27 s (16 studs, avant le réglage du départ) |
| Dégâts | 28 à 29 PV sur 140 par vague (3 tirs, 3 touches) |
| Recharge | 2e appui à 1,5 s refusé (aucune vague) ; la case 1 affiche 4,4 s restantes 1 s après le contact |
| Dash 0,3 s après l'appui | compétence annulée : pas de vague, pas de dégât, déplacement rendu |
| Nettoyage | 0 objet d'effet 3 s après |
| Erreurs | aucune erreur de script |

Défauts trouvés et corrigés pendant les tests : cases de la barre non affichées ; vague qui partait 4 studs avant la lame ;
étincelles placées d'après la pose de l'image précédente (la pose du marqueur ne s'affiche qu'à l'image suivante).
Non vérifié : l'aspect à l'œil (captures de Studio blanches) ; l'affichage chez un 2e joueur (un seul joueur en test).