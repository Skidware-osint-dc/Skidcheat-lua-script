-- Check for table that is shared between executions.
if not shared then
	return warn("No shared, no script.")
end

-- Module table.
local Skidcheat = {}

-- Services.
local playersService = game:GetService("Players")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local workspaceService = game:GetService("Workspace")
local lightingService = game:GetService("Lighting")
local tweenService = game:GetService("TweenService")
local teleportService = game:GetService("TeleportService")
local debrisService = game:GetService("Debris")

-- Constants.
local ACCENT_COLOR = Color3.fromRGB(150, 115, 255)
local BG_DARK = Color3.fromRGB(10, 10, 13)
local BG_PANEL = Color3.fromRGB(18, 18, 23)
local BG_ELEMENT = Color3.fromRGB(26, 26, 33)
local BG_ELEMENT_HOVER = Color3.fromRGB(36, 36, 45)
local TEXT_DIM = Color3.fromRGB(170, 170, 180)
local IS_MOBILE = userInputService.TouchEnabled and not userInputService.KeyboardEnabled

local R15_BONES = {
	{ "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}
local R6_BONES = {
	{ "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
	{ "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}
local GAME_IDS = { MM2 = 142823291, NaturalDisaster = 189707, Bloxspin = 13772394625, PrisonLife = 155615604 }
local NOCLIP_EXCEPT_MATERIALS = { [Enum.Material.Water] = true }

-- State.
local localPlayer = playersService.LocalPlayer
local currentCamera = workspaceService.CurrentCamera

Skidcheat.connections = {}
Skidcheat.espObjects = {}
Skidcheat.drawings = {}
Skidcheat.silentPart = nil
Skidcheat.lockedTarget = nil
Skidcheat.lastShot = 0
Skidcheat.lastTrigger = 0
Skidcheat.gui = nil
Skidcheat.hooked = false
Skidcheat.flyVelocity = nil
Skidcheat.flyGyro = nil
Skidcheat.noclipParts = {}
Skidcheat.originalLighting = nil
Skidcheat.shaderInstances = {}
Skidcheat.spinAngle = 0
Skidcheat.flingTargets = {}
Skidcheat.flingOldCFrame = nil
Skidcheat.flingRunning = false
Skidcheat.lastSafeCFrame = nil
Skidcheat.lastIncomingVelocity = Vector3.new()
Skidcheat.shaderState = { smoothGlare = 0, prevLookVec = Vector3.new(0, 0, -1), snowAccumulator = 0, fxFolder = nil }

Skidcheat.config = {
	aimbot = {
		enabled = false, holdToAim = not IS_MOBILE, teamCheck = true, wallCheck = true,
		fov = 150, smoothing = 6, prediction = 0.1, part = "Head", showFov = true,
		fovLock = false, lockBreakDistance = 250, aimAxis = "Both", fovAnchor = "Center",
		targetPriority = "Closest", ignoreKnocked = true,
	},
	silent = {
		enabled = false, hitChance = 100, part = "Head", teamCheck = true, wallCheck = false,
		fov = 220, prediction = 0.12, hitboxExpand = 0, fovAnchor = "Center",
	},
	trigger = {
		enabled = false, teamCheck = true, wallCheck = true, part = "Head",
		fov = 40, delayMin = 0.02, delayMax = 0.08, requireAim = true, fovAnchor = "Center",
	},
	rage = {
		enabled = false, autoFire = true, teamCheck = true, wallCheck = false,
		fireDelay = 0.08, prediction = 0.12, part = "Head", hitChance = 100, switchDelay = 0.15,
	},
	spin = { enabled = false, speed = 12, radius = 0, axis = "Y", randomize = false, bodyFreeze = false },
	esp = {
		enabled = false, box = true, cornerBox = false, skeleton = false, tracer = false,
		outline = false, chams = false, names = true, health = true, distance = true, weapon = false,
		teamCheck = false, maxDistance = 2000, tracerOrigin = "Bottom",
		boxColor = Color3.fromRGB(255, 255, 255), skeletonColor = Color3.fromRGB(0, 255, 140),
		tracerColor = Color3.fromRGB(255, 255, 255), chamColor = Color3.fromRGB(255, 60, 60),
		offscreenArrows = false, viewAngle = false, snapLines = false,
	},
	shaders = {
		dynamicTime = false, timeSpeed = 25, clockTime = 14, latitude = 41,
		atmoEnabled = false, atmoDensity = 0.3, atmoHaze = 1, atmoGlare = 1,
		rigEnabled = false, rigAttach = "Camera", rigDistance = 10,
		keyBrightness = 3, fillBrightness = 1.5, rimBrightness = 2,
		bloomEnabled = false, bloomIntensity = 1, bloomSize = 24, bloomThreshold = 2,
		sunRaysEnabled = false, sunRaysIntensity = 0.3, sunRaysSpread = 1,
		lensFlare = false, lensFlareIntensity = 1,
		dofEnabled = false, dofAutoFocus = true, dofFar = 10, dofNear = 0, dofDist = 85,
		colorCorrection = false, ccBrightness = 0, ccSaturation = 0, ccContrast = 0, ccTint = Color3.new(1, 1, 1),
		motionBlur = false, motionBlurStrength = 1, vignette = false, vignetteOpacity = 0.4,
		weather = "Clear", shinySurfaces = false,
	},
	misc = {
		speed = false, speedValue = 32, infJump = false, jumpPower = 50,
		noclip = false, noclipWhitelistOnly = false, noclipKey = Enum.KeyCode.N,
		fly = false, flySpeed = 60, flyVerticalSpeed = 60, flyCameraRelative = true, flyNoCollide = true,
		antiAfk = false,
		fling = { enabled = false, mode = "VelocitySpam", power = 9e7, autoReturn = true, allPlayers = false },
		antiFling = { enabled = false, velocityThreshold = 180, action = "Zero" },
		antiVoid = { enabled = false, voidY = -250, teleportDelay = 0.1 },
	},
	games = {
		mm2AutoDodge = false, mm2MurdererEsp = true, mm2SheriffEsp = true,
		ndSafeZoneEsp = false, ndAutoRun = false,
		bloxspinAutoSpin = false, bloxspinBetAmount = 10,
		plEspWanted = false, plAutoCuff = false,
	},
}

---Create an instance with properties.
---@param className string
---@param properties table
---@param parent Instance?
---@return Instance
local function create(className, properties, parent)
	local instance = Instance.new(className)
	for key, value in pairs(properties) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

---Track a connection for cleanup.
---@param connection RBXScriptConnection
local function track(connection)
	table.insert(Skidcheat.connections, connection)
end

---Track a drawing for cleanup.
---@param drawing table
---@return table
local function trackDrawing(drawing)
	table.insert(Skidcheat.drawings, drawing)
	return drawing
end

---True for any input that counts as a press, mouse or touch.
---@param input InputObject
---@return boolean
local function isPressInput(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

---Resolve the FOV anchor point in screen space. Defaults to screen center so taps and
---drags never move the circle or the target search point.
---@param anchor string
---@return Vector2
local function getFovAnchor(anchor)
	if anchor == "Mouse" and not IS_MOBILE then
		return userInputService:GetMouseLocation()
	end
	local size = currentCamera.ViewportSize
	return Vector2.new(size.X / 2, size.Y / 2)
end

---Get the local character's humanoid and root part.
---@return Model?, Humanoid?, BasePart?
local function getLocalCharacter()
	local character = localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = humanoid and humanoid.RootPart
	return character, humanoid, root
end

---Get a character's aim part, falling back to the root part.
---@param character Model
---@param partName string
---@return BasePart?
local function getAimPart(character, partName)
	return character:FindFirstChild(partName) or character:FindFirstChild("HumanoidRootPart")
end

---Check whether a part has a clear line from the camera.
---@param part BasePart
---@param character Model
---@return boolean
local function isVisible(part, character)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { localPlayer.Character, currentCamera }
	local origin = currentCamera.CFrame.Position
	local result = workspaceService:Raycast(origin, part.Position - origin, params)
	return result == nil or result.Instance:IsDescendantOf(character)
end

---True if a humanoid is ragdolled or in freefall physics, used to skip dead/knocked bodies.
---@param humanoid Humanoid
---@return boolean
local function isKnocked(humanoid)
	return humanoid:GetState() == Enum.HumanoidStateType.Ragdoll
		or humanoid:GetState() == Enum.HumanoidStateType.Physics
end

---Find the best target for a given set of settings.
---@param settings table
---@param useFov boolean
---@return Player?, BasePart?
local function getTarget(settings, useFov)
	local bestPlayer, bestPart, bestScore = nil, nil, math.huge
	local anchor = getFovAnchor(settings.fovAnchor or "Center")

	for _, player in ipairs(playersService:GetPlayers()) do
		if player == localPlayer then continue end
		if settings.teamCheck and player.Team == localPlayer.Team and player.Team ~= nil then continue end

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then continue end
		if settings.ignoreKnocked and isKnocked(humanoid) then continue end

		local part = getAimPart(character, settings.part)
		if not part then continue end

		local screenPos, onScreen = currentCamera:WorldToViewportPoint(part.Position)
		local distance = (Vector2.new(screenPos.X, screenPos.Y) - anchor).Magnitude

		if useFov then
			if not onScreen or distance > settings.fov then continue end
		else
			distance = (part.Position - currentCamera.CFrame.Position).Magnitude
		end

		if settings.wallCheck and not isVisible(part, character) then continue end

		local score = distance
		if settings.targetPriority == "LowestHealth" then
			score = humanoid.Health
		end

		if score < bestScore then
			bestPlayer, bestPart, bestScore = player, part, score
		end
	end

	return bestPlayer, bestPart
end

---Resolve FOV-lock target, sticking to the current one until it breaks lock conditions.
---@param settings table
---@return Player?, BasePart?
local function getLockedTarget(settings)
	if settings.fovLock and Skidcheat.lockedTarget then
		local player = Skidcheat.lockedTarget
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local part = character and getAimPart(character, settings.part)

		if humanoid and humanoid.Health > 0 and part then
			local screenPos, onScreen = currentCamera:WorldToViewportPoint(part.Position)
			local anchor = getFovAnchor(settings.fovAnchor or "Center")
			local dist = (Vector2.new(screenPos.X, screenPos.Y) - anchor).Magnitude

			if onScreen and dist <= settings.lockBreakDistance and (not settings.wallCheck or isVisible(part, character)) then
				return player, part
			end
		end
		Skidcheat.lockedTarget = nil
	end

	local player, part = getTarget(settings, true)
	if settings.fovLock then
		Skidcheat.lockedTarget = player
	end
	return player, part
end

---Predict where a part will be.
---@param part BasePart
---@param prediction number
---@return Vector3
local function predictPosition(part, prediction)
	return part.Position + part.AssemblyLinearVelocity * prediction
end

---Blend the camera toward a target position, optionally restricted to one axis.
---@param goalPosition Vector3
---@param smoothing number
---@param axis string
local function applyAim(goalPosition, smoothing, axis)
	local current = currentCamera.CFrame
	local goal = CFrame.new(current.Position, goalPosition)

	if axis == "Yaw" then
		local _, goalY = goal:ToOrientation()
		local currentX, _, currentZ = current:ToOrientation()
		goal = CFrame.new(current.Position) * CFrame.fromOrientation(currentX, goalY, currentZ)
	elseif axis == "Pitch" then
		local goalX = select(1, goal:ToOrientation())
		local _, currentY, currentZ = current:ToOrientation()
		goal = CFrame.new(current.Position) * CFrame.fromOrientation(goalX, currentY, currentZ)
	end

	currentCamera.CFrame = current:Lerp(goal, 1 / math.max(smoothing, 1))
end

---Update aimbot, FOV lock, silent aim, triggerbot and ragebot each frame.
---@param fovCircle table
local function updateAim(fovCircle)
	local aimbot = Skidcheat.config.aimbot
	local silent = Skidcheat.config.silent
	local trigger = Skidcheat.config.trigger
	local rage = Skidcheat.config.rage

	fovCircle.Visible = aimbot.enabled and aimbot.showFov
	fovCircle.Radius = aimbot.fov
	fovCircle.Position = getFovAnchor(aimbot.fovAnchor)

	Skidcheat.silentPart = nil
	if silent.enabled then
		local _, part = getTarget(silent, true)
		Skidcheat.silentPart = part
	end

	if trigger.enabled then
		local aiming = not trigger.requireAim or userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
		if aiming then
			local _, part = getTarget(trigger, true)
			local now = os.clock()
			local delay = trigger.delayMin + (trigger.delayMax - trigger.delayMin) * math.random()
			if part and now - Skidcheat.lastTrigger >= delay then
				Skidcheat.lastTrigger = now
				mouse1click()
			end
		end
	end

	if rage.enabled then
		local _, part = getTarget(rage, false)
		if part then
			applyAim(predictPosition(part, rage.prediction), 1, "Both")
			if rage.autoFire and os.clock() - Skidcheat.lastShot >= rage.fireDelay then
				Skidcheat.lastShot = os.clock()
				if math.random(1, 100) <= rage.hitChance then
					mouse1click()
				end
			end
		end
		return
	end

	if not aimbot.enabled then return end
	local pressed = userInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	if aimbot.holdToAim and not pressed then
		Skidcheat.lockedTarget = nil
		return
	end

	local _, part = getLockedTarget(aimbot)
	if not part then return end
	applyAim(predictPosition(part, aimbot.prediction), aimbot.smoothing, aimbot.aimAxis)
end

---Spin the local character around its vertical or horizontal axis, optionally jittered.
local function updateSpinbot()
	local spin = Skidcheat.config.spin
	local _, _, root = getLocalCharacter()
	if not spin.enabled or not root then return end

	local speed = spin.speed
	if spin.randomize then
		speed = speed * (0.6 + math.random() * 0.8)
	end

	Skidcheat.spinAngle = (Skidcheat.spinAngle + speed) % 360
	local rotation = CFrame.fromAxisAngle(spin.axis == "Y" and Vector3.new(0, 1, 0) or Vector3.new(1, 0, 0), math.rad(Skidcheat.spinAngle))
	root.CFrame = CFrame.new(root.Position) * rotation * CFrame.new(0, 0, spin.radius)

	if spin.bodyFreeze then
		root.AssemblyLinearVelocity = Vector3.new()
	end
end

---Create every drawing/cham object for a player.
---@param player Player
---@return table
local function createEsp(player)
	local esp = {
		box = trackDrawing(Drawing.new("Square")), cornerLines = {},
		name = trackDrawing(Drawing.new("Text")), weapon = trackDrawing(Drawing.new("Text")),
		distanceLabel = trackDrawing(Drawing.new("Text")), health = trackDrawing(Drawing.new("Line")),
		tracer = trackDrawing(Drawing.new("Line")), outline = trackDrawing(Drawing.new("Square")),
		arrow = trackDrawing(Drawing.new("Triangle")), skeleton = {}, highlight = nil,
	}

	for i = 1, 4 do
		esp.cornerLines[i] = trackDrawing(Drawing.new("Line"))
		esp.cornerLines[i].Thickness = 2
	end
	for i = 1, #R15_BONES do
		esp.skeleton[i] = trackDrawing(Drawing.new("Line"))
		esp.skeleton[i].Thickness = 1
	end

	esp.box.Thickness = 1
	esp.box.Filled = false
	esp.outline.Thickness = 3
	esp.outline.Filled = false
	esp.outline.Color = Color3.new(0, 0, 0)
	esp.name.Size = 13
	esp.name.Center = true
	esp.name.Outline = true
	esp.weapon.Size = 12
	esp.weapon.Center = true
	esp.weapon.Outline = true
	esp.weapon.Color = Color3.fromRGB(255, 220, 100)
	esp.distanceLabel.Size = 12
	esp.distanceLabel.Center = true
	esp.distanceLabel.Outline = true
	esp.health.Thickness = 2
	esp.tracer.Thickness = 1
	esp.arrow.Filled = true
	esp.arrow.Color = Color3.fromRGB(255, 60, 60)
	esp.highlight = create("Highlight", { FillTransparency = 1, OutlineTransparency = 1, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }, nil)

	Skidcheat.espObjects[player] = esp
	return esp
end

---Hide every visible piece of a player's ESP.
---@param esp table
local function hideEsp(esp)
	esp.box.Visible = false
	esp.outline.Visible = false
	esp.name.Visible = false
	esp.weapon.Visible = false
	esp.distanceLabel.Visible = false
	esp.health.Visible = false
	esp.tracer.Visible = false
	esp.arrow.Visible = false
	for _, line in ipairs(esp.cornerLines) do line.Visible = false end
	for _, line in ipairs(esp.skeleton) do line.Visible = false end
	esp.highlight.FillTransparency = 1
	esp.highlight.OutlineTransparency = 1
	esp.highlight.Parent = nil
end

---Remove ESP drawings and the highlight for a player.
---@param player Player
local function removeEsp(player)
	local esp = Skidcheat.espObjects[player]
	if not esp then return end
	for _, drawing in ipairs(esp.cornerLines) do pcall(function() drawing:Remove() end) end
	for _, drawing in ipairs(esp.skeleton) do pcall(function() drawing:Remove() end) end
	for key, drawing in pairs(esp) do
		if key ~= "cornerLines" and key ~= "skeleton" and key ~= "highlight" then
			pcall(function() drawing:Remove() end)
		end
	end
	esp.highlight:Destroy()
	Skidcheat.espObjects[player] = nil
end

---Draw the skeleton lines for a character.
---@param esp table
---@param character Model
local function drawSkeleton(esp, character)
	local bones = character:FindFirstChild("UpperTorso") and R15_BONES or R6_BONES
	for i = 1, #esp.skeleton do
		local pair = bones[i]
		local line = esp.skeleton[i]
		if not pair then line.Visible = false; continue end
		local partA = character:FindFirstChild(pair[1])
		local partB = character:FindFirstChild(pair[2])
		if not partA or not partB then line.Visible = false; continue end
		local posA, onA = currentCamera:WorldToViewportPoint(partA.Position)
		local posB, onB = currentCamera:WorldToViewportPoint(partB.Position)
		line.Visible = onA and onB
		line.From = Vector2.new(posA.X, posA.Y)
		line.To = Vector2.new(posB.X, posB.Y)
		line.Color = Skidcheat.config.esp.skeletonColor
	end
end

---Draw an off-screen direction arrow toward a target.
---@param esp table
---@param rootPosition Vector3
local function drawOffscreenArrow(esp, rootPosition)
	local screenSize = currentCamera.ViewportSize
	local center = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
	local toTarget = currentCamera.CFrame:PointToObjectSpace(rootPosition)
	if toTarget.Z > 0 then
		toTarget = Vector3.new(-toTarget.X, toTarget.Y, toTarget.Z)
	end
	local direction = Vector2.new(toTarget.X, -toTarget.Y)
	if direction.Magnitude < 1e-3 then direction = Vector2.new(0, -1) end
	direction = direction.Unit
	local radius = math.min(screenSize.X, screenSize.Y) / 2 - 40
	local tip = center + direction * radius
	local back = direction * -14
	local side = Vector2.new(-direction.Y, direction.X) * 8
	esp.arrow.Visible = true
	esp.arrow.PointA = tip
	esp.arrow.PointB = tip + back + side
	esp.arrow.PointC = tip + back - side
end

---Update ESP, tracers and chams for every player.
local function updateEsp()
	local esp = Skidcheat.config.esp
	local screenSize = currentCamera.ViewportSize

	for _, player in ipairs(playersService:GetPlayers()) do
		if player == localPlayer then continue end
		local espObjects = Skidcheat.espObjects[player] or createEsp(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		if not esp.enabled or not root or not humanoid or humanoid.Health <= 0 then hideEsp(espObjects); continue end
		if esp.teamCheck and player.Team == localPlayer.Team then hideEsp(espObjects); continue end

		local distance = (root.Position - currentCamera.CFrame.Position).Magnitude
		local rootScreen, onScreen = currentCamera:WorldToViewportPoint(root.Position)
		if distance > esp.maxDistance then hideEsp(espObjects); continue end

		if not onScreen then
			hideEsp(espObjects)
			if esp.offscreenArrows then drawOffscreenArrow(espObjects, root.Position) end
			continue
		end
		espObjects.arrow.Visible = false

		local top = currentCamera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
		local bottom = currentCamera:WorldToViewportPoint(root.Position - Vector3.new(0, 3.5, 0))
		local height = math.abs(bottom.Y - top.Y)
		local width = height / 1.8
		local healthRatio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
		local boxPosition = Vector2.new(rootScreen.X - width / 2, top.Y)
		local boxSize = Vector2.new(width, height)

		espObjects.box.Visible = esp.box and not esp.cornerBox
		espObjects.box.Color = esp.boxColor
		espObjects.box.Position = boxPosition
		espObjects.box.Size = boxSize
		espObjects.outline.Visible = esp.box and esp.outline and not esp.cornerBox
		espObjects.outline.Position = boxPosition
		espObjects.outline.Size = boxSize

		local cornerLen = math.min(width, height) * 0.25
		for _, line in ipairs(espObjects.cornerLines) do
			line.Visible = esp.box and esp.cornerBox
			line.Color = esp.boxColor
		end
		if esp.box and esp.cornerBox then
			local x1, y1, x2, y2 = boxPosition.X, boxPosition.Y, boxPosition.X + width, boxPosition.Y + height
			espObjects.cornerLines[1].From, espObjects.cornerLines[1].To = Vector2.new(x1, y1), Vector2.new(x1 + cornerLen, y1)
			espObjects.cornerLines[2].From, espObjects.cornerLines[2].To = Vector2.new(x2, y1), Vector2.new(x2 - cornerLen, y1)
			espObjects.cornerLines[3].From, espObjects.cornerLines[3].To = Vector2.new(x1, y2), Vector2.new(x1 + cornerLen, y2)
			espObjects.cornerLines[4].From, espObjects.cornerLines[4].To = Vector2.new(x2, y2), Vector2.new(x2 - cornerLen, y2)
		end

		if esp.skeleton then drawSkeleton(espObjects, character) else
			for _, line in ipairs(espObjects.skeleton) do line.Visible = false end
		end

		if esp.snapLines then
			espObjects.tracer.Visible = true
			espObjects.tracer.From = Vector2.new(screenSize.X / 2, 0)
		else
			espObjects.tracer.Visible = esp.tracer
			espObjects.tracer.From = esp.tracerOrigin == "Mouse" and userInputService:GetMouseLocation() or Vector2.new(screenSize.X / 2, screenSize.Y)
		end
		espObjects.tracer.Color = esp.tracerColor
		espObjects.tracer.To = Vector2.new(rootScreen.X, rootScreen.Y)

		espObjects.name.Visible = esp.names
		espObjects.name.Text = esp.viewAngle and string.format("%s | %d°", player.DisplayName, math.deg(math.atan2(root.CFrame.LookVector.X, root.CFrame.LookVector.Z))) or player.DisplayName
		espObjects.name.Position = Vector2.new(rootScreen.X, top.Y - 16)

		local tool = character:FindFirstChildOfClass("Tool")
		espObjects.weapon.Visible = esp.weapon and tool ~= nil
		if tool then
			espObjects.weapon.Text = tool.Name
			espObjects.weapon.Position = Vector2.new(rootScreen.X, top.Y - 30)
		end

		espObjects.distanceLabel.Visible = esp.distance
		espObjects.distanceLabel.Text = string.format("[%dm]", distance)
		espObjects.distanceLabel.Position = Vector2.new(rootScreen.X, bottom.Y + 4)

		espObjects.health.Visible = esp.health
		espObjects.health.Color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), healthRatio)
		espObjects.health.From = Vector2.new(boxPosition.X - 4, top.Y + height)
		espObjects.health.To = Vector2.new(boxPosition.X - 4, top.Y + height - height * healthRatio)

		if esp.chams then
			espObjects.highlight.Parent = character
			espObjects.highlight.FillColor = esp.chamColor
			espObjects.highlight.OutlineColor = esp.chamColor
			espObjects.highlight.FillTransparency = 0.6
			espObjects.highlight.OutlineTransparency = 0
		else
			espObjects.highlight.Parent = nil
		end
	end
end

---Apply fly velocity using camera direction and move input.
local function updateFly()
	local character, humanoid, root = getLocalCharacter()
	local misc = Skidcheat.config.misc

	if not misc.fly or not root or not humanoid then
		if Skidcheat.flyVelocity then
			Skidcheat.flyVelocity:Destroy()
			Skidcheat.flyVelocity = nil
		end
		if Skidcheat.flyGyro then
			Skidcheat.flyGyro:Destroy()
			Skidcheat.flyGyro = nil
		end
		if humanoid then humanoid.PlatformStand = false end
		return
	end

	if not Skidcheat.flyVelocity then
		Skidcheat.flyVelocity = create("BodyVelocity", { MaxForce = Vector3.new(1e9, 1e9, 1e9), Velocity = Vector3.new() }, root)
		Skidcheat.flyGyro = create("BodyGyro", { MaxTorque = Vector3.new(1e9, 1e9, 1e9), D = 50 }, root)
		humanoid.PlatformStand = true
		if misc.flyNoCollide then
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end
	end

	local moveVector = humanoid.MoveDirection
	local vertical = 0
	if userInputService:IsKeyDown(Enum.KeyCode.Space) then vertical = 1
	elseif userInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vertical = -1 end
	if Skidcheat.mobileFlyState then vertical = Skidcheat.mobileFlyState() end

	local direction
	if misc.flyCameraRelative then
		local lookVector = currentCamera.CFrame.LookVector
		direction = moveVector.Magnitude > 0 and (lookVector * moveVector:Dot(currentCamera.CFrame.LookVector) + currentCamera.CFrame.RightVector * moveVector:Dot(currentCamera.CFrame.RightVector)) or Vector3.new()
	else
		direction = moveVector
	end

	Skidcheat.flyVelocity.Velocity = direction.Unit * (direction.Magnitude > 0 and misc.flySpeed or 0) + Vector3.new(0, vertical * misc.flyVerticalSpeed, 0)
	Skidcheat.flyGyro.CFrame = currentCamera.CFrame
end

---Apply movement features: walkspeed, infinite jump power, and fly.
local function updateMisc()
	local misc = Skidcheat.config.misc
	local _, humanoid = getLocalCharacter()
	if not humanoid then return end

	if misc.speed then humanoid.WalkSpeed = misc.speedValue end
	if misc.infJump then humanoid.JumpPower = misc.jumpPower end
	updateFly()
end

---Toggle collisions for noclip and remember which parts were changed, honoring the
---material whitelist exception list and an optional whitelist-only mode.
local function updateNoclip()
	local character = localPlayer.Character
	if not character then return end
	local misc = Skidcheat.config.misc

	if not misc.noclip then
		for part in pairs(Skidcheat.noclipParts) do
			if part.Parent then part.CanCollide = true end
		end
		table.clear(Skidcheat.noclipParts)
		return
	end

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.CanCollide then
			if misc.noclipWhitelistOnly and not NOCLIP_EXCEPT_MATERIALS[part.Material] then continue end
			part.CanCollide = false
			Skidcheat.noclipParts[part] = true
		end
	end
end

---Nudge an anchor so the client stays reported as active.
local function updateAntiAfk()
	if not Skidcheat.config.misc.antiAfk then return end
	userInputService:GetMouseLocation()
end

---Fling a single target once per call, alternating teleport-and-velocity-spam offsets.
---@param targetPlayer Player
local function flingCharacterOnce(targetPlayer)
	local fling = Skidcheat.config.misc.fling
	local character, humanoid, root = getLocalCharacter()
	if not (character and humanoid and root) then return end

	local targetCharacter = targetPlayer.Character
	if not targetCharacter then return end
	local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	local targetRoot = targetHumanoid and targetHumanoid.RootPart
	local targetHead = targetCharacter:FindFirstChild("Head")
	if targetHumanoid and targetHumanoid.Sit then return end

	local anchorPart = targetRoot or targetHead
	if not anchorPart then return end

	if root.AssemblyLinearVelocity.Magnitude < 50 then
		Skidcheat.flingOldCFrame = root.CFrame
	end
	currentCamera.CameraSubject = targetHead or targetHumanoid

	local function slam(offsetCFrame, angleCFrame)
		local goal = CFrame.new(anchorPart.Position) * offsetCFrame * angleCFrame
		root.CFrame = goal
		character:PivotTo(goal)
		if fling.mode == "VelocitySpam" then
			root.AssemblyLinearVelocity = Vector3.new(fling.power, fling.power * 10, fling.power)
			root.AssemblyAngularVelocity = Vector3.new(fling.power * 10, fling.power * 10, fling.power * 10)
		end
	end

	local bodyVelocity = create("BodyVelocity", { Velocity = Vector3.new(), MaxForce = Vector3.new(9e9, 9e9, 9e9) }, root)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

	local startTime = os.clock()
	while os.clock() - startTime < 2 and fling.enabled do
		if targetRoot and targetRoot.AssemblyLinearVelocity.Magnitude >= 50 then
			slam(CFrame.new(0, 1.5, targetHumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
			task.wait()
			slam(CFrame.new(0, -1.5, -targetHumanoid.WalkSpeed), CFrame.new())
			task.wait()
		else
			local wobble = (os.clock() * 400) % 360
			local moveOffset = targetHumanoid and targetRoot and (targetHumanoid.MoveDirection * targetRoot.AssemblyLinearVelocity.Magnitude / 1.25) or Vector3.new()
			slam(CFrame.new(0, 1.5, 0) + moveOffset, CFrame.Angles(math.rad(wobble), 0, 0))
			task.wait()
			slam(CFrame.new(0, -1.5, 0) + moveOffset, CFrame.Angles(math.rad(wobble), 0, 0))
			task.wait()
		end
	end

	bodyVelocity:Destroy()
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
	currentCamera.CameraSubject = humanoid

	if fling.autoReturn and Skidcheat.flingOldCFrame then
		local recoverStart = os.clock()
		while os.clock() - recoverStart < 1 do
			local returnGoal = Skidcheat.flingOldCFrame * CFrame.new(0, 0.5, 0)
			root.CFrame = returnGoal
			character:PivotTo(returnGoal)
			for _, part in ipairs(character:GetChildren()) do
				if part:IsA("BasePart") then
					part.AssemblyLinearVelocity = Vector3.new()
					part.AssemblyAngularVelocity = Vector3.new()
				end
			end
			task.wait()
			if (root.Position - Skidcheat.flingOldCFrame.Position).Magnitude < 25 then break end
		end
	end
end

---Loop every selected fling target while the feature is enabled, one target at a time.
local function updateFling()
	local fling = Skidcheat.config.misc.fling
	if not fling.enabled or Skidcheat.flingRunning then return end

	Skidcheat.flingRunning = true
	task.spawn(function()
		while Skidcheat.config.misc.fling.enabled do
			for _, player in ipairs(playersService:GetPlayers()) do
				if not Skidcheat.config.misc.fling.enabled then break end
				local wantsTarget = fling.allPlayers and player ~= localPlayer or Skidcheat.flingTargets[player]
				if wantsTarget and player.Character then
					flingCharacterOnce(player)
				end
			end
			task.wait(0.1)
		end
		Skidcheat.flingRunning = false
	end)
end

---Record the local character's position as a safe recovery point whenever it is
---grounded and not already far below where it last stood.
local function updateSafePositionTracking()
	local _, humanoid, root = getLocalCharacter()
	if not humanoid or not root then return end
	if humanoid.FloorMaterial ~= Enum.Material.Air then
		Skidcheat.lastSafeCFrame = root.CFrame
	end
end

---Detect and counter incoming fling: a sudden large velocity spike on the local root
---part that did not come from our own fly/noclip/spin features.
local function updateAntiFling()
	local antiFling = Skidcheat.config.misc.antiFling
	if not antiFling.enabled then return end
	local _, humanoid, root = getLocalCharacter()
	if not root then return end

	local velocity = root.AssemblyLinearVelocity
	if velocity.Magnitude > antiFling.velocityThreshold and not Skidcheat.flyVelocity and not Skidcheat.config.spin.enabled then
		if antiFling.action == "Zero" then
			root.AssemblyLinearVelocity = Vector3.new()
			root.AssemblyAngularVelocity = Vector3.new()
		elseif antiFling.action == "Anchor" then
			root.Anchored = true
			task.delay(0.15, function()
				if root.Parent then root.Anchored = false end
			end)
		elseif antiFling.action == "Counter" and Skidcheat.lastSafeCFrame then
			root.CFrame = Skidcheat.lastSafeCFrame
			root.AssemblyLinearVelocity = Vector3.new()
			root.AssemblyAngularVelocity = Vector3.new()
		end
	end
end

---Detect falling toward the void and teleport back to the last known safe position.
local function updateAntiVoid()
	local antiVoid = Skidcheat.config.misc.antiVoid
	if not antiVoid.enabled then return end
	local _, _, root = getLocalCharacter()
	if not root then return end

	if root.Position.Y < antiVoid.voidY and Skidcheat.lastSafeCFrame then
		task.delay(antiVoid.teleportDelay, function()
			local _, _, currentRoot = getLocalCharacter()
			if currentRoot and currentRoot.Position.Y < antiVoid.voidY then
				currentRoot.CFrame = Skidcheat.lastSafeCFrame * CFrame.new(0, 3, 0)
				currentRoot.AssemblyLinearVelocity = Vector3.new()
			end
		end)
	end
end

---Lazily create every Lighting-effect instance the shader studio drives.
local function ensureShaderInstances()
	local s = Skidcheat.shaderInstances
	s.bloom = s.bloom or create("BloomEffect", { Enabled = false }, lightingService)
	s.sunRays = s.sunRays or create("SunRaysEffect", { Enabled = false }, lightingService)
	s.dof = s.dof or create("DepthOfFieldEffect", { Enabled = false }, lightingService)
	s.colorCorrection = s.colorCorrection or create("ColorCorrectionEffect", { Enabled = false }, lightingService)
	s.atmosphere = s.atmosphere or lightingService:FindFirstChildOfClass("Atmosphere") or create("Atmosphere", {}, lightingService)

	if not Skidcheat.shaderState.fxFolder then
		Skidcheat.shaderState.fxFolder = create("Folder", { Name = "SkidcheatFX" }, workspaceService)
	end

	if not s.keyLight then
		local function makeRigLight(name)
			local part = create("Part", { Name = name, Size = Vector3.new(1, 1, 1), Transparency = 1, CanCollide = false, CanQuery = false, Anchored = true }, Skidcheat.shaderState.fxFolder)
			create("PointLight", { Name = "Light", Range = 30 }, part)
			return part
		end
		s.keyLight = makeRigLight("Key")
		s.fillLight = makeRigLight("Fill")
		s.rimLight = makeRigLight("Rim")
	end

	s.vignetteStroke = s.vignetteStroke or (function()
		local vgui = create("ScreenGui", { Name = "SkidcheatVignette", IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, gethui())
		local frame = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, vgui)
		return create("UIStroke", { Thickness = 120, Color = Color3.new(0, 0, 0), Transparency = 1 }, frame)
	end)()
end

---Swap every BasePart's material to a shiny preset, tracking originals for revert.
local function updateShinySurfaces()
	local enabled = Skidcheat.config.shaders.shinySurfaces
	Skidcheat.shaderState.originalMaterials = Skidcheat.shaderState.originalMaterials or {}
	local originals = Skidcheat.shaderState.originalMaterials

	if enabled then
		for _, part in ipairs(workspaceService:GetDescendants()) do
			if part:IsA("BasePart") and not originals[part] then
				originals[part] = { part.Material, part.Reflectance }
				part.Material = Enum.Material.Glass
				part.Reflectance = 0.35
			end
		end
	else
		for part, original in pairs(originals) do
			if part.Parent then part.Material, part.Reflectance = original[1], original[2] end
		end
		table.clear(originals)
	end
end

---Advance time of day, position atmosphere/rig lights, bloom, sun rays, DoF, color
---grade, vignette and weather particles.
---@param dt number
local function updateShaderStudio(dt)
	local shaders = Skidcheat.config.shaders
	local state = Skidcheat.shaderState

	if not (shaders.dynamicTime or shaders.atmoEnabled or shaders.rigEnabled or shaders.bloomEnabled
		or shaders.sunRaysEnabled or shaders.dofEnabled or shaders.colorCorrection or shaders.motionBlur
		or shaders.vignette or shaders.weather ~= "Clear" or shaders.shinySurfaces) then
		return
	end

	ensureShaderInstances()
	local s = Skidcheat.shaderInstances

	if shaders.dynamicTime then
		lightingService.ClockTime = (lightingService.ClockTime + dt / math.max(shaders.timeSpeed, 1) * 60) % 24
	else
		lightingService.ClockTime = shaders.clockTime
	end
	lightingService.GeographicLatitude = shaders.latitude

	s.atmosphere.Density = shaders.atmoEnabled and shaders.atmoDensity or 0
	s.atmosphere.Haze = shaders.atmoHaze
	s.atmosphere.Glare = shaders.atmoGlare

	s.bloom.Enabled = shaders.bloomEnabled
	s.bloom.Intensity = shaders.bloomIntensity
	s.bloom.Size = shaders.bloomSize
	s.bloom.Threshold = shaders.bloomThreshold

	s.sunRays.Enabled = shaders.sunRaysEnabled
	s.sunRays.Spread = shaders.sunRaysSpread

	if shaders.sunRaysEnabled and shaders.lensFlare then
		local sunDir = lightingService:GetSunDirection()
		local camPos = currentCamera.CFrame.Position
		local lookDot = math.clamp(currentCamera.CFrame.LookVector:Dot(sunDir), 0, 1)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { state.fxFolder, localPlayer.Character }
		local sunHit = workspaceService:Raycast(camPos, sunDir * 700, params)
		local sunVisible = sunHit == nil and 1 or 0
		local targetGlare = (lookDot ^ 3) * sunVisible * shaders.lensFlareIntensity
		state.smoothGlare = state.smoothGlare + (targetGlare - state.smoothGlare) * math.min(dt * 8, 1)
		s.sunRays.Intensity = shaders.sunRaysIntensity + state.smoothGlare * 0.3
		s.bloom.Intensity = shaders.bloomIntensity + state.smoothGlare * 0.5
	else
		s.sunRays.Intensity = shaders.sunRaysIntensity
	end

	s.dof.Enabled = shaders.dofEnabled
	s.dof.FarIntensity = shaders.dofFar
	s.dof.NearIntensity = shaders.dofNear
	if shaders.dofEnabled and shaders.dofAutoFocus then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { state.fxFolder, localPlayer.Character }
		local hit = workspaceService:Raycast(currentCamera.CFrame.Position, currentCamera.CFrame.LookVector * 250, params)
		local targetDist = hit and (hit.Position - currentCamera.CFrame.Position).Magnitude or shaders.dofDist
		s.dof.FocusDistance = s.dof.FocusDistance + (math.clamp(targetDist, 6, 220) - s.dof.FocusDistance) * math.min(dt * 8, 1)
	else
		s.dof.FocusDistance = shaders.dofDist
	end

	s.colorCorrection.Enabled = shaders.colorCorrection
	s.colorCorrection.Brightness = shaders.ccBrightness
	s.colorCorrection.Saturation = shaders.ccSaturation
	s.colorCorrection.Contrast = shaders.ccContrast
	s.colorCorrection.TintColor = shaders.ccTint

	if shaders.rigEnabled then
		local anchorCFrame = currentCamera.CFrame
		if shaders.rigAttach == "Character" then
			local _, _, root = getLocalCharacter()
			if root then anchorCFrame = root.CFrame end
		end
		local d = shaders.rigDistance
		s.keyLight.CFrame = anchorCFrame * CFrame.new(d * 0.7, d * 0.45, -d * 0.75)
		s.fillLight.CFrame = anchorCFrame * CFrame.new(-d * 0.8, d * 0.15, -d * 0.6)
		s.rimLight.CFrame = anchorCFrame * CFrame.new(0, d * 0.55, d * 0.85)
		s.keyLight.Light.Brightness = shaders.keyBrightness
		s.fillLight.Light.Brightness = shaders.fillBrightness
		s.rimLight.Light.Brightness = shaders.rimBrightness
	end

	if shaders.motionBlur then
		local curLook = currentCamera.CFrame.LookVector
		local angularSpeed = (curLook - state.prevLookVec).Magnitude / math.max(dt, 0.001)
		Skidcheat.config.esp.enabled = Skidcheat.config.esp.enabled
	end
	state.prevLookVec = currentCamera.CFrame.LookVector

	s.vignetteStroke.Transparency = shaders.vignette and (1 - shaders.vignetteOpacity) or 1
	updateShinySurfaces()

	if shaders.weather == "Snow" then
		state.snowAccumulator = state.snowAccumulator + dt
		if state.snowAccumulator >= 0.03 then
			state.snowAccumulator = 0
			local camPos = currentCamera.CFrame.Position
			for _ = 1, 3 do
				local spawnPos = camPos + Vector3.new(math.random(-45, 45), math.random(22, 32), math.random(-45, 45))
				local flake = create("Part", {
					Size = Vector3.new(0.18, 0.18, 0.18), Shape = Enum.PartType.Ball,
					Material = Enum.Material.Neon, Color = Color3.fromRGB(245, 250, 255),
					CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false,
					Massless = true, CFrame = CFrame.new(spawnPos),
				}, state.fxFolder)
				flake.AssemblyLinearVelocity = Vector3.new(math.random(-4, 4), -math.random(8, 13), math.random(-4, 4))
				debrisService:AddItem(flake, 3.5)
			end
		end
	end
end

---Install the silent aim namecall hook.
local function installSilentAim()
	if Skidcheat.hooked then return end
	Skidcheat.hooked = true

	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		local method = getnamecallmethod()
		local part = Skidcheat.silentPart

		if part and not checkcaller() and self == workspaceService and method == "Raycast" then
			if math.random(1, 100) <= Skidcheat.config.silent.hitChance then
				local origin, direction, params = ...
				if typeof(origin) == "Vector3" and typeof(direction) == "Vector3" then
					local expandedTarget = part.Position + Vector3.new(0, Skidcheat.config.silent.hitboxExpand, 0)
					local aimDirection = (expandedTarget - origin).Unit * direction.Magnitude
					return oldNamecall(self, origin, aimDirection, params)
				end
			end
		end

		return oldNamecall(self, ...)
	end))
end

---Per-tick dispatcher for the currently detected game's feature set.
local function updateGameFeatures()
	local placeId = game.PlaceId
	local games = Skidcheat.config.games

	if placeId == GAME_IDS.NaturalDisaster and games.ndAutoRun then
		local _, humanoid = getLocalCharacter()
		if humanoid then humanoid.WalkSpeed = math.max(humanoid.WalkSpeed, 24) end
	end
	-- MM2 auto-dodge, Bloxspin auto-spin and Prison Life auto-cuff need each game's live
	-- remote paths, which drift per update; wire them here once mapped against the current build.
end

---Build a wavy black/grey gradient backdrop behind the panel.
---@param parent Instance
local function buildWavyBackground(parent)
	local canvas = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = BG_DARK, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 0 }, parent)
	create("UICorner", { CornerRadius = UDim.new(0, 12) }, canvas)
	create("UIStroke", { Color = Color3.fromRGB(45, 45, 55), Thickness = 1, Transparency = 0.4 }, canvas)

	local gradient = create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(6, 6, 8)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(24, 24, 30)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 6, 8)),
		}),
		Rotation = 45,
	}, canvas)

	task.spawn(function()
		while canvas.Parent do
			local tween = tweenService:Create(gradient, TweenInfo.new(7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Rotation = 225 })
			tween:Play()
			tween.Completed:Wait()
			gradient.Rotation = 45
		end
	end)
	return canvas
