# Les meilleures idées des gros jeux Roblox, une par critère

Écrit le 12/11/2026, à partir de recherches web. Les sources officielles Roblox sont marquées **[Roblox]**.
Les blogs et analyses de la communauté sont marqués **[blog]** : ce sont des avis, leurs chiffres ne sont pas vérifiés.
Chaque idée est une proposition pour Magicaland, pas une règle. Elle vient de `CRITERES.md` (grille pondérée).

| # | Critère (poids) | Meilleure idée retenue | Source | Application à Magicaland | Risque |
|---|---|---|---|---|---|
| 1 | Raison de revenir (25 %) | **Boucle courte et quêtes finissables en une séance** (25 à 35 min), plus **événements limités** | [blog] | 3 quêtes du jour de 10 min, une quête de la semaine ; événement saisonnier (ex. nuit de l'incendie) avec un don exclusif | Récompense de connexion « plate » : les avis divergent, certains disent qu'elle ne fait revenir que le lendemain. Lier la récompense à la boucle de jeu |
| 1b | idem | **Collection et échanges** (œufs, animaux rares : Adopt Me!) | [blog] | Collection de dons, de races et d'objets ; échanges plus tard | Échanges = fraude et arnaques, à modérer |
| 2 | Premières minutes (15 %) | **Du plaisir dans les 5 premières minutes** et **une mécanique à la fois**, récompense avant la 2e minute | [Roblox] pour les 5 minutes, [blog] pour le reste | Naissance, première attaque et première récompense en moins de 2 minutes. Cinématique d'intro courte et passable | Un tutoriel obligatoire trop long fait fuir. Pas de mur de texte |
| 3 | Prise en main (10 %) | **Un seul geste à la fois, zéro écran inutile** | [blog] | Commandes tactiles testées dès le premier prototype | Je n'ai pas trouvé la part de joueurs mobiles sur Roblox : à vérifier avant de choisir les commandes |
| 4 | Social (10 %) | **Bonus d'amis, coop, tâches partagées** ; « le lien social est le facteur de rétention le plus fiable » | [blog] | Boss de village à plusieurs, bonus quand on joue en groupe | Lourd à synchroniser : après la première version |
| 5 | Originalité (10 %) | Identité forte (naissance isekai à variables) | notre analyse | Mettre la naissance et le monde au centre de l'icône et du titre | Ne pas copier Pokémon : Brick Bronze a été retiré pour ça |
| 6 | Monétisation saine (10 %) | **Passes (achat unique) pour les avantages permanents, produits (achat répétable) pour les consommables** | [Roblox] | Passe cosmétique, accélérateurs, emplacements de collection. Pas de puissance achetable | Je n'ai pas trouvé de texte officiel sur le « payer pour gagner » |
| 6b | idem | **Objets aléatoires payants : afficher les probabilités en pourcentage, total exact de 100 %, avant l'achat**, mises à jour en direct quand une aide à la chance est active, bloqués dans les régions non éligibles | [Roblox] (page officielle « paid random items ») | Un tirage de don de naissance **payant** serait concerné. Un tirage **gagné en jouant** ne l'est pas | Règle à revérifier avant de construire. Le gacha payant est le point le plus risqué du projet |
| 7 | Technique (10 %) | Rester léger, tester sur téléphone modeste | notre analyse | Budget de pièces et d'effets défini dès le début | Roblox gère l'appareil mais pas notre contenu |
| 8 | Contenu régulier (10 %) | **Événements saisonniers** et mises à jour courtes | [blog] | Un calendrier réaliste pour une personne et une IA : une mise à jour par mois | Promettre plus que ce que l'on peut tenir |

## Ce que cela change dans le plan

- Le **tirage de naissance** est la meilleure idée à garder : c'est notre accroche, et un tirage **gratuit à la création du perso** n'est pas un achat aléatoire.
  Ne pas le rendre payant sans avoir relu la politique de Roblox.
- La **boucle quotidienne** (critère 1, le plus lourd) doit être conçue avant les combats : sans elle, un beau combat ne fait pas revenir.
- Avant tout achat dans le jeu, vérifier : probabilités affichées, régions, âge, et `PolicyService` côté code.

## Ce qui reste incertain

- Les chiffres de rétention des blogs (par exemple +40 % de rétention à 7 jours avec les récompenses quotidiennes) ne citent aucune étude.
- Les avis divergent sur les bonus de connexion quotidiens.
- Aucune source trouvée sur la part de joueurs mobiles sur Roblox.

## Sources

- Rétention, analytique : https://create.roblox.com/docs/production/analytics/retention.md
- Première impression et onboarding : https://create.roblox.com/docs/en-us/production/game-design/onboarding
- Engagement : https://create.roblox.com/docs/en-us/production/analytics/engagement
- Monétisation : https://create.roblox.com/docs/production/monetization.md
- Objets aléatoires payants : https://create.roblox.com/docs/en-us/production/monetization/paid-random-items
- Retour des joueurs (articles de développeurs) : https://medium.com/roblox-developer/from-the-devs-a-glance-aat-tools-you-can-employ-to-bring-players-back-to-your-game-by-e04a80f56c5
- Mécaniques de rétention (analyse) : https://rowatcher.com/news/how-top-roblox-games-keep-players-coming-back-retention-mechanics-that-work
- Boucle de jeu et rétention (analyse) : https://rowatcher.com/news/roblox-d7-retention-is-a-loop-problem-not-a-content-problem
