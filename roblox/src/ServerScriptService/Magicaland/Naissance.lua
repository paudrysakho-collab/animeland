-- Naissance : tirage de la race, de l'élément et du don, puis sauvegarde.
-- Un seul tirage par joueur : une naissance déjà enregistrée n'est jamais remplacée.
-- Dans Studio sans « accès aux API », le DataStore refuse : on garde alors les données en mémoire.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Donnees = require(ReplicatedStorage:WaitForChild("Magicaland"):WaitForChild("Donnees"))

local Naissance = {}

local VERSION = 1
local rng = Random.new()

local store = nil
local okStore, resultat = pcall(function()
	return DataStoreService:GetDataStore("MagicalandJoueurs_v1")
end)
if okStore then
	store = resultat
else
	warn("[Magicaland] DataStore indisponible, sauvegarde en mémoire seulement : " .. tostring(resultat))
end

local memoire = {} -- [UserId] = données (secours si le DataStore ne répond pas)
local donneesJoueurs = {} -- [Player] = données chargées
local lectureRatee = {} -- [Player] = true : la lecture a échoué, on n'écrit pas par-dessus

-- Tire une entrée au hasard selon les poids « w ».
local function tirerPondere(liste)
	local total = 0
	for _, entree in liste do
		total += entree.w
	end
	local r = rng:NextNumber() * total
	for _, entree in liste do
		r -= entree.w
		if r < 0 then
			return entree
		end
	end
	return liste[1]
end

-- Fait un nouveau tirage de naissance.
function Naissance.tirer()
	local race = tirerPondere(Donnees.RACES)
	local element = Donnees.ELEMENTS[rng:NextInteger(1, #Donnees.ELEMENTS)]
	local rarete = tirerPondere(Donnees.RARETES)
	local candidats = {}
	for _, don in Donnees.DONS do
		if don.rarete == rarete.id then
			table.insert(candidats, don)
		end
	end
	local don = candidats[rng:NextInteger(1, #candidats)]
	return {
		v = VERSION,
		race = race.id,
		element = element.id,
		don = don.id,
		rarete = rarete.id,
		pieces = 0,
		victoires = 0,
		bossVaincus = 0,
		objets = {},
		date = os.time(),
	}
end

local function cle(player)
	return "Joueur_" .. player.UserId
end

-- Vérifie qu'une sauvegarde lue est complète et connue.
local function estValide(d)
	return type(d) == "table"
		and Donnees.trouver(Donnees.RACES, d.race) ~= nil
		and Donnees.trouver(Donnees.ELEMENTS, d.element) ~= nil
		and Donnees.trouver(Donnees.DONS, d.don) ~= nil
		and Donnees.trouver(Donnees.RARETES, d.rarete) ~= nil
end

-- Charge la naissance du joueur, ou la tire si c'est sa première venue.
function Naissance.charger(player)
	local d = nil
	if store then
		local succes, res = pcall(function()
			return store:GetAsync(cle(player))
		end)
		if succes then
			d = res
		else
			lectureRatee[player] = true
			warn("[Magicaland] Lecture DataStore impossible (normal dans Studio sans accès aux API) : " .. tostring(res))
		end
	end
	if not estValide(d) then
		d = memoire[player.UserId]
	end

	local nouveau = false
	if not estValide(d) then
		d = Naissance.tirer()
		nouveau = true
	end
	d.pieces = tonumber(d.pieces) or 0
	d.victoires = tonumber(d.victoires) or 0
	d.bossVaincus = tonumber(d.bossVaincus) or 0
	if type(d.objets) ~= "table" then
		d.objets = {}
	end

	if player.Parent == nil then
		return nil -- le joueur est parti pendant le chargement
	end
	donneesJoueurs[player] = d
	memoire[player.UserId] = d
	if nouveau then
		Naissance.sauver(player)
	end
	return d
end

function Naissance.obtenir(player)
	return donneesJoueurs[player]
end

-- Enregistre les données. La naissance déjà en base est gardée telle quelle.
function Naissance.sauver(player)
	local d = donneesJoueurs[player]
	if not d then
		return
	end
	memoire[player.UserId] = d
	if not store or lectureRatee[player] then
		return
	end
	local succes, err = pcall(function()
		store:UpdateAsync(cle(player), function(ancien)
			if estValide(ancien) then
				ancien.pieces = d.pieces
				ancien.victoires = d.victoires
				ancien.bossVaincus = d.bossVaincus
				ancien.objets = d.objets
				return ancien
			end
			return d
		end)
	end)
	if not succes then
		warn("[Magicaland] Sauvegarde impossible : " .. tostring(err))
	end
end

function Naissance.oublier(player)
	donneesJoueurs[player] = nil
	lectureRatee[player] = nil
end

return Naissance
