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
	-- Énergie (comme le jeu web) : se gagne en frappant et en esquivant, se dépense dans les attaques spéciales.
	ENERGIE = { max = 10, depart = 2, parCoup = 1, parCritique = 1, parEsquive = 2 },
	-- 5 attaques spéciales (touches 1 à 5). Mêmes proportions que js/game.js (puissance x2 en temps réel) :
	-- Frappe 1,0 / Sort principal 1,6 / Sort secondaire 1,5 / Nova 1,1 en zone / Éveil 3,2 ; coûts 0/2/2/4/6.
	-- mult = multiplicateur des dégâts de base, recharge en secondes, charge = temps avant le coup.
	-- porteeBonus = portée en plus de la portée normale ; rayon (Nova) = zone autour du joueur.
	ATTAQUES = {
		{ id = "frappe", nom = "Frappe d'arcane", court = "Frappe", cout = 0, recharge = 4, mult = 2.0, charge = 0.25, porteeBonus = 4, gain = 1 },
		{ id = "sort1", nom = "Lance", court = "Lance", cout = 2, recharge = 7, mult = 3.2, charge = 0.5, porteeBonus = 16 },
		{ id = "sort2", nom = "Colonnes", court = "Colonnes", cout = 2, recharge = 9, mult = 3.0, charge = 0.6, porteeBonus = 12, effetFort = true },
		{ id = "nova", nom = "Nova", court = "Nova", cout = 4, recharge = 14, mult = 2.2, charge = 0.45, rayon = 24, zone = true },
		{ id = "eveil", nom = "Éveil", court = "Éveil", cout = 6, recharge = 30, mult = 6.4, charge = 1.6, porteeBonus = 30, invulnerable = true },
	},
	-- Transformation (touche T) : la jauge (0 à 100) se remplit pendant les combats et reste d'un combat à l'autre.
	TRANSFO = {
		jaugeMax = 100,
		parDegatInflige = 0.4, -- points de jauge par point de dégât infligé
		parDegatRecu = 0.8,
		parEsquive = 5,
		duree = 20,
		degats = 1.5, -- dégâts x1,5
		vitesse = 1.3, -- vitesse de marche x1,3
		defense = 0.6, -- dégâts reçus x0,6
		recharges = 0.6, -- recharges x0,6 (attaques spéciales et coup normal)
		invulnerable = 1.6, -- pendant la courte cinématique
		epuisement = 6, -- secondes d'épuisement ensuite
		epuiseVitesse = 0.7,
		epuiseDegats = 0.8,
	},
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

-- Ennemis. Le comportement de chacun est dans ServerScriptService.Magicaland.Ennemis.
-- porteeJoueur = distance à laquelle le joueur peut toucher l'ennemi.
Donnees.ENNEMIS = {
	golem = {
		nom = "Golem de mousse",
		pv = Donnees.COMBAT.MONSTRE.pv,
		porteeJoueur = 11,
		distanceApparition = 18,
		hauteurBarre = 3,
		faiblesse = "feu",
		resistance = "ombre",
		recompense = Donnees.COMBAT.RECOMPENSE_PIECES,
	},
	colosse = {
		nom = "Colosse des Ronces",
		boss = true,
		pv = 700,
		phase2 = 0.5, -- passe en phase 2 sous 50 % de vie
		porteeJoueur = 15,
		distanceApparition = 32,
		hauteurBarre = 7,
		vitesse = 5,
		vitesse2 = 7,
		recharge = 1.8,
		recharge2 = 1.3,
		-- Phase 1 : faible au Feu. Phase 2 (en flammes) : faible à la Glace, résiste au Feu.
		faiblesse = "feu",
		resistance = "lumiere",
		faiblesse2 = "glace",
		resistance2 = "feu",
		fouet = { degats = 15, preparation = 1.0, longueur = 16, largeur = 12 },
		racines = { degats = 18, preparation = 1.2, rayon = 5 },
		graines = { degats = 12, preparation = 1.1, rayon = 4.5, nombre = 4 },
		recompense = 300,
		objet = "ecorceArdente",
		niveauRequis = 1, -- victoires nécessaires pour le défier
	},
}

-- Objets rares gagnés contre les boss.
Donnees.OBJETS = {
	ecorceArdente = { nom = "Écorce ardente", rarete = "epique", desc = "Trophée du Colosse des Ronces." },
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
