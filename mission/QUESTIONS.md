# Questions en attente (mission combat)

Je continue le reste du travail en attendant les réponses. Rien n'est bloqué par ces questions.

## Q18 (16/11, outils) : extension Higgsfield pour Blender
L'extension officielle « Higgsfield for Blender » existe (higgsfield.ai/plugins/blender), mais elle demande **Blender 5.1 ou plus**.
Le PC a Blender 4.5.10 (tout le pipeline actuel tourne dessus). Je n'ai rien installé.
- **A) Ne rien installer** : on continue avec Blender 4.5 et les poses clés faites à la main (ce qui marche aujourd'hui).
- **B) Installer Blender 5.1 à côté de la 4.5** (sans toucher à la 4.5), puis installer l'extension et la tester sur le monstre
  (« Character Animation ») dans la limite de 50 crédits par jour. On ne la garde que si elle apporte un vrai gain.
- **C) Remplacer Blender 4.5 par 5.1** (plus risqué : il faudrait revérifier tous les scripts du pipeline).

Mon conseil : **B** si tu veux l'essayer, sinon **A**. Il faut ton accord pour installer un nouveau logiciel.

**Réponse de l'utilisateur : « installe » (= B). Fait le 16/11 :**
- Blender **5.2.4 LTS** (version portable officielle, empreinte SHA-256 vérifiée) dans `C:\Users\user\Blender52\blender-5.2.4-windows-x64\`.
  Blender 4.5 n'est pas touché ; tout le pipeline reste sur la 4.5.
- Extension **Higgsfield 1.5.61** (manifest officiel `hf-adobe-updates.higgsfield.ai/blender/manifest.json`, empreinte vérifiée)
  installée et activée dans Blender 5.2 (`bl_ext.user_default.higgsfield_blender`). Elle **ne peut pas** aller dans Blender 4.5 :
  elle exige 5.1 minimum et ses bibliothèques sont pour Python 3.13 / 3.14 (Blender 4.5 = Python 3.11).
- Son outil « Character Animation » = texte → mouvement 3D (modèle « kimodo », 20 images/s, plans de 10 s au plus) sur son
  squelette de 27 os, puis un transfert (« retarget ») sur une armature. Possible usage : une base de mouvement à transférer sur
  le rig R15, puis retravaillée à la main (poses clés, marqueurs).

## Q19 (16/11) : connexion à Higgsfield dans Blender 5.2 — ACTION DE L'UTILISATEUR
La connexion se fait par un code à valider dans le navigateur ; je ne peux pas me connecter à ta place.
1. Lance `C:\Users\user\Blender52\blender-5.2.4-windows-x64\blender.exe`.
2. Dans la barre Higgsfield (en bas de la vue 3D), clique « Sign in » ; une page s'ouvre : valide le code avec ton compte.
3. Dis-le moi : je testerai alors l'animation sur le monstre (budget : 50 crédits par jour au plus, coût annoncé avant).
En attendant, je continue les compétences du feu avec Blender 4.5.
