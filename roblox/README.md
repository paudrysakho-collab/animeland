# Magicaland sur Roblox : scripts du prototype

Copie des scripts de Place3 (Roblox Studio). Arborescence identique à Studio (format Rojo :
`.server.lua` = Script, `.client.lua` = LocalScript, `.lua` = ModuleScript).

- `ReplicatedStorage/Magicaland/Donnees` : tables (5 races, 5 éléments, 4 dons, raretés) et réglages du combat.
- `ServerScriptService/Magicaland/Principal` : crée les RemoteEvents, charge les joueurs, relie le combat.
- `ServerScriptService/Magicaland/Naissance` : tirage de naissance + DataStore (un seul tirage ; mémoire si pas d'accès API).
- `ServerScriptService/Magicaland/Combat` : combat en temps réel contre le Golem de mousse (le serveur décide tout).
- `StarterPlayer/StarterPlayerScripts/Magicaland/Client` : écran de naissance, barre de vie, bouton Attaquer, messages.

Prototype 1 (14/11/2026) : naissance + premier combat, testé dans Studio (victoire et défaite, aucune erreur).
Dans Studio, la sauvegarde DataStore ne marche qu'après publication du jeu et « Enable Studio Access to API Services ».
