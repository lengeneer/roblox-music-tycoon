<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">
<Item class="Workspace" referent="RBX0"><Properties><string name="Name">Workspace</string></Properties></Item>
<Item class="ServerScriptService" referent="RBX1"><Properties><string name="Name">ServerScriptService</string></Properties>
<Item class="Script" referent="RBX2"><Properties><string name="Name">MusikTycoonServer</string><ProtectedString name="Source"><![CDATA[--[[
	🎤 MUSIK TYCOON – "Vom Keller zur Legende"
	------------------------------------------------------------
	Server-Script  ->  gehört in ServerScriptService
	Baut beim Start die komplette Map:
	  • 6 große Studio-Plots (Vorderbereich + hinterer Konzertbereich)
	  • 2 Fließbänder, 10 Dropper, insgesamt 20 Upgrades
	    (Laptop-Beats ... Villa ... Konzertbühne ... Hologramm-Bühne)
	  • "Boulevard der Legenden": 20 Musiker aus allen Genres in zwei
	    Reihen, jeder mit eigenem Tanz, Spruch und Outfit.
	    Ganz am Ende wartet die Pop-Legende Nova Stardust.
	  • MEGA-FEATURE: alle 30 Minuten Spielzeit landet ein Superstar-
	    Gast in deinem Studio -> fetter Geld-/Fan-Bonus + x2-Boost
	  • NEUES ALBUM (Rebirth): Nach der Legende im Presswerk am Spawn
	    neu starten -> jedes Album gibt dauerhaft +50 % Einkommen
	  • Speichern per DataStore (nur im veröffentlichten Spiel bzw.
	    mit "Enable Studio Access to API Services")
	Alles unten in EINSTELLUNGEN kannst du frei anpassen.
	Alle Musiker- und Gastnamen sind frei erfunden.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

------------------------------------------------------------------
-- EINSTELLUNGEN
------------------------------------------------------------------
local START_CASH = 50
local PLOT_COUNT = 6           -- Max. Spieler pro Server sollte <= diesem Wert sein
local PLOT_SPACING = 120
local FAN_RATE = 0.2           -- Fans pro $ Track-Wert
local CONVEYOR_SPEED = 14
local SAVE_KEY = "MusikTycoon_v3"

local MEGA_INTERVAL = 30 * 60  -- alle 30 Min Spielzeit ein Mega-Feature (zum Testen z.B. 60)
local BOOST_DURATION = 10 * 60 -- so lange hält der Boost nach einem Mega-Feature
local BOOST_MULT = 2           -- Einkommen x2 während des Boosts
local ALBUM_BONUS = 0.5        -- +50 % Einkommen pro Album (Rebirth)

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

-- Upgrades in Kauf-Reihenfolge
-- kind: "dropper" (spawnt Tracks), "decor" (Multiplikator), "passive" ($ pro Sekunde)
-- needFeatures: so viele Musiker-Features brauchst du, bevor du es kaufen kannst
-- slot 1-5 = vorderes Fließband, slot 6-10 = hinteres Fließband
local ITEMS = {
	-- VORDERER BEREICH
	{id = "laptop",    name = "Laptop-Beats",        cost = 25,       kind = "dropper", value = 5,     interval = 2, slot = 1,  color = rgb(110, 190, 255)},
	{id = "mikro",     name = "Mikrofon",            cost = 150,      kind = "dropper", value = 12,    interval = 2, slot = 2,  color = rgb(255, 120, 200), requires = "laptop"},
	{id = "kabine",    name = "Gesangskabine",       cost = 500,      kind = "decor",   mult = 0.25,   requires = "mikro"},
	{id = "mpc",       name = "MPC-Beatmaschine",    cost = 1200,     kind = "dropper", value = 35,    interval = 2, slot = 3,  color = rgb(255, 170, 60),  requires = "kabine"},
	{id = "mischpult", name = "Mischpult",           cost = 3500,     kind = "dropper", value = 80,    interval = 2, slot = 4,  color = rgb(150, 255, 120), requires = "mpc",      needFeatures = 1},
	{id = "merch",     name = "Merch-Stand",         cost = 9000,     kind = "passive", income = 40,   requires = "mischpult", needFeatures = 2},
	{id = "video",     name = "Musikvideo-Set",      cost = 25000,    kind = "dropper", value = 250,   interval = 2, slot = 5,  color = rgb(200, 120, 255), requires = "merch",    needFeatures = 4},
	{id = "platte",    name = "Goldene Schallplatte", cost = 75000,   kind = "decor",   mult = 0.5,    requires = "video",     needFeatures = 5},
	{id = "bus",       name = "Tourbus",             cost = 200000,   kind = "passive", income = 600,  requires = "platte",    needFeatures = 7},
	{id = "villa",     name = "Villa mit Pool",      cost = 600000,   kind = "decor",   mult = 1,      requires = "bus",       needFeatures = 9},
	-- HINTERER KONZERTBEREICH
	{id = "synth",     name = "Synthesizer-Wand",    cost = 1.5e6,    kind = "dropper", value = 600,   interval = 2, slot = 6,  color = rgb(0, 255, 200),   requires = "villa",    needFeatures = 10},
	{id = "buehne",    name = "Konzertbühne",        cost = 4e6,      kind = "decor",   mult = 1.5,    requires = "synth",     needFeatures = 11},
	{id = "tribuene",  name = "Fan-Tribüne",         cost = 10e6,     kind = "passive", income = 3000, requires = "buehne",    needFeatures = 12},
	{id = "orchester", name = "Orchestergraben",     cost = 30e6,     kind = "dropper", value = 2000,  interval = 2, slot = 7,  color = rgb(255, 230, 150), requires = "tribuene", needFeatures = 13},
	{id = "label",     name = "Eigenes Plattenlabel", cost = 80e6,    kind = "passive", income = 10000, requires = "orchester", needFeatures = 14},
	{id = "laser",     name = "Laser-Show",          cost = 250e6,    kind = "dropper", value = 6000,  interval = 2, slot = 8,  color = rgb(255, 40, 40),   requires = "label",    needFeatures = 15},
	{id = "diamant",   name = "Diamant-Award",       cost = 700e6,    kind = "decor",   mult = 2,      requires = "laser",     needFeatures = 16},
	{id = "heli",      name = "Hubschrauber",        cost = 2e9,      kind = "passive", income = 40000, requires = "diamant",  needFeatures = 17},
	{id = "stadion",   name = "Stadion-Soundsystem", cost = 5e9,      kind = "dropper", value = 20000, interval = 2, slot = 9,  color = rgb(255, 255, 255), requires = "heli",     needFeatures = 18},
	{id = "hologramm", name = "Hologramm-Bühne",     cost = 12e9,     kind = "dropper", value = 60000, interval = 2, slot = 10, color = rgb(120, 160, 255), requires = "stadion",  needFeatures = 19},
}

-- Musiker auf dem Boulevard (in dieser Reihenfolge musst du sie featuren)
-- prop:   mic, headphones, guitar, violin, keytar, sax, baton, crown
-- extras: brille, irokese, langhaar, afro, cowboyhut, zylinder, umhang
-- dance:  hop, sway, groove, headbang, robot, spin
local MUSIKER = {
	{name = "MC Kellerkind",     genre = "Rap",       title = "Untergrund-Rapper",  fans = 0,      cost = 100,    reward = 250,    mult = 0.10, shirt = rgb(70, 70, 70),    cap = rgb(30, 30, 30),    prop = "mic",        extras = {},                      dance = "hop",      spruch = "Hier unten ist der Bass am lautesten!"},
	{name = "DJ Discokugel",     genre = "Techno",    title = "Club-Act",           fans = 200,    cost = 600,    reward = 600,    mult = 0.10, shirt = rgb(20, 20, 40),    cap = rgb(0, 255, 255),   prop = "headphones", extras = {"brille"},              dance = "groove",   spruch = "Ohne Beat kein Treat! 🪩"},
	{name = "Lil Bordstein",     genre = "Rap",       title = "Straßenrapper",      fans = 600,    cost = 1500,   reward = 1200,   mult = 0.15, shirt = rgb(200, 60, 60),   cap = rgb(255, 255, 255), prop = "mic",        extras = {"brille"},              dance = "sway",     spruch = "Der Bordstein ist mein Laufsteg!"},
	{name = "Gitarren-Gunter",   genre = "Rock",      title = "Rock-Newcomer",      fans = 1500,   cost = 4000,   reward = 2500,   mult = 0.20, shirt = rgb(30, 30, 30),    cap = rgb(120, 70, 40),   prop = "guitar",     extras = {"langhaar"},            dance = "headbang", spruch = "Lauter! LAUTER! 🎸"},
	{name = "Schlager-Sabine",   genre = "Schlager",  title = "Schlager-Liebling",  fans = 4000,   cost = 10000,  reward = 5000,   mult = 0.25, shirt = rgb(255, 150, 200), cap = rgb(255, 230, 120), prop = "mic",        extras = {"langhaar"},            dance = "sway",     spruch = "Ein Lied geht immer! 💖"},
	{name = "Lady Lyrik",        genre = "Soul",      title = "Soul-Stimme",        fans = 9000,   cost = 25000,  reward = 10000,  mult = 0.30, shirt = rgb(220, 80, 200),  cap = rgb(60, 20, 80),    prop = "mic",        extras = {"afro"},                dance = "groove",   spruch = "Jeder Reim ein Diamant. 💎"},
	{name = "Reggae-Ralle",      genre = "Reggae",    title = "Sonnenschein-Act",   fans = 15000,  cost = 45000,  reward = 15000,  mult = 0.30, shirt = rgb(40, 160, 60),   cap = rgb(255, 210, 0),   prop = "guitar",     extras = {"langhaar"},            dance = "sway",     spruch = "Ganz entspannt, Brudi... 🌴"},
	{name = "Metal-Manni",       genre = "Metal",     title = "Festival-Headliner", fans = 25000,  cost = 80000,  reward = 25000,  mult = 0.40, shirt = rgb(15, 15, 15),    cap = rgb(60, 60, 60),    prop = "guitar",     extras = {"langhaar", "brille"},  dance = "headbang", spruch = "HEADBANG ODER HEIMGANG! 🤘"},
	{name = "Violetta Violine",  genre = "Klassik",   title = "Orchester-Star",     fans = 45000,  cost = 150000, reward = 40000,  mult = 0.50, shirt = rgb(110, 30, 60),   cap = rgb(90, 50, 20),    prop = "violin",     extras = {"langhaar"},            dance = "sway",     spruch = "Ein Feature mit mir? Nur in C-Dur. 🎻"},
	{name = "Capo Kiosk",        genre = "Rap",       title = "Chartstürmer",       fans = 80000,  cost = 300000, reward = 70000,  mult = 0.60, shirt = rgb(30, 120, 220),  cap = rgb(10, 30, 80),    prop = "mic",        extras = {"brille"},              dance = "robot",    spruch = "Mein Kiosk, meine Regeln."},
	{name = "Jazz-Johanna",      genre = "Jazz",      title = "Jazz-Ikone",         fans = 140000, cost = 700000, reward = 120000, mult = 0.70, shirt = rgb(80, 20, 120),   cap = rgb(20, 20, 20),    prop = "sax",        extras = {"zylinder"},            dance = "groove",   spruch = "Improvisation ist alles. 🎷"},
	{name = "Boyband Blitzlicht", genre = "Boyband",  title = "Teenie-Schwarm",     fans = 250000, cost = 1.5e6,  reward = 200000, mult = 0.80, shirt = rgb(255, 255, 255), cap = rgb(0, 150, 255),   prop = "mic",        extras = {"brille"},              dance = "robot",    spruch = "Wir tanzen synchron – du auch? 🕺"},
	{name = "Country-Kalle",     genre = "Country",   title = "Cowboy-Star",        fans = 400000, cost = 3e6,    reward = 350000, mult = 0.90, shirt = rgb(150, 90, 40),   cap = rgb(110, 70, 30),   prop = "guitar",     extras = {"cowboyhut"},           dance = "hop",      spruch = "Yeehaw, Partner! 🤠"},
	{name = "Pixie Popstar",     genre = "Pop",       title = "Popstar",            fans = 700000, cost = 6e6,    reward = 600000, mult = 1.00, shirt = rgb(255, 100, 220), cap = rgb(120, 220, 255), prop = "keytar",     extras = {"afro"},                dance = "hop",      spruch = "Glitzer ist meine Lieblingsfarbe ✨"},
	{name = "DJ Dezibel",        genre = "EDM",       title = "Mainstage-DJ",       fans = 2e6,    cost = 20e6,   reward = 1.5e6,  mult = 1.20, shirt = rgb(10, 10, 10),    cap = rgb(255, 0, 120),   prop = "headphones", extras = {"irokese", "brille"},   dance = "hop",      spruch = "Bass kommt in 3... 2... 1... 💥"},
	{name = "Opern-Otto",        genre = "Oper",      title = "Opernlegende",       fans = 5e6,    cost = 60e6,   reward = 4e6,    mult = 1.40, shirt = rgb(20, 20, 20),    cap = rgb(150, 0, 0),     prop = "mic",        extras = {"zylinder", "umhang"},  dance = "sway",     spruch = "LA-LA-LAAAAA! 🎭"},
	{name = "Don Platin",        genre = "Rap",       title = "Platin-Artist",      fans = 12e6,   cost = 180e6,  reward = 10e6,   mult = 1.60, shirt = rgb(220, 220, 230), cap = rgb(150, 150, 160), prop = "mic",        extras = {"brille", "umhang"},    dance = "robot",    spruch = "Gold? Nein danke. Platin."},
	{name = "Rockröhre Rita",    genre = "Rock",      title = "Stadion-Rockerin",   fans = 30e6,   cost = 500e6,  reward = 25e6,   mult = 1.80, shirt = rgb(120, 0, 0),     cap = rgb(255, 120, 0),   prop = "guitar",     extras = {"langhaar", "brille"},  dance = "headbang", spruch = "Meine Stimme bricht Glas! 🔥"},
	{name = "Maestro Melodius",  genre = "Filmmusik", title = "Welt-Komponist",     fans = 70e6,   cost = 1.5e9,  reward = 60e6,   mult = 2.00, shirt = rgb(10, 10, 30),    cap = rgb(230, 230, 230), prop = "baton",      extras = {"langhaar", "umhang"},  dance = "sway",     spruch = "Hörst du das? Das ist Gänsehaut. 🎼"},
	{name = "Nova Stardust",     genre = "Pop-Legende", title = "👑 LEGENDE",       fans = 150e6,  cost = 5e9,    reward = 150e6,  mult = 3.00, shirt = rgb(250, 250, 255), cap = rgb(255, 200, 40),  prop = "crown",      extras = {"umhang", "brille"},    dance = "spin",     spruch = "Du hast es bis zu mir geschafft. Bereit für die Ewigkeit? 🌟"},
}

-- Superstar-Gäste fürs Mega-Feature (rotieren der Reihe nach)
local MEGA_GAESTE = {
	{name = "DJ Donnerwetter",       genre = "EDM-Superstar",   shirt = rgb(0, 200, 255),   cap = rgb(255, 255, 0),   prop = "headphones", extras = {"brille"},             dance = "hop",      spruch = "Ich hab den Donner mitgebracht! ⚡"},
	{name = "Die Gold-Boyband",      genre = "Boyband",         shirt = rgb(255, 200, 40),  cap = rgb(255, 255, 255), prop = "mic",        extras = {"brille"},             dance = "robot",    spruch = "Einmal Goldregen für dein Studio!"},
	{name = "Diva Diamant",          genre = "Opern-Diva",      shirt = rgb(180, 220, 255), cap = rgb(200, 200, 255), prop = "crown",      extras = {"langhaar", "umhang"}, dance = "spin",     spruch = "Dahling, das wird ein Hit! 💎"},
	{name = "Rocky Riffmaster",      genre = "Gitarren-Gott",   shirt = rgb(180, 0, 0),     cap = rgb(20, 20, 20),    prop = "guitar",     extras = {"irokese", "brille"},  dance = "headbang", spruch = "Ein Riff – und die Welt bebt! 🤘"},
	{name = "MC Meteor",             genre = "Weltraum-Rapper", shirt = rgb(90, 0, 160),    cap = rgb(0, 255, 150),   prop = "mic",        extras = {"brille", "umhang"},   dance = "groove",   spruch = "Direkt aus dem All in deine Charts! 🚀"},
	{name = "Das Galaxis-Orchester", genre = "Symphonie",       shirt = rgb(20, 20, 60),    cap = rgb(255, 255, 255), prop = "baton",      extras = {"zylinder"},           dance = "sway",     spruch = "Hundert Geigen nur für dich. 🎻"},
}

------------------------------------------------------------------
-- HILFSFUNKTIONEN
------------------------------------------------------------------
local WHITE = rgb(255, 255, 255)
local BLACK = rgb(10, 10, 10)
local DARK = rgb(35, 35, 40)
local GOLD = rgb(255, 200, 40)
local GREEN = rgb(60, 220, 100)
local RED = rgb(230, 60, 60)

local ITEM_BY_ID = {}
for _, it in ipairs(ITEMS) do
	ITEM_BY_ID[it.id] = it
end

local function fmt(n)
	n = tonumber(n) or 0
	local a = math.abs(n)
	if a >= 1e12 then
		return string.format("%.2f Bio", n / 1e12)
	elseif a >= 1e9 then
		return string.format("%.2f Mrd", n / 1e9)
	elseif a >= 1e6 then
		return string.format("%.2f Mio", n / 1e6)
	elseif a >= 1e3 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(math.floor(n))
end

local function block(parent, name, size, cf, color, material, extra)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color or WHITE
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if extra then
		for k, v in pairs(extra) do
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function sign(part, face, text, textColor)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 30
	sg.Parent = part
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Font = Enum.Font.GothamBlack
	l.TextColor3 = textColor or WHITE
	l.TextStrokeTransparency = 0.4
	l.Text = text
	l.Parent = sg
	return l
end

local function billboard(adornee, text, size, offsetY, color)
	local bb = Instance.new("BillboardGui")
	bb.Size = size or UDim2.fromOffset(200, 50)
	bb.StudsOffset = Vector3.new(0, offsetY or 3, 0)
	bb.MaxDistance = 90
	bb.Adornee = adornee
	bb.Parent = adornee
	local l = Instance.new("TextLabel")
	l.Name = "Label"
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Font = Enum.Font.GothamBlack
	l.TextColor3 = color or WHITE
	l.TextStrokeTransparency = 0
	l.Text = text
	l.Parent = bb
	return bb, l
end

local function hasValue(list, v)
	for _, x in ipairs(list or {}) do
		if x == v then return true end
	end
	return false
end

------------------------------------------------------------------
-- REMOTE + DATEN
------------------------------------------------------------------
local remote = Instance.new("RemoteEvent")
remote.Name = "RapTycoonEvent"
remote.Parent = ReplicatedStorage

local function toast(player, text, kind)
	remote:FireClient(player, "toast", {text = text, kind = kind or "info"})
end

local function toastAll(text, kind)
	remote:FireAllClients("toast", {text = text, kind = kind or "info"})
end

local Data = {}
local PLOTS = {}

local store
pcall(function()
	store = DataStoreService:GetDataStore(SAVE_KEY)
end)

local function getMult(d, ohneBoost)
	local m = 1
	for _, it in ipairs(ITEMS) do
		if it.mult and d.owned[it.id] then
			m += it.mult
		end
	end
	for i = 1, d.features do
		m += MUSIKER[i].mult
	end
	m *= (1 + ALBUM_BONUS * (d.albums or 0))
	if not ohneBoost and (d.boostLeft or 0) > 0 then
		m *= BOOST_MULT
	end
	return m
end

local function incomeRate(d)
	local rate = 0
	for _, it in ipairs(ITEMS) do
		if d.owned[it.id] then
			if it.kind == "dropper" then
				rate += it.value / it.interval
			elseif it.income then
				rate += it.income
			end
		end
	end
	return rate * getMult(d, true)
end

local function getRank(d)
	if d.features == 0 then
		return "Nobody"
	end
	return MUSIKER[d.features].title
end

local function updateStats(player)
	local d = Data[player]
	if not d then return end
	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end
	ls.Geld.Value = math.floor(math.min(d.cash, 9e18))
	ls.Fans.Value = math.floor(math.min(d.fans, 9e18))
	ls.Rang.Value = getRank(d)
	ls.Alben.Value = d.albums
	player:SetAttribute("Mult", getMult(d))
	player:SetAttribute("Albums", d.albums)
	player:SetAttribute("CanRebirth", d.features >= #MUSIKER)
	local nxt = MUSIKER[d.features + 1]
	if nxt then
		player:SetAttribute("NextRapper", nxt.name)
		player:SetAttribute("NextFans", nxt.fans)
		player:SetAttribute("NextCost", nxt.cost)
	else
		player:SetAttribute("NextRapper", "")
	end
end

local function notifyOnce(player, key, text, kind)
	local d = Data[player]
	if not d then return end
	local now = os.clock()
	if (d.lastMsg[key] or 0) + 2.5 < now then
		d.lastMsg[key] = now
		toast(player, text, kind)
	end
end

local function addEarnings(player, value)
	local d = Data[player]
	if not d then return end
	local m = getMult(d)
	d.cash += value * m
	d.fans += math.ceil(value * FAN_RATE * m)
	updateStats(player)
end

------------------------------------------------------------------
-- FIGUREN (Musiker + Gäste) mit Instrument, Outfit, Tanz & Spruch
------------------------------------------------------------------
local HAT_EXTRAS = {irokese = true, langhaar = true, afro = true, cowboyhut = true, zylinder = true}

local function buildFigure(parent, cf, r, s)
	local model = Instance.new("Model")
	model.Name = "Figur"
	model:SetAttribute("Dance", r.dance or "sway")
	model:SetAttribute("Spruch", r.spruch or "")
	model:SetAttribute("BaseCF", cf)
	model.Parent = parent

	local skin = rgb(205, 160, 120)
	local function bp(name, size, offset, color, mat, extra)
		return block(model, name, size * s, cf * CFrame.new(offset * s), color, mat, extra)
	end
	bp("BeinL", Vector3.new(1, 2, 1), Vector3.new(-0.5, 1, 0), rgb(40, 40, 60))
	bp("BeinR", Vector3.new(1, 2, 1), Vector3.new(0.5, 1, 0), rgb(40, 40, 60))
	local torso = bp("Torso", Vector3.new(2, 2, 1), Vector3.new(0, 3, 0), r.shirt)
	bp("ArmL", Vector3.new(1, 2, 1), Vector3.new(-1.5, 3, 0), skin)
	bp("ArmR", Vector3.new(1, 2, 1), Vector3.new(1.5, 3, 0), skin)
	local head = bp("Kopf", Vector3.new(1.2, 1.2, 1.2), Vector3.new(0, 4.6, 0), skin)
	sign(head, Enum.NormalId.Front, "😎", WHITE)
	bp("Kette", Vector3.new(1.4, 0.15, 0.1), Vector3.new(0, 3.7, -0.55), GOLD, Enum.Material.Neon)
	bp("Anhaenger", Vector3.new(0.45, 0.45, 0.1), Vector3.new(0, 3.3, -0.56), GOLD, Enum.Material.Neon)

	local extras = r.extras or {}
	local prop = r.prop or "mic"
	local wearsHat = prop == "headphones" or prop == "crown"
	for _, e in ipairs(extras) do
		if HAT_EXTRAS[e] then wearsHat = true end
	end
	if not wearsHat then
		bp("Cap", Vector3.new(1.3, 0.4, 1.3), Vector3.new(0, 5.35, 0), r.cap)
		bp("Schirm", Vector3.new(1.2, 0.15, 0.7), Vector3.new(0, 5.2, -0.9), r.cap)
	end

	-- Outfit-Extras
	if hasValue(extras, "brille") then
		bp("Brille", Vector3.new(1.15, 0.28, 0.1), Vector3.new(0, 4.75, -0.63), BLACK)
	end
	if hasValue(extras, "irokese") then
		bp("Irokese", Vector3.new(0.25, 0.8, 1.1), Vector3.new(0, 5.5, 0), r.cap, Enum.Material.Neon)
	end
	if hasValue(extras, "langhaar") then
		bp("HaarOben", Vector3.new(1.3, 0.3, 1.3), Vector3.new(0, 5.3, 0), r.cap)
		bp("HaarHinten", Vector3.new(1.3, 1.8, 0.3), Vector3.new(0, 4.3, 0.65), r.cap)
	end
	if hasValue(extras, "afro") then
		bp("Afro", Vector3.new(1.9, 1.9, 1.9), Vector3.new(0, 5.2, 0.15), r.cap, nil, {Shape = Enum.PartType.Ball})
	end
	if hasValue(extras, "cowboyhut") then
		bp("HutKrempe", Vector3.new(2.2, 0.12, 2.2), Vector3.new(0, 5.25, 0), r.cap)
		bp("HutOben", Vector3.new(1.2, 0.6, 1.2), Vector3.new(0, 5.6, 0), r.cap)
	end
	if hasValue(extras, "zylinder") then
		bp("ZylKrempe", Vector3.new(1.7, 0.12, 1.7), Vector3.new(0, 5.25, 0), BLACK)
		bp("ZylOben", Vector3.new(1.05, 1.3, 1.05), Vector3.new(0, 5.95, 0), BLACK)
	end
	if hasValue(extras, "umhang") then
		bp("Umhang", Vector3.new(2.2, 3, 0.15), Vector3.new(0, 2.8, 0.62), r.cap, Enum.Material.Fabric)
	end

	-- Instrument / Accessoire
	if prop == "mic" then
		bp("HandMikro", Vector3.new(0.25, 0.9, 0.25), Vector3.new(1.5, 3.1, -0.8), DARK, Enum.Material.Metal)
		bp("HandMikroKopf", Vector3.new(0.45, 0.45, 0.45), Vector3.new(1.5, 3.7, -0.8), rgb(190, 190, 200), Enum.Material.Metal)
	elseif prop == "headphones" then
		bp("Buegel", Vector3.new(1.5, 0.2, 0.3), Vector3.new(0, 5.3, 0), r.cap, Enum.Material.Neon)
		bp("MuschelL", Vector3.new(0.3, 0.7, 0.7), Vector3.new(-0.75, 4.6, 0), DARK)
		bp("MuschelR", Vector3.new(0.3, 0.7, 0.7), Vector3.new(0.75, 4.6, 0), DARK)
		bp("Pult", Vector3.new(3, 0.6, 1.2), Vector3.new(0, 2.6, -1.3), DARK, Enum.Material.Metal)
		bp("PultLicht", Vector3.new(2.6, 0.1, 0.9), Vector3.new(0, 2.95, -1.3), r.cap, Enum.Material.Neon)
	elseif prop == "guitar" then
		bp("GitarreKoerper", Vector3.new(1.6, 1.2, 0.3), Vector3.new(0.1, 2.6, -0.75), rgb(170, 30, 30))
		bp("GitarreHals", Vector3.new(1.9, 0.25, 0.15), Vector3.new(1.8, 2.9, -0.75), rgb(90, 55, 30), Enum.Material.Wood)
	elseif prop == "violin" then
		bp("Geige", Vector3.new(0.6, 1, 0.25), Vector3.new(-0.9, 3.9, -0.7), rgb(140, 70, 25), Enum.Material.Wood)
		bp("Bogen", Vector3.new(2.2, 0.08, 0.08), Vector3.new(-0.2, 4.2, -0.95), rgb(230, 220, 200))
	elseif prop == "keytar" then
		bp("Keytar", Vector3.new(2.6, 0.5, 0.3), Vector3.new(0.2, 2.8, -0.75), WHITE)
		bp("Tasten", Vector3.new(1.8, 0.15, 0.1), Vector3.new(0, 2.85, -0.92), r.cap, Enum.Material.Neon)
	elseif prop == "sax" then
		bp("Saxophon", Vector3.new(0.4, 1.7, 0.4), Vector3.new(0.6, 2.9, -0.8), GOLD, Enum.Material.Metal)
		bp("Trichter", Vector3.new(0.75, 0.5, 0.75), Vector3.new(0.6, 2.0, -0.95), GOLD, Enum.Material.Metal)
	elseif prop == "baton" then
		bp("Taktstock", Vector3.new(0.08, 0.08, 1.6), Vector3.new(1.5, 4.0, -1.1), WHITE, Enum.Material.Neon)
		bp("Notenpult", Vector3.new(1.6, 1.1, 0.15), Vector3.new(0, 2.9, -1.6), DARK, Enum.Material.Metal)
	elseif prop == "crown" then
		bp("Krone", Vector3.new(1.3, 0.4, 1.3), Vector3.new(0, 5.4, 0), GOLD, Enum.Material.Neon)
		for _, c in ipairs({Vector3.new(-0.5, 5.8, -0.5), Vector3.new(0.5, 5.8, -0.5), Vector3.new(-0.5, 5.8, 0.5), Vector3.new(0.5, 5.8, 0.5)}) do
			bp("Zacke", Vector3.new(0.25, 0.5, 0.25), c, GOLD, Enum.Material.Neon)
		end
		bp("Glitzerjacke", Vector3.new(2.1, 2.1, 1.1), Vector3.new(0, 3, 0), r.shirt, Enum.Material.Foil)
		local sp = Instance.new("Sparkles")
		sp.SparkleColor = GOLD
		sp.Parent = torso
	end
	return head, torso, model
end

------------------------------------------------------------------
-- MAP: WELT
------------------------------------------------------------------
Lighting.ClockTime = 17.4
Lighting.Brightness = 2

local MAP = Instance.new("Folder")
MAP.Name = "MusikTycoonMap"
MAP.Parent = workspace

local halfWidth = (PLOT_COUNT * PLOT_SPACING) / 2 + 60
block(MAP, "Boden", Vector3.new(halfWidth * 2, 2, 340), CFrame.new(0, -1, -35), rgb(70, 130, 70), Enum.Material.Grass)
block(MAP, "Boulevard", Vector3.new(halfWidth * 2 - 20, 0.4, 122), CFrame.new(0, 0.2, -118), rgb(45, 45, 50), Enum.Material.Asphalt)
block(MAP, "Mittellinie", Vector3.new(halfWidth * 2 - 40, 0.05, 1), CFrame.new(0, 0.42, -70), GOLD, Enum.Material.Neon)
block(MAP, "Mittellinie2", Vector3.new(halfWidth * 2 - 40, 0.05, 1), CFrame.new(0, 0.42, -125), GOLD, Enum.Material.Neon)

local spawn = Instance.new("SpawnLocation")
spawn.Name = "Spawn"
spawn.Size = Vector3.new(12, 1, 12)
spawn.CFrame = CFrame.new(0, 0.9, -66)
spawn.Anchored = true
spawn.Neutral = true
spawn.Color = GOLD
spawn.Material = Enum.Material.Neon
spawn.Duration = 0
spawn.Parent = MAP

local bigSign = block(MAP, "BoulevardSchild", Vector3.new(130, 16, 1), CFrame.new(0, 48, -190), DARK)
sign(bigSign, Enum.NormalId.Back, "🎤 BOULEVARD DER LEGENDEN 🎤\nvorne: Newcomer  •  hinten: Superstars", GOLD)
block(MAP, "SchildPfosten1", Vector3.new(2, 42, 2), CFrame.new(-60, 21, -190), DARK, Enum.Material.Metal)
block(MAP, "SchildPfosten2", Vector3.new(2, 42, 2), CFrame.new(60, 21, -190), DARK, Enum.Material.Metal)

-- Straßenlaternen
for _, lz in ipairs({-62, -125}) do
	for lx = -380, 380, 76 do
		if lz == -62 and math.abs(lx) < 45 then continue end
		block(MAP, "Laterne", Vector3.new(0.6, 12, 0.6), CFrame.new(lx, 6, lz), DARK, Enum.Material.Metal)
		local lamp = block(MAP, "Lampe", Vector3.new(1.6, 1.6, 1.6), CFrame.new(lx, 12.5, lz), rgb(255, 220, 150), Enum.Material.Neon, {Shape = Enum.PartType.Ball})
		local light = Instance.new("PointLight")
		light.Range = 24
		light.Brightness = 1.5
		light.Color = rgb(255, 210, 150)
		light.Parent = lamp
	end
end

------------------------------------------------------------------
-- MUSIKER AUF DEM BOULEVARD (2 Reihen à 10)
------------------------------------------------------------------
local tryFeature
local tryRebirth
local MUSIKER_HEADS = {}

local perRow = math.ceil(#MUSIKER / 2)
for i, r in ipairs(MUSIKER) do
	local rowIdx = (i <= perRow) and 0 or 1
	local k = (i - 1) % perRow
	local spacing = math.min(80, (halfWidth * 2 - 80) / perRow)
	local x = -((perRow - 1) * spacing) / 2 + k * spacing
	local z = (rowIdx == 0) and -100 or -152
	local h = 1 + i * 1.3
	local folder = Instance.new("Model")
	folder.Name = "Musiker_" .. i .. "_" .. r.name
	folder.Parent = MAP

	local tier = Color3.fromHSV((i - 1) / #MUSIKER * 0.85, 0.8, 1)
	block(folder, "Podest", Vector3.new(12, h, 12), CFrame.new(x, h / 2, z), DARK, Enum.Material.Marble)
	block(folder, "PodestLicht", Vector3.new(12.4, 0.4, 12.4), CFrame.new(x, h - 0.1, z), tier, Enum.Material.Neon)
	local plaque = block(folder, "Tafel", Vector3.new(8, 2.5, 0.3), CFrame.new(x, math.max(1.8, math.min(h - 1.5, 3)), z + 6.1), tier, Enum.Material.Neon)
	sign(plaque, Enum.NormalId.Back, "#" .. i .. " " .. r.genre, BLACK)

	local figCF = CFrame.new(x, h, z) * CFrame.Angles(0, math.pi, 0)
	local head = buildFigure(folder, figCF, r, 2)
	MUSIKER_HEADS[i] = head

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(260, 90)
	bb.StudsOffset = Vector3.new(0, 4.5, 0)
	bb.MaxDistance = 120
	bb.Adornee = head
	bb.Parent = head
	local nameL = Instance.new("TextLabel")
	nameL.Size = UDim2.fromScale(1, 0.5)
	nameL.BackgroundTransparency = 1
	nameL.TextScaled = true
	nameL.Font = Enum.Font.GothamBlack
	nameL.TextColor3 = tier
	nameL.TextStrokeTransparency = 0
	nameL.Text = "#" .. i .. "  " .. r.name .. "  (" .. r.genre .. ")"
	nameL.Parent = bb
	local infoL = Instance.new("TextLabel")
	infoL.Size = UDim2.fromScale(1, 0.5)
	infoL.Position = UDim2.fromScale(0, 0.5)
	infoL.BackgroundTransparency = 1
	infoL.TextScaled = true
	infoL.Font = Enum.Font.GothamBold
	infoL.TextColor3 = WHITE
	infoL.TextStrokeTransparency = 0
	infoL.Text = string.format("👥 %s Fans  •  💸 $%s\n+%d%% Einkommen", fmt(r.fans), fmt(r.cost), math.floor(r.mult * 100 + 0.5))
	infoL.Parent = bb

	local micZ = z + 9
	block(folder, "MikroFuss", Vector3.new(2, 0.3, 2), CFrame.new(x, 0.55, micZ), DARK, Enum.Material.Metal)
	local stand = block(folder, "MikroStaender", Vector3.new(0.3, 4.5, 0.3), CFrame.new(x, 2.9, micZ), DARK, Enum.Material.Metal)
	block(folder, "MikroKopf", Vector3.new(0.9, 0.9, 0.9), CFrame.new(x, 5.4, micZ), rgb(180, 180, 190), Enum.Material.Metal, {Shape = Enum.PartType.Ball})

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Feature machen"
	prompt.ObjectText = r.name
	prompt.HoldDuration = 0.8
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = stand
	prompt.Triggered:Connect(function(player)
		tryFeature(player, i)
	end)
end

-- Album-Presswerk (Rebirth) neben dem Spawn
do
	local f = Instance.new("Model")
	f.Name = "AlbumPresswerk"
	f.Parent = MAP
	local house = block(f, "Presswerk", Vector3.new(14, 10, 10), CFrame.new(32, 5.4, -64), rgb(25, 25, 35), Enum.Material.Metal)
	block(f, "Dach", Vector3.new(15, 1, 11), CFrame.new(32, 10.9, -64), GOLD, Enum.Material.Neon)
	local disc = block(f, "CD", Vector3.new(0.5, 8, 8), CFrame.new(32, 17, -64) * CFrame.Angles(0, math.rad(90), 0), rgb(220, 220, 255), Enum.Material.Foil, {Shape = Enum.PartType.Cylinder})
	sign(house, Enum.NormalId.Back, "💿 NEUES ALBUM\n(nach der Legende)", GOLD)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Neues Album droppen"
	prompt.ObjectText = "Rebirth: +" .. math.floor(ALBUM_BONUS * 100) .. "% für immer"
	prompt.HoldDuration = 2
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = house
	prompt.Triggered:Connect(function(player)
		tryRebirth(player)
	end)
	local _ = disc
end

------------------------------------------------------------------
-- PLOTS (STUDIOS)
------------------------------------------------------------------
local DROPPER_X = {-26, -15, -4, 7, 18}
local LINE_Z = {10, 80}  -- vorderes / hinteres Fließband
local BTN_ROWS = {-36, -24, 56, 66}
local BTN_POS = {}
for i = 1, #ITEMS do
	local row = BTN_ROWS[math.floor((i - 1) / 5) + 1] or 66
	local col = ((i - 1) % 5) * 18 - 36
	BTN_POS[i] = Vector3.new(col, 1.15, row)
end

local refreshButtons

local DECOR = {}

DECOR.kabine = function(o, f)
	local base = CFrame.new(-38, 0, 36)
	block(f, "KabinenBoden", Vector3.new(14, 0.4, 14), o * base * CFrame.new(0, 1.2, 0), rgb(60, 40, 30), Enum.Material.Wood)
	local glass = {Transparency = 0.5}
	block(f, "Glas1", Vector3.new(14, 10, 0.4), o * base * CFrame.new(0, 6.4, -7), rgb(170, 220, 255), Enum.Material.Glass, glass)
	block(f, "Glas2", Vector3.new(0.4, 10, 14), o * base * CFrame.new(-7, 6.4, 0), rgb(170, 220, 255), Enum.Material.Glass, glass)
	block(f, "Wand", Vector3.new(14, 10, 0.4), o * base * CFrame.new(0, 6.4, 7), rgb(40, 40, 45), Enum.Material.Fabric)
	block(f, "Wand2", Vector3.new(0.4, 10, 14), o * base * CFrame.new(7, 6.4, 0), rgb(40, 40, 45), Enum.Material.Fabric)
	block(f, "Dach", Vector3.new(14.4, 0.6, 14.4), o * base * CFrame.new(0, 11.7, 0), DARK)
	block(f, "Staender", Vector3.new(0.3, 5, 0.3), o * base * CFrame.new(0, 3.9, 0), DARK, Enum.Material.Metal)
	block(f, "Mikro", Vector3.new(0.9, 0.9, 0.9), o * base * CFrame.new(0, 6.6, 0), rgb(190, 190, 200), Enum.Material.Metal, {Shape = Enum.PartType.Ball})
	local onAir = block(f, "OnAir", Vector3.new(8, 2, 0.4), o * base * CFrame.new(0, 13, -6), RED, Enum.Material.Neon)
	sign(onAir, Enum.NormalId.Front, "ON AIR", WHITE)
end

DECOR.merch = function(o, f)
	local base = CFrame.new(-42, 0, -8)
	block(f, "Tisch", Vector3.new(10, 3, 4), o * base * CFrame.new(0, 2.5, 0), rgb(120, 80, 50), Enum.Material.Wood)
	local colors = {RED, GOLD, rgb(40, 40, 40), rgb(60, 120, 255)}
	for k = 1, 4 do
		block(f, "Shirt" .. k, Vector3.new(1.8, 0.6, 2), o * base * CFrame.new(-3.6 + (k - 1) * 2.4, 4.3, 0), colors[k], Enum.Material.Fabric)
	end
	local s = block(f, "MerchSchild", Vector3.new(10, 3, 0.4), o * base * CFrame.new(0, 8, 1.8), DARK)
	sign(s, Enum.NormalId.Front, "👕 MERCH", GOLD)
	block(f, "Pfosten1", Vector3.new(0.4, 6, 0.4), o * base * CFrame.new(-4.8, 4, 1.8), DARK, Enum.Material.Metal)
	block(f, "Pfosten2", Vector3.new(0.4, 6, 0.4), o * base * CFrame.new(4.8, 4, 1.8), DARK, Enum.Material.Metal)
end

DECOR.platte = function(o, f)
	local base = CFrame.new(26, 0, 38)
	block(f, "Sockel", Vector3.new(3, 6, 3), o * base * CFrame.new(0, 4, 0), DARK, Enum.Material.Marble)
	block(f, "Platte", Vector3.new(0.6, 11, 11), o * base * CFrame.new(0, 12.5, 0) * CFrame.Angles(0, math.rad(90), 0), GOLD, Enum.Material.Metal, {Shape = Enum.PartType.Cylinder, Reflectance = 0.3})
	block(f, "Label", Vector3.new(0.7, 3.5, 3.5), o * base * CFrame.new(0, 12.5, 0) * CFrame.Angles(0, math.rad(90), 0), RED, Enum.Material.SmoothPlastic, {Shape = Enum.PartType.Cylinder})
end

DECOR.bus = function(o, f)
	local base = CFrame.new(42, 0, -4)
	local body = block(f, "Bus", Vector3.new(10, 8, 24), o * base * CFrame.new(0, 7.5, 0), rgb(25, 25, 30), Enum.Material.Metal)
	block(f, "Fenster", Vector3.new(10.2, 2.5, 20), o * base * CFrame.new(0, 9, 0), rgb(60, 160, 255), Enum.Material.Neon, {Transparency = 0.3})
	sign(body, Enum.NormalId.Left, "WORLD TOUR 2026", GOLD)
	sign(body, Enum.NormalId.Right, "WORLD TOUR 2026", GOLD)
	for _, wx in ipairs({-5.3, 5.3}) do
		for _, wz in ipairs({-8, 8}) do
			block(f, "Rad", Vector3.new(1.5, 4, 4), o * base * CFrame.new(wx, 3, wz), rgb(15, 15, 15), Enum.Material.Rubber, {Shape = Enum.PartType.Cylinder})
		end
	end
end

DECOR.villa = function(o, f)
	local base = CFrame.new(0, 0, 38)
	block(f, "Haus", Vector3.new(36, 14, 14), o * base * CFrame.new(0, 8, 0), rgb(240, 240, 235), Enum.Material.Concrete)
	block(f, "Dach", Vector3.new(38, 1, 16), o * base * CFrame.new(0, 15.5, 0), DARK)
	for k = -2, 2 do
		block(f, "Fenster" .. k, Vector3.new(4, 4, 0.3), o * base * CFrame.new(k * 7, 10, -7.1), rgb(120, 200, 255), Enum.Material.Neon, {Transparency = 0.2})
	end
	block(f, "Tuer", Vector3.new(4, 6, 0.3), o * base * CFrame.new(0, 4, -7.1), GOLD, Enum.Material.Metal)
	local s = block(f, "VillaSchild", Vector3.new(16, 3, 0.4), o * base * CFrame.new(0, 18, -6), DARK)
	sign(s, Enum.NormalId.Front, "💎 VILLA 💎", GOLD)
	block(f, "PoolRand", Vector3.new(26, 0.6, 10), o * CFrame.new(0, 1.3, 24), WHITE, Enum.Material.Marble)
	block(f, "Pool", Vector3.new(24, 0.4, 8), o * CFrame.new(0, 1.5, 24), rgb(40, 170, 255), Enum.Material.Glass, {Transparency = 0.2, CanCollide = false})
end

DECOR.buehne = function(o, f)
	local base = CFrame.new(-28, 0, 100)
	block(f, "Buehne", Vector3.new(30, 3, 14), o * base * CFrame.new(0, 2.5, 0), rgb(20, 20, 25), Enum.Material.Metal)
	block(f, "BuehnenKante", Vector3.new(30.4, 0.3, 14.4), o * base * CFrame.new(0, 4.1, 0), GOLD, Enum.Material.Neon)
	local screen = block(f, "LEDWand", Vector3.new(28, 12, 0.6), o * base * CFrame.new(0, 10, 6.5), rgb(255, 0, 150), Enum.Material.Neon)
	sign(screen, Enum.NormalId.Front, "LIVE 🎤", WHITE)
	for _, sx in ipairs({-14, 14}) do
		block(f, "Box", Vector3.new(3, 8, 3), o * base * CFrame.new(sx, 8, -4), BLACK)
		block(f, "Traverse", Vector3.new(0.6, 16, 0.6), o * base * CFrame.new(sx, 12, 6), rgb(150, 150, 160), Enum.Material.Metal)
	end
	block(f, "TraverseOben", Vector3.new(29, 0.6, 0.6), o * base * CFrame.new(0, 20, 6), rgb(150, 150, 160), Enum.Material.Metal)
end

DECOR.tribuene = function(o, f)
	local base = CFrame.new(-44, 0, 72)
	local crowd = {RED, GOLD, rgb(60, 120, 255), GREEN, rgb(255, 120, 200), WHITE}
	for step = 0, 2 do
		block(f, "Stufe" .. step, Vector3.new(3, 2 + step * 2, 26), o * base * CFrame.new(2.5 - step * 3, 2 + step, 0), rgb(90, 90, 100), Enum.Material.Concrete)
		for n = 0, 5 do
			block(f, "Fan", Vector3.new(1.2, 2.4, 1.2), o * base * CFrame.new(2.5 - step * 3, 4.2 + step * 2, -10 + n * 4), crowd[(n + step) % #crowd + 1])
		end
	end
	local s = block(f, "TribSchild", Vector3.new(0.4, 3, 12), o * base * CFrame.new(4.2, 9, 0), DARK)
	sign(s, Enum.NormalId.Right, "❤ FANS ❤", RED)
end

DECOR.label = function(o, f)
	local base = CFrame.new(34, 0, 100)
	block(f, "Turm", Vector3.new(14, 30, 12), o * base * CFrame.new(0, 16, 0), rgb(30, 40, 60), Enum.Material.Glass, {Transparency = 0.15})
	for lvl = 1, 6 do
		block(f, "Etage" .. lvl, Vector3.new(14.2, 0.4, 12.2), o * base * CFrame.new(0, 1 + lvl * 5, 0), rgb(0, 200, 255), Enum.Material.Neon)
	end
	local s = block(f, "LabelSchild", Vector3.new(14, 4, 0.4), o * base * CFrame.new(0, 33.5, -6), BLACK)
	sign(s, Enum.NormalId.Front, "🏢 DEIN LABEL", GOLD)
end

DECOR.diamant = function(o, f)
	local base = CFrame.new(45, 0, 66)
	block(f, "Sockel", Vector3.new(4, 5, 4), o * base * CFrame.new(0, 3.5, 0), WHITE, Enum.Material.Marble)
	block(f, "Diamant", Vector3.new(4, 4, 4), o * base * CFrame.new(0, 9, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), rgb(170, 240, 255), Enum.Material.Glass, {Transparency = 0.1, Reflectance = 0.4})
	local glow = block(f, "Glanz", Vector3.new(1, 1, 1), o * base * CFrame.new(0, 9, 0), rgb(170, 240, 255), Enum.Material.Neon)
	local sp = Instance.new("Sparkles")
	sp.SparkleColor = rgb(170, 240, 255)
	sp.Parent = glow
end

DECOR.heli = function(o, f)
	local base = CFrame.new(6, 0, 96)
	local pad = block(f, "Landeplatz", Vector3.new(16, 0.4, 16), o * base * CFrame.new(0, 1.2, 0), rgb(50, 50, 55), Enum.Material.Concrete)
	sign(pad, Enum.NormalId.Top, "H", GOLD)
	block(f, "Rumpf", Vector3.new(5, 4.5, 9), o * base * CFrame.new(0, 4.8, 0), rgb(20, 20, 20), Enum.Material.Metal)
	block(f, "Cockpit", Vector3.new(4.6, 3, 2), o * base * CFrame.new(0, 5.3, -5), rgb(80, 180, 255), Enum.Material.Glass, {Transparency = 0.3})
	block(f, "Heck", Vector3.new(1.2, 1.2, 9), o * base * CFrame.new(0, 5.8, 8.5), rgb(20, 20, 20), Enum.Material.Metal)
	block(f, "Rotor", Vector3.new(18, 0.2, 1), o * base * CFrame.new(0, 7.6, 0), GOLD, Enum.Material.Metal)
	block(f, "Rotor2", Vector3.new(1, 0.2, 18), o * base * CFrame.new(0, 7.6, 0), GOLD, Enum.Material.Metal)
	block(f, "KufeL", Vector3.new(0.4, 0.4, 9), o * base * CFrame.new(-2.5, 1.8, 0), DARK, Enum.Material.Metal)
	block(f, "KufeR", Vector3.new(0.4, 0.4, 9), o * base * CFrame.new(2.5, 1.8, 0), DARK, Enum.Material.Metal)
end

local function buildDropper(plot, item, folder)
	local o = plot.origin
	local x = DROPPER_X[(item.slot - 1) % 5 + 1]
	local lz = LINE_Z[(item.slot <= 5) and 1 or 2]
	local model = Instance.new("Model")
	model.Name = item.name
	model.Parent = folder
	block(model, "Pfosten", Vector3.new(1, 10, 1), o * CFrame.new(x, 6, lz + 6), DARK, Enum.Material.Metal)
	block(model, "Arm", Vector3.new(1, 1, 5), o * CFrame.new(x, 11, lz + 3.5), DARK, Enum.Material.Metal)
	local body = block(model, "Gehaeuse", Vector3.new(5, 4, 5), o * CFrame.new(x, 10, lz), item.color)
	block(model, "Duese", Vector3.new(2, 1, 2), o * CFrame.new(x, 7.5, lz), DARK, Enum.Material.Metal)
	sign(body, Enum.NormalId.Front, item.name, BLACK)
	billboard(body, "🎵 +$" .. fmt(item.value), UDim2.fromOffset(120, 34), 4, item.color)

	local spawnCF = o * CFrame.new(x, 6, lz)
	task.spawn(function()
		while model.Parent do
			task.wait(item.interval)
			if not model.Parent or not plot.owner then break end
			local drop = Instance.new("Part")
			drop.Name = "Track"
			drop.Shape = Enum.PartType.Ball
			drop.Size = Vector3.new(1.4, 1.4, 1.4)
			drop.CFrame = spawnCF
			drop.Color = item.color
			drop.Material = Enum.Material.Neon
			drop:SetAttribute("Value", item.value)
			drop.Parent = plot.drops
			pcall(function()
				drop:SetNetworkOwner(nil)
			end)
			Debris:AddItem(drop, 25)
		end
	end)
end

local function buildItem(plot, item)
	local f = Instance.new("Folder")
	f.Name = item.id
	f.Parent = plot.items
	if item.kind == "dropper" then
		buildDropper(plot, item, f)
	elseif DECOR[item.id] then
		DECOR[item.id](plot.origin, f)
	end
end

local function tryBuy(player, plot, item)
	local d = Data[player]
	if not d or d.owned[item.id] then return end
	if item.requires and not d.owned[item.requires] then return end
	if item.needFeatures and d.features < item.needFeatures then
		notifyOnce(player, item.id, "🔒 Mach erst ein Feature mit " .. MUSIKER[item.needFeatures].name .. "!", "bad")
		return
	end
	if d.cash < item.cost then
		notifyOnce(player, item.id, "💸 Zu wenig Geld für " .. item.name .. " ($" .. fmt(item.cost) .. ")", "bad")
		return
	end
	d.cash -= item.cost
	d.owned[item.id] = true
	buildItem(plot, item)
	refreshButtons(plot)
	updateStats(player)
	toast(player, "✅ " .. item.name .. " gekauft!", "good")
	if item.id == "villa" then
		toast(player, "🏟 Der hintere Konzertbereich ist offen! Lauf hinter die Villa.", "good")
	end
end

refreshButtons = function(plot)
	local d = plot.owner and Data[plot.owner]
	for _, item in ipairs(ITEMS) do
		local btn = plot.buttons[item.id]
		local visible = d ~= nil and not d.owned[item.id] and (item.requires == nil or d.owned[item.requires] == true)
		btn.part.Transparency = visible and 0 or 1
		btn.part.CanCollide = visible
		btn.part.CanTouch = visible
		btn.gui.Enabled = visible
		if visible then
			local locked = item.needFeatures and d.features < item.needFeatures
			if locked then
				btn.part.Color = RED
				btn.label.Text = item.name .. "\n🔒 Feature mit " .. MUSIKER[item.needFeatures].name
			else
				btn.part.Color = GREEN
				btn.label.Text = item.name .. "\n$" .. fmt(item.cost)
			end
		end
	end
end

for i = 1, PLOT_COUNT do
	local x = (i - (PLOT_COUNT + 1) / 2) * PLOT_SPACING
	local o = CFrame.new(x, 0, 0)
	local folder = Instance.new("Model")
	folder.Name = "Studio_" .. i
	folder.Parent = MAP

	local plot = {index = i, origin = o, owner = nil, buttons = {}}
	plot.spawnCF = o * CFrame.new(0, 4, -44)

	-- Boden: vorne z -50..50, hinten (Konzertbereich) z 50..110
	block(folder, "Boden", Vector3.new(100, 1, 100), o * CFrame.new(0, 0.5, 0), rgb(55, 55, 62), Enum.Material.Concrete)
	block(folder, "BodenHinten", Vector3.new(100, 1, 60), o * CFrame.new(0, 0.5, 80), rgb(45, 35, 60), Enum.Material.Concrete)
	block(folder, "Trennlinie", Vector3.new(100, 0.1, 1), o * CFrame.new(0, 1.05, 50), GOLD, Enum.Material.Neon)
	block(folder, "WandL", Vector3.new(1, 2, 160), o * CFrame.new(-49.5, 2, 30), DARK)
	block(folder, "WandR", Vector3.new(1, 2, 160), o * CFrame.new(49.5, 2, 30), DARK)
	block(folder, "WandH", Vector3.new(100, 2, 1), o * CFrame.new(0, 2, 109.5), DARK)

	local signPart = block(folder, "Besitzerschild", Vector3.new(30, 6, 0.6), o * CFrame.new(0, 7, -49.5), DARK)
	plot.signLabel = sign(signPart, Enum.NormalId.Front, "Freies Studio #" .. i, GOLD)
	block(folder, "SchildPfosten1", Vector3.new(0.8, 5, 0.8), o * CFrame.new(-14, 2.5, -49.5), DARK, Enum.Material.Metal)
	block(folder, "SchildPfosten2", Vector3.new(0.8, 5, 0.8), o * CFrame.new(14, 2.5, -49.5), DARK, Enum.Material.Metal)

	plot.items = Instance.new("Folder")
	plot.items.Name = "Gekauft"
	plot.items.Parent = folder
	plot.drops = Instance.new("Folder")
	plot.drops.Name = "Tracks"
	plot.drops.Parent = folder
	plot.mega = Instance.new("Folder")
	plot.mega.Name = "MegaFeature"
	plot.mega.Parent = folder

	-- zwei Fließbänder mit Kasse
	for lineIdx, lz in ipairs(LINE_Z) do
		local conveyor = block(folder, "Fliessband" .. lineIdx, Vector3.new(58, 1, 6), o * CFrame.new(-1, 1.5, lz), rgb(30, 30, 30), Enum.Material.DiamondPlate)
		conveyor.AssemblyLinearVelocity = Vector3.new(CONVEYOR_SPEED, 0, 0)
		block(folder, "Gelaender", Vector3.new(58, 1.5, 0.5), o * CFrame.new(-1, 2.75, lz - 3.25), GOLD, Enum.Material.Metal)
		block(folder, "Gelaender", Vector3.new(58, 1.5, 0.5), o * CFrame.new(-1, 2.75, lz + 3.25), GOLD, Enum.Material.Metal)
		local collector = block(folder, "Kasse" .. lineIdx, Vector3.new(6, 3, 8), o * CFrame.new(31, 2.5, lz), GREEN, Enum.Material.Neon)
		billboard(collector, "💰 KASSE", UDim2.fromOffset(140, 40), 3, GREEN)
		collector.Touched:Connect(function(hit)
			if hit.Parent ~= plot.drops then return end
			local v = hit:GetAttribute("Value")
			if not v then return end
			hit:SetAttribute("Value", nil)
			hit:Destroy()
			if plot.owner then
				addEarnings(plot.owner, v)
			end
		end)
	end

	for idx, item in ipairs(ITEMS) do
		local pos = BTN_POS[idx]
		local part = block(folder, "Button_" .. item.id, Vector3.new(5, 0.3, 5), o * CFrame.new(pos), GREEN, Enum.Material.Neon)
		local gui, label = billboard(part, item.name, UDim2.fromOffset(170, 55), 3, WHITE)
		gui.MaxDistance = 45
		plot.buttons[item.id] = {part = part, gui = gui, label = label}
		part.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player and plot.owner == player then
				tryBuy(player, plot, item)
			end
		end)
	end

	PLOTS[i] = plot
	refreshButtons(plot)
end

------------------------------------------------------------------
-- FEATURES
------------------------------------------------------------------
tryFeature = function(player, i)
	local d = Data[player]
	if not d then return end
	local r = MUSIKER[i]
	if d.features >= i then
		toast(player, "Du hast schon ein Feature mit " .. r.name .. " 🤝", "info")
		return
	end
	if d.features < i - 1 then
		toast(player, "🚫 " .. r.name .. " kennt dich nicht. Arbeite dich erst an " .. MUSIKER[d.features + 1].name .. " vorbei!", "bad")
		return
	end
	if d.fans < r.fans then
		toast(player, "👥 " .. r.name .. " will mindestens " .. fmt(r.fans) .. " Fans sehen (du hast " .. fmt(d.fans) .. ")", "bad")
		return
	end
	if d.cash < r.cost then
		toast(player, "💸 Studiozeit mit " .. r.name .. " kostet $" .. fmt(r.cost), "bad")
		return
	end

	d.cash -= r.cost
	d.features = i
	d.fans += r.reward
	updateStats(player)
	if d.plot then
		refreshButtons(d.plot)
	end

	remote:FireClient(player, "feature", {name = r.name, title = r.title, spruch = r.spruch, final = (i == #MUSIKER)})
	local head = MUSIKER_HEADS[i]
	if head then
		local sp = Instance.new("Sparkles")
		sp.SparkleColor = GOLD
		sp.Parent = head
		Debris:AddItem(sp, 4)
	end

	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			toast(other, "🔥 " .. player.DisplayName .. " hat einen Feature mit " .. r.name .. " gedroppt!", "info")
		end
	end
	if i == #MUSIKER then
		toastAll("👑 " .. player.DisplayName .. " ist jetzt eine MUSIK-LEGENDE! 👑", "good")
		toast(player, "💿 Geh zum Album-Presswerk am Spawn und droppe dein nächstes Album!", "good")
	end
end

------------------------------------------------------------------
-- MEGA-FEATURE (alle 30 Minuten Spielzeit)
------------------------------------------------------------------
local claimMega

local function spawnMega(player, d)
	local plot = d.plot
	if not plot then return end
	plot.mega:ClearAllChildren()
	local guest = MEGA_GAESTE[(d.megaCount % #MEGA_GAESTE) + 1]
	local o = plot.origin
	local f = plot.mega

	block(f, "Buehne", Vector3.new(22, 1.5, 10), o * CFrame.new(0, 1.75, -8), rgb(20, 20, 25), Enum.Material.Metal)
	block(f, "BuehnenLicht", Vector3.new(22.4, 0.3, 10.4), o * CFrame.new(0, 2.4, -8), GOLD, Enum.Material.Neon)
	for _, sx in ipairs({-10, 10}) do
		local tower = block(f, "Lichtturm", Vector3.new(1.2, 14, 1.2), o * CFrame.new(sx, 9, -4), DARK, Enum.Material.Metal)
		local sp = Instance.new("Sparkles")
		sp.SparkleColor = GOLD
		sp.Parent = tower
		local fire = Instance.new("Fire")
		fire.Size = 6
		fire.Heat = 12
		fire.Color = rgb(255, 120, 0)
		fire.SecondaryColor = GOLD
		fire.Parent = block(f, "Feuerschale", Vector3.new(2, 1, 2), o * CFrame.new(sx, 16.5, -4), DARK, Enum.Material.Metal)
		for k = 1, 3 do
			local hue = Color3.fromHSV((k * 0.3 + (sx > 0 and 0.15 or 0)) % 1, 1, 1)
			block(f, "Strahl", Vector3.new(0.6, 30, 0.6),
				o * CFrame.new(sx, 16, -4) * CFrame.Angles(math.rad(-20 + k * 10), 0, math.rad(sx > 0 and -25 or 25)) * CFrame.new(0, 15, 0),
				hue, Enum.Material.Neon, {Transparency = 0.5, CanCollide = false, CanTouch = false})
		end
	end

	local head = buildFigure(f, o * CFrame.new(0, 2.5, -8), guest, 2)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(300, 90)
	bb.StudsOffset = Vector3.new(0, 4.5, 0)
	bb.MaxDistance = 200
	bb.AlwaysOnTop = true
	bb.Adornee = head
	bb.Parent = head
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextScaled = true
	l.Font = Enum.Font.GothamBlack
	l.TextColor3 = GOLD
	l.TextStrokeTransparency = 0
	l.Text = "⭐ MEGA-FEATURE ⭐\n" .. guest.name .. " (" .. guest.genre .. ")"
	l.Parent = bb

	block(f, "MegaMikroFuss", Vector3.new(2, 0.3, 2), o * CFrame.new(0, 1.15, -16), GOLD, Enum.Material.Neon)
	local stand = block(f, "MegaMikro", Vector3.new(0.3, 4.5, 0.3), o * CFrame.new(0, 3.5, -16), GOLD, Enum.Material.Metal)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "MEGA-FEATURE aufnehmen!"
	prompt.ObjectText = guest.name
	prompt.HoldDuration = 1.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = stand
	prompt.Triggered:Connect(function(who)
		if not plot.owner then return end
		if who == plot.owner then
			claimMega(who, guest)
		else
			toast(who, "Das ist nicht dein Studio – der Superstar wartet auf " .. plot.owner.DisplayName .. "!", "bad")
		end
	end)

	remote:FireClient(player, "megaArrive", {name = guest.name, genre = guest.genre})
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			toast(other, "⭐ " .. guest.name .. " ist gerade im Studio von " .. player.DisplayName .. " gelandet!", "info")
		end
	end
end

claimMega = function(player, guest)
	local d = Data[player]
	if not d or not d.megaPending then return end
	d.megaPending = false
	d.megaCount += 1
	d.nextMega = d.playtime + MEGA_INTERVAL

	local cash = math.max(2500, math.floor(incomeRate(d) * 600))
	local fans = math.max(1500, math.floor(d.fans * 0.25))
	d.cash += cash
	d.fans += fans
	d.boostLeft = BOOST_DURATION
	updateStats(player)
	if d.plot then
		d.plot.mega:ClearAllChildren()
	end

	remote:FireClient(player, "mega", {
		name = guest.name, genre = guest.genre, spruch = guest.spruch,
		cash = cash, fans = fans, boostMin = math.floor(BOOST_DURATION / 60), boostMult = BOOST_MULT,
	})
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			toast(other, "💥 " .. player.DisplayName .. " hat ein MEGA-FEATURE mit " .. guest.name .. " gedroppt!", "good")
		end
	end
end

------------------------------------------------------------------
-- NEUES ALBUM (Rebirth)
------------------------------------------------------------------
tryRebirth = function(player)
	local d = Data[player]
	if not d then return end
	if d.features < #MUSIKER then
		toast(player, "💿 Erst wenn du mit " .. MUSIKER[#MUSIKER].name .. " gefeatured hast, kannst du ein neues Album droppen.", "bad")
		return
	end
	d.albums += 1
	d.cash = START_CASH
	d.fans = 0
	d.features = 0
	d.owned = {}
	if d.plot then
		d.plot.items:ClearAllChildren()
		d.plot.drops:ClearAllChildren()
		refreshButtons(d.plot)
		local char = player.Character
		if char then
			char:PivotTo(d.plot.spawnCF)
		end
	end
	updateStats(player)
	remote:FireClient(player, "album", {albums = d.albums, bonus = math.floor(ALBUM_BONUS * d.albums * 100)})
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			toast(other, "💿 " .. player.DisplayName .. " hat Album Nr. " .. d.albums .. " gedroppt!", "good")
		end
	end
end

------------------------------------------------------------------
-- SPIELER
------------------------------------------------------------------
local function assignPlot(player)
	local d = Data[player]
	for _, plot in ipairs(PLOTS) do
		if not plot.owner then
			plot.owner = player
			d.plot = plot
			plot.signLabel.Text = "🎤 " .. player.DisplayName .. "s Studio"
			for _, item in ipairs(ITEMS) do
				if d.owned[item.id] then
					buildItem(plot, item)
				end
			end
			refreshButtons(plot)
			return plot
		end
	end
	return nil
end

local function releasePlot(plot)
	plot.owner = nil
	plot.items:ClearAllChildren()
	plot.drops:ClearAllChildren()
	plot.mega:ClearAllChildren()
	plot.signLabel.Text = "Freies Studio #" .. plot.index
	refreshButtons(plot)
end

local function savePlayer(player)
	local d = Data[player]
	if not d or not store or not d.loadOk then return end
	local owned = {}
	for id in pairs(d.owned) do
		table.insert(owned, id)
	end
	local payload = {
		cash = d.cash, fans = d.fans, features = d.features, owned = owned, albums = d.albums,
		playtime = d.playtime, nextMega = d.nextMega, megaCount = d.megaCount, boostLeft = d.boostLeft,
	}
	local ok, err = pcall(function()
		store:SetAsync("p_" .. player.UserId, payload)
	end)
	if not ok then
		warn("[MusikTycoon] Speichern fehlgeschlagen: " .. tostring(err))
	end
end

local function onPlayerAdded(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local function stat(class, name)
		local v = Instance.new(class)
		v.Name = name
		v.Parent = ls
	end
	stat("IntValue", "Geld")
	stat("IntValue", "Fans")
	stat("StringValue", "Rang")
	stat("IntValue", "Alben")
	ls.Parent = player

	local d = {
		cash = START_CASH, fans = 0, features = 0, owned = {}, albums = 0, lastMsg = {}, loadOk = false,
		playtime = 0, nextMega = MEGA_INTERVAL, megaCount = 0, boostLeft = 0, megaPending = false,
	}
	if store then
		local ok, saved = pcall(function()
			return store:GetAsync("p_" .. player.UserId)
		end)
		if ok then
			d.loadOk = true
			if type(saved) == "table" then
				d.cash = tonumber(saved.cash) or START_CASH
				d.fans = tonumber(saved.fans) or 0
				d.features = math.clamp(tonumber(saved.features) or 0, 0, #MUSIKER)
				d.albums = tonumber(saved.albums) or 0
				d.playtime = tonumber(saved.playtime) or 0
				d.nextMega = tonumber(saved.nextMega) or (d.playtime + MEGA_INTERVAL)
				d.megaCount = tonumber(saved.megaCount) or 0
				d.boostLeft = tonumber(saved.boostLeft) or 0
				for _, id in ipairs(saved.owned or {}) do
					if ITEM_BY_ID[id] then
						d.owned[id] = true
					end
				end
			end
		else
			warn("[MusikTycoon] Laden fehlgeschlagen (in Studio API-Zugriff aktivieren?): " .. tostring(saved))
		end
	end
	if not player.Parent then return end
	Data[player] = d

	local plot = assignPlot(player)
	updateStats(player)

	local function toPlot(char)
		if not d.plot then return end
		local hrp = char:WaitForChild("HumanoidRootPart", 5)
		if hrp then
			task.wait(0.1)
			char:PivotTo(d.plot.spawnCF)
		end
	end
	player.CharacterAdded:Connect(toPlot)
	if player.Character then
		task.spawn(toPlot, player.Character)
	end

	task.delay(2, function()
		if not player.Parent then return end
		if plot then
			toast(player, "🎤 Willkommen in deinem Studio! Kauf Laptop-Beats, hol dir Features auf dem Boulevard – alle 30 Min kommt ein MEGA-FEATURE ⭐", "good")
		else
			toast(player, "Alle Studios sind belegt 😕 – Server ist voll.", "bad")
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, p)
end

Players.PlayerRemoving:Connect(function(player)
	savePlayer(player)
	local d = Data[player]
	if d and d.plot then
		releasePlot(d.plot)
	end
	Data[player] = nil
end)

game:BindToClose(function()
	for _, p in ipairs(Players:GetPlayers()) do
		savePlayer(p)
	end
end)

-- Jede Sekunde: Spielzeit, Mega-Feature-Timer, Boost, passives Einkommen
task.spawn(function()
	while true do
		task.wait(1)
		for player, d in pairs(Data) do
			if d.plot then
				d.playtime += 1
				if d.boostLeft > 0 then
					d.boostLeft -= 1
					if d.boostLeft == 0 then
						toast(player, "Der Mega-Boost ist vorbei. Das nächste Mega-Feature kommt bestimmt! ⏱", "info")
						updateStats(player)
					end
				end
				if not d.megaPending and d.playtime >= d.nextMega then
					d.megaPending = true
					spawnMega(player, d)
				end
				player:SetAttribute("MegaIn", d.megaPending and 0 or math.max(0, d.nextMega - d.playtime))
				player:SetAttribute("MegaPending", d.megaPending)
				player:SetAttribute("BoostLeft", d.boostLeft)

				local income = 0
				for _, it in ipairs(ITEMS) do
					if it.income and d.owned[it.id] then
						income += it.income
					end
				end
				if income > 0 then
					d.cash += income * getMult(d)
					d.fans += math.ceil(income * 0.1)
					updateStats(player)
				end
			end
		end
	end
end)

-- Autosave alle 60 Sekunden
task.spawn(function()
	while true do
		task.wait(60)
		for _, p in ipairs(Players:GetPlayers()) do
			savePlayer(p)
		end
	end
end)

print("[MusikTycoon] Map gebaut – viel Spaß auf dem Weg zur Legende! 🎤")
]]></ProtectedString></Properties></Item>
</Item>
<Item class="StarterPlayer" referent="RBX3"><Properties><string name="Name">StarterPlayer</string></Properties>
<Item class="StarterPlayerScripts" referent="RBX4"><Properties><string name="Name">StarterPlayerScripts</string></Properties>
<Item class="LocalScript" referent="RBX5"><Properties><string name="Name">MusikTycoonClient</string><ProtectedString name="Source"><![CDATA[--[[
	🎤 MUSIK TYCOON – Client-GUI
	LocalScript  ->  gehört in StarterPlayer > StarterPlayerScripts
	Zeigt Geld, Fans, Multiplikator, Rang, nächstes Feature
	sowie Benachrichtigungen und das große Feature-Banner.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("RapTycoonEvent")

local GOLD = Color3.fromRGB(255, 200, 40)
local KIND_COLORS = {
	good = Color3.fromRGB(60, 220, 100),
	bad = Color3.fromRGB(240, 80, 80),
	info = Color3.fromRGB(255, 255, 255),
}

local function fmt(n)
	n = tonumber(n) or 0
	local a = math.abs(n)
	if a >= 1e12 then
		return string.format("%.2f Bio", n / 1e12)
	elseif a >= 1e9 then
		return string.format("%.2f Mrd", n / 1e9)
	elseif a >= 1e6 then
		return string.format("%.2f Mio", n / 1e6)
	elseif a >= 1e3 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(math.floor(n))
end

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = parent
end

local function stroke(parent, color)
	local s = Instance.new("UIStroke")
	s.Color = color or GOLD
	s.Thickness = 2
	s.Parent = parent
end

local gui = Instance.new("ScreenGui")
gui.Name = "RapTycoonGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

------------------------------------------------------------------
-- STATS-PANEL
------------------------------------------------------------------
local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(260, 262)
panel.Position = UDim2.new(0, 12, 0.5, -131)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
panel.BackgroundTransparency = 0.15
panel.Parent = gui
corner(panel, 12)
stroke(panel)

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingRight = UDim.new(0, 12)
pad.PaddingTop = UDim.new(0, 8)
pad.Parent = panel

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 2)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = panel

local function row(order, text, color, height, font)
	local l = Instance.new("TextLabel")
	l.LayoutOrder = order
	l.Size = UDim2.new(1, 0, 0, height or 24)
	l.BackgroundTransparency = 1
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextScaled = true
	l.Font = font or Enum.Font.GothamBold
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Text = text
	l.Parent = panel
	return l
end

row(0, "🎤 MUSIK KARRIERE", GOLD, 28, Enum.Font.GothamBlack)
local cashL = row(1, "💵 $0", Color3.fromRGB(120, 255, 140))
local fansL = row(2, "👥 0 Fans")
local multL = row(3, "📈 x1.00")
local rankL = row(4, "🏆 Nobody", GOLD)
local nextL = row(5, "🎯 Nächstes Feature: –", Color3.fromRGB(200, 200, 210), 34, Enum.Font.Gotham)
nextL.TextWrapped = true
local megaL = row(6, "⭐ Mega-Feature in 30:00", GOLD)
local boostL = row(7, "", Color3.fromRGB(120, 220, 255))
local albumL = row(8, "💿 0 Alben", Color3.fromRGB(220, 220, 255))

local function clock(sec)
	sec = math.max(0, math.floor(tonumber(sec) or 0))
	return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

task.spawn(function()
	local ls = player:WaitForChild("leaderstats")
	local geld = ls:WaitForChild("Geld")
	local fans = ls:WaitForChild("Fans")
	local rang = ls:WaitForChild("Rang")
	while gui.Parent do
		cashL.Text = "💵 $" .. fmt(geld.Value)
		fansL.Text = "👥 " .. fmt(fans.Value) .. " Fans"
		multL.Text = string.format("📈 Multiplikator x%.2f", player:GetAttribute("Mult") or 1)
		rankL.Text = "🏆 " .. rang.Value
		local nxt = player:GetAttribute("NextRapper")
		if nxt and nxt ~= "" then
			nextL.Text = string.format("🎯 Nächstes Feature: %s\n(%s Fans, $%s)", nxt, fmt(player:GetAttribute("NextFans")), fmt(player:GetAttribute("NextCost")))
		else
			nextL.Text = "👑 Du hast alle gefeatured!"
		end
		if player:GetAttribute("MegaPending") then
			megaL.Text = "⭐ MEGA-FEATURE wartet im Studio!"
		else
			megaL.Text = "⭐ Mega-Feature in " .. clock(player:GetAttribute("MegaIn"))
		end
		local boost = player:GetAttribute("BoostLeft") or 0
		boostL.Text = boost > 0 and ("🚀 x2-Boost aktiv: " .. clock(boost)) or ""
		local albums = player:GetAttribute("Albums") or 0
		if player:GetAttribute("CanRebirth") then
			albumL.Text = "💿 NEUES ALBUM bereit (Presswerk am Spawn)!"
		else
			albumL.Text = string.format("💿 %d Alben (+%d%%)", albums, albums * 50)
		end
		task.wait(0.2)
	end
end)

------------------------------------------------------------------
-- TOASTS
------------------------------------------------------------------
local toastHolder = Instance.new("Frame")
toastHolder.Size = UDim2.new(0, 460, 0, 200)
toastHolder.Position = UDim2.new(0.5, -230, 0, 10)
toastHolder.BackgroundTransparency = 1
toastHolder.Parent = gui

local tl = Instance.new("UIListLayout")
tl.Padding = UDim.new(0, 6)
tl.HorizontalAlignment = Enum.HorizontalAlignment.Center
tl.SortOrder = Enum.SortOrder.LayoutOrder
tl.Parent = toastHolder

local toastCount = 0
local function showToast(text, kind)
	toastCount += 1
	local f = Instance.new("TextLabel")
	f.LayoutOrder = toastCount
	f.Size = UDim2.new(1, 0, 0, 38)
	f.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	f.BackgroundTransparency = 0.1
	f.TextColor3 = KIND_COLORS[kind] or KIND_COLORS.info
	f.Font = Enum.Font.GothamBold
	f.TextScaled = true
	f.Text = "  " .. text .. "  "
	f.Parent = toastHolder
	corner(f, 8)
	stroke(f, KIND_COLORS[kind] or KIND_COLORS.info)

	-- max. 4 gleichzeitig
	local children = {}
	for _, c in ipairs(toastHolder:GetChildren()) do
		if c:IsA("TextLabel") then
			table.insert(children, c)
		end
	end
	if #children > 4 then
		table.sort(children, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
		children[1]:Destroy()
	end

	task.delay(3.5, function()
		if f.Parent then
			local tw = TweenService:Create(f, TweenInfo.new(0.4), {TextTransparency = 1, BackgroundTransparency = 1})
			tw:Play()
			tw.Completed:Wait()
			f:Destroy()
		end
	end)
end

------------------------------------------------------------------
-- FEATURE-BANNER
------------------------------------------------------------------
local function showBanner(bigText, smallText, color)
	local banner = Instance.new("Frame")
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.fromScale(0.5, 0.4)
	banner.Size = UDim2.fromOffset(0, 0)
	banner.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
	banner.BackgroundTransparency = 0.05
	banner.Parent = gui
	corner(banner, 16)
	stroke(banner, color or GOLD)

	local big = Instance.new("TextLabel")
	big.Size = UDim2.fromScale(1, 0.6)
	big.BackgroundTransparency = 1
	big.Font = Enum.Font.GothamBlack
	big.TextScaled = true
	big.TextColor3 = color or GOLD
	big.Text = bigText
	big.Parent = banner

	local small = Instance.new("TextLabel")
	small.Size = UDim2.fromScale(1, 0.35)
	small.Position = UDim2.fromScale(0, 0.6)
	small.BackgroundTransparency = 1
	small.Font = Enum.Font.GothamBold
	small.TextScaled = true
	small.TextColor3 = Color3.new(1, 1, 1)
	small.Text = smallText
	small.Parent = banner

	TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(560, 130)}):Play()
	task.delay(4, function()
		local tw = TweenService:Create(banner, TweenInfo.new(0.3), {Size = UDim2.fromOffset(0, 0)})
		tw:Play()
		tw.Completed:Wait()
		banner:Destroy()
	end)
end

event.OnClientEvent:Connect(function(kind, data)
	if kind == "toast" then
		showToast(data.text, data.kind)
	elseif kind == "feature" then
		if data.final then
			showBanner("👑 DU BIST EINE LEGENDE 👑", "Feature mit " .. data.name .. " – ganz oben angekommen!")
		else
			showBanner("🔥 FEATURE MIT " .. string.upper(data.name) .. " 🔥", "„" .. (data.spruch or "") .. "“  •  Neuer Rang: " .. data.title)
		end
	elseif kind == "megaArrive" then
		showBanner("⭐ SUPERSTAR IM STUDIO ⭐", data.name .. " (" .. data.genre .. ") wartet auf der Bühne – lauf hin!", Color3.fromRGB(255, 120, 255))
	elseif kind == "album" then
		showBanner("💿 ALBUM NR. " .. data.albums .. " IST DRAUSSEN 💿", "Neustart mit +" .. data.bonus .. "% Einkommen für immer!", Color3.fromRGB(160, 200, 255))
	elseif kind == "mega" then
		showBanner("💥 MEGA-FEATURE MIT " .. string.upper(data.name) .. " 💥",
			string.format("+$%s  •  +%s Fans  •  x%d-Boost für %d Min", fmt(data.cash), fmt(data.fans), data.boostMult, data.boostMin),
			Color3.fromRGB(255, 120, 255))
	end
end)

------------------------------------------------------------------
-- TÄNZE + SPRECHBLASEN (nur lokal, ruckelfrei)
------------------------------------------------------------------
local dancers = {}

local DANCES = {
	hop = function(t) return CFrame.new(0, math.abs(math.sin(t * 4)) * 1.6, 0) end,
	sway = function(t) return CFrame.Angles(0, 0, math.sin(t * 2.5) * 0.12) end,
	groove = function(t) return CFrame.new(0, math.abs(math.sin(t * 3)) * 0.6, 0) * CFrame.Angles(0, math.sin(t * 1.5) * 0.5, math.sin(t * 3) * 0.06) end,
	headbang = function(t) return CFrame.Angles(math.max(0, math.sin(t * 7)) * -0.22, 0, 0) end,
	robot = function(t)
		local step = math.floor(t * 2) % 4
		local yaw = ({0, 0.5, 0, -0.5})[step + 1]
		return CFrame.Angles(0, yaw, 0)
	end,
	spin = function(t) return CFrame.new(0, math.abs(math.sin(t * 2)) * 0.8, 0) * CFrame.Angles(0, t * 1.2, 0) end,
}

local function makeBubble(head, text)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(240, 60)
	bb.StudsOffset = Vector3.new(0, 10, 0)
	bb.Adornee = head
	bb.Enabled = false
	bb.Parent = gui
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundColor3 = Color3.new(1, 1, 1)
	l.TextColor3 = Color3.fromRGB(20, 20, 20)
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	l.TextWrapped = true
	l.Text = text
	l.Parent = bb
	corner(l, 14)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, 8)
	p.PaddingRight = UDim.new(0, 8)
	p.Parent = l
	return bb
end

local function register(model)
	if dancers[model] then return end
	task.spawn(function()
		local head = model:WaitForChild("Kopf", 10)
		if not head then return end
		task.wait(0.3)
		local base = model:GetAttribute("BaseCF")
		if typeof(base) ~= "CFrame" or not model.Parent then return end
		model.WorldPivot = base
		local spruch = model:GetAttribute("Spruch") or ""
		dancers[model] = {
			base = base,
			head = head,
			dance = DANCES[model:GetAttribute("Dance")] or DANCES.sway,
			phase = math.random() * 10,
			bubble = spruch ~= "" and makeBubble(head, spruch) or nil,
		}
	end)
end

local function scan(inst)
	if inst:IsA("Model") and inst.Name == "Figur" then
		register(inst)
	end
end

task.spawn(function()
	local map = workspace:WaitForChild("MusikTycoonMap")
	for _, inst in ipairs(map:GetDescendants()) do
		scan(inst)
	end
	map.DescendantAdded:Connect(scan)
end)

RunService.RenderStepped:Connect(function()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local t = os.clock()
	for model, info in pairs(dancers) do
		if not model.Parent then
			if info.bubble then info.bubble:Destroy() end
			dancers[model] = nil
		else
			local dist = root and (root.Position - info.base.Position).Magnitude or 0
			if dist < 220 then
				model:PivotTo(info.base * info.dance(t + info.phase))
			end
			if info.bubble then
				info.bubble.Enabled = root ~= nil and dist < 40
			end
		end
	end
end)
]]></ProtectedString></Properties></Item>
</Item></Item>
</roblox>