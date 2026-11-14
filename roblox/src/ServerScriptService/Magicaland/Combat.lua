-- Combat : premier combat en temps réel, joueur contre un Golem de mousse.
-- Le serveur décide de tout : position du monstre, dégâts, critiques, effets, victoire.
-- Le client envoie seulement « je veux attaquer ».

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Donnees = require(ReplicatedStorage:WaitForChild("Magicaland"):WaitForChild("Donnees"))
local C = Donnees.COMBAT
local M = C.MONSTRE

local Combat = {}

local combats = {} -- [Player] = état du combat en cours
local remoteEtat = nil
local rng = Random.new()

local COULEUR_MONSTRE = Color3.fromRGB(86, 150, 70)
local COULEUR_ALERTE = Color3.fromRGB(235, 90, 50)
local TAILLE_MONSTRE = Vector3.new(6, 6, 6)

-- Appelé quand un monstre tombe (branché par Principal pour donner la récompense).
Combat.surVictoire = nil

local function envoyer(player, message)
	if remoteEtat and player.Parent then
		remoteEtat:FireClient(player, message)
	end
end

local function partiesVivantes(player)
	local perso = player.Character
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	local racine = perso and perso:FindFirstChild("HumanoidRootPart")
	if hum and racine and hum.Health > 0 then
		return hum, racine
	end
	return nil, nil
end

local function distancePlat(a, b)
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- Applique les bonus de race au personnage (vie et vitesse).
function Combat.appliquerRace(player, donnees)
	local perso = player.Character
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	local race = donnees and Donnees.trouver(Donnees.RACES, donnees.race)
	if not (hum and race) then
		return
	end
	local pvMax = math.floor(C.PV_JOUEUR * race.pv)
	hum.MaxHealth = pvMax
	hum.Health = pvMax
	hum.WalkSpeed = race.vitesse
end

-- Construit le Golem de mousse (pièces simples) avec sa barre de vie.
local function creerMonstre(player, position)
	local modele = Instance.new("Model")
	modele.Name = "Monstre_" .. player.Name

	local corps = Instance.new("Part")
	corps.Name = "Corps"
	corps.Shape = Enum.PartType.Ball
	corps.Size = TAILLE_MONSTRE
	corps.Color = COULEUR_MONSTRE
	corps.Material = Enum.Material.Grass
	corps.Anchored = true
	corps.CanCollide = false
	corps.CFrame = CFrame.new(position)
	corps.Parent = modele
	modele.PrimaryPart = corps

	-- Deux yeux qui brillent, tournés vers l'avant (-Z).
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

	-- Barre de vie au-dessus du monstre.
	local panneau = Instance.new("BillboardGui")
	panneau.Name = "BarreVie"
	panneau.Size = UDim2.fromOffset(180, 46)
	panneau.StudsOffset = Vector3.new(0, 5, 0)
	panneau.AlwaysOnTop = true
	panneau.MaxDistance = 120
	panneau.Parent = corps

	local nom = Instance.new("TextLabel")
	nom.Name = "Nom"
	nom.BackgroundTransparency = 1
	nom.Size = UDim2.new(1, 0, 0, 20)
	nom.Font = Enum.Font.GothamBold
	nom.TextSize = 16
	nom.TextColor3 = Color3.new(1, 1, 1)
	nom.TextStrokeTransparency = 0.4
	nom.Text = M.nom
	nom.Parent = panneau

	local fond = Instance.new("Frame")
	fond.Name = "Fond"
	fond.Position = UDim2.fromOffset(0, 24)
	fond.Size = UDim2.new(1, 0, 0, 16)
	fond.BackgroundColor3 = Color3.fromRGB(30, 20, 30)
	fond.BorderSizePixel = 0
	fond.Parent = panneau
	Instance.new("UICorner", fond).CornerRadius = UDim.new(0, 6)

	local remplissage = Instance.new("Frame")
	remplissage.Name = "Remplissage"
	remplissage.Size = UDim2.fromScale(1, 1)
	remplissage.BackgroundColor3 = Color3.fromRGB(110, 210, 90)
	remplissage.BorderSizePixel = 0
	remplissage.Parent = fond
	Instance.new("UICorner", remplissage).CornerRadius = UDim.new(0, 6)

	local valeur = Instance.new("TextLabel")
	valeur.Name = "Valeur"
	valeur.BackgroundTransparency = 1
	valeur.Size = UDim2.fromScale(1, 1)
	valeur.Font = Enum.Font.GothamBold
	valeur.TextSize = 12
	valeur.TextColor3 = Color3.new(1, 1, 1)
	valeur.Text = M.pv .. " / " .. M.pv
	valeur.ZIndex = 2
	valeur.Parent = fond

	modele.Parent = Workspace
	return modele, corps
end

