-- Animations : tout l'habillage visuel du combat, côté joueur (rien de décisif ici).
-- - Vraies animations du personnage (coup et fente d'épée R15 officielles de Roblox) + traînée de la lame.
-- - Impacts en couches : éclair, onde de choc, étincelles, particules de l'élément, lumière, arrêt sur image.
-- - Esquive avec images rémanentes, « esquive parfaite » au ralenti visuel.
-- - Attaque spéciale : charge (tourbillon) puis rayon et explosion de l'élément.
-- - Entrée cinématique du boss, passage en phase 2, frappes au sol du boss.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Animations = {}

local joueur = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local rng = Random.new()

local ANIM_COUP = "rbxassetid://522635514" -- R15 coup d'épée (Roblox)
local ANIM_FENTE = "rbxassetid://522638767" -- R15 fente d'épée (Roblox)

local pistes = {}
local compteCoups = 0

-- Correction de couleur dédiée (teinte de phase 2, ralenti, flash).
local correction = Lighting:FindFirstChild("MagicalandCouleur") or Instance.new("ColorCorrectionEffect")
correction.Name = "MagicalandCouleur"
correction.Parent = Lighting
local flou = Lighting:FindFirstChild("MagicalandFlou") or Instance.new("BlurEffect")
flou.Name = "MagicalandFlou"
flou.Size = 0
flou.Parent = Lighting

local function tween(objet, duree, props, style, direction)
	local t = TweenService:Create(objet, TweenInfo.new(duree, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function personnage()
	local perso = joueur.Character
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	local racine = perso and perso:FindFirstChild("HumanoidRootPart")
	return perso, hum, racine
end

-- Charge les animations du personnage (à chaque réapparition).
function Animations.initPerso(perso)
	local hum = perso:WaitForChild("Humanoid", 10)
	local animator = hum and hum:WaitForChild("Animator", 10)
	if not animator then
		return
	end
	pistes = {}
	for cle, id in { coup = ANIM_COUP, fente = ANIM_FENTE } do
		local a = Instance.new("Animation")
		a.AnimationId = id
		local p = animator:LoadAnimation(a)
		p.Priority = Enum.AnimationPriority.Action
		pistes[cle] = p
	end
end

local function trainee(duree)
	local perso = joueur.Character
	local lame = perso and perso:FindFirstChild("LameMagique")
	local t = lame and lame:FindFirstChild("Tranchant") and lame.Tranchant:FindFirstChild("Trainee")
	if t then
		t.Enabled = true
		task.delay(duree, function()
			t.Enabled = false
		end)
	end
end

-- Coup de base : coup d'épée, une fente tous les 3 coups.
function Animations.coup()
	compteCoups += 1
	local p = (compteCoups % 3 == 0) and pistes.fente or pistes.coup
	if p then
		p:Play(0.05)
		p:AdjustSpeed(1.6)
	end
	trainee(0.35)
end

function Animations.sort()
	if pistes.fente then
		pistes.fente:Play(0.05)
		pistes.fente:AdjustSpeed(1.3)
	end
	trainee(0.45)
end

-- Arrêt sur image : le personnage se fige un instant, la caméra « pousse ».
function Animations.hitstop(duree)
	local perso = joueur.Character
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if animator then
		local figees = {}
		for _, p in animator:GetPlayingAnimationTracks() do
			table.insert(figees, { p, p.Speed })
			p:AdjustSpeed(0)
		end
		task.delay(duree, function()
			for _, f in figees do
				f[1]:AdjustSpeed(f[2] == 0 and 1 or f[2])
			end
		end)
	end
	local fov = camera.FieldOfView
	camera.FieldOfView = fov - 4
	tween(camera, 0.18, { FieldOfView = 70 })
end

-- Coup reçu : flash rouge sur le personnage et l'écran.
function Animations.touche()
	local perso = joueur.Character
	if perso then
		local h = Instance.new("Highlight")
		h.FillColor = Color3.fromRGB(255, 60, 60)
		h.FillTransparency = 0.35
		h.OutlineTransparency = 1
		h.Parent = perso
		Debris:AddItem(h, 0.18)
	end
	correction.TintColor = Color3.fromRGB(255, 150, 150)
	tween(correction, 0.35, { TintColor = Animations.teinteFond or Color3.new(1, 1, 1) })
end

-- Victoire : fente finale, ralenti visuel bref, gerbe dorée.
function Animations.victoire()
	local _, hum, racine = personnage()
	if hum then
		hum.Jump = true
	end
	if pistes.fente then
		pistes.fente:Play(0.05)
	end
	flou.Size = 10
	tween(flou, 0.6, { Size = 0 })
	correction.Saturation = -0.4
	tween(correction, 0.8, { Saturation = 0 })
	if racine then
		Animations.impact(racine.Position + Vector3.new(0, 2, 0), Color3.fromRGB(255, 210, 100), true)
	end
end

-- Image rémanente : copie translucide du personnage qui s'efface.
local function imageRemanente(couleur)
	local perso = joueur.Character
	if not perso then
		return
	end
	for _, p in perso:GetChildren() do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" and p.Transparency < 1 then
			local fantome = Instance.new("Part")
			fantome.Size = p.Size
			fantome.CFrame = p.CFrame
			fantome.Anchored = true
			fantome.CanCollide = false
			fantome.CanQuery = false
			fantome.CanTouch = false
			fantome.CastShadow = false
			fantome.Material = Enum.Material.Neon
			fantome.Color = couleur
			fantome.Transparency = 0.45
			fantome.Parent = Workspace
			tween(fantome, 0.35, { Transparency = 1 })
			Debris:AddItem(fantome, 0.4)
		end
	end
end

-- Ruée d'esquive : bond rapide + images rémanentes.
function Animations.esquive(couleur)
	local _, hum, racine = personnage()
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
	lv.PlaneVelocity = Vector2.new(dir.X, dir.Z) * 70
	lv.MaxForce = 1e6
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.Parent = racine
	Debris:AddItem(lv, 0.18)
	Debris:AddItem(att, 0.2)

	local c = couleur or Color3.fromRGB(120, 180, 255)
	task.spawn(function()
		for _ = 1, 3 do
			imageRemanente(c)
			task.wait(0.06)
		end
	end)
	return true
end

-- Esquive parfaite : ralenti visuel (désaturation, flou, zoom), comme un temps suspendu.
function Animations.esquiveParfaite()
	correction.Saturation = -0.7
	correction.Contrast = 0.2
	flou.Size = 6
	camera.FieldOfView = 58
	task.delay(0.45, function()
		tween(correction, 0.4, { Saturation = 0, Contrast = 0 })
		tween(flou, 0.4, { Size = 0 })
		tween(camera, 0.4, { FieldOfView = 70 })
	end)
end

local function partieNeon(taille, couleur, cf, forme, transparence)
	local p = Instance.new("Part")
	p.Size = taille
	p.Color = couleur
	p.Material = Enum.Material.Neon
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = transparence or 0.1
	if forme then
		p.Shape = forme
	end
	p.CFrame = cf
	p.Parent = Workspace
	return p
end

local function particules(parent, props, nombre)
	local att = Instance.new("Attachment")
	att.Parent = parent
	local pe = Instance.new("ParticleEmitter")
	pe.Enabled = false
	pe.LightEmission = 1
	for k, v in props do
		pe[k] = v
	end
	pe.Parent = att
	pe:Emit(nombre)
	return pe
end

-- Particules propres à chaque élément.
local function particulesElement(ancre, element, couleur, grand)
	local n = grand and 40 or 16
	if element == "feu" then
		particules(ancre, {
			Color = ColorSequence.new(Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 70, 20)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0) }),
			Speed = NumberRange.new(8, 20),
			SpreadAngle = Vector2.new(180, 180),
			Lifetime = NumberRange.new(0.4, 0.8),
			Acceleration = Vector3.new(0, 18, 0),
			Drag = 3,
		}, n)
	elseif element == "glace" then
		particules(ancre, {
			Color = ColorSequence.new(Color3.fromRGB(220, 245, 255), Color3.fromRGB(120, 200, 255)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0.1) }),
			Speed = NumberRange.new(14, 26),
			SpreadAngle = Vector2.new(180, 180),
			Lifetime = NumberRange.new(0.3, 0.6),
			Acceleration = Vector3.new(0, -40, 0),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-300, 300),
		}, n)
	elseif element == "foudre" then
		particules(ancre, {
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 200), Color3.fromRGB(255, 220, 60)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) }),
			Speed = NumberRange.new(30, 50),
			SpreadAngle = Vector2.new(180, 180),
			Lifetime = NumberRange.new(0.1, 0.25),
		}, n * 2)
	elseif element == "lumiere" then
		particules(ancre, {
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 230), Color3.fromRGB(255, 220, 140)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) }),
			Speed = NumberRange.new(4, 10),
			SpreadAngle = Vector2.new(180, 180),
			Lifetime = NumberRange.new(0.6, 1),
			Acceleration = Vector3.new(0, 10, 0),
		}, n)
	elseif element == "ombre" then
		particules(ancre, {
			Color = ColorSequence.new(Color3.fromRGB(120, 60, 180), Color3.fromRGB(20, 10, 30)),
			LightEmission = 0,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 3.5) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }),
			Speed = NumberRange.new(4, 10),
			SpreadAngle = Vector2.new(180, 180),
			Lifetime = NumberRange.new(0.5, 0.9),
		}, n)
	end
