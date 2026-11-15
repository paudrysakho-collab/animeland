# Analyse des jeux de combat anime sur Roblox (novembre 2026)

But : tirer des **principes** pour « From Nothing: Reborn » (RPG isekai, sabre en temps réel). On ne copie ni mouvements, ni noms, ni assets.

Légende : **[S n]** = source numérotée en bas. **(non vérifié)** = valeur courante dans la communauté ou dans nos notes, sans source fiable trouvée pendant cette recherche. Les wikis officiels (Fandom/wiki.gg) n'ont pas tous été accessibles : beaucoup de chiffres viennent de guides tiers, qui se contredisent parfois. À confirmer en jeu avant de s'en servir comme référence absolue.

## (a) Tableau comparatif

| Jeu | Combo de base (M1) | Fin de combo | Compétences | Ultime / éveil | Défense / mobilité | Points vérifiés |
|---|---|---|---|---|---|---|
| The Strongest Battlegrounds (TSB) | 4 M1 ; le 4e coup sert de déclencheur aux techs [S1] ; un « extend » à 7 M1 a été patché [S1] | Knockback, ou variantes uppercut / downslam au 4e coup [S2] | 4 par personnage (touches 1-4) (non vérifié) | Barre remplie en infligeant/subissant des coups, « awakening » avec nouveau moveset ; certains coups utilisables une fois par éveil [S5] | Dash avant/côté (Q), utilisable pour se relever d'un ragdoll s'il est rechargé [S2] ; wall combo avec 5 s de recharge [S2] ; block maintenu (F) (non vérifié) | Stun M1 plus long que l'intervalle entre deux coups, ce qui permet de « retarder » les M1 pour récupérer un dash [S2] ; ~86 k joueurs simultanés en juillet 2026 [S9] |
| Jujutsu Shenanigans | M1 en chaîne de 4 (non vérifié) | Knockback (non vérifié) | 4 par personnage (non vérifié) | Éveil puis « second éveil » ; un coup spécial chronométré (type Black Flash) remplit la jauge, par ex. la moitié de la barre de super-éveil pour un personnage [S3][S4] ; le nombre exact de réussites requises varie selon les patchs (2 ou 3) [S3][S4] | Block, dash (non vérifié) | Mécanique de **timing récompensé** qui accélère l'éveil [S3][S4] |
| Heroes Battlegrounds | 4 M1 (non vérifié) | Knockback (non vérifié) | 4 par héros (non vérifié) | Éveil par barre (non vérifié) | Block, dash (non vérifié) | Aucune source fiable trouvée |
| Type Soul | M1 par arme ; un style tire au hasard des M1 de plusieurs armes, les effets d'état d'un M1 se transmettent [S6] | Variable selon l'arme | Compétences par arme/race (non vérifié) | Libérations par paliers (non vérifié) | **Parry** : certains stuns empêchent explicitement de parer pendant leur durée [S6] | Équilibrage via patch notes sur stun et parry [S6] |
| Blox Fruits (épée) | Combo M1 à l'épée (non vérifié : 4-5 coups) | — | Z, X (parfois C) par épée, débloqués par **maîtrise** : Katana Z à maîtrise 1, X à 20 [S7] ; épées légendaires Z/X à 150-300 [S7b] | Pas d'ultime classique ; montée en puissance par maîtrise et éveils de fruits | Block (non vérifié pour le parry parfait : seule une source non fiable) | La **progression par maîtrise** débloque les compétences [S7][S7b] |
| Grand Piece Online | M1 épée/style | — | Compétences Z/X/C/V selon le style (ex. Rokushiki : X, Z, C, V) [S8] | — | Block maintenu sur F [S8] | Touches Z/X/C/V standard du genre [S8] |

## (b) Chiffres typiques du genre

