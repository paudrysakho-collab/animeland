-- Attaques : habillage visuel des 6 attaques spéciales (côté joueur, rien de décisif).
-- Chaque attaque a sa forme propre, colorée et « signée » par l'élément du joueur :
--   1 Frappe d'arcane : croissant géant tranché devant soi.
--   2 Lance : projectile de l'élément qui file jusqu'à l'ennemi et explose.
--   3 Colonnes : six colonnes de l'élément jaillissent du sol autour de l'ennemi.
--   4 Nova : sphère et anneaux qui s'étendent depuis le joueur (zone).
--   5 Jugement : cinématique, ciel qui s'assombrit, pilier colossal tombé du ciel.
--   6 Boule suprême : boule d'énergie géante lancée vers l'ennemi.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local Animations = require(script.Parent:WaitForChild("Animations"))
local T = require(game:GetService("ReplicatedStorage"):WaitForChild("Magicaland"):WaitForChild("Donnees")).TEXTURES
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

-- Lance la charge visuelle de l'attaque index. Renvoie une fonction qui l'arrête.
function Attaques.charge(index, couleur, element, duree, nomElement)
	local r = racine()
	if not r then
		return function() end
	end
	local nettoyer = {}
	local stopCharge = Animations.charge(couleur, duree)
	table.insert(nettoyer, stopCharge)

	-- Mouvements de charge : petit bond (Colonnes), lévitation (Nova, Ultime), saut arrière puis vol stationnaire (Jugement).
	if index == 3 then
		Animations.elan(0, 0, 30, 0.18, 0)
	elseif index == 4 then
		Animations.elan(0, 0, 9, duree, 0)
	elseif index == 5 then
		Animations.elan(-28, 0, 24, 0.25, 0)
		task.delay(0.26, function()
			Animations.elan(0, 0, 2, math.max(0.1, duree - 0.26), 0)
		end)
	elseif index == 6 then
		Animations.elan(0, 0, 4, duree, 0)
	end

	-- Pose de l'épée pendant la charge (une par attaque ; l'Ultime garde sa mise en scène).
	local POSE_CHARGE = { "bras", "garde", "leve", "puissance", "ciel" }
	if POSE_CHARGE[index] then
		Animations.pose(POSE_CHARGE[index], 0.15, math.max(0.05, duree - 0.1), 0.15)
	end

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
		O.bandesCinema("JUGEMENT", "Puissance " .. (nomElement or "") .. " libérée", duree + 1.4)
		cameraAutour(duree, 9, 3, 1)
		correction.TintColor = couleur:Lerp(BLANC, 0.5)
		tween(correction, duree, { Brightness = -0.25, Contrast = 0.35, Saturation = 0.3 })
		local colonne = neon(Vector3.new(80, 3, 3), couleur, CFrame.new(r.Position + Vector3.new(0, 38, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder, 0.5)
		tween(colonne, duree, { Size = Vector3.new(80, 9, 9), Transparency = 0.25 })
		local att = Instance.new("Attachment")
		att.Parent = r
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = T.etincelle
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
		local haut = r.Position + Vector3.new(0, 10, 0)
		local boulefeu = neon(Vector3.one, couleur, CFrame.new(haut), Enum.PartType.Ball, 0.05)
		local coeur = neon(Vector3.one * 0.6, Color3.fromRGB(255, 250, 225), CFrame.new(haut), Enum.PartType.Ball, 0)
		tween(boulefeu, duree, { Size = Vector3.one * 16 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(coeur, duree, { Size = Vector3.one * 9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		lumiere(boulefeu, couleur, 50, 7, duree + 2)
		local flammes = Instance.new("ParticleEmitter")
		flammes.Texture = element == "feu" and T.flamme or T.aura
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
		cameraAutour(duree, 13, 5, 0.4)
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

-- 1 : croissant géant devant le joueur, après une ruée tournoyante vers l'ennemi.
DECHAINER[1] = function(cible, couleur, element)
	local r = racine()
	Animations.pose("bras", 0.05, 0.3, 0.2) -- tournoiement, épée tendue
	if r and ((cible - r.Position) * Vector3.new(1, 0, 1)).Magnitude > 6 then
		Animations.elan(80, 0, 0, 0.12, 360, cible)
	else
		Animations.elan(0, 0, 0, 0.15, 360, cible)
	end
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

-- 2 : projectile de l'élément jusqu'au point visé ; le lanceur glisse en arrière sous le recul.
DECHAINER[2] = function(cible, couleur, element, _, vol)
	local r = racine()
	Animations.pose("estoc", 0.06, 0.25, 0.2) -- estocade qui projette la lance
	Animations.elan(-38, 0, 5, 0.15, 0, cible)
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
	local t = tween(projectile, vol or 0.16, { CFrame = CFrame.lookAt(cible, cible + (cible - depart).Unit) }, Enum.EasingStyle.Linear)
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

-- 3 : six colonnes autour du point visé ; le joueur retombe en frappant le sol.
DECHAINER[3] = function(cible, couleur, element)
	Animations.jouer("fente", 1.4)
	Animations.pose("abat", 0.06, 0.3, 0.2) -- l'épée s'abat et lance une vague d'énergie au sol
	Animations.elan(0, 0, -80, 0.1, 0, cible)
	local r = racine()
	if r then
		local depart = r.Position - Vector3.new(0, 1.5, 0)
		local arrivee = Vector3.new(cible.X, depart.Y, cible.Z)
		if (arrivee - depart).Magnitude > 1 then
			local dir = (arrivee - depart).Unit
			local vague = neon(Vector3.new(7, 4, 0.6), couleur, CFrame.lookAt(depart, depart + dir), nil, 0.1)
			tween(vague, 0.3, { CFrame = CFrame.lookAt(arrivee, arrivee + dir), Size = Vector3.new(10, 6, 0.3), Transparency = 0.6 }, Enum.EasingStyle.Linear)
			Debris:AddItem(vague, 0.32)
		end
	end
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
	Animations.elan(0, 0, -90, 0.1, 0) -- après la lévitation, on s'écrase au sol
	Animations.pose("planter", 0.05, 0.4, 0.25) -- l'épée plantée dans le sol déclenche l'explosion
	for i = 1, 8 do
		-- Fissures lumineuses qui partent de l'épée.
		local a = i * math.pi * 2 / 8 + rng:NextNumber(-0.2, 0.2)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local longueur = rng:NextNumber(8, 14)
		local fissure = neon(Vector3.new(0.5, 0.2, longueur), couleur, CFrame.lookAt(centre - Vector3.new(0, 2.85, 0) + dir * longueur / 2, centre - Vector3.new(0, 2.85, 0) + dir * longueur), nil, 0)
		tween(fissure, 0.6, { Transparency = 1 })
		Debris:AddItem(fissure, 0.65)
	end
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

-- 5 : Jugement, pilier colossal tombé du ciel ; le joueur plonge vers l'avant.
DECHAINER[5] = function(cible, couleur, element)
	Animations.jouer("coup", 1.2)
	Animations.pose("abat", 0.05, 0.3, 0.2) -- l'épée tendue vers le ciel s'abat : le pilier tombe
	Animations.elan(36, 0, -24, 0.15, 0, cible)
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

-- Explosion de l'Ultime : dôme, ondes, colonne en champignon, débris.
local function explosionUltime(cible, couleur, element)
	local sol = cible - Vector3.new(0, 3, 0)
	imageImpact(1)
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
	fovCoup(18, 1.1)
	camera.CameraType = Enum.CameraType.Custom
end

-- 6 : Ultime, la boule suprême part vers l'ennemi.
DECHAINER[6] = function(cible, couleur, element, _, volServeur)
	local r = racine()
	Animations.elan(-22, 0, 0, 0.12, 0, cible) -- recul du lancer
	local boules = Attaques.bouleUltime
	Attaques.bouleUltime = nil
	local boulefeu, coeur
	if boules and boules[1].Parent then
		boulefeu, coeur = boules[1], boules[2]
	else
		local haut = (r and r.Position or cible) + Vector3.new(0, 10, 0)
		boulefeu = neon(Vector3.one * 16, couleur, CFrame.new(haut), Enum.PartType.Ball, 0.05)
		coeur = neon(Vector3.one * 9, Color3.fromRGB(255, 250, 225), CFrame.new(haut), Enum.PartType.Ball, 0)
	end
	Animations.jouer("coup", 0.9)
	local vol = volServeur or 0.45
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
	task.delay(vol, function()
		boulefeu:Destroy()
		coeur:Destroy()
		explosionUltime(cible, couleur, element)
	end)
end

function Attaques.dechainer(index, cible, couleur, element, rayon, vol)
	local f = DECHAINER[index]
	if f and cible then
		f(cible, couleur, element, rayon, vol)
	end
end

-- Fin de charge sans coup (ennemi hors de portée) : on remet l'image.
function Attaques.annuler()
	local boules = Attaques.bouleUltime
	Attaques.bouleUltime = nil
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

function Attaques.remettre()
	Animations.fovBase = 70
	camera.FieldOfView = 70
	tween(correction, 0.5, { Saturation = 0, Contrast = 0, Brightness = 0, TintColor = Animations.teinteFond or BLANC })
end

return Attaques
