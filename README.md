# Isekai : prototype de combat

Prototype jouable dans le navigateur (téléphone ou PC). Un seul fichier : `index.html`.

Pour l'ouvrir en local : `python3 -m http.server` dans ce dossier, puis `http://localhost:8000`.

## Ce que contient le prototype

- **Naissance** : tirage de la race, de la famille et du don (élément + rareté). Sauvegardé dans le
  navigateur ; le bouton « Nouvelle naissance » est réservé aux tests.
- **Combat au tour par tour**, 3 héros (toi, Kael, Lysa) contre 2 vagues (2 monstres, puis un gardien).
  - Énergie partagée (⚡) : +1 par tour, +1 avec une attaque gratuite, +1 avec une parade.
  - Éléments : point faible (+50 % dégâts), résistance (-40 %).
  - Jauge de brèche : un monstre « brisé » prend +50 % de dégâts et saute son attaque.
  - **Esquive active** : à chaque attaque ennemie, touche l'écran quand l'anneau rejoint le cercle doré.
    Parade parfaite = 0 dégât, riposte et brèche. Esquive correcte = dégâts réduits à 35 %.
    Case « mode facile » pour des fenêtres plus larges.
- Images provisoires (emoji). Aucun son externe (petits bips générés).

## À équilibrer ensuite

Dégâts, vie des monstres, coût des compétences, durée de l'anneau, nombre d'attaques par monstre.
