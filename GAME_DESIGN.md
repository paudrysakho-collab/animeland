# Magicaland : Reborn in New World : document de conception

Version 0.1, 10/11/2026. Décisions prises avec l'utilisateur.

## Décisions

- **Genre** : isekai, visual novel + combats au tour par tour (inspiration : Clair Obscur : Expedition 33).
- **Plateforme** : navigateur, téléphone et PC. Aucune installation.
- **Personnages et monde** : 100 % originaux. On s'inspire des codes du genre (réincarnation,
  niveaux, races, magie, guilde, compagnes), jamais de personnages ou d'intrigues précis.
  Les codes d'un genre sont libres ; les personnages et histoires ne le sont pas.
- **Ton** : tout public. Compagnes attachantes, liens et romance, sans contenu sexuel.
  Tous les personnages sont adultes ou clairement non sexualisés.
- **Ordre de construction** : histoire solo d'abord, mode en ligne ensuite (comptes, serveur,
  un seul personnage par compte avec tirage de naissance définitif).
- **Direction artistique** : stylisée, peinte, forte lumière (clair-obscur). Décors avec parallaxe,
  personnages en couches animées, particules, musique. Pas de 3D réaliste au début.
- **Images** : provisoires pendant le prototype. Génération finale (Higgsfield ou autre)
  seulement après validation du prototype ; vérifier prix et crédits avant tout achat.

## Création du personnage (beaucoup de variables)

Tirage de naissance, qui change toute la partie :
- **Race** : humain, elfe, bête, nain, demi-esprit, etc. (à définir).
- **Famille et lieu de naissance** : noble, paysan, marchand, orphelin, tribu lointaine.
- **Don de naissance** : talent magique, affinité d'élément, chance, malédiction cachée.
- **Rareté du tirage** : commun à légendaire, avec un taux pour chaque niveau.
- **Mort possible** : certaines naissances sont dures (guerre, famine). Le joueur peut mourir
  tôt, et c'est une fin possible, pas un échec technique.

## Histoire

- Chapitres : naissance, enfance, apprentissage de la magie, premier départ, guilde, royaume.
- Choix qui changent les variables (affinités, réputation, force, magie, argent).
- Compagnes et compagnons : lien (affinité) qui débloque des scènes et des capacités en combat.

## Combat

- Tour par tour, avec esquive ou parade au bon moment (inspiration Clair Obscur).
- Attaques, soins, défense, objets, magie selon l'élément.
- Les variables de naissance changent les compétences disponibles.

## Combat validé par l'utilisateur (10/11/2026)

Le mode de combat du prototype est la bonne direction : tour par tour lisible comme Pokémon,
Final Fantasy X et Clair Obscur (équipe à gauche, ennemis en face, menu en bas à droite),
avec esquive active et parade. Les graphismes et animations viennent bien plus tard.

Logique commune à garder dans la durée :
- soins, boucliers et objets qui coûtent un tour ou de l'énergie ;
- points faibles et résistances par élément ;
- jauge de brèche (le « break » de FFX) ;
- statuts (poison, brûlure, gel, sommeil, bénédiction, malédiction) à ajouter ;
- compétences apprises et équipement à ajouter.

Piste à tester : contres et esquives plus variés (contre de classe, esquive parfaite qui donne un tour bonus).

Mode en ligne : faisable, comme les combats en ligne de Pokémon. Le serveur arbitre chaque tour
(dégâts, énergie, résultat de l'esquive) pour éviter la triche. À faire après le mode histoire.

## Étapes

1. Prototype : création de perso (naissance aléatoire), 1 chapitre, 1 combat, sauvegarde locale.
2. Compagnons, plusieurs chapitres, plus de variables.
3. Direction artistique finale, musique, animations.
4. Mode en ligne.

## Statuts (implémentés, 10/11/2026)

- Négatifs : poison (3 tours), brûlure (3), gel (1, la cible passe son tour), paralysie (2, 1 chance sur 2 de passer son tour), sommeil (2, se brise au premier coup), malédiction (3, dégâts -25 %).
- Positifs : régénération, bénédiction (dégâts +25 %), carapace (dégâts subis -30 %).
- Durée fixe en tours. Les dégâts sur la durée tombent au début de la phase de la cible.
- Infligés par l'élément : Feu brûle, Glace gèle, Foudre paralyse, Ombre (poison, sommeil ou malédiction), Lumière bénit un allié.
- Les ennemis en infligent aussi : une parade parfaite annule le statut, une esquive correcte divise la chance par 2, l'Esprit réduit la chance (jusqu'à -40 %).
- Boss : chance divisée par 3 sur les contrôles. Après un contrôle, la cible est protégée 1 tour.
- Réactions : Feu sur gelé = fonte (+50 %), Foudre sur gelé = choc (+40 %), Glace sur brûlé = éteint.
- Guérison : objets (Antidote, Panacée) et Soin de Lysa.

## Intro de la démo

Écran titre « Magicaland : Reborn in New World », tirage de naissance, résumé de la vie tiré de la fiche
(race, lieu, famille, don), puis bandits qui attaquent un village la nuit (3 bandits, puis le chef).
Ambiance clair-obscur : noir, violet, doré, flammes du village.

## Décisions du 11/11/2026

- **Style visuel** : anime sobre en cel-shading, proportions adultes, attaques très spectaculaires.
- **Monde** : zones à explorer à pied (village, forêt ancienne, capitale, ruines), décors générés par le code.
  Pas de monde ouvert d'un seul tenant. Pas de relevés 3D de Google (interdits) ; nature et forêts « comme avant ».
- **Roblox** : portage après la version web. Les règles (naissance, statuts, combat) restent séparées de
  l'affichage pour faciliter la réécriture en Luau. Roblox Studio se teste sur ordinateur, pas dans le cloud.

## Décisions du 12/11/2026 : version Roblox

- **Jeu** : Magicaland simplifié sur Roblox. Naissance aléatoire, village partagé entre joueurs, combats solo.
- **Combat en temps réel** (changement par rapport au prototype web, qui était au tour par tour). Les règles de fond restent
  (énergie, points faibles, statuts, parade parfaite, jauge de brèche) mais le déroulement est à reconcevoir : le joueur bouge,
  frappe et esquive en direct. À valider avec lui : types d'attaque, durée des combats, difficulté.
- Roblox Studio pas encore installé par l'utilisateur (12/11/2026).

## Choix du 14/11/2026 (version Roblox, type C : RPG de collection)

- Raison de revenir : collection de dons et de races, 3 quêtes du jour d'environ 10 min, un boss de la semaine.
- Monétisation : cosmétiques et passe de confort (emplacements de collection). **Aucun tirage payant.** Rien n'est monétisé sans accord.
- Jeu à plusieurs : boss de village en coopération, récompense commune.
- Contenu : un ajout par mois (zone ou événement), monstres et quêtes faits à partir de gabarits réutilisables.
- Notes dans `potentiel/notes.json`, historique dans `CRITERES.md`.
