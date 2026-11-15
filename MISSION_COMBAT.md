# Mission : refonte cinématique du combat (consignes de l'utilisateur, 15/11/2026)

Résumé fidèle et complet des consignes. En cas de doute, l'utilisateur tranche (AskUserQuestion via la session cloud).

## Règle fondamentale
L'**animation du personnage** est le cœur de chaque attaque. VFX, caméra et sons la renforcent, ils ne la remplacent pas.
Jamais un personnage immobile avec des particules devant lui. Une animation réussie reste compréhensible sans aucun effet.

## Structure définitive du combat
| Catégorie | Compétences |
|---|---|
| Attaques classiques | Coups de sabre rapides |
| Attaques physiques spéciales | 3 |
| Magie | 2 attaques offensives |
| 3e compétence de magie | 1 transformation (la SEULE transformation du jeu) |
| Déplacement | Dash réactif |

**Supprimer** les anciennes transformations, éveils, jauges d'éveil (dont la barre d'ultime et le mode « sabre doré » s'ils existent) et leurs interfaces,
après une copie de secours et une branche Git. Ne rien casser d'autre. Préparer (sans l'implémenter) 3 systèmes distincts : **style de combat**,
**élément**, **capacité innée** (liée au personnage ou à la race, par exemple dragon).

## Partie I : base
- **Monstre** : remplacer le monstre cubique par un humanoïde horrifique modélisé dans Blender. Plus grand qu'un avatar, élancé, peau noir charbon,
  longues griffes, longs cheveux noirs, visage inquiétant, yeux rouges lumineux. Il marche, court, attaque aux griffes, réagit aux coups, peut être projeté
  en l'air et subir des combos aériens. Silhouette d'abord, modèle léger.
- **Sabre** : katana détaillé et élégant (courbure, poignée, garde travaillée, reflets métalliques), inspiré de l'esthétique du sabre de Rengoku, mais **design original**.
  Partir du sabre existant s'il y en a un. **Pas d'aura élémentaire permanente sur le sabre** : il ne s'enflamme que pendant la transformation feu.