end

-- Éclair zigzag du ciel jusqu'au point (foudre).
local function eclair(position, couleur)
	local haut = position + Vector3.new(rng:NextNumber(-4, 4), 40, rng:NextNumber(-4, 4))
	local precedent = haut
	for i = 1, 8 do
		local t = i / 8
		local point = haut:Lerp(position, t) + (i < 8 and Vector3.new(rng:NextNumber(-2.5, 2.5), 0, rng:NextNumber(-2.5, 2.5)) or Vector3.zero)
		local longueur = (point - precedent).Magnitude
		local seg = partieNeon(Vector3.new(0.35, 0.35, longueur), couleur, CFrame.lookAt((point + precedent) / 2, point), nil, 0)
		tween(seg, 0.25, { Transparency = 1 })
		Debris:AddItem(seg, 0.3)
		precedent = point
	end
end

-- Impact en couches : éclair blanc, boule, onde de choc au sol, étincelles, particules de l'élément, lumière.
function Animations.impact(position, couleur, grand, element)
	local echelle = grand and 1.8 or 1
	local coeur = partieNeon(Vector3.new(1, 1, 1), Color3.new(1, 1, 1), CFrame.new(position), Enum.PartType.Ball, 0)
	tween(coeur, 0.12, { Size = Vector3.new(3, 3, 3) * echelle, Transparency = 1 })
	local boule = partieNeon(Vector3.new(1, 1, 1), couleur, CFrame.new(position), Enum.PartType.Ball, 0.15)
	tween(boule, 0.35, { Size = Vector3.new(7, 7, 7) * echelle, Transparency = 1 })

	local onde = partieNeon(Vector3.new(0.2, 2, 2), couleur, CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, 0.2)
	tween(onde, 0.4, { Size = Vector3.new(0.2, 14, 14) * Vector3.new(1, echelle, echelle), Transparency = 1 })

	local lumiere = Instance.new("PointLight")
	lumiere.Color = couleur
	lumiere.Range = 18 * echelle
	lumiere.Brightness = 6
	lumiere.Parent = boule
	tween(lumiere, 0.35, { Brightness = 0 })

	particules(boule, {
		Color = ColorSequence.new(Color3.new(1, 1, 1), couleur),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0) }),
		Speed = NumberRange.new(20, 40),
		SpreadAngle = Vector2.new(180, 180),
		Lifetime = NumberRange.new(0.2, 0.45),
		Drag = 5,
	}, grand and 40 or 18)
	if element then
		particulesElement(boule, element, couleur, grand)
		if element == "foudre" then
			eclair(position, couleur)
		end
	end

	Debris:AddItem(coeur, 0.2)
	Debris:AddItem(boule, 1.2)
	Debris:AddItem(onde, 0.45)
