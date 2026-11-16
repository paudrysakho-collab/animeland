-- Effets du pipeline (etapes 5b + 8a : effets REALISTES, plus aucun flipbook dessine). Tout ce qui est cree porte le prefixe PIPE_.
-- Le ciel n'est JAMAIS modifie (ni Sky, ni Atmosphere, ni proprietes de Lighting).
-- Seul objet ajoute dans Lighting : PIPE_FX_CC (ColorCorrection), cree pendant un effet et SUPPRIME des que plus aucun
-- effet n'est actif.
-- FX.Setup(rig) ; FX.MoveStart(rig, mv) ; FX.Swing(rig, on, mv) ; FX.Hit(rig, point, kind) ; FX.Impact(rig, point, track)
-- FX.UpdateCamera() (a chaque image) ; FX.Cleanup()
local Lighting = game:GetService("Lighting")
local FX = {}
local RFX = require(script.Parent:WaitForChild("RealFX"))
-- Palette de l'élément (préparation du système d'éléments : ProfilCombat). Aujourd'hui : feu pour tous.
local Profil = require(game:GetService("ReplicatedStorage"):WaitForChild("Magicaland"):WaitForChild("ProfilCombat"))
local FEU = Profil.ELEMENTS.feu.palette

FX.Sounds = {
	swingLight = "rbxassetid://91355094276522",
	swingHeavy = "rbxassetid://133924388399467",
	hitMetal = "rbxassetid://135531146395796",
	hitFlesh = "rbxassetid://129266577312737",
	final = "rbxassetid://114886581492786",
	kick = "rbxassetid://110864202516797",
}
-- flipbooks 4x4 (images de 256 px dans une texture 1024x1024), style dessine
FX.Flip = {
	lightning = "rbxassetid://93449923507458",
	slash = "rbxassetid://107229986654122",
	impact = "rbxassetid://108368299692402",
	impactGold = "rbxassetid://109164167367508",
	smoke = "rbxassetid://97427184441471",
}
FX.DashMoves = {attack = true, attack_2 = true, attack_3 = true, slash_2 = true, slash_4 = true}

-- Petite bouffee de flammes (budget de particules du coup respecte par RFX.burst).
local function flammeche(point, n)
	RFX.burst(point, {Texture = RFX.TEX.fire, Color = RFX.CS(0, FEU.etincelle, 1, FEU.flamme), LightEmission = 0.9, LightInfluence = 0,
		Size = RFX.NS(0, 0.6, 1, 1.4), Transparency = RFX.NS(0, 0.2, 1, 1), Lifetime = NumberRange.new(0.15, 0.3),
		Speed = NumberRange.new(3, 7), SpreadAngle = Vector2.new(180, 180), Drag = 5, Rotation = NumberRange.new(0, 360)}, n, 0.5)
end

local function fxFolder()
	local f = workspace:FindFirstChild("PIPE_FX")
	if not f then f = Instance.new("Folder"); f.Name = "PIPE_FX"; f.Parent = workspace end
	return f
end
local function newPart(props)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.Material = Enum.Material.Neon
	for k, v in pairs(props) do p[k] = v end
	p.Parent = fxFolder()
	return p
end
local function animate(dur, fn, done)
	task.spawn(function()
		local t0 = os.clock()
		while true do
			local a = (os.clock() - t0) / dur
			if a >= 1 then break end
			if not pcall(fn, a) then break end
			task.wait()
		end
		pcall(fn, 1)
		if done then pcall(done) end
	end)
end

-- ---------- ColorCorrection a compteur : jamais de reste dans Lighting ----------
local ccUsers = 0
local function ccAcquire()
	ccUsers += 1
	local c = Lighting:FindFirstChild("PIPE_FX_CC")
	if not c then c = Instance.new("ColorCorrectionEffect"); c.Name = "PIPE_FX_CC"; c.Parent = Lighting end
	return c
end
local function ccRelease()
	ccUsers = math.max(0, ccUsers - 1)
	if ccUsers == 0 then
		local c = Lighting:FindFirstChild("PIPE_FX_CC"); if c then c:Destroy() end
	end
end
local impactActive = 0

