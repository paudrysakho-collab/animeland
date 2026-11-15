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
local RunService = game:GetService("RunService")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

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

-- Étape 10 : tous les réglages sont dans ReplicatedStorage.Magicaland.EpeeReglages (partagés avec le client).
local RG = require(ReplicatedStorage.Magicaland:WaitForChild("EpeeReglages"))
local HITSTOP = RG.HITSTOP
local REMBOBINAGE_MIN, REMBOBINAGE_MAX = RG.REMBOBINAGE_MIN, RG.REMBOBINAGE_MAX
local RAYON_LAME = RG.RAYON_LAME
local STUN_COUP, STUN_BOSS, ANTI_STUN = RG.STUN_COUP, RG.STUN_BOSS, RG.ANTI_STUN
local RALENTI_FINAL = RG.RALENTI_FINAL
local VITESSE_RECUL, RECUL_SANS_MUR, PORTEE_MUR, MARGE_MUR = RG.VITESSE_RECUL, RG.RECUL_SANS_MUR, RG.PORTEE_MUR, RG.MARGE_MUR
local LANCER_HAUT, RECUL_COUP = RG.LANCER_HAUT, RG.RECUL_COUP
local ULT_MAX, ULT_GAIN, PORTEE_ULTIME = RG.ULT_MAX, RG.ULT_GAIN, RG.PORTEE_ULTIME
local DORE_DUREE, DORE_MULT = RG.DORE_DUREE, RG.DORE_MULT
local GARDE_MAX, GARDE_COUT, GARDE_REGEN, GARDE_CASSEE = RG.GARDE_MAX, RG.GARDE_COUT, RG.GARDE_REGEN, RG.GARDE_CASSEE
local PARADE_FENETRE, PARADE_STUN, PARADE_STUN_BOSS = RG.PARADE_FENETRE, RG.PARADE_STUN, RG.PARADE_STUN_BOSS
local ANTI_SPAM_PARADE = RG.ANTI_SPAM_PARADE
local DASH_RECHARGE = { avant = RG.DASH.avant.recharge, cote = RG.DASH.cote.recharge }

local function etat(player)
	local s = etats[player]
	if not s then
		s = { etape = 0, debut = -1e9, coup = nil, enCours = nil, derniereAction = 0, ultime = false,
			bloc = false, blocDepuis = -1e9, dernierDebutBloc = -1e9, dernierBloc = 0, gardeCasseeFin = 0,
			projeteJusqua = 0, dashPret = {} }
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
-- Historique des positions de chaque ennemi (0,4 s) pour le rembobinage.
local historique = {} -- [e] = { {t, CFrame}, ... }
local function cfPasse(e, recul)
	local h = historique[e]
	if not h or #h == 0 then
		return e.corps.CFrame
	end
	local cible = os.clock() - recul
	for i = #h, 1, -1 do
		if h[i][1] <= cible then
			return h[i][2]
		end
	end
	return h[1][2]
end

-- Balayage de la lame (spherecast le long de la lame, puis de l'image précédente à l'actuelle) avec rembobinage :
-- la cible est replacée là où le joueur la voyait (100 à 150 ms plus tôt selon son ping) en ramenant la lame dans
-- le repère de l'ennemi de ce moment-là.
local function lameTouche(player, e, racineCF, image, precedente)
	local ok, ping = pcall(function()
		return player:GetNetworkPing()
	end)
	local recul = math.clamp(ok and ping or 0, REMBOBINAGE_MIN, REMBOBINAGE_MAX)
	local corr = e.corps.CFrame * cfPasse(e, recul):Inverse()
	local function pt(img, i)
		return corr * (racineCF * Vector3.new(img[i], img[i + 1], img[i + 2]))
	end
	local a, b = pt(image, 2), pt(image, 5)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { e.modele }
	local segments = { { a, b } }
	if precedente then
		local pa, pb = pt(precedente, 2), pt(precedente, 5)
		table.insert(segments, { pb, b })
		table.insert(segments, { (pa + pb) / 2, (a + b) / 2 })
	end
	for _, seg in ipairs(segments) do
		local d = seg[2] - seg[1]
		if d.Magnitude > 0.05 then
			local r = Workspace:Spherecast(seg[1], RAYON_LAME, d, params)
			if r then
				return true, r.Position
			end
		end
	end
	-- La sphère ne voit pas ce qu'elle touche déjà au départ : test de recouvrement en plus.
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Include
	op.FilterDescendantsInstances = { e.modele }
	for _, p in ipairs({ b, (a + b) / 2, a }) do
		if #Workspace:GetPartBoundsInRadius(p, 1.2, op) > 0 then
			return true, p
		end
	end
	return false, nil
