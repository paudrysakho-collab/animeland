# Cahier des charges : intro cinématique 3D et combat 3D de Magicaland

Préparé le 10/11/2026 pour la session « première version ultime ». À lire avec `GAME_DESIGN.md` et `index.html`
(prototype 2D actuel, à garder comme référence de règles : le moteur de combat, les statuts et la naissance
ne changent pas, seul l'affichage passe en 3D).

## Décisions de l'utilisateur

- **Périmètre** : cinématique d'intro 3D + combat en 3D.
- **Modèles** : libres de droits (CC0 de préférence) avec leurs animations. Vérifier et noter la licence de
  chaque fichier dans un fichier `CREDITS.md`. Pas de modèle sous licence restrictive.
- **Musique** : orchestral sombre et héroïque, faite en code (Web Audio), sans fichier externe.
- **Qualité** : maximum de beauté (ombres douces, brume, particules, bloom), avec une qualité réglable
  automatiquement pour tenir 30 images/s au minimum sur téléphone.
- **Voix** : aucune. Textes, cris et bruitages générés par code.
- **Ouverture** : nuit, village en flammes, le perso court vers l'attaque ; plan sur Kael et Lysa ; le chef des
  bandits apparaît ; enchaînement direct sur le combat.
- **Caméra de combat** : dynamique par attaque, style FFX et Clair Obscur (plan large pour choisir, rapprochement
  pendant l'attaque, tremblement sur les gros coups, retour au plan large).
- **Pression** (les 4 choisis) : battements de cœur et bords rouges quand les PV sont bas ; musique à couches qui
  monte selon le combat (brisure, boss, allié à terre) ; ralenti et zoom sur les parades parfaites ; ennemi qui
  charge et caméra qui serre avant l'anneau d'esquive.
- Ton tout public, ambiance clair-obscur (noir, violet, doré, flammes). Titre : « Magicaland : Reborn in New World ».
- Réponses en français, simples ; l'utilisateur joue surtout depuis son téléphone.

## Faits techniques vérifiés (10/11/2026)

- **Pas de Blender** dans la session cloud : pas de modélisation, pas de rigging. Il faut des modèles déjà
  animés (GLB) ou des formes construites en code.
- **Page publiée (Artifact)** : scripts externes seulement depuis cdnjs, cdn.jsdelivr.net/npm, unpkg ;
  pas de `fetch` vers d'autres sites. Les fichiers du jeu (GLB, textures) se publient à côté de la page avec
  le paramètre `files` de l'outil Artifact et se chargent par chemin relatif.
- **Three.js** : `three@0.147.0` sur jsdelivr donne la version classique qui définit `THREE` en global :
  `build/three.min.js`, `examples/js/loaders/GLTFLoader.js`, `examples/js/utils/SkeletonUtils.js`,
  `examples/js/postprocessing/UnrealBloomPass.js` (tous répondent 200). Les modèles d'exemple ne sont pas sur
  npm. cdnjs fournit aussi `three.js/r128/three.min.js`.
- **Sources de modèles joignables depuis la session** : `raw.githubusercontent.com` (ex. modèles d'exemple
  Khronos : Fox.glb répond 200) et `quaternius.com` (page répond 200). `poly.pizza` et `kenney.nl` répondent 403.
  Vérifier le téléchargement réel et la licence avant d'utiliser un fichier.
- **Taille** : une page publiée fait 16 Mo maximum, les modèles doivent être allégés (cible : moins de
  10 Mo en tout pour la première version).
- **Test** : Chromium et Playwright sont installés ; Playwright peut prendre des captures du rendu WebGL
  (lancer avec `--use-gl=swiftshader` ou équivalent si besoin) et vérifier l'absence d'erreurs.
- **Skills à lire avant d'écrire** (dépôt `skills`, branche `claude/dazzling-bardeen-uao49i`) :
  `jeux-video` (guide), `threejs-game`, `build-mobile-threejs-games`, `threejs-gltf-loading`,
  `threejs-materials-lighting`, `threejs-perf`, `threejs-scene-setup`, `create-game-vfx`, `game-feel`,
  `camera-systems`, `compose-game-music`, `audio-design`, `build-game-audio-feedback`,
  `build-rigged-game-assets`, `game-3d-assets`, `add-3d-assets`, `game-ui-ux`.

## Règles du projet à respecter

- Annoncer le coût et demander l'accord avant tout service payant (aucun n'est prévu ici).
- Ne jamais demander à l'utilisateur de coller une clé dans la conversation.
- Rien n'est copié depuis un jeu existant : on s'inspire des mécaniques, pas des personnages ni du graphisme.
- Les combats gardent la logique du prototype : énergie, points faibles, brèche, statuts, esquive active
  (anneau de timing), parade parfaite.

## Livrables attendus

1. `index.html` (ou dossier de fichiers) : titre, naissance, cinématique d'intro 3D, combat 3D, fin.
2. `CREDITS.md` : source et licence de chaque modèle et son.
3. Publication en page privée (Artifact), même lien que la version actuelle.
4. Mise à jour de `GAME_DESIGN.md` et du résumé de session dans `JOURNAL.md` du dépôt `skills`.
5. Rapport franc à l'utilisateur : ce qui a été testé (captures, erreurs), ce qui ne l'a pas été (vrai
   téléphone), ce qui reste à faire.
