-- Rigs : fabrique de monstres riggés R15 (vrai squelette articulé), animés par l'Animator
-- avec les animations officielles de Roblox (créateur « Roblox », libres pour tous les jeux).
-- Le décor (pierres, mousse, ronces, lanternes) est soudé aux membres : il suit les animations.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local Rigs = {}

-- Animations R15 officielles de Roblox (vérifiées : créateur Roblox).
Rigs.ANIMS = {
	idle = "rbxassetid://507766388", -- R15Idle
	marche = "rbxassetid://507777826", -- Marche R15
	course = "rbxassetid://507767714", -- Course R15
	coup = "rbxassetid://522635514", -- R15 coup d'épée
	fente = "rbxassetid://522638767", -- R15 fente d'épée
}

-- Crée un rig R15 aux couleurs données. decorer(m) ajoute le décor avant la mise à l'échelle.
function Rigs.creer(nom, style, echelle, position, decorer)
	local d = Instance.new("HumanoidDescription")
	d.HeadColor = style.tete
	d.TorsoColor = style.corps
	d.LeftArmColor = style.bras
	d.RightArmColor = style.bras
	d.LeftLegColor = style.jambes
	d.RightLegColor = style.jambes
	d.WidthScale = style.largeur or 1.3
	d.DepthScale = style.profondeur or 1.2
	d.HeadScale = style.teteEchelle or 1.1
	d.BodyTypeScale = 0
	d.ProportionScale = 0

	local m = Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R15)
	m.Name = nom
	local animate = m:FindFirstChild("Animate")
	if animate then
		animate:Destroy() -- on joue nous-mêmes les animations
	end
	local hum = m:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.BreakJointsOnDeath = false
	hum.MaxHealth = 1e6
	hum.Health = 1e6 -- la vraie vie est gérée par Combat
	for _, etat in { Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.Dead, Enum.HumanoidStateType.Climbing } do
		hum:SetStateEnabled(etat, false)
	end
	local visage = m.Head:FindFirstChild("face")
	if visage then
		visage:Destroy()
	end

	if decorer then
		decorer(m)
	end
	if echelle ~= 1 then
		m:ScaleTo(echelle)
	end
	local racine = m:FindFirstChild("HumanoidRootPart")
	m:PivotTo(CFrame.new(position + Vector3.new(0, hum.HipHeight + racine.Size.Y / 2 + 0.1, 0)))
	m.ModelStreamingMode = Enum.ModelStreamingMode.Persistent -- toujours envoyé aux joueurs
	m.Parent = Workspace
	pcall(function()
		racine:SetNetworkOwner(nil) -- le serveur pilote le monstre
	end)

	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local pistes = {}
	for cle, id in Rigs.ANIMS do
		local a = Instance.new("Animation")
		a.AnimationId = id
		pistes[cle] = animator:LoadAnimation(a)
	end
	pistes.idle.Looped = true
	pistes.marche.Looped = true
	pistes.course.Looped = true
	pistes.coup.Priority = Enum.AnimationPriority.Action
	pistes.fente.Priority = Enum.AnimationPriority.Action
	pistes.idle:Play()

	-- Surbrillance : flash blanc à l'impact (remplissage) et contour d'alerte.
	local surbrillance = Instance.new("Highlight")
	surbrillance.FillColor = Color3.new(1, 1, 1)
	surbrillance.FillTransparency = 1
	surbrillance.OutlineColor = Color3.fromRGB(255, 60, 40)
	surbrillance.OutlineTransparency = 1
	surbrillance.DepthMode = Enum.HighlightDepthMode.Occluded
	surbrillance.Parent = m

	return m, hum, racine, pistes, surbrillance
end

-- Soude une pièce de décor à un membre du rig (décalage en coordonnées du membre).
function Rigs.accrocher(m, membre, taille, couleur, materiau, decalage, forme)
	local base = m:FindFirstChild(membre)
	local p = Instance.new("Part")
	p.Name = "Deco"
	p.Size = taille
	p.Color = couleur
	p.Material = materiau
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Anchored = false
	if forme then
		p.Shape = forme
	end
	p.CFrame = base.CFrame * decalage
	local soudure = Instance.new("WeldConstraint")
	soudure.Part0 = base
	soudure.Part1 = p
	soudure.Parent = p
	p.Parent = m
	return p
end

-- Marche ou attente selon la vitesse réelle du monstre.
function Rigs.majLocomotion(e)
	local v = (e.racine.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
	local p = e.pistes
	if v > 1.5 then
		if not p.marche.IsPlaying then
			p.idle:Stop(0.2)
			p.marche:Play(0.2)
		end
		p.marche:AdjustSpeed(math.clamp(v / (12 * e.echelle ^ 0.5), 0.6, 2))
	elseif p.marche.IsPlaying then
		p.marche:Stop(0.25)
		p.idle:Play(0.25)
	end
end

-- Se tourne vers une cible (sans pencher).
function Rigs.regarder(e, cible)
	local pos = e.racine.Position
	local plat = Vector3.new(cible.X, pos.Y, cible.Z)
	if (plat - pos).Magnitude > 0.1 then
		e.racine.CFrame = CFrame.lookAt(pos, plat)
	end
end

-- Mort : le rig s'effondre (articulations remplacées par des rotules), puis s'efface.
function Rigs.mourir(m, racine, impulsion)
	for _, piste in m:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator"):GetPlayingAnimationTracks() do
		piste:Stop(0)
	end
	local hum = m:FindFirstChildOfClass("Humanoid")
	hum.PlatformStand = true
	for _, moteur in m:GetDescendants() do
		if moteur:IsA("Motor6D") then
			local a0 = Instance.new("Attachment")
			a0.CFrame = moteur.C0
			a0.Parent = moteur.Part0
			local a1 = Instance.new("Attachment")
			a1.CFrame = moteur.C1
			a1.Parent = moteur.Part1
			local rotule = Instance.new("BallSocketConstraint")
			rotule.Attachment0 = a0
			rotule.Attachment1 = a1
			rotule.LimitsEnabled = true
			rotule.UpperAngle = 60
			rotule.Parent = moteur.Part1
			moteur:Destroy()
		end
	end
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" and p.Name ~= "Deco" then
			p.CanCollide = true
		end
	end
	if impulsion then
		racine:ApplyImpulse(impulsion * racine.AssemblyMass)
	end
	task.delay(2.2, function()
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				TweenService:Create(p, TweenInfo.new(1.2), { Transparency = 1 }):Play()
			end
		end
	end)
	Debris:AddItem(m, 3.6)
end

return Rigs