end

---------------------------------------------------------------------
-- Barre d'ultime, sabre doré, réactions de la cible
---------------------------------------------------------------------
local function gagnerUlt(player, n)
	if etat(player).ultime then
		return
	end
	player:SetAttribute("PIPE_Ultime", math.clamp((player:GetAttribute("PIPE_Ultime") or 0) + n, 0, ULT_MAX))
end

local function estDore(player)
	return (player:GetAttribute("PIPE_SabreDore") or 0) > Workspace:GetServerTimeNow()
end

-- Lame dorée et lumineuse (vue par tous). garderTemps : réappliquer après une réapparition sans relancer les 45 s.
local function dorer(player, oui, garderTemps)
	if not garderTemps then
		player:SetAttribute("PIPE_SabreDore", oui and (Workspace:GetServerTimeNow() + DORE_DUREE) or nil)
	end
	local perso = player.Character
	local sabre = perso and perso:FindFirstChild("PIPE_Sword")
	local lame = sabre and sabre:FindFirstChild("Blade")
	if not lame then
		return
	end
	local sa = lame:FindFirstChildOfClass("SurfaceAppearance")
	if sa then
		pcall(function()
			sa.Color = oui and Color3.fromRGB(255, 205, 110) or Color3.new(1, 1, 1)
		end)
	end
	local l = lame:FindFirstChild("PIPE_LumiereDoree")
	if oui and not l then
		l = Instance.new("PointLight")
		l.Name = "PIPE_LumiereDoree"
		l.Color = Color3.fromRGB(255, 200, 100)
		l.Range = 7
		l.Brightness = 1.6
		l.Parent = lame
	elseif not oui and l then
		l:Destroy()
	end
end

-- Arrêt sur image de la cible (ses animations figées 0,03 s).
local function hitStopCible(e)
	local anim = e.hum and e.hum:FindFirstChildOfClass("Animator")
	if not anim then
		return
	end
	local geles = {}
	for _, tr in ipairs(anim:GetPlayingAnimationTracks()) do
		if tr.Speed ~= 0 then
			geles[tr] = tr.Speed
			tr:AdjustSpeed(0)
		end
	end
	task.delay(HITSTOP, function()
		for tr, v in pairs(geles) do
			if tr.Speed == 0 then
				pcall(function()
					tr:AdjustSpeed(v)
				end)
			end
		end
	end)
end

-- Animation de choc de la cible (séquence PIPE_Choc). Coup lourd en préparation : super-armure, pas de choc.
local idChoc = nil
local function jouerChoc(e)
	if e.attaqueLourde or not e.hum or not e.modele.Parent then
		return
	end
	if not e.pisteChoc then
		local anim = e.hum:FindFirstChildOfClass("Animator")
		local pipe = ReplicatedStorage:FindFirstChild("PIPE_Epee")
		local seq = pipe and pipe:FindFirstChild("Sequences") and pipe.Sequences:FindFirstChild("PIPE_Choc")
		if not anim or not seq then
			return
		end
		if not idChoc then
			local publie = seq:GetAttribute("AnimationId")
			if publie and publie ~= "" then
				idChoc = publie
			else
				local ok, id = pcall(function()
					return KeyframeSequenceProvider:RegisterKeyframeSequence(seq)
				end)
				if not ok then
					return
				end
				idChoc = id
			end
		end
		local a = Instance.new("Animation")
		a.AnimationId = idChoc
		local ok, tr = pcall(function()
			return anim:LoadAnimation(a)
		end)
		if not ok then
			return
		end
		tr.Priority = Enum.AnimationPriority.Action2
		tr.Looped = false
		e.pisteChoc = tr
	end
	e.pisteChoc:Play(0.03, e.def.boss and 0.5 or 1, 1)
end