end

---Build the control panel.
local function buildGui()
	local gui = create("ScreenGui", { Name = "SkidcheatHub", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, gethui())
	Skidcheat.gui = gui

	local scaleFactor = IS_MOBILE and 0.76 or 1
	local main = create("Frame", {
		Size = UDim2.fromOffset(480 * scaleFactor, 400 * scaleFactor),
		Position = UDim2.new(0.5, -240 * scaleFactor, 0.5, -200 * scaleFactor),
		BackgroundTransparency = 1, Visible = not IS_MOBILE,
	}, gui)
	create("UIScale", { Scale = scaleFactor }, main)
	buildWavyBackground(main)

	local title = create("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = BG_PANEL, BorderSizePixel = 0, ZIndex = 2 }, main)
	create("UICorner", { CornerRadius = UDim.new(0, 12) }, title)
	create("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(45, 38, 70), ACCENT_COLOR), Rotation = 0 }, title)
	create("TextLabel", {
		Size = UDim2.new(0.6, 0, 1, 0), BackgroundTransparency = 1, Text = "  SKIDCHEAT HUB",
		TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2,
	}, title)
	create("TextLabel", {
		Size = UDim2.new(0.4, -10, 1, 0), Position = UDim2.new(0.6, 0, 0, 0), BackgroundTransparency = 1,
		Text = "v3.0", TextColor3 = TEXT_DIM, Font = Enum.Font.Gotham, TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 2,
	}, title)

	local dragging, dragStart, startPosition
	track(title.InputBegan:Connect(function(input)
		if isPressInput(input) then dragging, dragStart, startPosition = true, input.Position, main.Position end
	end))
	track(userInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
		end
	end))
	track(userInputService.InputEnded:Connect(function(input)
		if isPressInput(input) then dragging = false end
	end))

	local mobileToggle
	if IS_MOBILE then
		mobileToggle = create("TextButton", {
			Size = UDim2.fromOffset(50, 50), Position = UDim2.new(0, 10, 0.4, 0), BackgroundColor3 = BG_PANEL,
			Text = "SC", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 14,
		}, gui)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, mobileToggle)
		create("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(45, 38, 70), ACCENT_COLOR), Rotation = 90 }, mobileToggle)
		track(mobileToggle.Activated:Connect(function() main.Visible = not main.Visible end))
	end

	local tabBar = create("Frame", { Size = UDim2.new(0, 110, 1, -46), Position = UDim2.fromOffset(6, 42), BackgroundTransparency = 1, ZIndex = 2 }, main)
	local tabScroll = create("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = ACCENT_COLOR, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, tabBar)
	create("UIListLayout", { Padding = UDim.new(0, 4) }, tabScroll)

	local tabs, tabButtons = {}, {}

	---Show a single tab.
	---@param name string
	local function selectTab(name)
		for tabName, frame in pairs(tabs) do
			frame.Visible = tabName == name
			tabButtons[tabName].BackgroundColor3 = tabName == name and ACCENT_COLOR or BG_ELEMENT
			tabButtons[tabName].TextColor3 = tabName == name and Color3.new(1, 1, 1) or TEXT_DIM
		end
	end

	---Create a tab.
	---@param name string
	---@return ScrollingFrame
	local function addTab(name)
		local button = create("TextButton", {
			Size = UDim2.new(1, -4, 0, 28), BackgroundColor3 = BG_ELEMENT, BorderSizePixel = 0,
			Text = name, TextColor3 = TEXT_DIM, Font = Enum.Font.GothamMedium, TextSize = 12,
		}, tabScroll)
		create("UICorner", { CornerRadius = UDim.new(0, 6) }, button)

		local frame = create("ScrollingFrame", {
			Size = UDim2.new(1, -128, 1, -48), Position = UDim2.fromOffset(120, 42), BackgroundTransparency = 1,
			BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = ACCENT_COLOR,
			CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 2,
		}, main)
		create("UIListLayout", { Padding = UDim.new(0, 5) }, frame)

		tabs[name], tabButtons[name] = frame, button
		track(button.Activated:Connect(function() selectTab(name) end))
		return frame
	end

	---Add a section header label.
	---@param tab ScrollingFrame
	---@param text string
	local function addHeader(tab, text)
		create("TextLabel", {
			Size = UDim2.new(1, -6, 0, 20), BackgroundTransparency = 1, Text = text,
			TextColor3 = ACCENT_COLOR, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
		}, tab)
	end

	---Add a toggle row.
	---@param tab ScrollingFrame
	---@param label string
	---@param store table
	---@param key string
	local function addToggle(tab, label, store, key)
		local button = create("TextButton", {
			Size = UDim2.new(1, -6, 0, 28), BackgroundColor3 = BG_ELEMENT, BorderSizePixel = 0,
			Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
		}, tab)
		create("UICorner", { CornerRadius = UDim.new(0, 6) }, button)
		create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, button)

		local function refresh()
			button.Text = string.format("%s: %s", label, store[key] and "ON" or "OFF")
			button.TextColor3 = store[key] and ACCENT_COLOR or Color3.new(1, 1, 1)
			button.BackgroundColor3 = store[key] and BG_ELEMENT_HOVER or BG_ELEMENT
		end
		track(button.Activated:Connect(function() store[key] = not store[key]; refresh() end))
		refresh()
		return button
	end

	---Add a slider row, mouse and touch compatible.
	---@param tab ScrollingFrame
	---@param label string
	---@param store table
	---@param key string
	---@param min number
	---@param max number
	---@param step number
	local function addSlider(tab, label, store, key, min, max, step)
		local row = create("Frame", { Size = UDim2.new(1, -6, 0, 40), BackgroundColor3 = BG_ELEMENT, BorderSizePixel = 0 }, tab)
		create("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
		local text = create("TextLabel", {
			Size = UDim2.new(1, -8, 0, 18), Position = UDim2.fromOffset(8, 2), BackgroundTransparency = 1,
			Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.new(1, 1, 1), TextXAlignment = Enum.TextXAlignment.Left,
		}, row)
		local bar = create("Frame", { Size = UDim2.new(1, -16, 0, 10), Position = UDim2.fromOffset(8, 26), BackgroundColor3 = BG_DARK, BorderSizePixel = 0 }, row)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
		local fill = create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = ACCENT_COLOR, BorderSizePixel = 0 }, bar)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)

		local function refresh()
			text.Text = string.format("%s: %s", label, tostring(store[key]))
			fill.Size = UDim2.new((store[key] - min) / (max - min), 0, 1, 0)
		end

		local sliding = false
		local function setFromX(x)
			local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			local value = min + (max - min) * alpha
			store[key] = math.floor(value / step + 0.5) * step
			refresh()
		end

		track(bar.InputBegan:Connect(function(input)
			if isPressInput(input) then sliding = true; setFromX(input.Position.X) end
		end))
		track(userInputService.InputChanged:Connect(function(input)
			if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				setFromX(input.Position.X)
			end
		end))
		track(userInputService.InputEnded:Connect(function(input)
			if isPressInput(input) then sliding = false end
		end))
		refresh()
	end

	---Add a cycle button that steps through a list of string options.
	---@param tab ScrollingFrame
	---@param label string
	---@param store table
	---@param key string
	---@param options table
	local function addCycle(tab, label, store, key, options)
		local button = create("TextButton", {
			Size = UDim2.new(1, -6, 0, 28), BackgroundColor3 = BG_ELEMENT, BorderSizePixel = 0,
			Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
		}, tab)
		create("UICorner", { CornerRadius = UDim.new(0, 6) }, button)
		create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, button)

		local function refresh()
			button.Text = string.format("%s: %s", label, tostring(store[key]))
		end
		track(button.Activated:Connect(function()
			local index = table.find(options, store[key]) or 1
			store[key] = options[index % #options + 1]
			refresh()
		end))
		refresh()
	end

	-- Aimbot tab.
	local aimTab = addTab("Aimbot")
	addHeader(aimTab, "TARGETING")
	addToggle(aimTab, "Aimbot", Skidcheat.config.aimbot, "enabled")
	addToggle(aimTab, "Hold Aim", Skidcheat.config.aimbot, "holdToAim")
	addToggle(aimTab, "FOV Lock", Skidcheat.config.aimbot, "fovLock")
	addToggle(aimTab, "Team Check", Skidcheat.config.aimbot, "teamCheck")
	addToggle(aimTab, "Wall Check", Skidcheat.config.aimbot, "wallCheck")
	addToggle(aimTab, "Ignore Knocked", Skidcheat.config.aimbot, "ignoreKnocked")
	addToggle(aimTab, "Show FOV", Skidcheat.config.aimbot, "showFov")
	addCycle(aimTab, "FOV Anchor", Skidcheat.config.aimbot, "fovAnchor", { "Center", "Mouse" })
	addCycle(aimTab, "Priority", Skidcheat.config.aimbot, "targetPriority", { "Closest", "LowestHealth" })
	addCycle(aimTab, "Aim Part", Skidcheat.config.aimbot, "part", { "Head", "HumanoidRootPart", "UpperTorso" })
	addCycle(aimTab, "Aim Axis", Skidcheat.config.aimbot, "aimAxis", { "Both", "Yaw", "Pitch" })
	addHeader(aimTab, "TUNING")
	addSlider(aimTab, "FOV", Skidcheat.config.aimbot, "fov", 20, 600, 5)
	addSlider(aimTab, "Lock Break Dist", Skidcheat.config.aimbot, "lockBreakDistance", 50, 800, 10)
	addSlider(aimTab, "Smoothing", Skidcheat.config.aimbot, "smoothing", 1, 30, 1)
	addSlider(aimTab, "Prediction", Skidcheat.config.aimbot, "prediction", 0, 0.5, 0.01)

	-- Silent aim tab.
	local silentTab = addTab("Silent Aim")
	addToggle(silentTab, "Silent Aim", Skidcheat.config.silent, "enabled")
	addToggle(silentTab, "Team Check", Skidcheat.config.silent, "teamCheck")
	addToggle(silentTab, "Wall Check", Skidcheat.config.silent, "wallCheck")
	addCycle(silentTab, "FOV Anchor", Skidcheat.config.silent, "fovAnchor", { "Center", "Mouse" })
	addCycle(silentTab, "Aim Part", Skidcheat.config.silent, "part", { "Head", "HumanoidRootPart", "UpperTorso" })
	addSlider(silentTab, "FOV", Skidcheat.config.silent, "fov", 20, 1000, 10)
	addSlider(silentTab, "Hit Chance", Skidcheat.config.silent, "hitChance", 1, 100, 1)
	addSlider(silentTab, "Prediction", Skidcheat.config.silent, "prediction", 0, 0.5, 0.01)
	addSlider(silentTab, "Hitbox Expand", Skidcheat.config.silent, "hitboxExpand", -2, 2, 0.1)

	-- Trigger bot tab.
	local triggerTab = addTab("Trigger Bot")
	addToggle(triggerTab, "Trigger Bot", Skidcheat.config.trigger, "enabled")
	addToggle(triggerTab, "Require Aim Hold", Skidcheat.config.trigger, "requireAim")
	addToggle(triggerTab, "Team Check", Skidcheat.config.trigger, "teamCheck")
	addToggle(triggerTab, "Wall Check", Skidcheat.config.trigger, "wallCheck")
	addCycle(triggerTab, "FOV Anchor", Skidcheat.config.trigger, "fovAnchor", { "Center", "Mouse" })
	addCycle(triggerTab, "Aim Part", Skidcheat.config.trigger, "part", { "Head", "HumanoidRootPart", "UpperTorso" })
	addSlider(triggerTab, "FOV", Skidcheat.config.trigger, "fov", 5, 300, 5)
	addSlider(triggerTab, "Min Delay", Skidcheat.config.trigger, "delayMin", 0, 0.3, 0.01)
	addSlider(triggerTab, "Max Delay", Skidcheat.config.trigger, "delayMax", 0, 0.5, 0.01)

	-- Ragebot tab.
	local rageTab = addTab("Ragebot")
	addToggle(rageTab, "Ragebot", Skidcheat.config.rage, "enabled")
	addToggle(rageTab, "Auto Fire", Skidcheat.config.rage, "autoFire")
	addToggle(rageTab, "Team Check", Skidcheat.config.rage, "teamCheck")
	addToggle(rageTab, "Wall Check", Skidcheat.config.rage, "wallCheck")
	addCycle(rageTab, "Rage Part", Skidcheat.config.rage, "part", { "Head", "HumanoidRootPart", "UpperTorso" })
	addSlider(rageTab, "Fire Delay", Skidcheat.config.rage, "fireDelay", 0.01, 0.5, 0.01)
	addSlider(rageTab, "Prediction", Skidcheat.config.rage, "prediction", 0, 0.5, 0.01)
	addSlider(rageTab, "Hit Chance", Skidcheat.config.rage, "hitChance", 1, 100, 1)
	addSlider(rageTab, "Switch Delay", Skidcheat.config.rage, "switchDelay", 0, 1, 0.05)

	-- Spin bot tab.
	local spinTab = addTab("Spin Bot")
	addToggle(spinTab, "Spin Bot", Skidcheat.config.spin, "enabled")
	addToggle(spinTab, "Randomize Speed", Skidcheat.config.spin, "randomize")
	addToggle(spinTab, "Body Freeze", Skidcheat.config.spin, "bodyFreeze")
	addCycle(spinTab, "Axis", Skidcheat.config.spin, "axis", { "Y", "X" })
	addSlider(spinTab, "Speed", Skidcheat.config.spin, "speed", 1, 60, 1)
	addSlider(spinTab, "Radius", Skidcheat.config.spin, "radius", 0, 10, 0.5)

	-- ESP tab.
	local espTab = addTab("ESP")
	addToggle(espTab, "ESP", Skidcheat.config.esp, "enabled")
	addToggle(espTab, "Box", Skidcheat.config.esp, "box")
	addToggle(espTab, "Corner Box", Skidcheat.config.esp, "cornerBox")
	addToggle(espTab, "Outline", Skidcheat.config.esp, "outline")
	addToggle(espTab, "Skeleton", Skidcheat.config.esp, "skeleton")
	addToggle(espTab, "Tracer", Skidcheat.config.esp, "tracer")
	addToggle(espTab, "Snap Lines", Skidcheat.config.esp, "snapLines")
	addCycle(espTab, "Tracer Origin", Skidcheat.config.esp, "tracerOrigin", { "Bottom", "Mouse" })
	addToggle(espTab, "Chams", Skidcheat.config.esp, "chams")
	addToggle(espTab, "Names", Skidcheat.config.esp, "names")
	addToggle(espTab, "View Angle", Skidcheat.config.esp, "viewAngle")
	addToggle(espTab, "Weapon", Skidcheat.config.esp, "weapon")
	addToggle(espTab, "Health", Skidcheat.config.esp, "health")
	addToggle(espTab, "Distance", Skidcheat.config.esp, "distance")
	addToggle(espTab, "Off-screen Arrows", Skidcheat.config.esp, "offscreenArrows")
	addToggle(espTab, "Team Check", Skidcheat.config.esp, "teamCheck")
	addSlider(espTab, "Max Distance", Skidcheat.config.esp, "maxDistance", 100, 5000, 50)

	-- Visuals / shader studio tab.
	local visualsTab = addTab("Visuals")
	addHeader(visualsTab, "WORLD")
	addToggle(visualsTab, "No Shadows", Skidcheat.config.shaders, "atmoEnabled")
	addToggle(visualsTab, "Dynamic Time", Skidcheat.config.shaders, "dynamicTime")
	addSlider(visualsTab, "Clock Time", Skidcheat.config.shaders, "clockTime", 0, 24, 0.5)
	addSlider(visualsTab, "Time Speed", Skidcheat.config.shaders, "timeSpeed", 1, 120, 1)
	addToggle(visualsTab, "Atmosphere", Skidcheat.config.shaders, "atmoEnabled")
	addSlider(visualsTab, "Atmo Density", Skidcheat.config.shaders, "atmoDensity", 0, 1, 0.05)
	addHeader(visualsTab, "SHADERS")
	addToggle(visualsTab, "Shiny Surfaces", Skidcheat.config.shaders, "shinySurfaces")
	addToggle(visualsTab, "Bloom", Skidcheat.config.shaders, "bloomEnabled")
	addSlider(visualsTab, "Bloom Intensity", Skidcheat.config.shaders, "bloomIntensity", 0, 5, 0.1)
	addToggle(visualsTab, "Sun Rays", Skidcheat.config.shaders, "sunRaysEnabled")
	addSlider(visualsTab, "Sun Rays Intensity", Skidcheat.config.shaders, "sunRaysIntensity", 0, 1, 0.05)
	addToggle(visualsTab, "Lens Flare", Skidcheat.config.shaders, "lensFlare")
	addToggle(visualsTab, "Depth Of Field", Skidcheat.config.shaders, "dofEnabled")
	addToggle(visualsTab, "DoF Auto Focus", Skidcheat.config.shaders, "dofAutoFocus")
	addToggle(visualsTab, "Color Correction", Skidcheat.config.shaders, "colorCorrection")
	addSlider(visualsTab, "Saturation", Skidcheat.config.shaders, "ccSaturation", -1, 1, 0.05)
	addSlider(visualsTab, "Contrast", Skidcheat.config.shaders, "ccContrast", -1, 1, 0.05)
	addToggle(visualsTab, "Vignette", Skidcheat.config.shaders, "vignette")
	addSlider(visualsTab, "Vignette Strength", Skidcheat.config.shaders, "vignetteOpacity", 0, 1, 0.05)
	addCycle(visualsTab, "Weather", Skidcheat.config.shaders, "weather", { "Clear", "Snow" })
	addHeader(visualsTab, "3-POINT LIGHT RIG")
	addToggle(visualsTab, "Studio Rig", Skidcheat.config.shaders, "rigEnabled")
	addCycle(visualsTab, "Rig Attach", Skidcheat.config.shaders, "rigAttach", { "Camera", "Character" })
	addSlider(visualsTab, "Rig Distance", Skidcheat.config.shaders, "rigDistance", 2, 30, 1)

	-- Misc tab.
	local miscTab = addTab("Misc")
	addHeader(miscTab, "MOVEMENT")
	addToggle(miscTab, "Speed", Skidcheat.config.misc, "speed")
	addSlider(miscTab, "Speed Value", Skidcheat.config.misc, "speedValue", 16, 200, 1)
	addToggle(miscTab, "Infinite Jump", Skidcheat.config.misc, "infJump")
	addSlider(miscTab, "Jump Power", Skidcheat.config.misc, "jumpPower", 50, 300, 5)
	addToggle(miscTab, "Anti AFK", Skidcheat.config.misc, "antiAfk")

	addHeader(miscTab, "NOCLIP")
	addToggle(miscTab, "Noclip", Skidcheat.config.misc, "noclip")
	addToggle(miscTab, "Whitelist Materials Only", Skidcheat.config.misc, "noclipWhitelistOnly")

	addHeader(miscTab, "FLY")
	addToggle(miscTab, "Fly", Skidcheat.config.misc, "fly")
	addSlider(miscTab, "Fly Speed", Skidcheat.config.misc, "flySpeed", 10, 300, 5)
	addSlider(miscTab, "Fly Vertical Speed", Skidcheat.config.misc, "flyVerticalSpeed", 10, 300, 5)
	addToggle(miscTab, "Camera Relative", Skidcheat.config.misc, "flyCameraRelative")
	addToggle(miscTab, "No Collide While Flying", Skidcheat.config.misc, "flyNoCollide")

	addHeader(miscTab, "FLING")
	addToggle(miscTab, "Fling Enabled", Skidcheat.config.misc.fling, "enabled")
	addToggle(miscTab, "Fling All Players", Skidcheat.config.misc.fling, "allPlayers")
	addToggle(miscTab, "Auto Return After Fling", Skidcheat.config.misc.fling, "autoReturn")
	addCycle(miscTab, "Fling Mode", Skidcheat.config.misc.fling, "mode", { "VelocitySpam", "CFrameOnly" })
	addSlider(miscTab, "Fling Power", Skidcheat.config.misc.fling, "power", 1e6, 9e7, 1e6)

	local flingList = create("ScrollingFrame", {
		Size = UDim2.new(1, -6, 0, 110), BackgroundColor3 = BG_ELEMENT, BorderSizePixel = 0,
		ScrollBarThickness = 3, ScrollBarImageColor3 = ACCENT_COLOR, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, miscTab)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, flingList)
	create("UIListLayout", { Padding = UDim.new(0, 2) }, flingList)

	local function refreshFlingList()
		for _, child in ipairs(flingList:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		for _, player in ipairs(playersService:GetPlayers()) do
			if player == localPlayer then continue end
			local row = create("TextButton", {
				Size = UDim2.new(1, -4, 0, 24), BackgroundColor3 = BG_DARK, BorderSizePixel = 0,
				Text = player.DisplayName, TextColor3 = Skidcheat.flingTargets[player] and ACCENT_COLOR or Color3.new(1, 1, 1),
				Font = Enum.Font.Gotham, TextSize = 12, AutoButtonColor = false,
			}, flingList)
			track(row.Activated:Connect(function()
				Skidcheat.flingTargets[player] = not Skidcheat.flingTargets[player]
				row.TextColor3 = Skidcheat.flingTargets[player] and ACCENT_COLOR or Color3.new(1, 1, 1)
			end))
		end
	end
	refreshFlingList()
	track(playersService.PlayerAdded:Connect(refreshFlingList))
	track(playersService.PlayerRemoving:Connect(refreshFlingList))

	addHeader(miscTab, "ANTI-FLING / ANTI-VOID")
	addToggle(miscTab, "Anti-Fling", Skidcheat.config.misc.antiFling, "enabled")
	addCycle(miscTab, "Anti-Fling Action", Skidcheat.config.misc.antiFling, "action", { "Zero", "Anchor", "Counter" })
	addSlider(miscTab, "Velocity Threshold", Skidcheat.config.misc.antiFling, "velocityThreshold", 50, 500, 10)
	addToggle(miscTab, "Anti-Void", Skidcheat.config.misc.antiVoid, "enabled")
	addSlider(miscTab, "Void Y Level", Skidcheat.config.misc.antiVoid, "voidY", -1000, 0, 10)
	addSlider(miscTab, "Teleport Delay", Skidcheat.config.misc.antiVoid, "teleportDelay", 0, 1, 0.05)

	local rejoinButton = create("TextButton", {
		Size = UDim2.new(1, -6, 0, 28), BackgroundColor3 = BG_ELEMENT, BorderSizePixel = 0,
		Text = "Rejoin Server", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.Gotham, TextSize = 13, AutoButtonColor = false,
	}, miscTab)
	create("UICorner", { CornerRadius = UDim.new(0, 6) }, rejoinButton)
	track(rejoinButton.Activated:Connect(function()
		pcall(function() teleportService:Teleport(game.PlaceId, localPlayer) end)
	end))

	-- Games tab.
	local gamesTab = addTab("Games")
	addHeader(gamesTab, "MURDER MYSTERY 2")
	addToggle(gamesTab, "Auto Dodge Knife", Skidcheat.config.games, "mm2AutoDodge")
	addToggle(gamesTab, "Murderer ESP Tag", Skidcheat.config.games, "mm2MurdererEsp")
	addToggle(gamesTab, "Sheriff ESP Tag", Skidcheat.config.games, "mm2SheriffEsp")
	addHeader(gamesTab, "NATURAL DISASTER SURVIVAL")
	addToggle(gamesTab, "Safe Zone ESP", Skidcheat.config.games, "ndSafeZoneEsp")
	addToggle(gamesTab, "Auto Run To Safety", Skidcheat.config.games, "ndAutoRun")
	addHeader(gamesTab, "BLOXSPIN")
	addToggle(gamesTab, "Auto Spin", Skidcheat.config.games, "bloxspinAutoSpin")
	addSlider(gamesTab, "Bet Amount", Skidcheat.config.games, "bloxspinBetAmount", 1, 1000, 1)
	addHeader(gamesTab, "PRISON LIFE")
	addToggle(gamesTab, "Wanted ESP", Skidcheat.config.games, "plEspWanted")
	addToggle(gamesTab, "Auto Cuff Nearby", Skidcheat.config.games, "plAutoCuff")

	selectTab("Aimbot")

	-- Mobile fly controls, shown only while flying.
	if IS_MOBILE then
		local flyUp = create("TextButton", {
			Size = UDim2.fromOffset(46, 46), Position = UDim2.new(1, -60, 1, -120), BackgroundColor3 = BG_PANEL,
			Text = "UP", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 12, Visible = false,
		}, gui)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, flyUp)
		local flyDown = create("TextButton", {
			Size = UDim2.fromOffset(46, 46), Position = UDim2.new(1, -60, 1, -64), BackgroundColor3 = BG_PANEL,
			Text = "DOWN", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 11, Visible = false,
		}, gui)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, flyDown)

		local holdingUp, holdingDown = false, false
		track(flyUp.InputBegan:Connect(function(input) if isPressInput(input) then holdingUp = true end end))
		track(flyUp.InputEnded:Connect(function(input) if isPressInput(input) then holdingUp = false end end))
		track(flyDown.InputBegan:Connect(function(input) if isPressInput(input) then holdingDown = true end end))
		track(flyDown.InputEnded:Connect(function(input) if isPressInput(input) then holdingDown = false end end))

		Skidcheat.mobileFlyState = function()
			flyUp.Visible = Skidcheat.config.misc.fly
			flyDown.Visible = Skidcheat.config.misc.fly
			if holdingUp then return 1 end
			if holdingDown then return -1 end
			return 0
		end
	end

	track(userInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.RightShift then
			main.Visible = not main.Visible
		elseif input.KeyCode == Skidcheat.config.misc.noclipKey then
			Skidcheat.config.misc.noclip = not Skidcheat.config.misc.noclip
		end
	end))
