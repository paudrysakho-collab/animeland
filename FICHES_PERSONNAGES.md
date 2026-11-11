# Fiches personnages pour VRoid Studio

But : créer les persos de Magicaland dans VRoid Studio, les exporter en `.vrm`, les déposer dans `assets/vrm/`.
Claude s'occupe ensuite de les alléger et de les brancher dans le jeu.

## Réglages d'export (important)

- Format : **VRM 0.x** si VRoid Studio te propose le choix (le jeu le gère déjà). Si tu n'as que VRM 1.0, exporte quand même et dis-le : je m'adapterai.
- Cases de licence : usage commercial autorisé, modification autorisée, redistribution autorisée (tes persos, ton jeu).
- Nom du fichier : le nom du rôle, sans espace (`Kael.vrm`, `Lysa.vrm`, `Heros.vrm`...).
- Garde aussi le fichier du projet VRoid (`.vroid`) : tu pourras refaire des variantes (couleurs, tenues).
- Pose : laisse la pose de base (bras légèrement écartés).

## Ordre conseillé

1. **Kael** (premier essai, pour voir ce que VRoid permet).
2. **Lysa**.
3. **Le héros** (personnage du joueur).
4. Les bandits et le chef.

Ne cherche pas la perfection du premier coup : on remplace un perso à la fois et on regarde le résultat dans le jeu.

## Ambiance visuelle commune

Sobre, adulte, clair-obscur : couleurs posées et un peu désaturées, une couleur d'accent par perso, tenues pratiques d'aventurier (cuir, tissu, métal terni). Éviter les tons bonbon et les uniformes d'école.

## Les fiches

| Rôle | Corps et visage | Cheveux | Tenue | Couleur d'accent |
|---|---|---|---|---|
| **Kael** (guerrier, allié) | Adulte, carrure large, mâchoire marquée, regard calme, petite cicatrice | Brun foncé, courts, un peu en bataille | Armure légère de cuir et plaques, cape courte, gants | Rouge brique |
| **Lysa** (soigneuse, alliée) | Adulte, fine, visage doux, yeux clairs | Blanc argenté, longs, tressés sur le côté | Robe longue de prêtresse, capuche rabattue, ceinture avec fioles | Or pâle |
| **Le héros** (joueur) | Adulte neutre, visage simple et expressif (sa race ajoutera oreilles, cornes, queue ou ailes par le code) | Une couleur neutre de départ : le jeu varie la teinte | Tenue de voyageur : tunique, cape à capuche, bottes | Selon l'élément du joueur |
| **Bandit** | Adulte, visage dur, mal rasé | Noirs, sales, attachés | Cuir usé, bandeau, brassards | Brun terne |
| **Archer bandit** | Adulte, mince, regard fuyant | Châtains, mi-longs | Cuir vert sombre, capuche, carquois | Vert mousse |
| **Sorcier bandit** | Adulte, maigre, visage creusé | Gris, longs | Robe déchirée, capuche, symboles | Violet |
| **Chef des bandits** | Adulte, très massif, cicatrices | Roux sombre, barbe | Fourrure, plastron, épaulière | Rouge sombre |

## À savoir sur VRoid Studio

- Les vêtements sont limités aux pièces proposées par le logiciel. Pour une armure ou une cape précise, il faudra peut-être
  peindre les textures soi-même dans l'éditeur de textures de VRoid Studio. Je n'ai pas vérifié jusqu'où ça va : essaie, puis dis-moi ce qui manque.
- Ce que le logiciel ne fait pas (cornes, queue, ailes, armes) est ajouté par le code du jeu.
- Les cheveux et les jupes sont rigides pour l'instant dans le jeu.

## Envoyer les fichiers

Avec GitHub Desktop : copie les `.vrm` dans le dossier `assets/vrm` du dépôt, puis « Commit » et « Push ». Un fichier fait environ 15 Mo, c'est accepté par GitHub.
