# Magicaland : Reborn in New World

Jeu isekai jouable dans le navigateur (téléphone ou PC). Version 3D : `index.html`.
En local : `python3 -m http.server`, puis `http://localhost:8000` (les modèles 3D ne se chargent pas en ouvrant le fichier directement).

- `index.html` : page, styles et écrans. `js/game.js` : règles, naissance, combat. `js/stage3d.js` : scène 3D
  (village de nuit, personnages animés, caméra, effets). `js/audio.js` : musique orchestrale et bruitages générés.
- `assets/` : modèles 3D libres de droits (voir `CREDITS.md`).
- `prototype-2d.html` : ancien prototype 2D, gardé comme référence.
- `GAME_DESIGN.md` : décisions de conception. `EPIC_INTRO_BRIEF.md` : cahier des charges de la version 3D.
- Options dans l'adresse : `?q=0`, `?q=1` ou `?q=2` force la qualité (basse, moyenne, haute).

## Déroulé

Écran titre, tirage de naissance (rien ne se choisit, sauf le nom), cinématique d'intro (le village brûle,
tu cours, Kael et Lysa te rejoignent, le chef des bandits apparaît), combat en 3D contre 3 bandits puis le chef.

## Combat

Tour par tour : Attaque, Compétences, Objets, Défense. Énergie partagée, points faibles, jauge de brèche,
statuts, esquive active (anneau de timing) avec parade parfaite au ralenti. Caméra dynamique par attaque.
Pression : battements de cœur et bords rouges quand les PV sont bas, musique à couches, ennemi qui charge.
