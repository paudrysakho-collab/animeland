-- Principal : point d'entrée serveur de Magicaland.
-- Crée les RemoteEvents, charge la naissance de chaque joueur et relie le combat.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local dossier = ReplicatedStorage:WaitForChild("Magicaland")
local Donnees = require(dossier:WaitForChild("Donnees"))
local Naissance = require(script.Parent:WaitForChild("Naissance"))
local Combat = require(script.Parent:WaitForChild("Combat"))

-- Remotes : c'est le serveur qui les crée (le client les attend).
local ancien = dossier:FindFirstChild("Remotes")
if ancien then
	ancien:Destroy()
end
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"

local function creerRemote(classe, nom)
	local r = Instance.new(classe)
	r.Name = nom
	r.Parent = remotes
	return r
end

local ObtenirNaissance = creerRemote("RemoteFunction", "ObtenirNaissance") -- client -> serveur : « qui suis-je ? »
local Commencer = creerRemote("RemoteEvent", "Commencer") -- client -> serveur : lancer le combat
local Attaquer = creerRemote("RemoteEvent", "Attaquer") -- client -> serveur : intention d'attaquer
local EtatCombat = creerRemote("RemoteEvent", "EtatCombat") -- serveur -> client : ce qui se passe
local AttaqueSpeciale = creerRemote("RemoteEvent", "AttaqueSpeciale") -- client -> serveur : attaque spéciale n° 1 à 5
local Transformer = creerRemote("RemoteEvent", "Transformer") -- client -> serveur : transformation (jauge pleine)
remotes.Parent = dossier

Combat.init(EtatCombat)

-- Récompense de victoire : décidée et enregistrée par le serveur.
Combat.surVictoire = function(player, e)
	local d = Naissance.obtenir(player)
	if not d then
		return {}
	end
	d.pieces += e.def.recompense
	d.victoires += 1
	local objet = nil
	if e.def.objet then
		d.objets[e.def.objet] = (d.objets[e.def.objet] or 0) + 1
		d.bossVaincus += 1
		objet = e.def.objet
	end
	task.spawn(Naissance.sauver, player)
	return { total = d.pieces, victoires = d.victoires, objet = objet }
end

local enChargement = {} -- [Player] = true pendant la lecture de la sauvegarde
local derniereDemande = {} -- [Player] = heure du dernier « Commencer » (anti-spam)

-- Lame magique de la couleur de l'élément, soudée à la main droite (visible par tous).
-- La traînée (Trail) est allumée par le client pendant les coups.
local function equiperArme(player, d)
	local perso = player.Character
	local main = perso and perso:WaitForChild("RightHand", 10)
	if not main or perso:FindFirstChild("LameMagique") then
		return
	end
	local element = Donnees.trouver(Donnees.ELEMENTS, d.element)
	local couleur = element and element.couleur or Color3.new(1, 1, 1)

	local lame = Instance.new("Model")
	lame.Name = "LameMagique"
	local garde = Instance.new("Part")
	garde.Name = "Garde"
	garde.Size = Vector3.new(0.9, 0.2, 0.25)
	garde.Color = Color3.fromRGB(200, 160, 70)
	garde.Material = Enum.Material.Metal
	local tranchant = Instance.new("Part")
	tranchant.Name = "Tranchant"
	tranchant.Size = Vector3.new(0.18, 0.4, 3.6)
	tranchant.Color = couleur
	tranchant.Material = Enum.Material.Neon
	for _, p in { garde, tranchant } do
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.Parent = lame
	end
	garde.CFrame = main.CFrame * CFrame.new(0, -0.25, -0.2)
	tranchant.CFrame = garde.CFrame * CFrame.new(0, 0, -1.9)
	for _, p in { garde, tranchant } do
		local soudure = Instance.new("WeldConstraint")
		soudure.Part0 = main
		soudure.Part1 = p
		soudure.Parent = p
	end
	local lumiere = Instance.new("PointLight")
	lumiere.Color = couleur
	lumiere.Range = 7
	lumiere.Brightness = 1.2
	lumiere.Parent = tranchant
	local a0 = Instance.new("Attachment")
	a0.Name = "TraineeA"
	a0.Position = Vector3.new(0, 0, -1.7)
	a0.Parent = tranchant
	local a1 = Instance.new("Attachment")
	a1.Name = "TraineeB"
	a1.Position = Vector3.new(0, 0, 1.6)
	a1.Parent = tranchant
	local trainee = Instance.new("Trail")
	trainee.Name = "Trainee"
	trainee.Attachment0 = a0
	trainee.Attachment1 = a1
	trainee.Color = ColorSequence.new(couleur, Color3.new(1, 1, 1))
	trainee.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	trainee.Lifetime = 0.22
	trainee.LightEmission = 1
	trainee.FaceCamera = true
	trainee.Enabled = false
	trainee.Parent = tranchant
	lame.Parent = perso
