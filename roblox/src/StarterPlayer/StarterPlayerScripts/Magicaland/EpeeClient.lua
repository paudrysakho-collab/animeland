-- EpeeClient : style « épée » côté client (pipeline d'animation).
-- Joue les animations SUR PLACE et déplace le HumanoidRootPart selon la courbe de racine (EpeeDonnees), gère
-- l'enchaînement du combo (clic mémorisé 0,2 s) et les
-- effets envoyés par le serveur (EpeeFx) pour TOUS les joueurs proches. Le serveur vérifie et décide des dégâts.
-- Étape 10 : prédiction (l'animation part dès le clic ; la lame est aussi testée ici pour jouer tout de suite
-- l'arrêt sur image de 0,03 s, le flash blanc et les effets ; le serveur valide les touches), dash avant / latéral
-- (annule le combo, relève après une projection), bloc (F) et garde, boutons tactiles, mode d'effets allégé.
-- Mission combat (étape 2) : barre d'ultime, sabre doré et « Couronne de l'Aube » retirés ; coups joués plus vite
-- (RG.vitesseCoup) ; dash unique à recharge courte, avec mémoire d'appui et signal clair quand il recharge.
-- Les animations et effets viennent de ReplicatedStorage.PIPE_Epee (FX, RealFX, Sequences).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local UserInputService = game:GetService("UserInputService")

local joueur = Players.LocalPlayer
local dossier = ReplicatedStorage:WaitForChild("Magicaland")
local D = require(dossier:WaitForChild("EpeeDonnees"))
local remotes = dossier:WaitForChild("Remotes")
local AttaquerEpee = remotes:WaitForChild("AttaquerEpee")
local EpeeFx = remotes:WaitForChild("EpeeFx")
local BlocEpee = remotes:WaitForChild("BlocEpee")
local DashEpee = remotes:WaitForChild("DashEpee")
local EtatCombat = remotes:WaitForChild("EtatCombat")
local pipe = ReplicatedStorage:WaitForChild("PIPE_Epee")
local FX = require(pipe:WaitForChild("FX"))
local RFX = require(pipe:WaitForChild("RealFX"))

local E = {}
local pistes, persoCharge = {}, nil
local function nouvelEtat()
	return { etape = 0, cle = nil, debut = 0, file = false, depart = nil, verrou = nil, swing = false,
		imageTestee = 0, bloc = false, projete = false, sonne = 0 }
end
local etat = nouvelEtat()
local predits = {} -- [cle] = heure de la touche prédite (pour ne pas rejouer l'effet quand le serveur confirme)
local DISTANCE_EFFETS = 120 -- les autres joueurs voient les effets jusqu'à cette distance
local RG = require(dossier:WaitForChild("EpeeReglages")) -- réglages partagés avec le serveur
local HITSTOP = RG.HITSTOP
local RAYON_LAME = RG.RAYON_LAME
local BLOC_VITESSE = RG.BLOC_VITESSE -- vitesse de marche en garde
local POSE_GARDE = RG.POSE_GARDE
local DASH = RG.DASH
local dashPret = 0 -- heure à laquelle le dash est de nouveau prêt
local dashDemande = 0 -- appui mémorisé pendant la fin de la recharge
local signalDashJusqua = 0 -- la jauge du dash clignote après un appui trop tôt
local fpsCompte, fpsDebut, fpsBasJusqua = 0, os.clock(), 0 -- mode allégé automatique sous 45 images/s

local function idAnimation(seq)
	-- En Studio : séquence enregistrée à la volée. Dans le jeu publié : attribut AnimationId posé sur la séquence
	-- (voir pipeline-anim/04_roblox/a_publier.txt).
	local publie = seq:GetAttribute("AnimationId")
	if publie and publie ~= "" then
		return publie
	end
	return KeyframeSequenceProvider:RegisterKeyframeSequence(seq)
end

-- Mode d'effets allégé (particules divisées par 2) : téléphone, qualité graphique basse, ou attribut PIPE_FxLeger.
local function majModeLeger()
	local q = 0
	pcall(function()
		q = UserSettings().GameSettings.SavedQualityLevel.Value
	end)
	local leger = joueur:GetAttribute("PIPE_FxLeger") == true
		or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
		or (q > 0 and q <= 3)
		or os.clock() < fpsBasJusqua
	RFX.Echelle = leger and RG.FX.ECHELLE_ALLEGEE or 1
	if joueur:GetAttribute("PIPE_FxEchelle") ~= RFX.Echelle then
		joueur:SetAttribute("PIPE_FxEchelle", RFX.Echelle) -- affichage / tests seulement
	end
end

local function charger()
	local perso = joueur.Character
	if not perso then
		return nil
	end
	if persoCharge == perso then
		FX.Setup(perso) -- le sabre peut arriver après le préchargement (rien n'est recréé s'il est déjà prêt)
		return perso
	end
	local hum = perso:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not animator then
		return nil
	end
	pistes = {}
	local seqs = pipe:WaitForChild("Sequences")
	local function piste(nomSeq)
		local seq = seqs:FindFirstChild(nomSeq)
		if not seq then
			return nil
		end
		local a = Instance.new("Animation")
		a.AnimationId = idAnimation(seq)
		local tr = animator:LoadAnimation(a)
		tr.Looped = false
		tr.Priority = Enum.AnimationPriority.Action4
		return tr
	end
	for cle, c in pairs(D.coups) do
		pistes[cle] = piste(c.seq)
	end
	pistes.garde = piste(D.coups[POSE_GARDE.cle].seq)
	if pistes.garde then
		pistes.garde.Priority = Enum.AnimationPriority.Action3
	end
	persoCharge = perso
	FX.Setup(perso)
	majModeLeger()
	return perso
end

function E.actif()
	return joueur:GetAttribute("PIPE_Epee") == true
end

local function tactile()
	return UserInputService.TouchEnabled or joueur:GetAttribute("PIPE_ForceTactile") == true
end
function E.tactile()
	return E.actif() and tactile()
end

local function comboActuel()
	return joueur:GetAttribute("PIPE_Combo") == "EpeisteAvance" and "EpeisteAvance" or "Epeiste"
end

-- Bloque la marche pendant un coup (le HRP est déplacé par la courbe de racine).
local function verrouiller(perso, oui)
	local hum = perso:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	if oui and not etat.verrou then
		etat.verrou = { vitesse = hum.WalkSpeed, saut = hum.JumpPower, auto = hum.AutoRotate }
		hum.WalkSpeed = 0
		hum.AutoRotate = false
	elseif not oui and etat.verrou then
		hum.WalkSpeed = etat.verrou.vitesse
		hum.AutoRotate = etat.verrou.auto
		etat.verrou = nil
	end
end

local function racineA(racine, tp)
	local f = tp * D.fps
	local i = math.floor(f)
	local n = #racine / 2
	if n == 0 then
		return 0, 0
	end
	i = math.clamp(i, 0, n - 1)
	local j = math.min(i + 1, n - 1)
	local a = f - i
	local x = racine[i * 2 + 1] + (racine[j * 2 + 1] - racine[i * 2 + 1]) * a
	local z = racine[i * 2 + 2] + (racine[j * 2 + 2] - racine[i * 2 + 2]) * a
	return x, z
end

-- Ennemi du combat en cours (créé par le serveur : « Monstre_<nom> » ou « Boss_<nom> »).
local function cibleCombat()
	local m = workspace:FindFirstChild("Monstre_" .. joueur.Name) or workspace:FindFirstChild("Boss_" .. joueur.Name)
	local corps = m and (m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart)
	return m, corps
end

local function distancePlat(a, b)
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- Demi-largeur du corps de la cible : d'après son HumanoidRootPart (la silhouette entière, bras écartés et
-- décor compris, surestime la taille et laissait le joueur trop loin).
local function rayonCible(m, corps)
	if corps and corps.Name == "HumanoidRootPart" then
		return math.max(corps.Size.X, corps.Size.Z) / 2 * 1.1
	end
	local taille = m:GetExtentsSize()
	return math.min(math.max(taille.X, taille.Z) / 2, 4)
end

-- Ciblage léger : au début d'un coup, se tourner vers l'ennemi et s'en approcher d'au plus 4 studs
-- (le serveur tolère 4,5 studs de plus que le déplacement prévu du coup).
local function departVersCible(hrp)
	local m, corps = cibleCombat()
	if not corps then
		return hrp.CFrame
	end
	local plat = Vector3.new(corps.Position.X, hrp.Position.Y, corps.Position.Z)
	local d = (plat - hrp.Position).Magnitude
	if d < 0.5 or d > 22 then
		return hrp.CFrame
	end
	local voulu = rayonCible(m, corps) + 2.2
	local avance = math.clamp(d - voulu, 0, RG.CIBLAGE_AVANCE)
	local dir = (plat - hrp.Position).Unit
	return CFrame.lookAt(hrp.Position + dir * avance, plat)
end

-- Le déplacement de racine d'un coup ne doit ni faire entrer le joueur DANS la cible, ni la lui faire TRAVERSER
-- (il se retrouvait derrière elle, dos tourné, et la lame ne touchait plus). L'avancée est limitée le long de la
-- direction de départ : le joueur s'arrête à (demi-largeur de la cible + 1,2 stud) devant elle.
local function garderDistance(cf)
	local m, corps = cibleCombat()
	if not corps or not etat.depart then
		return cf
	end
	local avant = etat.depart.LookVector * Vector3.new(1, 0, 1)
	if avant.Magnitude < 0.05 then
		return cf
	end
	avant = avant.Unit
	local vers0 = (corps.Position - etat.depart.Position) * Vector3.new(1, 0, 1)
	if vers0:Dot(avant) < 0 then
		return cf -- la cible était derrière le joueur au départ du coup : rien à limiter
	end
	local mini = rayonCible(m, corps) + 1.2
	local vers = (corps.Position - cf.Position) * Vector3.new(1, 0, 1)
	local devant = vers:Dot(avant)
	local cote = (vers - avant * devant).Magnitude
	if devant >= mini or cote > mini then
		return cf
	end
	return cf - avant * (mini - devant)
end

---------------------------------------------------------------------
-- Interface : recharge du dash, garde, messages ; boutons tactiles
---------------------------------------------------------------------
local function creer(classe, props, parent)
	local o = Instance.new(classe)
	for k, v in pairs(props) do
		o[k] = v
	end
	o.Parent = parent
	return o
end
local function arrondir(o, r)
	creer("UICorner", { CornerRadius = UDim.new(0, r) }, o)
end

local pg = joueur:WaitForChild("PlayerGui")
local hud = creer("ScreenGui", { Name = "PIPE_EpeeHUD", ResetOnSpawn = false, DisplayOrder = 5, Enabled = false }, pg)
local cadre = creer("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18),
	Size = UDim2.fromOffset(320, 60), BackgroundTransparency = 1 }, hud)
local texteDash = creer("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.GothamBold,
	TextSize = 13, TextColor3 = Color3.fromRGB(220, 235, 255), TextStrokeTransparency = 0.5, Text = "DASH PRÊT (Q)" }, cadre)
