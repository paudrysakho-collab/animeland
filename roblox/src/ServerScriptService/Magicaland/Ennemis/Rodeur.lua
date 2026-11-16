-- Rôdeur de cendre (mission combat, étape 3) : humanoïde horrifique modélisé dans Blender
-- (pipeline-anim/scripts/rodeur.py), 1,6 fois un avatar, très mince, griffes de 40 cm, cheveux sur le visage, yeux rouges.
-- Rig R15 (Motor6D aux noms R15) monté dans ServerStorage.PipelineAnims.PIPE_RodeurTemplate.
-- Animations faites par poses clés (scripts/anims_rodeur.py) : attente, marche, course, griffe, choc, projeté.
-- Le serveur décide de tout : l'alerte (0,6 s = l'anticipation de l'animation), puis les dégâts au marqueur
-- « Contact » de l'animation de griffe (sécurité : 0,25 s plus tard si le marqueur n'arrive pas).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local Workspace = game:GetService("Workspace")

local Donnees = require(ReplicatedStorage:WaitForChild("Magicaland"):WaitForChild("Donnees"))
local Rigs = require(script.Parent.Parent:WaitForChild("Rigs"))
local M = Donnees.COMBAT.MONSTRE

local Rodeur = {}

local VITESSE_MARCHE = 8
local VITESSE_COURSE = 17
local DISTANCE_COURSE = 16 -- au-delà, il court
local LIMITE_FRAPPE = 0.25 -- sécurité si le marqueur « Contact » n'arrive pas

-- Identifiants des séquences (enregistrées à la volée dans Studio, ou publiées : attribut « AnimationId »).
local ids = {}
local function idSequence(nom)
	if ids[nom] then
		return ids[nom]
	end
	local seqs = ReplicatedStorage:FindFirstChild("PIPE_Epee") and ReplicatedStorage.PIPE_Epee:FindFirstChild("Sequences")
	local seq = seqs and seqs:FindFirstChild(nom)
	if not seq then
		return nil
	end
	local publie = seq:GetAttribute("AnimationId")
	if publie and publie ~= "" then
		ids[nom] = publie
	else
		local ok, id = pcall(function()
			return KeyframeSequenceProvider:RegisterKeyframeSequence(seq)
		end)
		ids[nom] = ok and id or nil
	end
	return ids[nom]
end

local function charger(animator, nom, priorite, boucle)
	local id = idSequence(nom)
	if not id then
		return nil
	end
	local a = Instance.new("Animation")
	a.AnimationId = id
	local ok, tr = pcall(function()
		return animator:LoadAnimation(a)
	end)
	if not ok then
		return nil
	end
	tr.Priority = priorite
	tr.Looped = boucle
	return tr
end

function Rodeur.creer(player, position, def)
	local gabarit = ServerStorage:WaitForChild("PipelineAnims"):WaitForChild("PIPE_RodeurTemplate")
	local m = gabarit:Clone()
	m.Name = "Monstre_" .. player.Name
	local hum = m:FindFirstChildOfClass("Humanoid")
	local racine = m.HumanoidRootPart
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.BreakJointsOnDeath = false
	hum.MaxHealth = 1e6
	hum.Health = 1e6 -- la vraie vie est gérée par Combat
	hum.WalkSpeed = VITESSE_MARCHE
	for _, etat in { Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.Dead, Enum.HumanoidStateType.Climbing } do
		hum:SetStateEnabled(etat, false)
	end
	m:PivotTo(CFrame.new(position + Vector3.new(0, hum.HipHeight + racine.Size.Y / 2 + 0.1, 0)))
	m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	m.Parent = Workspace
	pcall(function()
		racine:SetNetworkOwner(nil)
	end)

	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local P = Enum.AnimationPriority
	local pistes = {
		idle = charger(animator, "PIPE_rodeur_attente", P.Idle, true),
		marche = charger(animator, "PIPE_rodeur_marche", P.Movement, true),
		course = charger(animator, "PIPE_rodeur_course", P.Movement, true),
		coup = charger(animator, "PIPE_rodeur_griffe", P.Action, false),
		projete = charger(animator, "PIPE_rodeur_projete", P.Action3, true),
	}
	if pistes.idle then
		pistes.idle:Play()
	end

	local surbrillance = Instance.new("Highlight")
	surbrillance.FillColor = Color3.new(1, 1, 1)
	surbrillance.FillTransparency = 1
	surbrillance.OutlineColor = Color3.fromRGB(255, 60, 40)
	surbrillance.OutlineTransparency = 1
	surbrillance.DepthMode = Enum.HighlightDepthMode.Occluded
	surbrillance.Parent = m
	return m, racine, m:FindFirstChild("Head"), { hum = hum, pistes = pistes, surbrillance = surbrillance }
end

-- Résout le coup de griffe (une seule fois par attaque) : le serveur mesure la distance au moment du contact.
local function resoudre(e)
	if not e.attenteContact then
		return
	end
	e.attenteContact = false
	local ctx = e.ctx
	if not ctx or not e.racine.Parent then
		return
	end
	local dist = (Vector3.new(ctx.racine.Position.X, 0, ctx.racine.Position.Z) - Vector3.new(e.racine.Position.X, 0, e.racine.Position.Z)).Magnitude
	if dist <= M.portee + 1.5 then
		ctx.frapper(M.degats)
	else
		ctx.envoyer({ type = "esquive" })
	end
	e.mesureContact = os.clock() - (e.debutGriffe or os.clock())
end