| Paramètre | Valeur typique | Statut |
|---|---|---|
| Coups dans un combo M1 | 4 (TSB [S1]) ; 4-5 ailleurs | 4 vérifié pour TSB |
| Délai entre deux M1 | 0,3 à 0,45 s | non vérifié |
| Stun d'un M1 | un peu plus long que l'intervalle entre coups (≈0,5-0,7 s) | principe vérifié [S2], valeur non vérifiée |
| Fenêtre de dash après le dernier coup | ≈0,2 s (wall combo TSB) | [S2] |
| Recharge d'un combo/tech spécial | 5 s (wall combo TSB) | [S2] |
| Recharge du dash | 2 à 5 s, côté plus court que avant | non vérifié |
| Recharges des compétences | 6 à 25 s | non vérifié |
| Fenêtre de perfect block / parry | 0,15 à 0,25 s | non vérifié |
| Durée d'un éveil | 60 à 120 s | non vérifié |
| Cinématique d'ultime | 1,5 à 4 s, avec invulnérabilité | non vérifié |
| Particules par émetteur | max 400/s, **100/s sur mobile** | [S10] officiel |

## (c) VFX et textures : techniques et budgets mobile

Techniques Roblox courantes pour des effets « premium » :
- **Flipbooks de particules** : une texture 1024×1024 découpée en 2×2 (512 px), 4×4 (256 px) ou 8×8 (128 px) [S11] ; la doc indique que la lecture flipbook exige une texture 1024×1024 [S13], et une bêta permet des grilles personnalisées non carrées pour réduire la mémoire [S12].
- **Beams** pour traînées de lame et éclairs (segments + texture qui défile) ; un développeur signale que les beams sont les plus coûteux en lag s'ils sont mal dosés [S11].
- **MeshParts animés** (anneaux, croissants de lame) avec transparence animée par TweenService (non vérifié comme standard, pratique courante).
- **Impact frames** : 1 à 3 images avec `ColorCorrectionEffect` (contraste/saturation extrêmes, inversion) + caméra secouée (non vérifié, technique courante).
- **Hitstop** : figer les deux personnages 0,05 à 0,1 s à l'impact (non vérifié, principe classique de game feel).
- Ennemi principal de la performance : **le fill rate** (pixels transparents superposés), plus que le nombre d'émetteurs [S14] (source communautaire).

Budgets proposés pour mobile (nos cibles, pas des chiffres sourcés) :
| Élément | Budget |
|---|---|
| Texture flipbook | 1024×1024 total, 4×4 = 16 images de 256 px |
| Textures simples (étincelle, braise) | 256×256, 512 max |
| Particules visibles par impact | 20-40 ; 100-150 pour l'ultime |
| Rate par émetteur | ≤ 100/s (plafond mobile [S10]) |
| Beams actifs simultanés | ≤ 6 par joueur |
| Lights dynamiques (PointLight) | 1 par impact, durée < 0,2 s |
| Durée de vie des particules d'impact | 0,2 à 0,6 s |
| Mode « qualité basse » | divise les rates par 2 selon `UserSettings().GameSettings.SavedQualityLevel` |

## (d) Améliorations priorisées pour « From Nothing: Reborn »

