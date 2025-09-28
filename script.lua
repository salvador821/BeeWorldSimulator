-- Atlas v2 fr - HEARTBEAT FIXED VERSION
-- Made by sal

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Global Variables
_G.AutoDig = false
_G.AutoFarm = false
_G.SelectedField = "mango field"
_G.WalkSpeed = 16
_G.JumpPower = 50
_G.TokenRange = 100
_G.DebugText = "Script Loaded"
_G.CurrentFarmField = nil
_G.FarmConnection = nil
_G.DigConnection = nil

-- Field coordinates table
local fieldCoords = {
    ["mango field"] = Vector3.new(-1895.27, 73.50, -141.94),
    ["blueberry field"] = Vector3.new(-2074.56, 73.50, -188.62),
    ["daisy field"] = Vector3.new(-2166.29, 73.50, 41.82),
    ["cactus field"] = Vector3.new(-2398.86, 109.04, 42.60),
    ["strawberry field"] = Vector3.new(-1758.79, 73.50, -69.91),
    ["apple field"] = Vector3.new(-1967.78, 94.43, -344.20),
    ["lemon field"] = Vector3.new(-1832.23, 94.43, -310.76),
    ["grape field"] = Vector3.new(-2113.74, 94.43, -347.57),
    ["watermelon field"] = Vector3.new(-2220.26, 146.85, -507.15),
    ["forest field"] = Vector3.new(-2351.29, 95.15, -178.81),
    ["pear field"] = Vector3.new(-1814.76, 146.85, -488.39),
    ["mushroom field"] = Vector3.new(-1779.69, 146.85, -652.93),
    ["clover field"] = Vector3.new(-1638.08, 146.85, -487.75),
    ["bamboo field"] = Vector3.new(-1638.96, 117.49, -163.70),
    ["glitch field"] = Vector3.new(-2568.07, 168.00, -429.88),
    ["cave field"] = Vector3.new(-1995.52, 71.78, -63.91),
    ["mountain field"] = Vector3.new(-1995.52, 71.78, -63.91)
}

-- Create Window
local Window = Rayfield:CreateWindow({
   Name = "Atlas v2 fr",
   LoadingTitle = "Atlas v2 fr",
   LoadingSubtitle = "made by sal",
   ConfigurationSaving = {
      Enabled = false,
   },
   Discord = {
      Enabled = false,
   },
   KeySystem = false,
})

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Player reference
local Player = Players.LocalPlayer

-- Heartbeat wait function
local function HeartbeatWait(seconds)
    local start = os.clock()
    while os.clock() - start < seconds and RunService.Heartbeat:Wait() do
        if not _G.AutoFarm and not _G.AutoDig then
            return false
        end
    end
    return true
end

-- Quick heartbeat wait (non-interruptible)
local function QuickWait(seconds)
    local start = os.clock()
    while os.clock() - start < seconds do
        RunService.Heartbeat:Wait()
    end
end

-- Debug function
local function UpdateDebug(message)
    _G.DebugText = message
end

-- Get character
local function GetCharacter()
    local char = Player.Character
    if not char then
        char = Player.CharacterAdded:Wait()
        QuickWait(1)
    end
    return char
end

-- Apply speed
local function ApplySpeed()
    local char = GetCharacter()
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = _G.WalkSpeed
        char.Humanoid.JumpPower = _G.JumpPower
    end
end

-- Auto apply speed on respawn
Player.CharacterAdded:Connect(function()
    QuickWait(1)
    ApplySpeed()
end)

-- Check if at field
local function IsAtField()
    local char = GetCharacter()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    
    local fieldPos = fieldCoords[_G.SelectedField]
    if not fieldPos then return false end
    
    return (hrp.Position - fieldPos).Magnitude < 50
end

-- Simple movement with heartbeat
local function MoveToPosition(target)
    local char = GetCharacter()
    local humanoid = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not hrp then return false end
    
    humanoid:MoveTo(target)
    
    local startTime = os.clock()
    while os.clock() - startTime < 10 do
        if (hrp.Position - target).Magnitude < 10 then
            return true
        end
        RunService.Heartbeat:Wait()
    end
    return false
end

-- Get nearest token
local function GetNearestToken()
    local char = GetCharacter()
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    -- Look for tokens in common locations
    local debris = workspace:FindFirstChild("Debris")
    local tokens = {}
    
    if debris then
        local tokenFolder = debris:FindFirstChild("Tokens")
        if tokenFolder then
            for _, obj in pairs(tokenFolder:GetChildren()) do
                if obj:IsA("Part") then
                    table.insert(tokens, obj)
                end
            end
        end
    end
    
    -- Search workspace
    for _, obj in pairs(workspace:GetChildren()) do
        if obj:IsA("Part") and (obj.Name:lower():find("token") or obj:FindFirstChild("Token")) then
            table.insert(tokens, obj)
        end
    end
    
    -- Find closest
    local closest = nil
    local closestDist = math.huge
    
    for _, token in pairs(tokens) do
        local dist = (token.Position - hrp.Position).Magnitude
        if dist < _G.TokenRange and dist < closestDist then
            closest = token
            closestDist = dist
        end
    end
    
    return closest
end

-- Go to field function - FIXED
local function GoToField()
    UpdateDebug("Moving to " .. _G.SelectedField)
    local fieldPos = fieldCoords[_G.SelectedField]
    
    if MoveToPosition(fieldPos) then
        _G.CurrentFarmField = _G.SelectedField
        UpdateDebug("Arrived at " .. _G.SelectedField)
        return true
    else
        UpdateDebug("Failed to reach field")
        return false
    end
end

