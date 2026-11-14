-- Combat : combats en temps réel contre un ennemi (Golem de mousse ou Colosse des Ronces).
-- Le serveur décide de tout : position de l'ennemi, dégâts, critiques, effets, victoire.
-- Le client envoie seulement « je veux attaquer ».
-- Le comportement propre à chaque ennemi est dans le dossier Ennemis (un module par ennemi).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Donnees = require(ReplicatedStorage:WaitForChild("Magicaland"):WaitForChild("Donnees"))
local C = Donnees.COMBAT

local dossierEnnemis = script.Parent:WaitForChild("Ennemis")
local IA = {
	golem = require(dossierEnnemis:WaitForChild("Golem")),
	colosse = require(dossierEnnemis:WaitForChild("Colosse")),
}

local Combat = {}

local combats = {} -- [Player] = état du combat en cours
local remoteEtat = nil
local rng = Random.new()

-- Appelé quand un ennemi tombe (branché par Principal pour donner la récompense).
-- Reçoit (player, e) et renvoie { total, victoires, objet }.
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

-- Barre de vie au-dessus de l'ennemi.
local function creerBarre(corps, nom, pv, hauteur, boss)
	local largeur = boss and 260 or 180
	local panneau = Instance.new("BillboardGui")
	panneau.Name = "BarreVie"
	panneau.Size = UDim2.fromOffset(largeur, 46)
	panneau.StudsOffsetWorldSpace = Vector3.new(0, hauteur, 0)
	panneau.AlwaysOnTop = true
	panneau.MaxDistance = 200
	panneau.Parent = corps

	local etiquette = Instance.new("TextLabel")
	etiquette.Name = "Nom"
	etiquette.BackgroundTransparency = 1
	etiquette.Size = UDim2.new(1, 0, 0, 20)
	etiquette.Font = Enum.Font.GothamBold
	etiquette.TextSize = boss and 18 or 16
	etiquette.TextColor3 = boss and Color3.fromRGB(255, 200, 110) or Color3.new(1, 1, 1)
	etiquette.TextStrokeTransparency = 0.4
	etiquette.Text = nom
	etiquette.Parent = panneau

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
	valeur.Text = pv .. " / " .. pv
	valeur.ZIndex = 2
	valeur.Parent = fond
	return panneau
end

local function majBarre(e)
	local panneau = e.barre
	local fond = panneau and panneau.Parent and panneau:FindFirstChild("Fond")
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
	e.ia.detruire(e, raison)
	if raison == "defaite" then
		envoyer(player, { type = "defaite", ennemi = e.type, nom = e.def.nom })
		-- Retour garanti du joueur, même si son personnage n'est pas mort (chute, bug).
		task.delay(3, function()
			if player.Parent and not combats[player] then
				player:LoadCharacter()
			end
		end)
	end
end

-- Inflige des dégâts à l'ennemi et prévient le client.
local function blesserEnnemi(player, e, degats, critique, effet, special)
	e.pv = math.max(0, e.pv - degats)
	majBarre(e)

	-- Flash blanc à l'impact (surbrillance du rig).
	e.flashJusqua = os.clock() + 0.08
	if e.surbrillance then
		e.surbrillance.FillTransparency = 0.25
		task.delay(0.08, function()
			if e.surbrillance.Parent then
				e.surbrillance.FillTransparency = 1
			end
		end)
	end

	envoyer(player, {
		type = "coup",
		degats = degats,
		critique = critique,
		effet = effet,
		special = special,
		pv = e.pv,
		pvMax = e.pvMax,
		pos = e.corps.Position,
	})

	if e.pv <= 0 then
		local infos = Combat.surVictoire and Combat.surVictoire(player, e) or {}
		Combat.terminer(player, "victoire")
		envoyer(player, {
			type = "victoire",
			ennemi = e.type,
			nom = e.def.nom,
			boss = e.def.boss,
			pieces = e.def.recompense,
			total = infos.total,
			victoires = infos.victoires,
			objet = infos.objet,
		})
	end
end

-- L'ennemi touche le joueur : bouclier, boucle temporelle, puis vie.
local function frapperJoueur(player, e, hum, degats)
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