-- Fin de combo : combo A (Épéiste) = projetée en arrière, contre un mur s'il y en a un ; combo B (avancé) = en l'air.
-- Le boss est trop lourd : simple recul fort.
local function projeter(player, e, depuis, enHauteur)
	local corps = e.corps
	if e.def.boss or corps.Anchored or not e.hum then
		if e.ia.recul then
			e.ia.recul(e, depuis, 3)
		end
		return
	end
	local dir = (corps.Position - depuis) * Vector3.new(1, 0, 1)
	dir = dir.Magnitude > 0.05 and dir.Unit or -corps.CFrame.LookVector
	local att = Instance.new("Attachment")
	att.Name = "PIPE_ProjAtt"
	att.Parent = corps
	local lv = Instance.new("LinearVelocity")
	lv.Name = "PIPE_Projection"
	lv.Attachment0 = att
	lv.MaxForce = math.huge
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	local duree, mur
	if enHauteur then
		lv.VectorVelocity = dir * 6 + Vector3.new(0, LANCER_HAUT, 0)
		duree = 0.2
	else
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local exclus = { e.modele }
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then
				table.insert(exclus, p.Character)
			end
		end
		local fx = Workspace:FindFirstChild("PIPE_FX")
		if fx then
			table.insert(exclus, fx)
		end
		params.FilterDescendantsInstances = exclus
		local r = Workspace:Raycast(corps.Position, dir * PORTEE_MUR, params)
		local dist = RECUL_SANS_MUR
		if r and math.abs(r.Normal.Y) < 0.6 then
			mur = r
			dist = math.max(0.5, r.Distance - MARGE_MUR)
		end
		lv.VectorVelocity = dir * VITESSE_RECUL + Vector3.new(0, 4, 0)
		duree = dist / VITESSE_RECUL
	end
	lv.Parent = corps
	e.projeteJusqua = os.clock() + duree
	task.delay(duree, function()
		lv:Destroy()
		att:Destroy()
		if corps.Parent and not enHauteur then
			corps.AssemblyLinearVelocity = Vector3.new(0, math.min(0, corps.AssemblyLinearVelocity.Y), 0)
		end
		if mur and corps.Parent then
			remoteFx:FireAllClients({ joueur = player, type = "mur", pos = mur.Position, normal = mur.Normal })
		end
	end)
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
	local s = etat(player)
	local maintenant = os.clock()
	e.combo += 1
	e.comboEtape = 0 -- le combo de base repart de 1 après un coup d'épée
	e.dernierCoupCombo = maintenant
	local bonus = math.min(CO.bonusMax, (e.combo - 1) * CO.bonusParCoup)
	local chanceCritique = C.CRITIQUE_BASE + (e.donnees.don == "critique" and 0.15 or 0)
	local critique = I.rng:NextNumber() < chanceCritique
	local degats = I.calculerDegats(e, coup.mult * (1 + bonus) * (estDore(player) and DORE_MULT or 1), critique)
	local effet = I.appliquerEffet(e, hum, coup.final and 2 or 1, maintenant)
	local boss = e.def.boss
	if coup.final then
		-- 5e coup : l'étourdissement est rompu (anti-boucle), la cible est projetée puis brièvement ralentie.
		e.etourdiFin = maintenant + (boss and 0.25 or 0.6)
		e.antiStunFin = maintenant + ANTI_STUN
		e.ralentiFin = math.max(e.ralentiFin, maintenant + RALENTI_FINAL)
		projeter(player, e, racine.Position, comboDe(player) == "EpeisteAvance")
	else
		if maintenant >= (e.antiStunFin or 0) then
			e.etourdiFin = math.max(e.etourdiFin, maintenant + (boss and STUN_BOSS or STUN_COUP))
			if not boss and not e.attaqueLourde and e.ia.annulerAttaque then
				e.ia.annulerAttaque(e, maintenant)
			end
		end
		-- Petit recul seulement (la cible doit rester à portée du coup suivant) ; seul le 5e coup projette.
		local corps = e.corps
		local dir = (corps.Position - racine.Position) * Vector3.new(1, 0, 1)
		if not boss and not corps.Anchored and dir.Magnitude > 0.05 then
			corps:ApplyImpulse(dir.Unit * RECUL_COUP * corps.AssemblyMass)
		end
	end
	hitStopCible(e)
	task.delay(HITSTOP, jouerChoc, e)
	s.debut += HITSTOP -- même arrêt sur image que chez le client : les fenêtres du combo restent alignées
	gagnerUlt(player, coup.final and ULT_GAIN.final or ULT_GAIN.touche)
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
	local t0 = os.clock()
	if not hum or s.ultime or s.bloc or t0 < s.gardeCasseeFin or t0 < s.projeteJusqua then
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
		-- Après le coup final, on ne repart qu'une fois sa frappe terminée (pas d'annulation par matraquage du clic).
		local mini = precedent and (precedent.final and math.min(precedent.coupe, precedent.touche[2] + 0.45)
			or math.min(precedent.coupe, precedent.enchainement[1]))
		if precedent and ecoule < mini - marge then
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
	local dmax = deplacementMax(coup.racine) + RG.TOLERANCE_DEPLACEMENT -- + ciblage léger du client
	task.spawn(function()
		local touche = false
		local precedente = nil
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
				local ok, pos = lameTouche(player, e, r2.CFrame, image, precedente)
				if ok and not touche then
					touche = true
					infligerCoup(player, e, cle, coup, pos)
					return
				end
				precedente = image
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
	-- Barre d'ultime pleine ET cible proche : pas d'ultime dans le vide.
	if (player:GetAttribute("PIPE_Ultime") or 0) < ULT_MAX then
		remoteFx:FireClient(player, { joueur = player, type = "refusUltime", raison = "barre" })
		return
	end
	if not e or e.lancement or e.pv <= 0 or I.distancePlat(racine.Position, e.corps.Position) > PORTEE_ULTIME then
		remoteFx:FireClient(player, { joueur = player, type = "refusUltime", raison = "cible" })
		return
	end
	player:SetAttribute("PIPE_Ultime", 0)
	e.lancement = INDEX_ULTIME
	e.combo = 0
	e.comboEtape = 0
	e.invulnJusqua = math.max(e.invulnJusqua, maintenant + D.ultime.longueur + 0.6) -- invulnérable pendant l'ultime
	I.envoyerRessources(player, e)
	s.bloc, s.coup, s.etape = false, nil, 0
	player:SetAttribute("PIPE_Bloc", false)
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
						local ok, pos = lameTouche(player, e, r2.CFrame, image, nil)
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
		if player.Parent then
			dorer(player, true) -- mode « sabre doré » pendant 45 s
		end
	end)
