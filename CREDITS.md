# Crédits

## Personnages 3D

- **Modèles d'exemple VRoid Studio (version bêta)**, licence **Creative Commons Zero (CC0)**, indiquée dans les
  métadonnées de chaque fichier : Sendagaya Shibu, Sakurada Fumiriya, Victoria Rubin, Vita, Vivi, Darkness Shibu,
  HairSample_Male. Récupérés depuis https://github.com/madjin/vrm-samples (dossier `vroid/beta`).
  Conditions officielles : https://vroid.pixiv.help/hc/en-us/articles/4402614652569
  Modifications : textures réduites à 512 px en WebP, expressions du visage retirées, stockage en base64 (`assets/*.json`).

## Animations

- **Universal Animation Library**, par Quaternius, licence **CC0**.
  Source : https://opengameart.org/content/universal-animation-library (aussi sur quaternius.com).
  Modifications : 22 clips gardés, reportés sur le squelette VRoid au chargement (`assets/Anims.json`).

## Bibliothèques

- Three.js r147 (licence MIT), chargé depuis cdn.jsdelivr.net.

## Musique, bruitages, décor, armes

- Entièrement générés par le code du jeu, aucun fichier externe.

## Version précédente

- Les personnages cartoon de la première version 3D venaient du pack KayKit Adventurers (CC0, Kay Lousberg).
  Ils ne sont plus dans le jeu.

## Bruitages du jeu Roblox (prototype 1, 14/11/2026)

Sons de la bibliothèque officielle de Roblox (créateur « Roblox ») et d'APM Music (créateur « APMOfficial »,
musique et bruitages sous licence de Roblox, utilisables dans les jeux Roblox). Gratuits sur le Creator Store.
Aucun son d'anime ni de jeu existant. Volume, pitch, égaliseur et réverbération réglés dans
`roblox/src/ReplicatedStorage/Magicaland/Sons.lua`.

| ID | Nom | Créateur | Usage |
|---|---|---|---|
| 12222046 | hit.wav | Roblox | coup de base, bouclier |
| 12222253 | victory.wav | Roblox | victoire |
| 15674975792 | Roblox_UI_Whoosh_03 | Roblox | élan de l'attaque, esquive |
| 15675028888 | Roblox_UI_Whoosh_02 | Roblox | élan, glace |
| 9120031442 | Thunder With Lion Roar Searing Blast Growl 3 (SFX) | Roblox | foudre |
| rbxasset://sounds/impact_explosion_03.mp3 | impact_explosion_03 | livré avec Roblox | feu, impact reçu, mort du monstre |
| 9043338036 | BIG IMPACT HIT 11 | APMOfficial | coup, critique, impact reçu |
| 107073250463751 | Whoosh Heavy Low | APMOfficial | esquive, boucle temporelle |
| 1846573130 | Fireball | APMOfficial | feu, brûlure |
| 139431770683502 | Boom Fuze | APMOfficial | feu, mort du monstre |
| 1843023382 | Shatter Slam | APMOfficial | glace, bouclier |
| 1841352043 | Archway Laser Quest Fierce Energy Blast 2 | APMOfficial | foudre, lumière |
| 1841352055 | Archway Laser Quest Fierce Energy Blast 3 | APMOfficial | critique |
| 1839901345 | Powered Up Chimes | APMOfficial | lumière, boucle temporelle |
| 1835336214 | Creep Next Door Dark Whoosh | APMOfficial | ombre |
| 134785366676981 | Boom Power Deep | APMOfficial | ombre, apparition, défaite |
| 1835343491 | Grit Unlimited Stutter Swell | APMOfficial | alerte avant le coup du golem |
| 1843023670 | Rumble Slam | APMOfficial | apparition du golem |
| 1837829565 | HIT-Door Slam 02 | APMOfficial | impact reçu |
| 1836473422 | Victory Fanfare Sting | APMOfficial | victoire |


## Sons, musiques et images générés par IA pour Magicaland (14/11/2026)

