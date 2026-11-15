-- Ultime 01 "Couronne de l'Aube" : mise en scene (effets REALISTES, etape 8a) (camera scriptee + effets), cote client / apercu.
-- Utilisation : local u = Ultime01.New(rig) ; a chaque image u:Update(track.TimePosition) ; a la fin u:Finish()
-- Phases (s) : charge 0-0.8 | dash 0.8-1.0 | taille montante 1.0-1.6 | air 1.6-2.4 | pose suspendue 2.4-2.9 | frappe 2.9-3.5
-- Le ciel n'est jamais touche ; seule la ColorCorrection PIPE_ULT_CC est ajoutee pendant les flashs / impact frames
-- puis supprimee. Camera et eclairage remis comme avant dans Finish().
local Lighting = game:GetService("Lighting")
local FX = require(script.Parent:WaitForChild("FX"))
local RFX = require(script.Parent:WaitForChild("RealFX"))
local U = {}
U.__index = U
U.Sounds = {charge = "rbxassetid://119258644640718", dash = "rbxassetid://140191581069221",
	explosion = "rbxassetid://92607331013938"}
U.FAN = {1.78, 2.03, 2.27}       -- 3 coups en eventail
U.GROUND_HIT = 3.1               -- epee plantee
local GOLD = Color3.fromRGB(255, 205, 95)
local BLUE = Color3.fromRGB(120, 190, 255)

local function folderFX()
	local f = workspace:FindFirstChild("PIPE_ULT_FX")
	if not f then f = Instance.new("Folder"); f.Name = "PIPE_ULT_FX"; f.Parent = workspace end
	return f
end
local function newPart(props)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.Material = Enum.Material.Neon
	for k, v in pairs(props) do p[k] = v end
	p.Parent = folderFX()
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
local function sound(id, at, vol)
	local p = newPart({Name = "PIPE_UltSound", Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2), CFrame = CFrame.new(at)})
	local s = Instance.new("Sound"); s.SoundId = id; s.Volume = vol or 1; s.RollOffMaxDistance = 400; s.Parent = p
	s:Play()
	task.delay(6, function() p:Destroy() end)
end

function U.New(rig)
	local self = setmetatable({}, U)
	self.rig = rig
	self.hrp = rig.HumanoidRootPart
	self.cam = workspace.CurrentCamera
	self.saved = {cf = self.cam.CFrame, fov = self.cam.FieldOfView, type = self.cam.CameraType}
	self.cam.CameraType = Enum.CameraType.Scriptable
	self.fired = {}
	self.shake = 0
	self.last = -1
	FX.Setup(rig)
	self.ground = self.hrp.Position.Y - rig.Humanoid.HipHeight - self.hrp.Size.Y / 2
	return self
end

function U:cc()
	local c = Lighting:FindFirstChild("PIPE_ULT_CC")
	if not c then c = Instance.new("ColorCorrectionEffect"); c.Name = "PIPE_ULT_CC"; c.Parent = Lighting end
	return c
end
function U:ccOff()
	local c = Lighting:FindFirstChild("PIPE_ULT_CC"); if c then c:Destroy() end
end
function U:once(key, t, tp, fn)
	if not self.fired[key] and tp >= t then self.fired[key] = true; fn() end
end

-- ---------- effets ----------
function U:aura(dur)
	-- aura de charge realiste : particules dorees qui montent (ParticleEmitter), arcs electriques autour du corps
	-- et sur la lame, lumiere qui pulse, poussiere qui se souleve
	local rig = self.rig
	local host = Instance.new("Part"); host.Name = "PIPE_AuraHost"; host.Anchored = true; host.CanCollide = false
	host.CanQuery = false; host.CanTouch = false; host.Transparency = 1; host.Size = Vector3.new(4, 0.2, 4)
	host.CFrame = CFrame.new(rig.LowerTorso.Position.X, self.ground + 0.1, rig.LowerTorso.Position.Z)
	host.Parent = folderFX()
	local e = Instance.new("ParticleEmitter"); e.Texture = RFX.TEX.spark
	e.Color = RFX.CS(0, Color3.fromRGB(255, 230, 160), 1, Color3.fromRGB(255, 180, 70)); e.LightEmission = 1
	e.Size = RFX.NS(0, 0.18, 1, 0); e.Lifetime = NumberRange.new(0.6, 1.1); e.Speed = NumberRange.new(4, 8)
	e.EmissionDirection = Enum.NormalId.Top; e.SpreadAngle = Vector2.new(12, 12); e.Rate = 120
	e.Transparency = RFX.NS(0, 0, 1, 1); e.Parent = host
	local l = Instance.new("PointLight"); l.Color = GOLD; l.Range = 12; l.Brightness = 2; l.Parent = host
	RFX.Dust(host.Position, 1.2)
	RFX.BladeLightning(rig.PIPE_Sword.Blade, dur)
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < dur do
			local c = rig.UpperTorso.Position
			local a = c + Vector3.new(math.random() * 3 - 1.5, math.random() * 2.5 - 1, math.random() * 3 - 1.5)
			local b = Vector3.new(a.X + math.random() * 2 - 1, self.ground, a.Z + math.random() * 2 - 1)
			RFX.Lightning(a, b, 0.1, {width = 0.08, segments = 3, range = 10, brightness = 4})
			l.Brightness = 2 + math.random() * 3
			task.wait(0.09)
		end
		e.Enabled = false
		task.delay(1.2, function() host:Destroy() end)
	end)
