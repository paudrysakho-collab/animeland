-- Colosse des Ronces : premier boss. Rig R15 géant (≈ 21 studs) habillé d'écorce, de ronces,
-- de mousse et de lanternes violettes, animé par l'Animator (marche, frappe, fente).
-- Entrée : 3,5 s d'intro (le joueur voit une caméra cinématique), il ne bouge pas.
-- Phase 1 : fouet de ronces (zone rouge devant lui) et racines (cercle rouge sous le joueur).
-- Phase 2 (sous 50 %) : il s'embrase, le sol craque, il va plus vite et ajoute la pluie de graines.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Donnees = require(ReplicatedStorage:WaitForChild("Magicaland"):WaitForChild("Donnees"))
local Rigs = require(script.Parent.Parent:WaitForChild("Rigs"))

local Colosse = {}
local rng = Random.new()

local ECHELLE = 4.2
local DUREE_INTRO = 3.5
local BOIS = Color3.fromRGB(92, 64, 44)
local BOIS_FONCE = Color3.fromRGB(60, 42, 30)
local MOUSSE = Color3.fromRGB(78, 120, 58)
local BRAISE = Color3.fromRGB(255, 120, 40)
local VIOLET = Color3.fromRGB(190, 110, 255)
local ALERTE = Color3.fromRGB(235, 70, 50)

local function lanterne(m, membre, decalage)
	local l = Rigs.accrocher(m, membre, Vector3.new(0.22, 0.3, 0.22), VIOLET, Enum.Material.Neon, decalage)
	l.Name = "Lanterne"
	local lumiere = Instance.new("PointLight")
	lumiere.Color = VIOLET
	lumiere.Range = 12
	lumiere.Brightness = 1.6
	lumiere.Parent = l
end

local function decorer(m)
	local R = CFrame.Angles
	local rad = math.rad
	-- Couronne de branches.
	for i = -2, 2 do
		local b = Rigs.accrocher(m, "Head", Vector3.new(0.14, 1.1, 0.14), BOIS_FONCE, Enum.Material.Wood, CFrame.new(i * 0.22, 0.95, 0) * R(0, 0, rad(-i * 20)))
		b.Name = "Branche"
	end
	-- Yeux ambrés et bouche d'écorce.
	for _, x in { -0.25, 0.25 } do
		local oeil = Rigs.accrocher(m, "Head", Vector3.new(0.22, 0.14, 0.1), Color3.fromRGB(255, 190, 70), Enum.Material.Neon, CFrame.new(x, 0.12, -0.62))
		oeil.Name = "Oeil"
	end
	Rigs.accrocher(m, "Head", Vector3.new(0.6, 0.12, 0.08), Color3.fromRGB(20, 12, 8), Enum.Material.SmoothPlastic, CFrame.new(0, -0.25, -0.62))
	-- Plaques d'écorce sur le torse et mousse sur les épaules.
	Rigs.accrocher(m, "UpperTorso", Vector3.new(2.3, 1.2, 0.25), BOIS_FONCE, Enum.Material.Wood, CFrame.new(0, 0.1, -0.55) * R(0.05, 0, 0))
	local coeur = Rigs.accrocher(m, "UpperTorso", Vector3.new(0.7, 0.7, 0.7), BRAISE, Enum.Material.Neon, CFrame.new(0, 0, -0.7), Enum.PartType.Ball)
	coeur.Name = "Coeur"
	coeur.Transparency = 1
	for _, cote in { "Left", "Right" } do
		Rigs.accrocher(m, cote .. "UpperArm", Vector3.new(1.2, 0.5, 1.2), MOUSSE, Enum.Material.Grass, CFrame.new(0, 0.55, 0))
		Rigs.accrocher(m, cote .. "UpperArm", Vector3.new(0.7, 0.7, 0.7), Color3.fromRGB(110, 110, 105), Enum.Material.Slate, CFrame.new(0, 0.8, 0.2) * R(0.4, 0.6, 0.2))
		-- Ronces enroulées autour de l'avant-bras puis fouet qui pend de la main.
		for i = 0, 2 do
			local r = Rigs.accrocher(m, cote .. "LowerArm", Vector3.new(0.12, 0.12, 1.1), Color3.fromRGB(60, 45, 28), Enum.Material.Wood, CFrame.new(0, -0.3 + i * 0.25, 0) * R(0, rad(i * 60), rad(30)))
			r.Name = "Ronce"
		end
		for i = 1, 4 do
			local seg = Rigs.accrocher(m, cote .. "Hand", Vector3.new(0.14, 0.6, 0.14), Color3.fromRGB(70, 55, 35), Enum.Material.Wood, CFrame.new(0, -0.3 - i * 0.5, -0.12 * i) * R(rad(-10 * i), 0, 0))
			seg.Name = "Ronce"
			Rigs.accrocher(m, cote .. "Hand", Vector3.new(0.05, 0.05, 0.3), Color3.fromRGB(40, 30, 20), Enum.Material.Wood, CFrame.new(0.1, -0.3 - i * 0.5, -0.12 * i))
		end
	end
	-- Lanternes violettes.
	lanterne(m, "Head", CFrame.new(-0.55, 1.3, 0))
	lanterne(m, "Head", CFrame.new(0.6, 1.2, 0))
	lanterne(m, "UpperTorso", CFrame.new(-0.8, -0.3, -0.6))
	lanterne(m, "UpperTorso", CFrame.new(0.8, -0.5, -0.6))
	lanterne(m, "LeftUpperArm", CFrame.new(0, -0.4, -0.45))
	lanterne(m, "RightUpperArm", CFrame.new(0, -0.4, -0.45))
