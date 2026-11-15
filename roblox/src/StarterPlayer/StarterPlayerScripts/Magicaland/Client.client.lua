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
local EpeeClient = require(script.Parent:WaitForChild("EpeeClient")) -- style épée (combo à 5 coups + ultime)
local remotes = dossier:WaitForChild("Remotes")
local ObtenirNaissance = remotes:WaitForChild("ObtenirNaissance")
local Commencer = remotes:WaitForChild("Commencer")
local Attaquer = remotes:WaitForChild("Attaquer")
local EtatCombat = remotes:WaitForChild("EtatCombat")
local AttaqueSpeciale = remotes:WaitForChild("AttaqueSpeciale")
local Transformer = remotes:WaitForChild("Transformer")
local Eveiller = remotes:WaitForChild("Eveiller")

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

-- Boutons d'attaque spéciale en arc autour du bouton d'attaque (centre à 79 px du bord droit, 225 px du bas).
local ATTAQUES = Donnees.COMBAT.ATTAQUES
local boutonsAttaque = {}
local ANGLES = { 120, 150, 180, 210, 240 } -- 30° d'écart sur un rayon de 150 : les boutons ne se touchent pas
for i, A in ATTAQUES do
	local taille = (i == 6 and 84) or (i == 5 and 72) or 64
	local cx, cy = 340, 170 -- l'Ultime : sous le bouton de transformation
	if ANGLES[i] then
		local angle = math.rad(ANGLES[i])
		cx = 79 - math.cos(angle) * 150
		cy = 225 + math.sin(angle) * 150
	end
	local b = creer("TextButton", {
		Name = "Attaque" .. i,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -cx, 1, -cy),
		Size = UDim2.fromOffset(taille, taille),
		BackgroundColor3 = (i == 6 and Color3.fromRGB(225, 55, 20)) or (i == 5 and Color3.fromRGB(200, 120, 30)) or Color3.fromRGB(120, 60, 190),
		AutoButtonColor = true,
		Text = "",
	}, hud)
	arrondir(b, taille / 2)
	-- Icône générée de l'attaque en fond, voile sombre par-dessus pour garder le texte lisible.
	if Donnees.ICONES[A.id] then
		creer("ImageLabel", {
			Name = "Icone",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Image = Donnees.ICONES[A.id],
			ZIndex = 0,
		}, b)
		local voileIcone = creer("Frame", {
			Name = "VoileIcone",
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.55,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 0,
		}, b)
		arrondir(voileIcone, taille / 2)
	end
	local contour = creer("UIStroke", { Color = COULEURS.dore, Thickness = 2 }, b)
	local titre = creer("TextLabel", {
		Name = "Titre",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 6, 0.1, 0),
		Size = UDim2.new(1, -12, 0.32, 0),
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextColor3 = Color3.new(1, 1, 1),
		Text = i .. " " .. A.court,
	}, b)
	local cout = creer("TextLabel", {
		Name = "Cout",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0.44, 0),
		Size = UDim2.new(1, -16, 0.22, 0),
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(255, 230, 120),
		Text = A.cout == 0 and "gratuit" or (A.cout .. " ⚡"),
	}, b)
	-- Type et portée de l'attaque (contact, zone ou tir), en petit.
	creer("TextLabel", {
		Name = "Portee",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0.68, 0),
		Size = UDim2.new(1, -20, 0.17, 0),
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextColor3 = Color3.fromRGB(200, 220, 255),
		Text = A.etiquette or "",
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
	boutonsAttaque[i] = { bouton = b, contour = contour, voile = voile, titre = titre, cout = cout, icone = b:FindFirstChild("Icone") }
end

-- Bouton de transformation (jauge pleine), à gauche de l'arc.
local boutonTransfo = creer("TextButton", {
	Name = "Transformation",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -340, 1, -280),
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
creer("ImageLabel", {
	Name = "Icone",
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1, 1),
	Image = Donnees.ICONES.transformation,
	ImageTransparency = 0.25,
	ZIndex = 0,
}, boutonTransfo)
boutonTransfo.TextStrokeTransparency = 0.2
-- Icône de la jauge de puissance, à gauche de la barre.
creer("ImageLabel", {
	Name = "IconeJauge",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(-16, 56),
	Size = UDim2.fromOffset(32, 32),
	Image = Donnees.ICONES.jauge,
	ZIndex = 3,
}, cadreVie)
local contourTransfo = creer("UIStroke", { Color = Color3.fromRGB(120, 90, 90), Thickness = 3 }, boutonTransfo)

-- Bouton d'Éveil (moitié de la jauge), à gauche de la transformation.
local boutonEveil = creer("TextButton", {
	Name = "Eveil",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(1, -440, 1, -225),
	Size = UDim2.fromOffset(70, 70),
	BackgroundColor3 = Color3.fromRGB(40, 55, 80),
	AutoButtonColor = true,
	Font = Enum.Font.GothamBlack,
	TextSize = 13,
	TextColor3 = Color3.new(1, 1, 1),
	TextWrapped = true,
	Text = "ÉVEIL\n(G)",
}, hud)
arrondir(boutonEveil, 35)
local contourEveil = creer("UIStroke", { Color = Color3.fromRGB(90, 110, 140), Thickness = 3 }, boutonEveil)
-- Repère à 50 % sur la jauge : seuil de l'Éveil.
creer("Frame", {
	Name = "SeuilEveil",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.fromScale(Donnees.COMBAT.EVEIL.cout / Donnees.COMBAT.TRANSFO.jaugeMax, 0),
	Size = UDim2.new(0, 2, 1, 0),
	BackgroundColor3 = Color3.fromRGB(140, 200, 255),
	BorderSizePixel = 0,
	ZIndex = 3,
}, fondJauge)

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

-- Compteur de combo, à droite de l'écran.
local cadreCombo = creer("Frame", {
	Name = "Combo",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -20, 0.4, 0),
	Size = UDim2.fromOffset(230, 80),
	BackgroundTransparency = 1,
	Visible = false,
}, hud)
local texteCombo = creer("TextLabel", {
	Name = "Nombre",
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 52),
	Font = Enum.Font.GothamBlack,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = COULEURS.dore,
	TextStrokeTransparency = 0.2,
	Text = "",
}, cadreCombo)
local texteBonus = creer("TextLabel", {
	Name = "Bonus",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 52),
	Size = UDim2.new(1, 0, 0, 24),
	Font = Enum.Font.GothamBold,
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = COULEURS.texte,
	TextStrokeTransparency = 0.3,
	Text = "",
}, cadreCombo)
local echelleCombo = creer("UIScale", { Scale = 1 }, cadreCombo)
local jetonCombo = 0
local function montrerCombo(titre, sous, couleur, duree)
	cadreCombo.Visible = true
	texteCombo.Text = titre
	texteCombo.TextColor3 = couleur
	texteBonus.Text = sous
	echelleCombo.Scale = 1.45
	TweenService:Create(echelleCombo, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	jetonCombo += 1
	local jeton = jetonCombo
	task.delay(duree, function()
		if jeton == jetonCombo then
			cadreCombo.Visible = false
		end
	end)
end

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

-- Chiffres de dégâts stylés : police « comics », contour sombre, dégradé de couleur,
-- apparition qui claque puis petit saut en arc. Taille selon le coup (petit, normal, critique).
local function chiffreSurPart(part, texteChiffre, couleur, taille, fort)
	local panneau = creer("BillboardGui", {
		Size = UDim2.fromOffset(170, 80),
		StudsOffset = Vector3.new(math.random(-18, 18) / 10, 2.5 + math.random(), 0),
		AlwaysOnTop = true,
		LightInfluence = 0,
	}, part)
	local etiquette = creer("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.Bangers,
		TextSize = taille,
		TextColor3 = Color3.new(1, 1, 1),
		Rotation = math.random(-12, 12),
		Text = texteChiffre,
	}, panneau)
	local contour = creer("UIStroke", { Color = Color3.fromRGB(25, 10, 30), Thickness = fort and 3 or 2 }, etiquette)
	creer("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), couleur), Rotation = 90 }, etiquette)
	local echelle = creer("UIScale", { Scale = fort and 2.2 or 1.6 }, etiquette)
	TweenService:Create(echelle, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	local cote = math.random() < 0.5 and -1 or 1
	TweenService:Create(panneau, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffset = panneau.StudsOffset + Vector3.new(cote * 1.5, 3, 0),
	}):Play()
	task.delay(0.45, function()
		TweenService:Create(etiquette, TweenInfo.new(0.35), { TextTransparency = 1 }):Play()
		TweenService:Create(contour, TweenInfo.new(0.35), { Transparency = 1 }):Play()
	end)
	Debris:AddItem(panneau, 0.9)
end

-- Chiffre de dégâts au-dessus du monstre (petit pour la brûlure, énorme pour un critique).
local function chiffreDegats(valeur, couleur, grand)
	local corps = monstre and (monstre:FindFirstChild("Head") or monstre:FindFirstChild("HumanoidRootPart"))
	if not corps then
		return
	end
	local taille = grand and 44 or (valeur <= 5 and 20) or math.min(38, 26 + valeur / 8)
	chiffreSurPart(corps, tostring(valeur) .. (grand and " !" or ""), couleur, taille, grand)
end

-- Dégâts reçus par le joueur : petit chiffre rouge au-dessus de sa tête.
local function chiffreJoueur(valeur)
	local perso = joueur.Character
	local tete = perso and perso:FindFirstChild("Head")
	if tete and valeur > 0 then
		chiffreSurPart(tete, "-" .. valeur, Color3.fromRGB(255, 70, 60), 24, false)
	end
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
-- Combo : le client prévoit le coup suivant pour répondre tout de suite ; le serveur décide et corrige.
local COMBO = Donnees.COMBAT.COMBO
local SONS_COMBO = { "elan", "combo2", "combo3", "comboFinal" }
local comboLocal, dernierLocal, prochainLocal = 0, 0, 0
local transfoActive = false
local eveilActive = false
local function attaquer()
	-- Sabre équipé : combo d'épée (aussi hors combat, pour s'entraîner ; le serveur ne compte les dégâts qu'en combat).
	if EpeeClient.actif() then
		EpeeClient.attaquer()
		return
	end
	if not enCombat then
		return
	end
	local maintenant = os.clock()
	if maintenant < prochainLocal then
		return
	end
	if maintenant - dernierLocal > COMBO.fenetre then
		comboLocal = 0
	end
	comboLocal = comboLocal % #COMBO.etapes + 1
	dernierLocal = maintenant
	local vitesse = (fiche and fiche.don == "flux" and 0.7 or 1) * ((transfoActive and 0.7) or (eveilActive and 0.85) or 1)
	prochainLocal = maintenant + COMBO.etapes[comboLocal].apres * vitesse
	pulseBouton()
	Sons.jouer(SONS_COMBO[comboLocal] or "elan")
	local el = fiche and Donnees.trouver(Donnees.ELEMENTS, fiche.element)
	local corps = monstre and (monstre:FindFirstChild("HumanoidRootPart") or monstre.PrimaryPart)
	Animations.coupCombo(comboLocal, el and el.couleur, corps and corps.Position)
	Attaquer:FireServer()
end

-- Ruée d'esquive (1 s de recharge).
local derniereEsquive = 0
local function esquiver()
	-- Sabre équipé : l'esquive devient le dash (avant 3 s / côté 2 s, annule le combo).
	if EpeeClient.actif() then
		EpeeClient.dash()
		return
	end
	local maintenant = os.clock()
	if maintenant - derniereEsquive < 1 then
		return
	end
	local el = fiche and Donnees.trouver(Donnees.ELEMENTS, fiche.element)
	-- Transformé ou en Éveil : l'esquive devient un flash (téléportation éclair).
	local enFlash = transfoActive or eveilActive
	local ok = enFlash and Animations.flash(el and el.couleur) or Animations.esquive(el and el.couleur)
	if ok then
		derniereEsquive = maintenant
		Sons.jouer(enFlash and "flash" or "esquive")
		boutonEsquive.BackgroundTransparency = 0.5
		task.delay(1, function()
			boutonEsquive.BackgroundTransparency = 0
		end)
	end
end

-- Ressources reçues du serveur (seule source de vérité) et affichage.
local res = { energie = 0, jauge = 0, jaugeMax = 100, recharges = {}, transfo = 0, epuise = 0, eveil = 0, recu = 0 }
local SEUIL_EVEIL = Donnees.COMBAT.EVEIL.cout / Donnees.COMBAT.TRANSFO.jaugeMax
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
		if b.icone then
			b.icone.ImageTransparency = assez and 0 or 0.6
		end
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
		local resteEveil = res.eveil - (maintenant - res.recu)
		if resteEveil > 0 then
			texteJauge.Text = "ÉVEIL : " .. math.ceil(resteEveil) .. " s  ·  puissance " .. math.floor(ratio * 100) .. " %"
		elseif ratio >= 1 then
			texteJauge.Text = "TRANSFORMATION PRÊTE (T) !"
		elseif ratio >= SEUIL_EVEIL then
			texteJauge.Text = "ÉVEIL PRÊT (G)  ·  " .. math.floor(ratio * 100) .. " %"
		else
			texteJauge.Text = "Puissance " .. math.floor(ratio * 100) .. " %"
		end
		boutonTransfo.Text = "TRANSFO\n(T)"
	end
	local eveilReste = res.eveil - (maintenant - res.recu)
	local eveilPret = transfo <= 0 and epuise <= 0 and eveilReste <= 0 and res.jauge >= res.jaugeMax * SEUIL_EVEIL
	boutonEveil.Text = eveilReste > 0 and ("ÉVEIL\n" .. math.ceil(eveilReste) .. " s") or "ÉVEIL\n(G)"
	boutonEveil.BackgroundColor3 = (eveilPret or eveilReste > 0) and Color3.fromRGB(60, 150, 230) or Color3.fromRGB(40, 55, 80)
	contourEveil.Color = eveilPret and COULEURS.dore or Color3.fromRGB(90, 110, 140)
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
	-- Sabre équipé : l'ultime (touche F / 6) devient « Couronne de l'Aube » (même coût et recharge, vérifiés par le serveur).
	if index == 6 and EpeeClient.actif() then
		EpeeClient.ultime()
		return
	end
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

local function eveiller()
	if not enCombat then
		return
	end
	if res.jauge < res.jaugeMax * SEUIL_EVEIL then
		Sons.jouer("refus")
		afficherMessage("Il faut la moitié de la jauge pour l'Éveil.", COULEURS.doux, 1)
		return
	end
	Eveiller:FireServer()
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
boutonEveil.Activated:Connect(eveiller)
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
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.KeypadSix] = 6,
	[Enum.KeyCode.F] = 6,
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
	-- Sabre équipé : F = bloc (maintenu), Q = dash, V = ultime.
	if EpeeClient.entree(entree, true) then
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
	elseif entree.KeyCode == Enum.KeyCode.G then
		eveiller()
	else
		local index = TOUCHES[entree.KeyCode]
		if index then
			lancerAttaque(index)
		end
	end
