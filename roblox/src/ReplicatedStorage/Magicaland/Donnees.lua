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
	-- Combo de l'attaque de base : 4 coups enchaînés. « apres » = temps avant le coup suivant (vérifié par le serveur).
	-- Attendre plus que « fenetre » ramène au coup 1. Le compteur monte tant qu'on enchaîne sans être touché.
	COMBO = {
		fenetre = 1.0,
		etapes = {
			{ mult = 0.8, apres = 0.36 },
			{ mult = 0.9, apres = 0.36 },
			{ mult = 1.0, apres = 0.42 },
			{ mult = 1.8, apres = 0.7, final = true },
		},
		bonusParCoup = 0.03, -- +3 % de dégâts par coup du compteur…
		bonusMax = 0.3, -- … jusqu'à +30 %
		energieTous = 5, -- +1 énergie tous les 5 coups du compteur
		minFinition = 4, -- finir un combo d'au moins 4 coups par une attaque spéciale…
		bonusFinition = 1.25, -- … donne x1,25 aux dégâts de cette attaque
	},
	-- 5 attaques spéciales (touches 1 à 5). Mêmes proportions que js/game.js (puissance x2 en temps réel) :
	-- Frappe 1,0 / Sort principal 1,6 / Sort secondaire 1,5 / Nova 1,1 en zone / Éveil 3,2 ; coûts 0/2/2/4/6.
	-- mult = multiplicateur des dégâts de base, recharge en secondes, charge = temps avant le coup.
	-- Portée de chaque attaque (« type ») :
	--   contact  : touche seulement de près (portée normale + porteeBonus) ; trop loin, elle frappe dans le vide.
	--   zone     : touche tout ce qui est à moins de « rayon » du joueur.
	--   distance : part toujours vers l'ennemi, jusqu'à « portee » ; peut rater (ennemi trop loin ou qui bouge,
	--              « toucheRayon » = marge autour du point visé). Dégâts pleins de près, jusqu'à « attenuation » au bout.
	--   vitesse = vitesse du projectile (studs/s) ; vol = durée fixe avant l'impact ; etiquette = texte du bouton.
	ATTAQUES = {
		{ id = "frappe", nom = "Frappe d'arcane", court = "Frappe", cout = 0, recharge = 4, mult = 2.0, charge = 0.25, type = "contact", porteeBonus = 4, vol = 0.12, gain = 1, etiquette = "contact" },
		{ id = "sort1", nom = "Lance", court = "Lance", cout = 2, recharge = 7, mult = 3.2, charge = 0.5, type = "distance", portee = 60, vitesse = 110, toucheRayon = 7, attenuation = 0.5, etiquette = "tir · 60" },
		{ id = "sort2", nom = "Colonnes", court = "Colonnes", cout = 2, recharge = 9, mult = 3.0, charge = 0.6, effetFort = true, type = "distance", portee = 40, vol = 0.42, toucheRayon = 9, attenuation = 0.7, etiquette = "tir · 40" },
		{ id = "nova", nom = "Nova", court = "Nova", cout = 4, recharge = 14, mult = 2.2, charge = 0.45, type = "zone", rayon = 24, vol = 0.08, etiquette = "zone · 24" },
		{ id = "jugement", nom = "Jugement", court = "Jugement", cout = 6, recharge = 30, mult = 6.4, charge = 1.6, invulnerable = true, type = "distance", portee = 70, vol = 0.15, toucheRayon = 10, attenuation = 0.75, etiquette = "tir · 70" },
		-- Ultime (touche 6 ou F) : boule suprême, toute l'énergie. Transformé : charge plus longue = cinématique anime.
		{ id = "ultime", nom = "Boule suprême", court = "ULTIME", cout = 10, recharge = 45, mult = 9.0, charge = 1.3, chargeTransfo = 2.6, invulnerable = true, type = "distance", portee = 80, vol = 0.45, volTransfo = 0.8, toucheRayon = 12, attenuation = 0.6, etiquette = "tir · 80" },
	},
	-- Transformation (touche T) : la jauge (0 à 100) se remplit pendant les combats et reste d'un combat à l'autre.
	TRANSFO = {
		jaugeMax = 100,
		parDegatInflige = 0.4, -- points de jauge par point de dégât infligé
		parDegatRecu = 0.8,
		parEsquive = 5,
		duree = 20,
		degats = 1.8, -- dégâts x1,8 (bien plus fort que l'Éveil)
		vitesse = 1.35, -- vitesse de marche x1,35
		defense = 0.5, -- dégâts reçus x0,5
		recharges = 0.5, -- recharges x0,5 (attaques spéciales)
		taille = 1.12, -- l'apparence change : corps plus grand, cheveux de lumière, cristaux aux épaules
		invulnerable = 1.6, -- pendant la courte cinématique (après la montée)
		montee = 2.4, -- montée dramatique avant la transformation (immobile et invincible)
		epuisement = 6, -- secondes d'épuisement ensuite
		epuiseVitesse = 0.7,
		epuiseDegats = 0.8,
	},
	-- Éveil (touche G) : tous les personnages l'ont. Coûte la moitié de la jauge et renforce les compétences
	-- pendant 25 s. Moins fort que la transformation, sans épuisement ; on peut se transformer pendant l'Éveil.
	EVEIL = {
		cout = 50,
		duree = 25,
		degats = 1.15, -- tous les coups
		degatsSpeciaux = 1.3, -- en plus, pour les attaques spéciales
		recharges = 0.75,
		energie = 1.5, -- énergie gagnée x1,5 (aussi pendant la transformation)
		invulnerable = 0.8,
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
		pv = 3000, -- beaucoup de vie : pour tester toutes les attaques (avant : 700)
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
		fouet = { degats = 6, preparation = 1.0, longueur = 16, largeur = 12 },
		racines = { degats = 7, preparation = 1.2, rayon = 5 },
		graines = { degats = 5, preparation = 1.1, rayon = 4.5, nombre = 4 },
		recompense = 300,
		objet = "ecorceArdente",
		niveauRequis = 1, -- victoires nécessaires pour le défier
	},
}

-- Images générées pour Magicaland (Higgsfield, 15/11/2026), importées sur le compte du jeu. Voir CREDITS.md.
-- Textures d'effets : fond transparent ; les blanches se teintent de la couleur de l'élément.
Donnees.TEXTURES = {
	flamme = "rbxassetid://98225440635041",
	eclair = "rbxassetid://121678256785394",
	cristal = "rbxassetid://135532586247910",
	lumiere = "rbxassetid://76346610510911",
	fumee = "rbxassetid://88593271338446",
	onde = "rbxassetid://106498819149245",
	aura = "rbxassetid://79985723352319",
	etincelle = "rbxassetid://83597516268763",
	eclats = "rbxassetid://131754686613656",
	orbe = "rbxassetid://74339143096067",
}
-- Icônes de l'interface (rondes), par identifiant d'attaque ou d'objet.
Donnees.ICONES = {
	frappe = "rbxassetid://123365827670536",
	sort1 = "rbxassetid://93331756798476",
	sort2 = "rbxassetid://103841422545639",
	nova = "rbxassetid://99040993802967",
	jugement = "rbxassetid://86826737937541",
	ultime = "rbxassetid://111048192649187",
	transformation = "rbxassetid://91419595273081",
	jauge = "rbxassetid://130766915957561",
	ecorceArdente = "rbxassetid://77614347238487",
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