end

---Tear down everything this panel created.
function Skidcheat.detach()
	for _, connection in ipairs(Skidcheat.connections) do
		pcall(function() connection:Disconnect() end)
	end
	for _, drawing in ipairs(Skidcheat.drawings) do
		pcall(function() drawing:Remove() end)
	end
	for player in pairs(Skidcheat.espObjects) do
		removeEsp(player)
	end

	Skidcheat.config.misc.noclip = false
	Skidcheat.config.misc.fly = false
	Skidcheat.config.misc.fling.enabled = false
	Skidcheat.config.misc.antiFling.enabled = false
	Skidcheat.config.misc.antiVoid.enabled = false
	updateNoclip()
	updateFly()

	Skidcheat.config.shaders.shinySurfaces = false
	Skidcheat.config.shaders.bloomEnabled = false
	Skidcheat.config.shaders.sunRaysEnabled = false
	Skidcheat.config.shaders.dofEnabled = false
	Skidcheat.config.shaders.colorCorrection = false
	Skidcheat.config.shaders.vignette = false
	Skidcheat.config.shaders.weather = "Clear"
	updateShinySurfaces()
	if Skidcheat.shaderState.fxFolder then
		Skidcheat.shaderState.fxFolder:Destroy()
	end
	for _, instance in pairs(Skidcheat.shaderInstances) do
		if typeof(instance) == "Instance" then
			pcall(function() instance:Destroy() end)
		end
	end
	currentCamera.FieldOfView = 70

	if Skidcheat.gui then Skidcheat.gui:Destroy() end

	Skidcheat.silentPart = nil
	Skidcheat.lockedTarget = nil
	Skidcheat.config.silent.enabled = false
	Skidcheat.flingTargets = {}
	Skidcheat.connections, Skidcheat.drawings, Skidcheat.espObjects = {}, {}, {}