-- Token collection
local function CollectTokens()
    UpdateDebug("Collecting tokens...")
    
    for i = 1, 15 do
        if not _G.AutoFarm then break end
        
        local token = GetNearestToken()
        if token then
            UpdateDebug("Moving to token")
            MoveToPosition(token.Position)
            QuickWait(0.5)
        else
            UpdateDebug("No tokens found")
            break
        end
    end
end
-- Main farming with heartbeat connection
local function StartFarming()
    if _G.FarmConnection then
        _G.FarmConnection:Disconnect()
        _G.FarmConnection = nil
    end
    
    UpdateDebug("Auto Farm STARTED")
    
    _G.FarmConnection = RunService.Heartbeat:Connect(function()
        if not _G.AutoFarm then
            _G.FarmConnection:Disconnect()
            _G.FarmConnection = nil
            return
        end
        
        -- Force field navigation when field changes
        if _G.CurrentFarmField ~= _G.SelectedField or not IsAtField() then
            GoToField()
        end
        
        -- Collect tokens if at field
        if IsAtField() then
            CollectTokens()
        end
    end)
end

-- Auto Dig with heartbeat connection
local function StartDigging()
    if _G.DigConnection then
        _G.DigConnection:Disconnect()
        _G.DigConnection = nil
    end
    
    UpdateDebug("Auto Dig STARTED")
    
    local lastDigTime = 0
    _G.DigConnection = RunService.Heartbeat:Connect(function()
        if not _G.AutoDig then
            _G.DigConnection:Disconnect()
            _G.DigConnection = nil
            return
        end
        
        -- Dig every 0.1 seconds
        if os.clock() - lastDigTime >= 0.1 then
            local char = GetCharacter()
            for _, tool in pairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    local remote = tool:FindFirstChild("ToolRemote")
                    if remote then
                        remote:FireServer()
                    end
                end
            end
            lastDigTime = os.clock()
        end
    end)
end

-- Create UI
local MainTab = Window:CreateTab("Main", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)
local InfoTab = Window:CreateTab("Info", 4483362458)

-- Field dropdown
local FieldDropdown = MainTab:CreateDropdown({
    Name = "Field",
    Options = {
        "mango field", "blueberry field", "daisy field", "cactus field", 
        "strawberry field", "apple field", "lemon field", "grape field", 
        "watermelon field", "forest field", "pear field", "mushroom field", 
        "clover field", "bamboo field", "glitch field", "cave field", 
        "mountain field"
    },
    CurrentOption = "mango field",
    Flag = "FieldDropdown",
    Callback = function(Option)
        _G.SelectedField = Option
        UpdateDebug("Field: " .. Option)
        -- Force field change when dropdown changes
        if _G.AutoFarm then
            _G.CurrentFarmField = nil
        end
    end,
})

-- Auto Dig toggle
local AutoDigToggle = MainTab:CreateToggle({
    Name = "Auto Dig",
    CurrentValue = false,
    Flag = "AutoDigToggle",
    Callback = function(Value)
        _G.AutoDig = Value
        if Value then
            StartDigging()
        else
            if _G.DigConnection then
                _G.DigConnection:Disconnect()
                _G.DigConnection = nil
            end
            UpdateDebug("Auto Dig disabled")
        end
    end,
})

-- Auto Farm toggle - FIXED FIELD NAVIGATION
local AutoFarmToggle = MainTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarmToggle",
    Callback = function(Value)
        _G.AutoFarm = Value
        if Value then
            -- ALWAYS reset field when toggling on
            _G.CurrentFarmField = nil
            StartFarming()
        else
            if _G.FarmConnection then
                _G.FarmConnection:Disconnect()
                _G.FarmConnection = nil
            end
            UpdateDebug("Auto Farm disabled")
        end
    end,
})

-- Settings
SettingsTab:CreateSection("Movement")

local WalkSpeedSlider = SettingsTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 120},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        _G.WalkSpeed = Value
        ApplySpeed()
    end,
})

local JumpPowerSlider = SettingsTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 120},
    Increment = 1,
    Suffix = "Power",
    CurrentValue = 50,
    Flag = "JumpPowerSlider",
    Callback = function(Value)
        _G.JumpPower = Value
        ApplySpeed()
    end,
})

SettingsTab:CreateSection("Farming")

local TokenRangeSlider = SettingsTab:CreateSlider({
    Name = "Token Range",
    Range = {50, 500},
    Increment = 10,
    Suffix = "Studs",
    CurrentValue = 100,
    Flag = "TokenRangeSlider",
    Callback = function(Value)
        _G.TokenRange = Value
    end,
})

-- Emergency stop
SettingsTab:CreateButton({
    Name = "STOP ALL",
    Callback = function()
        _G.AutoDig = false
        _G.AutoFarm = false
        
        if _G.DigConnection then
            _G.DigConnection:Disconnect()
            _G.DigConnection = nil
        end
        
        if _G.FarmConnection then
            _G.FarmConnection:Disconnect()
            _G.FarmConnection = nil
        end
        
        UpdateDebug("EVERYTHING STOPPED")
    end,
})

-- Info tab
InfoTab:CreateLabel("Atlas v2 fr - Made by sal")
InfoTab:CreateLabel("Auto Dig: Fires ToolRemote every 0.1s")
InfoTab:CreateLabel("Auto Farm: Goes to field and collects tokens")
InfoTab:CreateLabel("Field: Select where to farm")

local DebugLabel = InfoTab:CreateLabel("Debug: " .. _G.DebugText)

-- Update debug display with heartbeat
_G.DebugConnection = RunService.Heartbeat:Connect(function()
    DebugLabel:Set("Text", "Debug: " .. _G.DebugText)
end)

-- Apply speed on start
QuickWait(2)
ApplySpeed()
UpdateDebug("READY - Select field and enable features")

print("Atlas v2 fr - HEARTBEAT EDITION - LOADED SUCCESSFULLY")