end

function U:fanHit()
	local tip = (self.rig.PIPE_Sword.Blade.CFrame * CFrame.new(0, 1.4, 0)).Position
	RFX.Sparks(tip, 18, Color3.fromRGB(255, 225, 160))
	RFX.Lightning(tip + Vector3.new(math.random() * 2 - 1, 2.5, math.random() * 2 - 1), tip, 0.12, {width = 0.1, range = 12, brightness = 5})
	sound(FX.Sounds.swingLight, tip, 0.7)
	sound(FX.Sounds.hitMetal, tip, 0.6)
	self.shake = math.max(self.shake, 0.25)
end

function U:impactFrames()
	-- 3 impact frames de 0,06 s : N&B / inverse / N&B ; yeux dores ; Highlight blanc
	local c = self:cc()
	local rig = self.rig
	local eyes = {}
	for _, n in ipairs({"PIPE_EyeL", "PIPE_EyeR"}) do
		local e = rig.Head:FindFirstChild(n)
		if e then table.insert(eyes, e); e.Color = GOLD; e.Transparency = 0; e.PIPE_EyeLight.Color = GOLD; e.PIPE_EyeLight.Enabled = true end
	end
	self.eyes = eyes
	local hl = Instance.new("Highlight"); hl.Name = "PIPE_UltHighlight"; hl.FillColor = Color3.new(1, 1, 1)
	hl.OutlineColor = GOLD; hl.FillTransparency = 0.2; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Adornee = rig; hl.Parent = rig
	task.spawn(function()
		pcall(function()
			c.Saturation = -1; c.Contrast = 1.5; task.wait(0.06)
			c.Saturation = 0; c.Contrast = -2; task.wait(0.06)
			c.Saturation = -1; c.Contrast = 1.5; task.wait(0.06)
			c.Saturation = 0; c.Contrast = 0.15; c.TintColor = Color3.fromRGB(255, 240, 215)
			hl.FillTransparency = 0.75
		end)
		task.wait(0.25)
		self:ccOff()
		hl:Destroy()
	end)
	sound(FX.Sounds.swingHeavy, rig.Head.Position, 1)
end

