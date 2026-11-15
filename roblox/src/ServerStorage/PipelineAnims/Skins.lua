-- Skins du joueur (etape 8c) : vetements en MeshParts soudes aux parties du R15 (pieces generiques de
-- PipelineAnims.PIPE_ClothRaw, modelisees dans Blender : scripts/vetements.py). Tout est dans un Model "PIPE_Skin".
-- Skins.Apply(rig, n)  -- n = 1 aventurier debutant, 2 chevalier-mage, 3 epeiste errant
-- Chaque piece : {mesh, partie, taille (multiplie la taille de la partie) ou abs, decalage (repere de la partie), couleur, matiere}
local Skins = {}
local RAW = script.Parent:WaitForChild("PIPE_ClothRaw")
local F, L, M, FOIL = Enum.Material.Fabric, Enum.Material.Leather, Enum.Material.Metal, Enum.Material.Foil
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local SKIN_TONE = rgb(232, 190, 160)

local function P(mesh, part, k, off, color, mat, abs)
	return {mesh = mesh, part = part, k = k, off = off or CFrame.new(), color = color, mat = mat, abs = abs}
end
local function both(list, mesh, base, ...)
	table.insert(list, P(mesh, "Left" .. base, ...)); table.insert(list, P(mesh, "Right" .. base, ...))
end

Skins.Names = {"Aventurier debutant", "Chevalier-mage", "Epeiste errant"}
Skins.Defs = {}

-- 1) aventurier debutant : chemise de lin, ceinture de cuir, pantalon de toile, bottes, cape courte usee
do
	local d = {}
	local LIN, CUIR, TOILE, BOTTE, CAPE = rgb(214, 200, 168), rgb(98, 62, 36), rgb(112, 98, 82), rgb(72, 46, 30), rgb(72, 86, 60)
	table.insert(d, P("shell", "UpperTorso", Vector3.new(1.07, 1.03, 1.12), nil, LIN, F))
	table.insert(d, P("shell", "LowerTorso", Vector3.new(1.06, 1.1, 1.1), nil, TOILE, F))
	both(d, "shell", "UpperArm", Vector3.new(1.08, 1.02, 1.08), nil, LIN, F)
	both(d, "shell", "LowerArm", Vector3.new(1.07, 0.45, 1.07), CFrame.new(0, 0.32, 0), LIN, F)     -- manches retroussees
	table.insert(d, P("ring", "LowerTorso", Vector3.new(1.08, 1.0, 1.16), nil, CUIR, L))
	table.insert(d, P("shell", "LowerTorso", nil, CFrame.new(0, 0, -0.58), rgb(170, 150, 95), M, Vector3.new(0.3, 0.26, 0.06)))  -- boucle
	both(d, "shell", "UpperLeg", Vector3.new(1.06, 1.02, 1.08), nil, TOILE, F)
	both(d, "shell", "LowerLeg", Vector3.new(1.05, 0.5, 1.06), CFrame.new(0, 0.33, 0), TOILE, F)
	both(d, "shell", "LowerLeg", Vector3.new(1.1, 0.56, 1.12), CFrame.new(0, -0.3, 0), BOTTE, L)
	both(d, "shell", "Foot", Vector3.new(1.06, 1.35, 1.07), CFrame.new(0, 0.02, 0), BOTTE, L)
	table.insert(d, P("cape", "UpperTorso", nil, CFrame.new(0, -0.35, 0.66), CAPE, F, Vector3.new(2.15, 2.0, 0.55)))
	Skins.Defs[1] = d
end

-- 2) chevalier-mage : manteau long sombre a liseres dores, epauliere, bottes hautes
do
	local d = {}
	local NAVY, OR, ACIER, PANT, BOTTE = rgb(30, 32, 50), rgb(204, 164, 72), rgb(62, 64, 74), rgb(38, 36, 44), rgb(22, 20, 24)
	table.insert(d, P("shell", "UpperTorso", Vector3.new(1.08, 1.04, 1.13), nil, NAVY, F))
	table.insert(d, P("shell", "LowerTorso", Vector3.new(1.07, 1.25, 1.12), nil, NAVY, F))
	table.insert(d, P("shell", "UpperTorso", nil, CFrame.new(0, 0, -0.575), OR, FOIL, Vector3.new(0.12, 1.72, 0.06)))     -- liseré central
	table.insert(d, P("ring", "UpperTorso", nil, CFrame.new(0, 0.82, 0), OR, FOIL, Vector3.new(1.35, 0.22, 1.16)))        -- col
	both(d, "shell", "UpperArm", Vector3.new(1.1, 1.03, 1.1), nil, NAVY, F)
	both(d, "shell", "LowerArm", Vector3.new(1.1, 1.0, 1.1), nil, NAVY, F)
	both(d, "shell", "LowerArm", Vector3.new(1.17, 0.17, 1.17), CFrame.new(0, -0.45, 0), OR, FOIL)                         -- poignets dores
	table.insert(d, P("pauldron", "LeftUpperArm", nil, CFrame.new(0, 0.52, 0), ACIER, M, Vector3.new(1.35, 0.75, 1.35)))
	table.insert(d, P("ring", "LeftUpperArm", nil, CFrame.new(0, 0.24, 0), OR, FOIL, Vector3.new(1.4, 0.08, 1.4)))
	-- pans du manteau (devant et derriere, sur chaque cuisse : ils suivent les jambes)
	both(d, "tail", "UpperLeg", nil, CFrame.new(0, -0.5, 0.5), NAVY, F, Vector3.new(1.2, 2.2, 0.45))
	both(d, "tail", "UpperLeg", nil, CFrame.new(0, -0.5, -0.5) * CFrame.Angles(0, math.pi, 0), NAVY, F, Vector3.new(1.2, 2.2, 0.45))
	both(d, "shell", "UpperLeg", Vector3.new(1.05, 1.0, 1.06), nil, PANT, F)
	both(d, "shell", "LowerLeg", Vector3.new(1.12, 1.02, 1.13), nil, BOTTE, L)
	both(d, "shell", "Foot", Vector3.new(1.07, 1.35, 1.08), CFrame.new(0, 0.02, 0), BOTTE, L)
	Skins.Defs[2] = d