end

function Colosse.creer(player, position, def)
	local m, hum, racine, pistes, surbrillance = Rigs.creer("Boss_" .. player.Name, {
		tete = BOIS,
		corps = BOIS,
		bras = BOIS,
		jambes = BOIS_FONCE,
		largeur = 1.4,
		profondeur = 1.3,
		teteEchelle = 1.2,
	}, ECHELLE, position, decorer)
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" and p.Name ~= "Deco" then
			p.Material = Enum.Material.Wood
		end
	end
	hum.WalkSpeed = def.vitesse
	return m, racine, m:FindFirstChild("Head"), { hum = hum, pistes = pistes, surbrillance = surbrillance }
end

-- Zone d'alerte au sol (disque ou rectangle rouge qui pulse).
local function zoneDisque(e, centre, rayon)
	local z = Instance.new("Part")
	z.Name = "ZoneAlerte"
	z.Shape = Enum.PartType.Cylinder
	z.Size = Vector3.new(0.3, rayon * 2, rayon * 2)
	z.CFrame = CFrame.new(centre.X, e.sol + 0.2, centre.Z) * CFrame.Angles(0, 0, math.rad(90))
	z.Color = ALERTE
	z.Material = Enum.Material.Neon
	z.Transparency = 0.55
	z.Anchored = true
	z.CanCollide = false
	z.CanQuery = false
	z.CanTouch = false
	z.Parent = Workspace
	TweenService:Create(z, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.25 }):Play()
	return { part = z, centre = Vector3.new(centre.X, 0, centre.Z), rayon = rayon }
end

local function zoneRectangle(e, cf, largeur, longueur)
	local z = Instance.new("Part")
	z.Name = "ZoneAlerte"
	z.Size = Vector3.new(largeur, 0.3, longueur)
	local centre = cf * CFrame.new(0, 0, -longueur / 2)
	z.CFrame = CFrame.new(centre.Position.X, e.sol + 0.2, centre.Position.Z) * (cf - cf.Position)
	z.Color = ALERTE
	z.Material = Enum.Material.Neon
	z.Transparency = 0.55
	z.Anchored = true
	z.CanCollide = false
	z.CanQuery = false
	z.CanTouch = false
	z.Parent = Workspace
	TweenService:Create(z, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Transparency = 0.25 }):Play()
	return { part = z, rect = z.CFrame, largeur = largeur, longueur = longueur }
end

local function dansZone(zone, position)
	if zone.rayon then
		local d = Vector3.new(position.X, 0, position.Z) - zone.centre
		return d.Magnitude <= zone.rayon + 1 -- 1 stud de tolérance pour le corps du joueur
	end
	local local_ = zone.rect:PointToObjectSpace(Vector3.new(position.X, zone.rect.Position.Y, position.Z))
	return math.abs(local_.X) <= zone.largeur / 2 + 1 and math.abs(local_.Z) <= zone.longueur / 2 + 1
end

local function nettoyerZones(e)
	if e.attaque then
		for _, zone in e.attaque.zones do
			zone.part:Destroy()
		end
	end
end

