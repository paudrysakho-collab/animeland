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

## Connexion à Roblox Studio (doc officielle relue le 14/11/2026 : https://create.roblox.com/docs/en-us/studio/mcp.md)

Studio est installé chez l'utilisateur (14/11/2026).
1. Dans Studio : **Assistant**, puis **…**, puis **Manage MCP Servers**, activer **Enable Studio as MCP server**.
2. **Quick connect** (Assistant Settings, MCP Servers) gère **Claude Code** et **Claude Desktop** : activer celui utilisé, puis redémarrer Claude.
   Si le client n'apparaît pas : l'installer puis redémarrer Studio.
3. Sinon, configuration manuelle sous Windows : commande `cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat` (serveur nommé `Roblox_Studio`, transport stdio).
4. Le serveur tourne **sur l'ordinateur** : seule une session Claude **locale** le voit. Une session cloud ne le voit pas.
5. Test : `list_roblox_studios`, puis `search_game_tree` sur Workspace (un Baseplate neuf montre Camera, Terrain, Baseplate, SpawnLocation).
6. Un client connecté peut lire et modifier tous les projets ouverts dans Studio : n'ouvrir que le projet du jeu.

Outils fournis (extraits) : lire, chercher et modifier les scripts ; explorer le jeu ; exécuter du Luau ; lancer un test, lire la console,
capturer l'écran ; simuler clavier, souris et déplacement ; enregistrer le projet ; et de la génération par IA de Roblox :
`generate_avatar` (avatar R15 rigué et animable à partir d'un texte), `generate_animation`, `generate_mesh`, `generate_material`,
`generate_procedural_model`. Coût et conditions d'usage de ces générations : non vérifiés, à regarder avant de s'en servir.

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

## Règles de génération de l'utilisateur (14/11/2026)

- **ElevenLabs** : générer librement, au maximum, **sans demander** (bruitages, variantes, voix, musique selon le connecteur).
- **Google AI Studio** (clé gratuite) : utiliser librement tout ce qui est gratuit, sans demander ; s'arrêter et signaler si un appel devient payant.
- **Higgsfield** : **toujours demander l'accord** avant chaque génération (crédits payants).
- Sons de l'anime Fire Force : référence d'ambiance seulement, jamais utilisés (droits d'auteur).
