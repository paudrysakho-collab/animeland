# Isekai : prototype de combat

Prototype jouable dans le navigateur (téléphone ou PC). Un seul fichier : `index.html`.
En local : `python3 -m http.server`, puis `http://localhost:8000`.

## Naissance (rien ne se choisit, sauf le nom)

Tirage au sort de : race (11), lieu de naissance (8), famille (10), divinité de la réincarnation (11),
7 caractéristiques (Force, Vitalité, Intelligence, Esprit, Agilité, Charisme, Chance), 5 affinités
de magie, don d'isekai (8, de commun à légendaire), 2 ou 3 traits de caractère (18), malédiction
cachée rare, fratrie, argent de départ, apparence. Un rang de naissance (D à SS) résume le tout.
Sauvegardé dans le navigateur ; le bouton « Nouvelle naissance » sert aux tests.

## Combat (style Pokémon / Final Fantasy)

- Ton équipe en bas à gauche, les ennemis en face en haut à droite, menu en bas à droite :
  Attaque, Compétences, Objets, Défense.
- Énergie partagée (⚡), éléments (point faible +50 %, résistance -40 %), jauge de brèche.
- Esquive active : touche l'écran quand l'anneau rejoint le cercle doré (parade parfaite = 0 dégât + riposte).
  L'agilité élargit les fenêtres. Case « mode facile ».
- Critiques selon la Chance, passifs selon le don d'isekai.
- Images provisoires dessinées en SVG.

## À faire

Équilibrage, plus de variables (effets de statut, compétences apprises), histoire, vraies images.
