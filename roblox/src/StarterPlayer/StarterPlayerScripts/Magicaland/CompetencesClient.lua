-- Compétences du feu côté client (mission combat, étape 4), touches 1 à 6.
-- Prédiction : l'animation part dès l'appui ; les effets suivent les MARQUEURS de l'animation (« Contact »...), donc
-- la lame et l'effet sont synchronisés à l'image près. Le serveur décide (recharge, direction, dégâts) et envoie les
-- effets aux autres joueurs (EpeeFx). Effets réalistes (particules de feu, fumée, lumière), sans contour dessiné ;
-- le ciel n'est jamais touché. Option de confort (attribut PIPE_Confort) : pas de tremblement ni de zoom de caméra.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local joueur = Players.LocalPlayer
local dossier = ReplicatedStorage:WaitForChild("Magicaland")
local CF = require(dossier:WaitForChild("CompetencesFeu"))
local remotes = dossier:WaitForChild("Remotes")
local Competence = remotes:WaitForChild("Competence")
local EpeeFx = remotes:WaitForChild("EpeeFx")
local pipe = ReplicatedStorage:WaitForChild("PIPE_Epee")
local FX = require(pipe:WaitForChild("FX"))
local RFX = require(pipe:WaitForChild("RealFX"))

local M = {}
local EpeeClient -- branché par Client (M.brancher)
local pret = {} -- [n] = heure locale de fin de recharge
local enCours = nil -- { n, piste, fin, annule, contact }
local pistes, persoPistes = {}, nil
local vagues = {} -- [Player] = vague affichée (pour l'arrêter à l'impact)

local function confort()
	return joueur:GetAttribute(CF.ATTRIBUT_CONFORT) == true
end

local function NS(...)
	local k, v = {}, { ... }
	for i = 1, #v, 2 do
		table.insert(k, NumberSequenceKeypoint.new(v[i], v[i + 1]))
	end
	return NumberSequence.new(k)
end
local function CS(...)
	local k, v = {}, { ... }
	for i = 1, #v, 2 do
		table.insert(k, ColorSequenceKeypoint.new(v[i], v[i + 1]))
	end
	return ColorSequence.new(k)
end

local FEU = CS(0, Color3.fromRGB(255, 236, 190), 0.25, Color3.fromRGB(255, 160, 60), 0.7, Color3.fromRGB(200, 70, 25), 1, Color3.fromRGB(70, 25, 15))

---------------------------------------------------------------------
-- Animation
---------------------------------------------------------------------
local function piste(perso, nomSeq)
	if persoPistes ~= perso then
		pistes, persoPistes = {}, perso
	end
	if pistes[nomSeq] then
		return pistes[nomSeq]
	end
	local hum = perso:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	local seq = pipe.Sequences:FindFirstChild(nomSeq)
	if not animator or not seq then
		return nil
	end
	local a = Instance.new("Animation")
	local publie = seq:GetAttribute("AnimationId")
	a.AnimationId = (publie and publie ~= "") and publie or KeyframeSequenceProvider:RegisterKeyframeSequence(seq)
	local tr = animator:LoadAnimation(a)
	tr.Priority = Enum.AnimationPriority.Action4
	tr.Looped = false
	pistes[nomSeq] = tr
	return tr
end

local function cible()
	local m = Workspace:FindFirstChild("Monstre_" .. joueur.Name) or Workspace:FindFirstChild("Boss_" .. joueur.Name)
	return m and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart)
end

local function pointeLame(perso)
	local s = perso:FindFirstChild("PIPE_Sword")
	local b = s and s:FindFirstChild("Blade")
	return b and (b.CFrame * CFrame.new(0, 1.55, 0)).Position
end

local function solSous(pos, exclus)
	local p = RaycastParams.new()
	p.FilterType = Enum.RaycastFilterType.Exclude
	p.FilterDescendantsInstances = exclus
	local r = Workspace:Raycast(pos + Vector3.new(0, 3, 0), Vector3.new(0, -14, 0), p)
	return r and r.Position.Y or pos.Y
end