local function playSound(id, at, vol, speed)
	if not id or id == "" then return end
	local p = newPart({Name = "PIPE_SoundPart", Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2), CFrame = CFrame.new(at)})
	local s = Instance.new("Sound"); s.Name = "PIPE_Sound"; s.SoundId = id; s.Volume = vol or 0.8
	s.PlaybackSpeed = (speed or 1) * (0.95 + math.random() * 0.1); -- hauteur variee de +-5 % a chaque son
	 s.RollOffMaxDistance = 300; s.Parent = p
	s:Play()
	task.delay(5, function() p:Destroy() end)
end
FX.Sound = playSound

-- ---------- lecteur de flipbook (BillboardGui face camera) ----------
local function flip(id, at, size, dur, opts)
	opts = opts or {}
	local p = newPart({Name = "PIPE_FlipAnchor", Transparency = 1, Size = Vector3.new(0.1, 0.1, 0.1), CFrame = CFrame.new(at)})
	local bb = Instance.new("BillboardGui"); bb.Name = "PIPE_Flip"
	bb.Size = UDim2.fromScale(size, size); bb.LightInfluence = 0; bb.AlwaysOnTop = opts.onTop == true
	bb.Adornee = p; bb.Parent = p
	local img = Instance.new("ImageLabel")
	img.Size = UDim2.fromScale(1, 1); img.BackgroundTransparency = 1; img.Image = id
	img.ImageRectSize = Vector2.new(256, 256); img.Rotation = opts.rotation or 0
	img.ImageColor3 = opts.color or Color3.new(1, 1, 1)
	img.Parent = bb
	animate(dur, function(a)
		local f = math.clamp(math.floor(a * 16), 0, 15)
		img.ImageRectOffset = Vector2.new((f % 4) * 256, math.floor(f / 4) * 256)
		if opts.follow then p.CFrame = CFrame.new(opts.follow()) end
	end, function() p:Destroy() end)
end
FX.PlayFlip = flip

-- ---------- camera ----------
local shakeUntil, shakeAmp, camBase, fovBase = 0, 0, nil, nil
function FX.Shake(amp, dur)
	local cam = workspace.CurrentCamera
	if os.clock() >= shakeUntil then camBase = cam.CFrame; shakeAmp = 0 end
	shakeAmp = math.max(shakeAmp, amp)
	shakeUntil = math.max(shakeUntil, os.clock() + dur)
end
function FX.UpdateCamera()
	local cam = workspace.CurrentCamera
	if not camBase then return end
	if os.clock() < shakeUntil then
		local r = function() return (math.random() * 2 - 1) * shakeAmp end
		cam.CFrame = camBase * CFrame.new(r(), r(), 0) * CFrame.Angles(r() * 0.02, r() * 0.02, r() * 0.03)
	else
		cam.CFrame = camBase; camBase = nil
	end
end
function FX.Zoom(fovTo, dur)
	local cam = workspace.CurrentCamera
	fovBase = fovBase or cam.FieldOfView
	local base = fovBase
	animate(dur, function(a)
		local k = a < 0.3 and (a / 0.3) or (1 - (a - 0.3) / 0.7)
		cam.FieldOfView = base + (fovTo - base) * k
	end, function() cam.FieldOfView = base; fovBase = nil end)
end

