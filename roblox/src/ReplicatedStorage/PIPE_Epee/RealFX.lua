-- Effets REALISTES du pipeline (etape 8a) : aucun contour, aucun flipbook dessine.
-- RealFX.Lightning(p0, p1, dur, opts)      : eclair en Beams (zigzag qui change chaque image, ramifications, PointLight)
-- RealFX.BladeLightning(blade, dur)        : petits arcs electriques qui courent le long d'une lame
-- RealFX.Sparks(pos, n, color)             : gerbe d'etincelles (ParticleEmitter)
-- RealFX.Dust(pos, scale)                  : poussiere / fumee claire au sol
-- RealFX.Explosion(pos, scale)             : flash, boule de feu, fumee sombre, etincelles, debris, onde de choc translucide
-- RealFX.EnergySphere(pos, rMax, dur)      : sphere d'energie translucide parcourue d'eclairs
local R = {}
local TEX = {
	fire = "rbxasset://textures/particles/fire_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	spark = "rbxasset://textures/particles/sparkles_main.dds",
	fireSpark = "rbxasset://textures/particles/fire_sparks_main.dds",
}
R.TEX = TEX
local ELEC = Color3.fromRGB(205, 228, 255)

-- Etape 10 : effets courts et legers. Hors ultime, un effet dure au plus R.DUREE_MAX (0,4 s) et un coup emet au plus
-- R.budget particules (FX.Hit / FX.Impact posent 40). R.Echelle = 0,5 en mode allege (telephone, qualite basse).
-- R.SansLimite > 0 pendant un ultime : ni plafond de duree, ni budget.
R.DUREE_MAX = 0.4
R.Echelle = 1
R.SansLimite = 0
R.budget = math.huge
function R.Budget(n) R.budget = n or math.huge end
local function lim(d)
	if R.SansLimite > 0 then return d end
	return math.min(d, R.DUREE_MAX)
end
R.lim = lim

local function root()
	local f = workspace:FindFirstChild("PIPE_FX")
	if not f then f = Instance.new("Folder"); f.Name = "PIPE_FX"; f.Parent = workspace end
	return f
end
local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.Transparency = 1; p.Size = Vector3.new(0.2, 0.2, 0.2)
	for k, v in pairs(props) do p[k] = v end
	p.Parent = root()
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
R.animate = animate
R.part = part
local function NS(...) local k = {} local v = {...} for i = 1, #v, 2 do table.insert(k, NumberSequenceKeypoint.new(v[i], v[i + 1])) end return NumberSequence.new(k) end
local function CS(...) local k = {} local v = {...} for i = 1, #v, 2 do table.insert(k, ColorSequenceKeypoint.new(v[i], v[i + 1])) end return ColorSequence.new(k) end
R.NS, R.CS = NS, CS

-- ---------- eclairs (Beams) ----------
local function boltPoints(p0, p1, segs, jitter)
	local pts = {p0}
	local dir = p1 - p0
	local len = dir.Magnitude
	local side1 = dir:Cross(Vector3.new(0, 1, 0)); if side1.Magnitude < 1e-3 then side1 = dir:Cross(Vector3.new(1, 0, 0)) end
	side1 = side1.Unit
	local side2 = dir:Cross(side1).Unit
	for i = 1, segs - 1 do
		local t = i / segs
		local off = (side1 * (math.random() * 2 - 1) + side2 * (math.random() * 2 - 1)) * len * jitter
		table.insert(pts, p0 + dir * t + off)
	end
	table.insert(pts, p1)
	return pts
end
local function beamChain(host, n, width, color)
	local atts, beams = {}, {}
	for i = 1, n + 1 do local a = Instance.new("Attachment"); a.Parent = host; atts[i] = a end
	for i = 1, n do
		local b = Instance.new("Beam")
		b.Attachment0 = atts[i]; b.Attachment1 = atts[i + 1]
		b.Width0 = width; b.Width1 = width * 0.8; b.FaceCamera = true; b.LightEmission = 1; b.LightInfluence = 0
		b.Color = ColorSequence.new(color); b.Transparency = NS(0, 0, 1, 0.1); b.Segments = 1
		b.Parent = host; beams[i] = b
	end
	return atts, beams