end

---------------------------------------------------------------------
-- Bloc (F), parade parfaite, garde ; dash ; dégâts reçus
---------------------------------------------------------------------
local function pointGarde(player)
	local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return r and (r.Position + r.CFrame.LookVector * 1.6 + Vector3.new(0, 0.6, 0)) or nil
end

function Epee.bloquer(player, oui)
	if type(oui) ~= "boolean" or not player:GetAttribute("PIPE_Epee") then
		return
	end
	local s = etat(player)
	local t = os.clock()
	if oui then
		if s.bloc or s.ultime or t < s.gardeCasseeFin or (player:GetAttribute("PIPE_Garde") or GARDE_MAX) <= 0 then
			return
		end
		s.bloc = true
		-- Parade parfaite seulement si la garde n'a pas été levée juste avant (pas de matraquage de F).
		s.blocDepuis = (t - s.dernierDebutBloc >= ANTI_SPAM_PARADE) and t or -1e9
		s.dernierDebutBloc = t
		s.coup, s.etape = nil, 0 -- lever la garde annule le combo
		s.derniereAction = t
		Epee.degainer(player, true)
	else
		if not s.bloc then
			return
		end
		s.bloc = false
		s.dernierBloc = t
	end
	player:SetAttribute("PIPE_Bloc", s.bloc)
end