---------------------------------------------------------------------
-- Effets du Sillon de braise
---------------------------------------------------------------------
-- Braises qui se détachent de la lame pendant l'armé (pas d'aura permanente : seulement pendant la compétence).
local function braisesLame(perso, duree)
	local s = perso:FindFirstChild("PIPE_Sword")
	local b = s and s:FindFirstChild("Blade")
	if not b then
		return
	end
	local att = Instance.new("Attachment")
	att.Name = "PIPE_BraisesLame"
	att.Position = Vector3.new(0, 0.4, 0)
	att.Parent = b
	local e = Instance.new("ParticleEmitter")
	e.Texture = RFX.TEX.fireSpark
	e.Color = CS(0, Color3.fromRGB(255, 220, 160), 1, Color3.fromRGB(255, 110, 40))
	e.LightEmission = 1
	e.Size = NS(0, 0.12, 1, 0)
	e.Lifetime = NumberRange.new(0.35, 0.7)
	e.Speed = NumberRange.new(1, 3)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, 5, 0)
	e.Rate = 30 * RFX.Echelle
	e.Shape = Enum.ParticleEmitterShape.Box
	e.Parent = att
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 140, 60)
	l.Range = 6
	l.Brightness = 0
	l.Parent = att
	RFX.animate(duree, function(a)
		l.Brightness = 1.2 * a
	end)
	task.delay(duree, function()
		e.Enabled = false
		l.Enabled = false
		task.delay(0.8, function()
			att:Destroy()
		end)
	end)
end

local function emetteur(parent, props)
	local e = Instance.new("ParticleEmitter")
	for k, v in props do
		e[k] = v
	end
	e.Parent = parent
	return e
end

-- La vague : un front de flammes au ras du sol qui avance, une traînée brûlée qui s'efface derrière lui.
local function creerVague(proprio, origine, dir, vitesse, portee, ecoule)
	local ancienne = vagues[proprio]
	if ancienne then
		ancienne.arreter()
	end
	local cf0 = CFrame.lookAt(origine, origine + dir)
	local front = RFX.part({ Name = "PIPE_Vague", Size = Vector3.new(2.6, 0.4, 1.4), CFrame = cf0 })
	local ech = RFX.Echelle
	local flammes = emetteur(front, { Texture = RFX.TEX.fire, Color = FEU, LightEmission = 0.85, LightInfluence = 0,
		Size = NS(0, 1.4, 0.4, 2.3, 1, 0.5), Transparency = NS(0, 0.25, 0.6, 0.45, 1, 1),
		Lifetime = NumberRange.new(0.22, 0.42), Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(25, 25),
		EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, 7, 0), Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-120, 120), Rate = 170 * ech, Shape = Enum.ParticleEmitterShape.Box,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume })
	local braises = emetteur(front, { Texture = RFX.TEX.fireSpark, Color = CS(0, Color3.fromRGB(255, 225, 170), 1, Color3.fromRGB(255, 100, 35)),
		LightEmission = 1, Size = NS(0, 0.16, 1, 0), Lifetime = NumberRange.new(0.4, 0.8), Speed = NumberRange.new(5, 12),
		SpreadAngle = Vector2.new(60, 60), EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, -14, 0),
		Drag = 2, Rate = 45 * ech })
	local fumee = emetteur(front, { Texture = RFX.TEX.smoke, Color = ColorSequence.new(Color3.fromRGB(45, 40, 38)),
		LightInfluence = 1, Size = NS(0, 1.5, 1, 4.5), Transparency = NS(0, 0.65, 0.4, 0.7, 1, 1),
		Lifetime = NumberRange.new(0.8, 1.4), Speed = NumberRange.new(1.5, 4), EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0, 2.5, 0), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-30, 30),
		Rate = 22 * ech })
	local lumiere = Instance.new("PointLight")
	lumiere.Color = Color3.fromRGB(255, 140, 55)
	lumiere.Range = 14
	lumiere.Brightness = 3
	lumiere.Parent = front

	local v = { fini = false }
	local derniereTrace = 0
	local t0 = os.clock() - (ecoule or 0)
	local conn
	local function trace(d)
		-- sol brûlé (sombre) et fine ligne de braises qui refroidit
		local pos = origine + dir * d
		local cf = CFrame.lookAt(pos, pos + dir)
		local brule = RFX.part({ Name = "PIPE_Brulure", Transparency = 0.2, Material = Enum.Material.Slate,
			Color = Color3.fromRGB(30, 24, 21), Size = Vector3.new(2.0 + math.random() * 0.6, 0.05, 1.7), CFrame = cf * CFrame.new(0, 0.03, 0) })
		local ligne = RFX.part({ Name = "PIPE_Braise", Transparency = 0.1, Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 120, 45), Size = Vector3.new(0.14, 0.06, 1.7), CFrame = cf * CFrame.new((math.random() - 0.5) * 0.4, 0.05, 0) })
		RFX.animate(0.9, function(a)
			ligne.Transparency = 0.1 + 0.9 * a
			ligne.Color = Color3.fromRGB(255, 120 - 80 * a, 45 - 30 * a)
		end, function()
			ligne:Destroy()
		end)
		task.delay(1.2, function()
			RFX.animate(1.3, function(a)
				brule.Transparency = 0.2 + 0.8 * a
			end, function()
				brule:Destroy()
			end)
		end)
	end
	function v.arreter()
		if v.fini then
			return
		end
		v.fini = true
		if conn then
			conn:Disconnect()
		end
		flammes.Enabled, braises.Enabled, fumee.Enabled = false, false, false
		RFX.animate(0.3, function(a)
			lumiere.Brightness = 3 * (1 - a)
		end)
		task.delay(1.5, function()
			front:Destroy()
		end)
		if vagues[proprio] == v then
			vagues[proprio] = nil
		end
	end
	conn = RunService.RenderStepped:Connect(function()
		local d = math.min((os.clock() - t0) * vitesse, portee)
		front.CFrame = cf0 + dir * d
		while derniereTrace + 1.6 <= d do
			derniereTrace += 1.6
			trace(derniereTrace)
		end
		if d >= portee then
			v.arreter()
		end
	end)
	vagues[proprio] = v
	return v