local fondDash = creer("Frame", { Position = UDim2.fromOffset(60, 18), Size = UDim2.new(1, -120, 0, 10),
	BackgroundColor3 = Color3.fromRGB(16, 22, 34), BackgroundTransparency = 0.2 }, cadre)
arrondir(fondDash, 5)
local barreDash = creer("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(150, 205, 255) }, fondDash)
arrondir(barreDash, 5)
local fondGarde = creer("Frame", { Position = UDim2.fromOffset(40, 34), Size = UDim2.new(1, -80, 0, 6),
	BackgroundColor3 = Color3.fromRGB(16, 22, 34), BackgroundTransparency = 0.2 }, cadre)
arrondir(fondGarde, 3)
local barreGarde = creer("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(120, 180, 255) }, fondGarde)
arrondir(barreGarde, 3)
local texteInfos = creer("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 0, 16),
	Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(230, 235, 245), TextStrokeTransparency = 0.6, Text = "" }, cadre)
local annonceLabel = creer("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3),
	Size = UDim2.fromOffset(520, 40), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 26,
	TextColor3 = Color3.new(1, 1, 1), TextStrokeTransparency = 0.35, Text = "", Visible = false }, hud)
local voileRouge = creer("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 30, 20),
	BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0 }, hud)

local jetonAnnonce = 0
local function annonce(texte, couleur, duree)
	jetonAnnonce += 1
	local j = jetonAnnonce
	annonceLabel.Text = texte
	annonceLabel.TextColor3 = couleur or Color3.new(1, 1, 1)
	annonceLabel.Visible = true
	task.delay(duree or 1, function()
		if jetonAnnonce == j then
			annonceLabel.Visible = false
		end
	end)
