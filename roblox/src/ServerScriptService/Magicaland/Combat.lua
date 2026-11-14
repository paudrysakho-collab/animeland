-- Combat : combats en temps réel contre un ennemi (Golem de mousse ou Colosse des Ronces).
-- Le serveur décide de tout : position de l'ennemi, dégâts, critiques, effets, énergie, recharges,
-- transformation et victoire. Le client envoie seulement des intentions (« je veux attaquer »,
-- « attaque spéciale n° 3 », « je me transforme »).
-- Le comportement propre à chaque ennemi est dans le dossier Ennemis (un module par ennemi).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Donnees = require(ReplicatedStorage:WaitForChild("Magicaland"):WaitForChild("Donnees"))
local C = Donnees.COMBAT
local EN = C.ENERGIE
local TR = C.TRANSFO

local dossierEnnemis = script.Parent:WaitForChild("Ennemis")
local IA = {
	golem = require(dossierEnnemis:WaitForChild("Golem")),
	colosse = require(dossierEnnemis:WaitForChild("Colosse")),
}

local Combat = {}

local combats = {} -- [Player] = état du combat en cours
local jauges = {} -- [Player] = jauge de transformation (garde sa valeur d'un combat à l'autre)
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

local function vitesseRace(donnees)
	local race = donnees and Donnees.trouver(Donnees.RACES, donnees.race)
	return race and race.vitesse or 16
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
-- Énergie, jauge de transformation, bonus
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
		jauge = math.floor(jauges[player] or 0),
		jaugeMax = TR.jaugeMax,
		recharges = recharges,
		transfo = e.transfoFin and math.max(0, e.transfoFin - maintenant) or 0,
		epuise = e.epuiseFin and math.max(0, e.epuiseFin - maintenant) or 0,
	})
end

local function gagnerEnergie(e, n)
	e.energie = math.clamp(e.energie + n, 0, EN.max)
end

local function remplirJauge(player, e, n)
	if e.transfoFin then
		return -- pas de remplissage pendant la transformation
	end
	jauges[player] = math.clamp((jauges[player] or 0) + n, 0, TR.jaugeMax)
end

-- Bonus en cours : transformation (plus fort) ou épuisement (plus faible).
local function multDegats(e)
	if e.transfoFin then
		return TR.degats
	elseif e.epuiseFin then
		return TR.epuiseDegats
	end
	return 1
end

local function multRecharge(e)
	return e.transfoFin and TR.recharges or 1
end

-- Dégâts d'un coup : race, faiblesse, résistance, Ombre, transformation, critique.
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
	degats *= multDegats(e)
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
-- Transformation : aura visible par tous (créée ici, côté serveur)
---------------------------------------------------------------------
local function retirerAura(player)
	local perso = player.Character
	local aura = perso and perso:FindFirstChild("AuraTransfo")
	if aura then
		aura:Destroy()
	end
	if perso then
		for _, d in perso:GetDescendants() do
			if d.Name == "AuraTransfoPiece" then
				d:Destroy()
			end
		end
	end
end

