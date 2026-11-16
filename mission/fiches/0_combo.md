# Combo de base au sabre : 5 coups faits main (retours de l'utilisateur du 16/11)

Les 10 coups Mixamo sont retirés du combo. Les deux combos (Épéiste, Épéiste avancé) utilisent les 5 mêmes coups faits main ;
seule la fin change (Épéiste : projeté en arrière ; avancé : projeté en l'air). Animations : `anims_combo.py` (poses clés sur
le rig R15, `anim_lib.py`), données de jeu : `gen_epee_donnees.py` → `EpeeDonnees.lua`.

## Référence (jeu vidéo d'anime)
- **Jeu** : Demon Slayer: The Hinokami Chronicles. **Vidéo** : `MgyxfmKFA8c` (« Tanjiro (Water Breathing) Complete Moveset »),
  vue en images à 10 i/s, recadrées sur les deux personnages (0,2 → 2,6 s). Planche : `mission/refs/combo_hinokami.jpg`.
- Ce que montrent les images, et le coup qui en est tiré :

| Temps (vidéo) | Ce qu'on voit | Coup du jeu |
|---|---|---|
| 0,3 → 0,4 s | coup **montant en diagonale** (bas gauche → haut droite), fente basse, genoux très pliés | 1. `coup_montant` |
| 0,6 → 0,7 s | coup **horizontal** de droite à gauche à hauteur de taille, hanches qui tournent | 2. `coup_horizontal` |
| 0,8 → 1,0 s | **grand diagonal descendant** avec un grand pas, fin accroupie | 3. `coup_descendant` |
| 1,7 → 2,1 s | **estoc en ruée** : le corps traverse la distance, fente très longue, jambe arrière tendue | 4. `coup_estoc` |
| 1,1 → 1,3 s | **rotation sautée** puis impact (finale) | 5. `coup_tourbillon` |

Repris : la forme de chaque coup, les appuis bas et larges, un pas en avant par coup, la rotation des hanches, le rythme
(coup en 0,1 s, puis tenue). Pas repris : noms, apparence, sons, images, effets du jeu.
**Honnêteté** : les poses sont construites d'après ces images (forme, appuis, rythme), pas calquées image par image ; une passe
plus fidèle (rafales plus serrées, 3 ou 4 poses relevées par coup) reste possible si le rendu ne suffit pas.

## Les 5 coups (temps de l'animation)
| Coup | Anticipation | Contact | Suivi | Durée | Avance |
|---|---|---|---|---|---|
| 1. montant | 0,10 (lame basse à gauche, buste tourné à gauche, poids en arrière) | 0,20 (devant, montée) | 0,28 (haut à droite) | 0,62 s | 1,5 stud |
| 2. horizontal | 0,12 (buste tourné à droite, bras tendu derrière) | 0,22 (devant, à hauteur de taille) | 0,30 (à gauche, bras croisé) | 0,62 s | 1,8 stud |
| 3. descendant | 0,14 (sabre au-dessus de l'épaule droite, corps cambré) | 0,25 (devant, en descendant, grand pas) | 0,34 (bas à gauche, accroupi) | 0,70 s | 2,3 studs |
| 4. estoc | 0,12 (sabre ramené à la hanche, coude plié) | 0,22 (bras tendu, fente) | tenue 0,32 | 0,65 s | 3,4 studs |
| 5. tourbillon | 0,12 (accroupi, tordu à droite) | rotation complète en l'air 0,22 → 0,40, coupe face à la cible 0,46 | 0,56 | 0,85 s | 1,7 stud |

## Vérifications (par le calcul, `verif_anim.py` et `blade_data.py`)
- Aucun membre dans le corps, aucune lame dans le corps, pieds jamais sous le sol, jambes jamais croisées, pointe jamais sous
  le sol (après 3 corrections : pointe sous le sol dans le coup montant et le descendant, pieds trop bas).
- Trajectoires de la pointe : 5 formes différentes (montée gauche → droite ; balayage horizontal ; descente droite → gauche ;
  estoc jusqu'à 10 studs devant ; tour complet). Fenêtres de touche : 0,07 à 0,10 s.

## Test en jeu (Play, touche E, 16/11) — implémenté, importé, testé
- 5 appuis (tous les 0,40 à 0,43 s) → **5 coups sur 5 touchent** : 140 → 130 → 119 → 106 → 92 → 69 PV (finale : 23).
- Le monstre joue sa réaction de choc ; le joueur avance de **18,6 studs** pendant le combo. Aucune erreur de script.
- Non vérifié : l'aspect à l'œil (captures blanches) — à juger par l'utilisateur.