end
E.annonce = annonce

local function flashRougeEcran()
	RFX.animate(0.35, function(a)
		voileRouge.BackgroundTransparency = 0.72 + 0.28 * a
	end, function()
		voileRouge.BackgroundTransparency = 1
	end)
end

-- Boutons tactiles (téléphone) : attaque, dash, bloc (maintenu). Les boutons ATTAQUER / ESQUIVE de base
-- sont cachés par Client quand celui-ci est affiché.
local tactileGui = creer("ScreenGui", { Name = "PIPE_EpeeTactile", ResetOnSpawn = false, DisplayOrder = 6, Enabled = false }, pg)
local boutons = {}
local function bouton(nom, texte, x, y, taille, couleur)
	local b = creer("TextButton", { Name = nom, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, x, 1, y),
		Size = UDim2.fromOffset(taille, taille), BackgroundColor3 = couleur, BackgroundTransparency = 0.15, AutoButtonColor = true,
		Font = Enum.Font.GothamBlack, TextSize = taille > 100 and 18 or 14, TextColor3 = Color3.new(1, 1, 1), Text = texte }, tactileGui)
	arrondir(b, taille // 2)
	creer("UIStroke", { Color = Color3.fromRGB(240, 200, 110), Thickness = 2 }, b)
	boutons[nom] = b
	return b
end
local bAttaque = bouton("Attaque", "ATTAQUE", -24, -150, 112, Color3.fromRGB(190, 60, 50))
local bDash = bouton("Dash", "DASH", -150, -146, 80, Color3.fromRGB(60, 120, 200))
local bBloc = bouton("Bloc", "BLOC", -28, -276, 80, Color3.fromRGB(70, 80, 100))
E.boutons = boutons

---------------------------------------------------------------------
-- Effets locaux : images rémanentes, arrêt sur image
---------------------------------------------------------------------
local function dossierFx()
	local f = workspace:FindFirstChild("PIPE_FX")
	if not f then
		f = Instance.new("Folder")
		f.Name = "PIPE_FX"
		f.Parent = workspace
	end
	return f
end

-- Copie translucide du personnage (membres, tenue et sabre), qui s'efface en « duree » secondes.
local function imageRemanente(perso, couleur, duree, transparence)
	local m = Instance.new("Model")
	m.Name = "PIPE_Remanence"
	local function copier(p)
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" and p.Transparency < 0.9 and not p.Name:match("^PIPE_Eye") then
			local g = p:Clone()
			g:ClearAllChildren()
			g.Anchored = true
			g.CanCollide = false
			g.CanQuery = false
			g.CanTouch = false
			g.CastShadow = false
			g.Massless = true
			g.Material = Enum.Material.Neon
			g.Color = couleur
			g.Transparency = transparence
			if g:IsA("MeshPart") then
				pcall(function()
					g.TextureID = ""
				end)
			end
			g.CFrame = p.CFrame
			g.Parent = m
		end
	end
	for _, p in ipairs(perso:GetChildren()) do
		copier(p)
		if p.Name == "PIPE_Sword" or p.Name == "PIPE_Saya" or p:IsA("Model") or p:IsA("Accessory") then
			for _, q in ipairs(p:GetDescendants()) do
				copier(q)
			end
		end
	end
	m.Parent = dossierFx()
	local parts = m:GetChildren()
	RFX.animate(duree, function(a)
		for _, g in ipairs(parts) do
			g.Transparency = transparence + (1 - transparence) * a
		end
	end, function()
		m:Destroy()
	end)
	return m
end
E.imageRemanente = imageRemanente

local function arretSurImage(tr, vitesse)
	etat.debut += HITSTOP
	if tr and tr.IsPlaying then
		tr:AdjustSpeed(0)
		task.delay(HITSTOP, function()
			if tr.IsPlaying and tr.Speed == 0 then
				tr:AdjustSpeed(vitesse or 1)
			end
		end)
	end
end

---------------------------------------------------------------------
-- Prédiction de touche (même balayage de lame que le serveur, sans rembobinage)
---------------------------------------------------------------------
local paramsCible = RaycastParams.new()
paramsCible.FilterType = Enum.RaycastFilterType.Include
local overlapCible = OverlapParams.new()
overlapCible.FilterType = Enum.RaycastFilterType.Include

local function predireTouche(perso, c, tp)
	local m, corps = cibleCombat()
	if not m or not corps then
		return nil
	end
	local hrp = perso.HumanoidRootPart
	if c.contact then
		if tp >= c.touche[1] and tp <= c.touche[2] then
			local taille = m:GetExtentsSize()
			if distancePlat(corps.Position, hrp.Position) <= math.max(taille.X, taille.Z) / 2 + 4 then
				return FX.HitPoint(perso, { short = "kick" })
			end
		end
		return nil
	end
	paramsCible.FilterDescendantsInstances = { m }
	overlapCible.FilterDescendantsInstances = { m }
	local cf = hrp.CFrame
	local function pt(img, i)
		return cf * Vector3.new(img[i], img[i + 1], img[i + 2])
	end
	for idx = etat.imageTestee + 1, #c.lame do
		local img = c.lame[idx]
		if img[1] > tp then
			break
		end
		etat.imageTestee = idx
		local a, b = pt(img, 2), pt(img, 5)
		local segs = { { a, b } }
		local prec = c.lame[idx - 1]
		if prec then
			local pa, pb = pt(prec, 2), pt(prec, 5)
			table.insert(segs, { pb, b })
			table.insert(segs, { (pa + pb) / 2, (a + b) / 2 })
		end
		for _, s in ipairs(segs) do
			local d = s[2] - s[1]
			if d.Magnitude > 0.05 then
				local r = workspace:Spherecast(s[1], RAYON_LAME, d, paramsCible)
				if r then
					return r.Position
				end
			end
		end
		for _, q in ipairs({ b, (a + b) / 2, a }) do
			if #workspace:GetPartBoundsInRadius(q, 1.2, overlapCible) > 0 then
				return q
			end
		end
	end
	return nil
end

local function jouerToucheLocale(perso, cle, pos)
	local c = D.coups[cle]
	local m = cibleCombat()
	FX.TargetFlash(m, 0.05)
	if c.final then
		FX.Impact(perso, pos, pistes[cle], RG.vitesseCoup(cle)) -- impact frame : seulement pour celui qui frappe
	else
		arretSurImage(pistes[cle], RG.vitesseCoup(cle))
		FX.Hit(perso, pos, c.contact and "kick" or nil)
	end
end

---------------------------------------------------------------------
-- Combo
---------------------------------------------------------------------
local function annulerCombo(perso)
	local tr = etat.cle and pistes[etat.cle]
	if tr and tr.IsPlaying then
		tr:Stop(0.06)
	end
	if etat.swing then
		FX.Swing(perso, false, nil)
		etat.swing = false
	end
	etat.cle, etat.etape, etat.file = nil, 0, false
	verrouiller(perso, false)
end

local function jouerCoup(perso, k)
	local liste = D[comboActuel()]
	local cle = liste[k]
	local c = D.coups[cle]
	local tr = pistes[cle]
	if not tr then
		return
	end
	local precedent = etat.cle and pistes[etat.cle]
	if precedent and precedent ~= tr then
		precedent:Stop(D.FONDU)
	end
	etat.etape = (k == #liste) and 0 or k
	etat.cle = cle
	etat.debut = os.clock()
	etat.file = false
	etat.swing = false
	etat.imageTestee = 0
	predits[cle] = nil
	etat.depart = departVersCible(perso.HumanoidRootPart)
	perso.HumanoidRootPart.CFrame = etat.depart
	verrouiller(perso, true)
	tr:Play(D.FONDU) -- prédiction : l'animation part tout de suite, le serveur valide ensuite
	tr:AdjustSpeed(RG.vitesseCoup(cle)) -- coups plus rapides que la source
	FX.MoveStart(perso, { short = c.nom })
	AttaquerEpee:FireServer(k)
end

local function occupe()
	return etat.bloc or etat.projete or os.clock() < etat.sonne or os.clock() < (E.occupeJusqua or 0)
end
E.occupe = occupe -- lu par CompetencesClient (E.occupeJusqua = fin de la compétence en cours)
function E.annulerCombo()
	local p = joueur.Character
	if p then
		annulerCombo(p)
	end
end

function E.attaquer()
	if not E.actif() or occupe() then
		return
	end
	local perso = charger()
	if not perso then
		return
	end
	local c = etat.cle and D.coups[etat.cle]
	local tReel = os.clock() - etat.debut
	local t = tReel * RG.vitesseCoup(etat.cle) -- temps de l'animation
	if c and c.final and t < math.min(c.coupe, c.touche[2] + 0.45) then
		return -- le coup final va jusqu'au bout de sa frappe
	end
	if not c or tReel > c.coupe / RG.vitesseCoup(etat.cle) + D.RESET then
		jouerCoup(perso, 1)
	elseif t < c.enchainement[1] then
		etat.file = os.clock() -- clic mémorisé 0,2 s : le coup suivant part si la fenêtre s'ouvre à temps
	elseif t <= c.enchainement[2] then
		jouerCoup(perso, etat.etape == 0 and 1 or etat.etape + 1)
	else
		jouerCoup(perso, 1)
	end
end

---------------------------------------------------------------------
-- Bloc (F) : garde maintenue ; parade parfaite si levée juste avant le coup (décidé par le serveur)
---------------------------------------------------------------------
function E.bloquer(oui)
	local perso = charger()
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	if oui then
		if not E.actif() or etat.bloc or etat.projete or os.clock() < etat.sonne
			or (joueur:GetAttribute("PIPE_Garde") or 100) <= 0 then
			return
		end
		annulerCombo(perso)
		etat.bloc = true
		etat.vitesseAvantBloc = hum.WalkSpeed
		hum.WalkSpeed = hum.WalkSpeed * BLOC_VITESSE
		local g = pistes.garde
		if g then
			g:Play(0.08)
			g.TimePosition = POSE_GARDE.t
			g:AdjustSpeed(0)
		end
		BlocEpee:FireServer(true)
	else
		if not etat.bloc then
			return
		end
		etat.bloc = false
		if etat.vitesseAvantBloc then
			hum.WalkSpeed = etat.vitesseAvantBloc
			etat.vitesseAvantBloc = nil
		end
		if pistes.garde then
			pistes.garde:Stop(0.12)
		end
		BlocEpee:FireServer(false)
	end
end

---------------------------------------------------------------------
-- Projection (coup lourd encaissé) et relevé
---------------------------------------------------------------------
local function relever(perso)
	etat.projete = false
	local hum = perso:FindFirstChildOfClass("Humanoid")
	local hrp = perso:FindFirstChild("HumanoidRootPart")
	if hum then
		hum.PlatformStand = false
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	if hrp then
		local look = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
		if look.Magnitude < 0.1 then
			look = Vector3.new(0, 0, -1)
		end
		hrp.AssemblyAngularVelocity = Vector3.zero
		local p = hrp.Position + Vector3.new(0, 0.5, 0)
		hrp.CFrame = CFrame.lookAt(p, p + look.Unit)
	end
end

local function projeterJoueur(perso, depuis)
	local hum = perso:FindFirstChildOfClass("Humanoid")
	local hrp = perso:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then
		return
	end
	annulerCombo(perso)
	if etat.bloc then
		E.bloquer(false)
	end
	etat.projete = true
	local jeton = {}
	etat.jetonProjete = jeton
	local dir = (hrp.Position - depuis) * Vector3.new(1, 0, 1)
	dir = dir.Magnitude > 0.05 and dir.Unit or -hrp.CFrame.LookVector
	hum.PlatformStand = true
	hrp.AssemblyLinearVelocity = dir * 42 + Vector3.new(0, 30, 0)
	hrp.AssemblyAngularVelocity = dir:Cross(Vector3.yAxis) * -8
	FX.Shake(0.35, 0.25)
	annonce("PROJETÉ ! Dash (Q) pour te relever", Color3.fromRGB(255, 170, 150), 1)
	task.delay(RG.PROJECTION_JOUEUR - 0.05, function()
		if etat.projete and etat.jetonProjete == jeton and perso.Parent then
			relever(perso)
		end
	end)
end

---------------------------------------------------------------------
-- Dash : une seule recharge courte (RG.DASH.recharge), vers l'avant ou dans la direction du déplacement.
-- Il annule le combo et le bloc, et relève après une projection. Un appui fait pendant la fin de la recharge
-- (RG.DASH.tampon) est gardé et part dès que le dash est prêt. Plus tôt, l'appui donne un signal clair
-- (son sourd + jauge du dash qui clignote) : le joueur voit que c'est la recharge, pas un bug.
---------------------------------------------------------------------
function E.dash()
	if not E.actif() or os.clock() < etat.sonne then
		return
	end
	local maintenant = os.clock()
	if maintenant < dashPret then
		if dashPret - maintenant <= DASH.tampon then
			dashDemande = maintenant -- gardé : part dès la fin de la recharge
		else
			signalDashJusqua = maintenant + 0.35
			local r = joueur.Character and joueur.Character:FindFirstChild("HumanoidRootPart")
			if r then
				FX.Sound(FX.Sounds.swingLight, r.Position, 0.15, 0.5)
			end
		end
		return
	end
	local perso = charger()
	local hum = perso and perso:FindFirstChildOfClass("Humanoid")
	local hrp = perso and perso:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.Health <= 0 then
		return
	end
	local look = hrp.CFrame.LookVector * Vector3.new(1, 0, 1)
	look = look.Magnitude > 0.05 and look.Unit or Vector3.new(0, 0, -1)
	local dir = hum.MoveDirection * Vector3.new(1, 0, 1)
	local sorte = "avant"
	if dir.Magnitude > 0.1 then
		dir = dir.Unit
		if dir:Dot(look) < 0.5 then
			sorte = "cote"
		end
	else
		dir = look
	end
	local P = DASH[sorte]
	dashPret = maintenant + DASH.recharge
	dashDemande = 0
	annulerCombo(perso)
	if E.surDash then
		E.surDash() -- un dash avant le contact annule la compétence en cours
	end
	if etat.bloc then
		E.bloquer(false)
	end
	if etat.projete then
		relever(perso)
	end
	local att = Instance.new("Attachment")
	att.Name = "PIPE_DashAtt"
	att.Parent = hrp
	local lv = Instance.new("LinearVelocity")
	lv.Name = "PIPE_Dash"
	lv.Attachment0 = att
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	lv.PrimaryTangentAxis = Vector3.new(1, 0, 0)
	lv.SecondaryTangentAxis = Vector3.new(0, 0, 1)
	lv.PlaneVelocity = Vector2.new(dir.X, dir.Z) * P.vitesse
	lv.MaxForce = 1e6
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.Parent = hrp
	task.delay(P.duree, function()
		lv:Destroy()
		att:Destroy()
	end)
	local sol = hrp.Position - Vector3.new(0, hum.HipHeight + hrp.Size.Y / 2, 0)
	RFX.Dust(sol, 0.6)
	for i = 0, 2 do
		task.delay(i * 0.05, function()
			if perso.Parent then
				imageRemanente(perso, Color3.fromRGB(190, 215, 255), 0.22, 0.65)
			end
		end)
	end
	FX.Sound(FX.Sounds.swingLight, hrp.Position, 0.5, 0.8)
	DashEpee:FireServer(sorte)
end

---------------------------------------------------------------------
-- Entrées : F = bloc (maintenu), Q = dash
---------------------------------------------------------------------
function E.entree(entree, debut)
	if not E.actif() then
		return false
	end
	local k = entree.KeyCode
	if k == Enum.KeyCode.F then
		E.bloquer(debut)
		return true
	elseif not debut then
		return false
	elseif k == Enum.KeyCode.Q then
		E.dash()
		return true
	end
	return false
end

bAttaque.Activated:Connect(function()
	E.attaquer()
end)
bDash.Activated:Connect(function()
	E.dash()
end)
bBloc.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
		E.bloquer(true)
	end
end)
bBloc.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
		E.bloquer(false)
	end
end)

