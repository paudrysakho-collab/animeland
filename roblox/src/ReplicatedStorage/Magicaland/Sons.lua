-- Sons : bruitages du combat, côté client seulement (c'est de l'habillage, pas de la règle).
-- Chaque effet superpose 2 ou 3 sons. Sources : bibliothèque officielle Roblox (créateur « Roblox »)
-- et APM Music (« APMOfficial », sous licence de Roblox pour tous les jeux). Liste dans CREDITS.md.
-- Aucun son d'anime ni de jeu existant.

local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local Sons = {}

-- Identifiants (voir CREDITS.md).
local ID = {
	coup = "rbxassetid://12222046", -- hit.wav (Roblox)
	impactLourd = "rbxassetid://9043338036", -- BIG IMPACT HIT 11 (APM)
	whoosh1 = "rbxassetid://15674975792", -- Roblox_UI_Whoosh_03 (Roblox)
	whoosh2 = "rbxassetid://15675028888", -- Roblox_UI_Whoosh_02 (Roblox)
	whooshGrave = "rbxassetid://107073250463751", -- Whoosh Heavy Low (APM)
	boule = "rbxassetid://1846573130", -- Fireball (APM)
	boomFuze = "rbxassetid://139431770683502", -- Boom Fuze (APM)
	explosion = "rbxasset://sounds/impact_explosion_03.mp3", -- son livré avec Roblox
	eclat = "rbxassetid://1843023382", -- Shatter Slam (APM)
	tonnerre = "rbxassetid://9120031442", -- Thunder ... Searing Blast (Roblox)
	energie = "rbxassetid://1841352043", -- Fierce Energy Blast 2 (APM)
	energie3 = "rbxassetid://1841352055", -- Fierce Energy Blast 3 (APM)
	carillon = "rbxassetid://1839901345", -- Powered Up Chimes (APM)
	whooshSombre = "rbxassetid://1835336214", -- Creep Next Door Dark Whoosh (APM)
	boomGrave = "rbxassetid://134785366676981", -- Boom Power Deep (APM)
	montee = "rbxassetid://1835343491", -- Grit Unlimited Stutter Swell (APM)
	grondement = "rbxassetid://1843023670", -- Rumble Slam (APM)
	victoire = "rbxassetid://12222253", -- victory.wav (Roblox)
	fanfare = "rbxassetid://1836473422", -- Victory Fanfare Sting (APM)
	porte = "rbxassetid://1837829565", -- HIT-Door Slam 02 (APM)
}

-- Groupes de mixage : combat (égaliseur + réverbération) et interface.
local function groupe(nom, volume)
	local g = SoundService:FindFirstChild(nom)
	if not g then
		g = Instance.new("SoundGroup")
		g.Name = nom
		g.Volume = volume
		g.Parent = SoundService
	end
	return g
end

local groupeCombat = groupe("MagicalandCombat", 0.8)
local groupeInterface = groupe("MagicalandInterface", 0.7)

if not groupeCombat:FindFirstChildOfClass("EqualizerSoundEffect") then
	local eq = Instance.new("EqualizerSoundEffect")
	eq.LowGain = 4 -- basses renforcées : souffle grave des explosions
	eq.MidGain = 0
	eq.HighGain = -2
	eq.Parent = groupeCombat
	local reverb = Instance.new("ReverbSoundEffect")
	reverb.DecayTime = 0.9
	reverb.WetLevel = -14
	reverb.DryLevel = 0
	reverb.Priority = 1
	reverb.Parent = groupeCombat
end

