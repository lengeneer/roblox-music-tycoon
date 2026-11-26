--[[
	🎤 MUSIK TYCOON – Client  (v4 – Neon-Nights-Redesign)
	LocalScript  ->  gehört in StarterPlayer > StarterPlayerScripts
	• Karriere-Panel mit Fortschrittsbalken zum nächsten Feature
	• Benachrichtigungen + große Banner
	• Wegweiser-Strahl zum nächsten Ziel (Feature / Mega-Feature / Album)
	• Status über jedem Musiker (✅ gefeatured / 🎯 als Nächstes / 🔒)
	• Tänze, Sprechblasen, drehende Deko und pulsierende Neon-Lichter
	  (alles nur lokal -> ruckelfrei und ohne Server-Last)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("MusikTycoonEvent")

local GOLD = Color3.fromRGB(255, 200, 40)
local PINK = Color3.fromRGB(255, 60, 170)
local CYAN = Color3.fromRGB(40, 220, 255)
local BG = Color3.fromRGB(16, 14, 24)
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

local function clock(sec)
	sec = math.max(0, math.floor(tonumber(sec) or 0))
	return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or GOLD
	s.Thickness = thickness or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function gradient(parent, a, b, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(a, b)
	g.Rotation = rot or 0
	g.Parent = parent
	return g
end

local gui = Instance.new("ScreenGui")
gui.Name = "MusikTycoonGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Auf kleinen Bildschirmen (Handy) alles etwas kleiner
local uiScale = Instance.new("UIScale")
uiScale.Parent = gui
local function rescale()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local y = cam.ViewportSize.Y
	uiScale.Scale = math.clamp(y / 820, 0.62, 1)
end
rescale()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
end

------------------------------------------------------------------
-- KARRIERE-PANEL
------------------------------------------------------------------
local panel = Instance.new("Frame")
panel.Name = "Karriere"
panel.AnchorPoint = Vector2.new(0, 0.5)
panel.Size = UDim2.fromOffset(270, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.Position = UDim2.new(0, 12, 0.5, 0)
panel.BackgroundColor3 = BG
panel.BackgroundTransparency = 0.12
panel.Parent = gui
corner(panel, 14)
local panelStroke = stroke(panel, PINK, 2)
gradient(panelStroke, PINK, CYAN, 45)

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingRight = UDim.new(0, 12)
pad.PaddingTop = UDim.new(0, 10)
pad.PaddingBottom = UDim.new(0, 10)
pad.Parent = panel

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 3)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = panel

local function row(order, text, color, height, font)
	local l = Instance.new("TextLabel")
	l.LayoutOrder = order
	l.Size = UDim2.new(1, 0, 0, height or 22)
	l.BackgroundTransparency = 1
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextScaled = true
	l.Font = font or Enum.Font.GothamBold
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.Text = text
	l.Parent = panel
	return l
end

local function bar(order, color)
	local back = Instance.new("Frame")
	back.LayoutOrder = order
	back.Size = UDim2.new(1, 0, 0, 14)
	back.BackgroundColor3 = Color3.fromRGB(40, 36, 55)
	back.Parent = panel
	corner(back, 7)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = color
	fill.Parent = back
	corner(fill, 7)
	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Font = Enum.Font.GothamBold
	txt.TextScaled = true
	txt.TextColor3 = Color3.new(1, 1, 1)
	txt.TextStrokeTransparency = 0.3
	txt.ZIndex = 2
	txt.Parent = back
	return fill, txt
end

local title = row(0, "🎤 MUSIK-KARRIERE", GOLD, 28, Enum.Font.GothamBlack)
gradient(title, GOLD, PINK, 0)
title.TextColor3 = Color3.new(1, 1, 1)
local cashL = row(1, "💵 $0", Color3.fromRGB(120, 255, 140), 26, Enum.Font.GothamBlack)
local incomeL = row(2, "⚡ $0/s", Color3.fromRGB(180, 255, 190), 18)
local fansL = row(3, "👥 0 Fans")
local multL = row(4, "📈 x1.00")
local rankL = row(5, "🏆 Nobody", GOLD)
local nextL = row(6, "🎯 Nächstes Feature: –", Color3.fromRGB(210, 210, 225), 20, Enum.Font.GothamBold)
local fanFill, fanTxt = bar(7, CYAN)
local cashFill, cashTxt = bar(8, Color3.fromRGB(90, 220, 120))
local megaL = row(9, "⭐ Mega-Feature in 30:00", GOLD)
local boostL = row(10, "", Color3.fromRGB(120, 220, 255))
local albumL = row(11, "💿 0 Alben", Color3.fromRGB(220, 220, 255))

local function setBar(fill, txt, have, need, label)
	local pct = need > 0 and math.clamp(have / need, 0, 1) or 1
	TweenService:Create(fill, TweenInfo.new(0.25), {Size = UDim2.fromScale(pct, 1)}):Play()
	if pct >= 1 then
		txt.Text = "✅ " .. label .. " erreicht"
	else
		txt.Text = string.format("%s: %s / %s", label, fmt(have), fmt(need))
	end
end

local geld, fans, rang
task.spawn(function()
	local ls = player:WaitForChild("leaderstats")
	geld = ls:WaitForChild("Geld")
	fans = ls:WaitForChild("Fans")
	rang = ls:WaitForChild("Rang")
	while gui.Parent do
		cashL.Text = "💵 $" .. fmt(geld.Value)
		incomeL.Text = "⚡ ca. $" .. fmt(player:GetAttribute("Income") or 0) .. " pro Sekunde"
		fansL.Text = "👥 " .. fmt(fans.Value) .. " Fans"
		multL.Text = string.format("📈 Multiplikator x%.2f", player:GetAttribute("Mult") or 1)
		rankL.Text = "🏆 " .. rang.Value
		local nxt = player:GetAttribute("NextRapper")
		if nxt and nxt ~= "" then
			nextL.Text = "🎯 Nächstes Feature: " .. nxt
			fanFill.Parent.Visible = true
			cashFill.Parent.Visible = true
			setBar(fanFill, fanTxt, fans.Value, player:GetAttribute("NextFans") or 0, "Fans")
			setBar(cashFill, cashTxt, geld.Value, player:GetAttribute("NextCost") or 0, "Geld")
		else
			nextL.Text = "👑 Du hast alle gefeatured!"
			fanFill.Parent.Visible = false
			cashFill.Parent.Visible = false
		end
		if player:GetAttribute("MegaPending") then
			megaL.Text = "⭐ MEGA-FEATURE wartet im Studio!"
		else
			megaL.Text = "⭐ Mega-Feature in " .. clock(player:GetAttribute("MegaIn"))
		end
		local boost = player:GetAttribute("BoostLeft") or 0
		boostL.Visible = boost > 0
		boostL.Text = "🚀 x2-Boost aktiv: " .. clock(boost)
		local albums = player:GetAttribute("Albums") or 0
		if player:GetAttribute("CanRebirth") then
			albumL.Text = "💿 NEUES ALBUM bereit (Presswerk am Spawn)!"
		else
			albumL.Text = string.format("💿 %d Alben (+%d%%)", albums, albums * 50)
		end
		task.wait(0.25)
	end
end)

------------------------------------------------------------------
-- TOASTS
------------------------------------------------------------------
local toastHolder = Instance.new("Frame")
toastHolder.AnchorPoint = Vector2.new(0.5, 0)
toastHolder.Size = UDim2.new(0, 480, 0, 240)
toastHolder.Position = UDim2.new(0.5, 0, 0, 10)
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
	local color = KIND_COLORS[kind] or KIND_COLORS.info
	local f = Instance.new("TextLabel")
	f.LayoutOrder = toastCount
	f.Size = UDim2.new(1, 0, 0, 0)
	f.AutomaticSize = Enum.AutomaticSize.Y
	f.BackgroundColor3 = BG
	f.BackgroundTransparency = 0.08
	f.TextColor3 = color
	f.Font = Enum.Font.GothamBold
	f.TextSize = 18
	f.TextWrapped = true
	f.Text = text
	f.Parent = toastHolder
	corner(f, 10)
	local s = stroke(f, color, 2)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, 12)
	p.PaddingRight = UDim.new(0, 12)
	p.PaddingTop = UDim.new(0, 8)
	p.PaddingBottom = UDim.new(0, 8)
	p.Parent = f

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

	task.delay(4, function()
		if f.Parent then
			local tw = TweenService:Create(f, TweenInfo.new(0.4), {TextTransparency = 1, BackgroundTransparency = 1})
			TweenService:Create(s, TweenInfo.new(0.4), {Transparency = 1}):Play()
			tw:Play()
			tw.Completed:Wait()
			f:Destroy()
		end
	end)
end

------------------------------------------------------------------
-- BANNER
------------------------------------------------------------------
local currentBanner
local function showBanner(bigText, smallText, color)
	if currentBanner then
		currentBanner:Destroy()
	end
	color = color or GOLD
	local banner = Instance.new("Frame")
	banner.AnchorPoint = Vector2.new(0.5, 0.5)
	banner.Position = UDim2.fromScale(0.5, 0.38)
	banner.Size = UDim2.fromOffset(0, 0)
	banner.BackgroundColor3 = BG
	banner.BackgroundTransparency = 0.04
	banner.ClipsDescendants = true
	banner.Parent = gui
	currentBanner = banner
	corner(banner, 18)
	local s = stroke(banner, color, 3)
	gradient(s, color, Color3.new(1, 1, 1), 0)

	local big = Instance.new("TextLabel")
	big.Size = UDim2.new(1, -24, 0.58, 0)
	big.Position = UDim2.fromOffset(12, 6)
	big.BackgroundTransparency = 1
	big.Font = Enum.Font.GothamBlack
	big.TextScaled = true
	big.TextColor3 = color
	big.TextStrokeTransparency = 0.5
	big.Text = bigText
	big.Parent = banner

	local small = Instance.new("TextLabel")
	small.Size = UDim2.new(1, -24, 0.34, 0)
	small.Position = UDim2.new(0, 12, 0.6, 0)
	small.BackgroundTransparency = 1
	small.Font = Enum.Font.GothamBold
	small.TextScaled = true
	small.TextColor3 = Color3.new(1, 1, 1)
	small.Text = smallText
	small.Parent = banner

	TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Size = UDim2.fromOffset(600, 140)}):Play()
	task.delay(4.5, function()
		if not banner.Parent then return end
		local tw = TweenService:Create(banner, TweenInfo.new(0.3), {Size = UDim2.fromOffset(0, 0)})
		tw:Play()
		tw.Completed:Wait()
		banner:Destroy()
		if currentBanner == banner then
			currentBanner = nil
		end
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
		showBanner("⭐ SUPERSTAR IM STUDIO ⭐", data.name .. " (" .. data.genre .. ") wartet auf der Bühne – folge dem Strahl!", Color3.fromRGB(255, 120, 255))
	elseif kind == "album" then
		showBanner("💿 ALBUM NR. " .. data.albums .. " IST DRAUSSEN 💿", "Neustart mit +" .. data.bonus .. "% Einkommen für immer!", Color3.fromRGB(160, 200, 255))
	elseif kind == "mega" then
		showBanner("💥 MEGA-FEATURE MIT " .. string.upper(data.name) .. " 💥",
			string.format("+$%s  •  +%s Fans  •  x%d-Boost für %d Min", fmt(data.cash), fmt(data.fans), data.boostMult, data.boostMin),
			Color3.fromRGB(255, 120, 255))
	end
end)

