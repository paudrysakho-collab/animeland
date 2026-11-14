-- Client : écran de naissance, interface du combat et commandes (clic, touche E, bouton tactile),
-- 5 attaques spéciales (touches 1 à 5, R = 2) et transformation (T), avec leurs boutons tactiles.
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
local Animations = require(script.Parent:WaitForChild("Animations"))
local Attaques = require(script.Parent:WaitForChild("Attaques"))
local remotes = dossier:WaitForChild("Remotes")
local ObtenirNaissance = remotes:WaitForChild("ObtenirNaissance")
local Commencer = remotes:WaitForChild("Commencer")
local Attaquer = remotes:WaitForChild("Attaquer")
local EtatCombat = remotes:WaitForChild("EtatCombat")
local AttaqueSpeciale = remotes:WaitForChild("AttaqueSpeciale")
local Transformer = remotes:WaitForChild("Transformer")

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
	Size = UDim2.fromOffset(300, 88),
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

-- Bouton d'esquive (ruée), au-dessus du bouton d'attaque.
local boutonEsquive = creer("TextButton", {
	Name = "Esquive",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -34, 1, -290),
	Size = UDim2.fromOffset(90, 90),
	BackgroundColor3 = Color3.fromRGB(60, 120, 200),
	AutoButtonColor = true,
	Font = Enum.Font.GothamBlack,
	TextSize = 15,
	TextColor3 = Color3.new(1, 1, 1),
	Text = "ESQUIVE\n(Q)",
}, hud)
arrondir(boutonEsquive, 45)
creer("UIStroke", { Color = COULEURS.dore, Thickness = 2 }, boutonEsquive)

-- Énergie (10 cases) et jauge de transformation, sous la barre de vie.
local ENERGIE_MAX = Donnees.COMBAT.ENERGIE.max
local casesEnergie = {}
local rangeeEnergie = creer("Frame", {
	Name = "Energie",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(10, 48),
	Size = UDim2.new(1, -20, 0, 12),
}, cadreVie)
creer("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, rangeeEnergie)
for i = 1, ENERGIE_MAX do
	local case = creer("Frame", {
		Name = "Case" .. i,
		LayoutOrder = i,
		Size = UDim2.new(1 / ENERGIE_MAX, -3, 1, 0),
		BackgroundColor3 = Color3.fromRGB(55, 45, 80),
	}, rangeeEnergie)
	arrondir(case, 3)
	casesEnergie[i] = case
end
local fondJauge = creer("Frame", {
	Name = "Jauge",
	Position = UDim2.fromOffset(10, 66),
	Size = UDim2.new(1, -20, 0, 14),
	BackgroundColor3 = Color3.fromRGB(25, 15, 25),
}, cadreVie)
arrondir(fondJauge, 5)
local barreJauge = creer("Frame", {
	Name = "Barre",
	Size = UDim2.fromScale(0, 1),
	BackgroundColor3 = Color3.fromRGB(255, 80, 60),
}, fondJauge)
arrondir(barreJauge, 5)
local texteJauge = creer("TextLabel", {
	Name = "Texte",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 11,
	TextColor3 = Color3.new(1, 1, 1),
	ZIndex = 2,
	Text = "Transformation 0 %",
}, fondJauge)

-- 5 boutons d'attaque spéciale en arc autour du bouton d'attaque (centre à 79 px du bord droit, 225 px du bas).
local ATTAQUES = Donnees.COMBAT.ATTAQUES
local boutonsAttaque = {}
local ANGLES = { 140, 165, 190, 215, 240 }
for i, A in ATTAQUES do
	local angle = math.rad(ANGLES[i])
	local taille = i == 5 and 72 or 64
	local cx = 79 - math.cos(angle) * 125
	local cy = 225 + math.sin(angle) * 125
	local b = creer("TextButton", {
		Name = "Attaque" .. i,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -cx, 1, -cy),
		Size = UDim2.fromOffset(taille, taille),
		BackgroundColor3 = i == 5 and Color3.fromRGB(200, 120, 30) or Color3.fromRGB(120, 60, 190),
		AutoButtonColor = true,
		Text = "",
	}, hud)
	arrondir(b, taille / 2)
	local contour = creer("UIStroke", { Color = COULEURS.dore, Thickness = 2 }, b)
	local titre = creer("TextLabel", {
		Name = "Titre",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 6, 0.16, 0),
		Size = UDim2.new(1, -12, 0.36, 0),
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		Text = i .. " " .. A.court,
	}, b)
	local cout = creer("TextLabel", {
		Name = "Cout",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0.56, 0),
		Size = UDim2.new(1, -16, 0.26, 0),
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 230, 120),
		Text = A.cout == 0 and "gratuit" or (A.cout .. " ⚡"),
	}, b)
	local voile = creer("TextLabel", {
		Name = "Recharge",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBlack,
		TextSize = 20,
		TextColor3 = Color3.new(1, 1, 1),
		Text = "",
		Visible = false,
		ZIndex = 3,
	}, b)
	arrondir(voile, taille / 2)
	boutonsAttaque[i] = { bouton = b, contour = contour, voile = voile, titre = titre, cout = cout }
