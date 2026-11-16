# Compétence 1 (touche 1) : slash à distance de feu, « Sillon de braise » — REFAIT À LA MAIN (16/11, soir)

Choix de l'utilisateur : Q1 = A : posture, armé, coup descendant jusqu'au sol ; au contact, une vague de feu part au ras
du sol vers la cible et explose à l'impact. Retours du 16/11 : animation dessinée à la main d'après un jeu vidéo d'anime,
caméra façon anime pour les attaques spéciales.

## Référence (jeu vidéo d'anime)
- **Jeu** : Demon Slayer: The Hinokami Chronicles. **Vidéo** : `SIAivrO6KlA` (« Rengoku (Flame Hashira) Complete Moveset »),
  **12,2 → 14,0 s** (coup final au sabre, levé très haut puis abattu jusqu'au sol, explosion devant).
  Vue en images à 10 i/s, recadrées. Planche : `mission/refs/slash_hinokami.jpg`.
- Poses relevées et reproduites sur le rig R15 :

| Temps vidéo | Ce qu'on voit | Pose dans l'animation |
|---|---|---|
| 12,2 s | armé : debout, grand, sabre très haut au-dessus de la tête, lame vers l'arrière | 0,28 s (et tension 0,38 s, marqueur `Depart`) |
| 12,4 s | grand pas en avant, la lame passe au sommet de l'arc devant | 0,46 s |
| 12,5 s | contact : fente extrême, jambe arrière tendue, buste couché vers l'avant, lame au sol | 0,54 s (marqueur `Contact`) |
| 12,7 → 13,6 s | longue tenue basse pendant l'explosion | 0,62 → 1,05 s (raccourcie pour le jeu) |
| 13,7 → 14,0 s | on se relève | 1,05 → 1,50 s |

Repris : forme du coup, appuis, grand pas, rythme (armé lent, frappe en 0,08 s, longue tenue). Pas repris : nom,
apparence, sons, effets, images.

## Animation `PIPE_feu_slash` (1,50 s, `roblox/outils/blender/anims_feu.py`, SUR PLACE)
- Le grand pas (3 studs) est un vrai déplacement : le client avance le HumanoidRootPart de 0,38 à 0,50 s (courbe douce),
  limité à 4 studs de la cible et arrêté par les murs (`CompetencesFeu.pas`).
- Contrôles (`verif_anim.py`) : aucun membre ni lame dans le corps, pieds jamais sous le sol, pointe au sol pendant la tenue
  (−2,8 à −3,15 pour un sol à −3,0), après 2 corrections (pointe 1,5 stud sous le sol, pied avant enfoncé au tassement).

## Caméra façon anime (locale, coupée par l'option Confort)
0 → 0,12 s : passage vers un gros plan 3/4 face sur le haut du corps (FOV 52, puis lente poussée) pendant l'armé ;
au contact : coupe vers un angle bas de côté (voit la fente et le départ de la vague) avec zoom rapide (FOV 40 → 62 en 0,15 s) ;
0,95 → 1,30 s : retour en douceur vers la caméra de jeu. Toujours rendue en cas de dash (annulation), de mort ou à la fin.
`CompetencesClient.lua` (cameraAnime, avancer) ; réglages dans `CompetencesFeu.lua` (camera).

## Tests (Play dans Studio, 16/11, vraie touche 1) — implémenté, importé, testé
| Mesure | Cible à 15 studs | Cible à 5,5 studs |
|---|---|---|
| Appui → contact | 0,67 s (animation 0,54 s + démarrage) | 0,67 s |
| Grand pas | 3,00 studs | 1,50 stud (s'arrête à 4 studs de la cible) |
| Pointe / départ de la vague | 0,15 stud d'écart, 0,24 au-dessus du sol | — |
| Contact → impact confirmé par le serveur | 0,11 s | 0,06 s |
| Caméra | Scriptable de 0,2 à 1,5 s, rendue à 13 studs (comme avant) | idem |
| Erreurs | aucune | aucune |

Défauts trouvés et corrigés : pas bloqué par la cible (le rayon touchait le monstre) ; après le retour, la caméra de jeu se
collait au joueur (Camera.Focus resté à l'ancienne place → Focus mis à jour à chaque image et caméra reposée avant de rendre).
Reste : à l'impact, un effet existant remonte le FOV ~0,1 s (68 au lieu de 62) ; non vérifié : l'aspect à l'œil (captures
blanches), l'option Confort et l'annulation par dash avec la nouvelle caméra (code prévu, pas re-testé), 2e joueur.