-- Couches de chaque effet : id, volume, pitch, début (s) et durée max (s).
local EFFETS = {
	elan = { { ID.whoosh1, 0.6, 1.1, 0, 0.5 }, { ID.whoosh2, 0.3, 1.3, 0, 0.4 } },
	coup = { { ID.coup, 0.8, 0.9, 0, 0.6 }, { ID.impactLourd, 0.45, 1.15, 0, 0.9 } },
	critique = { { ID.energie3, 0.6, 1.1, 0, 1.2 }, { ID.impactLourd, 0.7, 0.85, 0, 1.2 } },
	feu = { { ID.boule, 0.55, 1.15, 0, 1.1 }, { ID.boomFuze, 0.5, 1.1, 0, 1.2 }, { ID.explosion, 0.35, 1.2, 0, 1 } },
	glace = { { ID.eclat, 0.55, 1.25, 0, 1.2 }, { ID.whoosh2, 0.3, 0.8, 0, 0.5 } },
	foudre = { { ID.tonnerre, 0.45, 1.2, 0, 1.0 }, { ID.energie, 0.45, 1.3, 0, 0.9 } },
	lumiere = { { ID.carillon, 0.45, 1.2, 0, 1.3 }, { ID.energie, 0.25, 1.6, 0, 0.6 } },
	ombre = { { ID.whooshSombre, 0.5, 1.2, 0, 1.0 }, { ID.boomGrave, 0.45, 1.0, 0, 1.2 } },
	brulure = { { ID.boule, 0.2, 1.4, 0, 0.5 } },
	esquive = { { ID.whooshGrave, 0.6, 1.25, 0, 0.8 }, { ID.whoosh1, 0.4, 0.9, 0, 0.5 } },
	alerte = { { ID.montee, 0.45, 1.3, 0, 0.7 } },
	impactRecu = { { ID.porte, 0.55, 0.8, 0, 0.8 }, { ID.impactLourd, 0.5, 0.75, 0, 1 }, { ID.explosion, 0.2, 0.7, 0, 0.8 } },
	bouclier = { { ID.eclat, 0.35, 1.6, 0, 0.6 }, { ID.coup, 0.4, 1.4, 0, 0.4 } },
	apparition = { { ID.grondement, 0.65, 0.8, 0, 2.5 }, { ID.boomGrave, 0.45, 0.7, 0, 2 } },
	boucle = { { ID.carillon, 0.6, 0.9, 0, 2 }, { ID.whooshGrave, 0.4, 0.8, 0, 1 } },
	mortMonstre = { { ID.boomFuze, 0.6, 0.8, 0, 1.6 }, { ID.explosion, 0.4, 0.9, 0, 1.4 } },
	victoire = { { ID.victoire, 0.6, 1, 0, 2 }, { ID.fanfare, 0.5, 1, 0, 6 } },
	defaite = { { ID.boomGrave, 0.5, 0.6, 0, 2.5 } },
}

local INTERFACE = { victoire = true, defaite = true }

local modeles = {} -- un Sound modèle par couche, préchargé

local function modele(id)
	local s = modeles[id]
	if not s then
		s = Instance.new("Sound")
		s.SoundId = id
		modeles[id] = s
	end
	return s
end

-- Joue un effet. La variation de pitch (±5 %) évite la répétition mécanique.
function Sons.jouer(nom)
	local couches = EFFETS[nom]
	if not couches then
		return
	end
	local cible = INTERFACE[nom] and groupeInterface or groupeCombat
	for _, c in couches do
		local s = modele(c[1]):Clone()
		s.Volume = c[2]
		s.PlaybackSpeed = c[3] * (0.95 + math.random() * 0.1)
		s.TimePosition = c[4]
		s.SoundGroup = cible
		s.Parent = cible
		s:Play()
		Debris:AddItem(s, c[5] / s.PlaybackSpeed + 0.1)
	end
end

-- Charge les sons à l'avance pour éviter un blanc au premier coup.
function Sons.precharger()
	local liste = {}
	for _, couches in EFFETS do
		for _, c in couches do
			table.insert(liste, modele(c[1]))
		end
	end
	task.spawn(function()
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync(liste)
		end)
	end)
end

-- Pour les tests : liste des identifiants utilisés.
Sons.ID = ID

return Sons