end

-- Bouton de transformation (jauge pleine), à gauche de l'arc.
local boutonTransfo = creer("TextButton", {
	Name = "Transformation",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -305, 1, -270),
	Size = UDim2.fromOffset(78, 78),
	BackgroundColor3 = Color3.fromRGB(70, 40, 40),
	AutoButtonColor = true,
	Font = Enum.Font.GothamBlack,
	TextSize = 13,
	TextColor3 = Color3.new(1, 1, 1),
	TextWrapped = true,
	Text = "TRANSFO\n(T)",
}, hud)
arrondir(boutonTransfo, 39)
local contourTransfo = creer("UIStroke", { Color = Color3.fromRGB(120, 90, 90), Thickness = 3 }, boutonTransfo)

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

-- Défier le boss : visible après une première victoire.
local boutonBoss = creer("TextButton", {
	Name = "DefierBoss",
	LayoutOrder = 4,
	Size = UDim2.new(1, 0, 0, 48),
	BackgroundColor3 = Color3.fromRGB(200, 80, 40),
	Font = Enum.Font.GothamBlack,
	TextSize = 17,
	TextColor3 = Color3.new(1, 1, 1),
	Text = "Défier le Colosse des Ronces (boss)",
	Visible = false,
}, fin)
arrondir(boutonBoss, 12)

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
	local corps = monstre and (monstre:FindFirstChild("Head") or monstre:FindFirstChild("HumanoidRootPart"))
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
	task.spawn(Animations.initPerso, perso)
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
	Animations.coup()
	Attaquer:FireServer()
end

-- Ruée d'esquive (1 s de recharge).
local derniereEsquive = 0
local function esquiver()
	local maintenant = os.clock()
	if maintenant - derniereEsquive < 1 then
		return
	end
	local el = fiche and Donnees.trouver(Donnees.ELEMENTS, fiche.element)
	if Animations.esquive(el and el.couleur) then
		derniereEsquive = maintenant
		Sons.jouer("esquive")
		boutonEsquive.BackgroundTransparency = 0.5
		task.delay(1, function()
			boutonEsquive.BackgroundTransparency = 0
		end)
	end
end

-- Ressources reçues du serveur (seule source de vérité) et affichage.
local res = { energie = 0, jauge = 0, jaugeMax = 100, recharges = {}, transfo = 0, epuise = 0, recu = 0 }
local arreterCharge = nil -- charge visuelle en cours
local indexEnCharge = nil

local function stopperCharge()
	if arreterCharge then
		arreterCharge()
		arreterCharge = nil
	end
	indexEnCharge = nil
end

local function couleurElement()
	local el = fiche and Donnees.trouver(Donnees.ELEMENTS, fiche.element)
	return el and el.couleur or COULEURS.dore, el and el.id, el and el.nom
end