-- ---------- rig ----------
function FX.Setup(rig)
	local sword = rig:FindFirstChild("PIPE_Sword")
	local blade = sword and sword:FindFirstChild("Blade")
	if blade and not blade:FindFirstChild("PIPE_Braises") then
		-- Feu discret pendant les coups, AUCUNE aura permanente : emetteurs a 0 par seconde, declenches par FX.Swing.
		-- (Plus de trainee blanche.)
		local b = Instance.new("ParticleEmitter"); b.Name = "PIPE_Braises"; b.Rate = 0; b.Texture = RFX.TEX.fireSpark
		b.Color = RFX.CS(0, FEU.etincelle, 0.6, FEU.flamme, 1, FEU.braise); b.LightEmission = 1; b.LightInfluence = 0
		b.Size = RFX.NS(0, 0.14, 1, 0); b.Lifetime = NumberRange.new(0.2, 0.4); b.Speed = NumberRange.new(2, 6)
		b.SpreadAngle = Vector2.new(180, 180); b.Acceleration = Vector3.new(0, 8, 0); b.Drag = 4; b.Transparency = RFX.NS(0, 0, 1, 1)
		b.Parent = blade
		local f = Instance.new("ParticleEmitter"); f.Name = "PIPE_Flammeches"; f.Rate = 0; f.Texture = RFX.TEX.fire
		f.Color = RFX.CS(0, FEU.etincelle, 1, FEU.flamme); f.LightEmission = 0.8; f.LightInfluence = 0
		f.Size = RFX.NS(0, 0.35, 1, 0); f.Lifetime = NumberRange.new(0.12, 0.22); f.Speed = NumberRange.new(0.5, 1.5)
		f.Transparency = RFX.NS(0, 0.3, 1, 1); f.Rotation = NumberRange.new(0, 360); f.Parent = blade
	end
	local head = rig:FindFirstChild("Head")
	if head and not head:FindFirstChild("PIPE_EyeL") then
		for _, side in ipairs({{"PIPE_EyeL", -0.2}, {"PIPE_EyeR", 0.2}}) do
			local e = Instance.new("Part"); e.Name = side[1]
			e.Size = Vector3.new(0.16, 0.07, 0.05); e.Material = Enum.Material.Neon; e.Color = FEU.etincelle
			e.Transparency = 1; e.CanCollide = false; e.CanQuery = false; e.CanTouch = false; e.Massless = true
			e.CFrame = head.CFrame * CFrame.new(side[2], 0.12, -0.585)
			local w = Instance.new("Weld"); w.Part0 = head; w.Part1 = e; w.C0 = CFrame.new(side[2], 0.12, -0.585); w.Parent = e
			local l = Instance.new("PointLight"); l.Name = "PIPE_EyeLight"; l.Color = e.Color; l.Range = 4; l.Brightness = 3; l.Enabled = false; l.Parent = e
			e.Parent = head
		end
	end
end

local function groundUnder(rig, point)
	local hrp = rig.HumanoidRootPart
	return Vector3.new(point.X, hrp.Position.Y - rig.Humanoid.HipHeight - hrp.Size.Y / 2, point.Z)
end

function FX.MoveStart(rig, mv)
	if mv and FX.DashMoves[mv.short] then
		local hrp = rig.HumanoidRootPart
		local g = groundUnder(rig, hrp.Position)
		RFX.Dust(g - hrp.CFrame.LookVector * 0.8, 0.8)
	end
end

-- Coups de base : un feu discret part de la lame au debut du geste (braises + petites flammes) et le souffle.
local enCours = setmetatable({}, {__mode = "k"})
function FX.Swing(rig, on, mv)
	local sword = rig:FindFirstChild("PIPE_Sword")
	local blade = sword and sword:FindFirstChild("Blade")
	if not blade or enCours[rig] == on then return end
	enCours[rig] = on
	if on then
		local braises, flammes = blade:FindFirstChild("PIPE_Braises"), blade:FindFirstChild("PIPE_Flammeches")
		if braises then braises:Emit(math.max(2, math.floor(8 * RFX.Echelle + 0.5))) end
		if flammes then flammes:Emit(math.max(1, math.floor(3 * RFX.Echelle + 0.5))) end
		if mv and mv.short ~= "kick" then
			playSound(mv.final and FX.Sounds.swingHeavy or FX.Sounds.swingLight, blade.Position, 0.6) -- couche 1 : souffle
		end
	end
end

function FX.HitPoint(rig, mv)
	local hrp = rig:FindFirstChild("HumanoidRootPart")
	if mv and mv.short == "kick" then
		local lf, rf = rig.LeftFoot, rig.RightFoot
		local zl = hrp.CFrame:PointToObjectSpace(lf.Position).Z
		local zr = hrp.CFrame:PointToObjectSpace(rf.Position).Z
		return (zl < zr and lf or rf).Position
	end
	return (rig.PIPE_Sword.Blade.CFrame * CFrame.new(0, 1.3, 0)).Position
end

