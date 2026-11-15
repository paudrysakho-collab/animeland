-- EpeeClient : style « épée » côté client (pipeline d'animation).
-- Joue les animations SUR PLACE et déplace le HumanoidRootPart selon la courbe de racine (EpeeDonnees), gère
-- l'enchaînement du combo (clic mémorisé), l'ultime « Couronne de l'Aube » (caméra scriptée, impact frames) et les
-- effets envoyés par le serveur (EpeeFx) pour TOUS les joueurs proches. Le serveur vérifie et décide des dégâts.
-- Les animations et effets viennent de ReplicatedStorage.PIPE_Epee (FX, RealFX, Ultime01, Sequences).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local joueur = Players.LocalPlayer
local dossier = ReplicatedStorage:WaitForChild("Magicaland")
local D = require(dossier:WaitForChild("EpeeDonnees"))
local remotes = dossier:WaitForChild("Remotes")
local AttaquerEpee = remotes:WaitForChild("AttaquerEpee")
local UltimeEpee = remotes:WaitForChild("UltimeEpee")
local EpeeFx = remotes:WaitForChild("EpeeFx")
local pipe = ReplicatedStorage:WaitForChild("PIPE_Epee")
local FX = require(pipe:WaitForChild("FX"))
local RFX = require(pipe:WaitForChild("RealFX"))
local U = require(pipe:WaitForChild("Ultime01"))

local E = {}
local pistes, persoCharge = {}, nil
local etat = { etape = 0, cle = nil, debut = 0, file = false, ultime = false, depart = nil, verrou = nil }
local DISTANCE_EFFETS = 120 -- les autres joueurs voient les effets jusqu'à cette distance

local function idAnimation(seq)
	-- En Studio : séquence enregistrée à la volée. Dans le jeu publié : attribut AnimationId posé sur la séquence
	-- (voir pipeline-anim/04_roblox/a_publier.txt).
	local publie = seq:GetAttribute("AnimationId")
	if publie and publie ~= "" then
		return publie
	end
	return KeyframeSequenceProvider:RegisterKeyframeSequence(seq)
end

local function charger()
	local perso = joueur.Character
	if not perso then
		return nil
	end
	if persoCharge == perso then
		return perso
	end
	local hum = perso:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not animator then
		return nil
	end
	pistes = {}
	local seqs = pipe:WaitForChild("Sequences")
	local function piste(nomSeq)
		local seq = seqs:FindFirstChild(nomSeq)
		if not seq then
			return nil
		end
		local a = Instance.new("Animation")
		a.AnimationId = idAnimation(seq)
		local tr = animator:LoadAnimation(a)
		tr.Looped = false
		tr.Priority = Enum.AnimationPriority.Action4
		return tr
	end
	for cle, c in pairs(D.coups) do
		pistes[cle] = piste(c.seq)
	end
	pistes.ultime = piste(D.ultime.seq)
	persoCharge = perso
	FX.Setup(perso)
	return perso
end

function E.actif()
	return joueur:GetAttribute("PIPE_Epee") == true
end

local function comboActuel()
	return joueur:GetAttribute("PIPE_Combo") == "EpeisteAvance" and "EpeisteAvance" or "Epeiste"
end

-- Bloque la marche pendant un coup (le HRP est déplacé par la courbe de racine).
local function verrouiller(perso, oui)
	local hum = perso:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	if oui and not etat.verrou then
		etat.verrou = { vitesse = hum.WalkSpeed, saut = hum.JumpPower, auto = hum.AutoRotate }
		hum.WalkSpeed = 0
		hum.AutoRotate = false
	elseif not oui and etat.verrou then
		hum.WalkSpeed = etat.verrou.vitesse
		hum.AutoRotate = etat.verrou.auto
		etat.verrou = nil
	end
end

local function racineA(racine, tp)
	local f = tp * D.fps
	local i = math.floor(f)
	local n = #racine / 2
	if n == 0 then
		return 0, 0
	end
	i = math.clamp(i, 0, n - 1)
	local j = math.min(i + 1, n - 1)
	local a = f - i
	local x = racine[i * 2 + 1] + (racine[j * 2 + 1] - racine[i * 2 + 1]) * a
	local z = racine[i * 2 + 2] + (racine[j * 2 + 2] - racine[i * 2 + 2]) * a
	return x, z
end

-- Ennemi du combat en cours (créé par le serveur : « Monstre_<nom> » ou « Boss_<nom> »).
local function cibleCombat()
	local m = workspace:FindFirstChild("Monstre_" .. joueur.Name) or workspace:FindFirstChild("Boss_" .. joueur.Name)
	local corps = m and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart)
	return m, corps