function Colosse.init(e, maintenant)
	e.echelle = ECHELLE
	e.phase = 1
	e.introFin = maintenant + DUREE_INTRO
	e.prochaineAttaque = e.introFin + 1
	e.attaque = nil
	e.cycle = 0
	e.prochainChemin = 0
	e.fissures = {}
	e.duree_intro = DUREE_INTRO
	-- Rugissement d'entrée : grande fente au ralenti.
	e.pistes.fente:Play(0.2)
	e.pistes.fente:AdjustSpeed(0.35)
end

function Colosse.annulerAttaque(e, maintenant)
	nettoyerZones(e)
	e.attaque = nil
	e.surbrillance.OutlineTransparency = 1
	e.pistes.coup:Stop(0.15)
	e.pistes.fente:Stop(0.15)
	e.hum.AutoRotate = true
	e.prochaineAttaque = math.max(e.prochaineAttaque, maintenant + 1)
end

-- Fissures de lave qui rayonnent autour du boss (phase 2).
local function fissures(e)
	local centre = e.racine.Position
	for i = 1, 10 do
		local a = (i / 10) * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local longueur = rng:NextNumber(10, 22)
		local f = Instance.new("Part")
		f.Name = "Fissure"
		f.Size = Vector3.new(rng:NextNumber(0.6, 1.4), 0.2, longueur)
		f.CFrame = CFrame.new(centre.X + math.cos(a) * (longueur / 2 + 3), e.sol + 0.12, centre.Z + math.sin(a) * (longueur / 2 + 3)) * CFrame.Angles(0, -a + math.pi / 2, 0)
		f.Color = BRAISE
		f.Material = Enum.Material.Neon
		f.Anchored = true
		f.CanCollide = false
		f.CanQuery = false
		f.CanTouch = false
		f.Transparency = 1
		f.Parent = Workspace
		TweenService:Create(f, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { Transparency = 0.1 }):Play()
		table.insert(e.fissures, f)
	end
end

-- Passage en phase 2 : il s'embrase et le sol craque.
local function phase2(e, maintenant, ctx)
	e.phase = 2
	e.faiblesse = e.def.faiblesse2
	e.resistance = e.def.resistance2
	Colosse.annulerAttaque(e, maintenant)
	e.prochaineAttaque = maintenant + 2.2
	e.hum.WalkSpeed = e.def.vitesse2
	for _, p in e.modele:GetDescendants() do
		if p:IsA("BasePart") then
			if p.Name == "UpperTorso" or p.Name == "Head" or p.Name:match("Arm") or p.Name == "Ronce" or p.Name == "Branche" then
				local feu = Instance.new("Fire")
				feu.Size = p.Name == "UpperTorso" and 14 or 6
				feu.Heat = 10
				feu.Color = BRAISE
				feu.SecondaryColor = VIOLET
				feu.Parent = p
			end
			if p.Name == "Coeur" then
				p.Transparency = 0
				local lumiere = Instance.new("PointLight")
				lumiere.Color = BRAISE
				lumiere.Range = 30
				lumiere.Brightness = 4
				lumiere.Parent = p
			elseif p.Name == "Lanterne" or p.Name == "Oeil" then
				p.Color = BRAISE
			elseif p.Name ~= "HumanoidRootPart" and p.Name ~= "Deco" and p.Name ~= "Fissure" then
				p.Color = Color3.fromRGB(70, 40, 28)
			end
		end
	end
	fissures(e)
	e.pistes.fente:Play(0.1)
	e.pistes.fente:AdjustSpeed(0.5)
	ctx.envoyer({ type = "phase", numero = 2, nom = e.def.nom, pos = e.racine.Position })
end