end

-- Charge de l'attaque spéciale : tourbillon autour du joueur, lumière qui monte.
function Animations.charge(couleur, duree)
	local _, _, racine = personnage()
	if not racine then
		return function() end
	end
	local att = Instance.new("Attachment")
	att.Parent = racine
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.new(1, 1, 1), couleur)
	pe.LightEmission = 1
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	pe.Rate = 120
	pe.Speed = NumberRange.new(-12, -8) -- vers le centre
	pe.Lifetime = NumberRange.new(0.3, 0.5)
	pe.Shape = Enum.ParticleEmitterShape.Sphere
	pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	pe.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	pe.Parent = att
	pe.Rate = 120
	local lumiere = Instance.new("PointLight")
	lumiere.Color = couleur
	lumiere.Range = 4
	lumiere.Brightness = 1
	lumiere.Parent = att
	tween(lumiere, duree, { Range = 22, Brightness = 5 })
	local anneau = partieNeon(Vector3.new(0.2, 9, 9), couleur, CFrame.new(racine.Position - Vector3.new(0, 2.8, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, 0.6)
	tween(anneau, duree, { Size = Vector3.new(0.2, 3, 3), Transparency = 0.1 })
	camera.FieldOfView = 70
	tween(camera, duree, { FieldOfView = 62 })
	return function()
		pe.Enabled = false
		Debris:AddItem(att, 0.6)
		anneau:Destroy()
		tween(camera, 0.25, { FieldOfView = 70 })
	end
end

-- Déchaînement : rayon de la lame jusqu'à l'ennemi puis énorme impact.
function Animations.special(cible, couleur, element)
	local _, _, racine = personnage()
	Animations.sort()
	if racine then
		local depart = racine.Position + Vector3.new(0, 1.5, 0)
		local longueur = (cible - depart).Magnitude
		local rayon = partieNeon(Vector3.new(2.2, 2.2, longueur), couleur, CFrame.lookAt((depart + cible) / 2, cible), nil, 0)
		local coeur = partieNeon(Vector3.new(0.8, 0.8, longueur), Color3.new(1, 1, 1), rayon.CFrame, nil, 0)
		tween(rayon, 0.35, { Size = Vector3.new(0.1, 0.1, longueur), Transparency = 1 })
		tween(coeur, 0.3, { Transparency = 1 })
		Debris:AddItem(rayon, 0.4)
		Debris:AddItem(coeur, 0.4)
	end
	Animations.impact(cible, couleur, true, element)
	task.delay(0.08, function()
		Animations.impact(cible + Vector3.new(rng:NextNumber(-2, 2), 2, rng:NextNumber(-2, 2)), couleur, true, element)
	end)
	correction.Brightness = 0.35
	tween(correction, 0.4, { Brightness = 0 })
	flou.Size = 8
	tween(flou, 0.35, { Size = 0 })
end

-- Frappe au sol du boss : colonnes de poussière et éclats là où étaient les zones.
function Animations.frappeSol(centres)
	for _, c in centres or {} do
		local colonne = partieNeon(Vector3.new(0.3, 6, 6), Color3.fromRGB(255, 190, 110), CFrame.new(c) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, 0.2)
		tween(colonne, 0.45, { Size = Vector3.new(0.3, 18, 18), Transparency = 1 })
		Debris:AddItem(colonne, 0.5)
		particules(colonne, {
			Color = ColorSequence.new(Color3.fromRGB(140, 110, 80)),
			LightEmission = 0,
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 3) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }),
			Speed = NumberRange.new(10, 25),
			SpreadAngle = Vector2.new(60, 60),
			EmissionDirection = Enum.NormalId.Top,
			Lifetime = NumberRange.new(0.5, 1),
			Acceleration = Vector3.new(0, -30, 0),
		}, 25)
	end
