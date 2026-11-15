# Combat au sabre : comment c'est fait

Jeu : « From Nothing: Reborn » (Roblox). Ce fichier décrit le style épée tel qu'il est après l'étape 10.
Le serveur décide de tout (dégâts, recharges, barre d'ultime, garde, invulnérabilité). Le client demande, prédit et affiche.

## Où est quoi

| Fichier (dans `roblox/src`) | Rôle |
|---|---|
| `ReplicatedStorage/Magicaland/EpeeReglages.lua` | **Tous les réglages** (durées, distances, gains). Partagé client / serveur. C'est le seul fichier à toucher pour régler le ressenti. |
| `ReplicatedStorage/Magicaland/EpeeDonnees.lua` | Données de chaque coup : animation, fenêtre de touche, position de la lame image par image, dégâts. **Généré** par `pipeline-anim/scripts/gen_epee_donnees.py`, ne pas modifier à la main. |
| `ServerScriptService/Magicaland/Epee.lua` | Serveur : rythme du combo, balayage de la lame avec rembobinage, étourdissement, projections, barre d'ultime, bloc / parade, dash, sabre doré. |
| `ServerScriptService/Magicaland/Combat.lua` | Règles communes (dégâts, énergie, victoire, IA des ennemis). Appelle `Combat.filtreDegatsJoueur` quand un ennemi touche (bloc, parade, projection) et signale les coups lourds. |
| `StarterPlayerScripts/Magicaland/EpeeClient.lua` | Client : entrées, prédiction, animations, caméra, effets, barres, boutons tactiles. |
| `ReplicatedStorage/PIPE_Epee/FX.lua`, `RealFX.lua`, `Ultime01.lua` | Effets (réalistes, sans contour dessiné). Le ciel n'est jamais modifié. |

Commandes réseau (dossier `Remotes`) : `AttaquerEpee(k)`, `UltimeEpee()`, `BlocEpee(vrai/faux)`, `DashEpee("avant"/"cote")`, `EclairEpee()` (étape 12),
et `EpeeFx` (serveur → clients : effets à jouer). Chaque commande est vérifiée : type des arguments, état du joueur, rythme, distance. Une demande invalide est ignorée.

État du joueur visible par tous (attributs posés par le serveur) : `PIPE_Ultime` (0 à 100), `PIPE_Garde` (0 à 100), `PIPE_Bloc`, `PIPE_SabreDore` (heure de fin), `PIPE_Combo`.

## Touches

| Action | Clavier | Téléphone |
|---|---|---|
| Combo (5 coups) | clic ou E | bouton ATTAQUE |
| Bloc (maintenu) / parade parfaite | F | bouton BLOC |
| Dash (avant, ou sur le côté si on se déplace de côté) | Q | bouton DASH |
| Ultime | V ou 6 | bouton ULTIME |

## Ce que fait un coup

1. Clic : le client lance l'animation tout de suite et envoie « coup n° k ». Un clic fait trop tôt est gardé en mémoire et part dès que la fenêtre s'ouvre.
2. Le client teste la lame à chaque image de la fenêtre de touche. S'il touche, il joue aussitôt l'arrêt sur image (0,03 s), le flash blanc de la cible (0,05 s), les étincelles et les 3 couches de son (souffle, impact, grave, hauteur variée de ±5 %).
3. Le serveur refait le même test de son côté (balayage en sphère le long de la lame, cible replacée là où le joueur la voyait 100 à 150 ms plus tôt) et, s'il confirme, applique les dégâts, l'étourdissement et l'animation de choc. Une seule touche par coup.
4. 5e coup : l'étourdissement est rompu (la cible ne peut plus être étourdie pendant 2 s), la cible est projetée (combo A : en arrière, contre un mur s'il y en a un ; combo B : en l'air) puis ralentie 1,5 s.

## Valeurs principales (voir `EpeeReglages.lua`)

- Arrêt sur image : 0,03 s. Étourdissement par coup : 1,5 s (0,5 s pour un boss).
- Barre d'ultime : +7 par touche, +12 sur le coup final, +20 par parade parfaite, +6 par coup bloqué, +10 par coup reçu. Ultime possible à 100 et si la cible est à moins de 16 studs. Invulnérable pendant l'ultime, puis sabre doré 45 s (dégâts × 1,25).
- Garde : 100. Un coup bloqué coûte 3 × ses dégâts. Garde à 0 : brisée, sonné 1,5 s. Elle remonte de 25 par seconde.
- Parade parfaite : garde levée moins de 0,2 s avant le coup. L'attaquant est étourdi 1,6 s (0,8 s pour un boss).
- Coups lourds (flash rouge) : imparables, ils projettent le joueur. Golem : 1 attaque sur 3. Colosse : les racines.
- Dash : avant 3 s de recharge, côté 2 s. Il annule le combo et relève après une projection.
- Effets : 0,4 s au plus et 40 particules au plus par coup (sauf l'ultime). Particules divisées par 2 sur téléphone, en qualité basse ou sous 45 images/s.

## Ajouter une attaque ou un combo

1. Convertir l'animation avec le pipeline (`pipeline-anim/scripts`), puis régénérer `EpeeDonnees.lua` avec `gen_epee_donnees.py` (il calcule la fenêtre de touche et la lame).
2. Ajouter la clé du coup dans la liste du combo (`D["MonCombo"] = { ... }`) et la séquence dans `ReplicatedStorage/PIPE_Epee/Sequences`.
3. Rien à changer dans `Epee.lua` ni `EpeeClient.lua` : ils lisent les listes. Pour le jeu publié, publier la séquence (voir `pipeline-anim/04_roblox/a_publier.txt`).

## Ajouter un style (feu, eau, terre, air)

Pas encore prévu dans le code : aujourd'hui les couleurs des effets sont dans `FX.lua` (traînée, étincelles). Pour un style, il faudra une table de couleurs et de sons par style dans `EpeeReglages` et la passer à `FX`. C'est un petit chantier, pas encore fait.

## Limites connues (honnêtement)

- Les fichiers ne sont pas encore rangés dans des dossiers `Shared / Combat` séparés et ne sont pas en Luau strict (seul `EpeeReglages` l'est). Le système est unique (pas de doublon), mais `Combat.lua` et `Client.client.lua` restent de gros fichiers.
- Pas de vraie machine d'états écrite noir sur blanc : les états (attaque, bloc, projeté, sonné, ultime) sont des drapeaux avec des délais de secours.
- Les effets ne sont pas réutilisés (pas de « pooling ») : ils sont créés puis détruits. Mesuré : aucun objet ne reste après 60 coups et 10 ultimes.
- La pose de garde est une image figée d'une attaque, en attendant une vraie animation de garde.
- Un seul ennemi par joueur (combats en solo) : le cas « plusieurs monstres » n'existe pas dans le jeu actuel. Test à 2 joueurs non fait (l'outil ne lance qu'un joueur).