end

local function explosion(pos, proprio)
	RFX.SansLimite += 1 -- explosion d'une compétence : un peu plus longue que l'impact d'un coup
	RFX.Explosion(pos + Vector3.new(0, 0.5, 0), 1.15)
	-- colonne de flammes qui monte (le feu « explose » vers le haut, pas une boule dessinée)
	RFX.burst(pos + Vector3.new(0, 1, 0), { Texture = RFX.TEX.fire, Color = FEU, LightEmission = 0.9,
		Size = NS(0, 2.5, 0.5, 4.5, 1, 1.5), Transparency = NS(0, 0.1, 0.7, 0.4, 1, 1), Lifetime = NumberRange.new(0.5, 0.9),
		Speed = NumberRange.new(14, 26), SpreadAngle = Vector2.new(18, 18), EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0, -6, 0), Drag = 3, Rotation = NumberRange.new(0, 360) }, 22, 2)
	task.delay(1.6, function()
		RFX.SansLimite -= 1
	end)
	FX.Sound(FX.Sounds.final, pos, 0.9, 0.75)
	if proprio == joueur and not confort() then
		FX.Shake(0.6, 0.3)
	end
end

---------------------------------------------------------------------
-- Lancer (touche)
---------------------------------------------------------------------
local function liberer(perso, verrou)
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	if hum and verrou then
		hum.WalkSpeed = verrou.vitesse
		hum.AutoRotate = verrou.auto
	end
	if EpeeClient then
		EpeeClient.occupeJusqua = 0
	end
end