end
function R.Lightning(p0, p1, dur, opts)
	opts = opts or {}
	local segs = opts.segments or math.random(3, 4)
	local width = opts.width or 0.18
	local color = opts.color or ELEC
	local host = part({Name = "PIPE_Bolt", CFrame = CFrame.new()})
	local mainA, mainB = beamChain(host, segs, width, color)
	local glowA, glowB = beamChain(host, segs, width * 4, color)
	for _, b in ipairs(glowB) do b.Transparency = NS(0, 0.82, 1, 0.9) end
	local branches = {}
	for i = 1, (opts.branches or math.random(1, 2)) do local a = beamChain(host, 2, width * 0.55, color); table.insert(branches, a) end
	local lp = part({Name = "PIPE_BoltLight", CFrame = CFrame.new((p0 + p1) / 2)})
	local light = Instance.new("PointLight"); light.Color = color; light.Range = opts.range or 14; light.Brightness = 0; light.Parent = lp
	animate(lim(dur), function(a)
		local pts = boltPoints(p0, p1, segs, opts.jitter or 0.12)
		for i, at in ipairs(mainA) do at.WorldPosition = pts[i] end
		for i, at in ipairs(glowA) do at.WorldPosition = pts[i] end
		for _, br in ipairs(branches) do
			local s = pts[math.random(2, segs)]
			local d = (p1 - p0).Magnitude * (0.15 + math.random() * 0.2)
			local e = s + Vector3.new(math.random() - 0.5, math.random() - 0.7, math.random() - 0.5).Unit * d
			local bp = boltPoints(s, e, 2, 0.2)
			for i, at in ipairs(br) do at.WorldPosition = bp[i] end
		end
		local on = math.random() < 0.8
		for _, b in ipairs(mainB) do b.Enabled = on end
		for _, b in ipairs(glowB) do b.Enabled = on end
		light.Brightness = (opts.brightness or 6) * (on and 1 or 0.15) * (1 - a ^ 2)
	end, function() host:Destroy(); lp:Destroy() end)
end
function R.BladeLightning(blade, dur)
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < dur and blade.Parent do
			local cf = blade.CFrame
			local h = blade.Size.Y / 2
			local a = (cf * CFrame.new(0, -h + math.random() * h, 0)).Position
			local b = (cf * CFrame.new((math.random() - 0.5) * 0.4, math.random() * h, (math.random() - 0.5) * 0.3)).Position
			R.Lightning(a, b, 0.09, {width = 0.06, segments = 3, branches = 1, range = 6, brightness = 3, jitter = 0.18})
			task.wait(0.05)
		end
	end)
end

-- ---------- particules ----------
local function burst(pos, props, n, life)
	n = math.max(1, math.floor(n * R.Echelle + 0.5))
	if R.SansLimite <= 0 then
		n = math.min(n, R.budget)
		if n <= 0 then return nil end
		if R.budget ~= math.huge then R.budget -= n end
		local lt = props.Lifetime
		if lt and lt.Max > R.DUREE_MAX then
			props.Lifetime = NumberRange.new(math.min(lt.Min, R.DUREE_MAX * 0.6), R.DUREE_MAX)
		end
		life = math.min(life or 4, R.DUREE_MAX + 0.3)
	end
	local p = part({Name = "PIPE_Emitter", CFrame = CFrame.new(pos)})
	local e = Instance.new("ParticleEmitter")
	e.Enabled = false
	for k, v in pairs(props) do e[k] = v end
	e.Parent = p
	e:Emit(n)
	task.delay(life or 4, function() p:Destroy() end)
	return e
end
R.burst = burst
function R.Sparks(pos, n, color)
	burst(pos, {Texture = TEX.fireSpark, Color = ColorSequence.new(color or Color3.fromRGB(255, 210, 140)),
		LightEmission = 1, Size = NS(0, 0.25, 1, 0), Lifetime = NumberRange.new(0.25, 0.55), Speed = NumberRange.new(14, 30),
		SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -40, 0), Drag = 3, Transparency = NS(0, 0, 1, 1)}, n or 14, 1.5)
end
function R.Dust(pos, scale)
	scale = scale or 1
	burst(pos, {Texture = TEX.smoke, Color = ColorSequence.new(Color3.fromRGB(170, 160, 150)), LightInfluence = 1,
		Size = NS(0, 1.2 * scale, 1, 4 * scale), Transparency = NS(0, 0.55, 0.3, 0.6, 1, 1),
		Lifetime = NumberRange.new(0.7, 1.3), Speed = NumberRange.new(3 * scale, 7 * scale), SpreadAngle = Vector2.new(80, 10),
		EmissionDirection = Enum.NormalId.Top, Drag = 4, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-40, 40)}, 10, 2.5)