local function creerAura(player, couleur)
	local perso = player.Character
	local racine = perso and perso:FindFirstChild("HumanoidRootPart")
	local tete = perso and perso:FindFirstChild("Head")
	if not (racine and tete) then
		return
	end
	retirerAura(player)
	local dossier = Instance.new("Folder")
	dossier.Name = "AuraTransfo"

	-- Silhouette illuminée.
	local h = Instance.new("Highlight")
	h.Name = "Silhouette"
	h.FillColor = couleur
	h.FillTransparency = 0.72
	h.OutlineColor = couleur:Lerp(Color3.new(1, 1, 1), 0.5)
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Adornee = perso
	h.Parent = dossier
	dossier.Parent = perso

	local function piece(parent, classe)
		local p = Instance.new(classe)
		p.Name = "AuraTransfoPiece"
		p.Parent = parent
		return p
	end

	-- Flammes d'aura qui montent autour du corps.
	local att = piece(racine, "Attachment")
	att.Position = Vector3.new(0, -1.5, 0)
	local flammes = piece(att, "ParticleEmitter")
	flammes.Color = ColorSequence.new(Color3.new(1, 1, 1), couleur)
	flammes.LightEmission = 1
	flammes.LightInfluence = 0
	flammes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0) })
	flammes.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
	flammes.Lifetime = NumberRange.new(0.5, 0.9)
	flammes.Rate = 70
	flammes.Speed = NumberRange.new(4, 9)
	flammes.SpreadAngle = Vector2.new(15, 15)
	flammes.EmissionDirection = Enum.NormalId.Top
	flammes.Shape = Enum.ParticleEmitterShape.Cylinder
	flammes.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	flammes.Acceleration = Vector3.new(0, 6, 0)
	local etincelles = piece(att, "ParticleEmitter")
	etincelles.Color = ColorSequence.new(couleur:Lerp(Color3.new(1, 1, 1), 0.6))
	etincelles.LightEmission = 1
	etincelles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
	etincelles.Lifetime = NumberRange.new(0.4, 0.8)
	etincelles.Rate = 40
	etincelles.Speed = NumberRange.new(6, 14)
	etincelles.SpreadAngle = Vector2.new(40, 40)
	etincelles.EmissionDirection = Enum.NormalId.Top
	local lumiere = piece(racine, "PointLight")
	lumiere.Color = couleur
	lumiere.Range = 16
	lumiere.Brightness = 3

	-- Yeux rouges lumineux, soudés à la tête.
	local taille = tete.Size
	for _, cote in { -1, 1 } do
		local oeil = Instance.new("Part")
		oeil.Name = "AuraTransfoPiece"
		oeil.Shape = Enum.PartType.Ball
		oeil.Size = Vector3.new(0.22, 0.22, 0.22) * math.clamp(taille.Y / 1.2, 0.7, 1.6)
		oeil.Color = Color3.fromRGB(255, 30, 30)
		oeil.Material = Enum.Material.Neon
		oeil.CanCollide = false
		oeil.CanQuery = false
		oeil.CanTouch = false
		oeil.Massless = true
		oeil.CastShadow = false
		oeil.CFrame = tete.CFrame * CFrame.new(cote * taille.X * 0.17, taille.Y * 0.1, -taille.Z * 0.46)
		local soudure = Instance.new("WeldConstraint")
		soudure.Part0 = tete
		soudure.Part1 = oeil
		soudure.Parent = oeil
		local trace = Instance.new("ParticleEmitter")
		trace.Color = ColorSequence.new(Color3.fromRGB(255, 60, 40))
		trace.LightEmission = 1
		trace.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0) })
		trace.Lifetime = NumberRange.new(0.2, 0.35)
		trace.Rate = 25
		trace.Speed = NumberRange.new(0.5, 1)
		trace.LockedToPart = false
		trace.Parent = oeil
		oeil.Parent = perso
	end
	local lueur = piece(tete, "PointLight")
	lueur.Color = Color3.fromRGB(255, 40, 40)
	lueur.Range = 5
	lueur.Brightness = 2
end

local function finirTransformation(player, e, maintenant, versEpuisement)
	e.transfoFin = nil
	retirerAura(player)
	local hum = partiesVivantes(player)
	if versEpuisement then
		e.epuiseFin = maintenant + TR.epuisement
		if hum then
			hum.WalkSpeed = vitesseRace(e.donnees) * TR.epuiseVitesse
		end
		envoyer(player, { type = "finTransfo", epuisement = TR.epuisement })
	elseif hum then
		hum.WalkSpeed = vitesseRace(e.donnees)
	end
	envoyerRessources(player, e)
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
	-- Transformation et épuisement s'arrêtent avec le combat.
	if e.transfoFin or e.epuiseFin then
		e.transfoFin = nil
		e.epuiseFin = nil
		retirerAura(player)
		local hum = partiesVivantes(player)
		if hum then
			hum.WalkSpeed = vitesseRace(e.donnees)
		end
	end
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
	remplirJauge(player, e, degats * TR.parDegatInflige)

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
	elseif effet ~= "brulureTick" then
		envoyerRessources(player, e)
	end
end

-- L'ennemi touche le joueur : invulnérabilité, défense, bouclier, boucle temporelle, puis vie.
local function frapperJoueur(player, e, hum, degats)
	if os.clock() < e.invulnJusqua then
		envoyer(player, { type = "degatsRecus", degats = 0, absorbe = 0, bouclier = e.bouclier, invulnerable = true })
		return
	end
	if e.transfoFin then
		degats = math.floor(degats * TR.defense + 0.5)
	end
	remplirJauge(player, e, degats * TR.parDegatRecu)
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
		transfoFin = nil,
		epuiseFin = nil,
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