-- Lance une attaque : zone rouge, contour d'alerte, animation au ralenti, puis frappe.
local function lancerAttaque(e, maintenant, ctx, distance)
	local def = e.def
	local nom
	if e.phase == 1 then
		nom = (distance <= def.fouet.longueur and rng:NextNumber() < 0.6) and "fouet" or "racines"
	else
		e.cycle += 1
		local suite = { "graines", "fouet", "racines" }
		nom = suite[(e.cycle - 1) % #suite + 1]
		if nom == "fouet" and distance > def.fouet.longueur then
			nom = "racines"
		end
	end

	local acc = e.phase == 2 and 0.85 or 1
	local zones = {}
	local joueur = ctx.racine.Position
	local attaque
	e.hum:Move(Vector3.zero)
	e.hum.AutoRotate = false
	Rigs.regarder(e, joueur)
	if nom == "fouet" then
		local cf = CFrame.new(e.racine.Position.X, e.sol, e.racine.Position.Z) * (e.racine.CFrame - e.racine.CFrame.Position)
		table.insert(zones, zoneRectangle(e, cf * CFrame.new(0, 0, -2), def.fouet.largeur, def.fouet.longueur))
		attaque = def.fouet
		e.piste = e.pistes.coup
	elseif nom == "racines" then
		table.insert(zones, zoneDisque(e, joueur, def.racines.rayon))
		attaque = def.racines
		e.piste = e.pistes.fente
	else
		table.insert(zones, zoneDisque(e, joueur, def.graines.rayon))
		for _ = 2, def.graines.nombre do
			local a = rng:NextNumber() * math.pi * 2
			local r = rng:NextNumber(5, 11)
			table.insert(zones, zoneDisque(e, joueur + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r), def.graines.rayon))
		end
		attaque = def.graines
		e.piste = e.pistes.coup
	end
	e.piste:Play(0.15)
	e.piste:AdjustSpeed(0.2)
	e.surbrillance.OutlineTransparency = 0
	e.attaque = { nom = nom, fin = maintenant + attaque.preparation * acc, zones = zones, degats = attaque.degats }
	ctx.envoyer({ type = "alerte", attaque = nom })
end

local function resoudreAttaque(e, maintenant, ctx)
	local touche = false
	for _, zone in e.attaque.zones do
		if dansZone(zone, ctx.racine.Position) then
			touche = true
		end
	end
	local centres = {}
	for _, zone in e.attaque.zones do
		table.insert(centres, zone.part.Position)
	end
	ctx.envoyer({ type = "frappeBoss", attaque = e.attaque.nom, centres = centres })
	if touche then
		ctx.frapper(e.attaque.degats)
	else
		ctx.envoyer({ type = "esquive" })
	end
	for _, zone in e.attaque.zones do
		local p = zone.part
		p.Color = Color3.fromRGB(255, 200, 120)
		p.Transparency = 0.1
		TweenService:Create(p, TweenInfo.new(0.4), { Transparency = 1 }):Play()
		Debris:AddItem(p, 0.45)
	end
	e.piste:AdjustSpeed(2.4)
	e.surbrillance.OutlineTransparency = 1
	e.attaque = nil
	e.prochaineAttaque = maintenant + (e.phase == 2 and e.def.recharge2 or e.def.recharge)
	task.delay(0.5, function()
		e.hum.AutoRotate = true
	end)
end

function Colosse.mettreAJour(e, dt, maintenant, ctx)
	local def = e.def
	if maintenant < e.introFin then
		e.hum:Move(Vector3.zero)
		Rigs.regarder(e, ctx.racine.Position)
		return
	end
	if e.phase == 1 and e.pv <= e.pvMax * def.phase2 then
		phase2(e, maintenant, ctx)
	end

	local pos = e.racine.Position
	local joueur = ctx.racine.Position
	local dist = (Vector3.new(joueur.X, 0, joueur.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
	local etourdi = maintenant < e.etourdiFin

	if e.attaque then
		if maintenant >= e.attaque.fin then
			resoudreAttaque(e, maintenant, ctx)
		end
	elseif etourdi then
		e.hum:Move(Vector3.zero)
	else
		e.hum.WalkSpeed = (e.phase == 2 and def.vitesse2 or def.vitesse) * (maintenant < e.ralentiFin and 0.6 or 1)
		if dist > 9 then
			if maintenant >= e.prochainChemin then
				e.prochainChemin = maintenant + 0.2
				e.hum:MoveTo(joueur)
			end
		else
			e.hum:Move(Vector3.zero)
			Rigs.regarder(e, joueur)
		end
		if maintenant >= e.prochaineAttaque and dist <= 26 then
			lancerAttaque(e, maintenant, ctx, dist)
		end
	end

	Rigs.majLocomotion(e)
end

-- Mort : le colosse s'effondre en arrière, les fissures s'éteignent.
function Colosse.detruire(e, raison)
	nettoyerZones(e)
	e.attaque = nil
	for _, f in e.fissures do
		TweenService:Create(f, TweenInfo.new(2), { Transparency = 1 }):Play()
		Debris:AddItem(f, 2.1)
	end
	if raison ~= "victoire" then
		e.modele:Destroy()
		return
	end
	local barre = e.tete and e.tete:FindFirstChild("BarreVie")
	if barre then
		barre:Destroy()
	end
	Rigs.mourir(e.modele, e.racine, -e.racine.CFrame.LookVector * 12 + Vector3.new(0, 15, 0))
end

return Colosse
