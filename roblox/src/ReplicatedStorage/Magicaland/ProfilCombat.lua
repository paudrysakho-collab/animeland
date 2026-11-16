--!strict
-- ProfilCombat : PRÉPARATION des 3 systèmes distincts demandés par la mission (pas encore branchés au gameplay) :
--   - style de combat : la façon de se battre (aujourd'hui : le sabre) ;
--   - élément : la matière et les couleurs des effets (feu, eau, terre, vent) ;
--   - capacité innée : liée au personnage ou à la race (par exemple dragon).
-- Aujourd'hui, seul le couple « sabre + feu » sert, et seulement pour les couleurs des effets des coups de base (FX).
-- Les autres éléments seront conçus à part (pas un recoloriage du feu) : voir pipeline-anim/mission/PROPOSITIONS.md.

local P = {}

P.STYLES = {
	sabre = { nom = "Sabre", combos = { "Epeiste", "EpeisteAvance" } },
}

P.ELEMENTS = {
	feu = {
		nom = "Feu",
		caractere = "agressif, explosif",
		palette = {
			etincelle = Color3.fromRGB(255, 185, 95),
			flamme = Color3.fromRGB(255, 120, 40),
			braise = Color3.fromRGB(150, 40, 10),
			lumiere = Color3.fromRGB(255, 180, 110),
		},
	},
	eau = { nom = "Eau", caractere = "fluide, circulaire" }, -- à concevoir
	terre = { nom = "Terre", caractere = "lourd, brutal" }, -- à concevoir
	vent = { nom = "Vent", caractere = "rapide, tranchant" }, -- à concevoir
}

P.CAPACITES_INNEES = {} -- exemple prévu : dragon (liée à la race). Rien d'implémenté.

P.DEFAUT = { style = "sabre", element = "feu", inne = nil }

-- Plus tard : lu depuis la naissance du personnage. Pour l'instant : sabre + feu pour tout le monde.
function P.profil(_joueur: Player?)
	return P.DEFAUT
end

return P
