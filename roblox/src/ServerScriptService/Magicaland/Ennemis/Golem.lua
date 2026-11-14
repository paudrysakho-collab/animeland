-- Golem de mousse : premier ennemi. Avance, s'arrête près du joueur, devient rouge (alerte),
-- puis frappe en se jetant en avant. Reculer pendant l'alerte = esquive.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Donnees = require(ReplicatedStorage:WaitForChild("Magicaland"):WaitForChild("Donnees"))
local M = Donnees.COMBAT.MONSTRE

local Golem = {}

local COULEUR = Color3.fromRGB(86, 150, 70)
local COULEUR_ALERTE = Color3.fromRGB(235, 90, 50)
local TAILLE = Vector3.new(6, 6, 6)

-- Construit le golem (pièces simples). Le pivot est au sol.
function Golem.creer(player, position, def)
	local modele = Instance.new("Model")
	modele.Name = "Monstre_" .. player.Name

	local corps = Instance.new("Part")
	corps.Name = "Corps"
	corps.Shape = Enum.PartType.Ball
	corps.Size = TAILLE
	corps.Color = COULEUR
	corps.Material = Enum.Material.Grass
	corps.Anchored = true
	corps.CanCollide = false
	corps.CFrame = CFrame.new(position + Vector3.new(0, TAILLE.Y / 2, 0))
	corps.Parent = modele
	modele.PrimaryPart = corps

	for _, cote in { -1, 1 } do
		local oeil = Instance.new("Part")
		oeil.Name = "Oeil"
		oeil.Shape = Enum.PartType.Ball
		oeil.Size = Vector3.new(1.1, 1.1, 1.1)
		oeil.Color = Color3.fromRGB(255, 240, 150)
		oeil.Material = Enum.Material.Neon
		oeil.Anchored = true
		oeil.CanCollide = false
		oeil.CFrame = corps.CFrame * CFrame.new(cote * 1.2, 0.9, -2.6)
		oeil.Parent = modele
	end

	modele.Parent = Workspace
	return modele, corps
end

function Golem.init(e, maintenant)
	e.prochaineAttaque = maintenant + 2
	e.prepareJusqua = nil
	e.elanJusqua = 0
	e.posReelle = e.corps.Position -- position sans les décalages d'animation
end

function Golem.annulerAttaque(e, maintenant)
	e.prepareJusqua = nil
	e.corps.Size = TAILLE
	e.prochaineAttaque = math.max(e.prochaineAttaque, maintenant + 1)
end

-- Léger recul quand il est touché.
function Golem.recul(e, depuis)
	local recul = e.posReelle - depuis
	recul = Vector3.new(recul.X, 0, recul.Z)
	if recul.Magnitude > 0.01 then
		e.posReelle += recul.Unit * 0.8
	end
end

function Golem.mettreAJour(e, dt, maintenant, ctx)
	local pos = e.posReelle
	local cible = Vector3.new(ctx.racine.Position.X, pos.Y, ctx.racine.Position.Z)
	local vers = cible - pos
	local dist = vers.Magnitude
	local etourdi = maintenant < e.etourdiFin
	local nouvellePos = pos

	if e.prepareJusqua then
		-- Animation d'alerte : il gonfle et se penche en arrière.
		if maintenant >= e.prepareJusqua then
			e.prepareJusqua = nil
			e.corps.Size = TAILLE
			if dist <= M.portee + 1.5 then
				ctx.frapper(M.degats)
			else
				ctx.envoyer({ type = "esquive" })
			end
			e.prochaineAttaque = maintenant + M.recharge
			e.elanJusqua = maintenant + 0.18 -- bond en avant pendant la frappe
		end
	elseif not etourdi then
		local arret = M.portee - 2.5
		if dist > arret and dist > 0.01 then
			local vitesse = M.vitesse * (maintenant < e.ralentiFin and 0.5 or 1)
			nouvellePos = pos + vers.Unit * math.min(dist - arret, vitesse * dt)
		end
		if dist <= M.portee and maintenant >= e.prochaineAttaque then
			e.prepareJusqua = maintenant + M.preparation
			e.corps.Size = TAILLE * 1.15
			ctx.envoyer({ type = "alerte", attaque = "golem" })
		end
	end

	-- Couleur : flash d'impact, puis alerte, gel, étourdi ou normal.
	if maintenant >= e.flashJusqua then
		if e.prepareJusqua then
			e.corps.Color = COULEUR_ALERTE
		elseif maintenant < e.ralentiFin then
			e.corps.Color = Color3.fromRGB(140, 200, 230)
		elseif etourdi then
			e.corps.Color = Color3.fromRGB(240, 230, 110)
		else
			e.corps.Color = COULEUR
		end
	end

	e.posReelle = nouvellePos
	if dist > 0.01 then
		local cf = CFrame.lookAt(nouvellePos, Vector3.new(cible.X, nouvellePos.Y, cible.Z))
		if e.prepareJusqua then
			cf *= CFrame.Angles(math.rad(15), 0, 0) -- se penche en arrière avant de frapper
		elseif maintenant < e.elanJusqua then
			cf *= CFrame.new(0, 0, -1.8) * CFrame.Angles(math.rad(-20), 0, 0) -- bond en avant
		end
		e.modele:PivotTo(cf)
	end
end

-- Mort : il tourne sur lui-même, rétrécit et s'enfonce dans le sol.
function Golem.detruire(e, raison)
	if raison ~= "victoire" then
		e.modele:Destroy()
		return
	end
	local depart = e.modele:GetPivot()
	local valeur = Instance.new("NumberValue")
	valeur.Changed:Connect(function(t)
		if e.modele.Parent then
			e.modele:PivotTo(depart * CFrame.new(0, -2.5 * t, 0) * CFrame.Angles(0, math.rad(540 * t), 0))
		end
	end)
	for _, partie in e.modele:GetChildren() do
		if partie:IsA("BasePart") then
			TweenService:Create(partie, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Size = Vector3.new(0.2, 0.2, 0.2) }):Play()
		end
	end
	TweenService:Create(valeur, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Value = 1 }):Play()
	task.delay(0.7, function()
		valeur:Destroy()
		e.modele:Destroy()
	end)
end

return Golem
