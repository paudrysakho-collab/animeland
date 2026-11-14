-- Donnees : tables de naissance et réglages du combat.
-- Version réduite des tables de js/game.js (5 races, 5 éléments, 4 dons, 4 raretés).
-- Module partagé : le serveur s'en sert pour décider, le client seulement pour afficher.

local Donnees = {}

-- Races. w = poids dans le tirage (plus il est grand, plus la race est fréquente).
-- pv = multiplicateur de vie, degats = multiplicateur de dégâts, vitesse = vitesse de marche.
Donnees.RACES = {
	{ id = "humain", nom = "Humain", w = 34, desc = "Polyvalent, sans faiblesse.", pv = 1.0, degats = 1.0, vitesse = 16 },
	{ id = "elfe", nom = "Elfe", w = 10, desc = "Magie vive, corps fragile.", pv = 0.85, degats = 1.2, vitesse = 17 },
	{ id = "nain", nom = "Nain", w = 10, desc = "Solide comme la roche.", pv = 1.3, degats = 0.95, vitesse = 14 },
	{ id = "chat", nom = "Homme-chat", w = 8, desc = "Agile et chanceux.", pv = 0.9, degats = 1.0, vitesse = 20 },
	{ id = "dragon", nom = "Demi-dragon", w = 3, desc = "Sang de dragon, puissance brute.", pv = 1.2, degats = 1.25, vitesse = 16 },
}

-- Éléments de magie (tirage équitable). Chaque élément a un effet en combat.
Donnees.ELEMENTS = {
	{ id = "feu", nom = "Feu", couleur = Color3.fromRGB(255, 120, 60), effet = "Brûlure : 4 dégâts par seconde pendant 3 s." },
	{ id = "glace", nom = "Glace", couleur = Color3.fromRGB(120, 200, 255), effet = "Gel : le monstre avance 2 fois moins vite pendant 2 s." },
	{ id = "foudre", nom = "Foudre", couleur = Color3.fromRGB(255, 225, 80), effet = "Choc : 25 % de chances d'étourdir le monstre 1 s." },
	{ id = "lumiere", nom = "Lumière", couleur = Color3.fromRGB(255, 245, 200), effet = "Lumière : chaque coup te soigne de 3 PV." },
	{ id = "ombre", nom = "Ombre", couleur = Color3.fromRGB(170, 110, 230), effet = "Ombre : +20 % de dégâts." },
}

-- Raretés du don, avec le taux de chaque niveau (mêmes taux que le jeu web).
Donnees.RARETES = {
	{ id = "commun", nom = "Commun", w = 52, couleur = Color3.fromRGB(200, 200, 210) },
	{ id = "rare", nom = "Rare", w = 30, couleur = Color3.fromRGB(90, 160, 255) },
	{ id = "epique", nom = "Épique", w = 14, couleur = Color3.fromRGB(190, 100, 255) },
	{ id = "legendaire", nom = "Légendaire", w = 4, couleur = Color3.fromRGB(255, 190, 60) },
}

-- Dons d'isekai : un par rareté dans ce prototype.
Donnees.DONS = {
	{ id = "barriere", nom = "Barrière innée", rarete = "commun", desc = "Commence chaque combat avec un bouclier de 30." },
	{ id = "critique", nom = "Chance du démon", rarete = "rare", desc = "+15 % de coups critiques." },
	{ id = "flux", nom = "Flux de mana", rarete = "epique", desc = "Tu frappes 30 % plus vite." },
	{ id = "boucle", nom = "Boucle temporelle", rarete = "legendaire", desc = "Une fois par combat, tu reviens à 50 % de vie." },
}

-- Réglages du premier combat (le serveur est le seul à les appliquer).
Donnees.COMBAT = {
	PV_JOUEUR = 100,
	DEGATS_BASE = 12,
	RECHARGE_ATTAQUE = 0.45, -- secondes entre deux coups
	PORTEE_ATTAQUE = 11, -- distance max (en studs) pour toucher
	CRITIQUE_BASE = 0.10,
	MULT_CRITIQUE = 1.8,
	RECOMPENSE_PIECES = 50,
	MONSTRE = {
		nom = "Golem de mousse",
		pv = 140,
		degats = 8,
		vitesse = 9, -- studs par seconde
		portee = 7, -- distance de frappe
		preparation = 0.6, -- temps d'alerte avant le coup : on peut s'éloigner pour l'esquiver
		recharge = 1.8, -- pause après chaque coup
		faiblesse = "feu", -- dégâts x1,25
		resistance = "ombre", -- dégâts x0,8 (l'Ombre garde quand même +20 %)
	},
}

-- Cherche une entrée par son id dans une des tables ci-dessus.
function Donnees.trouver(liste, id)
	for _, entree in liste do
		if entree.id == id then
			return entree
		end
	end
	return nil
end

return Donnees
