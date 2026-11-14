-- Client : écran de naissance, interface du combat et commandes (clic, touche E, bouton tactile).
-- Le client n'envoie que des intentions ; il affiche ce que le serveur lui dit.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local joueur = Players.LocalPlayer
local dossier = ReplicatedStorage:WaitForChild("Magicaland")
local Donnees = require(dossier:WaitForChild("Donnees"))
local Sons = require(dossier:WaitForChild("Sons"))
Sons.precharger()
local remotes = dossier:WaitForChild("Remotes")
local ObtenirNaissance = remotes:WaitForChild("ObtenirNaissance")
local Commencer = remotes:WaitForChild("Commencer")
local Attaquer = remotes:WaitForChild("Attaquer")
local EtatCombat = remotes:WaitForChild("EtatCombat")

local COULEURS = {
	voile = Color3.fromRGB(12, 8, 22),
	panneau = Color3.fromRGB(30, 22, 50),
	bordure = Color3.fromRGB(120, 90, 170),
	dore = Color3.fromRGB(235, 190, 90),
	texte = Color3.fromRGB(242, 236, 252),
	doux = Color3.fromRGB(175, 165, 200),
	vie = Color3.fromRGB(110, 210, 90),
	danger = Color3.fromRGB(240, 90, 70),
}

local enCombat = false
local monstre = nil
local fiche = nil

---------------------------------------------------------------------
-- Petits outils de construction
---------------------------------------------------------------------
local function creer(classe, proprietes, parent)
	local objet = Instance.new(classe)
	for nom, valeur in proprietes do
		objet[nom] = valeur
	end
	objet.Parent = parent
	return objet
end

local function arrondir(objet, rayon)
	creer("UICorner", { CornerRadius = UDim.new(0, rayon) }, objet)
end

local function texte(parent, nom, contenu, taille, couleur, police)
	return creer("TextLabel", {
		Name = nom,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = police or Enum.Font.Gotham,
		TextSize = taille,
		TextColor3 = couleur or COULEURS.texte,
		TextWrapped = true,
		Text = contenu,
	}, parent)
end

local gui = creer("ScreenGui", {
	Name = "MagicalandUI",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, joueur:WaitForChild("PlayerGui"))

---------------------------------------------------------------------
-- Écran d'accueil : la naissance
---------------------------------------------------------------------
local accueil = creer("Frame", {
	Name = "Accueil",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = COULEURS.voile,
	BackgroundTransparency = 0.2,
}, gui)

local carte = creer("Frame", {
	Name = "Carte",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0.9, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = COULEURS.panneau,
}, accueil)
arrondir(carte, 14)
creer("UIStroke", { Color = COULEURS.bordure, Thickness = 2 }, carte)
creer("UISizeConstraint", { MaxSize = Vector2.new(440, math.huge) }, carte)
creer("UIPadding", {
	PaddingTop = UDim.new(0, 18),
	PaddingBottom = UDim.new(0, 18),
	PaddingLeft = UDim.new(0, 20),
	PaddingRight = UDim.new(0, 20),
}, carte)
creer("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, carte)

texte(carte, "Titre", "Magicaland", 34, COULEURS.dore, Enum.Font.GothamBlack).LayoutOrder = 1
texte(carte, "SousTitre", "Reborn in New World : ta naissance", 15, COULEURS.doux).LayoutOrder = 2
local statut = texte(carte, "Statut", "Le destin se décide…", 16, COULEURS.texte)
statut.LayoutOrder = 3

-- Une ligne de la fiche : étiquette, valeur en couleur, description.
local function ligneFiche(ordre, etiquette)
	local bloc = creer("Frame", {
		Name = "Ligne_" .. etiquette,
		LayoutOrder = ordre,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(42, 32, 68),
		Visible = false,
	}, carte)
	arrondir(bloc, 10)
	creer("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
	}, bloc)
	creer("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, bloc)
	local e = texte(bloc, "Etiquette", etiquette, 12, COULEURS.doux)
	e.LayoutOrder = 1
	e.TextXAlignment = Enum.TextXAlignment.Left
	local v = texte(bloc, "Valeur", "", 20, COULEURS.texte, Enum.Font.GothamBold)
	v.LayoutOrder = 2
	v.TextXAlignment = Enum.TextXAlignment.Left
	local d = texte(bloc, "Desc", "", 13, COULEURS.doux)
	d.LayoutOrder = 3
	d.TextXAlignment = Enum.TextXAlignment.Left
	return bloc, v, d
end

local blocRace, valRace, descRace = ligneFiche(4, "Race")
local blocElement, valElement, descElement = ligneFiche(5, "Élément de magie")
local blocDon, valDon, descDon = ligneFiche(6, "Don d'isekai")

local note = texte(carte, "Note", "Ta naissance est définitive : un seul tirage par joueur.", 12, COULEURS.doux)
note.LayoutOrder = 7
note.Visible = false

local boutonCommencer = creer("TextButton", {
	Name = "Commencer",
	LayoutOrder = 8,
	Size = UDim2.new(1, 0, 0, 52),
	BackgroundColor3 = COULEURS.dore,
	AutoButtonColor = true,
	Font = Enum.Font.GothamBlack,
	TextSize = 20,
	TextColor3 = Color3.fromRGB(40, 25, 10),
	Text = "Commencer",
	Visible = false,
}, carte)
arrondir(boutonCommencer, 12)

---------------------------------------------------------------------
-- Interface du combat
---------------------------------------------------------------------
local hud = creer("Frame", {
	Name = "HUD",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Visible = false,
}, gui)

local cadreVie = creer("Frame", {
	Name = "Vie",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 10),
	Size = UDim2.fromOffset(300, 54),
	BackgroundColor3 = COULEURS.panneau,
	BackgroundTransparency = 0.15,
}, hud)
arrondir(cadreVie, 10)
creer("UIStroke", { Color = COULEURS.bordure, Thickness = 1.5 }, cadreVie)

local resume = creer("TextLabel", {
	Name = "Resume",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(10, 4),
	Size = UDim2.new(1, -20, 0, 18),
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = COULEURS.texte,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "",
}, cadreVie)

local fondVie = creer("Frame", {
	Name = "Fond",
	Position = UDim2.fromOffset(10, 26),
	Size = UDim2.new(1, -20, 0, 18),
	BackgroundColor3 = Color3.fromRGB(25, 15, 25),
}, cadreVie)
arrondir(fondVie, 6)
local barreVie = creer("Frame", {
	Name = "Barre",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = COULEURS.vie,
}, fondVie)
arrondir(barreVie, 6)
local texteVie = creer("TextLabel", {
	Name = "Texte",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = Color3.new(1, 1, 1),
	ZIndex = 2,
	Text = "",
}, fondVie)

local boutonAttaque = creer("TextButton", {
	Name = "Attaquer",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -24, 1, -170),
	Size = UDim2.fromOffset(110, 110),
	BackgroundColor3 = Color3.fromRGB(200, 70, 60),
	AutoButtonColor = true,
	Font = Enum.Font.GothamBlack,
	TextSize = 18,
	TextColor3 = Color3.new(1, 1, 1),
	Text = "ATTAQUER\n(clic ou E)",
}, hud)
arrondir(boutonAttaque, 55)
creer("UIStroke", { Color = COULEURS.dore, Thickness = 3 }, boutonAttaque)

