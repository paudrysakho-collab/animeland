# Magicaland sur Roblox : démarrage

Décision de l'utilisateur du 12/11/2026 : **on commence par un jeu Roblox**, plus simple (avatars animés fournis,
multijoueur et publication intégrés). Le jeu web (`index.html`, `js/`) reste dans le dépôt comme référence des règles.

## Comment on travaille

Roblox Studio tourne sur le Windows de l'utilisateur. Une session cloud ne peut ni l'ouvrir ni le tester.
Il faut une **session Claude locale** (appli de bureau, session Claude Code qui tourne sur l'ordinateur), reliée à Studio :

1. Installer Roblox Studio (gratuit, compte Roblox) et ouvrir un nouveau projet (« Baseplate »).
2. Dans Studio : **Assistant**, puis **Manage MCP Servers**, puis **« Enable Studio as MCP server »**.
3. Brancher ce serveur MCP dans Claude sur l'ordinateur (la session locale lit la documentation Roblox à jour pour la
   marche exacte : `https://create.roblox.com/docs/llms.txt`).
4. Ne connecter que des clients de confiance : un client connecté peut lire et modifier tous les projets ouverts dans Studio.

Outils attendus une fois relié : lire l'arborescence du jeu, lire et écrire les scripts, exécuter du Luau, lancer et
arrêter un test, lire la console, capturer l'écran. Non essayé depuis le cloud.

Skills du dépôt `paudrysakho-collab/skills` (branche `claude/dazzling-bardeen-uao49i`) à lire d'abord :
`jeux-video`, `roblox-studio-workflow`, `roblox-luau`, `roblox-characters`, `roblox-networking`, `roblox-datastores`,
`roblox-ui`, `roblox-physics`, `roblox-simulator-economy`, plus `rpg`, `game-feel`, `game-ui-ux`.

## Ce qu'on reprend du jeu web (les règles, pas l'affichage)

Tout est dans `js/game.js` et `GAME_DESIGN.md` :
- **Naissance aléatoire**, seul le nom se choisit : race (11), lieu, famille, divinité, 7 caractéristiques, 5 affinités de
  magie, don d'isekai (8, de commun à légendaire), traits, malédiction rare, rang de D à SS.
- **Combat au tour par tour** : Attaque, Compétences, Objets, Défense ; énergie partagée ; points faibles et résistances ;
  jauge de brèche ; esquive active avec parade parfaite ; critiques.
- **Statuts** à durée fixe : poison, brûlure, gel, paralysie, sommeil, malédiction, régénération, bénédiction, carapace ;
  infligés par l'élément ; réactions simples ; boss résistants.
- Personnages et monde **originaux** (aucun personnage d'anime existant), ton tout public.

## Réponses de l'utilisateur (12/11/2026)

1. Jeu : Magicaland simplifié. 2. Combats : **temps réel**. 3. Monde partagé, combats solo. 4. Studio : pas encore installé.

## Connexion à Roblox Studio (vérifiée dans la documentation Roblox, jamais essayée depuis le cloud)

Source : https://create.roblox.com/docs/en-us/ai/coding-harness.md
1. Installer Roblox Studio (gratuit, compte Roblox) et ouvrir un projet Baseplate.
2. Dans Studio : bouton **Assistant** (en haut à droite), puis **⋯**, puis **Manage MCP Servers**, vérifier que MCP est activé.
3. « Quick connect » propose **Cursor** et **Visual Studio Code**. La documentation ne décrit pas de raccourci pour Claude Code :
   suivre la page « Connect to the Roblox Studio MCP server » pour la configuration manuelle.
4. Test : demander à l'agent de lire l'arborescence du jeu ; sur un Baseplate neuf il doit lister Camera, Terrain, Baseplate, SpawnLocation.
5. Optionnel : Script Sync (synchronise des fichiers du dépôt vers Studio).

## Points de vigilance

- Argent et tirages payants : Roblox les encadre (probabilités à afficher, restrictions par pays et par âge).
  Vérifier les règles actuelles avant de construire un gacha. Rien de monétisé ni publié sans l'accord de l'utilisateur.
- Sur Roblox, le serveur décide (dégâts, tirages, sauvegarde) : ne jamais faire confiance au client.
- Garder le code dans le dépôt (fichiers Luau) pour ne pas dépendre du seul fichier Studio ; voir Rojo dans `roblox-studio-workflow`.

## Message à coller dans la session locale

> Lis ROBLOX.md, GAME_DESIGN.md et REPRISE.md du dépôt paudrysakho-collab/animeland (branche claude/dazzling-bardeen-uao49i),
> et les skills Roblox du dépôt paudrysakho-collab/skills (même branche). Aide-moi à relier Roblox Studio à Claude par son
> serveur MCP, puis pose-moi les questions ouvertes de ROBLOX.md avant de construire quoi que ce soit. Réponds en français, simplement.