local function majRessources()
	local maintenant = os.clock()
	local couleur = couleurElement()
	for i, case in casesEnergie do
		case.BackgroundColor3 = i <= res.energie and Color3.fromRGB(255, 220, 80) or Color3.fromRGB(55, 45, 80)
	end
	for i, A in ATTAQUES do
		local b = boutonsAttaque[i]
		local reste = (res.recharges[i] or 0) - (maintenant - res.recu)
		local assez = res.energie >= A.cout
		b.voile.Visible = reste > 0.05
		b.voile.Text = reste > 0.05 and tostring(math.ceil(reste)) or ""
		b.bouton.BackgroundTransparency = assez and 0 or 0.55
		b.cout.TextColor3 = assez and Color3.fromRGB(255, 230, 120) or COULEURS.danger
		b.contour.Color = (assez and reste <= 0.05) and couleur or Color3.fromRGB(90, 80, 110)
	end
	local transfo = res.transfo - (maintenant - res.recu)
	local epuise = res.epuise - (maintenant - res.recu)
	if transfo > 0 then
		barreJauge.Size = UDim2.fromScale(math.clamp(transfo / Donnees.COMBAT.TRANSFO.duree, 0, 1), 1)
		barreJauge.BackgroundColor3 = couleur
		texteJauge.Text = "TRANSFORMÉ : " .. math.ceil(transfo) .. " s"
		boutonTransfo.Text = "ACTIF\n" .. math.ceil(transfo) .. " s"
	elseif epuise > 0 then
		barreJauge.Size = UDim2.fromScale(0, 1)
		texteJauge.Text = "Épuisé : " .. math.ceil(epuise) .. " s"
		boutonTransfo.Text = "ÉPUISÉ"
	else
		local ratio = math.clamp(res.jauge / res.jaugeMax, 0, 1)
		barreJauge.Size = UDim2.fromScale(ratio, 1)
		barreJauge.BackgroundColor3 = ratio >= 1 and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(200, 80, 60)
		texteJauge.Text = ratio >= 1 and "TRANSFORMATION PRÊTE (T) !" or ("Transformation " .. math.floor(ratio * 100) .. " %")
		boutonTransfo.Text = "TRANSFO\n(T)"
	end
	local prete = transfo <= 0 and epuise <= 0 and res.jauge >= res.jaugeMax
	boutonTransfo.BackgroundColor3 = prete and Color3.fromRGB(220, 40, 40) or Color3.fromRGB(70, 40, 40)
	contourTransfo.Color = prete and COULEURS.dore or Color3.fromRGB(120, 90, 90)
	-- Le bouton prêt « bat » doucement.
	local battement = prete and (1 + 0.06 * math.sin(maintenant * 8)) or 1
	boutonTransfo.Size = UDim2.fromOffset(78 * battement, 78 * battement)
end

game:GetService("RunService").RenderStepped:Connect(function()
	if hud.Visible then
		majRessources()
	end
end)

local function lancerAttaque(index)
	if not enCombat or indexEnCharge then
		return
	end
	local A = ATTAQUES[index]
	if not A then
		return
	end
	-- Petit contrôle local pour répondre vite ; le serveur revérifie tout.
	local reste = (res.recharges[index] or 0) - (os.clock() - res.recu)
	if reste > 0.05 then
		Sons.jouer("refus")
		return
	end
	if res.energie < A.cout then
		Sons.jouer("refus")
		afficherMessage("Pas assez d'énergie (" .. A.cout .. " ⚡) : frappe et esquive !", COULEURS.doux, 1.2)
		return
	end
	AttaqueSpeciale:FireServer(index)
end

local function transformer()
	if not enCombat then
		return
	end
	if res.jauge < res.jaugeMax then
		Sons.jouer("refus")
		afficherMessage("Jauge de transformation pas encore pleine.", COULEURS.doux, 1)
		return
	end
	Transformer:FireServer()
end

local function lancerCombat(typeEnnemi)
	fin.Visible = false
	accueil.Visible = false
	hud.Visible = true
	boutonAttaque.Visible = true
	boutonEsquive.Visible = true
	Commencer:FireServer(typeEnnemi or "golem")
end

boutonCommencer.Activated:Connect(function()
	lancerCombat("golem")
end)
boutonAttaque.Activated:Connect(attaquer)
boutonEsquive.Activated:Connect(esquiver)
for i, b in boutonsAttaque do
	b.bouton.Activated:Connect(function()
		lancerAttaque(i)
	end)
end
boutonTransfo.Activated:Connect(transformer)
boutonRejouer.Activated:Connect(function()
	if attenteRespawn then
		return
	end
	lancerCombat("golem")
end)
boutonBoss.Activated:Connect(function()
	if attenteRespawn then
		return
	end
	lancerCombat("colosse")
end)

local TOUCHES = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.KeypadOne] = 1,
	[Enum.KeyCode.KeypadTwo] = 2,
	[Enum.KeyCode.KeypadThree] = 3,
	[Enum.KeyCode.KeypadFour] = 4,
	[Enum.KeyCode.KeypadFive] = 5,
}

