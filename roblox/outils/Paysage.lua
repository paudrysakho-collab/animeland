-- Paysage de Magicaland : à lancer UNE FOIS dans Studio (barre de commande ou outil execute_luau), en mode édition.
-- Crée le terrain (prairie, collines, lac, montagnes enneigées, chemins), une forêt, des rochers, des fleurs,
-- un cercle de ruines autour de l'arène et règle la lumière (fin d'après-midi, brume, reflets, nuages).
-- L'arène (rayon 80 autour du point d'apparition) reste plate pour les combats.
-- Relancer efface et recrée tout (graine fixe : même résultat).

local T = workspace.Terrain
local M = Enum.Material
local Lighting = game:GetService("Lighting")
local rng = Random.new(2026)

-- Nettoyage.
T:Clear()
local ancien = workspace:FindFirstChild("Paysage")
if ancien then
	ancien:Destroy()
end
local dossier = Instance.new("Folder")
dossier.Name = "Paysage"

-- Le grand socle gris d'origine passe sous le terrain (filet de sécurité invisible).
local socle = workspace:FindFirstChild("Baseplate")
if socle then
	socle.Transparency = 1
	socle.Position = Vector3.new(0, -40, 0)
end

-- Couleurs du terrain (style anime doux).
T:SetMaterialColor(M.Grass, Color3.fromRGB(104, 158, 74))
T:SetMaterialColor(M.LeafyGrass, Color3.fromRGB(84, 140, 64))
T:SetMaterialColor(M.Ground, Color3.fromRGB(150, 120, 86))
T:SetMaterialColor(M.Rock, Color3.fromRGB(118, 112, 120))
T:SetMaterialColor(M.Sand, Color3.fromRGB(214, 196, 150))
T:SetMaterialColor(M.Cobblestone, Color3.fromRGB(150, 146, 140))
T.WaterColor = Color3.fromRGB(60, 140, 170)
T.WaterTransparency = 0.6
T.WaterReflectance = 0.6
T.WaterWaveSize = 0.12
T.WaterWaveSpeed = 8
pcall(function()
	T.Decoration = true -- brins d'herbe animés
end)

local function surCercle(dMin, dMax)
	local a = rng:NextNumber(0, math.pi * 2)
	local d = rng:NextNumber(dMin, dMax)
	return Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
end

local LAC = Vector3.new(170, 0, -150)
local function loinDuLac(p, marge)
	return (Vector3.new(p.X, 0, p.Z) - LAC).Magnitude > 50 + (marge or 0)
end

-- 1. Prairie : couche de 12 studs, surface à y = 0,5.
T:FillBlock(CFrame.new(0, -5.5, 0), Vector3.new(960, 12, 960), M.Grass)
task.wait()

-- 2. Collines douces hors de l'arène.
for i = 1, 45 do
	local p = surCercle(140, 340)
	if loinDuLac(p, 30) then
		T:FillBall(p + Vector3.new(0, rng:NextNumber(-26, -12), 0), rng:NextNumber(25, 48), i % 3 == 0 and M.LeafyGrass or M.Grass)
	end
	if i % 6 == 0 then
		task.wait()
	end
end

-- 3. Couronne de montagnes enneigées (bord du monde).
for i = 1, 40 do
	local a = i / 40 * math.pi * 2 + rng:NextNumber(-0.04, 0.04)
	local d = rng:NextNumber(400, 440)
	local rayon = rng:NextNumber(70, 115)
	local centre = Vector3.new(math.cos(a) * d, rng:NextNumber(-35, 5), math.sin(a) * d)
	T:FillBall(centre, rayon, M.Rock)
	T:FillBall(centre + Vector3.new(0, rayon * 0.78, 0), rayon * 0.32, M.Snow)
	task.wait()
end

-- 4. Lac avec plage de sable.
T:FillCylinder(CFrame.new(LAC + Vector3.new(0, -1, 0)), 3, 54, M.Sand)
T:FillCylinder(CFrame.new(LAC + Vector3.new(0, -2, 0)), 12, 44, M.Air)
T:FillCylinder(CFrame.new(LAC + Vector3.new(0, -10, 0)), 4, 46, M.Sand)
T:FillCylinder(CFrame.new(LAC + Vector3.new(0, -4.5, 0)), 5, 43, M.Water)
task.wait()