end
function R.Shockwave(pos, radius, dur, color)
	local ring = part({Name = "PIPE_Shockwave", Shape = Enum.PartType.Cylinder, Material = Enum.Material.Glass,
		Color = color or Color3.fromRGB(255, 235, 210), Transparency = 0.6, Size = Vector3.new(0.3, 1, 1),
		CFrame = CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))})
	animate(lim(dur), function(a)
		local d = 1 + radius * 2 * (1 - (1 - a) ^ 3)
		ring.Size = Vector3.new(0.3 * (1 - a) + 0.05, d, d)
		ring.Transparency = 0.6 + 0.4 * a
	end, function() ring:Destroy() end)
end
local function debris(center, n, scale)
	n = math.max(1, math.floor(n * R.Echelle + 0.5))
	local duree = lim(1.1)
	for i = 1, n do
		local s = (0.25 + math.random() * 0.4) * scale
		local p = part({Name = "PIPE_Debris", Transparency = 0, Material = Enum.Material.Slate, Color = Color3.fromRGB(90 + math.random(0, 25), 84, 78), Size = Vector3.new(s, s * 0.7, s)})
		local v = Vector3.new(math.random() * 2 - 1, 0, math.random() * 2 - 1).Unit * (6 + math.random() * 8) * scale + Vector3.new(0, (14 + math.random() * 12) * math.sqrt(scale), 0)
		local rot = Vector3.new(math.random(), math.random(), math.random()) * 10
		animate(duree, function(a)
			local t = a * duree
			local pos = center + Vector3.new(0, 0.3, 0) + v * t + Vector3.new(0, -30 * t * t, 0)
			if pos.Y < center.Y then pos = Vector3.new(pos.X, center.Y + s / 2, pos.Z) end
			p.CFrame = CFrame.new(pos) * CFrame.Angles(rot.X * t, rot.Y * t, rot.Z * t)
			p.Transparency = math.max(0, (a - 0.7) / 0.3)
		end, function() p:Destroy() end)
	end
end
R.Debris = debris
function R.Explosion(pos, scale)
	scale = scale or 1
	local lp = part({Name = "PIPE_ExplosionLight", CFrame = CFrame.new(pos + Vector3.new(0, 1, 0))})
	local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 190, 120); l.Range = math.min(60, 30 * scale); l.Brightness = 10; l.Parent = lp
	animate(lim(0.6), function(a) l.Brightness = 10 * (1 - a) ^ 2 end, function() lp:Destroy() end)
	local core = part({Name = "PIPE_Fireball", Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 170, 70),
		Transparency = 0.15, CFrame = CFrame.new(pos + Vector3.new(0, 1, 0))})
	animate(lim(0.35), function(a)
		local s = (1 + 7 * (1 - (1 - a) ^ 2)) * scale
		core.Size = Vector3.new(s, s, s)
		core.Transparency = 0.15 + 0.85 * a
		core.Color = Color3.fromRGB(255, 170 - 80 * a, 70 - 50 * a)
	end, function() core:Destroy() end)
	burst(pos + Vector3.new(0, 1, 0), {Texture = TEX.fire, Color = CS(0, Color3.fromRGB(255, 240, 200), 0.3, Color3.fromRGB(255, 150, 50), 1, Color3.fromRGB(120, 40, 20)),
		LightEmission = 0.9, Size = NS(0, 2 * scale, 0.4, 5 * scale, 1, 6 * scale), Transparency = NS(0, 0, 0.6, 0.3, 1, 1),
		Lifetime = NumberRange.new(0.35, 0.7), Speed = NumberRange.new(8 * scale, 18 * scale), SpreadAngle = Vector2.new(180, 180),
		Drag = 5, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-90, 90)}, 26, 2)
	task.delay(0.12, function()
		burst(pos + Vector3.new(0, 1.5, 0), {Texture = TEX.smoke, Color = ColorSequence.new(Color3.fromRGB(55, 50, 48)), LightInfluence = 1,
			Size = NS(0, 3 * scale, 1, 9 * scale), Transparency = NS(0, 0.3, 0.5, 0.45, 1, 1),
			Lifetime = NumberRange.new(1.4, 2.4), Speed = NumberRange.new(4 * scale, 9 * scale), SpreadAngle = Vector2.new(70, 70),
			Acceleration = Vector3.new(0, 3, 0), Drag = 2, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-30, 30)}, 18, 4)
	end)
	R.Sparks(pos + Vector3.new(0, 1, 0), math.floor(30 * scale))
	debris(pos, math.floor(10 * scale), math.min(scale, 1.6))
	R.Shockwave(pos, 9 * scale, 0.5)
	R.Dust(pos, 1.6 * scale)