end

-- 3) epeiste errant : veste style kimono, larges manches, obi, hakama sombre, echarpe
do
	local d = {}
	local INDIGO, CLAIR, OBI, HAKAMA, ECHARPE, BANDE = rgb(36, 42, 64), rgb(205, 198, 186), rgb(112, 32, 30), rgb(44, 44, 50), rgb(128, 52, 40), rgb(182, 172, 152)
	table.insert(d, P("shell", "UpperTorso", Vector3.new(1.09, 1.04, 1.13), nil, INDIGO, F))
	table.insert(d, P("shell", "UpperTorso", nil, CFrame.new(-0.18, 0.05, -0.58) * CFrame.Angles(0, 0, math.rad(-28)), CLAIR, F, Vector3.new(0.22, 1.45, 0.06)))   -- col croise
	table.insert(d, P("shell", "UpperTorso", nil, CFrame.new(0.2, 0.15, -0.585) * CFrame.Angles(0, 0, math.rad(28)), INDIGO, F, Vector3.new(0.22, 1.2, 0.06)))
	both(d, "flare", "UpperArm", nil, CFrame.new(0, -0.1, 0), INDIGO, F, Vector3.new(1.55, 1.35, 1.45))               -- manches larges
	both(d, "shell", "LowerArm", Vector3.new(1.05, 0.85, 1.05), CFrame.new(0, -0.05, 0), BANDE, F)                      -- bandes de tissu
	table.insert(d, P("ring", "LowerTorso", Vector3.new(1.09, 1.4, 1.15), nil, OBI, F))
	both(d, "flare", "UpperLeg", nil, CFrame.new(0, -0.05, 0), HAKAMA, F, Vector3.new(1.45, 1.45, 1.4))
	both(d, "flare", "LowerLeg", nil, CFrame.new(0, 0.0, 0), HAKAMA, F, Vector3.new(1.6, 1.35, 1.5))
	both(d, "shell", "Foot", Vector3.new(1.04, 1.2, 1.04), CFrame.new(0, 0.02, 0), CLAIR, F)
	table.insert(d, P("scarf", "UpperTorso", nil, CFrame.new(0, 0.5, 0.08), ECHARPE, F, Vector3.new(1.6, 1.55, 1.35)))
	Skins.Defs[3] = d
end

function Skins.Apply(rig, n)
	local old = rig:FindFirstChild("PIPE_Skin"); if old then old:Destroy() end
	local def = Skins.Defs[n]; if not def then return end
	local model = Instance.new("Model"); model.Name = "PIPE_Skin"
	model:SetAttribute("Skin", Skins.Names[n])
	for i, p in ipairs(def) do
		local part = rig:FindFirstChild(p.part)
		local src = RAW:FindFirstChild(p.mesh)
		if part and src then
			local mp = src:Clone()
			mp.Name = "PIPE_" .. p.mesh .. "_" .. p.part .. "_" .. i
			mp.Size = p.abs or (part.Size * p.k)
			mp.Color = p.color; mp.Material = p.mat
			mp.Anchored = false; mp.CanCollide = false; mp.CanQuery = false; mp.CanTouch = false; mp.Massless = true
			mp.CFrame = part.CFrame * p.off
			local w = Instance.new("Weld"); w.Part0 = part; w.Part1 = mp; w.C0 = p.off; w.Parent = mp
			mp.Parent = model
		end
	end
	model.Parent = rig
	-- teint de peau pour la tete et les mains (parties visibles)
	local bc = rig:FindFirstChildOfClass("BodyColors")
	if bc then bc.HeadColor3 = SKIN_TONE; bc.LeftArmColor3 = SKIN_TONE; bc.RightArmColor3 = SKIN_TONE end
	for _, n2 in ipairs({"Head", "LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm"}) do
		local bp = rig:FindFirstChild(n2); if bp then bp.Color = SKIN_TONE end
	end
	return model
end

return Skins