local function majBarre(e)
	local fond = e.corps:FindFirstChild("BarreVie") and e.corps.BarreVie:FindFirstChild("Fond")
	if not fond then
		return
	end
	local ratio = math.clamp(e.pv / e.pvMax, 0, 1)
	fond.Remplissage.Size = UDim2.fromScale(ratio, 1)
	fond.Remplissage.BackgroundColor3 = Color3.fromRGB(230, 70, 60):Lerp(Color3.fromRGB(110, 210, 90), ratio)
	fond.Valeur.Text = math.ceil(e.pv) .. " / " .. e.pvMax
end

-- Fin du combat, quelle qu'en soit la raison (victoire, défaite, départ).
function Combat.terminer(player, raison)
	local e = combats[player]
	if not e then
		return
	end
	combats[player] = nil
	if raison == "victoire" then
		-- Le monstre rétrécit puis disparaît.
		for _, partie in e.modele:GetChildren() do
			if partie:IsA("BasePart") then
				TweenService:Create(partie, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Size = Vector3.new(0.2, 0.2, 0.2) }):Play()
			end
		end
		task.delay(0.4, function()
			e.modele:Destroy()
		end)
	else
		e.modele:Destroy()
	end
	if raison == "defaite" then
		envoyer(player, { type = "defaite" })
	end
end

-- Inflige des dégâts au monstre et prévient le client.
local function blesserMonstre(player, e, degats, critique, effet)
	e.pv = math.max(0, e.pv - degats)
	majBarre(e)

	-- Petit flash blanc à l'impact.
	e.flashJusqua = os.clock() + 0.08
	e.corps.Color = Color3.new(1, 1, 1)

	envoyer(player, { type = "coup", degats = degats, critique = critique, effet = effet, pv = e.pv, pvMax = e.pvMax })

	if e.pv <= 0 then
		local recompense = C.RECOMPENSE_PIECES
		local total = nil
		if Combat.surVictoire then
			total = Combat.surVictoire(player, recompense)
		end
		Combat.terminer(player, "victoire")
		envoyer(player, { type = "victoire", pieces = recompense, total = total })
	end
end

-- Le monstre frappe le joueur.
local function frapperJoueur(player, e, hum)
	local degats = M.degats
	local absorbe = 0
	if e.bouclier > 0 then
		absorbe = math.min(e.bouclier, degats)
		e.bouclier -= absorbe
		degats -= absorbe
	end
	local boucle = false
	if degats > 0 then
		if hum.Health - degats <= 0 and e.donnees.don == "boucle" and not e.boucleUtilisee then
			e.boucleUtilisee = true
			boucle = true
			hum.Health = hum.MaxHealth * 0.5
		else
			hum.Health = math.max(0, hum.Health - degats)
		end
	end
	envoyer(player, { type = "degatsRecus", degats = degats, absorbe = absorbe, bouclier = e.bouclier, boucle = boucle })
end

-- Démarre le combat si tout est en ordre.
function Combat.demarrer(player, donnees)
	if combats[player] or not donnees then
		return false
	end
	local hum, racine = partiesVivantes(player)
	if not hum then
		return false
	end

	-- Le monstre apparaît à 18 studs devant le joueur, posé sur le sol.
	local devant = racine.CFrame.LookVector * Vector3.new(1, 0, 1)
	if devant.Magnitude < 0.1 then
		devant = Vector3.new(0, 0, -1)
	end
	local point = racine.Position + devant.Unit * 18
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local sol = Workspace:Raycast(point + Vector3.new(0, 40, 0), Vector3.new(0, -200, 0), params)
	local hauteur = sol and sol.Position.Y or (racine.Position.Y - 3)
	local position = Vector3.new(point.X, hauteur + TAILLE_MONSTRE.Y / 2, point.Z)

	local modele, corps = creerMonstre(player, position)
	modele:PivotTo(CFrame.lookAt(position, Vector3.new(racine.Position.X, position.Y, racine.Position.Z)))

	local maintenant = os.clock()
	combats[player] = {
		modele = modele,
		corps = corps,
		donnees = donnees,
		pv = M.pv,
		pvMax = M.pv,
		derniereAttaque = 0,
		prochaineAttaqueMonstre = maintenant + 2,
		prepareJusqua = nil,
		brulureFin = 0,
		brulureTick = 0,
		ralentiFin = 0,
		etourdiFin = 0,
		flashJusqua = 0,
		bouclier = donnees.don == "barriere" and 30 or 0,
		boucleUtilisee = false,
	}
	envoyer(player, { type = "debut", modele = modele, nom = M.nom, pv = M.pv, pvMax = M.pv, bouclier = combats[player].bouclier })
	return true
end