function M.lancer(n)
	local def = CF.liste[n]
	if not def or not EpeeClient or not EpeeClient.actif() then
		return
	end
	local maintenant = os.clock()
	if enCours or EpeeClient.occupe() then
		return
	end
	if maintenant < (pret[n] or 0) then
		M.signalRecharge(n)
		return
	end
	local perso = joueur.Character
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	local hrp = perso and perso:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.Health <= 0 then
		return
	end
	local tr = piste(perso, def.seq)
	if not tr then
		return
	end
	pret[n] = maintenant + def.recharge
	EpeeClient.annulerCombo()
	EpeeClient.occupeJusqua = maintenant + def.duree
	-- face à la cible
	local c = cible()
	if c then
		local plat = Vector3.new(c.Position.X, hrp.Position.Y, c.Position.Z)
		if (plat - hrp.Position).Magnitude > 0.5 then
			hrp.CFrame = CFrame.lookAt(hrp.Position, plat)
		end
	end
	local verrou = { vitesse = hum.WalkSpeed, auto = hum.AutoRotate }
	hum.WalkSpeed = 0
	hum.AutoRotate = false
	local action = { n = n, piste = tr, annule = false, contact = false }
	enCours = action
	Competence:FireServer(n)
	tr:Play(0.06)
	braisesLame(perso, def.contact)
	if not confort() then
		task.delay(0.14, function()
			if not action.annule then
				FX.Zoom(64, 0.3)
			end
		end)
	end
	local conns = {}
	table.insert(conns, tr:GetMarkerReachedSignal("Contact"):Connect(function()
		if action.annule or action.contact then
			return
		end
		action.contact = true
		action.tContact = os.clock()
		FX.Zoom(70, 0.15)
		-- Point d'impact = là où la lame se pose dans l'animation (mesuré : 6,9 studs devant, 0,95 à droite).
		-- (Lire la lame ici donnerait la pose de l'image précédente : la pose du marqueur s'affiche à l'image suivante.)
		local v = def.vague
		local avant = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
		avant = avant.Magnitude > 0.01 and avant.Unit or Vector3.new(0, 0, -1)
		local droite = Vector3.new(-avant.Z, 0, avant.X)
		local exclus = { perso, Workspace:FindFirstChild("PIPE_FX") }
		local depart = hrp.Position + avant * v.avance + droite * v.decalage
		local origine = Vector3.new(depart.X, solSous(depart, exclus), depart.Z)
		local impact = origine
		RFX.Sparks(impact + Vector3.new(0, 0.3, 0), 18)
		RFX.Dust(impact, 0.8)
		FX.Sound(FX.Sounds.swingHeavy, impact, 0.8, 0.85)
		FX.Sound(FX.Sounds.hitMetal, impact, 0.5, 0.6)
		if not confort() then
			FX.Shake(0.35, 0.2)
		end
		-- vague prédite (même calcul que le serveur : départ devant le joueur, vers la cible si elle est devant)
		local dir = avant
		local ci = cible()
		if ci then
			local vers = (ci.Position - hrp.Position) * Vector3.new(1, 0, 1)
			if vers.Magnitude > 0.5 and math.deg(math.acos(math.clamp(vers.Unit:Dot(avant), -1, 1))) <= v.angleMax then
				dir = vers.Unit
			end
		end
		creerVague(joueur, origine, dir, v.vitesse, v.portee, 0)
		joueur:SetAttribute("PIPE_TestContact", os.clock()) -- mesures des tests (écart marqueur / vague)
		task.spawn(function()
			task.wait() -- image suivante : la pose du contact est affichée
			local pointe = pointeLame(perso)
			if pointe then
				joueur:SetAttribute("PIPE_TestEcartPointe", (Vector3.new(pointe.X, origine.Y, pointe.Z) - origine).Magnitude)
				joueur:SetAttribute("PIPE_TestHauteurPointe", pointe.Y - origine.Y)
			end
		end)
	end))
	local function finir()
		for _, cn in conns do
			cn:Disconnect()
		end
		if enCours == action then
			enCours = nil
		end
		liberer(perso, verrou)
	end
	action.annuler = function()
		if action.contact then
			return
		end
		action.annule = true
		tr:Stop(0.1)
		FX.Zoom(70, 0.15)
		finir()
	end
	task.delay(def.duree / math.max(0.01, tr.Speed), function()
		if enCours == action then
			finir()
		end
	end)
end

-- Un dash avant le contact annule la compétence (le serveur fait pareil).
function M.surDash()
	if enCours and enCours.annuler then
		enCours.annuler()
	end
end

---------------------------------------------------------------------
-- Effets reçus du serveur
---------------------------------------------------------------------
EpeeFx.OnClientEvent:Connect(function(m)
	if type(m) ~= "table" then
		return
	end
	if m.type == "vague" then
		if m.joueur == joueur then
			return -- déjà affichée (prédite au marqueur « Contact »)
		end
		local moi = joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart")
		if moi and (moi.Position - m.origine).Magnitude > 150 then
			return
		end
		creerVague(m.joueur, m.origine, m.dir, m.vitesse, m.portee, math.max(0, Workspace:GetServerTimeNow() - m.t0))
	elseif m.type == "vague_impact" then
		local v = vagues[m.joueur]
		if v then
			v.arreter()
		end
		explosion(m.pos, m.joueur)
		if m.joueur == joueur then
			joueur:SetAttribute("PIPE_TestImpact", os.clock())
		end
	elseif m.type == "vague_fin" then
		local v = vagues[m.joueur]
		if v then
			v.arreter()
		end
	elseif m.type == "competence_refus" and m.joueur == joueur then
		pret[m.n] = os.clock() + (m.reste or 0)
	end
end)

---------------------------------------------------------------------
-- Interface : barre des 6 compétences (recharge) et bouton de confort
---------------------------------------------------------------------
local cases = {}
local signalJusqua = {}
function M.signalRecharge(n)
	signalJusqua[n] = os.clock() + 0.35
	local r = joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart")
	if r then
		FX.Sound(FX.Sounds.swingLight, r.Position, 0.15, 0.5)
	end
end

local function creerInterface()
	local gui = Instance.new("ScreenGui")
	gui.Name = "PIPE_Competences"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	local barre = Instance.new("Frame")
	barre.Name = "Barre"
	barre.BackgroundTransparency = 1
	barre.AnchorPoint = Vector2.new(0.5, 1)
	barre.Position = UDim2.new(0.5, 0, 1, -96)
	barre.Size = UDim2.fromOffset(6 * 50, 46)
	barre.Parent = gui
	for n = 1, 6 do
		local def = CF.liste[n]
		local c = Instance.new("TextButton")
		c.Name = "Case" .. n
		c.AutoButtonColor = false
		c.Size = UDim2.fromOffset(44, 44)
		c.Position = UDim2.fromOffset((n - 1) * 50, 0)
		c.BackgroundColor3 = def and Color3.fromRGB(40, 22, 16) or Color3.fromRGB(25, 25, 28)
		c.BackgroundTransparency = def and 0.15 or 0.55
		c.Text = tostring(n)
		c.TextColor3 = def and Color3.fromRGB(255, 200, 150) or Color3.fromRGB(110, 110, 115)
		c.Font = Enum.Font.GothamBold
		c.TextSize = 16
		c.TextYAlignment = Enum.TextYAlignment.Top
		local coin = Instance.new("UICorner")
		coin.CornerRadius = UDim.new(0, 6)
		coin.Parent = c
		local trait = Instance.new("UIStroke")
		trait.Color = def and Color3.fromRGB(255, 130, 60) or Color3.fromRGB(70, 70, 75)
		trait.Thickness = 1.5
		trait.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		trait.Parent = c
		local voile = Instance.new("Frame")
		voile.Name = "Recharge"
		voile.BackgroundColor3 = Color3.new(0, 0, 0)
		voile.BackgroundTransparency = 0.35
		voile.AnchorPoint = Vector2.new(0, 1)
		voile.Position = UDim2.fromScale(0, 1)
		voile.Size = UDim2.fromScale(1, 0)
		voile.BorderSizePixel = 0
		voile.Parent = c
		local reste = Instance.new("TextLabel")
		reste.Name = "Reste"
		reste.BackgroundTransparency = 1
		reste.Size = UDim2.fromScale(1, 0.6)
		reste.Position = UDim2.fromScale(0, 0.4)
		reste.Text = ""
		reste.TextColor3 = Color3.new(1, 1, 1)
		reste.Font = Enum.Font.GothamBold
		reste.TextSize = 14
		reste.Parent = c
		c.Activated:Connect(function()
			M.lancer(n)
		end)
		c.Parent = barre
		cases[n] = { bouton = c, voile = voile, reste = reste, trait = trait }
	end
	local opt = Instance.new("TextButton")
	opt.Name = "Confort"
	opt.AnchorPoint = Vector2.new(1, 0)
	opt.Position = UDim2.new(1, -12, 0, 52)
	opt.Size = UDim2.fromOffset(150, 28)
	opt.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	opt.BackgroundTransparency = 0.25
	opt.TextColor3 = Color3.fromRGB(220, 220, 225)
	opt.Font = Enum.Font.Gotham
	opt.TextSize = 13
	local coin = Instance.new("UICorner")
	coin.CornerRadius = UDim.new(0, 6)
	coin.Parent = opt
	local function majTexte()
		opt.Text = confort() and "Confort : OUI (moins d'effets)" or "Confort : NON"
	end
	majTexte()
	opt.Activated:Connect(function()
		joueur:SetAttribute(CF.ATTRIBUT_CONFORT, not confort())
		majTexte()
	end)
	opt.Parent = gui
	gui.Parent = joueur:WaitForChild("PlayerGui")
	return gui
end

local gui
RunService.RenderStepped:Connect(function()
	if not gui then
		return
	end
	local actif = EpeeClient and EpeeClient.actif()
	gui.Enabled = actif == true
	if not actif then
		return
	end
	local t = os.clock()
	for n, c in cases do
		local def = CF.liste[n]
		if def then
			local r = math.max(0, (pret[n] or 0) - t)
			c.voile.Size = UDim2.fromScale(1, r / def.recharge)
			c.reste.Text = r > 0 and string.format("%.1f", r) or ""
			c.trait.Color = t < (signalJusqua[n] or 0) and Color3.fromRGB(255, 60, 50) or Color3.fromRGB(255, 130, 60)
		end
	end
end)

function M.brancher(epeeClient)
	EpeeClient = epeeClient
	EpeeClient.surDash = M.surDash
	gui = creerInterface()
end

return M