UserInputService.InputBegan:Connect(function(entree, traiteParJeu)
	if traiteParJeu then
		return
	end
	if entree.UserInputType == Enum.UserInputType.MouseButton1 or entree.KeyCode == Enum.KeyCode.E then
		attaquer()
	elseif entree.KeyCode == Enum.KeyCode.Q then
		esquiver()
	elseif entree.KeyCode == Enum.KeyCode.R then
		lancerAttaque(2) -- l'ancien sort R devient la Lance
	elseif entree.KeyCode == Enum.KeyCode.T then
		transformer()
	else
		local index = TOUCHES[entree.KeyCode]
		if index then
			lancerAttaque(index)
		end
	end
end)

---------------------------------------------------------------------
-- Messages du serveur
---------------------------------------------------------------------
local NOMS_EFFETS = { brulure = "Brûlure !", gel = "Gel !", choc = "Choc !", soin = "+3 PV" }
local SONS_ATTAQUES = { "frappe", "lance", "colonnes", "nova", "eveil" }

local function afficherFin(titre, contenu)
	finTitre.Text = titre
	finTexte.Text = contenu
	fin.Visible = true
	boutonAttaque.Visible = false
	boutonEsquive.Visible = false
	boutonBoss.Visible = fiche ~= nil and (fiche.victoires or 0) >= 1
end

local ALERTES = {
	golem = "Attention ! Recule ou esquive (Q) !",
	fouet = "Fouet de ronces ! Sors de la zone rouge !",
	racines = "Racines ! Bouge vite !",
	graines = "Pluie de graines ! Évite les cercles !",
}