end

-- Ciblage léger : au début d'un coup, se tourner vers l'ennemi et s'en approcher d'au plus 3 studs
-- (le serveur tolère 3 studs de plus que le déplacement prévu du coup).
local function departVersCible(hrp)
	local m, corps = cibleCombat()
	if not corps then
		return hrp.CFrame
	end
	local plat = Vector3.new(corps.Position.X, hrp.Position.Y, corps.Position.Z)
	local d = (plat - hrp.Position).Magnitude
	if d < 0.5 or d > 22 then
		return hrp.CFrame
	end
	local taille = m:GetExtentsSize()
	local voulu = math.max(taille.X, taille.Z) / 2 + 3.5
	local avance = math.clamp(d - voulu, 0, 3)
	local dir = (plat - hrp.Position).Unit
	return CFrame.lookAt(hrp.Position + dir * avance, plat)
end

local function jouerCoup(perso, k)
	local liste = D[comboActuel()]
	local cle = liste[k]
	local c = D.coups[cle]
	local tr = pistes[cle]
	if not tr then
		return
	end
	local precedent = etat.cle and pistes[etat.cle]
	if precedent and precedent ~= tr then
		precedent:Stop(D.FONDU)
	end
	etat.etape = (k == #liste) and 0 or k
	etat.cle = cle
	etat.debut = os.clock()
	etat.file = false
	etat.swing = false
	etat.depart = departVersCible(perso.HumanoidRootPart)
	perso.HumanoidRootPart.CFrame = etat.depart
	verrouiller(perso, true)
	tr:Play(D.FONDU)
	tr:AdjustSpeed(1)
	FX.MoveStart(perso, { short = c.nom })
	AttaquerEpee:FireServer(k)
end

function E.attaquer()
	if not E.actif() or etat.ultime then
		return
	end
	local perso = charger()
	if not perso then
		return
	end
	local c = etat.cle and D.coups[etat.cle]
	local t = os.clock() - etat.debut
	if not c or t > c.coupe + D.RESET then
		jouerCoup(perso, 1)
	elseif t < c.enchainement[1] then
		etat.file = true -- clic mémorisé : le coup suivant part dès que la fenêtre s'ouvre
	elseif t <= c.enchainement[2] then
		jouerCoup(perso, etat.etape == 0 and 1 or etat.etape + 1)
	else
		jouerCoup(perso, 1)
	end
end

function E.ultime()
	if not E.actif() or etat.ultime then
		return
	end
	if not charger() then
		return
	end
	UltimeEpee:FireServer()
end

local function lancerUltime(perso)
	local tr = pistes.ultime
	if not tr then
		return
	end
	local prec = etat.cle and pistes[etat.cle]
	if prec then
		prec:Stop(0.05)
	end
	etat.cle = nil
	etat.ultime = true
	local hrp = perso.HumanoidRootPart
	local _, corps = cibleCombat()
	if corps and (corps.Position - hrp.Position).Magnitude > 0.5 then
		hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(corps.Position.X, hrp.Position.Y, corps.Position.Z))
	end
	etat.depart = hrp.CFrame
	verrouiller(perso, true)
	local u = U.New(perso)
	tr:Play(0.05)
	tr:AdjustSpeed(1)
	task.spawn(function()
		local tient = nil
		while etat.ultime and perso.Parent do
			local tp = tr.TimePosition
			if not tient and tp >= tr.Length - 0.05 then
				tr:AdjustSpeed(0)
				tient = os.clock()
			end
			local tps = tient and (tr.Length + os.clock() - tient) or tp
			local x, z = racineA(D.ultime.racine, math.min(tps, D.ultime.longueur))
			perso.HumanoidRootPart.CFrame = etat.depart * CFrame.new(x, 0, z)
			u:Update(tps)
			if tient and os.clock() - tient > 1.2 then
				break
			end
			RunService.RenderStepped:Wait()
		end
		u:Finish()
		tr:Stop(0.2)
		etat.ultime = false
		verrouiller(perso, false)
	end)
