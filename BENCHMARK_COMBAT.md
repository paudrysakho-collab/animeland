# Comparaison avec les meilleurs jeux de combat anime de Roblox

Écrit le 15/11/2026. Jeux de référence : les « battlegrounds » anime les plus joués (The Strongest Battlegrounds, Jujutsu Shenanigans,
Heroes Battlegrounds, Anime Battlegrounds) et les RPG d'action anime. Ce sont des **observations générales sur le genre**, pas des mesures :
à vérifier en jouant. On s'inspire des principes, on ne copie ni les mouvements, ni les noms, ni les effets d'un jeu précis.

## Ce que ces jeux font tous

| Point | Ce qu'ils font | Chez nous (15/11) | À corriger |
|---|---|---|---|
| Réactivité | Le coup part en moins de 0,1 s après le clic ; l'animation démarre côté client tout de suite, le serveur valide après | À vérifier après l'intégration | Lancer l'animation côté client dès le clic (prédiction), le serveur ne fait que valider les touches |
| Combo | 4 à 5 clics ; le dernier coup projette l'ennemi au loin (knockback), avec un son plus lourd | 5 coups, final avec impact frame | Ajouter le knockback et le ralenti de l'ennemi sur le coup final |
| Hit-stop | Toutes les touches figent les deux personnages 0,03 à 0,08 s | Seulement sur le coup final | Petit hit-stop (0,03 s) sur chaque coup qui touche, pas dans le vide |
| Réaction de l'ennemi | Animation de choc (« hit reaction ») à chaque touche, petit recul, flash blanc sur l'ennemi | À vérifier | Animation de choc + Highlight blanc 0,05 s sur la cible |
| Lisibilité | Effets puissants mais courts ; on voit toujours les personnages | Effets réalistes en cours | Limiter chaque effet à moins de 0,4 s, sauf l'ultime ; pas de flash plein écran pour les autres joueurs |
| Ultime | Cinématique de 2 à 4 s, caméra qui tourne, invulnérabilité pendant l'ultime, barre de charge visible | 3,5 s, caméra scriptée | Ajouter : barre d'ultime qui se remplit en frappant, invulnérabilité pendant l'ultime, lancement seulement si une cible est proche |
| Déplacement | Dash avec touche dédiée (Q), saut, esquive rapide, un peu de bloc ou parade | Esquive flash existante | Vérifier qu'on peut dasher entre deux coups (annulation du combo par le dash) |
| Son | Chaque coup a un son de souffle et un son de touche différents ; le son de touche est plus fort que le souffle | 6 sons | Varier légèrement la hauteur des sons à chaque coup (±5 %) pour éviter la répétition |
| Téléphone | Gros boutons à l'écran (attaque, dash, ultime), effets allégés automatiquement | À vérifier | Boutons tactiles + mode d'effets allégé si le téléphone est lent |
| Performances | Pas de chute d'images pendant l'ultime, même à 10 joueurs | Test de 20 utilisations prévu | Nettoyer tous les effets (Debris), réutiliser les objets, limiter les particules |

## Ce qui nous distingue déjà

- Les **touches calculées le long de la lame** (plus précises que les boîtes de touche classiques).
- Un **monde isekai avec progression** (naissance, collection, quêtes) : la plupart des battlegrounds n'ont que le combat.
- Des ultimes **originaux**, faits à la main.

## Liste à donner à la session locale après l'étape 9

1. Prédiction côté client : l'animation part dès le clic.
2. Hit-stop de 0,03 s sur chaque touche, et animation de choc + flash blanc sur la cible.
3. Knockback et ralenti de l'ennemi sur le coup final du combo.
4. Barre d'ultime (se remplit en frappant), invulnérabilité pendant l'ultime.
5. Annulation du combo par le dash.
6. Variation de hauteur des sons (±5 %).
7. Boutons tactiles et mode d'effets allégé.
8. Effets limités à 0,4 s (sauf ultime), nettoyage systématique.
