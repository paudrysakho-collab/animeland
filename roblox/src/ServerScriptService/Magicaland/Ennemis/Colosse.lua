-- Colosse des Ronces : premier boss (« boss de la semaine »). Arbre-golem géant en pièces simples.
-- Phase 1 : fouet de ronces (zone rouge devant lui) et racines (cercle rouge sous le joueur).
-- Phase 2 (sous 50 % de vie) : il s'embrase, va plus vite, et ajoute la pluie de graines (4 cercles).
-- Chaque attaque est annoncée par une zone rouge au sol : en sortir à temps = esquive.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Donnees = require(ReplicatedStorage:WaitForChild("Magicaland"):WaitForChild("Donnees"))

local Colosse = {}
local rng = Random.new()

local BOIS = Color3.fromRGB(92, 64, 44)
local BOIS_FONCE = Color3.fromRGB(60, 42, 30)
local MOUSSE = Color3.fromRGB(78, 120, 58)
local BRAISE = Color3.fromRGB(255, 120, 40)
local VIOLET = Color3.fromRGB(190, 110, 255)
local ALERTE = Color3.fromRGB(235, 70, 50)

-- Ajoute une pièce ancrée, sans collision, placée par rapport au pied du boss.
local function piece(modele, nom, taille, couleur, materiau, cf, base, forme)
	local p = Instance.new("Part")
	p.Name = nom
	p.Size = taille
	p.Color = couleur
	p.Material = materiau
	p.Anchored = true
	p.CanCollide = false
	p.CastShadow = true
	if forme then
		p.Shape = forme
	end
	p.CFrame = base * cf
	p.Parent = modele
	return p
end