---------------------------------------------------------------------
-- Boucle : déplacement de la racine, traînée, prédiction de touche, coup suivant mémorisé, fin de coup, interface
---------------------------------------------------------------------
local prochaineMajUI = 0
local function majInterface()
	local actif = E.actif()
	hud.Enabled = actif
	tactileGui.Enabled = actif and tactile()
	if not actif then
		return
	end
	local t = os.clock()
	-- Dash : jauge qui se remplit pendant la recharge ; elle clignote en rouge si on appuie trop tôt.
	local reste = math.max(0, dashPret - t)
	local signal = t < signalDashJusqua
	barreDash.Size = UDim2.fromScale(1 - math.clamp(reste / DASH.recharge, 0, 1), 1)
	if reste > 0 then
		texteDash.Text = ("DASH EN RECHARGE  %.1f s"):format(reste)
		barreDash.BackgroundColor3 = signal and Color3.fromRGB(255, 120, 90) or Color3.fromRGB(110, 130, 160)
	else
		texteDash.Text = "DASH PRÊT (Q)"
		barreDash.BackgroundColor3 = Color3.fromRGB(150, 205, 255)
	end
	texteDash.TextColor3 = signal and Color3.fromRGB(255, 150, 120) or Color3.fromRGB(220, 235, 255)
	local garde = joueur:GetAttribute("PIPE_Garde") or 100
	barreGarde.Size = UDim2.fromScale(math.clamp(garde / 100, 0, 1), 1)
	barreGarde.BackgroundColor3 = garde < 30 and Color3.fromRGB(255, 120, 90) or Color3.fromRGB(120, 180, 255)
	texteInfos.Text = "Garde (F)   ·   Dash (Q)"
	bDash.Text = reste > 0 and ("DASH\n%.1f"):format(reste) or "DASH"
	bDash.BackgroundTransparency = reste > 0 and 0.55 or 0.15