1. **Hitstop + impact frame** sur le 5e coup de chaque combo et sur l'ultime (0,06-0,1 s, ColorCorrection 1-2 images). Gain de ressenti le plus fort pour le coût le plus faible.
2. **Stun calibré** : stun de chaque coup légèrement supérieur à l'intervalle entre coups (principe [S2]), stun cassé au 5e coup pour éviter les boucles infinies.
3. **Fins de combo différenciées** : combo A finit en knockback horizontal (vers un mur), combo B en projection vers le haut (suite aérienne possible). Mêmes principes que le genre, animations à nous.
4. **Hitbox côté serveur sur la lame** : balayage (spherecast/raycast entre positions successives de la lame) seulement pendant la fenêtre active ; une cible touchée une fois par coup ; tolérance de latence (rembobinage court de 100-150 ms).
5. **Dash cancel** : permettre d'annuler la récupération d'un coup par un dash, avec recharge (3 s avant, 2 s côté) ; dash utilisable pour se relever d'un ragdoll s'il est rechargé (principe [S2]).
6. **Block + parry** : block maintenu réduit les dégâts et use une jauge de garde ; parry dans une fenêtre courte (≈0,2 s) qui étourdit l'attaquant ; certains coups lourds « imparables » signalés par un flash de couleur (principe vu chez Type Soul [S6]).
7. **Recharge anti-répétition** des techniques spéciales (comme les 5 s des wall combos [S2]) pour garder des combos variés.
8. **Jauge de « Couronne de l'Aube »** qui se remplit en touchant, en parant (bonus) et en subissant des dégâts ; un geste de timing réussi (parry parfait) donne un gros bonus, à l'image du timing récompensé de Jujutsu Shenanigans [S3].
9. **Ultime en deux temps** : cinématique de 2-3 s, joueur invulnérable, puis 45-60 s d'état éveillé avec moveset de sabre modifié (traînée dorée, coups plus longs) ; la caméra cinématique est désactivable.
10. **Éclairs réalistes** : Beams segmentés régénérés 2-3 fois en 0,15 s + flash PointLight bref + texture d'arc 256 px ; jamais d'éclair permanent.
11. **Feu réaliste** : flipbook 4×4 de flammes (1024) + braises 256 px à faible rate + fumée sombre ; budget ≤ 40 particules par coup.
12. **Mode qualité mobile** : rates ÷2 et pas de flipbook secondaire sur appareils faibles ; test sur téléphone réel ([S10] plafond 100/s).
13. **Sons en couches** : swing (whoosh), impact (métal/chair), queue grave pour l'ultime ; légère variation de hauteur aléatoire à chaque coup.
14. **Progression sans tirage payant** : débloquer de nouveaux styles de sabre et la deuxième compétence par la maîtrise d'arme (principe de Blox Fruits [S7]), pas par des tirages.
15. **Lisibilité** : indicateur de recharge clair (touches 1-4 ou Z/X/C, standard du genre [S8]) et prise en charge manette/tactile.

## (e) Sources

- [S1] Bloxodes, techniques de TSB : https://bloxodes.com/wiki/the-strongest-battlegrounds/techniques
- [S2] Guides TSB (délai M1, dash après ragdoll, wall combo 5 s, dash 0,2 s) : https://rblxguide.com/games/the-strongest-battlegrounds/techs ; https://games.gg/fr/roblox/guides/guide-de-combat-the-strongest-battlegrounds/ ; https://allthings.how/how-to-do-burst-damage-in-the-strongest-battlegrounds/
- [S3] Sportskeeda, Jujutsu Shenanigans « Perfection » : https://www.sportskeeda.com/roblox-news/jujutsu-shenanigans-perfection-guide
- [S4] Pro Game Guides, second éveil de Mahito : https://progameguides.com/roblox/jujutsu-shenanigans-mahito-second-awakening-explained-roblox/ ; Prima Games, Black Flash : https://primagames.com/gaming/how-to-black-flash-in-jujutsu-shenanigans
- [S5] Wiki communautaire TSB (coups d'éveil) : https://sites.google.com/view/tsbwiki/kj
- [S6] Patch notes Type Soul (2024) : https://progameguides.com/roblox/latest-type-soul-patch-notes-update/
- [S7] Blox Fruits Wiki, Katana : https://blox-fruits.fandom.com/wiki/Katana ; [S7b] https://progameguides.com/roblox/strongest-swords-in-roblox-blox-fruits/
- [S8] Sportskeeda, styles de combat GPO : https://www.sportskeeda.com/roblox-news/grand-piece-fighting-style-guide
- [S9] Classement juillet 2026 : https://studiokrew.com/blog/top-roblox-games-july-2026/
- [S10] Doc Roblox, émetteurs de particules : https://create.roblox.com/docs/effects/particle-emitters
- [S11] DevForum, sortie des flipbooks : https://devforum.roblox.com/t/particles%E2%80%99-flipbook-release/2029388/63
- [S12] DevForum, flipbooks personnalisés : https://devforum.roblox.com/t/client-beta-optimize-your-particle-animations-with-custom-flipbook-layouts/4005128
- [S13] Doc Roblox, enum ParticleFlipbookTextureCompatible : https://create.roblox.com/docs/reference/engine/enums/ParticleFlipbookTextureCompatible.md
- [S14] Guide communautaire VFX (fill rate) : https://skillsmp.com/creators/nonlooped/roblox-suite/roblox-vfx

Non trouvés : chiffres officiels de Heroes Battlegrounds et Peroxide, durées exactes d'éveil, fenêtres de parry, recharges de dash. Ils sont marqués « non vérifié » ci-dessus.