-- Demande d'attaque du joueur : tout est vérifié ici.
function Combat.attaquer(player)
	local e = combats[player]
	if not e then
		return
	end
	local maintenant = os.clock()
	local recharge = C.RECHARGE_ATTAQUE * (e.donnees.don == "flux" and 0.7 or 1)
	if maintenant - e.derniereAttaque < recharge then
		return -- trop tôt : on ignore (anti-spam)
	end
	local hum, racine = partiesVivantes(player)
	if not hum then
		return
	end
	if distancePlat(racine.Position, e.corps.Position) > C.PORTEE_ATTAQUE then
		e.derniereAttaque = maintenant
		envoyer(player, { type = "tropLoin" })
		return
	end
	e.derniereAttaque = maintenant

	local race = Donnees.trouver(Donnees.RACES, e.donnees.race)
	local element = e.donnees.element
	local degats = C.DEGATS_BASE * (race and race.degats or 1)
	if element == M.faiblesse then
		degats *= 1.25
	elseif element == M.resistance then
		degats *= 0.8
	end
	if element == "ombre" then
		degats *= 1.2
	end

	local chanceCritique = C.CRITIQUE_BASE + (e.donnees.don == "critique" and 0.15 or 0)
	local critique = rng:NextNumber() < chanceCritique
	if critique then
		degats *= C.MULT_CRITIQUE
	end
	degats = math.max(1, math.floor(degats + 0.5))

	-- Effet de l'élément.
	local effet = nil
	if element == "feu" then
		e.brulureFin = maintenant + 3
		e.brulureTick = maintenant + 1
		effet = "brulure"
	elseif element == "glace" then
		e.ralentiFin = maintenant + 2
		effet = "gel"
	elseif element == "foudre" and rng:NextNumber() < 0.25 then
		e.etourdiFin = maintenant + 1
		e.prepareJusqua = nil -- le coup en préparation est annulé
		e.prochaineAttaqueMonstre = math.max(e.prochaineAttaqueMonstre, maintenant + 1)
		effet = "choc"
	elseif element == "lumiere" then
		hum.Health = math.min(hum.MaxHealth, hum.Health + 3)
		effet = "soin"
	end

	-- Léger recul du monstre.
	local recul = e.corps.Position - racine.Position
	recul = Vector3.new(recul.X, 0, recul.Z)
	if recul.Magnitude > 0.01 then
		e.modele:PivotTo(e.modele:GetPivot() + recul.Unit * 0.8)
	end

	blesserMonstre(player, e, degats, critique, effet)
end

-- Boucle du monstre : avance, prépare son coup (alerte), frappe.
local function mettreAJour(dt)
	local maintenant = os.clock()
	for player, e in combats do
		local hum, racine = partiesVivantes(player)
		if not hum then
			Combat.terminer(player, "defaite")
			continue
		end

		-- Brûlure : 4 dégâts par seconde.
		if maintenant < e.brulureFin + 0.05 and maintenant >= e.brulureTick then
			e.brulureTick += 1
			blesserMonstre(player, e, 4, false, "brulureTick")
			if not combats[player] then
				continue
			end
		end

		local pos = e.corps.Position
		local cible = Vector3.new(racine.Position.X, pos.Y, racine.Position.Z)
		local vers = cible - pos
		local dist = vers.Magnitude
		local etourdi = maintenant < e.etourdiFin
		local nouvellePos = pos

		if e.prepareJusqua then
			if maintenant >= e.prepareJusqua then
				e.prepareJusqua = nil
				e.corps.Size = TAILLE_MONSTRE
				if dist <= M.portee + 1.5 then
					frapperJoueur(player, e, hum)
				else
					envoyer(player, { type = "esquive" })
				end
				e.prochaineAttaqueMonstre = maintenant + M.recharge
			end
		elseif not etourdi then
			local arret = M.portee - 2.5
			if dist > arret and dist > 0.01 then
				local vitesse = M.vitesse * (maintenant < e.ralentiFin and 0.5 or 1)
				nouvellePos = pos + vers.Unit * math.min(dist - arret, vitesse * dt)
			end
			if dist <= M.portee and maintenant >= e.prochaineAttaqueMonstre then
				e.prepareJusqua = maintenant + M.preparation
				e.corps.Size = TAILLE_MONSTRE * 1.15
				envoyer(player, { type = "alerte" })
			end
		end

		-- Couleur : flash d'impact, puis alerte, gel ou normal.
		if maintenant >= e.flashJusqua then
			if e.prepareJusqua then
				e.corps.Color = COULEUR_ALERTE
			elseif maintenant < e.ralentiFin then
				e.corps.Color = Color3.fromRGB(140, 200, 230)
			elseif etourdi then
				e.corps.Color = Color3.fromRGB(240, 230, 110)
			else
				e.corps.Color = COULEUR_MONSTRE
			end
		end

		if dist > 0.01 then
			e.modele:PivotTo(CFrame.lookAt(nouvellePos, Vector3.new(cible.X, nouvellePos.Y, cible.Z)))
		end
	end
end

function Combat.estEnCombat(player)
	return combats[player] ~= nil
end

function Combat.init(remoteEtatCombat)
	remoteEtat = remoteEtatCombat
	RunService.Heartbeat:Connect(mettreAJour)
end

return Combat