end

RunService.RenderStepped:Connect(function()
	FX.UpdateCamera()
	local maintenant = os.clock()
	fpsCompte += 1
	if maintenant - fpsDebut >= 2 then
		if fpsCompte / (maintenant - fpsDebut) < RG.FX.FPS_ALLEGE then
			fpsBasJusqua = maintenant + 10 -- images par seconde trop basses : effets allégés pendant 10 s
		end
		fpsCompte, fpsDebut = 0, maintenant
	end
	if maintenant >= prochaineMajUI then
		prochaineMajUI = maintenant + 0.1
		majInterface()
		if math.floor(maintenant) % 2 == 0 then
			majModeLeger()
		end
	end
	if dashDemande > 0 and maintenant >= dashPret then
		dashDemande = 0
		E.dash() -- appui mémorisé pendant la fin de la recharge
	end
	if not etat.cle then
		return
	end
	local perso = joueur.Character
	local c = D.coups[etat.cle]
	local tr = pistes[etat.cle]
	if not perso or not c or not tr or not perso:FindFirstChild("HumanoidRootPart") then
		return
	end
	local vitesse = RG.vitesseCoup(etat.cle)
	local tReel = maintenant - etat.debut
	local t = tReel * vitesse -- temps de l'animation (coups joués plus vite que la source)
	local tp = tr.IsPlaying and tr.TimePosition or t
	if tp <= c.coupe then
		local x, z = racineA(c.racine, tp)
		perso.HumanoidRootPart.CFrame = garderDistance(etat.depart * CFrame.new(x, 0, z))
	end
	local surLame = tp >= c.touche[1] - 0.12 and tp <= c.touche[2] + 0.05 and not c.contact
	if surLame ~= etat.swing then
		etat.swing = surLame
		FX.Swing(perso, surLame, { short = c.nom, final = c.final })
	end
	-- Prédiction : la lame est testée ici aussi ; l'effet de touche part sans attendre le serveur.
	if not predits[etat.cle] and tp >= c.touche[1] - 0.001 and tp <= c.touche[2] + 0.05 then
		local pos = predireTouche(perso, c, tp)
		if pos then
			predits[etat.cle] = maintenant
			jouerToucheLocale(perso, etat.cle, pos)
		end
	end
	if etat.file and maintenant - etat.file > RG.TAMPON_CLIC then
		etat.file = false -- clic fait trop en avance : oublié
	end
	if etat.file and t >= c.enchainement[1] and etat.etape ~= 0 then
		jouerCoup(perso, etat.etape + 1)
		return
	end
	if t >= c.coupe and tr.IsPlaying then
		tr:Stop(c.final and 0.25 or 0.15)
	end
	if t >= c.coupe + 0.1 and etat.verrou then
		verrouiller(perso, false)
	end
	if tReel > c.coupe / vitesse + D.RESET then
		etat.cle = nil
		etat.etape = 0
	end
end)