end
-- Impact court (coups normaux et coup final, hors ultime) : lumiere, bouffee de feu, etincelles, petits debris.
-- 8 + 16 + 6 = 30 particules au plus (avant le budget du coup), tout disparait en 0,4 s.
function R.Impact(pos, scale, color)
	scale = scale or 1
	local lp = part({Name = "PIPE_ImpactLight", CFrame = CFrame.new(pos)})
	local l = Instance.new("PointLight"); l.Color = color or Color3.fromRGB(255, 225, 170); l.Range = 16 * scale; l.Brightness = 8; l.Parent = lp
	animate(lim(0.25), function(a) l.Brightness = 8 * (1 - a) ^ 2 end, function() lp:Destroy() end)
	burst(pos, {Texture = TEX.fire, Color = CS(0, Color3.fromRGB(255, 245, 215), 1, Color3.fromRGB(255, 150, 60)), LightEmission = 1,
		Size = NS(0, 1.2 * scale, 1, 2.6 * scale), Transparency = NS(0, 0.1, 1, 1), Lifetime = NumberRange.new(0.15, 0.3),
		Speed = NumberRange.new(6 * scale, 12 * scale), SpreadAngle = Vector2.new(180, 180), Drag = 6, Rotation = NumberRange.new(0, 360)}, 8, 0.6)
	R.Sparks(pos, 16, color)
	debris(pos, math.floor(6 * scale), math.min(scale, 1.3))
	R.Shockwave(pos, 4 * scale, 0.3)
end
-- Impact contre un mur (fin du combo A) : poussiere, eclats de pierre, fissure lumineuse breve.
function R.WallImpact(pos, normal)
	normal = normal or Vector3.new(0, 0, 1)
	R.Dust(pos + normal * 0.5, 1.2)
	debris(pos + normal * 0.5, 8, 1)
	R.Sparks(pos + normal * 0.3, 12, Color3.fromRGB(255, 230, 190))
	local crack = part({Name = "PIPE_WallCrack", Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Transparency = 0.3,
		Color = Color3.fromRGB(255, 220, 170), Size = Vector3.new(0.05, 3, 3),
		CFrame = CFrame.lookAt(pos + normal * 0.06, pos + normal) * CFrame.Angles(0, math.rad(90), 0)})
	animate(lim(0.35), function(a) crack.Transparency = 0.3 + 0.7 * a end, function() crack:Destroy() end)
end
function R.EnergySphere(pos, rMax, dur, colors)
	colors = colors or {Color3.fromRGB(255, 215, 120), Color3.fromRGB(140, 200, 255)}
	local s = part({Name = "PIPE_EnergySphere", Shape = Enum.PartType.Ball, Material = Enum.Material.ForceField, Color = colors[1],
		Transparency = 0, CFrame = CFrame.new(pos)})
	local inner = part({Name = "PIPE_EnergyInner", Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = colors[2],
		Transparency = 0.85, CFrame = CFrame.new(pos)})
	animate(dur, function(a)
		local d = 1 + (rMax * 2 - 1) * (1 - (1 - a) ^ 3)
		s.Size = Vector3.new(d, d, d); inner.Size = Vector3.new(d * 0.92, d * 0.92, d * 0.92)
		if math.random() < 0.6 then
			local r = d / 2
			local u = Vector3.new(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5).Unit
			local v = (u + Vector3.new(math.random() - 0.5, math.random() * 0.4, math.random() - 0.5) * 0.9).Unit
			R.Lightning(pos + u * r, pos + v * r, 0.08, {width = 0.1, segments = 3, branches = 1, range = 10, brightness = 4})
		end
	end)
	return s, inner
end
return R