end)

UserInputService.InputEnded:Connect(function(entree)
	EpeeClient.entree(entree, false)
end)

-- Téléphone avec le sabre : les boutons tactiles du style épée remplacent ATTAQUER / ESQUIVE.
game:GetService("RunService").Heartbeat:Connect(function()
	if EpeeClient.tactile() then
		boutonAttaque.Visible = false
		boutonEsquive.Visible = false
	end
end)

---------------------------------------------------------------------
-- Messages du serveur
---------------------------------------------------------------------
local NOMS_EFFETS = { brulure = "Brûlure !", gel = "Gel !", choc = "Choc !", soin = "+3 PV" }
local SONS_ATTAQUES = { "frappe", "lance", "colonnes", "nova", "eveil", "ultime" }

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
		if m.etape then
			comboLocal = m.etape -- le serveur a le dernier mot sur le coup du combo
		end
		if m.combo and m.combo >= 2 then
			local k = math.clamp(m.combo / 15, 0, 1)
			local sous = "+" .. math.floor((m.bonus or 0) * 100 + 0.5) .. " % dégâts" .. (m.etape == 4 and "  ·  FINAL" or "")
			montrerCombo(m.combo .. " COMBO", sous, COULEURS.dore:Lerp(COULEURS.danger, k), COMBO.fenetre + 0.2)
		end
		if m.finition then
			montrerCombo("FINITION !", "Combo de " .. m.finition .. " : dégâts x1,25", COULEURS.danger, 1.6)
		end
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
				-- Le visuel est parti au « lancer » ; ici, l'impact confirmé par le serveur.
				Sons.jouer("comboImpact")
				Animations.hitstop(m.special >= 5 and 0.2 or 0.1)
			elseif m.pos then
				local final = m.etape == 4
				Animations.impact(m.pos, couleur, m.critique or final, element and element.id)
				if final then
					local pos = m.pos
					task.delay(0.06, function()
						Animations.impact(pos + Vector3.new(0, 1.5, 0), couleur, true, element and element.id)
					end)
					Sons.jouer("comboImpact")
					secousse(1)
				end
				Animations.hitstop(final and 0.12 or (m.critique and 0.09) or (0.035 + 0.01 * (m.etape or 1)))
				if m.critique and not final then
					secousse(0.5)
				end
			end
			if m.special then
				local nomEl = string.upper(element and element.nom or "Magie")
				local titres = { "FRAPPE D'ARCANE !", "LANCE DE " .. nomEl .. " !", "COLONNES DE " .. nomEl .. " !", "NOVA DE " .. nomEl .. " !", "JUGEMENT : " .. m.degats .. " !", "BOULE SUPRÊME : " .. m.degats .. " !" }
				afficherMessage(titres[m.special] or "SORT !", couleur, m.special >= 5 and 2 or 1.2)
			elseif m.etape == 4 then
				afficherMessage(m.critique and "COUP FINAL CRITIQUE !" or "COUP FINAL !", m.critique and COULEURS.dore or couleur, 0.7)
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
		res.eveil = m.eveil or 0
		res.recu = os.clock()
	elseif m.type == "attaque" then
		-- Le serveur a validé : charge visuelle ; le coup arrive ensuite avec le message « coup ».
		stopperCharge()
		local couleur, idEl, nomEl = couleurElement()
		local index = m.index
		indexEnCharge = index
		Sons.jouer((index == 6 and "ultimeCharge") or (index == 5 and "chargeLongue") or "chargeCourte")
		arreterCharge = Attaques.charge(index, couleur, idEl, m.charge, nomEl, m.transforme)
		local A = ATTAQUES[index]
		if index < 5 and A then
			afficherMessage(A.nom .. "…", couleur, m.charge + 0.2)
		end
		-- Sécurité : si aucun coup n'arrive, on arrête la charge.
		task.delay(m.charge + 1.5, function()
			if indexEnCharge == index then
				stopperCharge()
				Attaques.annuler()
			end
		end)
	elseif m.type == "lancer" then
		-- Le coup part (le serveur a choisi le point visé) : mouvement, projectile ou zone, son.
		stopperCharge()
		local couleur, idEl = couleurElement()
		Attaques.dechainer(m.index, m.cible, couleur, idEl, m.rayon, m.vol)
		Sons.jouer(SONS_ATTAQUES[m.index] or "special")
	elseif m.type == "rate" then
		stopperCharge()
		Sons.jouer("rate")
		afficherMessage("Raté !", COULEURS.doux, 0.8)
	elseif m.type == "refus" then
		Sons.jouer("refus")
		if m.raison == "energie" then
			afficherMessage("Pas assez d'énergie !", COULEURS.doux, 0.9)
		end
	elseif m.type == "transfo" then
		local couleur, idEl = couleurElement()
		transfoActive = true
		eveilActive = false
		Sons.jouer("transfo")
		Attaques.transformation(couleur, idEl)
		task.delay(1.6, function()
			if enCombat then
				afficherMessage("TRANSFORMÉ ! Forces x1,8 et nouvelle apparence !", couleur, 2.5)
			end
		end)
	elseif m.type == "transfoMontee" then
		local couleur, idEl = couleurElement()
		Sons.jouer("transfoMontee")
		Attaques.monteeTransfo(couleur, idEl, m.duree)
		-- Le cri, au moment du très gros plan sur les yeux.
		task.delay((m.duree or 2.4) * 0.75, function()
			Sons.jouer("transfoCri")
		end)
	elseif m.type == "eveil" then
		local couleur, idEl = couleurElement()
		eveilActive = true
		Sons.jouer("eveilEtat")
		Attaques.eveilEtat(couleur, idEl)
		afficherMessage("ÉVEIL ! Compétences renforcées (attaques spéciales x1,3, recharges plus courtes).", couleur, 2.5)
	elseif m.type == "finEveil" then
		eveilActive = false
		afficherMessage("Fin de l'Éveil.", COULEURS.doux, 1)
	elseif m.type == "finTransfo" then
		transfoActive = false
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
		chiffreJoueur(m.degats or 0)
		if (m.degats or 0) > 0 then
			-- Un coup reçu casse le combo.
			dernierLocal = 0
			if cadreCombo.Visible then
				montrerCombo("COMBO CASSÉ", "", COULEURS.doux, 0.8)
			end
		end
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
		transfoActive = false
		comboLocal, dernierLocal = 0, 0
		eveilActive = false
		cadreCombo.Visible = false
		Sons.jouer("mortMonstre")
		Sons.jouer("victoire")
		Sons.musique(nil)
		task.delay(4, function()
			if not enCombat then
				Sons.musique("village") -- retour au calme du village
			end
		end)
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
		-- Icône de l'objet rare gagné (à droite du titre).
		local icone = finTitre:FindFirstChild("IconeObjet") or creer("ImageLabel", {
			Name = "IconeObjet",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(64, 64),
		}, finTitre)
		icone.Image = (m.objet and Donnees.ICONES[m.objet]) or ""
		icone.Visible = objet ~= nil and Donnees.ICONES[m.objet] ~= nil
		afficherFin(m.boss and "Boss vaincu !" or "Victoire !", texteFin)
		boutonRejouer.Text = "Nouveau combat"
	elseif m.type == "defaite" then
		stopperCharge()
		Attaques.remettre()
		transfoActive = false
		comboLocal, dernierLocal = 0, 0
		eveilActive = false
		cadreCombo.Visible = false
		Sons.jouer("defaite")
		Sons.musique(nil)
		task.delay(4, function()
			if not enCombat then
				Sons.musique("village") -- retour au calme du village
			end
		end)
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
		Sons.musique("village")
	else
		statut.Text = "Le destin tarde à répondre. Rejoins la partie pour réessayer."
	end
end)
