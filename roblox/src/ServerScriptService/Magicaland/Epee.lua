-- Epee : style « épée » (pipeline d'animation) côté serveur.
-- Combos « Épéiste » / « Épéiste avancé » (5 coups, fenêtres d'enchaînement) et ultime « Couronne de l'Aube ».
-- Le client envoie seulement « coup n° k » ou « ultime ». Le serveur vérifie le rythme, la distance et le
-- déplacement, puis teste la LAME à chaque image de la fenêtre de touche (données de EpeeDonnees, repère du
-- HumanoidRootPart) contre l'ennemi du combat en cours. Une seule touche par cible et par coup. Les dégâts,
-- l'énergie, les effets et la victoire passent par les fonctions de Combat (Combat._interne) : mêmes règles.
-- Équipement : skin + sabre (au fourreau, dégainé pendant les attaques). Zone de test : Workspace.PIPE_ZoneTest.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Donnees = require(ReplicatedStorage:WaitForChild("Magicaland"):WaitForChild("Donnees"))
local D = require(ReplicatedStorage.Magicaland:WaitForChild("EpeeDonnees"))
local C = Donnees.COMBAT
local EN = C.ENERGIE
local CO = C.COMBO

local Epee = {}
local Combat, I, remoteFx
local etats = {} -- [Player] = état du style épée

local INDEX_ULTIME = 6 -- l'ultime remplace l'attaque n° 6 (touche F / 6) : même coût, même recharge
local GRIP = CFrame.new(0, 0, 0, 0.866025, 0.25, -0.433013, 0.5, -0.433013, 0.75, 0, -0.866025, -0.5)
local SAYA_DIR = Vector3.new(0.05, -0.45, 0.89).Unit
local SAYA_C0 = CFrame.fromMatrix(Vector3.new(-1.05, -0.05, -0.45), (Vector3.new(1, 0, 0) - SAYA_DIR * SAYA_DIR.X).Unit, SAYA_DIR)
	* CFrame.new(0.0546, 1.71, 0)
local RENGAINE_APRES = 5 -- secondes sans attaque avant de rengainer

local function etat(player)
	local s = etats[player]
	if not s then
		s = { etape = 0, debut = -1e9, coup = nil, enCours = nil, derniereAction = 0, ultime = false }
		etats[player] = s
	end
	return s
end

local function comboDe(player)
	local c = player:GetAttribute("PIPE_Combo")
	return (c == "EpeisteAvance") and "EpeisteAvance" or "Epeiste"
end

---------------------------------------------------------------------
-- Équipement : skin + sabre + fourreau
---------------------------------------------------------------------
local function dossierPipe()
	return ServerStorage:FindFirstChild("PipelineAnims")
end

function Epee.degainer(player, oui)
	local perso = player.Character
	local sabre = perso and perso:FindFirstChild("PIPE_Sword")
	if not sabre then
		return
	end
	local main = sabre.Handle:FindFirstChild("PIPE_Weld_Main")
	local fourreau = sabre.Handle:FindFirstChild("PIPE_Weld_Fourreau")
	if main and fourreau then
		main.Enabled = oui
		fourreau.Enabled = not oui
	end
	player:SetAttribute("PIPE_Degaine", oui)
end

function Epee.equiper(player, numeroSkin)
	local perso = player.Character
	local dossier = dossierPipe()
	if not perso or not dossier or not perso:FindFirstChild("RightHand") then
		return
	end
	numeroSkin = numeroSkin or player:GetAttribute("PIPE_Skin") or 1
	player:SetAttribute("PIPE_Skin", numeroSkin)
	local Skins = require(dossier:WaitForChild("Skins"))
	Skins.Apply(perso, numeroSkin)
	for _, n in ipairs({ "PIPE_Sword", "PIPE_Saya" }) do
		local o = perso:FindFirstChild(n)
		if o then
			o:Destroy()
		end
	end
	local gabarit = dossier:FindFirstChild("PIPE_KatanaTemplate")
	if not gabarit then
		return
	end
	local saya = gabarit.PIPE_Saya:Clone()
	saya.CFrame = perso.LowerTorso.CFrame * SAYA_C0
	local ws = Instance.new("Weld")
	ws.Name = "PIPE_Weld_Saya"
	ws.Part0 = perso.LowerTorso
	ws.Part1 = saya
	ws.C0 = SAYA_C0
	ws.Parent = saya
	saya.Parent = perso
	local sabre = gabarit.PIPE_Sword:Clone()
	local h = sabre.Handle
	h.CFrame = perso.RightHand.CFrame * GRIP
	for _, p in ipairs(sabre:GetChildren()) do
		if p:IsA("BasePart") and p ~= h then
			local w = p:FindFirstChildOfClass("Weld")
			if w then
				p.CFrame = h.CFrame * w.C0
			end
		end
	end
	local main = Instance.new("Weld")
	main.Name = "PIPE_Weld_Main"
	main.Part0 = perso.RightHand
	main.Part1 = h
	main.C0 = GRIP
	main.Parent = h
	-- Au fourreau : la poignée sort de l'embouchure (même origine que le fourreau, cf. scripts/katana.py).
	local fourreau = Instance.new("Weld")
	fourreau.Name = "PIPE_Weld_Fourreau"
	fourreau.Part0 = saya
	fourreau.Part1 = h
	fourreau.C0 = CFrame.new(-0.0546, -2.2, 0)
	fourreau.Parent = h
	sabre.Parent = perso
	player:SetAttribute("PIPE_Epee", true)
	Epee.degainer(player, false)
end

---------------------------------------------------------------------
-- Test de la lame (segment base -> pointe) contre l'ennemi
---------------------------------------------------------------------
local function lameTouche(e, racineCF, image)
	local a = racineCF * Vector3.new(image[2], image[3], image[4])
	local b = racineCF * Vector3.new(image[5], image[6], image[7])
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { e.modele }
	local r = Workspace:Raycast(a, b - a, params)
	if r then
		return true, r.Position
	end
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Include
	op.FilterDescendantsInstances = { e.modele }
	local proches = Workspace:GetPartBoundsInRadius(b, 1.2, op)
	if #proches > 0 then
		return true, b
	end
	return false, nil
end

-- Déplacement maximal de la racine pendant un coup (anti-téléportation : le HRP ne doit pas aller plus loin).
local function deplacementMax(racine)
	local m = 0
	for i = 1, #racine, 2 do
		m = math.max(m, Vector3.new(racine[i], 0, racine[i + 1]).Magnitude)
	end
	return m
end

local function infligerCoup(player, e, cle, coup, pos)
	local hum, racine = I.partiesVivantes(player)
	if not hum then
		return
	end
	local maintenant = os.clock()
	e.combo += 1
	e.comboEtape = 0 -- le combo de base repart de 1 après un coup d'épée
	e.dernierCoupCombo = maintenant
	local bonus = math.min(CO.bonusMax, (e.combo - 1) * CO.bonusParCoup)
	local chanceCritique = C.CRITIQUE_BASE + (e.donnees.don == "critique" and 0.15 or 0)
	local critique = I.rng:NextNumber() < chanceCritique
	local degats = I.calculerDegats(e, coup.mult * (1 + bonus), critique)
	local effet = I.appliquerEffet(e, hum, coup.final and 2 or 1, maintenant)
	if coup.final then
		e.etourdiFin = math.max(e.etourdiFin, maintenant + (e.def.boss and 0.25 or 0.6))
	end
	if e.ia.recul then
		e.ia.recul(e, racine.Position, coup.final and 2 or 1)
	end
	I.gagnerEnergie(e, EN.parCoup + (critique and EN.parCritique or 0) + (coup.final and 1 or 0))
	remoteFx:FireAllClients({ joueur = player, type = "touche", cle = cle, pos = pos, final = coup.final })
	I.blesserEnnemi(player, e, degats, critique, effet, nil, { combo = e.combo, etape = 0, bonus = bonus })
end

---------------------------------------------------------------------
-- Combo
---------------------------------------------------------------------
function Epee.attaquer(player, k)
	if type(k) ~= "number" then
		return
	end
	k = math.floor(k)
	local s = etat(player)
	local hum, racine = I.partiesVivantes(player)
	if not hum or s.ultime then
		return
	end
	local liste = D[comboDe(player)]
	if not liste or not liste[k] then
		return
	end
	local maintenant = os.clock()
	-- Rythme (anti-triche) : le coup k doit suivre le coup k-1 dans sa fenêtre d'enchaînement, ou repartir de 1.
	local precedent = s.coup and D.coups[s.coup]
	local ecoule = maintenant - s.debut
	local marge = 0.15 -- réseau
	if k == 1 then
		if precedent and ecoule < math.min(precedent.coupe, precedent.enchainement[1]) - marge then
			return -- trop tôt
		end
	else
		if s.etape ~= k - 1 or not precedent then
			return
		end
		if ecoule < precedent.enchainement[1] - marge or ecoule > precedent.enchainement[2] + marge + D.RESET then
			return
		end
	end
	local cle = liste[k]
	local coup = D.coups[cle]
	s.etape = (k == #liste) and 0 or k
	s.coup = cle
	s.debut = maintenant
	s.derniereAction = maintenant
	Epee.degainer(player, true)
	remoteFx:FireAllClients({ joueur = player, type = "coup", cle = cle })

	local e = I.combats[player]
	if not e or e.lancement then
		return -- hors combat : animation seulement
	end
	-- Distance au départ : trop loin, le coup part dans le vide (pas de test de lame).
	if I.distancePlat(racine.Position, e.corps.Position) > e.def.porteeJoueur + deplacementMax(coup.racine) + 6 then
		return
	end
	local depart = racine.Position
	local dmax = deplacementMax(coup.racine) + 3
	task.spawn(function()
		local touche = false
		for _, image in ipairs(coup.lame) do
			local attente = s.debut + image[1] - os.clock()
			if attente > 0 then
				task.wait(attente)
			end
			if s.coup ~= cle or I.combats[player] ~= e then
				return
			end
			local h2, r2 = I.partiesVivantes(player)
			if not h2 then
				return
			end
			if I.distancePlat(r2.Position, depart) > dmax then
				return -- déplacement impossible pour ce coup : refusé
			end
			if coup.contact then
				if I.distancePlat(r2.Position, e.corps.Position) <= e.def.porteeJoueur + 1 then
					infligerCoup(player, e, cle, coup, e.corps.Position)
					return
				end
			else
				local ok, pos = lameTouche(e, r2.CFrame, image)
				if ok and not touche then
					touche = true
					infligerCoup(player, e, cle, coup, pos)
					return
				end
			end
		end
	end)
end

---------------------------------------------------------------------
-- Ultime « Couronne de l'Aube »
---------------------------------------------------------------------
function Epee.ultime(player)
	local s = etat(player)
	local e = I.combats[player]
	local hum, racine = I.partiesVivantes(player)
	if not hum or s.ultime then
		return
	end
	local A = C.ATTAQUES[INDEX_ULTIME]
	local maintenant = os.clock()
	if e then
		if e.lancement then
			return
		end
		if maintenant < e.pret[INDEX_ULTIME] then
			I.envoyer(player, { type = "refus", raison = "recharge", index = INDEX_ULTIME })
			return
		end
		if e.energie < A.cout then
			I.envoyer(player, { type = "refus", raison = "energie", index = INDEX_ULTIME })
			return
		end
		e.energie -= A.cout
		e.pret[INDEX_ULTIME] = maintenant + A.recharge * I.multRecharge(e)
		e.lancement = INDEX_ULTIME
		e.combo = 0
		e.comboEtape = 0
		e.invulnJusqua = math.max(e.invulnJusqua, maintenant + D.ultime.longueur + 0.6)
		I.envoyerRessources(player, e)
	end
	s.ultime = true
	s.derniereAction = maintenant
	Epee.degainer(player, true)
	remoteFx:FireAllClients({ joueur = player, type = "ultime" })
	local U = D.ultime
	local depart = racine.Position
	task.spawn(function()
		local dejaTouche = {}
		local function attendre(t)
			local w = maintenant + t - os.clock()
			if w > 0 then
				task.wait(w)
			end
		end
		-- 3 coups en éventail (test de lame autour de chaque instant)
		for n, tFan in ipairs(U.eventail) do
			for _, image in ipairs(U.lame) do
				if math.abs(image[1] - tFan) <= 0.07 and not dejaTouche[n] then
					attendre(image[1])
					local h2, r2 = I.partiesVivantes(player)
					if e and h2 and I.combats[player] == e and I.distancePlat(r2.Position, depart) < 24 then
						local ok, pos = lameTouche(e, r2.CFrame, image)
						if ok then
							dejaTouche[n] = true
							local degats = I.calculerDegats(e, A.mult / 9 * U.multEventail, false)
							remoteFx:FireAllClients({ joueur = player, type = "touche", cle = "ultime", pos = pos })
							I.blesserEnnemi(player, e, degats, false, nil, INDEX_ULTIME, {})
						end
					end
				end
			end
		end
		-- frappe au sol : zone autour du point d'impact
		attendre(U.sol)
		local h3, r3 = I.partiesVivantes(player)
		if e and h3 and I.combats[player] == e and e.pv > 0 then
			local impact = r3.Position + r3.CFrame.LookVector * 1.5
			if I.distancePlat(r3.Position, depart) < 24 and I.distancePlat(impact, e.corps.Position) <= U.rayonSol + (e.def.boss and 4 or 0) then
				local t = os.clock()
				local degats = I.calculerDegats(e, A.mult / 9 * U.multSol, true)
				local effet = I.appliquerEffet(e, h3, 3, t)
				e.etourdiFin = math.max(e.etourdiFin, t + (e.def.boss and 0.4 or 1))
				if e.ia.annulerAttaque then
					e.ia.annulerAttaque(e, t)
				end
				if e.ia.recul then
					e.ia.recul(e, impact, 4)
				end
				remoteFx:FireAllClients({ joueur = player, type = "touche", cle = "ultimeSol", pos = e.corps.Position, final = true })
				I.blesserEnnemi(player, e, degats, true, effet, INDEX_ULTIME, {})
			end
		end
		attendre(U.longueur)
		if e and I.combats[player] == e then
			e.lancement = nil
			I.envoyerRessources(player, e)
		end
		s.ultime = false
	end)
end

---------------------------------------------------------------------
-- Zone de test : pancartes (ProximityPrompt) pour le skin et le combo
---------------------------------------------------------------------
local function brancherZoneTest()
	local zone = Workspace:FindFirstChild("PIPE_ZoneTest")
	if not zone then
		return
	end
	for _, pancarte in ipairs(zone:GetDescendants()) do
		if pancarte:IsA("ProximityPrompt") then
			pancarte.Triggered:Connect(function(player)
				local skin = pancarte:GetAttribute("Skin")
				local combo = pancarte:GetAttribute("Combo")
				if skin then
					Epee.equiper(player, skin)
				elseif combo then
					player:SetAttribute("PIPE_Combo", combo)
					local s = etat(player)
					s.etape, s.coup = 0, nil
				end
			end)
		end
	end
end

function Epee.init(combat, remoteAttaquer, remoteUltime, remoteFxEvent)
	Combat = combat
	I = combat._interne
	remoteFx = remoteFxEvent
	remoteAttaquer.OnServerEvent:Connect(Epee.attaquer)
	remoteUltime.OnServerEvent:Connect(Epee.ultime)
	brancherZoneTest()
	local function surPerso(player, perso)
		perso:WaitForChild("RightHand", 10)
		perso:WaitForChild("LowerTorso", 10)
		task.wait(0.3)
		if player.Character == perso then
			Epee.equiper(player)
		end
	end
	local function surJoueur(player)
		player:SetAttribute("PIPE_Combo", player:GetAttribute("PIPE_Combo") or "Epeiste")
		player.CharacterAdded:Connect(function(perso)
			surPerso(player, perso)
		end)
		if player.Character then
			task.spawn(surPerso, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(surJoueur)
	for _, p in ipairs(Players:GetPlayers()) do
		surJoueur(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		etats[p] = nil
	end)
	-- Rengaine automatique après quelques secondes sans attaque.
	task.spawn(function()
		while true do
			task.wait(1)
			local t = os.clock()
			for p, s in pairs(etats) do
				if p:GetAttribute("PIPE_Degaine") and not s.ultime and t - s.derniereAction > RENGAINE_APRES then
					Epee.degainer(p, false)
				end
			end
		end
	end)
end

return Epee
