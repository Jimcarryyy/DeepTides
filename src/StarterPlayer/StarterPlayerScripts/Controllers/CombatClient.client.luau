--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ZoneConfig = require(ReplicatedStorage.Config.ZoneConfig)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local AttackRequest = Remotes:WaitForChild("AttackRequest") :: RemoteEvent
local AbilityRequest = Remotes:WaitForChild("AbilityRequest") :: RemoteEvent

local isAttacking = false
local isDodging = false
local lastDodgeTime = 0
local DODGE_COOLDOWN = 1.8

-- 1. TOGGLE EQUIP / UNEQUIP (KEY 1 / SLOT 1 CLICK)
local function toggleEquipTool()
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if not hum or not backpack or hum.Health <= 0 then return end

	local currentTool = char:FindFirstChildOfClass("Tool")
	if currentTool and currentTool.Name:match("^DivingTool_") then
		-- Currently holding weapon: UNEQUIP IT (Put in backpack)
		hum:UnequipTools()
	else
		-- Currently unequipped: DRAW WEAPON from backpack
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") and item.Name:match("^DivingTool_") then
				hum:EquipTool(item)
				break
			end
		end
	end
end

-- 2. PROCEDURAL WEAPON SWING MOTION
local function playAttackMotion()
	local char = LocalPlayer.Character
	if not char then return end

	local tool = char:FindFirstChildOfClass("Tool")
	if not tool or not tool.Name:match("^DivingTool_") then return end

	local handle = tool:FindFirstChild("Handle") :: BasePart?
	if not handle then return end

	local origGrip = tool.Grip
	tool.Grip = origGrip * CFrame.new(0, 0, -1.2) * CFrame.Angles(math.rad(20), 0, 0)
	task.wait(0.12)
	tool.Grip = origGrip
end

-- 3. ATTACK TRIGGER (LEFT-CLICK / TAP / R2)
local function triggerAttack()
	if isAttacking then return end

	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if not hum or hum.Health <= 0 then return end

	-- If weapon is currently unequipped in backpack, auto-equip it first!
	local equippedTool = char:FindFirstChildOfClass("Tool")
	if not equippedTool or not equippedTool.Name:match("^DivingTool_") then
		if backpack then
			for _, item in ipairs(backpack:GetChildren()) do
				if item:IsA("Tool") and item.Name:match("^DivingTool_") then
					hum:EquipTool(item)
					task.wait(0.08)
					equippedTool = char:FindFirstChildOfClass("Tool")
					break
				end
			end
		end
	end

	if not equippedTool or not equippedTool.Name:match("^DivingTool_") then return end

	isAttacking = true
	AttackRequest:FireServer()
	playAttackMotion()

	task.wait(0.35)
	isAttacking = false
end

-- 4. DIRECTIONAL DODGE DASH (STRICTLY UNDERWATER)
local function triggerDodge()
	local now = os.clock()
	if isDodging or (now - lastDodgeTime < DODGE_COOLDOWN) then return end

	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end

	local isSwimming = hum:GetState() == Enum.HumanoidStateType.Swimming
	local isSubmerged = (hrp.Position.Y < ZoneConfig.WATER_SURFACE_Y) or isSwimming
	if not isSubmerged then
		return -- Space bar jumps normally on land!
	end

	isDodging = true
	lastDodgeTime = now

	local moveDir = hum.MoveDirection
	if moveDir.Magnitude == 0 then
		moveDir = hrp.CFrame.LookVector
	end

	local bv = Instance.new("BodyVelocity")
	bv.Name = "DodgeVelocity"
	bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bv.Velocity = moveDir * 55
	bv.Parent = hrp

	task.wait(0.2)
	bv:Destroy()
	isDodging = false
end

-- 5. SUIT ABILITY TRIGGER (BUTTON 2 / Q)
local function triggerAbility()
	local char = LocalPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	AbilityRequest:FireServer()
end

-- ===================================================================
-- INPUT BINDINGS
-- ===================================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- 1. TOGGLE EQUIP / UNEQUIP (Key 1 / Keypad 1)
	if input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.KeypadOne then
		toggleEquipTool()

	-- 2. ATTACK (Left Click / Screen Tap / Controller R2)
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 
		or input.UserInputType == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.ButtonR2 then
		triggerAttack()

	-- 3. SUIT ABILITY (Q / Number 2 / Controller Y)
	elseif input.KeyCode == Enum.KeyCode.Q
		or input.KeyCode == Enum.KeyCode.Two
		or input.KeyCode == Enum.KeyCode.KeypadTwo
		or input.KeyCode == Enum.KeyCode.ButtonY then
		triggerAbility()

	-- 4. DODGE DASH (Space / Shift / Number 3 / Controller B) - Underwater only
	elseif input.KeyCode == Enum.KeyCode.Space
		or input.KeyCode == Enum.KeyCode.LeftShift
		or input.KeyCode == Enum.KeyCode.Three
		or input.KeyCode == Enum.KeyCode.KeypadThree
		or input.KeyCode == Enum.KeyCode.ButtonB then
		triggerDodge()
	end
end)

-- Click support on the Action Bar slots
task.defer(function()
	local mainHUD = PlayerGui:WaitForChild("MainHUD", 5)
	if mainHUD then
		local actionBar = mainHUD:WaitForChild("CombatActionBar", 3)
		if actionBar then
			local slotAttack = actionBar:FindFirstChild("Slot_Attack")
			local slotAbility = actionBar:FindFirstChild("Slot_Ability")
			local slotDodge = actionBar:FindFirstChild("Slot_Dodge")

			-- Clicking Slot 1 toggles Equip / Unequip
			if slotAttack then
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, 0, 1, 0)
				btn.BackgroundTransparency = 1
				btn.Text = ""
				btn.Parent = slotAttack
				btn.MouseButton1Click:Connect(toggleEquipTool)
			end

			if slotAbility then
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, 0, 1, 0)
				btn.BackgroundTransparency = 1
				btn.Text = ""
				btn.Parent = slotAbility
				btn.MouseButton1Click:Connect(triggerAbility)
			end

			if slotDodge then
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, 0, 1, 0)
				btn.BackgroundTransparency = 1
				btn.Text = ""
				btn.Parent = slotDodge
				btn.MouseButton1Click:Connect(triggerDodge)
			end
		end
	end
end)

print("[Deep Tides] CombatClient: Equip/Unequip on '1' & Attack on Click active.")