EtatCombat.OnClientEvent:Connect(function(m)
	if type(m) ~= "table" then
		return
	end
	if m.type == "debut" then
		enCombat = true
		monstre = m.modele
		-- Le modèle peut arriver un peu après le message (diffusion des instances).
		task.spawn(function()
			local mod = m.modele or workspace:WaitForChild(m.nomModele, 4)
			monstre = mod
			if m.boss and mod then
				Animations.intro(mod, m.intro, m.nom)
			end
		end)
		bouclier = m.bouclier or 0
		majVie()
		Sons.jouer("apparition")
		Sons.musique(m.boss and "boss" or "combat")
		if m.boss then
			afficherMessage(m.nom .. " se dresse ! Évite les zones rouges (Q pour esquiver).", COULEURS.danger, 3)
		else
			afficherMessage(m.nom .. " approche ! Frappe-le (clic, E ou bouton).", COULEURS.dore, 2.5)
		end
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
			local couleur = element and element.couleur or COULEURS.texte
			if m.special then
				stopperCharge()
				local A = ATTAQUES[m.special]
				Attaques.dechainer(m.special, m.pos, couleur, element and element.id, A and A.rayon)
				Sons.jouer(SONS_ATTAQUES[m.special] or "special")
				Animations.hitstop(m.special == 5 and 0.2 or 0.1)
			elseif m.pos then
				Animations.impact(m.pos, couleur, m.critique, element and element.id)
				Animations.hitstop(m.critique and 0.09 or 0.045)
				if m.critique then
					Animations.sort()
					secousse(0.5)
				end
			end
			if m.special then
				local nomEl = string.upper(element and element.nom or "Magie")
				local titres = { "FRAPPE D'ARCANE !", "LANCE DE " .. nomEl .. " !", "COLONNES DE " .. nomEl .. " !", "NOVA DE " .. nomEl .. " !", "ÉVEIL : " .. m.degats .. " !" }
				afficherMessage(titres[m.special] or "SORT !", couleur, m.special == 5 and 2 or 1.2)
			elseif m.critique then
				afficherMessage("Critique !", COULEURS.dore, 0.6)
			elseif m.effet and NOMS_EFFETS[m.effet] then
				afficherMessage(NOMS_EFFETS[m.effet], element and element.couleur, 0.6)
			end
		end
	elseif m.type == "alerte" then
		Sons.jouer("alerte")
		afficherMessage(ALERTES[m.attaque] or ALERTES.golem, COULEURS.danger, 0.9)
	elseif m.type == "frappeBoss" then
		Sons.jouer("frappeBoss")
		Animations.frappeSol(m.centres)
		secousse(0.9)
	elseif m.type == "phase" then
		Sons.jouer("phase2")
		Animations.phase2(m.pos)
		secousse(1.5)
		afficherMessage(m.nom .. " s'embrase ! Il craint maintenant la Glace.", Color3.fromRGB(255, 140, 60), 3)
	elseif m.type == "esquive" then
		Sons.jouer("esquive")
		if os.clock() - derniereEsquive < 0.8 then
			Animations.esquiveParfaite()
			afficherMessage("ESQUIVE PARFAITE !", Color3.fromRGB(140, 200, 255), 1)
		else
			afficherMessage("Esquivé !", COULEURS.vie, 0.7)
		end
	elseif m.type == "ressources" then
		res.energie = m.energie or 0
		res.jauge = m.jauge or 0
		res.jaugeMax = m.jaugeMax or 100
		res.recharges = m.recharges or {}
		res.transfo = m.transfo or 0
		res.epuise = m.epuise or 0
		res.recu = os.clock()
	elseif m.type == "attaque" then
		-- Le serveur a validé : charge visuelle ; le coup arrive ensuite avec le message « coup ».
		stopperCharge()
		local couleur, idEl, nomEl = couleurElement()
		local index = m.index
		indexEnCharge = index
		Sons.jouer(index == 5 and "chargeLongue" or "chargeCourte")
		arreterCharge = Attaques.charge(index, couleur, idEl, m.charge, nomEl)
		local A = ATTAQUES[index]
		if index ~= 5 and A then
			afficherMessage(A.nom .. "…", couleur, m.charge + 0.2)
		end
		-- Sécurité : si aucun coup n'arrive, on arrête la charge.
		task.delay(m.charge + 1.5, function()
			if indexEnCharge == index then
				stopperCharge()
				Attaques.annuler()
			end
		end)
	elseif m.type == "rate" then
		stopperCharge()
		Attaques.annuler()
		afficherMessage("Raté : l'ennemi s'est éloigné !", COULEURS.doux, 1)
	elseif m.type == "refus" then
		Sons.jouer("refus")
		if m.raison == "energie" then
			afficherMessage("Pas assez d'énergie !", COULEURS.doux, 0.9)
		end
	elseif m.type == "transfo" then
		local couleur, idEl = couleurElement()
		Sons.jouer("transfo")
		Attaques.transformation(couleur, idEl)
		task.delay(1.6, function()
			if enCombat then
				afficherMessage("TRANSFORMÉ ! Dégâts, vitesse, défense et recharges en hausse.", couleur, 2.5)
			end
		end)
	elseif m.type == "finTransfo" then
		Sons.jouer("finTransfo")
		Attaques.finTransformation()
		afficherMessage("Transformation terminée : tu es épuisé quelques secondes.", COULEURS.doux, 2)
	elseif m.type == "finEpuisement" then
		Attaques.finEpuisement()
		afficherMessage("Tu as repris ton souffle.", COULEURS.vie, 1)
	elseif m.type == "tropLoin" then
		afficherMessage("Trop loin : approche-toi !", COULEURS.doux, 0.8)
	elseif m.type == "degatsRecus" then
		bouclier = m.bouclier or 0
		majVie()
		if m.boucle then
			Sons.jouer("boucle")
		elseif m.degats > 0 then
			Sons.jouer("impactRecu")
			Animations.touche()
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
		stopperCharge()
		Attaques.remettre()
		Sons.jouer("mortMonstre")
		Sons.jouer("victoire")
		Sons.musique(nil)
		enCombat = false
		monstre = nil
		bouclier = 0
		majVie()
		Animations.finCombat()
		Animations.victoire()
		if fiche then
			fiche.pieces = m.total or fiche.pieces
			fiche.victoires = m.victoires or fiche.victoires
		end
		local texteFin = "Le " .. (m.nom or "monstre") .. " est vaincu.\nRécompense : +" .. m.pieces .. " pièces" .. (m.total and (" (total " .. m.total .. ")") or "") .. "."
		local objet = m.objet and Donnees.OBJETS[m.objet]
		if objet then
			texteFin ..= "\nObjet rare : " .. objet.nom .. " !"
		end
		afficherFin(m.boss and "Boss vaincu !" or "Victoire !", texteFin)
		boutonRejouer.Text = "Nouveau combat"
	elseif m.type == "defaite" then
		stopperCharge()
		Attaques.remettre()
		Sons.jouer("defaite")
		Sons.musique(nil)
		Animations.finCombat()
		enCombat = false
		monstre = nil
		bouclier = 0
		attenteRespawn = true
		afficherFin("Tu es tombé…", "Le " .. (m.nom or "monstre") .. " a gagné cette fois. Surveille les alertes rouges et esquive avec Q !")
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