-- 5. Arène : cercle de pavés autour de la zone de combat.
T:FillCylinder(CFrame.new(0, 0, 0), 1, 92, M.Cobblestone)
T:FillCylinder(CFrame.new(0, 0, 0), 1.2, 85, M.Grass)

-- 6. Chemins de terre qui partent de l'arène.
local function chemin(depart, arrivee, largeur)
	local pas = 8
	local n = math.ceil((arrivee - depart).Magnitude / pas)
	for k = 0, n do
		local p = depart:Lerp(arrivee, k / n) + Vector3.new(rng:NextNumber(-2, 2), 0, rng:NextNumber(-2, 2))
		T:FillCylinder(CFrame.new(p.X, 0, p.Z), 1.1, largeur / 2, M.Ground)
	end
end
chemin(Vector3.new(0, 0, -92), Vector3.new(0, 0, -380), 9)
chemin(Vector3.new(80, 0, -45), LAC + Vector3.new(-50, 0, 20), 8)
chemin(Vector3.new(-80, 0, 40), Vector3.new(-330, 0, 160), 8)
task.wait()

-- 7. Rochers à moitié enterrés.
for i = 1, 70 do
	local p = surCercle(100, 370)
	if loinDuLac(p, 5) then
		T:FillBall(p + Vector3.new(0, rng:NextNumber(-2, 1), 0), rng:NextNumber(2.5, 7), M.Rock)
	end
	if i % 10 == 0 then
		task.wait()
	end
end

