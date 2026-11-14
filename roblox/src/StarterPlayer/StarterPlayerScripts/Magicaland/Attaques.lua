-- Attaques : habillage visuel des 5 attaques spéciales et de la transformation (côté joueur, rien de décisif).
-- Chaque attaque a sa forme propre, colorée et « signée » par l'élément du joueur :
--   1 Frappe d'arcane : croissant géant tranché devant soi.
--   2 Lance : projectile de l'élément qui file jusqu'à l'ennemi et explose.
--   3 Colonnes : six colonnes de l'élément jaillissent du sol autour de l'ennemi.
--   4 Nova : sphère et anneaux qui s'étendent depuis le joueur (zone).
--   5 Éveil : cinématique, ciel qui s'assombrit, pilier colossal tombé du ciel.
-- Transformation : cinématique de caméra, colonne d'énergie, image teintée pendant 20 s.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local Animations = require(script.Parent:WaitForChild("Animations"))
local O = Animations.outils
local tween = O.tween
local neon = O.partieNeon
local particules = O.particules
local correction = O.correction
local flou = O.flou

local Attaques = {}

local joueur = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local rng = Random.new()
local BLANC = Color3.new(1, 1, 1)
local RunService = game:GetService("RunService")
local ultimeTransforme = false -- l'Ultime en cours a-t-il été lancé transformé ?

local function racine()
	local _, _, r = O.personnage()
	return r
end

