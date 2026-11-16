-- Compétences du feu (touches 1 à 6) côté serveur (mission combat, étape 4).
-- Le client envoie seulement le numéro. Le serveur vérifie (sabre équipé, vivant, pas occupé, recharge), choisit
-- la direction d'après SES positions, lance l'action au temps du marqueur de l'animation, simule la vague image par
-- image et applique les dégâts avec les mêmes règles que les coups (Combat._interne). Les clients n'affichent que
-- des effets (EpeeFx). Un dash avant le contact annule la compétence (la recharge est quand même comptée).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Donnees = require(ReplicatedStorage:WaitForChild("Magicaland"):WaitForChild("Donnees"))
local CF = require(ReplicatedStorage.Magicaland:WaitForChild("CompetencesFeu"))
local C = Donnees.COMBAT

local Competences = {}
local I, remoteFx, Epee
local etats = {} -- [Player] = { pret = { [n] = heure }, jeton = table ou nil }

local function etat(player)
	local s = etats[player]
	if not s then
		s = { pret = {}, jeton = nil }
		etats[player] = s
	end
	return s
end

local function filtre(player, e)
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	local liste = { player.Character }
	if e and e.modele then
		table.insert(liste, e.modele)
	end
	local fx = Workspace:FindFirstChild("PIPE_FX")
	if fx then
		table.insert(liste, fx)
	end
	p.FilterDescendantsInstances = liste
	return p
end

-- Hauteur du sol sous un point (ou 3 studs plus bas si rien).
local function hauteurSol(pos, params)
	local r = Workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, -14, 0), params)
	return r and r.Position.Y or (pos.Y - 3)
end

local function toucherVague(player, e, def, pos)
	local hum = I.partiesVivantes(player)
	if not hum or I.combats[player] ~= e or e.pv <= 0 then
		return
	end
	local maintenant = os.clock()
	local critique = I.rng:NextNumber() < C.CRITIQUE_BASE + (e.donnees.don == "critique" and 0.15 or 0)
	local degats = I.calculerDegats(e, def.vague.mult, critique)
	local effet = I.appliquerEffet(e, hum, 2, maintenant)
	if not e.def.boss then
		e.etourdiFin = math.max(e.etourdiFin, maintenant + def.vague.etourdi)
		if not e.attaqueLourde and e.ia.annulerAttaque then
			e.ia.annulerAttaque(e, maintenant)
		end
	end
	if Epee.projeterCible then
		Epee.projeterCible(player, e, pos, false) -- recul fort, loin de l'explosion
	end
	remoteFx:FireAllClients({ joueur = player, type = "vague_impact", pos = pos, cible = e.corps.Position })
	I.blesserEnnemi(player, e, degats, critique, effet, nil, nil)
end

-- 1. Sillon de braise : la vague part du point où la lame touche le sol et file au ras du sol.
local function lancerVague(player, e, racine, def)
	local v = def.vague
	local params = filtre(player, e)
	local avant = racine.CFrame.LookVector * Vector3.new(1, 0, 1)
	avant = avant.Magnitude > 0.01 and avant.Unit or Vector3.new(0, 0, -1)
	local dir = avant
	if e and e.corps and e.corps.Parent then
		local vers = (e.corps.Position - racine.Position) * Vector3.new(1, 0, 1)
		if vers.Magnitude > 0.5 and math.deg(math.acos(math.clamp(vers.Unit:Dot(avant), -1, 1))) <= v.angleMax then
			dir = vers.Unit
		end
	end
	local droite = Vector3.new(-avant.Z, 0, avant.X)
	local depart = racine.Position + avant * v.avance + droite * v.decalage
	local origine = Vector3.new(depart.X, hauteurSol(depart, params), depart.Z)
	local portee = v.portee
	local mur = Workspace:Raycast(origine + Vector3.new(0, 1.5, 0), dir * v.portee, params)
	if mur and math.abs(mur.Normal.Y) < 0.6 then
		portee = math.max(0, mur.Distance - 0.5)
	end
	remoteFx:FireAllClients({ joueur = player, type = "vague", origine = origine, dir = dir, vitesse = v.vitesse,
		portee = portee, t0 = Workspace:GetServerTimeNow() })
	local debut = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local d = math.min((os.clock() - debut) * v.vitesse, portee)
		local pos = origine + dir * d
		if e and I.combats[player] == e and e.pv > 0 and e.corps.Parent then
			local c = e.corps.Position
			local plat = Vector3.new(c.X - pos.X, 0, c.Z - pos.Z).Magnitude
			local demi = math.max(e.corps.Size.X, e.corps.Size.Z) / 2
			if plat <= v.rayon + demi and c.Y - pos.Y < 10 and c.Y - pos.Y > -3 then
				conn:Disconnect()
				toucherVague(player, e, def, pos)
				return
			end
		end
		if d >= portee then
			conn:Disconnect()
			remoteFx:FireAllClients({ joueur = player, type = "vague_fin", pos = pos })
		end
	end)
end

local ACTIONS = { slash = lancerVague }

function Competences.lancer(player, n)
	if type(n) ~= "number" then
		return
	end
	n = math.floor(n)
	local def = CF.liste[n]
	if not def or not player:GetAttribute("PIPE_Epee") then
		return
	end
	local hum, racine = I.partiesVivantes(player)
	local s = etat(player)
	local t = os.clock()
	if not hum or Epee.occupe(player) or s.jeton then
		return
	end
	-- Recharge (marge réseau 0,15 s). Le client affiche la sienne ; en cas de refus il le saura par « refus ».
	if t < (s.pret[n] or 0) - 0.15 then
		remoteFx:FireClient(player, { joueur = player, type = "competence_refus", n = n, reste = s.pret[n] - t })
		return
	end
	s.pret[n] = t + def.recharge
	local jeton = {}
	s.jeton = jeton
	Epee.reserver(player, def.duree, function()
		if s.jeton == jeton and not jeton.contact then
			jeton.annule = true -- dash avant le contact
		end
	end)
	Epee.degainer(player, true)
	remoteFx:FireAllClients({ joueur = player, type = "competence", n = n })
	task.delay(def.contact, function()
		jeton.contact = true
		if not jeton.annule and player.Parent and racine.Parent and ACTIONS[def.id] then
			ACTIONS[def.id](player, I.combats[player], racine, def)
		end
	end)
	task.delay(def.duree, function()
		if s.jeton == jeton then
			s.jeton = nil
		end
	end)
end

function Competences.init(combat, remoteCompetence, remoteFxEvent, epee)
	I = combat._interne
	remoteFx = remoteFxEvent
	Epee = epee
	remoteCompetence.OnServerEvent:Connect(Competences.lancer)
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		etats[p] = nil
	end)
end

return Competences