-- Petites pièces de décor (ancrées).
local function piece(forme, taille, cf, couleur, materiau, parent, collision)
	local p = Instance.new("Part")
	p.Shape = forme or Enum.PartType.Block
	p.Size = taille
	p.CFrame = cf
	p.Color = couleur
	p.Material = materiau or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = collision == true
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- 8. Forêt : feuillus (boules de feuillage) et sapins (cônes en étages).
local foret = Instance.new("Folder")
foret.Name = "Foret"
foret.Parent = dossier
local VERTS = { Color3.fromRGB(70, 130, 60), Color3.fromRGB(88, 150, 70), Color3.fromRGB(60, 115, 72), Color3.fromRGB(120, 160, 70) }
for i = 1, 170 do
	local p = surCercle(110, 380)
	if loinDuLac(p, 8) and math.abs(p.X) > 10 then
		local arbre = Instance.new("Model")
		arbre.Name = "Arbre"
		local h = rng:NextNumber(10, 18)
		local base = Vector3.new(p.X, 0, p.Z)
		piece(Enum.PartType.Cylinder, Vector3.new(h, rng:NextNumber(1.4, 2.2), rng:NextNumber(1.4, 2.2)), CFrame.new(base + Vector3.new(0, h / 2 - 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(105, 75, 50), Enum.Material.Wood, arbre, true)
		local vert = VERTS[rng:NextInteger(1, #VERTS)]
		if i % 3 == 0 then
			-- Sapin : étages qui rétrécissent.
			for k = 0, 3 do
				local largeur = (4 - k) * 2.6
				piece(Enum.PartType.Block, Vector3.new(largeur, 2.6, largeur), CFrame.new(base + Vector3.new(0, h * 0.45 + k * 2.6, 0)) * CFrame.Angles(0, math.rad(45 * k), 0), vert:Lerp(Color3.new(0, 0.2, 0.1), 0.25), Enum.Material.Grass, arbre)
			end
		else
			for k = 1, 3 do
				local d = Vector3.new(rng:NextNumber(-2.5, 2.5), rng:NextNumber(-1, 2.5), rng:NextNumber(-2.5, 2.5))
				local r = rng:NextNumber(6, 9)
				piece(Enum.PartType.Ball, Vector3.one * r, CFrame.new(base + Vector3.new(0, h, 0) + d), vert, Enum.Material.Grass, arbre)
			end
		end
		arbre.Parent = foret
	end
	if i % 20 == 0 then
		task.wait()
	end
end

-- 9. Fleurs en touffes.
local fleurs = Instance.new("Folder")
fleurs.Name = "Fleurs"
fleurs.Parent = dossier
local COULEURS_FLEURS = { Color3.fromRGB(255, 120, 160), Color3.fromRGB(255, 220, 90), Color3.fromRGB(180, 140, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(120, 200, 255) }
for i = 1, 70 do
	local centre = surCercle(95, 330)
	if loinDuLac(centre, 4) then
		local c = COULEURS_FLEURS[rng:NextInteger(1, #COULEURS_FLEURS)]
		for _ = 1, 4 do
			local p = centre + Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3))
			piece(Enum.PartType.Block, Vector3.new(0.15, 1.2, 0.15), CFrame.new(p + Vector3.new(0, 1, 0)), Color3.fromRGB(70, 130, 60), Enum.Material.Grass, fleurs)
			piece(Enum.PartType.Ball, Vector3.one * 0.7, CFrame.new(p + Vector3.new(0, 1.7, 0)), c, Enum.Material.SmoothPlastic, fleurs)
		end
	end
	if i % 20 == 0 then
		task.wait()
	end
end

-- 10. Ruines : 12 piliers de pierre autour de l'arène (certains brisés) et cristaux magiques lumineux.
local ruines = Instance.new("Folder")
ruines.Name = "Ruines"
ruines.Parent = dossier
for i = 1, 12 do
	local a = i / 12 * math.pi * 2
	local p = Vector3.new(math.cos(a) * 98, 0, math.sin(a) * 98)
	local h = (i % 4 == 0) and rng:NextNumber(4, 7) or rng:NextNumber(14, 20)
	local pilier = piece(Enum.PartType.Block, Vector3.new(4, h, 4), CFrame.new(p + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, a, math.rad(rng:NextNumber(-4, 4))), Color3.fromRGB(170, 165, 158), Enum.Material.Slate, ruines, true)
	pilier.Name = "Pilier"
	if h > 10 then
		piece(Enum.PartType.Block, Vector3.new(5.5, 1.2, 5.5), pilier.CFrame * CFrame.new(0, h / 2 + 0.6, 0), Color3.fromRGB(150, 145, 140), Enum.Material.Slate, ruines, true)
	end
	if i % 2 == 0 then
		local cristal = piece(Enum.PartType.Block, Vector3.new(1.2, 3.5, 1.2), CFrame.new(p + Vector3.new(0, h + 3.5, 0)) * CFrame.Angles(math.rad(20), math.rad(45), math.rad(15)), Color3.fromRGB(120, 210, 255), Enum.Material.Neon, ruines)
		cristal.Name = "Cristal"
		local lumiere = Instance.new("PointLight")
		lumiere.Color = cristal.Color
		lumiere.Range = 14
		lumiere.Brightness = 1.5
		lumiere.Parent = cristal
	end
end
task.wait()
dossier.Parent = workspace

-- 11. Nuages.
local nuages = T:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
nuages.Cover = 0.55
nuages.Density = 0.65
nuages.Color = Color3.fromRGB(255, 245, 240)
nuages.Parent = T

-- 12. Lumière : fin d'après-midi dorée, brume légère, reflets.
Lighting.ClockTime = 16.6
Lighting.GeographicLatitude = 35
Lighting.Brightness = 2.6
Lighting.Ambient = Color3.fromRGB(70, 62, 82)
Lighting.OutdoorAmbient = Color3.fromRGB(128, 118, 136)
Lighting.ShadowSoftness = 0.25
pcall(function()
	Lighting.EnvironmentDiffuseScale = 0.8
	Lighting.EnvironmentSpecularScale = 0.6
end)
local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
atmo.Density = 0.32
atmo.Offset = 0.15
atmo.Color = Color3.fromRGB(205, 178, 160)
atmo.Decay = Color3.fromRGB(110, 92, 125)
atmo.Glare = 0.35
atmo.Haze = 1.6
local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
bloom.Intensity = 0.6
bloom.Size = 28
bloom.Threshold = 1.6
local rayons = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect", Lighting)
rayons.Intensity = 0.08
rayons.Spread = 0.6
local profondeur = Lighting:FindFirstChildOfClass("DepthOfFieldEffect")
if profondeur then
	profondeur.FarIntensity = 0.12
	profondeur.FocusDistance = 60
	profondeur.InFocusRadius = 90
	profondeur.NearIntensity = 0
end
local ambiance = Lighting:FindFirstChild("MagicalandAmbiance") or Instance.new("ColorCorrectionEffect")
ambiance.Name = "MagicalandAmbiance"
ambiance.Saturation = 0.12
ambiance.Contrast = 0.08
ambiance.TintColor = Color3.fromRGB(255, 248, 240)
ambiance.Parent = Lighting

return "Paysage créé : " .. #foret:GetChildren() .. " arbres, " .. #fleurs:GetChildren() .. " pièces de fleurs."