end

-- Boucle : déplacement de la racine, traînée, coup suivant mémorisé, fin de coup, caméra.
RunService.RenderStepped:Connect(function()
	FX.UpdateCamera()
	if etat.ultime or not etat.cle then
		return
	end
	local perso = joueur.Character
	local c = D.coups[etat.cle]
	local tr = pistes[etat.cle]
	if not perso or not c or not tr or not perso:FindFirstChild("HumanoidRootPart") then
		return
	end
	local t = os.clock() - etat.debut
	local tp = tr.IsPlaying and tr.TimePosition or t
	if tp <= c.coupe then
		local x, z = racineA(c.racine, tp)
		perso.HumanoidRootPart.CFrame = etat.depart * CFrame.new(x, 0, z)
	end
	local surLame = tp >= c.touche[1] - 0.12 and tp <= c.touche[2] + 0.05 and not c.contact
	if surLame ~= etat.swing then
		etat.swing = surLame
		FX.Swing(perso, surLame, { short = c.nom, final = c.final })
	end
	if etat.file and t >= c.enchainement[1] and etat.etape ~= 0 then
		jouerCoup(perso, etat.etape + 1)
		return
	end
	if t >= c.coupe and tr.IsPlaying then
		tr:Stop(c.final and 0.25 or 0.15)
	end
	if t >= c.coupe + 0.1 and etat.verrou then
		verrouiller(perso, false)
	end
	if t > c.coupe + D.RESET then
		etat.cle = nil
		etat.etape = 0
	end
end)

-- Effets décidés par le serveur, pour tous les joueurs proches.
EpeeFx.OnClientEvent:Connect(function(m)
	local auteur = m.joueur
	local perso = auteur and auteur.Character
	local moi = joueur.Character
	local racineMoi = moi and moi:FindFirstChild("HumanoidRootPart")
	if auteur == joueur then
		if m.type == "ultime" then
			local p = charger()
			if p then
				lancerUltime(p)
			end
		elseif m.type == "touche" and moi then
			local c = D.coups[m.cle]
			if m.cle == "ultimeSol" or m.cle == "ultime" then
				RFX.Sparks(m.pos, 20)
			elseif c and c.final then
				FX.Impact(moi, m.pos, pistes[m.cle]) -- impact frame : seulement pour celui qui frappe
			else
				FX.Hit(moi, m.pos, c and c.contact and "kick" or nil)
			end
		end
		return
	end
	-- Autres joueurs : effets dans le monde + léger tremblement s'ils sont proches.
	local pos = m.pos or (perso and perso:FindFirstChild("HumanoidRootPart") and perso.HumanoidRootPart.Position)
	if not pos or not racineMoi or (racineMoi.Position - pos).Magnitude > DISTANCE_EFFETS then
		return
	end
	local proche = (racineMoi.Position - pos).Magnitude < 40
	if m.type == "touche" then
		RFX.Sparks(pos, m.final and 30 or 12)
		if m.final then
			RFX.Explosion(pos, 0.8)
		end
		if proche then
			FX.Shake(m.final and 0.2 or 0.06, 0.15)
		end
	elseif m.type == "ultime" and perso then
		task.delay(3.1, function()
			local r = perso:FindFirstChild("HumanoidRootPart")
			if r then
				RFX.Explosion(r.Position, 1.6)
				if (racineMoi.Position - r.Position).Magnitude < 40 then
					FX.Shake(0.3, 0.3)
				end
			end
		end)
	end
end)

joueur.CharacterAdded:Connect(function()
	persoCharge = nil
	etat = { etape = 0, cle = nil, debut = 0, file = false, ultime = false, depart = nil, verrou = nil }
end)

return E