-- Coups lourds annoncés par le serveur : flash rouge, impossible à bloquer.
EtatCombat.OnClientEvent:Connect(function(m)
	if type(m) == "table" and m.type == "alerte" and m.lourd and E.actif() then
		flashRougeEcran()
		annonce("COUP LOURD : IMPARABLE ! Esquive avec un dash (Q)", Color3.fromRGB(255, 110, 90), 1)
	end
end)

local function effetGarde(pos, couleur, n)
	if not pos then
		return
	end
	RFX.Budget(40)
	RFX.Sparks(pos, n, couleur)
	RFX.Budget()
	local p = RFX.part({ Name = "PIPE_GardeLight", CFrame = CFrame.new(pos) })
	local l = Instance.new("PointLight")
	l.Color = couleur
	l.Range = 12
	l.Brightness = 6
	l.Parent = p
	RFX.animate(0.18, function(a)
		l.Brightness = 6 * (1 - a)
	end, function()
		p:Destroy()
	end)
end

-- Effets décidés par le serveur, pour tous les joueurs proches.
EpeeFx.OnClientEvent:Connect(function(m)
	local auteur = m.joueur
	local perso = auteur and auteur.Character
	local moi = joueur.Character
	local racineMoi = moi and moi:FindFirstChild("HumanoidRootPart")
	if auteur == joueur then
		if m.type == "touche" and moi then
			local c = D.coups[m.cle]
			if predits[m.cle] and os.clock() - predits[m.cle] < 1.5 then
				-- déjà joué par la prédiction
			else
				FX.TargetFlash(cibleCombat(), 0.05)
				if c and c.final then
					FX.Impact(moi, m.pos, pistes[m.cle], RG.vitesseCoup(m.cle))
				else
					arretSurImage(pistes[m.cle], RG.vitesseCoup(m.cle))
					FX.Hit(moi, m.pos, c and c.contact and "kick" or nil)
				end
			end
		elseif m.type == "parade" then
			effetGarde(m.pos, Color3.fromRGB(255, 220, 130), 24)
			FX.TargetFlash(m.cible, 0.08)
			FX.Sound(FX.Sounds.hitMetal, m.pos or racineMoi.Position, 0.9, 1.25)
			FX.Sound(FX.Sounds.final, m.pos or racineMoi.Position, 0.35, 0.7)
			FX.Shake(0.2, 0.15)
			FX.Zoom(62, 0.3)
			annonce("PARADE PARFAITE !", Color3.fromRGB(255, 225, 130), 0.9)
		elseif m.type == "bloque" then
			effetGarde(m.pos, Color3.fromRGB(170, 205, 255), 10)
			FX.Sound(FX.Sounds.hitMetal, m.pos or racineMoi.Position, 0.6, 0.9)
			FX.Shake(0.1, 0.1)
		elseif m.type == "gardeCassee" then
			effetGarde(m.pos, Color3.fromRGB(255, 140, 100), 18)
			FX.Sound(FX.Sounds.hitMetal, m.pos or racineMoi.Position, 0.9, 0.7)
			FX.Shake(0.3, 0.2)
			local p = charger()
			if p then
				if etat.bloc then
					etat.bloc = true -- E.bloquer(false) restaure la vitesse et la pose
					E.bloquer(false)
				end
				etat.sonne = os.clock() + (m.duree or 1.5)
				verrouiller(p, true)
				task.delay(m.duree or 1.5, function()
					if os.clock() >= etat.sonne - 0.01 and not etat.cle then
						verrouiller(p, false)
					end
				end)
			end
			annonce("GARDE BRISÉE !", Color3.fromRGB(255, 140, 100), 1.2)
		elseif m.type == "projete" then
			local p = charger()
			if p and m.depuis then
				projeterJoueur(p, m.depuis)
			end
		elseif m.type == "mur" then
			RFX.WallImpact(m.pos, m.normal)
			FX.Shake(0.25, 0.18)
			FX.Sound(FX.Sounds.kick, m.pos, 0.8, 0.7)
		end
		return
	end
	-- Autres joueurs : effets dans le monde + léger tremblement s'ils sont proches.
	local pos = m.pos or (perso and perso:FindFirstChild("HumanoidRootPart") and perso.HumanoidRootPart.Position)
	if not pos or not racineMoi or (racineMoi.Position - pos).Magnitude > DISTANCE_EFFETS then
		return
	end
	local proche = (racineMoi.Position - pos).Magnitude < 40
	if m.type == "touche" then
		RFX.Budget(40)
		RFX.Sparks(pos, m.final and 24 or 12)
		RFX.Budget()
		if m.final then
			RFX.Impact(pos, 1)
		end
		if proche then
			FX.Shake(m.final and 0.2 or 0.06, 0.15)
		end
	elseif m.type == "parade" or m.type == "bloque" or m.type == "gardeCassee" then
		effetGarde(pos, m.type == "parade" and Color3.fromRGB(255, 220, 130) or Color3.fromRGB(170, 205, 255), 10)
	elseif m.type == "mur" then
		RFX.WallImpact(pos, m.normal)
	end
end)

-- Préchargement des animations dès que le sabre est équipé : sinon le 1er coup ou le 1er dash saccade
-- (mesuré : 290 ms de retard et un dash 2 fois plus court).
local function prechargerBientot()
	task.delay(1, function()
		if E.actif() then
			charger()
		end
	end)
end
joueur:GetAttributeChangedSignal("PIPE_Epee"):Connect(prechargerBientot)
prechargerBientot()

joueur.CharacterAdded:Connect(function()
	persoCharge = nil
	etat = nouvelEtat()
	prechargerBientot()
end)

return E