local function sparks(point, n, color)
	for i = 1, n do
		local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5).Unit
		local dist = 2 + math.random() * 1.5
		local p = newPart({Name = "PIPE_Spark", Size = Vector3.new(0.08, 0.08, 0.7), Color = color or Color3.fromRGB(235, 240, 255)})
		animate(0.22, function(a)
			local pos = point + dir * dist * a
			p.CFrame = CFrame.lookAt(pos, pos + dir); p.Transparency = a
			p.Size = Vector3.new(0.08, 0.08, 0.7 * (1 - a * 0.7))
		end, function() p:Destroy() end)
	end
end
local function flashLight(point, brightness, range, dur, color)
	local p = newPart({Name = "PIPE_FlashLight", Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2), CFrame = CFrame.new(point)})
	local l = Instance.new("PointLight"); l.Color = color or Color3.fromRGB(200, 225, 255); l.Range = range; l.Brightness = brightness; l.Parent = p
	animate(dur, function(a) l.Brightness = brightness * (1 - a) end, function() p:Destroy() end)
end

-- Flash blanc sur la cible touchee (0,05 s), vu tout de suite par celui qui frappe.
function FX.TargetFlash(model, dur)
	if not model or not model.Parent then return end
	local hl = Instance.new("Highlight"); hl.Name = "PIPE_FlashCible"
	hl.FillColor = Color3.new(1, 1, 1); hl.FillTransparency = 0; hl.OutlineTransparency = 1
	hl.DepthMode = Enum.HighlightDepthMode.Occluded; hl.Adornee = model; hl.Parent = fxFolder()
	task.delay(dur or 0.05, function() hl:Destroy() end)
end

