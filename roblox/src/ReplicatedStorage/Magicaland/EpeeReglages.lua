--!strict
-- EpeeReglages : TOUS les réglages du style épée, partagés par le serveur (Epee) et le client (EpeeClient).
-- Aucune de ces valeurs n'est recopiée dans la logique : pour régler le ressenti, on ne touche qu'à ce fichier.
-- Les données propres à chaque coup (animation, fenêtre de touche, lame, dégâts) sont dans EpeeDonnees.
-- Le serveur reste seul juge : le client lit ces valeurs pour prédire et afficher, jamais pour décider.

local R = {
	-- Touches
	HITSTOP = 0.03, -- arrêt sur image à chaque coup qui touche (attaquant + cible), en secondes
	REMBOBINAGE_MIN = 0.10, -- rembobinage de la cible selon le ping du joueur (100 à 150 ms)
	REMBOBINAGE_MAX = 0.15,
	RAYON_LAME = 0.55, -- rayon du balayage de la lame (spherecast)
	CIBLAGE_AVANCE = 4, -- au début d'un coup, le joueur s'approche de la cible d'au plus 4 studs
	TOLERANCE_DEPLACEMENT = 4.5, -- marge du serveur sur le déplacement d'un coup (anti-téléportation)

	-- Réactions de la cible
	STUN_COUP = 1.5, -- un peu plus long que l'intervalle entre deux coups (jusqu'à 1,4 s dans le combo avancé)
	STUN_BOSS = 0.5,
	ANTI_STUN = 2, -- après le 5e coup, la cible ne peut plus être étourdie pendant 2 s (pas de boucle infinie)
	RALENTI_FINAL = 1.5, -- ralenti de la cible après le coup final
	RECUL_COUP = 6, -- petit recul des coups 1 à 4 (vitesse en studs/s)
	VITESSE_RECUL = 65, -- fin du combo A : projetée en arrière
	RECUL_SANS_MUR = 14, -- distance de la projection s'il n'y a pas de mur
	PORTEE_MUR = 22, -- un mur est cherché jusqu'à cette distance derrière la cible
	MARGE_MUR = 1.6, -- la cible s'arrête à cette distance du mur
	LANCER_HAUT = 50, -- fin du combo B : projetée en l'air (vitesse verticale)

	-- Bloc, garde, parade
	GARDE_MAX = 100,
	GARDE_COUT = 3, -- garde perdue par point de dégât bloqué
	GARDE_REGEN = 25, -- garde regagnée par seconde (1 s après le dernier coup bloqué)
	GARDE_CASSEE = 1.5, -- garde brisée : sonné pendant 1,5 s
	PARADE_FENETRE = 0.2, -- parade parfaite : garde levée moins de 0,2 s avant le coup
	PARADE_STUN = 1.6,
	PARADE_STUN_BOSS = 0.8,
	ANTI_SPAM_PARADE = 0.6, -- pas de parade parfaite si la garde vient d'être levée (matraquage de F)
	BLOC_VITESSE = 0.35, -- vitesse de marche en garde (× vitesse normale)
	POSE_GARDE = { cle = "Epeiste_1", t = 0.45 }, -- image figée servant de pose de garde (provisoire)

	-- Coups lourds des ennemis (imparables, flash rouge)
	LOURD_MULT = 1.5, -- dégâts du coup lourd du golem
	LOURD_TOUS_LES = 3, -- 1 attaque du golem sur 3 est lourde
	PROJECTION_JOUEUR = 1.3, -- durée au sol après un coup lourd (le dash relève plus tôt)

	-- Dash : une seule recharge courte ; il annule le combo et relève après une projection
	DASH = {
		recharge = 1.2, -- secondes entre deux dashs
		tampon = 0.15, -- un appui fait dans les 0,15 s avant la fin de la recharge part dès que le dash est prêt
		avant = { vitesse = 80, duree = 0.16 },
		cote = { vitesse = 66, duree = 0.15 },
	},

	-- Attaques de base : vitesse de lecture des animations (× la vitesse de la source). Le serveur utilise la même
	-- valeur pour ses fenêtres de touche. Les coups à longue préparation sont plus accélérés.
	VITESSE_COUPS = { defaut = 1.3, EpeisteAvance_1 = 1.6, EpeisteAvance_4 = 1.45 },
	TAMPON_CLIC = 0.2, -- un clic fait au plus 0,2 s avant l'ouverture de la fenêtre enchaîne quand même

	-- Effets (hors ultime)
	FX = {
		DUREE_MAX = 0.4, -- un effet dure au plus 0,4 s
		PARTICULES_MAX = 40, -- par coup
		FPS_ALLEGE = 45, -- sous 45 images/s : particules divisées par 2
		ECHELLE_ALLEGEE = 0.5,
	},
}

-- Vitesse de lecture du coup « cle » (1 = vitesse de la source).
function R.vitesseCoup(cle: string?): number
	local v = R.VITESSE_COUPS
	return (cle and v[cle]) or v.defaut
end

return table.freeze(R)