end

local function surPersonnage(player)
	local d = Naissance.obtenir(player)
	if d then
		player.Character:WaitForChild("Humanoid", 10)
		Combat.appliquerRace(player, d)
		equiperArme(player, d)
	end
end

local function surArrivee(player)
	enChargement[player] = true
	player.CharacterAdded:Connect(function()
		surPersonnage(player)
	end)
	Naissance.charger(player)
	enChargement[player] = nil
	if player.Character then
		surPersonnage(player)
	end
end

Players.PlayerAdded:Connect(surArrivee)
for _, player in Players:GetPlayers() do
	task.spawn(surArrivee, player)
end

Players.PlayerRemoving:Connect(function(player)
	Combat.terminer(player, "depart")
	Naissance.sauver(player)
	Naissance.oublier(player)
	Combat.oublier(player)
	enChargement[player] = nil
	derniereDemande[player] = nil
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		Naissance.sauver(player)
	end
end)

-- Le client demande sa fiche : on attend la fin du chargement (15 s max).
ObtenirNaissance.OnServerInvoke = function(player)
	local debut = os.clock()
	while not Naissance.obtenir(player) and os.clock() - debut < 15 do
		task.wait(0.1)
	end
	local d = Naissance.obtenir(player)
	if not d then
		return nil
	end
	-- On renvoie une copie : seulement les identifiants, le client trouve les noms dans Donnees.
	return {
		race = d.race,
		element = d.element,
		don = d.don,
		rarete = d.rarete,
		pieces = d.pieces,
		victoires = d.victoires,
		bossVaincus = d.bossVaincus,
	}
end

-- Le client demande un combat : "golem" ou "colosse" (le boss demande au moins une victoire).
Commencer.OnServerEvent:Connect(function(player, typeEnnemi)
	local maintenant = os.clock()
	if derniereDemande[player] and maintenant - derniereDemande[player] < 1 then
		return
	end
	derniereDemande[player] = maintenant
	if typeEnnemi ~= "colosse" then
		typeEnnemi = "golem"
	end
	local d = Naissance.obtenir(player)
	if not d or Combat.estEnCombat(player) then
		return
	end
	local def = Donnees.ENNEMIS[typeEnnemi]
	if def.niveauRequis and d.victoires < def.niveauRequis then
		return
	end
	Combat.demarrer(player, d, typeEnnemi)
end)

-- Le client donne seulement le numéro de l'attaque : coût, recharge et portée sont vérifiés par Combat.
AttaqueSpeciale.OnServerEvent:Connect(function(player, index)
	Combat.attaqueSpeciale(player, index)
end)

Transformer.OnServerEvent:Connect(function(player)
	Combat.transformer(player)
end)

-- Outil de test, seulement dans Studio : remplit l'énergie et la jauge (BindableEvent côté serveur, invisible des joueurs).
if game:GetService("RunService"):IsStudio() then
	local test = Instance.new("BindableEvent")
	test.Name = "MagicalandTestRemplir"
	test.Event:Connect(function()
		for _, player in Players:GetPlayers() do
			Combat._remplirPourTest(player)
		end
	end)
	test.Parent = game:GetService("ServerStorage")
end

-- Les arguments envoyés par le client sont ignorés : le serveur calcule tout.
Attaquer.OnServerEvent:Connect(function(player)
	Combat.attaquer(player)
end)

print("[Magicaland] Serveur prêt (" .. #Donnees.RACES .. " races, " .. #Donnees.ELEMENTS .. " éléments, " .. #Donnees.DONS .. " dons).")