Tous originaux, générés à partir de descriptions écrites pour le jeu (aucun nom ni style d'œuvre existante).
Fichiers sources dans `roblox/audio/` et `roblox/visuels/`. Sons importés sur le compte Roblox du créateur.

Coûts : ElevenLabs 150 crédits (3 sons, 50 chacun). Higgsfield 29,4 crédits (451,25 → 421,85).

| Fichier | Outil | ID Roblox | Usage |
|---|---|---|---|
| higgsfield/feu.mp3 | Higgsfield Seed Audio 1.0 | 75575520099278 | élément Feu, brûlure |
| higgsfield/glace.mp3 | Higgsfield Seed Audio 1.0 | 103248004919213 | élément Glace |
| higgsfield/foudre.mp3 | Higgsfield Seed Audio 1.0 | 90346451949199 | élément Foudre |
| elevenlabs/foudre_eclair.mp3 | ElevenLabs Sound Effects | 92919685822889 | élément Foudre (variante) |
| higgsfield/lumiere.mp3 | Higgsfield Seed Audio 1.0 | 98053171874557 | élément Lumière |
| higgsfield/ombre.mp3 | Higgsfield Seed Audio 1.0 | 78029039846132 | élément Ombre |
| higgsfield/lame_1.mp3, lame_2.mp3 | Higgsfield Seed Audio 1.0 | 108948210221237, 124499126502201 | élan de l'attaque |
| higgsfield/coup_lourd_1.mp3, coup_lourd_2.mp3 | Higgsfield Seed Audio 1.0 | 71051572797802, 91171784767583 | coup, impact reçu |
| higgsfield/esquive_1.mp3, esquive_2.mp3 | Higgsfield Seed Audio 1.0 | 90723111353172, 140654368945715 | esquive |
| elevenlabs/esquive_whoosh.mp3 | ElevenLabs Sound Effects | 90609476739701 | esquive (variante) |
| higgsfield/montee_pouvoir.mp3 | Higgsfield Seed Audio 1.0 | 85176675320308 | alerte du golem, boucle temporelle |
| higgsfield/attaque_speciale.mp3 | Higgsfield Seed Audio 1.0 | 124805435185584 | coup critique |
| higgsfield/rugissement_golem.mp3 | Higgsfield Seed Audio 1.0 | 137426593653661 | apparition et mort du golem |
| higgsfield/apparition_golem.mp3 | Higgsfield Seed Audio 1.0 | 118039862995546 | apparition du golem |
| higgsfield/bouclier.mp3 | Higgsfield Seed Audio 1.0 | 99604478975577 | bouclier |
| higgsfield/victoire.mp3 | Higgsfield Seed Audio 1.0 | 99136911717446 | victoire |
| elevenlabs/victoire_stinger.mp3 | ElevenLabs Sound Effects | 86759059904136 | victoire (variante) |
| higgsfield/frappe_boss.mp3 | Higgsfield Seed Audio 1.0 | 137340020123073 | réservé au futur boss |
| higgsfield/musique_combat.mp3 (60 s) | Higgsfield Sonilo Music | 117643081330032 | musique de combat |
| higgsfield/musique_boss.mp3 (60 s) | Higgsfield Sonilo Music | 133353519976843 | réservé au futur boss |
| visuels/icone.png | Higgsfield GPT Image 2.5 (high) | — | icône du jeu (non importée) |
| visuels/miniature_1..3.png | Higgsfield GPT Image 2.5 (medium) | — | miniatures (non importées) |
| visuels/concept_*.png (5) | Higgsfield Nano Banana 2 | — | concept art des 5 races |
| visuels/boss_colosse_phase1.png, boss_colosse_phase2.png | Higgsfield Nano Banana 2 | — | concept art du boss Colosse des Ronces (3 cr) |

Boss Colosse des Ronces et animations (coup, sort, coup reçu, victoire, esquive, golem, effondrement du boss) :
construits en pièces Roblox et animés par le code, aucun fichier ni génération payante. Higgsfield après le boss : 418,85 crédits.

## Animations Roblox officielles (refonte du combat, 14/11/2026)

Monstres et personnage animés avec les animations R15 publiées par Roblox (créateur « Roblox », libres dans les jeux Roblox) :
507766388 R15Idle, 507777826 Marche R15, 507767714 Course R15, 522635514 coup d'épée R15, 522638767 fente d'épée R15.
Rigs créés par code (HumanoidDescription), aucun modèle tiers, aucun script tiers. Aucune génération payante.