function U:groundHit()
	local rig = self.rig
	local tip = (rig.PIPE_Sword.Blade.CFrame * CFrame.new(0, 1.6, 0)).Position
	local g = Vector3.new(tip.X, self.ground, tip.Z)
	sound(U.Sounds.explosion, g, 1)
	self.shake = 1.0
	local c = self:cc(); c.Brightness = 0.35
	animate(0.18, function(a) c.Brightness = 0.35 * (1 - a) end, function() self:ccOff() end)
	-- eclairs qui frappent le sol autour de la lame
	for i = 1, 5 do
		task.delay(i * 0.04, function()
			local ang = math.random() * math.pi * 2
			local hitp = g + Vector3.new(math.cos(ang) * (2 + math.random() * 5), 0, math.sin(ang) * (2 + math.random() * 5))
			RFX.Lightning(hitp + Vector3.new(math.random() * 4 - 2, 18, math.random() * 4 - 2), hitp, 0.25, {width = 0.25, range = 26, brightness = 8})
		end)
	end
	-- sphere d'energie translucide (ForceField + Neon faible opacite) parcourue d'eclairs, puis explosion realiste
	local sphere, inner = RFX.EnergySphere(g, 9, 0.42)
	task.delay(0.42, function()
		sphere:Destroy(); inner:Destroy()
		RFX.Explosion(g, 2.2)
	end)
	-- sol fissure (fissures sombres avec lueur de braise qui s'eteint)
	for i = 1, 11 do
		local ang = (i / 11) * math.pi * 2 + math.random() * 0.3
		local len = 4 + math.random() * 6
		local mid = g + Vector3.new(math.cos(ang) * len / 2, 0.03, math.sin(ang) * len / 2)
		local crack = newPart({Name = "PIPE_Crack", Material = Enum.Material.Slate, Color = Color3.fromRGB(30, 26, 26),
			Size = Vector3.new(0.3 + math.random() * 0.25, 0.06, len), CFrame = CFrame.lookAt(mid, g)})
		local glow = newPart({Name = "PIPE_CrackGlow", Color = Color3.fromRGB(255, 140, 50), Size = Vector3.new(0.1, 0.07, len * 0.9), CFrame = crack.CFrame})
		animate(2.4, function(a)
			glow.Transparency = math.min(1, 0.2 + a * 1.4)
			crack.Transparency = math.max(0, (a - 0.6) / 0.4)
		end, function() crack:Destroy(); glow:Destroy() end)
	end
end

-- ---------- camera + declenchements ----------
function U:Update(tp)
	local rig, hrp, cam = self.rig, self.hrp, self.cam
	local center = rig.LowerTorso.Position
	local look = hrp.CFrame.LookVector
	local right = hrp.CFrame.RightVector
	local up = Vector3.new(0, 1, 0)

	self:once("charge", 0, tp, function()
		sound(U.Sounds.charge, center, 1)
		self:aura(0.85)
	end)
	self:once("dash", 0.8, tp, function()
		sound(U.Sounds.dash, center, 1)
		local c = self:cc(); c.Brightness = 0.3
		animate(0.12, function(a) c.Brightness = 0.3 * (1 - a) end, function() self:ccOff() end)
		RFX.Dust(Vector3.new(center.X, self.ground, center.Z), 1.2)
		self.shake = 0.5
		self.dashCam = hrp.Position + right * 9 + up * 3 + look * 2
	end)
	self:once("swingOn", 1.0, tp, function() FX.Swing(rig, true) ; sound(FX.Sounds.swingHeavy, center, 0.8) end)
	for i, t in ipairs(U.FAN) do self:once("fan" .. i, t, tp, function() self:fanHit() end) end
	self:once("swingOff", 2.4, tp, function() FX.Swing(rig, false) end)
	self:once("impactFrames", 2.45, tp, function() self:impactFrames() end)
	self:once("ground", U.GROUND_HIT, tp, function() self:groundHit() end)
	self:once("eyesOff", 3.4, tp, function()
		for _, e in ipairs(self.eyes or {}) do e.Transparency = 1; e.PIPE_EyeLight.Enabled = false; e.Color = Color3.fromRGB(150, 220, 255); e.PIPE_EyeLight.Color = e.Color end
	end)

	-- camera
	local cf, fov
	if tp < 0.8 then
		local k = tp / 0.8
		local ang = math.rad(-40 + 95 * k)             -- rotation lente autour du perso
		local dir = (look * math.cos(ang) + right * math.sin(ang))
		cf = CFrame.lookAt(center + dir * (12 - 3 * k) + up * (2.5 + k), center + up * 0.8)
		fov = 70 - 20 * k
		self.shake = math.max(self.shake, 0.06 + 0.1 * k)  -- le sol tremble
	elseif tp < 1.0 then
		local k = (tp - 0.8) / 0.2
		cf = CFrame.lookAt(self.dashCam - look * 3 * k, center)  -- recul de camera
		fov = 50 + 30 * math.sin(math.min(1, k * 1.5) * math.pi / 2)
	elseif tp < 2.4 then
		-- contre-plongee qui suit
		cf = CFrame.lookAt(center + right * 10 + look * 4 - up * 1.0, rig.Head.Position + up * 0.5)
		fov = 68
	elseif tp < 2.9 then
		-- tres gros plan visage (le perso regarde -Z de la tete)
		local head = rig.Head.CFrame
		cf = CFrame.lookAt((head * CFrame.new(0.4, 0.15, -2.4)).Position, head.Position + up * 0.1)
		fov = 45
	else
		-- plan large sur la frappe au sol
		local landing = Vector3.new(center.X, hrp.Position.Y, center.Z) -- apercu : la racine bouge ; jeu : le HRP bouge
		cf = CFrame.lookAt(landing + right * 24 - look * 6 + up * 9, landing + up * 1.5)
		fov = 70
	end
	if self.shake > 0.01 then
		local s = self.shake
		cf = cf * CFrame.new((math.random() * 2 - 1) * s, (math.random() * 2 - 1) * s, 0) * CFrame.Angles(0, 0, (math.random() * 2 - 1) * s * 0.03)
		self.shake = self.shake * 0.9
	end
	cam.CFrame = cf
	cam.FieldOfView = fov
end

function U:Finish()
	FX.Swing(self.rig, false)
	for _, e in ipairs(self.eyes or {}) do pcall(function() e.Transparency = 1; e.PIPE_EyeLight.Enabled = false end) end
	local hl = self.rig:FindFirstChild("PIPE_UltHighlight"); if hl then hl:Destroy() end
	self:ccOff()
	local cam = self.cam
	cam.CameraType = self.saved.type
	cam.CFrame = self.saved.cf
	cam.FieldOfView = self.saved.fov
end

function U.Cleanup()
	local c = Lighting:FindFirstChild("PIPE_ULT_CC"); if c then c:Destroy() end
	local f = workspace:FindFirstChild("PIPE_ULT_FX"); if f then f:Destroy() end
end

return U