-- Secousse de caméra (décalage de l'humanoïde).
local function secousse(force, duree)
	local _, hum = O.personnage()
	if not hum then
		return
	end
	task.spawn(function()
		local fin = os.clock() + (duree or 0.25)
		while os.clock() < fin do
			local k = (fin - os.clock()) / (duree or 0.25)
			hum.CameraOffset = Vector3.new((rng:NextNumber() - 0.5) * force * k, (rng:NextNumber() - 0.5) * force * k, 0)
			task.wait(0.025)
		end
		hum.CameraOffset = Vector3.zero
	end)
end
Attaques.secousse = secousse

local function flash(luminosite, duree, teinte)
	correction.Brightness = luminosite
	if teinte then
		correction.TintColor = teinte
	end
	tween(correction, duree, { Brightness = 0, TintColor = Animations.teinteFond or BLANC })
end

local function fovCoup(delta, retour)
	camera.FieldOfView = 70 + delta
	tween(camera, retour or 0.35, { FieldOfView = Animations.fovBase or 70 })
end

-- Onde au sol (anneau plat qui s'élargit).
local function onde(position, couleur, taille, duree, epaisseur)
	local p = neon(Vector3.new(epaisseur or 0.3, 2, 2), couleur, CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, 0.15)
	tween(p, duree, { Size = Vector3.new(epaisseur or 0.3, taille, taille), Transparency = 1 })
	Debris:AddItem(p, duree + 0.05)
	return p
end

-- Boule qui grossit et s'efface.
local function boule(position, couleur, taille, duree, transparence)
	local p = neon(Vector3.new(1, 1, 1), couleur, CFrame.new(position), Enum.PartType.Ball, transparence or 0.1)
	tween(p, duree, { Size = Vector3.one * taille, Transparency = 1 })
	Debris:AddItem(p, duree + 0.05)
	return p
end

local function lumiere(parent, couleur, portee, eclat, duree)
	local l = Instance.new("PointLight")
	l.Color = couleur
	l.Range = portee
	l.Brightness = eclat
	l.Parent = parent
	tween(l, duree, { Brightness = 0 })
	return l
end

-- Pointe (glace, ombre) : un bloc fin et pointu qui sort du sol.
local function pointe(position, couleur, hauteur, materiau, inclinaison)
	local cf = CFrame.new(position) * CFrame.Angles(rng:NextNumber(-inclinaison, inclinaison), rng:NextNumber(0, 6.28), rng:NextNumber(-inclinaison, inclinaison))
	local p = neon(Vector3.new(1.4, 0.2, 1.4), couleur, cf, nil, 0.05)
	p.Material = materiau or Enum.Material.Neon
	p.Size = Vector3.new(1.6, 0.2, 1.6)
	tween(p, 0.12, { Size = Vector3.new(1.6, hauteur, 1.6), CFrame = cf * CFrame.new(0, hauteur / 2, 0) }, Enum.EasingStyle.Back)
	task.delay(0.7, function()
		tween(p, 0.4, { Transparency = 1, Size = Vector3.new(0.2, hauteur, 0.2) })
	end)
	Debris:AddItem(p, 1.2)
	return p
end

-- Signature de l'élément à un point : ajoute la touche propre à chaque élément.
local function signature(position, element, couleur, echelle)
	echelle = echelle or 1
	if element == "feu" then
		local p = boule(position, Color3.fromRGB(255, 200, 80), 10 * echelle, 0.5)
		particules(p, {
			Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 60, 10)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5 * echelle), NumberSequenceKeypoint.new(1, 0) }),
			Speed = NumberRange.new(10, 30),
			SpreadAngle = Vector2.new(180, 180),
			Lifetime = NumberRange.new(0.5, 1),
			Acceleration = Vector3.new(0, 25, 0),
			Drag = 2,
		}, math.floor(50 * echelle))
	elseif element == "glace" then
		for _ = 1, math.floor(6 * echelle) do
			local d = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)) * 4 * echelle
			pointe(position + d - Vector3.new(0, 2, 0), Color3.fromRGB(190, 235, 255), rng:NextNumber(4, 8) * echelle, Enum.Material.Glass, 0.5)
		end
	elseif element == "foudre" then
		for _ = 1, math.max(1, math.floor(3 * echelle)) do
			O.eclair(position + Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3)) * echelle, couleur)
		end
	elseif element == "lumiere" then
		local rayon = neon(Vector3.new(60, 5 * echelle, 5 * echelle), Color3.fromRGB(255, 250, 220), CFrame.new(position + Vector3.new(0, 28, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, 0.1)
		tween(rayon, 0.5, { Size = Vector3.new(60, 0.2, 0.2), Transparency = 1 })
		Debris:AddItem(rayon, 0.55)
	elseif element == "ombre" then
		local p = boule(position, Color3.fromRGB(25, 10, 40), 12 * echelle, 0.6, 0)
		p.Material = Enum.Material.SmoothPlastic
		onde(position, Color3.fromRGB(170, 110, 230), 20 * echelle, 0.5)
	end
end

---------------------------------------------------------------------
-- Charges (avant que le coup parte)
---------------------------------------------------------------------

-- Bandes de cinéma + titre de l'Éveil, caméra qui tourne de près autour du joueur.
local function cameraAutour(duree, distance, hauteur, tours)
	local r = racine()
	if not r then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local debut = os.clock()
	local face = r.CFrame.LookVector
	task.spawn(function()
		while os.clock() - debut < duree and r.Parent do
			local t = (os.clock() - debut) / duree
			local angle = math.rad(-40 + 100 * tours * t)
			local dir = CFrame.Angles(0, angle, 0):VectorToWorldSpace(face)
			local centre = r.Position + Vector3.new(0, 1.5, 0)
			camera.CFrame = CFrame.lookAt(centre + dir * (distance + 4 * t) + Vector3.new(0, hauteur - 1.5 * t, 0), centre)
			task.wait()
		end
		camera.CameraType = Enum.CameraType.Custom
	end)
end

-- Lignes de vitesse façon anime, qui partent du centre de l'écran.
local function lignesVitesse(duree, couleur)
	local gui = Instance.new("ScreenGui")
	gui.Name = "MagicalandLignes"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 9
	gui.Parent = joueur.PlayerGui
	local lignes = {}
	for i = 1, 36 do
		local f = Instance.new("Frame")
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.BorderSizePixel = 0
		f.BackgroundColor3 = i % 3 == 0 and couleur or BLANC
		f.Parent = gui
		lignes[i] = f
	end
	local fin = os.clock() + duree
	local connexion
	connexion = RunService.RenderStepped:Connect(function()
		if os.clock() > fin or not gui.Parent then
			connexion:Disconnect()
			gui:Destroy()
			return
		end
		local ecran = camera.ViewportSize
		for _, f in lignes do
			local a = rng:NextNumber(0, math.pi * 2)
			local d = rng:NextNumber(0.3, 0.45) * ecran.Magnitude
			local longueur = rng:NextNumber(0.2, 0.4) * ecran.Magnitude
			f.Position = UDim2.new(0.5, math.cos(a) * d, 0.5, math.sin(a) * d)
			f.Size = UDim2.fromOffset(longueur, rng:NextInteger(2, 5))
			f.Rotation = math.deg(a)
			f.BackgroundTransparency = rng:NextNumber(0.1, 0.6)
		end
	end)
	return gui
end

-- Images d'impact : noir et blanc très contrasté pendant quelques images.
local function imageImpact(fois)
	task.spawn(function()
		for _ = 1, fois or 2 do
			correction.Saturation = -1
			correction.Contrast = 2
			correction.Brightness = 0.35
			task.wait(0.05)
			correction.Brightness = -0.6
			task.wait(0.04)
		end
		tween(correction, 0.25, { Saturation = 0, Contrast = 0, Brightness = 0 })
	end)
end

-- Gros texte qui claque à l'écran.
local function texteAnime(texte, couleur, duree)
	local gui = Instance.new("ScreenGui")
	gui.Name = "MagicalandCri"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 11
	gui.Parent = joueur.PlayerGui
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, 0.42)
	l.Size = UDim2.fromScale(0.9, 0.22)
	l.Font = Enum.Font.GothamBlack
	l.TextScaled = true
	l.Text = texte
	l.TextColor3 = Color3.fromRGB(255, 245, 220)
	l.Rotation = -6
	l.Parent = gui
	local contour = Instance.new("UIStroke")
	contour.Color = couleur
	contour.Thickness = 5
	contour.Parent = l
	local echelle = Instance.new("UIScale")
	echelle.Scale = 2.4
	echelle.Parent = l
	tween(echelle, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(duree, function()
		tween(l, 0.25, { TextTransparency = 1 })
		tween(contour, 0.25, { Transparency = 1 })
	end)
	Debris:AddItem(gui, duree + 0.3)
end

-- Cinématique anime de l'Ultime transformé : 3 plans (gros plan des yeux, contre-plongée, épaule).
local function cinematiqueAnime(duree, couleur, boulefeu)
	local perso, _, r = O.personnage()
	local tete = perso and perso:FindFirstChild("Head")
	if not (r and tete) then
		return
	end
	O.bandesCinema("ULTIME", "Boule suprême", duree + 0.8)
	lignesVitesse(duree, couleur)
	camera.CameraType = Enum.CameraType.Scriptable
	local debut = os.clock()
	local etape = 0
	task.spawn(function()
		while os.clock() - debut < duree and r.Parent do
			local t = (os.clock() - debut) / duree
			local face = r.CFrame.LookVector
			if t < 0.35 then
				-- Plan 1 : très gros plan sur le visage (yeux rouges), zoom brutal.
				if etape == 0 then
					etape = 1
					camera.FieldOfView = 55
					tween(camera, duree * 0.3, { FieldOfView = 22 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
				end
				local c = tete.Position
				camera.CFrame = CFrame.lookAt(c + face * 4 + Vector3.new(rng:NextNumber(-0.05, 0.05), 0.2, 0), c)
			elseif t < 0.7 then
				-- Plan 2 : contre-plongée, la boule grossit au-dessus du joueur.
				if etape == 1 then
					etape = 2
					imageImpact(2)
					texteAnime("ULTIME !", couleur, 1)
					camera.FieldOfView = 85
					tween(camera, duree * 0.35, { FieldOfView = 70 })
					secousse(1, 0.3)
				end
				local k = (t - 0.35) / 0.35
				local base = r.Position + face * 6 + r.CFrame.RightVector * (3 - 6 * k) - Vector3.new(0, 2.2, 0)
				local haut = (boulefeu and boulefeu.Parent) and boulefeu.Position or (r.Position + Vector3.new(0, 8, 0))
				camera.CFrame = CFrame.lookAt(base, (r.Position + haut) / 2)
			else
				-- Plan 3 : par-dessus l'épaule, vers l'ennemi.
				if etape == 2 then
					etape = 3
					imageImpact(1)
					camera.FieldOfView = 50
					tween(camera, duree * 0.3, { FieldOfView = 62 })
				end
				camera.CFrame = CFrame.lookAt(r.Position - face * 9 + r.CFrame.RightVector * 3 + Vector3.new(0, 4, 0), r.Position + face * 20 + Vector3.new(0, 4, 0))
			end
			task.wait()
		end
	end)
end

-- Lance la charge visuelle de l'attaque index. Renvoie une fonction qui l'arrête.
function Attaques.charge(index, couleur, element, duree, nomElement, transforme)
	local r = racine()
	if not r then
		return function() end
	end
	local nettoyer = {}
	local stopCharge = Animations.charge(couleur, duree)
	table.insert(nettoyer, stopCharge)

	if index == 1 then
		O.trainee(duree + 0.3)
		Animations.jouer("coup", 0.6)
	elseif index == 2 then
		-- Orbe qui grossit devant le joueur.
		local orbe = neon(Vector3.one * 0.5, couleur, r.CFrame * CFrame.new(0, 1.5, -2.5), Enum.PartType.Ball, 0)
		local coeur = neon(Vector3.one * 0.3, BLANC, orbe.CFrame, Enum.PartType.Ball, 0)
		tween(orbe, duree, { Size = Vector3.one * 3.5 })
		tween(coeur, duree, { Size = Vector3.one * 1.8 })
		lumiere(orbe, couleur, 16, 4, duree + 0.3)
		table.insert(nettoyer, function()
			orbe:Destroy()
			coeur:Destroy()
		end)
	elseif index == 3 then
		-- Cercle de runes au sol sous le joueur.
		local cercle = neon(Vector3.new(0.2, 4, 4), couleur, CFrame.new(r.Position - Vector3.new(0, 2.9, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, 0.4)
		tween(cercle, duree, { Size = Vector3.new(0.2, 16, 16), Transparency = 0.2 })
		table.insert(nettoyer, function()
			tween(cercle, 0.3, { Transparency = 1 })
			Debris:AddItem(cercle, 0.35)
		end)
		Animations.jouer("fente", 0.4)
	elseif index == 4 then
		-- Anneaux qui se resserrent, l'image se fige un peu.
		for i = 1, 3 do
			task.delay((i - 1) * duree / 3, function()
				local a = neon(Vector3.new(0.3, 30, 30), couleur, CFrame.new(r.Position - Vector3.new(0, 2.8, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, 0.5)
				tween(a, duree / 2, { Size = Vector3.new(0.3, 3, 3), Transparency = 0 })
				Debris:AddItem(a, duree / 2 + 0.05)
			end)
		end
		correction.Saturation = 0
		tween(correction, duree, { Saturation = -0.4, Contrast = 0.2 })
		table.insert(nettoyer, function()
			tween(correction, 0.3, { Saturation = 0, Contrast = 0 })
		end)
	elseif index == 5 then
		-- Éveil : cinématique, ciel sombre, colonne d'énergie autour du joueur.
		O.bandesCinema("ÉVEIL", "Puissance " .. (nomElement or "") .. " libérée", duree + 1.4)
		cameraAutour(duree, 9, 3, 1)
		correction.TintColor = couleur:Lerp(BLANC, 0.5)
		tween(correction, duree, { Brightness = -0.25, Contrast = 0.35, Saturation = 0.3 })
		local colonne = neon(Vector3.new(80, 3, 3), couleur, CFrame.new(r.Position + Vector3.new(0, 38, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, 0.5)
		tween(colonne, duree, { Size = Vector3.new(80, 9, 9), Transparency = 0.25 })
		local att = Instance.new("Attachment")
		att.Parent = r
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(BLANC, couleur)
		pe.LightEmission = 1
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
		pe.Lifetime = NumberRange.new(0.6, 1)
		pe.Speed = NumberRange.new(15, 25)
		pe.EmissionDirection = Enum.NormalId.Top
		pe.SpreadAngle = Vector2.new(20, 20)
		pe.Rate = 150
		pe.Parent = att
		O.particulesElement(colonne, element, couleur, true)
		task.spawn(function()
			for _ = 1, 4 do
				task.wait(duree / 4)
				if colonne.Parent then
					onde(r.Position - Vector3.new(0, 2.8, 0), couleur, 24, 0.5)
					secousse(0.4, 0.2)
				end
			end
		end)
		table.insert(nettoyer, function()
			pe.Enabled = false
			Debris:AddItem(att, 1)
			tween(colonne, 0.25, { Transparency = 1 })
			Debris:AddItem(colonne, 0.3)
		end)
		Animations.jouer("fente", 0.3)
	elseif index == 6 then
		-- Ultime : boule suprême qui grossit au-dessus du joueur, l'énergie y est aspirée.
		ultimeTransforme = transforme == true
		local haut = r.Position + Vector3.new(0, 10, 0)
		local boulefeu = neon(Vector3.one, couleur, CFrame.new(haut), Enum.PartType.Ball, 0.05)
		local coeur = neon(Vector3.one * 0.6, Color3.fromRGB(255, 250, 225), CFrame.new(haut), Enum.PartType.Ball, 0)
		tween(boulefeu, duree, { Size = Vector3.one * 16 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(coeur, duree, { Size = Vector3.one * 9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		lumiere(boulefeu, couleur, 50, 7, duree + 2)
		local flammes = Instance.new("ParticleEmitter")
		flammes.Color = ColorSequence.new(Color3.fromRGB(255, 240, 160), couleur)
		flammes.LightEmission = 1
		flammes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 4), NumberSequenceKeypoint.new(1, 0) })
		flammes.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		flammes.Lifetime = NumberRange.new(0.4, 0.8)
		flammes.Rate = 140
		flammes.Speed = NumberRange.new(3, 8)
		flammes.SpreadAngle = Vector2.new(180, 180)
		flammes.Acceleration = Vector3.new(0, 12, 0)
		flammes.Parent = boulefeu
		local aspire = flammes:Clone()
		aspire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
		aspire.Speed = NumberRange.new(-30, -20)
		aspire.Acceleration = Vector3.zero
		aspire.Shape = Enum.ParticleEmitterShape.Sphere
		aspire.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		aspire.Rate = 200
		aspire.Parent = boulefeu
		Attaques.bouleUltime = { boulefeu, coeur }
		Debris:AddItem(boulefeu, duree + 4)
		Debris:AddItem(coeur, duree + 4)
		correction.TintColor = Color3.fromRGB(255, 200, 160)
		tween(correction, duree, { Brightness = -0.3, Contrast = 0.3 })
		task.spawn(function()
			for i = 1, math.floor(duree / 0.3) do
				task.wait(0.3)
				if boulefeu.Parent then
					onde(r.Position - Vector3.new(0, 2.8, 0), couleur, 20, 0.4)
					secousse(0.3 + i * 0.05, 0.15)
				end
			end
		end)
		if ultimeTransforme then
			cinematiqueAnime(duree, couleur, boulefeu)
		else
			cameraAutour(duree, 13, 5, 0.4)
		end
		Animations.jouer("fente", 0.25)
	end

	return function()
		for _, f in nettoyer do
			f()
		end
	end
end

---------------------------------------------------------------------
-- Déchaînements (quand le serveur confirme le coup)
---------------------------------------------------------------------
local DECHAINER = {}

-- 1 : croissant géant devant le joueur.
DECHAINER[1] = function(cible, couleur, element)
	local r = racine()
	Animations.jouer("fente", 1.6)
	O.trainee(0.4)
	if r then
		local base = CFrame.lookAt(r.Position, Vector3.new(cible.X, r.Position.Y, cible.Z)) * CFrame.new(0, 0.5, -4)
		for i = -5, 5 do
			local a = math.rad(i * 13)
			local seg = neon(Vector3.new(2.6, 0.4, 0.9), i == 0 and BLANC or couleur, base * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -3) * CFrame.Angles(0, 0, math.rad(i * 3)), nil, 0)
			tween(seg, 0.32, { CFrame = base * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -9), Size = Vector3.new(4.5, 0.15, 1.8), Transparency = 1 })
			Debris:AddItem(seg, 0.35)
		end
		O.imageRemanente(couleur)
	end
	Animations.impact(cible, couleur, true, element)
	fovCoup(-8, 0.3)
	secousse(0.8, 0.2)
end

-- 2 : projectile de l'élément jusqu'à l'ennemi.
DECHAINER[2] = function(cible, couleur, element)
	local r = racine()
	Animations.jouer("coup", 1.8)
	local depart = r and (r.Position + r.CFrame.LookVector * 2.5 + Vector3.new(0, 1.5, 0)) or cible
	local forme = element == "glace" and Vector3.new(1.2, 1.2, 7) or Vector3.one * 3.5
	local projectile = neon(forme, couleur, CFrame.lookAt(depart, cible), element ~= "glace" and Enum.PartType.Ball or nil, 0)
	if element == "ombre" then
		projectile.Color = Color3.fromRGB(30, 10, 50)
	end
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1, 0)
	a0.Parent = projectile
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -1, 0)
	a1.Parent = projectile
	local tr = Instance.new("Trail")
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Color = ColorSequence.new(BLANC, couleur)
	tr.LightEmission = 1
	tr.Lifetime = 0.25
	tr.WidthScale = NumberSequence.new(1, 0)
	tr.Parent = projectile
	lumiere(projectile, couleur, 18, 5, 0.4)
	if element == "foudre" then
		local longueur = (cible - depart).Magnitude
		local rayon = neon(Vector3.new(1.2, 1.2, longueur), couleur, CFrame.lookAt((depart + cible) / 2, cible), nil, 0)
		tween(rayon, 0.3, { Transparency = 1, Size = Vector3.new(0.1, 0.1, longueur) })
		Debris:AddItem(rayon, 0.35)
	end
	local t = tween(projectile, 0.16, { CFrame = CFrame.lookAt(cible, cible + (cible - depart).Unit) }, Enum.EasingStyle.Linear)
	t.Completed:Connect(function()
		projectile:Destroy()
		Animations.impact(cible, couleur, true, element)
		boule(cible, couleur, 16, 0.45, 0.2)
		onde(cible - Vector3.new(0, 2, 0), couleur, 26, 0.45)
		signature(cible, element, couleur, 1)
		flash(0.3, 0.35)
		secousse(1, 0.25)
	end)
	fovCoup(-6, 0.4)
end

-- 3 : six colonnes autour de l'ennemi.
DECHAINER[3] = function(cible, couleur, element)
	Animations.jouer("fente", 1.4)
	local sol = cible - Vector3.new(0, 3, 0)
	for i = 0, 6 do
		task.delay(i * 0.06, function()
			local angle = i * math.pi * 2 / 6
			local pos = i == 6 and sol or (sol + Vector3.new(math.cos(angle), 0, math.sin(angle)) * 7)
			local hauteur = i == 6 and 26 or 16
			if element == "glace" or element == "ombre" then
				pointe(pos, element == "glace" and Color3.fromRGB(190, 235, 255) or Color3.fromRGB(60, 20, 90), hauteur * 0.6, element == "glace" and Enum.Material.Glass or Enum.Material.Neon, 0.25)
			end
			local col = neon(Vector3.new(hauteur, 1, 1), couleur, CFrame.new(pos + Vector3.new(0, hauteur / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, 0.1)
			tween(col, 0.12, { Size = Vector3.new(hauteur, 4, 4) }, Enum.EasingStyle.Back)
			task.delay(0.15, function()
				tween(col, 0.4, { Size = Vector3.new(hauteur * 1.2, 0.2, 0.2), Transparency = 1 })
			end)
			Debris:AddItem(col, 0.6)
			onde(pos + Vector3.new(0, 0.2, 0), couleur, 10, 0.35)
			O.particulesElement(col, element, couleur, false)
			if element == "foudre" then
				O.eclair(pos, couleur)
			end
			secousse(0.5, 0.1)
		end)
	end
	task.delay(0.42, function()
		Animations.impact(cible, couleur, true, element)
		signature(cible, element, couleur, 0.8)
		flash(0.25, 0.3)
	end)
end

-- 4 : Nova, la zone autour du joueur.
DECHAINER[4] = function(_, couleur, element, rayon)
	local r = racine()
	if not r then
		return
	end
	rayon = rayon or 24
	local centre = r.Position
	Animations.jouer("fente", 1.2)
	boule(centre, BLANC, 8, 0.15, 0)
	local sphere = boule(centre, couleur, rayon * 2, 0.55, 0.35)
	lumiere(sphere, couleur, 40, 8, 0.6)
	onde(centre - Vector3.new(0, 2.8, 0), couleur, rayon * 2, 0.5, 0.5)
	task.delay(0.1, function()
		onde(centre - Vector3.new(0, 2.7, 0), BLANC, rayon * 2.3, 0.45, 0.2)
	end)
	task.delay(0.2, function()
		onde(centre - Vector3.new(0, 2.6, 0), couleur, rayon * 2.6, 0.6, 0.15)
	end)
	-- Éclats projetés en cercle.
	for i = 1, 16 do
		local a = i * math.pi * 2 / 16
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local eclat = neon(Vector3.new(0.6, 0.6, 3), couleur, CFrame.lookAt(centre, centre + dir), nil, 0)
		tween(eclat, 0.4, { CFrame = CFrame.lookAt(centre + dir * rayon, centre + dir * (rayon + 1)), Transparency = 1 })
		Debris:AddItem(eclat, 0.45)
	end
	particules(sphere, {
		Color = ColorSequence.new(BLANC, couleur),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
		Speed = NumberRange.new(40, 70),
		SpreadAngle = Vector2.new(180, 10),
		Lifetime = NumberRange.new(0.3, 0.5),
		Drag = 4,
	}, 80)
	O.particulesElement(sphere, element, couleur, true)
	flash(0.5, 0.5)
	flou.Size = 10
	tween(flou, 0.4, { Size = 0 })
	fovCoup(10, 0.5)
	secousse(1.6, 0.4)
end

-- 5 : Éveil, pilier colossal tombé du ciel.
DECHAINER[5] = function(cible, couleur, element)
	Animations.jouer("coup", 1.2)
	local sol = cible - Vector3.new(0, 3, 0)
	-- Avertissement : le pilier fin apparaît, puis s'élargit d'un coup.
	local pilier = neon(Vector3.new(300, 2, 2), BLANC, CFrame.new(sol + Vector3.new(0, 150, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, 0)
	local gaine = neon(Vector3.new(300, 4, 4), couleur, pilier.CFrame, Enum.PartType.Cylinder, 0.3)
	tween(pilier, 0.12, { Size = Vector3.new(300, 10, 10) }, Enum.EasingStyle.Back)
	tween(gaine, 0.15, { Size = Vector3.new(300, 22, 22) }, Enum.EasingStyle.Back)
	lumiere(gaine, couleur, 60, 10, 1.2)
	task.delay(0.35, function()
		tween(pilier, 0.6, { Size = Vector3.new(300, 0.3, 0.3), Transparency = 1 })
		tween(gaine, 0.8, { Size = Vector3.new(300, 40, 40), Transparency = 1 })
	end)
	Debris:AddItem(pilier, 1)
	Debris:AddItem(gaine, 1.2)
	-- Trois ondes de choc et l'explosion de l'élément.
	for i = 0, 2 do
		task.delay(i * 0.12, function()
			onde(sol + Vector3.new(0, 0.3, 0), i == 1 and BLANC or couleur, 50 + i * 20, 0.6, 0.6)
			Animations.impact(cible + Vector3.new(rng:NextNumber(-3, 3), rng:NextNumber(0, 4), rng:NextNumber(-3, 3)), couleur, true, element)
		end)
	end
	local dome = boule(sol, couleur, 34, 0.8, 0.25)
	O.particulesElement(dome, element, couleur, true)
	signature(cible, element, couleur, 2)
	-- Débris projetés en l'air.
	for _ = 1, 14 do
		local bloc = Instance.new("Part")
		bloc.Size = Vector3.one * rng:NextNumber(0.6, 1.6)
		bloc.Color = Color3.fromRGB(90, 75, 60)
		bloc.Material = Enum.Material.Slate
		bloc.CanCollide = false
		bloc.CanQuery = false
		bloc.CanTouch = false
		bloc.CFrame = CFrame.new(sol + Vector3.new(rng:NextNumber(-4, 4), 1, rng:NextNumber(-4, 4)))
		bloc.AssemblyLinearVelocity = Vector3.new(rng:NextNumber(-30, 30), rng:NextNumber(40, 70), rng:NextNumber(-30, 30))
		bloc.Parent = Workspace
		Debris:AddItem(bloc, 2)
	end
	flash(0.9, 0.8, couleur:Lerp(BLANC, 0.6))
	tween(correction, 0.8, { Contrast = 0, Saturation = 0 })
	flou.Size = 16
	tween(flou, 0.6, { Size = 0 })
	Animations.hitstop(0.22)
	fovCoup(14, 0.8)
	secousse(2.4, 0.7)
end

-- Explosion de l'Ultime : dôme, ondes, colonne en champignon, débris ; plan large si transformé.
local function explosionUltime(cible, couleur, element, transforme)
	local sol = cible - Vector3.new(0, 3, 0)
	imageImpact(transforme and 3 or 1)
	boule(cible, Color3.fromRGB(255, 250, 230), 34, 0.3, 0)
	local dome = boule(cible, couleur, 80, 1.4, 0.1)
	lumiere(dome, couleur, 60, 12, 1.5)
	O.particulesElement(dome, element, couleur, true)
	particules(dome, {
		Color = ColorSequence.new(Color3.fromRGB(255, 240, 160), couleur),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(1, 0) }),
		Speed = NumberRange.new(30, 80),
		SpreadAngle = Vector2.new(180, 180),
		Lifetime = NumberRange.new(0.6, 1.2),
		Acceleration = Vector3.new(0, 20, 0),
		Drag = 3,
	}, 120)
	for i = 0, 3 do
		task.delay(i * 0.1, function()
			onde(sol + Vector3.new(0, 0.3, 0), i % 2 == 0 and couleur or BLANC, 70 + i * 35, 0.8, 0.8)
		end)
	end
	local colonne = neon(Vector3.new(10, 14, 14), couleur, CFrame.new(sol + Vector3.new(0, 5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, 0.1)
	tween(colonne, 0.6, { Size = Vector3.new(90, 26, 26), CFrame = CFrame.new(sol + Vector3.new(0, 45, 0)) * CFrame.Angles(0, 0, math.rad(90)), Transparency = 1 })
	Debris:AddItem(colonne, 0.65)
	task.delay(0.25, function()
		boule(sol + Vector3.new(0, 55, 0), couleur, 50, 1, 0.3)
	end)
	signature(cible, element, couleur, 2.5)
	for _ = 1, 24 do
		local bloc = Instance.new("Part")
		bloc.Size = Vector3.one * rng:NextNumber(0.8, 2)
		bloc.Color = Color3.fromRGB(70, 55, 45)
		bloc.Material = Enum.Material.Slate
		bloc.CanCollide = false
		bloc.CanQuery = false
		bloc.CanTouch = false
		bloc.CFrame = CFrame.new(sol + Vector3.new(rng:NextNumber(-6, 6), 1, rng:NextNumber(-6, 6)))
		bloc.AssemblyLinearVelocity = Vector3.new(rng:NextNumber(-45, 45), rng:NextNumber(50, 90), rng:NextNumber(-45, 45))
		bloc.Parent = Workspace
		Debris:AddItem(bloc, 2.5)
	end
	task.delay(0.2, function()
		flash(1.3, 1.4, couleur:Lerp(BLANC, 0.5))
	end)
	flou.Size = 22
	tween(flou, 1, { Size = 0 })
	Animations.hitstop(0.28)
	secousse(3.5, 1.1)
	fovCoup(transforme and 25 or 18, 1.1)
	if transforme then
		texteAnime("SUPRÊME !", couleur, 1.4)
		-- Plan large qui tourne autour de l'explosion, puis retour au jeu.
		camera.CameraType = Enum.CameraType.Scriptable
		local debut = os.clock()
		local c
		c = RunService.RenderStepped:Connect(function()
			local t = os.clock() - debut
			if t > 1.3 then
				c:Disconnect()
				camera.CameraType = Enum.CameraType.Custom
				return
			end
			local a = t * 0.9
			camera.CFrame = CFrame.lookAt(cible + Vector3.new(math.cos(a) * 55, 18 + t * 8, math.sin(a) * 55), cible + Vector3.new(0, 8, 0))
		end)
	else
		camera.CameraType = Enum.CameraType.Custom
	end
end

-- 6 : Ultime, la boule suprême part vers l'ennemi (suivie par la caméra si transformé).
DECHAINER[6] = function(cible, couleur, element)
	local r = racine()
	local boules = Attaques.bouleUltime
	Attaques.bouleUltime = nil
	local transforme = ultimeTransforme
	ultimeTransforme = false
	local boulefeu, coeur
	if boules and boules[1].Parent then
		boulefeu, coeur = boules[1], boules[2]
	else
		local haut = (r and r.Position or cible) + Vector3.new(0, 10, 0)
		boulefeu = neon(Vector3.one * 16, couleur, CFrame.new(haut), Enum.PartType.Ball, 0.05)
		coeur = neon(Vector3.one * 9, Color3.fromRGB(255, 250, 225), CFrame.new(haut), Enum.PartType.Ball, 0)
	end
	Animations.jouer("coup", 0.9)
	local vol = transforme and 0.8 or 0.45
	local depart = boulefeu.Position
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 5, 0)
	a0.Parent = boulefeu
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -5, 0)
	a1.Parent = boulefeu
	local trainee = Instance.new("Trail")
	trainee.Attachment0 = a0
	trainee.Attachment1 = a1
	trainee.Color = ColorSequence.new(Color3.fromRGB(255, 240, 160), couleur)
	trainee.LightEmission = 1
	trainee.Lifetime = 0.35
	trainee.WidthScale = NumberSequence.new(1, 0)
	trainee.Parent = boulefeu
	tween(boulefeu, vol, { CFrame = CFrame.new(cible) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tween(coeur, vol, { CFrame = CFrame.new(cible) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local suivi = nil
	if transforme then
		lignesVitesse(vol, couleur)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = 55
		local dir = (cible - depart).Magnitude > 0.1 and (cible - depart).Unit or Vector3.new(0, 0, -1)
		suivi = RunService.RenderStepped:Connect(function()
			if boulefeu.Parent then
				local p = boulefeu.Position
				camera.CFrame = CFrame.lookAt(p - dir * 26 + Vector3.new(0, 7, 0), p + dir * 10)
			end
		end)
	end
	task.delay(vol, function()
		if suivi then
			suivi:Disconnect()
		end
		boulefeu:Destroy()
		coeur:Destroy()
		explosionUltime(cible, couleur, element, transforme)
	end)
end

function Attaques.dechainer(index, cible, couleur, element, rayon)
	local f = DECHAINER[index]
	if f and cible then
		f(cible, couleur, element, rayon)
	end
end

-- Fin de charge sans coup (ennemi hors de portée) : on remet l'image.
function Attaques.annuler()
	local boules = Attaques.bouleUltime
	Attaques.bouleUltime = nil
	ultimeTransforme = false
	if boules then
		for _, p in boules do
			p:Destroy()
		end
	end
	local lignes = joueur.PlayerGui:FindFirstChild("MagicalandLignes")
	if lignes then
		lignes:Destroy()
	end
	camera.FieldOfView = Animations.fovBase or 70
	tween(correction, 0.3, { Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Animations.teinteFond or BLANC })
	camera.CameraType = Enum.CameraType.Custom
end

---------------------------------------------------------------------
-- Transformation
---------------------------------------------------------------------
function Attaques.transformation(couleur, element)
	local r = racine()
	if not r then
		return
	end
	-- Cinématique : la caméra se place face au joueur (on voit les yeux rouges), puis tourne.
	O.bandesCinema("TRANSFORMATION", "Toutes tes forces x1,5 pendant 20 s", 2)
	cameraAutour(1.5, 7, 1.5, 0.8)
	Animations.jouer("fente", 0.5)
	correction.TintColor = couleur:Lerp(BLANC, 0.3)
	correction.Brightness = 0.6
	correction.Contrast = 0.3
	tween(correction, 1.2, { Brightness = 0, Contrast = 0.1, TintColor = couleur:Lerp(BLANC, 0.8) })
	-- Colonne d'énergie, ondes et souffle.
	local colonne = neon(Vector3.new(120, 2, 2), couleur, CFrame.new(r.Position + Vector3.new(0, 58, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, 0.2)
	tween(colonne, 0.25, { Size = Vector3.new(120, 12, 12) }, Enum.EasingStyle.Back)
	task.delay(0.6, function()
		tween(colonne, 0.8, { Size = Vector3.new(120, 0.3, 0.3), Transparency = 1 })
	end)
	Debris:AddItem(colonne, 1.5)
	lumiere(colonne, couleur, 50, 8, 1.4)
	for i = 0, 3 do
		task.delay(0.15 + i * 0.2, function()
			onde(r.Position - Vector3.new(0, 2.8, 0), i % 2 == 0 and couleur or BLANC, 30 + i * 12, 0.6, 0.4)
			secousse(0.9 - i * 0.15, 0.2)
		end)
	end
	O.particulesElement(colonne, element, couleur, true)
	flou.Size = 12
	tween(flou, 0.8, { Size = 0 })
	-- Pendant la transformation : champ de vision un peu plus large (sensation de vitesse).
	Animations.fovBase = 76
	tween(camera, 1.5, { FieldOfView = 76 })
end

function Attaques.finTransformation()
	Animations.fovBase = 70
	tween(camera, 0.8, { FieldOfView = 70 })
	-- Épuisement : image délavée.
	correction.TintColor = Animations.teinteFond or BLANC
	tween(correction, 0.8, { Saturation = -0.45, Contrast = 0 })
end

function Attaques.finEpuisement()
	tween(correction, 0.8, { Saturation = 0, Contrast = 0 })
end

function Attaques.remettre()
	Animations.fovBase = 70
	camera.FieldOfView = 70
	tween(correction, 0.5, { Saturation = 0, Contrast = 0, Brightness = 0, TintColor = Animations.teinteFond or BLANC })
end

return Attaques
