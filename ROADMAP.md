# Feuille de route de Magicaland

Écrite le 11/11/2026. Principe : finir une petite version complète et belle avant d'élargir. Chaque phase a un objectif,
des livrables et un critère « fini quand ». On ne passe à la suivante que si le critère est atteint.

## Ce qui est fait

Écran titre, naissance aléatoire (beaucoup de variables), cinématique d'intro 3D, combat au tour par tour en 3D
(esquive active, statuts, objets), persos anime CC0 animés, village peint, effets d'attaque par élément, musique générée.

## Phase 1 : la tranche verticale (objectif : « un jeu court, fini, beau »)

Durée visée : quelques semaines de travail. C'est la phase qui décide si le projet tient.

1. **Persos finals** : l'utilisateur crée 3 à 5 persos de base dans VRoid Studio (`FICHES_PERSONNAGES.md`), je les branche.
2. **Contours dessinés** sur les persos (cel-shading) et réglage de la lumière sur eux.
3. **Musique dramatique** : thème principal, thème de combat, thème de boss, jouables en continu (skill `compose-game-music`).
4. **Une zone explorable à pied** (le village) : déplacement au clavier, caméra qui suit, PNJ avec dialogues, 1 quête,
   rencontre qui lance le combat (skills `camera-systems`, `dialogue-systems`, `game-ui-ux`).
5. **Progression minimale** : niveaux, 2 à 3 compétences apprises par perso, 1 arme et 1 armure à équiper (skill `rpg`).
6. **Sauvegarde** (navigateur) et réglages (son, qualité, touches) (skill `save-systems`).
7. **Équilibrage** : 3 combats, une difficulté qui monte, un boss.

**Fini quand** : une personne qui n'a jamais vu le jeu peut jouer 20 à 30 minutes de bout en bout (intro, exploration,
2 à 3 combats, boss, fin) sans bug bloquant, sur un ordinateur normal, à 30 images/s minimum.

## Phase 2 : le monde (objectif : « ça devient un vrai RPG »)

1. Carte du monde avec lieux reliés ; une 2e et une 3e zone générées (forêt ancienne, capitale, ruines).
2. Histoire : chapitres, choix qui changent les variables de naissance, compagnons avec liens (skill `visual-novel`).
3. Plus de variantes de persos et de monstres (variantes par le code + quelques modèles supplémentaires).
4. Classes, arbre de compétences, plus d'objets.

**Fini quand** : 3 à 5 heures de jeu cohérentes, avec une fin.

## Phase 3 : en ligne

Comptes, serveur qui arbitre les combats, un seul perso par compte avec tirage de naissance définitif
(skill `add-multiplayer`). Coûts mensuels de serveur à chiffrer avant de commencer.

## Phase 4 : sortie

Test avec des joueurs, correction, page de présentation, bande-annonce (Higgsfield/Canva), publication, éventuellement version Roblox
(réécriture en Luau, à tester sur Roblox Studio côté utilisateur).

## Décisions à prendre (et quand)

| Décision | Quand | Ma recommandation |
|---|---|---|
| Rester en web (Three.js) ou passer à un moteur (Godot, Unity) | **Fin de la phase 1** | Web pour la phase 1. Si la phase 2 (grandes zones, beaucoup de contenu) devient lourde, Godot est gratuit et plus adapté, mais je ne peux ni l'ouvrir ni le tester depuis le cloud : il faudrait travailler sur l'ordinateur de l'utilisateur. |
| Personnages : VRoid Studio seul ou ajouter des modèles sur mesure | Après les 5 persos de base | VRoid + variantes par le code. Modèles sur mesure (Meshy ou artiste) seulement si le rendu ne suffit pas. |
| Argent : gratuit, achat, gacha | Avant la phase 3 | À étudier tôt : les tirages payants ont des règles légales (probabilités affichées, âge) et les magasins d'applications les encadrent. |
| Droits : persos et monde originaux | Déjà décidé | Garder un `CREDITS.md` à jour. |

## Risques connus

- **Le style** dépend de VRoid Studio : à valider dès les premiers persos.
- **La fluidité** sur ordinateurs modestes : filtre peinture et ombres lourds, qualité réglable à garder.
- **L'ampleur** : un monde « grand » avec beaucoup de persos est un projet de studio. La phase 1 sert à mesurer ce que l'on peut vraiment faire.
- **Pas de test sur le matériel de l'utilisateur** depuis le cloud : toujours demander un retour réel (fluidité, son).

## Rythme de travail

1. Le dépôt GitHub privé `animeland` est la source de vérité (GitHub Desktop pour récupérer les mises à jour).
2. Chaque session commence par `REPRISE.md` et finit par un commit, un test automatique et un rapport franc.
3. L'utilisateur teste, dit ce qui cloche, je corrige. Une étape à la fois, avec une capture avant de continuer.
