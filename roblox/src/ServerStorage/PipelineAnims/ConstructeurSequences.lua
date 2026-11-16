--!strict
-- Construit une KeyframeSequence à partir des poses clés exportées par pipeline-anim/scripts/anim_lib.py
-- (fichiers 04_roblox/seq/PIPE_*.json). Même interpolation que dans Blender : slerp entre deux clés,
-- courbe u -> 1 - (1 - u)^ease (ou u^|ease| si ease < 0), une image tous les 1/fps.
-- Les marqueurs (KeyframeMarker « Contact », « Depart »...) sont posés sur une image à leur temps exact.
-- Outil d'édition seulement (lancé depuis Studio) : rien n'est appelé pendant le jeu.

local HttpService = game:GetService("HttpService")

local Constructeur = {}

local function courbe(u: number, p: number): number
	if p < 0 then
		return u ^ -p
	end
	return 1 - (1 - u) ^ p
end

function Constructeur.construire(json: string, destination: Instance): KeyframeSequence
	local d = HttpService:JSONDecode(json)
	local parts = d.parts
	local nbMot = #parts
	local cles = d.keys
	local function rot(cle, i)
		local b = 2 + (i - 1) * 4
		return CFrame.new(0, 0, 0, cle[b + 1], cle[b + 2], cle[b + 3], cle[b + 4])
	end
	local function racine(cle)
		local b = 2 + nbMot * 4
		return Vector3.new(cle[b + 1], cle[b + 2], cle[b + 3])
	end
	-- temps des images : grille fps + temps exacts des marqueurs
	local temps = {}
	local nf = math.floor(d.duree * d.fps + 0.5)
	for f = 0, nf do
		table.insert(temps, f / d.fps)
	end
	for _, m in d.markers do
		table.insert(temps, m[2])
	end
	table.sort(temps)
	local alea = Random.new(#d.nom)
	local bruit = {}
	for i = 1, nbMot do
		bruit[i] = {}
	end

	local ks = Instance.new("KeyframeSequence")
	ks.Name = d.nom
	ks.Loop = d.boucle
	ks.Priority = (Enum.AnimationPriority :: any)[d.priorite] or Enum.AnimationPriority.Action
	local dernier = -1
	for fi, t in temps do
		if t - dernier < 1e-4 then
			continue
		end
		dernier = t
		local k1 = 1
		for i, c in cles do
			if c[1] <= t + 1e-9 then
				k1 = i
			end
		end
		local k2 = math.min(k1 + 1, #cles)
		local a, b = cles[k1], cles[k2]
		local u = if k2 == k1 then 0 else (t - a[1]) / (b[1] - a[1])
		local w = courbe(math.clamp(u, 0, 1), b[2])
		local kf = Instance.new("Keyframe")
		kf.Time = t
		local poses: { [string]: Pose } = {}
		local hrp = Instance.new("Pose")
		hrp.Name = "HumanoidRootPart"
		hrp.Weight = 0
		hrp.Parent = kf
		poses.HumanoidRootPart = hrp
		for i = 1, nbMot do
			local cf = rot(a, i):Lerp(rot(b, i), w)
			if d.tremble and t >= d.tremble[1] and t <= d.tremble[2] then
				local amp = math.rad(d.tremble[3]) * (t - d.tremble[1]) / math.max(1e-6, d.tremble[2] - d.tremble[1])
				local n = bruit[i]
				n[fi] = Vector3.new(alea:NextNumber(-1, 1), alea:NextNumber(-1, 1), alea:NextNumber(-1, 1))
				local nv = n[fi] * 0.6 + (n[fi - 1] or n[fi]) * 0.4
				cf = cf * CFrame.fromEulerAnglesXYZ(nv.X * amp, nv.Y * amp, nv.Z * amp)
			end
			if i == 1 then -- moteur Root : position de la racine
				cf = CFrame.new(racine(a):Lerp(racine(b), w)) * cf
			end
			local p = Instance.new("Pose")
			p.Name = parts[i][1]
			p.CFrame = cf
			p.Weight = 1
			p.EasingStyle = Enum.PoseEasingStyle.Linear
			poses[parts[i][1]] = p
		end
		for i = 1, nbMot do
			local p = poses[parts[i][1]]
			p.Parent = poses[parts[i][2]]
		end
		for _, m in d.markers do
			if math.abs(m[2] - t) < 1e-4 then
				local mk = Instance.new("KeyframeMarker")
				mk.Name = m[1]
				mk.Value = m[3]
				kf:AddMarker(mk)
			end
		end
		kf.Parent = ks
	end
	local ancien = destination:FindFirstChild(d.nom)
	if ancien then
		ancien:Destroy()
	end
	ks.Parent = destination
	return ks
end

return Constructeur
