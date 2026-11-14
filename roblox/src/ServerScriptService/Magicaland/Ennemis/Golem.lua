-- Golem de mousse : monstre riggé R15 (≈ 8 studs) couvert de pierres et de mousse, yeux qui brillent.
-- Il marche vers le joueur, lève le bras (contour rouge = alerte), puis frappe en se fendant en avant.
-- Reculer ou esquiver (Q) pendant l'alerte = esquive.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Donnees = require(ReplicatedStorage:WaitForChild("Magicaland"):WaitForChild("Donnees"))
local Rigs = require(script.Parent.Parent:WaitForChild("Rigs"))
local M = Donnees.COMBAT.MONSTRE

local Golem = {}

local ECHELLE = 1.7
local MOUSSE = Color3.fromRGB(86, 150, 70)
local PIERRE = Color3.fromRGB(105, 110, 100)

local function decorer(m)
	local R = CFrame.Angles
	-- Pierres sur les épaules et le dos, mousse sur la tête, yeux lumineux.
	for _, cote in { "Left", "Right" } do
		Rigs.accrocher(m, cote .. "UpperArm", Vector3.new(1.4, 1, 1.4), PIERRE, Enum.Material.Slate, CFrame.new(0, 0.5, 0) * R(0.3, 0.5, 0.2))
		Rigs.accrocher(m, cote .. "LowerArm", Vector3.new(1.2, 1.1, 1.2), PIERRE, Enum.Material.Slate, CFrame.new(0, -0.2, 0) * R(0.2, 0.9, 0))
	end
	Rigs.accrocher(m, "UpperTorso", Vector3.new(2.2, 1.6, 0.8), PIERRE, Enum.Material.Slate, CFrame.new(0, 0.2, 0.7) * R(0.1, 0, 0.05))
	Rigs.accrocher(m, "Head", Vector3.new(1.6, 0.5, 1.4), MOUSSE, Enum.Material.Grass, CFrame.new(0, 0.6, 0))
	for _, x in { -0.28, 0.28 } do
		local oeil = Rigs.accrocher(m, "Head", Vector3.new(0.3, 0.2, 0.1), Color3.fromRGB(255, 230, 120), Enum.Material.Neon, CFrame.new(x, 0.1, -0.6))
		local lumiere = Instance.new("PointLight")
		lumiere.Color = Color3.fromRGB(255, 220, 120)
		lumiere.Range = 6
		lumiere.Brightness = 1
		lumiere.Parent = oeil
	end
end

function Golem.creer(player, position, def)
	local m, hum, racine, pistes, surbrillance = Rigs.creer("Monstre_" .. player.Name, {
		tete = MOUSSE,
		corps = Color3.fromRGB(70, 120, 60),
		bras = MOUSSE,
		jambes = Color3.fromRGB(60, 100, 50),
		largeur = 1.4,
		profondeur = 1.3,
	}, ECHELLE, position, decorer)
	hum.WalkSpeed = M.vitesse + 3
	return m, racine, m:FindFirstChild("Head"), { hum = hum, pistes = pistes, surbrillance = surbrillance }
end

function Golem.init(e, maintenant)
	e.echelle = ECHELLE
	e.prochaineAttaque = maintenant + 2
	e.prepareJusqua = nil
	e.prochainChemin = 0
end

function Golem.annulerAttaque(e, maintenant)
	e.prepareJusqua = nil
	e.surbrillance.OutlineTransparency = 1
	e.pistes.coup:Stop(0.1)
	e.hum.AutoRotate = true
	e.prochaineAttaque = math.max(e.prochaineAttaque, maintenant + 1)
end

-- Recul physique quand il est touché.
function Golem.recul(e, depuis)
	local dir = (e.racine.Position - depuis) * Vector3.new(1, 0, 1)
	if dir.Magnitude > 0.01 then
		e.racine:ApplyImpulse(dir.Unit * e.racine.AssemblyMass * 18)
	end
end

function Golem.mettreAJour(e, dt, maintenant, ctx)
	local pos = e.racine.Position
	local joueur = ctx.racine.Position
	local dist = (Vector3.new(joueur.X, 0, joueur.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
	local etourdi = maintenant < e.etourdiFin
	local portee = M.portee

	if e.prepareJusqua then
		if maintenant >= e.prepareJusqua then
			-- Frappe : l'animation repart vite, il se fend en avant.
			e.prepareJusqua = nil
			e.surbrillance.OutlineTransparency = 1
			e.pistes.coup:AdjustSpeed(2.2)
			e.racine:ApplyImpulse(e.racine.CFrame.LookVector * e.racine.AssemblyMass * 30)
			if dist <= portee + 1.5 then
				ctx.frapper(M.degats)
			else
				ctx.envoyer({ type = "esquive" })
			end
			e.prochaineAttaque = maintenant + M.recharge
			task.delay(0.4, function()
				e.hum.AutoRotate = true
			end)
		end
	elseif etourdi then
		e.hum:Move(Vector3.zero)
	else
		e.hum.WalkSpeed = (M.vitesse + 3) * (maintenant < e.ralentiFin and 0.5 or 1)
		if dist > portee - 2 then
			if maintenant >= e.prochainChemin then
				e.prochainChemin = maintenant + 0.15
				e.hum:MoveTo(joueur)
			end
		else
			e.hum:Move(Vector3.zero)
			Rigs.regarder(e, joueur)
		end
		if dist <= portee and maintenant >= e.prochaineAttaque then
			-- Alerte : contour rouge, bras levé au ralenti.
			e.prepareJusqua = maintenant + M.preparation
			e.hum:Move(Vector3.zero)
			e.hum.AutoRotate = false
			Rigs.regarder(e, joueur)
			e.surbrillance.OutlineTransparency = 0
			e.pistes.coup:Play(0.1)
			e.pistes.coup:AdjustSpeed(0.25)
			ctx.envoyer({ type = "alerte", attaque = "golem" })
		end
	end

	Rigs.majLocomotion(e)
end

function Golem.detruire(e, raison)
	if raison ~= "victoire" then
		e.modele:Destroy()
		return
	end
	local recul = -e.racine.CFrame.LookVector * 25 + Vector3.new(0, 30, 0)
	Rigs.mourir(e.modele, e.racine, recul)
end

return Golem