-- Construit le Colosse (environ 24 studs de haut). Il regarde vers -Z.
function Colosse.creer(player, position, def)
	local modele = Instance.new("Model")
	modele.Name = "Boss_" .. player.Name
	local base = CFrame.new(position)
	local P = function(...)
		return piece(modele, ...)
	end
	local R = CFrame.Angles

	-- Jambes en souches, avec racines aux pieds.
	for _, x in { -2.6, 2.6 } do
		P("Jambe", Vector3.new(3, 8, 3), BOIS, Enum.Material.Wood, CFrame.new(x, 4, 0), base)
		for i = 0, 2 do
			local a = math.rad(i * 120 + (x > 0 and 30 or 0))
			P("Racine", Vector3.new(0.8, 0.8, 3.2), BOIS_FONCE, Enum.Material.Wood, CFrame.new(x + math.sin(a) * 1.8, 0.4, math.cos(a) * 1.8) * R(0, a, 0) * R(math.rad(-20), 0, 0), base)
		end
	end

	-- Tronc (le « corps » : barre de vie, flash d'impact, distance de frappe).
	local tronc = P("Corps", Vector3.new(8, 10, 5.5), BOIS, Enum.Material.Wood, CFrame.new(0, 13, 0), base)
	P("Ecorce", Vector3.new(8.4, 2, 5.9), BOIS_FONCE, Enum.Material.Wood, CFrame.new(0, 9, 0), base)

	-- Cœur : invisible en phase 1, brasier en phase 2.
	local coeur = P("Coeur", Vector3.new(3, 3, 3), BRAISE, Enum.Material.Neon, CFrame.new(0, 13.5, -2.4), base, Enum.PartType.Ball)
	coeur.Transparency = 1

	-- Tête en écorce, yeux ambrés, bouche sombre.
	P("Tete", Vector3.new(4.5, 4.5, 4), BOIS, Enum.Material.Wood, CFrame.new(0, 20.2, -0.3), base)
	for _, x in { -1, 1 } do
		P("Oeil", Vector3.new(0.9, 0.9, 0.4), Color3.fromRGB(255, 190, 70), Enum.Material.Neon, CFrame.new(x, 20.8, -2.4), base)
	end
	P("Bouche", Vector3.new(2.4, 0.6, 0.3), Color3.fromRGB(20, 12, 8), Enum.Material.SmoothPlastic, CFrame.new(0, 19.1, -2.35), base)

	-- Couronne de branches.
	for i = -2, 2 do
		P("Branche", Vector3.new(0.6, 4, 0.6), BOIS_FONCE, Enum.Material.Wood, CFrame.new(i * 1.1, 24, 0) * R(0, 0, math.rad(-i * 18)), base)
	end

	-- Épaules couvertes de mousse et de pierres.
	for _, x in { -4.8, 4.8 } do
		P("Mousse", Vector3.new(3.4, 1.6, 4), MOUSSE, Enum.Material.Grass, CFrame.new(x, 17.6, 0), base)
		P("Pierre", Vector3.new(2.2, 2.2, 2.2), Color3.fromRGB(110, 110, 105), Enum.Material.Slate, CFrame.new(x * 1.05, 18.6, 0.6) * R(0.4, 0.6, 0.2), base)
	end

	-- Bras-fouets : un bras de bois puis trois segments de ronces avec épines.
	for _, cote in { -1, 1 } do
		local epaule = CFrame.new(cote * 5.6, 16.5, 0)
		P("Bras", Vector3.new(2, 7, 2), BOIS, Enum.Material.Wood, epaule * R(0, 0, math.rad(cote * 25)) * CFrame.new(0, -3.2, 0), base)
		local main = epaule * R(0, 0, math.rad(cote * 25)) * CFrame.new(0, -6.6, 0)
		for i = 1, 3 do
			local seg = main * R(math.rad(-15 * i), 0, math.rad(cote * 12 * i)) * CFrame.new(0, -1.6 * i, -0.6 * i)
			P("Ronce", Vector3.new(0.9, 3, 0.9), Color3.fromRGB(70, 55, 35), Enum.Material.Wood, seg, base)
			P("Epine", Vector3.new(0.3, 0.3, 1.2), Color3.fromRGB(40, 30, 20), Enum.Material.Wood, seg * CFrame.new(0.5, 0, 0) * R(0, math.rad(90), 0), base)
		end
	end

	-- Lanternes violettes accrochées aux branches et au tronc.
	local lanternes = {}
	for _, pos in { Vector3.new(-3, 22.5, -1), Vector3.new(3.2, 22, -1), Vector3.new(-3.5, 14, -3), Vector3.new(3.5, 12, -3), Vector3.new(0, 10.5, -3) } do
		local l = P("Lanterne", Vector3.new(0.8, 1.1, 0.8), VIOLET, Enum.Material.Neon, CFrame.new(pos), base)
		local lumiere = Instance.new("PointLight")
		lumiere.Color = VIOLET
		lumiere.Range = 10
		lumiere.Brightness = 1.5
		lumiere.Parent = l
		table.insert(lanternes, l)
	end

	modele.WorldPivot = base
	modele.Parent = Workspace
	return modele, tronc
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
	e.phase = 1
	e.prochaineAttaque = maintenant + 2.5
	e.attaque = nil
	e.posReelle = e.modele:GetPivot().Position
	e.orientation = e.modele:GetPivot() - e.modele:GetPivot().Position -- rotation seule (sans les animations)
	e.elanJusqua = 0
	e.couleurTronc = BOIS
	e.cycle = 0
end

function Colosse.annulerAttaque(e, maintenant)
	nettoyerZones(e)
	e.attaque = nil
	e.prochaineAttaque = math.max(e.prochaineAttaque, maintenant + 1)
end

-- Passage en phase 2 : il s'embrase.
local function phase2(e, maintenant, ctx)
	e.phase = 2
	e.faiblesse = e.def.faiblesse2
	e.resistance = e.def.resistance2
	Colosse.annulerAttaque(e, maintenant)
	e.prochaineAttaque = maintenant + 1.8
	e.couleurTronc = Color3.fromRGB(70, 40, 28)
	for _, p in e.modele:GetChildren() do
		if p:IsA("BasePart") then
			if p.Name == "Corps" or p.Name == "Bras" or p.Name == "Ronce" or p.Name == "Tete" or p.Name == "Branche" then
				local feu = Instance.new("Fire")
				feu.Size = p.Name == "Corps" and 9 or 4
				feu.Heat = 8
				feu.Color = BRAISE
				feu.SecondaryColor = VIOLET
				feu.Parent = p
				if p.Name ~= "Corps" then
					p.Color = Color3.fromRGB(70, 40, 28)
				end
			elseif p.Name == "Coeur" then
				p.Transparency = 0
				local lumiere = Instance.new("PointLight")
				lumiere.Color = BRAISE
				lumiere.Range = 18
				lumiere.Brightness = 3
				lumiere.Parent = p
			elseif p.Name == "Lanterne" or p.Name == "Oeil" then
				p.Color = BRAISE
			end
		end
	end
	ctx.envoyer({ type = "phase", numero = 2, nom = e.def.nom })
end

-- Lance une attaque : zone rouge, puis résolution après la préparation.
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

	local acc = e.phase == 2 and 0.85 or 1 -- en phase 2, il prépare plus vite
	local zones = {}
	local joueur = ctx.racine.Position
	local attaque
	if nom == "fouet" then
		local cf = CFrame.new(e.posReelle) * e.orientation
		table.insert(zones, zoneRectangle(e, cf, def.fouet.largeur, def.fouet.longueur))
		attaque = def.fouet
	elseif nom == "racines" then
		table.insert(zones, zoneDisque(e, joueur, def.racines.rayon))
		attaque = def.racines
	else
		table.insert(zones, zoneDisque(e, joueur, def.graines.rayon))
		for _ = 2, def.graines.nombre do
			local a = rng:NextNumber() * math.pi * 2
			local r = rng:NextNumber(5, 11)
			table.insert(zones, zoneDisque(e, joueur + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r), def.graines.rayon))
		end
		attaque = def.graines
	end
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
	ctx.envoyer({ type = "frappeBoss", attaque = e.attaque.nom })
	if touche then
		ctx.frapper(e.attaque.degats)
	else
		ctx.envoyer({ type = "esquive" })
	end
	-- Éclat visuel bref à la place des zones.
	for _, zone in e.attaque.zones do
		local p = zone.part
		p.Color = Color3.fromRGB(255, 200, 120)
		p.Transparency = 0.2
		TweenService:Create(p, TweenInfo.new(0.35), { Transparency = 1 }):Play()
		Debris:AddItem(p, 0.4)
	end
	e.attaque = nil
	e.elanJusqua = maintenant + 0.25
	e.prochaineAttaque = maintenant + (e.phase == 2 and e.def.recharge2 or e.def.recharge)
