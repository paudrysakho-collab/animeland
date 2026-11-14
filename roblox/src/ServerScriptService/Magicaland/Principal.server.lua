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

local function surPersonnage(player)
	local d = Naissance.obtenir(player)
	if d then
		player.Character:WaitForChild("Humanoid", 10)
		Combat.appliquerRace(player, d)
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

-- Les arguments envoyés par le client sont ignorés : le serveur calcule tout.
Attaquer.OnServerEvent:Connect(function(player)
	Combat.attaquer(player)
end)

print("[Magicaland] Serveur prêt (" .. #Donnees.RACES .. " races, " .. #Donnees.ELEMENTS .. " éléments, " .. #Donnees.DONS .. " dons).")
