-- Combat : combats en temps réel contre un ennemi (Golem de mousse ou Colosse des Ronces).
-- Le serveur décide de tout : position de l'ennemi, dégâts, critiques, effets, énergie, recharges et victoire.
-- Le client envoie seulement des intentions (« je veux attaquer », « attaque spéciale n° 3 »).
-- Le comportement propre à chaque ennemi est dans le dossier Ennemis (un module par ennemi).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Donnees = require(ReplicatedStorage:WaitForChild("Magicaland"):WaitForChild("Donnees"))
local C = Donnees.COMBAT
local EN = C.ENERGIE
local EpeeReglages = require(ReplicatedStorage.Magicaland:WaitForChild("EpeeReglages"))

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
-- Style épée : filtre des dégâts reçus (bloc, parade parfaite, projection). Reçoit (player, e, degats, info) et
-- renvoie les dégâts à appliquer, ou nil si le coup est entièrement géré (bloqué ou paré).
Combat.filtreDegatsJoueur = nil

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

---------------------------------------------------------------------
-- Énergie
---------------------------------------------------------------------

-- État des ressources pour l'affichage du client (temps restants en secondes).
local function envoyerRessources(player, e)
	local maintenant = os.clock()
	local recharges = {}
	for i = 1, #C.ATTAQUES do
		recharges[i] = math.max(0, e.pret[i] - maintenant)
	end
	envoyer(player, {
		type = "ressources",
		energie = e.energie,
		energieMax = EN.max,
		recharges = recharges,
	})
end

local function gagnerEnergie(e, n)
	e.energie = math.clamp(e.energie + n, 0, EN.max)
end

-- Dégâts d'un coup : race, faiblesse, résistance, Ombre, critique.
local function calculerDegats(e, mult, critique)
	local race = Donnees.trouver(Donnees.RACES, e.donnees.race)
	local element = e.donnees.element
	local degats = C.DEGATS_BASE * mult * (race and race.degats or 1)
	if element == e.faiblesse then
		degats *= 1.25
	elseif element == e.resistance then
		degats *= 0.8
	end
	if element == "ombre" then
		degats *= 1.2
	end
	if critique then
		degats *= C.MULT_CRITIQUE
	end
	return math.max(1, math.floor(degats + 0.5))
end

-- Effet de l'élément. force : 1 = coup normal, 2 = attaque spéciale, 3 = attaque spéciale renforcée.
-- Les boss résistent mieux aux contrôles.
local function appliquerEffet(e, hum, force, maintenant)
	local element = e.donnees.element
	local boss = e.def.boss
	if element == "feu" then
		e.brulureFin = maintenant + 1 + 2 * force
		e.brulureTick = maintenant + 1
		return "brulure"
	elseif element == "glace" then
		e.ralentiFin = math.max(e.ralentiFin, maintenant + (boss and 0.5 or 1) * (force + 1))
		return "gel"
	elseif element == "foudre" then
		local chance = force == 1 and (boss and 0.1 or 0.25) or 1
		if rng:NextNumber() < chance then
			e.etourdiFin = math.max(e.etourdiFin, maintenant + (boss and 0.3 or 0.6) * (force == 1 and 1.6 or force))
			if e.ia.annulerAttaque then
				e.ia.annulerAttaque(e, maintenant)
			end
			return "choc"
		end
	elseif element == "lumiere" then
		hum.Health = math.min(hum.MaxHealth, hum.Health + (force == 1 and 3 or 8 * force))
		return "soin"
	end
	return nil
end