------------------------------------------------------------------
-- MAP-OBJEKTE: Tänze, Sprechblasen, Drehen, Pulsieren
------------------------------------------------------------------
local dancers = {}
local spinners = {}
local pulsers = {}
local musikerStands = {} -- [index] = MikroStaender
local musikerStatus = {} -- [index] = TextLabel

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
	bb.StudsOffset = Vector3.new(0, 11, 0)
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

local function registerDancer(model)
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
		registerDancer(inst)
	elseif inst:IsA("BasePart") then
		local spin = inst:GetAttribute("Spin")
		if spin then
			spinners[inst] = {base = inst.CFrame, speed = spin}
		end
		local pulse = inst:GetAttribute("Pulse")
		if pulse then
			pulsers[inst] = {color = inst.Color, speed = pulse, phase = math.random() * 6}
		end
		local idx = inst:GetAttribute("MusikerIndex")
		if idx and inst.Name == "MikroStaender" then
			musikerStands[idx] = inst
		end
	elseif inst:IsA("TextLabel") and inst.Name == "Status" then
		local m = inst:FindFirstAncestorWhichIsA("Model")
		while m and not m:GetAttribute("MusikerIndex") do
			m = m:FindFirstAncestorWhichIsA("Model")
		end
		if m then
			musikerStatus[m:GetAttribute("MusikerIndex")] = inst
		end
	end
