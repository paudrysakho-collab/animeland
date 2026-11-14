-- Animations : mouvements du personnage faits par le code (gratuits, aucun fichier d'animation à importer).
-- On tourne les articulations (Motor6D.C0) avec des tweens courts, par-dessus les animations de marche.
-- Aussi : effets d'impact (VFX) et la ruée d'esquive. Tout est local au joueur (habillage).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local Animations = {}

local joueur = Players.LocalPlayer
local origines = {} -- [Motor6D] = C0 d'origine
local jetons = {} -- [nom d'articulation] = numéro de la dernière pose (évite les retours en arrière mélangés)

local ARTICULATIONS = {
	epauleD = { "RightUpperArm", "RightShoulder" },
	epauleG = { "LeftUpperArm", "LeftShoulder" },
	taille = { "UpperTorso", "Waist" },
}

local function moteur(nom)
	local perso = joueur.Character
	local chemin = ARTICULATIONS[nom]
	local partie = perso and perso:FindFirstChild(chemin[1])
	local m = partie and partie:FindFirstChild(chemin[2])
	if m and m:IsA("Motor6D") then
		if not origines[m] then
			origines[m] = m.C0
		end
		return m
	end
	return nil -- avatar R6 ou personnage absent : pas d'animation, sans erreur
end

local function pose(nom, rotation, duree, style)
	local m = moteur(nom)
	if not m then
		return
	end
	jetons[nom] = (jetons[nom] or 0) + 1
	TweenService:Create(m, TweenInfo.new(duree, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		C0 = origines[m] * rotation,
	}):Play()
	return jetons[nom]
end

local function repos(nom, duree, jeton)
	if jeton and jetons[nom] ~= jeton then
		return -- une autre pose a pris la main entre-temps
	end
	pose(nom, CFrame.new(), duree or 0.2)
end

local R = CFrame.Angles
local rad = math.rad

-- Coup de base : le bras droit monte puis tranche, le buste tourne.
function Animations.coup()
	task.spawn(function()
		pose("epauleD", R(rad(130), 0, rad(-15)), 0.07)
		task.wait(0.07)
		local j1 = pose("epauleD", R(rad(-35), 0, rad(25)), 0.1, Enum.EasingStyle.Back)
		local j2 = pose("taille", R(0, rad(-25), 0), 0.1)
		task.wait(0.16)
		repos("epauleD", 0.18, j1)
		repos("taille", 0.18, j2)
	end)
end

-- Sort d'élément (coup critique) : les deux bras tendus vers l'avant.
function Animations.sort()
	task.spawn(function()
		local j1 = pose("epauleD", R(rad(90), 0, rad(-10)), 0.1)
		local j2 = pose("epauleG", R(rad(90), 0, rad(10)), 0.1)
		local j3 = pose("taille", R(rad(-8), 0, 0), 0.1)
		task.wait(0.3)
		repos("epauleD", 0.2, j1)
		repos("epauleG", 0.2, j2)
		repos("taille", 0.2, j3)
	end)
end

-- Coup reçu : le buste part en arrière, flash rouge.
function Animations.touche()
	local perso = joueur.Character
	if perso then
		local h = Instance.new("Highlight")
		h.FillColor = Color3.fromRGB(255, 60, 60)
		h.FillTransparency = 0.45
		h.OutlineTransparency = 1
		h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.Parent = perso
		Debris:AddItem(h, 0.15)
	end
	task.spawn(function()
		local j = pose("taille", R(rad(-20), 0, 0), 0.06)
		task.wait(0.1)
		repos("taille", 0.25, j)
	end)
end

-- Victoire : bras levés et petit saut.
function Animations.victoire()
	local perso = joueur.Character
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Jump = true
	end
	task.spawn(function()
		local j1 = pose("epauleD", R(rad(165), 0, rad(-15)), 0.25, Enum.EasingStyle.Back)
		local j2 = pose("epauleG", R(rad(165), 0, rad(15)), 0.25, Enum.EasingStyle.Back)
		task.wait(1.3)
		repos("epauleD", 0.4, j1)
		repos("epauleG", 0.4, j2)
	end)
end

-- Ruée d'esquive : bond rapide dans la direction de marche (ou en arrière si immobile).
-- Le personnage appartient physiquement au joueur, donc le serveur voit le déplacement.
function Animations.esquive()
	local perso = joueur.Character
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	local racine = perso and perso:FindFirstChild("HumanoidRootPart")
	if not (hum and racine) or hum.Health <= 0 then
		return false
	end
	local dir = hum.MoveDirection
	if dir.Magnitude < 0.1 then
		dir = -racine.CFrame.LookVector
	end
	dir = Vector3.new(dir.X, 0, dir.Z).Unit

	local att = Instance.new("Attachment")
	att.Parent = racine
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	lv.PrimaryTangentAxis = Vector3.new(1, 0, 0)
	lv.SecondaryTangentAxis = Vector3.new(0, 0, 1)
	lv.PlaneVelocity = Vector2.new(dir.X, dir.Z) * 65
	lv.MaxForce = 1e6
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.Parent = racine
	Debris:AddItem(lv, 0.18)
	Debris:AddItem(att, 0.2)

	task.spawn(function()
		local j = pose("taille", R(rad(18), 0, 0), 0.06)
		task.wait(0.18)
		repos("taille", 0.2, j)
	end)
	return true
end

-- Impact : boule lumineuse de la couleur de l'élément + étincelles, à l'endroit touché.
function Animations.impact(position, couleur, grand)
	local boule = Instance.new("Part")
	boule.Shape = Enum.PartType.Ball
	boule.Material = Enum.Material.Neon
	boule.Color = couleur
	boule.Anchored = true
	boule.CanCollide = false
	boule.CanQuery = false
	boule.CanTouch = false
	boule.CastShadow = false
	boule.Size = Vector3.new(1, 1, 1)
	boule.Transparency = 0.15
	boule.CFrame = CFrame.new(position)
	boule.Parent = Workspace

	local taille = grand and 9 or 5
	TweenService:Create(boule, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(taille, taille, taille),
		Transparency = 1,
	}):Play()

	local att = Instance.new("Attachment")
	att.Parent = boule
	local etincelles = Instance.new("ParticleEmitter")
	etincelles.Color = ColorSequence.new(couleur)
	etincelles.LightEmission = 1
	etincelles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	etincelles.Speed = NumberRange.new(12, 22)
	etincelles.SpreadAngle = Vector2.new(180, 180)
	etincelles.Lifetime = NumberRange.new(0.25, 0.45)
	etincelles.Drag = 4
	etincelles.Enabled = false
	etincelles.Parent = att
	etincelles:Emit(grand and 30 or 14)

	Debris:AddItem(boule, 0.6)
end

return Animations