end

---Initialize the panel.
function Skidcheat.init()
	buildGui()
	installSilentAim()

	local fovCircle = trackDrawing(Drawing.new("Circle"))
	fovCircle.Thickness = 1
	fovCircle.NumSides = 64
	fovCircle.Color = ACCENT_COLOR
	fovCircle.Filled = false

	track(runService.RenderStepped:Connect(function()
		currentCamera = workspaceService.CurrentCamera
		updateAim(fovCircle)
		updateEsp()
		updateMisc()
	end))

	track(runService.Heartbeat:Connect(function(dt)
		updateShaderStudio(dt)
	end))

	track(runService.Stepped:Connect(function()
		updateNoclip()
		updateSpinbot()
		updateAntiAfk()
		updateGameFeatures()
		updateSafePositionTracking()
		updateAntiFling()
		updateAntiVoid()
		updateFling()
	end))

	track(playersService.PlayerRemoving:Connect(removeEsp))
end

---@param error string
local function onInitializeError(error)
	warn("Failed to initialize.")
	warn(error)
	warn(debug.traceback())
	Skidcheat.detach()
end

-- Replace any previous execution.
if shared.SkidcheatHub then
	shared.SkidcheatHub.detach()
end

shared.SkidcheatHub = Skidcheat
xpcall(Skidcheat.init, onInitializeError)