end

local map
task.spawn(function()
	map = workspace:WaitForChild("MusikTycoonMap")
	for _, inst in ipairs(map:GetDescendants()) do
		scan(inst)
	end
	map.DescendantAdded:Connect(scan)
end)

RunService.RenderStepped:Connect(function()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local rootPos = root and root.Position
	local t = os.clock()

	for model, info in pairs(dancers) do
		if not model.Parent then
			if info.bubble then info.bubble:Destroy() end
			dancers[model] = nil
		else
			local dist = rootPos and (rootPos - info.base.Position).Magnitude or 0
			if dist < 220 then
				model:PivotTo(info.base * info.dance(t + info.phase))
			end
			if info.bubble then
				info.bubble.Enabled = rootPos ~= nil and dist < 40
			end
		end
	end

	for part, info in pairs(spinners) do
		if not part.Parent then
			spinners[part] = nil
		elseif not rootPos or (rootPos - info.base.Position).Magnitude < 250 then
			local pos = info.base.Position
			part.CFrame = CFrame.new(pos) * CFrame.Angles(0, t * info.speed, 0) * (info.base - pos)
		end
	end

	for part, info in pairs(pulsers) do
		if not part.Parent then
			pulsers[part] = nil
		elseif not rootPos or (rootPos - part.Position).Magnitude < 250 then
			local k = 0.55 + 0.45 * math.abs(math.sin(t * info.speed + info.phase))
			local c = info.color
			part.Color = Color3.new(c.R * k, c.G * k, c.B * k)
		end
	end
end)