-- 3 couches de son par touche : souffle (FX.Swing), impact (metal / chair / coup de pied), grave (grondement bas).
-- Au plus 40 particules par coup (RFX.Budget), effets de 0,4 s au plus.
local hitCount = 0
function FX.Hit(rig, point, kind)
	hitCount += 1
	RFX.Budget(40)
	-- feu discret : etincelles chaudes, petite bouffee de flammes, lumiere orangee (plus d'eclair bleu)
	sparks(point, math.random(2, 3), FEU.etincelle)
	flashLight(point, 6, 10, 0.12, FEU.lumiere)
	FX.Shake(0.12, 0.12)
	RFX.Sparks(point, 12, FEU.etincelle)
	flammeche(point, 5)
	RFX.Budget()
	if kind == "kick" then playSound(FX.Sounds.kick, point, 0.8) -- couche 2 : impact
	else playSound(hitCount % 2 == 0 and FX.Sounds.hitFlesh or FX.Sounds.hitMetal, point, 0.75) end
	playSound(FX.Sounds.final, point, 0.25, 0.6) -- couche 3 : grave
	if impactActive == 0 then
		local c = ccAcquire()
		animate(0.08, function(a) if impactActive == 0 then c.Brightness = 0.1 * (1 - a) end end, ccRelease)
	end
end

local function shockwave(center, rMax, dur, color)
	local seg = 28
	local parts = {}
	for i = 1, seg do parts[i] = newPart({Name = "PIPE_Shock", Size = Vector3.new(0.6, 0.12, 0.25), Color = color}) end
	animate(dur, function(a)
		local r = 0.8 + (rMax - 0.8) * (1 - (1 - a) ^ 2)
		for i, p in ipairs(parts) do
			local ang = (i / seg) * math.pi * 2
			local pos = center + Vector3.new(math.cos(ang) * r, 0.1, math.sin(ang) * r)
			p.Size = Vector3.new(2 * math.pi * r / seg * 1.05, 0.12 + 0.2 * (1 - a), 0.25 + 0.35 * (1 - a))
			p.CFrame = CFrame.lookAt(pos, center) * CFrame.Angles(0, math.pi / 2, 0)
			p.Transparency = 0.1 + 0.9 * a
		end
	end, function() for _, p in ipairs(parts) do p:Destroy() end end)
end
local function debris(center, n)
	for i = 1, n do
		local s = 0.25 + math.random() * 0.35
		local p = newPart({Name = "PIPE_Debris", Size = Vector3.new(s, s * 0.7, s), Material = Enum.Material.Slate,
			Color = Color3.fromRGB(95 + math.random(0, 30), 90, 85)})
		local v = Vector3.new(math.random() * 2 - 1, 0, math.random() * 2 - 1).Unit * (6 + math.random() * 6) + Vector3.new(0, 14 + math.random() * 10, 0)
		local rot = Vector3.new(math.random(), math.random(), math.random()) * 12
		local p0 = center + Vector3.new(0, 0.3, 0)
		animate(0.4, function(a)
			local t = a * 0.9
			local pos = p0 + v * t + Vector3.new(0, -25 * t * t, 0)
			if pos.Y < center.Y then pos = Vector3.new(pos.X, center.Y + s / 2, pos.Z) end
			p.CFrame = CFrame.new(pos) * CFrame.Angles(rot.X * t, rot.Y * t, rot.Z * t)
			p.Transparency = math.max(0, (a - 0.6) / 0.4)
		end, function() p:Destroy() end)
	end
end

function FX.Impact(rig, point, track, vitesse)
	impactActive += 1
	local c = ccAcquire()
	local hl = Instance.new("Highlight"); hl.Name = "PIPE_Highlight"
	hl.FillColor = Color3.new(1, 1, 1); hl.FillTransparency = 0.05; hl.OutlineColor = Color3.new(1, 1, 1); hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee = rig; hl.Parent = rig
	local eyes = {}
	for _, n in ipairs({"PIPE_EyeL", "PIPE_EyeR"}) do
		local e = rig.Head:FindFirstChild(n)
		if e then table.insert(eyes, e); e.Transparency = 0; e.PIPE_EyeLight.Enabled = true end
	end
	if track then track:AdjustSpeed(0.05); task.delay(0.08, function() pcall(function() track:AdjustSpeed(vitesse or 1) end) end) end
	FX.Zoom(55, 0.25)
	FX.Shake(0.55, 0.35)
	flashLight(point, 14, 26, 0.35, Color3.fromRGB(255, 240, 210))
	RFX.Budget(40)
	sparks(point, 8, FEU.etincelle)
	local g = groundUnder(rig, point)
	debris(g, math.max(4, math.floor(10 * RFX.Echelle)))
	flammeche(point, 8)
	RFX.Impact(g + Vector3.new(0, 1, 0), 1.4)
	RFX.Budget()
	playSound(FX.Sounds.hitMetal, point, 0.8, 0.9)
	playSound(FX.Sounds.final, point, 1)
	playSound(FX.Sounds.final, point, 0.45, 0.55) -- couche grave
	task.spawn(function()
		local ok, err = pcall(function()
			-- 0,08 + 0,05 + 0,07 + 0,18 = 0,38 s : sous la limite de 0,4 s
			c.Saturation = -1; c.Contrast = 1.4; c.Brightness = 0.05            -- noir et blanc tres contraste
			task.wait(0.08)
			c.Saturation = 0; c.Contrast = -2; c.Brightness = 0                 -- 2-3 images inversees
			task.wait(0.05)
			c.Saturation = -1; c.Contrast = 1.2                                 -- retour N&B
			task.wait(0.07)
			hl.FillTransparency = 0.6
			local t0 = os.clock()
			while os.clock() - t0 < 0.18 do                                     -- retour progressif aux couleurs
				local a = (os.clock() - t0) / 0.18
				c.Saturation = -1 * (1 - a); c.Contrast = 1.2 * (1 - a)
				hl.FillTransparency = 0.6 + 0.4 * a; hl.OutlineTransparency = a
				task.wait()
			end
		end)
		impactActive = math.max(0, impactActive - 1)
		ccRelease()
		hl:Destroy()
		for _, e in ipairs(eyes) do e.Transparency = 1; e.PIPE_EyeLight.Enabled = false end
		if not ok then warn("PIPE FX.Impact : " .. tostring(err)) end
	end)
end

function FX.Cleanup()
	impactActive = 0; ccUsers = 0
	for _, ch in ipairs(Lighting:GetChildren()) do if ch.Name:match("^PIPE_") then ch:Destroy() end end
	local f = workspace:FindFirstChild("PIPE_FX"); if f then f:Destroy() end
	if fovBase then workspace.CurrentCamera.FieldOfView = fovBase; fovBase = nil end
end

return FX