function Epee.dash(player, sorte)
	local recharge = DASH_RECHARGE[sorte]
	if not recharge or not player:GetAttribute("PIPE_Epee") then
		return
	end
	local s = etat(player)
	local t = os.clock()
	if s.ultime or t < (s.dashPret[sorte] or 0) - 0.2 or t < s.gardeCasseeFin then
		return
	end
	s.dashPret[sorte] = t + recharge
	s.coup, s.etape, s.debut = nil, 0, -1e9 -- le dash annule le combo (le test de lame en cours s'arrête)
	if s.bloc then
		s.bloc = false
		s.dernierBloc = t
		player:SetAttribute("PIPE_Bloc", false)
	end
	s.projeteJusqua = 0 -- le dash permet de se relever après une projection
end

-- Appelé par Combat quand un ennemi touche un joueur qui a le sabre. Renvoie les dégâts, ou nil si bloqué / paré.
local function filtreDegats(player, e, degats, info)
	if not player:GetAttribute("PIPE_Epee") then
		return degats
	end
	local s = etat(player)
	local t = os.clock()
	local lourd = info and info.lourd
	local depuis = e.corps and e.corps.Position
	if lourd and e.type == "golem" then
		degats = math.floor(degats * RG.LOURD_MULT + 0.5)
	end
	if s.bloc and not lourd then
		if t - s.blocDepuis <= PARADE_FENETRE then
			-- Parade parfaite : aucun dégât, l'attaquant est étourdi.
			e.etourdiFin = math.max(e.etourdiFin, t + (e.def.boss and PARADE_STUN_BOSS or PARADE_STUN))
			if e.ia.annulerAttaque then
				e.ia.annulerAttaque(e, t)
			end
			hitStopCible(e)
			gagnerUlt(player, ULT_GAIN.parade)
			remoteFx:FireAllClients({ joueur = player, type = "parade", pos = pointGarde(player), cible = e.modele })
			return nil
		end
		local garde = (player:GetAttribute("PIPE_Garde") or GARDE_MAX) - degats * GARDE_COUT
		s.dernierBloc = t
		if garde > 0 then
			player:SetAttribute("PIPE_Garde", garde)
			gagnerUlt(player, ULT_GAIN.bloc)
			remoteFx:FireAllClients({ joueur = player, type = "bloque", pos = pointGarde(player) })
			return nil
		end
		-- Garde brisée : la moitié du coup passe et le joueur est sonné.
		player:SetAttribute("PIPE_Garde", 0)
		s.bloc = false
		player:SetAttribute("PIPE_Bloc", false)
		s.gardeCasseeFin = t + GARDE_CASSEE
		s.coup, s.etape = nil, 0
		remoteFx:FireAllClients({ joueur = player, type = "gardeCassee", pos = pointGarde(player), duree = GARDE_CASSEE })
		degats = math.floor(degats * 0.5 + 0.5)
	end
	gagnerUlt(player, ULT_GAIN.recu)
	if lourd and depuis then
		-- Coup lourd encaissé : projection (le dash permet de se relever plus vite).
		s.projeteJusqua = t + RG.PROJECTION_JOUEUR
		s.coup, s.etape = nil, 0
		remoteFx:FireClient(player, { joueur = player, type = "projete", depuis = depuis })
	end
	return degats
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

function Epee.init(combat, remoteAttaquer, remoteUltime, remoteFxEvent, remoteBloc, remoteDash, remoteEclair)
	Combat = combat
	I = combat._interne
	remoteFx = remoteFxEvent
	remoteAttaquer.OnServerEvent:Connect(Epee.attaquer)
	remoteUltime.OnServerEvent:Connect(Epee.ultime)
	if remoteBloc then
		remoteBloc.OnServerEvent:Connect(Epee.bloquer)
	end
	if remoteDash then
		remoteDash.OnServerEvent:Connect(Epee.dash)
	end
	if remoteEclair and Epee.eclair then
		remoteEclair.OnServerEvent:Connect(Epee.eclair)
	end
	Combat.filtreDegatsJoueur = filtreDegats
	-- Historique des positions des ennemis (rembobinage).
	RunService.Heartbeat:Connect(function()
		local t = os.clock()
		local actifs = {}
		for _, e in pairs(I.combats) do
			if e.corps and e.corps.Parent then
				actifs[e] = true
				local h = historique[e]
				if not h then
					h = {}
					historique[e] = h
				end
				table.insert(h, { t, e.corps.CFrame })
				while #h > 1 and t - h[1][1] > 0.4 do
					table.remove(h, 1)
				end
			end
		end
		for e in pairs(historique) do
			if not actifs[e] then
				historique[e] = nil
			end
		end
	end)
	-- Garde : regagnée 1 s après le dernier coup bloqué ; fin du sabre doré.
	task.spawn(function()
		while true do
			task.wait(0.2)
			local t = os.clock()
			for p, s in pairs(etats) do
				local g = p:GetAttribute("PIPE_Garde") or GARDE_MAX
				if not s.bloc and t - s.dernierBloc > 1 and t >= s.gardeCasseeFin and g < GARDE_MAX then
					p:SetAttribute("PIPE_Garde", math.min(GARDE_MAX, g + GARDE_REGEN * 0.2))
				end
				local fin = p:GetAttribute("PIPE_SabreDore")
				if fin and Workspace:GetServerTimeNow() >= fin then
					dorer(p, false)
				elseif fin then
					local perso = p.Character
					local lame = perso and perso:FindFirstChild("PIPE_Sword") and perso.PIPE_Sword:FindFirstChild("Blade")
					if lame and not lame:FindFirstChild("PIPE_LumiereDoree") then
						dorer(p, true, true)
					end
				end
			end
		end
	end)
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
		player:SetAttribute("PIPE_Ultime", player:GetAttribute("PIPE_Ultime") or 0)
		player:SetAttribute("PIPE_Garde", GARDE_MAX)
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