------------------------------------------------------------------
-- MUSIKER-STATUS + WEGWEISER-STRAHL
------------------------------------------------------------------
local guideAttachTarget -- wird bei jedem Zielwechsel neu erstellt (Ziel kann zerstört werden)
local guideTargetPart
local guideAttachRoot
local guideBeam

local function ensureBeam()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	if not guideAttachRoot or guideAttachRoot.Parent ~= root then
		guideAttachRoot = Instance.new("Attachment")
		guideAttachRoot.Name = "WegweiserStart"
		guideAttachRoot.Position = Vector3.new(0, -1.5, 0)
		guideAttachRoot.Parent = root
		if guideBeam then guideBeam:Destroy() end
		guideBeam = Instance.new("Beam")
		guideBeam.Attachment0 = guideAttachRoot
		guideBeam.Attachment1 = guideAttachTarget
		guideBeam.Enabled = false
		guideBeam.FaceCamera = true
		guideBeam.Width0 = 0.6
		guideBeam.Width1 = 0.6
		guideBeam.LightEmission = 1
		guideBeam.Segments = 20
		guideBeam.CurveSize0 = 8
		guideBeam.CurveSize1 = -8
		guideBeam.Color = ColorSequence.new(GOLD, PINK)
		guideBeam.Transparency = NumberSequence.new(0.2)
		guideBeam.TextureSpeed = 1
		guideBeam.Parent = root
	end
	return guideBeam
end

local function findMegaMic()
	local idx = player:GetAttribute("PlotIndex") or 0
	if idx == 0 or not map then return nil end
	local studio = map:FindFirstChild("Studio_" .. idx)
	local mega = studio and studio:FindFirstChild("MegaFeature")
	return mega and mega:FindFirstChild("MegaMikro")
end

local function findPresswerk()
	local f = map and map:FindFirstChild("AlbumPresswerk")
	return f and f:FindFirstChild("Presswerk")
end

task.spawn(function()
	while gui.Parent do
		local features = player:GetAttribute("Features") or 0
		local nextFans = player:GetAttribute("NextFans") or 0
		local nextCost = player:GetAttribute("NextCost") or 0
		local haveFans = fans and fans.Value or 0
		local haveCash = geld and geld.Value or 0

		for i, label in pairs(musikerStatus) do
			if i <= features then
				label.Text = "✅ GEFEATURED"
				label.TextColor3 = Color3.fromRGB(90, 230, 120)
			elseif i == features + 1 then
				if haveFans >= nextFans and haveCash >= nextCost then
					label.Text = "🎯 JETZT FEATUREN!"
					label.TextColor3 = GOLD
				else
					label.Text = "🎯 ALS NÄCHSTES"
					label.TextColor3 = CYAN
				end
			else
				label.Text = "🔒"
				label.TextColor3 = Color3.fromRGB(170, 170, 180)
			end
		end

		-- Ziel für den Strahl: Mega-Feature > Album > bezahlbares Feature
		local target
		if player:GetAttribute("MegaPending") then
			target = findMegaMic()
		end
		if not target and player:GetAttribute("CanRebirth") then
			target = findPresswerk()
		end
		if not target and haveFans >= nextFans and haveCash >= nextCost then
			target = musikerStands[features + 1]
		end

		local beam = ensureBeam()
		if beam then
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local near = target and root and (root.Position - target.Position).Magnitude < 14
			if target and not near then
				if target ~= guideTargetPart or not guideAttachTarget or not guideAttachTarget.Parent then
					if guideAttachTarget then guideAttachTarget:Destroy() end
					guideAttachTarget = Instance.new("Attachment")
					guideAttachTarget.Name = "WegweiserZiel"
					guideAttachTarget.Parent = target
					guideTargetPart = target
				end
				beam.Attachment1 = guideAttachTarget
				beam.Enabled = true
			else
				beam.Enabled = false
			end
		end
		task.wait(0.4)
	end
end)