---------------------------------------------------------------------
-- Fin, dégâts, coups reçus
---------------------------------------------------------------------

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
local function blesserEnnemi(player, e, degats, critique, effet, special, combo)
	e.pv = math.max(0, e.pv - degats)
	majBarre(e)

	-- Flash blanc à l'impact (surbrillance du rig).
	e.flashJusqua = os.clock() + 0.05
	if e.surbrillance then
		e.surbrillance.FillColor = Color3.new(1, 1, 1)
		e.surbrillance.FillTransparency = 0
		task.delay(0.05, function()
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
		combo = combo and combo.combo,
		etape = combo and combo.etape,
		bonus = combo and combo.bonus,
		finition = combo and combo.finition,
		proximite = combo and combo.proximite,
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
	elseif effet ~= "brulureTick" then
		envoyerRessources(player, e)
	end
end

-- L'ennemi touche le joueur : invulnérabilité, défense, bouclier, boucle temporelle, puis vie.
local function frapperJoueur(player, e, hum, degats, info)
	info = info or { lourd = e.attaqueLourde }
	e.attaqueLourde = false
	if os.clock() < e.invulnJusqua then
		envoyer(player, { type = "degatsRecus", degats = 0, absorbe = 0, bouclier = e.bouclier, invulnerable = true })
		return
	end
	if Combat.filtreDegatsJoueur then
		local d = Combat.filtreDegatsJoueur(player, e, degats, info)
		if d == nil then
			envoyerRessources(player, e)
			return
		end
		degats = d
	end
	local absorbe = 0
	if e.bouclier > 0 then
		absorbe = math.min(e.bouclier, degats)
		e.bouclier -= absorbe
		degats -= absorbe
	end
	local boucle = false
	if degats > 0 then
		-- Un coup reçu casse le combo.
		e.combo = 0
		e.comboEtape = 0
		if hum.Health - degats <= 0 and e.donnees.don == "boucle" and not e.boucleUtilisee then
			e.boucleUtilisee = true
			boucle = true
			hum.Health = hum.MaxHealth * 0.5
		else
			hum.Health = math.max(0, hum.Health - degats)
		end
	end
	envoyer(player, { type = "degatsRecus", degats = degats, absorbe = absorbe, bouclier = e.bouclier, boucle = boucle })
	envoyerRessources(player, e)
end

---------------------------------------------------------------------
-- Début du combat
---------------------------------------------------------------------

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

	local pret = {}
	for i = 1, #C.ATTAQUES do
		pret[i] = 0
	end

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
		energie = EN.depart,
		pret = pret, -- heure à laquelle chaque attaque spéciale est de nouveau prête
		lancement = nil, -- attaque spéciale en cours de charge
		invulnJusqua = 0,
		combo = 0, -- coups enchaînés (compteur affiché)
		comboEtape = 0, -- coup du combo (1 à 4)
		dernierCoupCombo = 0,
		prochainCoup = 0, -- heure du prochain coup permis (rythme du combo)
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
	envoyerRessources(player, e)
	return true
end

---------------------------------------------------------------------
-- Actions du joueur (tout est vérifié ici)
---------------------------------------------------------------------

-- Coup normal = un coup du combo (4 coups enchaînés). Le rythme est vérifié ici (anti-triche).
function Combat.attaquer(player)
	local e = combats[player]
	if not e or e.lancement then
		return
	end
	local CO = C.COMBO
	local maintenant = os.clock()
	if maintenant < e.prochainCoup - 0.05 then
		return -- trop tôt : on ignore (petite marge pour le réseau)
	end
	local hum, racine = partiesVivantes(player)
	if not hum then
		return
	end
	-- Trop attendu : le combo repart du coup 1.
	if maintenant - e.dernierCoupCombo > CO.fenetre then
		e.comboEtape = 0
		e.combo = 0
	end
	local vitesse = e.donnees.don == "flux" and 0.7 or 1
	if distancePlat(racine.Position, e.corps.Position) > e.def.porteeJoueur then
		-- Coup de contact trop loin : il frappe dans le vide (le client joue déjà l'animation).
		e.prochainCoup = maintenant + 0.3
		return
	end
	e.comboEtape = e.comboEtape % #CO.etapes + 1
	local etape = CO.etapes[e.comboEtape]
	e.combo += 1
	e.dernierCoupCombo = maintenant
	e.prochainCoup = maintenant + etape.apres * vitesse
	local bonus = math.min(CO.bonusMax, (e.combo - 1) * CO.bonusParCoup)

	local chanceCritique = C.CRITIQUE_BASE + (e.donnees.don == "critique" and 0.15 or 0)
	local critique = rng:NextNumber() < chanceCritique
	local degats = calculerDegats(e, etape.mult * (1 + bonus), critique)
	local effet = appliquerEffet(e, hum, etape.final and 2 or 1, maintenant)
	if etape.final then
		-- Coup final : l'ennemi vacille un instant.
		e.etourdiFin = math.max(e.etourdiFin, maintenant + (e.def.boss and 0.2 or 0.5))
	end

	if e.ia.recul then
		e.ia.recul(e, racine.Position, etape.final and 2 or 1)
	end
	local gain = EN.parCoup + (critique and EN.parCritique or 0) + (etape.final and 1 or 0)
	if e.combo % CO.energieTous == 0 then
		gain += 1
	end
	gagnerEnergie(e, gain)
	blesserEnnemi(player, e, degats, critique, effet, nil, { combo = e.combo, etape = e.comboEtape, bonus = bonus })
end

-- Attaque spéciale n° index (1 à 5) : coût, recharge et portée vérifiés, puis le coup part après la charge.
function Combat.attaqueSpeciale(player, index)
	local e = combats[player]
	if not e or type(index) ~= "number" or e.lancement then
		return
	end
	index = math.floor(index)
	local A = C.ATTAQUES[index]
	if not A then
		return
	end
	local maintenant = os.clock()
	local hum, racine = partiesVivantes(player)
	if not hum then
		return
	end
	if maintenant < e.pret[index] then
		envoyer(player, { type = "refus", raison = "recharge", index = index })
		return
	end
	if e.energie < A.cout then
		envoyer(player, { type = "refus", raison = "energie", index = index })
		return
	end
	-- Portée de l'attaque : plus de refus « trop loin », le coup part toujours (voir plus bas).
	local portee = (A.type == "zone" and A.rayon) or (A.type == "contact" and e.def.porteeJoueur + (A.porteeBonus or 0)) or A.portee
	local pleine = e.def.porteeJoueur + 6 -- jusqu'ici, une attaque à distance fait ses dégâts pleins
	local margeTouche = (A.toucheRayon or 0) + (e.def.boss and 4 or 0)

	-- Validé : on paie tout de suite, la recharge démarre.
	-- Finir un combo par une attaque spéciale renforce l'attaque, puis le combo repart de zéro.
	local CO = C.COMBO
	local finition = (e.combo >= CO.minFinition and maintenant - e.dernierCoupCombo <= CO.fenetre) and e.combo or nil
	e.combo = 0
	e.comboEtape = 0
	local duree = A.charge
	e.energie -= A.cout
	e.pret[index] = maintenant + A.recharge
	e.lancement = index
	if A.invulnerable then
		e.invulnJusqua = math.max(e.invulnJusqua, maintenant + duree + 0.6)
	end
	envoyer(player, { type = "attaque", index = index, charge = duree, element = e.donnees.element })
	envoyerRessources(player, e)

	task.delay(duree, function()
		if combats[player] ~= e then
			return
		end
		e.lancement = nil
		local hum2, racine2 = partiesVivantes(player)
		if not hum2 then
			return
		end
		-- Le coup part toujours : le serveur choisit le point visé et le temps de vol, puis vérifie s'il touche.
		local depart = racine2.Position
		local dist = distancePlat(depart, e.corps.Position)
		local dir = (e.corps.Position - depart) * Vector3.new(1, 0, 1)
		dir = dir.Magnitude > 0.1 and dir.Unit or racine2.CFrame.LookVector
		local vise
		if A.type == "zone" then
			vise = depart
		elseif dist <= portee then
			vise = e.corps.Position
		elseif A.type == "contact" then
			vise = depart + dir * portee -- frappe dans le vide, devant soi
		else
			vise = depart + dir * portee + Vector3.new(0, -2, 0) -- le tir retombe au bout de sa portée
		end
		local vol = (A.vitesse and math.clamp(math.min(dist, portee) / A.vitesse, 0.12, 0.7)) or A.vol or 0.1
		envoyer(player, { type = "lancer", index = index, cible = vise, vol = vol, rayon = A.rayon })

		task.delay(vol, function()
			if combats[player] ~= e then
				return
			end
			local hum3, racine3 = partiesVivantes(player)
			if not hum3 then
				return
			end
			local d = distancePlat(racine3.Position, e.corps.Position)
			local touche
			if A.type == "zone" then
				touche = d <= portee
			elseif A.type == "contact" then
				touche = d <= portee + 2
			else
				-- À distance : il fallait être à portée au départ, et l'ennemi ne doit pas avoir quitté le point visé.
				touche = dist <= portee and distancePlat(vise, e.corps.Position) <= margeTouche
			end
			if not touche then
				envoyer(player, { type = "rate", index = index, pos = vise })
				envoyerRessources(player, e)
				return
			end
			local t = os.clock()
			-- Plus on est près, plus ça fait mal (attaques à distance seulement).
			local proximite = 1
			if A.type == "distance" and dist > pleine then
				local k = math.clamp((dist - pleine) / math.max(1, portee - pleine), 0, 1)
				proximite = 1 - k * (1 - (A.attenuation or 1))
			end
			local chanceCritique = C.CRITIQUE_BASE + (e.donnees.don == "critique" and 0.15 or 0)
			local critique = index >= 5 or rng:NextNumber() < chanceCritique
			local degats = calculerDegats(e, A.mult * proximite * (finition and CO.bonusFinition or 1), critique and index < 5)
			local force = (index >= 5 or A.effetFort) and 3 or 2
			local effet = appliquerEffet(e, hum3, force, t)
			if A.type == "zone" or index >= 5 then
				-- Nova, Jugement et Ultime coupent l'attaque en préparation de l'ennemi.
				e.etourdiFin = math.max(e.etourdiFin, t + (e.def.boss and 0.4 or 1))
				if e.ia.annulerAttaque then
					e.ia.annulerAttaque(e, t)
				end
			end
			if e.ia.recul then
				e.ia.recul(e, A.type == "zone" and racine3.Position or depart, force + (A.type == "zone" and 1 or 0))
			end
			if A.gain then
				gagnerEnergie(e, A.gain)
			end
			blesserEnnemi(player, e, degats, critique, effet, index, { finition = finition, proximite = proximite })
		end)
	end)
end

---------------------------------------------------------------------
-- Boucle commune : brûlure, puis comportement propre à l'ennemi.
---------------------------------------------------------------------
-- Flash rouge (2 clignements) : annonce un coup lourd, impossible à bloquer.
local function flashRouge(e)
	local h = e.surbrillance
	if not h then
		return
	end
	task.spawn(function()
		for _ = 1, 2 do
			h.FillColor = Color3.fromRGB(255, 40, 30)
			h.FillTransparency = 0.35
			task.wait(0.09)
			h.FillTransparency = 1
			task.wait(0.07)
		end
		h.FillColor = Color3.new(1, 1, 1)
	end)
end

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
			frapper = function(degats, info)
				frapperJoueur(player, e, hum, degats, info)
			end,
			envoyer = function(message)
				-- Coups lourds (imparables) : 1 attaque sur 3 du golem, les racines du colosse ; flash rouge sur l'ennemi.
				if message.type == "alerte" then
					e.nbAlertes = (e.nbAlertes or 0) + 1
					local lourd = message.lourd or message.attaque == "racines" or (e.type == "golem" and e.nbAlertes % EpeeReglages.LOURD_TOUS_LES == 0)
					message.lourd = lourd
					e.attaqueLourde = lourd
					if lourd then
						flashRouge(e)
					end
				elseif message.type == "esquive" then
					e.attaqueLourde = false
				end
				-- Une attaque esquivée rapporte de l'énergie.
				if message.type == "esquive" then
					gagnerEnergie(e, EN.parEsquive)
				end
				envoyer(player, message)
				if message.type == "esquive" then
					envoyerRessources(player, e)
				end
			end,
		})
	end
end

function Combat.estEnCombat(player)
	return combats[player] ~= nil
end

function Combat.oublier(_player)
	-- Rien à oublier entre deux combats depuis la suppression de l'ancienne jauge de transformation.
end

-- Pour les tests dans Studio : remplit l'énergie.
function Combat._remplirPourTest(player)
	local e = combats[player]
	if e then
		e.energie = EN.max
		envoyerRessources(player, e)
	end
end

-- Accès interne pour le style épée (module Epee) : il réutilise exactement les mêmes règles
-- (dégâts, critiques, effets, énergie, recharges, victoire) au lieu de les dupliquer.
Combat._interne = {
	combats = combats,
	rng = rng,
	envoyer = envoyer,
	envoyerRessources = envoyerRessources,
	partiesVivantes = partiesVivantes,
	distancePlat = distancePlat,
	calculerDegats = calculerDegats,
	blesserEnnemi = blesserEnnemi,
	appliquerEffet = appliquerEffet,
	gagnerEnergie = gagnerEnergie,
}

function Combat.init(remoteEtatCombat)
	remoteEtat = remoteEtatCombat
	RunService.Heartbeat:Connect(mettreAJour)
end

return Combat
