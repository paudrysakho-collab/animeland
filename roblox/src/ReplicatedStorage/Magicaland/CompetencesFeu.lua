--!strict
-- Les compétences du feu (mission combat, étape 4), touches 1 à 6. Réglages partagés client / serveur.
-- Chaque compétence : une animation faite par poses clés (pipeline-anim/scripts/anims_feu.py) avec des marqueurs ;
-- le serveur décide de tout (recharge, direction, dégâts), le client prédit l'animation et les effets.
-- Fiches : mission/fiches/*.md.

local CompetencesFeu = {}

CompetencesFeu.ATTRIBUT_CONFORT = "PIPE_Confort" -- vrai = moins de flashs et de mouvements de caméra (Q16)

CompetencesFeu.liste = {
	[1] = {
		id = "slash",
		nom = "Sillon de braise",
		seq = "PIPE_feu_slash",
		duree = 1.50, -- longueur de l'animation faite main (s) ; référence : mission/fiches/1_slash.md
		contact = 0.54, -- marqueur « Contact » : la lame touche le sol, la vague part
		recharge = 6,
		-- grand pas en avant (animation SUR PLACE : le déplacement est donné au HumanoidRootPart par le client)
		pas = { debut = 0.38, fin = 0.50, distance = 3.0 },
		-- caméra façon anime (locale, coupée par l'option Confort) : CFrame relatives au HumanoidRootPart (avant = -Z)
		camera = {
			grosPlan = { pos = Vector3.new(-3.0, 2.3, -4.4), regard = Vector3.new(0, 2.1, 0), fov = 52 }, -- 3/4 face, armé
			frappe = { pos = Vector3.new(7.5, 0.3, -2.5), regard = Vector3.new(0, -1.2, -6.5), fov = 62 }, -- angle bas de côté
			entree = 0.12, -- fin du passage vers le gros plan
			retour = 0.95, -- début du retour vers la caméra de jeu
			fin = 1.30, -- caméra de jeu rendue (1,3 s au total)
		},
		vague = {
			vitesse = 55, -- studs/s
			portee = 42, -- studs au plus
			rayon = 2.6, -- + demi-largeur de la cible
			avance = 5.9, -- départ devant le joueur (après le pas) : là où la pointe touche le sol (verif_anim : 8,95 - 3)
			decalage = 0.95, -- ... et un peu à droite (la lame tombe du côté de la main droite)
			angleMax = 70, -- vise la cible si elle est à moins de 70° de l'avant
			mult = 2.4, -- multiplicateur de dégâts (mêmes règles que les coups)
			etourdi = 0.5,
		},
	},
}

return CompetencesFeu
