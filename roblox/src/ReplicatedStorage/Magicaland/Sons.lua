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

-- Sons originaux générés pour Magicaland (Higgsfield Seed Audio et ElevenLabs), importés sur le compte du jeu.
local GEN = {
	feu = "rbxassetid://75575520099278",
	glace = "rbxassetid://103248004919213",
	foudre = "rbxassetid://90346451949199",
	foudreEL = "rbxassetid://92919685822889",
	lumiere = "rbxassetid://98053171874557",
	ombre = "rbxassetid://78029039846132",
	lame1 = "rbxassetid://108948210221237",
	lame2 = "rbxassetid://124499126502201",
	coupLourd1 = "rbxassetid://71051572797802",
	coupLourd2 = "rbxassetid://91171784767583",
	esquive1 = "rbxassetid://90723111353172",
	esquive2 = "rbxassetid://140654368945715",
	esquiveEL = "rbxassetid://90609476739701",
	montee = "rbxassetid://85176675320308",
	attaqueSpeciale = "rbxassetid://124805435185584",
	rugissement = "rbxassetid://137426593653661",
	apparition = "rbxassetid://118039862995546",
	bouclier = "rbxassetid://99604478975577",
	victoire = "rbxassetid://99136911717446",
	victoireEL = "rbxassetid://86759059904136",
	frappeBoss = "rbxassetid://137340020123073", -- réservé au futur boss
	musiqueCombat = "rbxassetid://117643081330032",
	musiqueBoss = "rbxassetid://133353519976843", -- réservé au futur boss
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
-- Une couche dont l'id est une liste tire une variante au hasard à chaque fois.
local EFFETS = {
	elan = { { { GEN.lame1, GEN.lame2 }, 0.6, 1.05, 0, 0.8 }, { ID.whoosh1, 0.25, 1.2, 0, 0.4 } },
	coup = { { { GEN.coupLourd1, GEN.coupLourd2 }, 0.55, 1.1, 0, 0.7 }, { ID.coup, 0.45, 0.9, 0, 0.5 } },
	critique = { { GEN.attaqueSpeciale, 0.65, 1.1, 0, 1.4 }, { ID.impactLourd, 0.6, 0.85, 0, 1.2 } },
	feu = { { GEN.feu, 0.6, 1.1, 0, 1.4 }, { ID.boomFuze, 0.3, 1.1, 0, 1 } },
	glace = { { GEN.glace, 0.6, 1.1, 0, 1.3 }, { ID.eclat, 0.3, 1.25, 0, 0.8 } },
	foudre = { { { GEN.foudre, GEN.foudreEL }, 0.55, 1.1, 0, 1.2 }, { ID.energie, 0.25, 1.3, 0, 0.6 } },
	lumiere = { { GEN.lumiere, 0.55, 1.1, 0, 1.4 }, { ID.carillon, 0.25, 1.2, 0, 0.8 } },
	ombre = { { GEN.ombre, 0.6, 1.05, 0, 1.2 }, { ID.boomGrave, 0.3, 1.0, 0, 1 } },
	brulure = { { GEN.feu, 0.15, 1.5, 0.3, 0.5 } },
	esquive = { { { GEN.esquive1, GEN.esquive2, GEN.esquiveEL }, 0.6, 1.15, 0, 0.7 } },
	alerte = { { GEN.montee, 0.45, 1.6, 0, 0.7 }, { ID.montee, 0.2, 1.3, 0, 0.6 } },
	impactRecu = { { { GEN.coupLourd1, GEN.coupLourd2 }, 0.65, 0.8, 0, 1 }, { ID.porte, 0.35, 0.8, 0, 0.8 } },
	bouclier = { { GEN.bouclier, 0.55, 1.1, 0, 1 } },
	apparition = { { GEN.apparition, 0.6, 1, 0, 2.5 }, { GEN.rugissement, 0.55, 0.9, 0, 2.5 } },
	boucle = { { ID.carillon, 0.6, 0.9, 0, 2 }, { GEN.montee, 0.35, 1.2, 0, 1.2 } },
	mortMonstre = { { GEN.rugissement, 0.5, 1.2, 0, 1.5 }, { ID.explosion, 0.4, 0.9, 0, 1.4 } },
	victoire = { { { GEN.victoire, GEN.victoireEL }, 0.6, 1, 0, 6 }, { ID.victoire, 0.35, 1, 0, 2 } },
	defaite = { { ID.boomGrave, 0.5, 0.6, 0, 2.5 } },
	frappeBoss = { { GEN.frappeBoss, 0.75, 1, 0, 2 }, { ID.boomGrave, 0.35, 0.8, 0, 1.5 } },
	phase2 = { { GEN.rugissement, 0.75, 0.7, 0, 3 }, { GEN.feu, 0.55, 0.8, 0, 2 } },
	charge = { { GEN.montee, 0.55, 1.1, 0, 1 } },
	special = { { GEN.attaqueSpeciale, 0.8, 0.95, 0, 2.5 }, { ID.boomGrave, 0.5, 0.9, 0, 1.5 } },
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
		local id = c[1]
		if type(id) == "table" then
			id = id[math.random(1, #id)]
		end
		local s = modele(id):Clone()
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
			if type(c[1]) == "table" then
				for _, id in c[1] do
					table.insert(liste, modele(id))
				end
			else
				table.insert(liste, modele(c[1]))
			end
		end
	end
	task.spawn(function()
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync(liste)
		end)
	end)
end

-- Musique de combat : fondu à l'entrée et à la sortie, en boucle.
local groupeMusique = groupe("MagicalandMusique", 0.45)
local musique = nil

function Sons.musique(nom)
	local TweenService = game:GetService("TweenService")
	local ancienne = musique
	musique = nil
	if ancienne then
		local t = TweenService:Create(ancienne, TweenInfo.new(1.2), { Volume = 0 })
		t.Completed:Connect(function()
			ancienne:Destroy()
		end)
		t:Play()
	end
	local id = nom == "combat" and GEN.musiqueCombat or nom == "boss" and GEN.musiqueBoss or nil
	if not id then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Looped = true
	s.Volume = 0
	s.SoundGroup = groupeMusique
	s.Parent = groupeMusique
	s:Play()
	TweenService:Create(s, TweenInfo.new(1.5), { Volume = 0.6 }):Play()
	musique = s
end

-- Pour les tests : listes des identifiants utilisés.
Sons.ID = ID
Sons.GEN = GEN

return Sons