function Rodeur.init(e, maintenant)
	e.echelle = 1.6
	e.seqChoc = "PIPE_rodeur_choc" -- réaction aux coups (lue par Epee.jouerChoc)
	e.prochaineAttaque = maintenant + 2
	e.prepareJusqua = nil
	e.prochainChemin = 0
	local coup = e.pistes.coup
	if coup then
		coup:GetMarkerReachedSignal("Depart"):Connect(function()
			if e.attenteContact and e.racine.Parent then
				e.racine:ApplyImpulse(e.racine.CFrame.LookVector * e.racine.AssemblyMass * 26) -- fente
			end
		end)
		coup:GetMarkerReachedSignal("Contact"):Connect(function()
			resoudre(e)
		end)
	end
end

function Rodeur.annulerAttaque(e, maintenant)
	e.prepareJusqua = nil
	e.attenteContact = false
	e.surbrillance.OutlineTransparency = 1
	if e.pistes.coup then
		e.pistes.coup:Stop(0.1)
	end
	e.hum.AutoRotate = true
	e.prochaineAttaque = math.max(e.prochaineAttaque, maintenant + 1)
end

function Rodeur.recul(e, depuis, force)
	local dir = (e.racine.Position - depuis) * Vector3.new(1, 0, 1)
	if dir.Magnitude > 0.01 then
		force = force or 1
		e.racine:ApplyImpulse((dir.Unit * 16 * force + Vector3.new(0, force >= 2 and 10 * force or 0, 0)) * e.racine.AssemblyMass)
	end
end

-- Projeté (appelé par Epee.projeter) : membres qui battent tant qu'il est en l'air.
function Rodeur.projete(e, duree)
	local p = e.pistes.projete
	if p and not p.IsPlaying then
		for _, nom in { "idle", "marche", "course" } do
			if e.pistes[nom] and e.pistes[nom].IsPlaying then
				e.pistes[nom]:Stop(0.1)
			end
		end
		p:Play(0.08)
	end
	e.projeteVu = os.clock() + duree
end

local function locomotion(e, maintenant)
	local p = e.pistes
	-- fin de projection : de nouveau au sol ; tant qu'il vole, ni marche ni attente
	if p.projete and p.projete.IsPlaying then
		if maintenant > (e.projeteVu or 0) + 0.25 and e.hum.FloorMaterial ~= Enum.Material.Air then
			p.projete:Stop(0.2)
		else
			return
		end
	end
	local v = (e.racine.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
	local voulu = "idle"
	if v > 1.5 then
		voulu = e.hum.WalkSpeed > VITESSE_MARCHE + 1 and "course" or "marche"
	end
	for _, nom in { "idle", "marche", "course" } do
		local tr = p[nom]
		if tr then
			if nom == voulu and not tr.IsPlaying then
				tr:Play(0.25)
			elseif nom ~= voulu and tr.IsPlaying then
				tr:Stop(0.25)
			end
		end
	end
	if voulu == "marche" and p.marche then
		p.marche:AdjustSpeed(math.clamp(v / VITESSE_MARCHE, 0.6, 1.6))
	elseif voulu == "course" and p.course then
		p.course:AdjustSpeed(math.clamp(v / VITESSE_COURSE, 0.7, 1.4))
	end
end

function Rodeur.mettreAJour(e, dt, maintenant, ctx)
	e.ctx = ctx
	local pos = e.racine.Position
	local joueur = ctx.racine.Position
	local dist = (Vector3.new(joueur.X, 0, joueur.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
	local etourdi = maintenant < e.etourdiFin
	local portee = M.portee

	if e.attenteContact and maintenant >= (e.limiteContact or 0) then
		resoudre(e) -- sécurité : le marqueur n'est pas arrivé
	end

	if e.prepareJusqua then
		if maintenant >= e.prepareJusqua then
			-- L'anticipation est finie : l'animation arrive au marqueur « Contact » (0,1 s plus loin).
			e.prepareJusqua = nil
			e.surbrillance.OutlineTransparency = 1
			e.limiteContact = maintenant + LIMITE_FRAPPE
			e.prochaineAttaque = maintenant + M.recharge
			task.delay(0.6, function()
				if e.hum.Parent then
					e.hum.AutoRotate = true
				end
			end)
		end
	elseif etourdi then
		e.hum:Move(Vector3.zero)
	else
		local lent = maintenant < e.ralentiFin
		local court = dist > DISTANCE_COURSE and not lent
		e.hum.WalkSpeed = (court and VITESSE_COURSE or VITESSE_MARCHE) * (lent and 0.5 or 1)
		if dist > portee - 2 then
			if maintenant >= e.prochainChemin then
				e.prochainChemin = maintenant + 0.15
				e.hum:MoveTo(joueur)
			end
		else
			e.hum:Move(Vector3.zero)
			Rigs.regarder(e, joueur)
		end
		if dist <= portee and maintenant >= e.prochaineAttaque and not e.attenteContact then
			-- Alerte : contour rouge pendant l'anticipation (bras armé très haut, tremblement).
			e.prepareJusqua = maintenant + M.preparation
			e.attenteContact = true
			e.limiteContact = math.huge
			e.debutGriffe = maintenant
			e.hum:Move(Vector3.zero)
			e.hum.AutoRotate = false
			Rigs.regarder(e, joueur)
			e.surbrillance.OutlineTransparency = 0
			if e.pistes.coup then
				e.pistes.coup:Play(0.05)
			end
			ctx.envoyer({ type = "alerte", attaque = "golem" })
		end
	end

	locomotion(e, maintenant)
end

function Rodeur.detruire(e, raison)
	if raison ~= "victoire" then
		e.modele:Destroy()
		return
	end
	local recul = -e.racine.CFrame.LookVector * 25 + Vector3.new(0, 30, 0)
	Rigs.mourir(e.modele, e.racine, recul)
end

return Rodeur
