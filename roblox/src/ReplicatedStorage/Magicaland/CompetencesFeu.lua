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
		duree = 1.25, -- longueur de l'animation (s)
		contact = 0.60, -- marqueur « Contact » : la lame touche le sol, la vague part
		recharge = 6,
		vague = {
			vitesse = 55, -- studs/s
			portee = 42, -- studs au plus
			rayon = 2.6, -- + demi-largeur de la cible
			avance = 6.9, -- départ devant le joueur : là où la pointe de la lame touche le sol (mesuré en jeu)
			decalage = 0.95, -- ... et un peu à droite (la lame tombe du côté de la main droite)
			angleMax = 70, -- vise la cible si elle est à moins de 70° de l'avant
			mult = 2.4, -- multiplicateur de dégâts (mêmes règles que les coups)
			etourdi = 0.5,
		},
	},
}

return CompetencesFeu