local message = creer("TextLabel", {
	Name = "Message",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.3),
	Size = UDim2.new(0.9, 0, 0, 40),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	TextSize = 26,
	TextColor3 = COULEURS.texte,
	TextStrokeTransparency = 0.3,
	TextWrapped = true,
	Text = "",
}, hud)

-- Panneau de fin (victoire ou défaite).
local fin = creer("Frame", {
	Name = "Fin",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.new(0.85, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = COULEURS.panneau,
	Visible = false,
}, gui)
arrondir(fin, 14)
creer("UIStroke", { Color = COULEURS.dore, Thickness = 2 }, fin)
creer("UISizeConstraint", { MaxSize = Vector2.new(380, math.huge) }, fin)
creer("UIPadding", {
	PaddingTop = UDim.new(0, 18),
	PaddingBottom = UDim.new(0, 18),
	PaddingLeft = UDim.new(0, 18),
	PaddingRight = UDim.new(0, 18),
}, fin)
creer("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, fin)
local finTitre = texte(fin, "Titre", "", 30, COULEURS.dore, Enum.Font.GothamBlack)
finTitre.LayoutOrder = 1
local finTexte = texte(fin, "Texte", "", 16, COULEURS.texte)
finTexte.LayoutOrder = 2
local boutonRejouer = creer("TextButton", {
	Name = "Rejouer",
	LayoutOrder = 3,
	Size = UDim2.new(1, 0, 0, 48),
	BackgroundColor3 = COULEURS.dore,
	Font = Enum.Font.GothamBlack,
	TextSize = 18,
	TextColor3 = Color3.fromRGB(40, 25, 10),
	Text = "Nouveau combat",
}, fin)
arrondir(boutonRejouer, 12)

---------------------------------------------------------------------
-- Effets visuels
---------------------------------------------------------------------
local jetonMessage = 0
local function afficherMessage(contenu, couleur, duree)
	jetonMessage += 1
	local jeton = jetonMessage
	message.Text = contenu
	message.TextColor3 = couleur or COULEURS.texte
	message.TextTransparency = 0
	message.TextStrokeTransparency = 0.3
	task.delay(duree or 1.5, function()
		if jeton == jetonMessage then
			TweenService:Create(message, TweenInfo.new(0.3), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

-- Chiffre de dégâts qui saute au-dessus du monstre.
local function chiffreDegats(valeur, couleur, grand)
	local corps = monstre and monstre:FindFirstChild("Corps")
	if not corps then
		return
	end
	local panneau = creer("BillboardGui", {
		Size = UDim2.fromOffset(120, 50),
		StudsOffset = Vector3.new(math.random(-15, 15) / 10, 3, 0),
		AlwaysOnTop = true,
	}, corps)
	local etiquette = creer("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBlack,
		TextSize = grand and 34 or 24,
		TextColor3 = couleur,
		TextStrokeTransparency = 0.2,
		Text = tostring(valeur),
	}, panneau)
	TweenService:Create(panneau, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = panneau.StudsOffset + Vector3.new(0, 2.5, 0),
	}):Play()
	TweenService:Create(etiquette, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(panneau, 0.8)
end

-- Petite secousse de caméra quand on prend un coup.
local function secousse(force)
	local perso = joueur.Character
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	task.spawn(function()
		for _ = 1, 6 do
			hum.CameraOffset = Vector3.new((math.random() - 0.5) * force, (math.random() - 0.5) * force, 0)
			task.wait(0.03)
		end
		hum.CameraOffset = Vector3.zero
	end)
end

local function pulseBouton()
	boutonAttaque.Size = UDim2.fromOffset(100, 100)
	TweenService:Create(boutonAttaque, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(110, 110),
	}):Play()
end

---------------------------------------------------------------------
-- Barre de vie du joueur
---------------------------------------------------------------------
local bouclier = 0
local function majVie()
	local perso = joueur.Character
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	local ratio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
	barreVie.Size = UDim2.fromScale(ratio, 1)
	barreVie.BackgroundColor3 = COULEURS.danger:Lerp(COULEURS.vie, ratio)
	local t = "Toi : " .. math.ceil(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
	if bouclier > 0 then
		t ..= "   (bouclier " .. bouclier .. ")"
	end
	texteVie.Text = t
end

local attenteRespawn = false
local function surPersonnage(perso)
	local hum = perso:WaitForChild("Humanoid")
	hum.HealthChanged:Connect(majVie)
	hum:GetPropertyChangedSignal("MaxHealth"):Connect(majVie)
	majVie()
	if attenteRespawn then
		attenteRespawn = false
		boutonRejouer.Text = "Réessayer"
		boutonRejouer.Active = true
		boutonRejouer.AutoButtonColor = true
		boutonRejouer.BackgroundTransparency = 0
	end
end
joueur.CharacterAdded:Connect(surPersonnage)
if joueur.Character then
	task.spawn(surPersonnage, joueur.Character)
end

---------------------------------------------------------------------
-- Actions du joueur
---------------------------------------------------------------------
local derniereAttaque = 0
local function attaquer()
	if not enCombat then
		return
	end
	local maintenant = os.clock()
	if maintenant - derniereAttaque < 0.15 then
		return -- simple confort : le vrai contrôle est fait par le serveur
	end
	derniereAttaque = maintenant
	pulseBouton()
	Sons.jouer("elan")
	Attaquer:FireServer()
end

local function lancerCombat()
	fin.Visible = false
	accueil.Visible = false
	hud.Visible = true
	boutonAttaque.Visible = true
	Commencer:FireServer()
end

boutonCommencer.Activated:Connect(lancerCombat)
boutonAttaque.Activated:Connect(attaquer)
boutonRejouer.Activated:Connect(function()
	if attenteRespawn then
		return
	end
	lancerCombat()
end)

UserInputService.InputBegan:Connect(function(entree, traiteParJeu)
	if traiteParJeu then
		return
	end
	if entree.UserInputType == Enum.UserInputType.MouseButton1 or entree.KeyCode == Enum.KeyCode.E then
		attaquer()
	end
end)

---------------------------------------------------------------------
-- Messages du serveur
---------------------------------------------------------------------
local NOMS_EFFETS = { brulure = "Brûlure !", gel = "Gel !", choc = "Choc !", soin = "+3 PV" }

local function afficherFin(titre, contenu)
	finTitre.Text = titre
	finTexte.Text = contenu
	fin.Visible = true
	boutonAttaque.Visible = false
end

EtatCombat.OnClientEvent:Connect(function(m)
	if type(m) ~= "table" then
		return
	end
	if m.type == "debut" then
		enCombat = true
		monstre = m.modele
		bouclier = m.bouclier or 0
		majVie()
		Sons.jouer("apparition")
		Sons.musique("combat")
		afficherMessage(m.nom .. " approche ! Frappe-le (clic, E ou bouton).", COULEURS.dore, 2.5)
	elseif m.type == "coup" then
		local element = fiche and Donnees.trouver(Donnees.ELEMENTS, fiche.element)
		if m.effet == "brulureTick" then
			Sons.jouer("brulure")
			chiffreDegats(m.degats, Color3.fromRGB(255, 140, 60), false)
		else
			Sons.jouer("coup")
			if element then
				Sons.jouer(element.id)
			end
			if m.critique then
				Sons.jouer("critique")
			end
			chiffreDegats(m.degats, m.critique and COULEURS.dore or (element and element.couleur or COULEURS.texte), m.critique)
			if m.critique then
				afficherMessage("Critique !", COULEURS.dore, 0.6)
			elseif m.effet and NOMS_EFFETS[m.effet] then
				afficherMessage(NOMS_EFFETS[m.effet], element and element.couleur, 0.6)
			end
		end
	elseif m.type == "alerte" then
		Sons.jouer("alerte")
		afficherMessage("Attention ! Recule pour esquiver !", COULEURS.danger, 0.6)
	elseif m.type == "esquive" then
		Sons.jouer("esquive")
		afficherMessage("Esquivé !", COULEURS.vie, 0.7)
	elseif m.type == "tropLoin" then
		afficherMessage("Trop loin : approche-toi !", COULEURS.doux, 0.8)
	elseif m.type == "degatsRecus" then
		bouclier = m.bouclier or 0
		majVie()
		if m.boucle then
			Sons.jouer("boucle")
		elseif m.degats > 0 then
			Sons.jouer("impactRecu")
		else
			Sons.jouer("bouclier")
		end
		if m.boucle then
			afficherMessage("Boucle temporelle ! Tu reviens à 50 % de vie.", COULEURS.dore, 2)
		elseif (m.absorbe or 0) > 0 and m.degats == 0 then
			afficherMessage("Le bouclier encaisse le coup !", Color3.fromRGB(140, 200, 255), 0.8)
		end
		secousse(m.degats > 0 and 0.6 or 0.25)
	elseif m.type == "victoire" then
		Sons.jouer("mortMonstre")
		Sons.jouer("victoire")
		Sons.musique(nil)
		enCombat = false
		monstre = nil
		bouclier = 0
		majVie()
		if fiche and m.total then
			fiche.pieces = m.total
		end
		afficherFin("Victoire !", "Le " .. Donnees.COMBAT.MONSTRE.nom .. " est vaincu.\nRécompense : +" .. m.pieces .. " pièces" .. (m.total and (" (total " .. m.total .. ")") or "") .. ".")
		boutonRejouer.Text = "Nouveau combat"
	elseif m.type == "defaite" then
		Sons.jouer("defaite")
		Sons.musique(nil)
		enCombat = false
		monstre = nil
		bouclier = 0
		attenteRespawn = true
		afficherFin("Tu es tombé…", "Le golem a gagné cette fois. Recule quand il devient rouge !")
		boutonRejouer.Text = "Attends ton retour…"
		boutonRejouer.Active = false
		boutonRejouer.AutoButtonColor = false
		boutonRejouer.BackgroundTransparency = 0.5
	end
end)

---------------------------------------------------------------------
-- Chargement de la fiche de naissance
---------------------------------------------------------------------
local function remplirFiche(f)
	local race = Donnees.trouver(Donnees.RACES, f.race)
	local element = Donnees.trouver(Donnees.ELEMENTS, f.element)
	local don = Donnees.trouver(Donnees.DONS, f.don)
	local rarete = Donnees.trouver(Donnees.RARETES, f.rarete)
	if not (race and element and don and rarete) then
		statut.Text = "Fiche illisible. Rejoins la partie pour réessayer."
		return
	end
	valRace.Text = race.nom
	descRace.Text = race.desc
	valElement.Text = element.nom
	valElement.TextColor3 = element.couleur
	descElement.Text = element.effet
	valDon.Text = don.nom .. "  ·  " .. rarete.nom
	valDon.TextColor3 = rarete.couleur
	descDon.Text = don.desc
	resume.Text = race.nom .. " · " .. element.nom .. " · " .. don.nom
	statut.Text = f.victoires > 0 and ("Bon retour ! Victoires : " .. f.victoires .. ", pièces : " .. f.pieces) or "Tu viens de renaître dans un nouveau monde."
	blocRace.Visible = true
	blocElement.Visible = true
	blocDon.Visible = true
	note.Visible = true
	boutonCommencer.Visible = true
end

task.spawn(function()
	local ok, resultat = pcall(function()
		return ObtenirNaissance:InvokeServer()
	end)
	if ok and type(resultat) == "table" then
		fiche = resultat
		remplirFiche(resultat)
	else
		statut.Text = "Le destin tarde à répondre. Rejoins la partie pour réessayer."
	end
end)