end

-- Bandes noires de cinéma + grand titre.
local function bandesCinema(titre, sousTitre, duree)
	local gui = joueur.PlayerGui:FindFirstChild("MagicalandCinema")
	if gui then
		gui:Destroy()
	end
	gui = Instance.new("ScreenGui")
	gui.Name = "MagicalandCinema"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 10
	gui.Parent = joueur.PlayerGui
	local haut = Instance.new("Frame")
	haut.BackgroundColor3 = Color3.new(0, 0, 0)
	haut.BorderSizePixel = 0
	haut.Size = UDim2.new(1, 0, 0, 0)
	haut.Parent = gui
	local bas = haut:Clone()
	bas.AnchorPoint = Vector2.new(0, 1)
	bas.Position = UDim2.fromScale(0, 1)
	bas.Parent = gui
	tween(haut, 0.4, { Size = UDim2.new(1, 0, 0.12, 0) })
	tween(bas, 0.4, { Size = UDim2.new(1, 0, 0.12, 0) })
	local texte = Instance.new("TextLabel")
	texte.BackgroundTransparency = 1
	texte.AnchorPoint = Vector2.new(0.5, 0.5)
	texte.Position = UDim2.fromScale(0.5, 0.7)
	texte.Size = UDim2.new(0.9, 0, 0, 70)
	texte.Font = Enum.Font.GothamBlack
	texte.TextScaled = true
	texte.TextColor3 = Color3.fromRGB(255, 200, 110)
	texte.TextStrokeTransparency = 0.2
	texte.Text = titre
	texte.TextTransparency = 1
	texte.Parent = gui
	local sous = texte:Clone()
	sous.Position = UDim2.fromScale(0.5, 0.78)
	sous.Size = UDim2.new(0.9, 0, 0, 30)
	sous.TextColor3 = Color3.fromRGB(230, 220, 250)
	sous.Text = sousTitre
	sous.Parent = gui
	task.delay(0.6, function()
		tween(texte, 0.4, { TextTransparency = 0 })
		tween(sous, 0.4, { TextTransparency = 0 })
	end)
	task.delay(duree - 0.4, function()
		tween(haut, 0.4, { Size = UDim2.new(1, 0, 0, 0) })
		tween(bas, 0.4, { Size = UDim2.new(1, 0, 0, 0) })
		tween(texte, 0.3, { TextTransparency = 1 })
		tween(sous, 0.3, { TextTransparency = 1 })
		Debris:AddItem(gui, 0.5)
	end)
