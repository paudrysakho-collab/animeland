# REPRISE : Magicaland (dépôt `animeland`)

Écrit le 10/11/2026 par Claude (session cloud), limite de session à 93 %.
Branche de travail : `claude/dazzling-bardeen-uao49i`. Tout est commité et poussé.

## Le projet

« Magicaland : Reborn in New World » : jeu isekai dans le navigateur (téléphone d'abord).
Naissance tirée au sort (seul le nom se choisit), cinématique d'intro 3D, combat au tour par tour en 3D
inspiré de Pokémon, Final Fantasy X et Clair Obscur. Personnages 100 % originaux, ton tout public.
Lire `GAME_DESIGN.md` (décisions), `EPIC_INTRO_BRIEF.md` (cahier des charges 3D), `README.md`, `CREDITS.md`.

## État actuel (fait et testé)

- `index.html` + `js/game.js` (règles, naissance, combat), `js/stage3d.js` (Three.js r147 : village de nuit,
  acteurs, caméra, effets), `js/audio.js` (musique et bruitages générés en Web Audio).
- Modèles : KayKit Adventurers (CC0), dans `assets/` en `.glb` (sources) et `.json` base64 (chargés par le jeu,
  car une page publiée refuse les `.glb`).
- Test automatique (Chromium sans écran, `--use-angle=swiftshader`) : partie complète jusqu'à la victoire
  contre le chef, aucune erreur, en qualité basse. Non vérifié : le son, un vrai téléphone, les détails de race.
- Page publiée (privée) : https://claude.ai/artifact/N6jBUPkyrWao9m4rkvkctv (fichier source de la page :
  le `<style>` et le `<body>` de `index.html`, publiés avec `js/*` et `assets/*.json`).
- `prototype-2d.html` : ancien prototype 2D, référence des règles.

## Retour de l'utilisateur sur la version 3D (10/11/2026)

Il aime. À changer :
1. **Style trop enfantin** (grosses têtes cartoon de KayKit) : il veut un style plus sobre et plus avancé.
   Il faut de nouveaux modèles 3D. Il pense à Higgsfield (abonnement pas encore pris, environ 50 €) :
   vérifier d'abord si Higgsfield produit des modèles 3D riggés, sinon regarder Meshy (image vers 3D + rig,
   cité dans le skill `game-3d-assets`) ou des packs CC0 aux proportions réalistes (Quaternius).
   Annoncer tout coût et attendre son accord avant de payer.
2. **Musique plus dramatique et épique** : à retravailler dans `js/audio.js` (skill `compose-game-music`,
   mode « revision rules for weak music » : plus de présence, forme A/B, percussions, chœur, montée).
3. **Chercher d'autres skills de jeux sur GitHub** : recherche faite, rien d'installé. Candidats non encore
   dans le dépôt `skills` : `htdt/godogen` (7 320 étoiles, MIT, Godot autonome), `MRCalderon3D/everything-game-dev-code`
   (MIT, 86 skills), `bullish0x/GameStudio` (MIT, 182 skills), `brockmartin/roblox-game-skill` (licence inconnue).
   Déjà installé : `gamedev-skills/awesome-gamedev-agent-skills`. Lire leurs scripts avant d'installer.

## Prochaines étapes proposées

1. Musique plus dramatique (gratuit, tout de suite).
2. Choisir la voie des modèles sobres avec l'utilisateur, puis remplacer les 5 modèles (le code prend un
   modèle par rôle dans `SPEC` de `js/game.js` et les animations par nom dans `js/stage3d.js`).
3. Ensuite : compétences apprises, équipement, mode histoire, puis mode en ligne.

## Règles de l'utilisateur

Réponses en français, simples (il est sur téléphone). Poser les questions avec l'outil AskUserQuestion
(4 par envoi). Gratuit d'abord ; rien de payant, publié ou monétisé sans son accord. Assets libres de droits
avec `CREDITS.md`. Ne jamais demander de coller une clé dans la conversation.
Modèle : Sonnet pour le courant, Fable pour les gros chantiers (c'est lui qui change avec `/model`).
Dépôt `skills` : les 141 skills de jeux sont fusionnés dans la branche `claude/dazzling-bardeen-uao49i` seulement.