- **Attaques de base** : plus rapides et mieux enchaînées ; **supprimer les traînées blanches** ; **garder les impact frames** (très appréciées) ;
  effets élémentaires subtils (feu : petites flammes et étincelles ; eau : gouttelettes ; terre : poussière et fragments ; vent : courants d'air). Impact synchronisé au contact de la lame.
- **Dash** : il ne marche qu'une fois sur deux, c'est PRIORITAIRE. Auditer les entrées, les recharges et les interruptions ; réactivité immédiate ;
  recharge plus courte et équilibrée ; un dash en recharge doit être clairement signalé (différent d'un bug). Tester des activations successives.

## Partie II : 3 attaques physiques (type feu d'abord)
1. **Slash à distance** : posture, armé, coup descendant jusqu'au sol ; au contact, une vague de feu part vers la cible et explose à l'impact.
   Synchronisation parfaite lame et vague. Pour les autres éléments : repenser, pas recolorer.
2. **Danse des dix slashes** (environ 5 s, à courte portée) : courte préparation, puis environ 10 coups de directions différentes en se déplaçant
   **réellement** autour de la cible (les positions dessinent une étoile), brèves traînées élémentaires, petits impacts, variations de rythme, finale puissante. Ciblage cohérent.
3. **Combo aérien ultime** (inspiration : Trunks du futur contre Freezer) : frappe qui projette la cible en l'air, poursuite en saut, la caméra suit,
   plusieurs coups aériens aux animations distinctes, suspension, puis traversée éclair avec le sabre ; environ 0,5 s de noir et blanc, impact frames fortes,
   effet de coupure stylisé (sans démembrement), son très puissant, le personnage finit de l'autre côté. Caméra cinématique mais jouable, locale au joueur.
   Gérer la mort ou la disparition de la cible pendant la séquence.

## Partie III : magie du feu
1. **Projectile** (inspiration : la « Big Bang Attack » de Vegeta) : posture, bras levé, paume vers la cible, énergie ardente qui se concentre avec de petites décharges,
   pose d'incantation, lancer brutal, recul de la main, explosion. Préparation courte et percutante.
2. **Explosion de feu absolue** (inspiration : la « Final Explosion » de Vegeta) : posture dramatique, corps contracté, pulsations lumineuses, aura qui monte,
   tension à la caméra, libération, gigantesque explosion circulaire, onde de choc, son puissant. **Coût en vie, immobilisation ou vulnérabilité : à discuter avec l'utilisateur,
   pas de sacrifice mortel automatique.**
3. **Transformation « Lame Incandescente »** : le personnage regarde son sabre (gros plan), concentration, le sabre est ramené devant le visage, les flammes
   se propagent sur la lame jusqu'à l'envelopper, aura ardente, posture plus intimidante, puis retour fluide au jeu. **Demander à l'utilisateur** :
   la durée, les dégâts, la vitesse, l'effet sur les 3 attaques physiques, la recharge et les conditions.

## Partie IV : autres éléments
Feu : agressif, explosif. Eau : fluide, circulaire. Terre : lourd, brutal. Vent : rapide, tranchant (pistes seulement).
**Le feu d'abord, excellent et validé**, puis proposer des concepts pour les autres éléments (choix par AskUserQuestion). Pas de recoloriage.

## Partie V : outils
- **Blender** : monstre, sabre, toutes les animations, avec de vraies poses clés, anticipation, accélération et récupération.
  Pipeline : inspecter, créer ou corriger, exporter, importer, configurer, synchroniser, tester, corriger. Utiliser les marqueurs d'animation (KeyframeMarker) pour synchroniser.
- **Higgsfield** : vérifier ce qui est réellement accessible (CLI sur le PC, extension Blender, Character Animation, 3D Model, Motion Control, Cinema Studio).
  Character Animation en priorité, si elle produit une animation 3D modifiable (sinon, s'en servir comme référence). 3D Model pour une base du monstre et du sabre,
  retravaillée dans Blender. Les vidéos ne servent que de storyboards : **une belle vidéo n'est pas une animation jouable**.
  Annoncer le coût avant les générations importantes (au-delà de 50 crédits par jour : demander l'accord).
- **YouTube** : recherche réelle (yt-dlp et images). Fiche par attaque : vidéos, timestamps, techniques retenues. Ne jamais prétendre avoir vu des images si seule la transcription a été lue.
- Références (s'inspirer seulement, ne rien copier) : Blox Fruits, Jujutsu Shenanigans, The Strongest Battlegrounds, Rengoku, Zoro, Vegeta, Trunks contre Freezer, Devil May Cry.

## Partie VI : collaboration
Utiliser souvent AskUserQuestion pour les choix créatifs, avec 2 à 4 options concrètes et ce qui les distingue. Regrouper les questions.
Ne pas déranger l'utilisateur pour des détails. Être force de proposition : pour chacune des 6 compétences, proposer des alternatives plus originales
(chorégraphie, originalité, intérêt en combat, références, difficulté), et laisser l'utilisateur choisir entre son idée et les propositions.
Ne pas ajouter de compétences.

## Partie VII : étapes
0. Audit (structure, scripts, animations, compétences, effets, transformations, connexions Blender, Roblox, Higgsfield et YouTube, performances, réactivité).
1. Recherche et direction artistique (storyboards, alternatives, questions).
2. Nettoyage (sauvegarde, suppression des éveils et transformations, correction du dash et des attaques de base).
3. Assets (monstre, sabre, animations, vérifiés dans Roblox).
4. Prototype feu : slash à distance, dix slashes, combo aérien, projectile, explosion, transformation.
5. Tests (gestes, mécanique, fluidité, caméra, synchro, réactivité, collisions, multijoueur, courtes captures vidéo si possible).
6. Concepts pour les autres éléments.

## Critères de refus
Personnage immobile pendant un effet ; explosion à la place d'une chorégraphie ; compétences trop semblables ; animations lentes ou artificielles ;
lame désynchronisée des impacts ; caméra injouable ; assets Blender mal intégrés ; animation qui ne marche qu'en démo ; compétence qui ne touche pas ;
anciens éveils ou transformations encore présents. Prévoir une option pour réduire les effets de caméra et les flashs.

## Compte rendu à chaque étape
Ce qui a été modifié, les fichiers et assets concernés, les références vidéo, les tests et leurs résultats, ce qui reste à corriger, les décisions à prendre.
Distinguer : **conçu / implémenté / importé / testé / validé**. Ne rien déclarer terminé sans vérification.