-- Démarre un combat si tout est en ordre. typeEnnemi : "golem" ou "colosse".
function Combat.demarrer(player, donnees, typeEnnemi)
	local def = Donnees.ENNEMIS[typeEnnemi]
	local ia = IA[typeEnnemi]
	if combats[player] or not donnees or not def or not ia then
		return false
	end
	local hum, racine = partiesVivantes(player)
	if not hum then
		return false
	end

	-- L'ennemi apparaît devant le joueur, posé sur le sol.
	local devant = racine.CFrame.LookVector * Vector3.new(1, 0, 1)
	if devant.Magnitude < 0.1 then
		devant = Vector3.new(0, 0, -1)
	end
	local point = racine.Position + devant.Unit * def.distanceApparition
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local touche = Workspace:Raycast(point + Vector3.new(0, 40, 0), Vector3.new(0, -200, 0), params)
	local sol = touche and touche.Position.Y or (racine.Position.Y - 3)
	local position = Vector3.new(point.X, sol, point.Z)

	local modele, corps, tete, extras = ia.creer(player, position, def)
	extras = extras or {}
	local barre = creerBarre(tete or corps, def.nom, def.pv, def.hauteurBarre, def.boss)
	modele:PivotTo(CFrame.lookAt(modele:GetPivot().Position, Vector3.new(racine.Position.X, modele:GetPivot().Position.Y, racine.Position.Z)))

	local e = {
		type = typeEnnemi,
		def = def,
		ia = ia,
		modele = modele,
		corps = corps,
		racine = corps,
		tete = tete,
		barre = barre,
		hum = extras.hum,
		pistes = extras.pistes,
		surbrillance = extras.surbrillance,
		derniereSpeciale = 0,
		sol = sol,
		donnees = donnees,
		pv = def.pv,
		pvMax = def.pv,
		faiblesse = def.faiblesse,
		resistance = def.resistance,
		derniereAttaque = 0,
		brulureFin = 0,
		brulureTick = 0,
		ralentiFin = 0,
		etourdiFin = 0,
		flashJusqua = 0,
		bouclier = donnees.don == "barriere" and 30 or 0,
		boucleUtilisee = false,
	}
	ia.init(e, os.clock())
	combats[player] = e
	envoyer(player, {
		type = "debut",
		ennemi = typeEnnemi,
		boss = def.boss,
		modele = modele,
		nomModele = modele.Name,
		nom = def.nom,
		pv = e.pv,
		pvMax = e.pvMax,
		bouclier = e.bouclier,
		intro = e.duree_intro,
	})
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
	if distancePlat(racine.Position, e.corps.Position) > e.def.porteeJoueur then
		e.derniereAttaque = maintenant
		envoyer(player, { type = "tropLoin" })
		return
	end
	e.derniereAttaque = maintenant

	local race = Donnees.trouver(Donnees.RACES, e.donnees.race)
	local element = e.donnees.element
	local degats = C.DEGATS_BASE * (race and race.degats or 1)
	if element == e.faiblesse then
		degats *= 1.25
	elseif element == e.resistance then
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

	-- Effet de l'élément (les boss résistent mieux aux contrôles).
	local effet = nil
	if element == "feu" then
		e.brulureFin = maintenant + 3
		e.brulureTick = maintenant + 1
		effet = "brulure"
	elseif element == "glace" then
		e.ralentiFin = maintenant + (e.def.boss and 1 or 2)
		effet = "gel"
	elseif element == "foudre" and rng:NextNumber() < (e.def.boss and 0.1 or 0.25) then
		e.etourdiFin = maintenant + 1
		if e.ia.annulerAttaque then
			e.ia.annulerAttaque(e, maintenant)
		end
		effet = "choc"
	elseif element == "lumiere" then
		hum.Health = math.min(hum.MaxHealth, hum.Health + 3)
		effet = "soin"
	end

	if e.ia.recul then
		e.ia.recul(e, racine.Position)
	end

	blesserEnnemi(player, e, degats, critique, effet)
end

-- Attaque spéciale de l'élément (après une charge côté client) : gros dégâts, effet renforcé.
function Combat.special(player)
	local e = combats[player]
	if not e then
		return
	end
	local S = C.SPECIAL
	local maintenant = os.clock()
	if maintenant - e.derniereSpeciale < S.recharge then
		return
	end
	local hum, racine = partiesVivantes(player)
	if not hum then
		return
	end
	if distancePlat(racine.Position, e.corps.Position) > e.def.porteeJoueur + S.porteeBonus then
		envoyer(player, { type = "tropLoin" })
		return
	end
	e.derniereSpeciale = maintenant

	local race = Donnees.trouver(Donnees.RACES, e.donnees.race)
	local element = e.donnees.element
	local degats = C.DEGATS_BASE * S.mult * (race and race.degats or 1)
	if element == e.faiblesse then
		degats *= 1.25
	elseif element == e.resistance then
		degats *= 0.8
	end
	if element == "ombre" then
		degats *= 1.2
	end
	degats = math.floor(degats + 0.5)

	local boss = e.def.boss
	if element == "feu" then
		e.brulureFin = maintenant + 5
		e.brulureTick = maintenant + 1
	elseif element == "glace" then
		e.ralentiFin = maintenant + (boss and 1.5 or 3)
	elseif element == "foudre" then
		e.etourdiFin = maintenant + (boss and 0.6 or 1.5)
		if e.ia.annulerAttaque then
			e.ia.annulerAttaque(e, maintenant)
		end
	elseif element == "lumiere" then
		hum.Health = math.min(hum.MaxHealth, hum.Health + 20)
	end
	if e.ia.recul then
		e.ia.recul(e, racine.Position)
	end
	blesserEnnemi(player, e, degats, true, element, true)
end

-- Boucle commune : brûlure, puis comportement propre à l'ennemi.
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
			blesserEnnemi(player, e, 4, false, "brulureTick")
			if not combats[player] then
				continue
			end
		end

		e.ia.mettreAJour(e, dt, maintenant, {
			hum = hum,
			racine = racine,
			frapper = function(degats)
				frapperJoueur(player, e, hum, degats)
			end,
			envoyer = function(message)
				envoyer(player, message)
			end,
		})
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