end

function Colosse.mettreAJour(e, dt, maintenant, ctx)
	local def = e.def
	if e.phase == 1 and e.pv <= e.pvMax * def.phase2 then
		phase2(e, maintenant, ctx)
	end

	local pos = e.posReelle
	local cible = Vector3.new(ctx.racine.Position.X, pos.Y, ctx.racine.Position.Z)
	local vers = cible - pos
	local dist = vers.Magnitude
	local etourdi = maintenant < e.etourdiFin
	local nouvellePos = pos

	if e.attaque then
		if maintenant >= e.attaque.fin then
			resoudreAttaque(e, maintenant, ctx)
		end
	elseif not etourdi then
		local arret = 9
		if dist > arret and dist > 0.01 then
			local vitesse = (e.phase == 2 and def.vitesse2 or def.vitesse) * (maintenant < e.ralentiFin and 0.6 or 1)
			nouvellePos = pos + vers.Unit * math.min(dist - arret, vitesse * dt)
		end
		if maintenant >= e.prochaineAttaque and dist <= 26 then
			lancerAttaque(e, maintenant, ctx, dist)
		end
	end
	e.posReelle = nouvellePos

	-- Animation : penché en arrière pendant la préparation, élan vers l'avant à la frappe,
	-- léger balancement en marchant. Il ne se tourne pas pendant le fouet (la zone est fixe).
	if not (e.attaque and e.attaque.nom == "fouet") and dist > 0.01 then
		local regard = CFrame.lookAt(Vector3.zero, Vector3.new(vers.X, 0, vers.Z))
		e.orientation = e.orientation:Lerp(regard, math.min(1, dt * 6)) -- se tourne en douceur
	end
	local base = CFrame.new(nouvellePos) * e.orientation
	if e.attaque then
		base *= CFrame.Angles(math.rad(8), 0, 0)
	elseif maintenant < e.elanJusqua then
		base *= CFrame.new(0, 0, -2) * CFrame.Angles(math.rad(-10), 0, 0)
	else
		base *= CFrame.Angles(0, 0, math.rad(math.sin(maintenant * 3) * 2))
	end
	e.modele:PivotTo(base)

	-- Couleur du tronc : flash d'impact, alerte, gel ou normale.
	if maintenant >= e.flashJusqua then
		if e.attaque then
			e.corps.Color = ALERTE
		elseif maintenant < e.ralentiFin then
			e.corps.Color = Color3.fromRGB(140, 190, 220)
		else
			e.corps.Color = e.couleurTronc
		end
	end
end

-- Mort : il s'effondre en morceaux. Autre fin : il disparaît.
function Colosse.detruire(e, raison)
	nettoyerZones(e)
	e.attaque = nil
	if raison ~= "victoire" then
		e.modele:Destroy()
		return
	end
	local centre = e.modele:GetPivot().Position
	for _, p in e.modele:GetChildren() do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = true
			local dir = (p.Position - centre) * Vector3.new(1, 0, 1)
			if dir.Magnitude < 0.1 then
				dir = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1))
			end
			p.AssemblyLinearVelocity = dir.Unit * rng:NextNumber(8, 18) + Vector3.new(0, rng:NextNumber(10, 25), 0)
		end
	end
	local barre = e.corps:FindFirstChild("BarreVie")
	if barre then
		barre:Destroy()
	end
	Debris:AddItem(e.modele, 5)
end

return Colosse