-- Coup normal.
function Combat.attaquer(player)
	local e = combats[player]
	if not e or e.lancement then
		return
	end
	local maintenant = os.clock()
	local recharge = C.RECHARGE_ATTAQUE * (e.donnees.don == "flux" and 0.7 or 1) * (e.transfoFin and 0.75 or 1)
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

	local chanceCritique = C.CRITIQUE_BASE + (e.donnees.don == "critique" and 0.15 or 0)
	local critique = rng:NextNumber() < chanceCritique
	local degats = calculerDegats(e, 1, critique)
	local effet = appliquerEffet(e, hum, 1, maintenant)

	if e.ia.recul then
		e.ia.recul(e, racine.Position)
	end
	gagnerEnergie(e, EN.parCoup + (critique and EN.parCritique or 0))
	blesserEnnemi(player, e, degats, critique, effet)
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
	local portee = A.zone and A.rayon or (e.def.porteeJoueur + (A.porteeBonus or 0))
	if distancePlat(racine.Position, e.corps.Position) > portee then
		envoyer(player, { type = "tropLoin" })
		return
	end

	-- Validé : on paie tout de suite, la recharge démarre.
	e.energie -= A.cout
	e.pret[index] = maintenant + A.recharge * multRecharge(e)
	e.lancement = index
	if A.invulnerable then
		e.invulnJusqua = math.max(e.invulnJusqua, maintenant + A.charge + 0.6)
	end
	envoyer(player, { type = "attaque", index = index, charge = A.charge, element = e.donnees.element })
	envoyerRessources(player, e)

	task.delay(A.charge, function()
		if combats[player] ~= e then
			return
		end
		e.lancement = nil
		local hum2, racine2 = partiesVivantes(player)
		if not hum2 then
			return
		end
		-- Petite marge : l'ennemi a pu bouger pendant la charge.
		if distancePlat(racine2.Position, e.corps.Position) > portee + 6 then
			envoyer(player, { type = "rate", index = index })
			envoyerRessources(player, e)
			return
		end
		local t = os.clock()
		local chanceCritique = C.CRITIQUE_BASE + (e.donnees.don == "critique" and 0.15 or 0)
		local critique = index == 5 or rng:NextNumber() < chanceCritique
		local degats = calculerDegats(e, A.mult, critique and index ~= 5)
		local force = (index == 5 or A.effetFort) and 3 or 2
		local effet = appliquerEffet(e, hum2, force, t)
		if A.zone or index == 5 then
			-- Nova et Éveil coupent l'attaque en préparation de l'ennemi.
			e.etourdiFin = math.max(e.etourdiFin, t + (e.def.boss and 0.4 or 1))
			if e.ia.annulerAttaque then
				e.ia.annulerAttaque(e, t)
			end
		end
		if e.ia.recul then
			e.ia.recul(e, racine2.Position)
		end
		if A.gain then
			gagnerEnergie(e, A.gain)
		end
		blesserEnnemi(player, e, degats, critique, effet, index)
	end)
end

-- Transformation : jauge pleine, en combat, pas déjà transformé ni épuisé.
function Combat.transformer(player)
	local e = combats[player]
	if not e or e.transfoFin or e.epuiseFin then
		return
	end
	if (jauges[player] or 0) < TR.jaugeMax then
		envoyer(player, { type = "refus", raison = "jauge" })
		return
	end
	local hum = partiesVivantes(player)
	if not hum then
		return
	end
	local maintenant = os.clock()
	jauges[player] = 0
	e.transfoFin = maintenant + TR.duree
	e.invulnJusqua = math.max(e.invulnJusqua, maintenant + TR.invulnerable)
	hum.WalkSpeed = vitesseRace(e.donnees) * TR.vitesse
	-- Les recharges en cours raccourcissent aussi.
	for i, t in e.pret do
		if t > maintenant then
			e.pret[i] = maintenant + (t - maintenant) * TR.recharges
		end
	end
	local element = Donnees.trouver(Donnees.ELEMENTS, e.donnees.element)
	creerAura(player, element and element.couleur or Color3.new(1, 1, 1))
	envoyer(player, { type = "transfo", duree = TR.duree, element = e.donnees.element })
	envoyerRessources(player, e)
end

---------------------------------------------------------------------
-- Boucle commune : brûlure, transformation, puis comportement propre à l'ennemi.
---------------------------------------------------------------------
local function mettreAJour(dt)
	local maintenant = os.clock()
	for player, e in combats do
		local hum, racine = partiesVivantes(player)
		if not hum then
			Combat.terminer(player, "defaite")
			continue
		end

		if e.transfoFin and maintenant >= e.transfoFin then
			finirTransformation(player, e, maintenant, true)
		elseif e.epuiseFin and maintenant >= e.epuiseFin then
			e.epuiseFin = nil
			hum.WalkSpeed = vitesseRace(e.donnees)
			envoyer(player, { type = "finEpuisement" })
			envoyerRessources(player, e)
		end

		-- Brûlure : 4 dégâts par seconde.
		if maintenant < e.brulureFin + 0.05 and maintenant >= e.brulureTick then
			e.brulureTick += 1
			blesserEnnemi(player, e, math.floor(4 * multDegats(e) + 0.5), false, "brulureTick")
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
				-- Une attaque esquivée rapporte de l'énergie et de la jauge.
				if message.type == "esquive" then
					gagnerEnergie(e, EN.parEsquive)
					remplirJauge(player, e, TR.parEsquive)
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

function Combat.oublier(player)
	jauges[player] = nil
end

-- Pour les tests dans Studio : remplit énergie et jauge.
function Combat._remplirPourTest(player)
	local e = combats[player]
	jauges[player] = TR.jaugeMax
	if e then
		e.energie = EN.max
		envoyerRessources(player, e)
	end
end

function Combat.init(remoteEtatCombat)
	remoteEtat = remoteEtatCombat
	RunService.Heartbeat:Connect(mettreAJour)
end

return Combat