end

-- Entrée du boss : la caméra part du joueur, tourne autour du colosse et finit face à lui.
function Animations.intro(modele, duree, nom)
	duree = duree or 3.5
	local tete = modele and modele:FindFirstChild("Head")
	local _, _, racine = personnage()
	if not (tete and racine) then
		return
	end
	bandesCinema(string.upper(nom or "Boss"), "Boss de la semaine", duree)
	camera.CameraType = Enum.CameraType.Scriptable
	local cible = tete.Position
	local depuis = racine.Position + Vector3.new(0, 6, 0) - (cible - racine.Position).Unit * 8
	camera.CFrame = CFrame.lookAt(depuis, cible)
	local valeur = Instance.new("NumberValue")
	local face = (racine.Position - cible) * Vector3.new(1, 0, 1)
	face = face.Magnitude > 0.1 and face.Unit or Vector3.new(0, 0, 1)
	valeur.Changed:Connect(function(t)
		if not tete.Parent then
			return
		end
		local c = tete.Position
		local angle = (1 - t) * math.rad(70)
		local dir = CFrame.Angles(0, angle, 0):VectorToWorldSpace(face)
		local position = c + dir * (14 + 10 * (1 - t)) + Vector3.new(0, -6 + 8 * (1 - t), 0)
		camera.CFrame = CFrame.lookAt(depuis:Lerp(position, math.min(1, t * 3)), c)
	end)
	tween(valeur, duree - 0.6, { Value = 1 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	task.delay(duree - 0.6, function()
		valeur:Destroy()
		camera.CameraType = Enum.CameraType.Custom
	end)
end

-- Phase 2 : flash orange, teinte de braise, titre.
function Animations.phase2(position)
	Animations.teinteFond = Color3.fromRGB(255, 225, 200)
	correction.TintColor = Color3.fromRGB(255, 170, 110)
	correction.Brightness = 0.3
	tween(correction, 1.2, { TintColor = Animations.teinteFond, Brightness = 0 })
	flou.Size = 12
	tween(flou, 0.8, { Size = 0 })
	if position then
		Animations.impact(position + Vector3.new(0, 8, 0), Color3.fromRGB(255, 120, 40), true, "feu")
	end
	bandesCinema("PHASE 2", "Le Colosse s'embrase !", 2.2)
end

-- Fin de combat : on remet l'image normale.
function Animations.finCombat()
	Animations.teinteFond = nil
	tween(correction, 0.8, { TintColor = Color3.new(1, 1, 1), Saturation = 0, Contrast = 0, Brightness = 0 })
	flou.Size = 0
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
end

return Animations
