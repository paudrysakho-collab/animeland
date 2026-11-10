# Jeu isekai (nom provisoire) : document de conception

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
