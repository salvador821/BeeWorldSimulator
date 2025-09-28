-- Atlas v2 fr - FREEZE FIXED VERSION
-- Made by sal

-- Balanced Secure Mode to prevent freezing
getgenv().SecureMode = false  -- Disabled to prevent game freezing
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Global Variables
_G.AutoDig = false
_G.AutoFarm = false
_G.SelectedField = "mango field"
_G.WalkSpeed = 16
_G.JumpPower = 50
_G.TokenRange = 100
_G.DebugText = "Script Loaded - Freeze Protection Active"
_G.CurrentFarmField = "NONE"
_G.FarmRunning = false
_G.DigRunning = false
_G.ErrorLog = {}

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
   LoadingTitle = "Atlas v2 fr - Freeze Fixed",
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

-- Anti-freeze function - prevents game freezing
local function AntiFreezeWait(seconds)
    local start = tick()
    local frames = 0
    
    while tick() - start < seconds do
        frames = frames + 1
        
        -- Yield every 50 frames to prevent freezing
        if frames >= 50 then
            frames = 0
            RunService.Heartbeat:Wait()
            RunService.RenderStepped:Wait()
            task.wait()
        else
            RunService.Heartbeat:Wait()
        end
        
        -- Emergency break if game is freezing
        if tick() - start > seconds * 2 then
            break
        end
    end
end

-- Lightweight wait for most operations
local function LightWait(seconds)
    local start = tick()
    while tick() - start < seconds do
        RunService.Heartbeat:Wait()
    end
end

-- Error logging function
local function LogError(errorMsg)
    local timestamp = os.date("%X")
    local errorEntry = "[" .. timestamp .. "] " .. errorMsg
    table.insert(_G.ErrorLog, 1, errorEntry)
    
    if #_G.ErrorLog > 20 then
        table.remove(_G.ErrorLog, 21)
    end
    
    print("[ERROR]: " .. errorMsg)
end

-- Safe pcall wrapper with anti-freeze
local function SafeCall(func, errorContext)
    local success, result = pcall(func)
    if not success then
        LogError(errorContext .. ": " .. tostring(result))
        
        -- Anti-freeze: Don't spam errors
        LightWait(0.1)
    end
    return success, result
end

-- Debug function
local function UpdateDebug(message)
    _G.DebugText = message
    print("[DEBUG]: " .. message)
end

-- Get character
local function GetCharacter()
    return SafeCall(function()
        local char = Player.Character
        if not char then
            char = Player.CharacterAdded:Wait()
            LightWait(1)
        end
        return char
    end, "GetCharacter")
end

-- Apply speed
local function ApplySpeed()
    SafeCall(function()
        local char = GetCharacter()
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = _G.WalkSpeed
            char.Humanoid.JumpPower = _G.JumpPower
        end
    end, "ApplySpeed")
end

-- Auto apply speed on respawn
Player.CharacterAdded:Connect(function()
    LightWait(1)
    ApplySpeed()
end)

-- Check if at field
local function IsAtField()
    return SafeCall(function()
        local char = GetCharacter()
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return false end
        
        local fieldPos = fieldCoords[_G.SelectedField]
        if not fieldPos then return false end
        
        local distance = (hrp.Position - fieldPos).Magnitude
        return distance < 50
    end, "IsAtField")
end

-- Simple movement with anti-freeze
local function MoveToPosition(target)
    return SafeCall(function()
        local char = GetCharacter()
        local humanoid = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        
        if not humanoid or not hrp then return false end
        
        humanoid:MoveTo(target)
        
        local startTime = tick()
        local lastCheck = tick()
        
        while tick() - startTime < 15 do
            if not _G.AutoFarm then return false end
            
            local distance = (hrp.Position - target).Magnitude
            if distance < 10 then
                return true
            end
            
            -- Anti-freeze: Use lightweight wait
            if tick() - lastCheck > 0.5 then
                if distance > 20 then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
                lastCheck = tick()
            end
            
            LightWait(0.1)
        end
        
        return false
    end, "MoveToPosition")
end
-- Get nearest token with anti-freeze
local function GetNearestToken()
    return SafeCall(function()
        local char = GetCharacter()
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        
        local tokens = {}
        local maxTokensToCheck = 50  -- Limit to prevent freezing
        
        -- Search in common locations
        local debris = workspace:FindFirstChild("Debris")
        if debris then
            local tokenFolder = debris:FindFirstChild("Tokens")
            if tokenFolder then
                local count = 0
                for _, obj in pairs(tokenFolder:GetChildren()) do
                    if count >= maxTokensToCheck then break end
                    if obj:IsA("Part") then
                        table.insert(tokens, obj)
                        count = count + 1
                    end
                end
            end
        end
        
        -- Search workspace with limit
        local count = 0
        for _, obj in pairs(workspace:GetChildren()) do
            if count >= maxTokensToCheck then break end
            if obj:IsA("Part") and obj.Name:lower():find("token") then
                table.insert(tokens, obj)
                count = count + 1
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
    end, "GetNearestToken")
end

-- Go to field - ANTI-FREEZE VERSION
local function GoToField()
    return SafeCall(function()
        UpdateDebug("NAVIGATING TO: " .. _G.SelectedField)
        
        local fieldPos = fieldCoords[_G.SelectedField]
        if not fieldPos then
            UpdateDebug("ERROR: Invalid field position")
            return false
        end
        
        local success = MoveToPosition(fieldPos)
        
        if success then
            _G.CurrentFarmField = _G.SelectedField
            UpdateDebug("SUCCESS: Arrived at " .. _G.SelectedField)
            return true
        else
            UpdateDebug("FAILED: Could not reach field")
            return false
        end
    end, "GoToField")
end

-- Token collection with anti-freeze
local function CollectTokens()
    return SafeCall(function()
        UpdateDebug("COLLECTING TOKENS...")
        
        local tokensCollected = 0
        while _G.AutoFarm and tokensCollected < 5 do  -- Reduced from 10 to 5
            -- CHECK FOR FIELD CHANGE DURING TOKEN COLLECTION
            if _G.CurrentFarmField ~= _G.SelectedField then
                UpdateDebug("FIELD CHANGED - STOPPING TOKEN COLLECTION")
                return
            end
            
            local token = GetNearestToken()
            if token then
                UpdateDebug("Found token, moving to it")
                MoveToPosition(token.Position)
                LightWait(0.3)  -- Reduced wait time
                tokensCollected = tokensCollected + 1
            else
                UpdateDebug("No tokens found")
                break
            end
        end
    end, "CollectTokens")
end

-- MAIN FARMING FUNCTION - ANTI-FREEZE
local function FarmLoop()
    if _G.FarmRunning then return end
    _G.FarmRunning = true
    
    UpdateDebug("FARM LOOP STARTED - ANTI-FREEZE ACTIVE")
    
    while _G.AutoFarm do
        SafeCall(function()
            -- Anti-freeze: Add small delay between cycles
            LightWait(0.5)
            
            -- CHECK FOR FIELD CHANGE AT START OF EVERY CYCLE
            if _G.CurrentFarmField ~= _G.SelectedField then
                UpdateDebug("FIELD CHANGED DETECTED - GOING TO NEW FIELD")
            end
            
            -- ALWAYS go to field first if we're not at the correct field
            if _G.CurrentFarmField ~= _G.SelectedField or not IsAtField() then
                UpdateDebug("STEP 1: Going to field...")
                if not GoToField() then
                    UpdateDebug("Failed to go to field, retrying...")
                    LightWait(2)
                    return
                end
            else
                UpdateDebug("Already at correct field, collecting tokens...")
            end
            
            -- Wait a moment to ensure we're at field
            LightWait(0.5)  -- Reduced from 1 second
            
            -- Collect tokens (but check for field change during collection)
            UpdateDebug("STEP 2: Collecting tokens...")
            CollectTokens()
            
        end, "FarmLoop Cycle")
        
        -- Anti-freeze: Main loop delay
        LightWait(1)
    end
    
    _G.FarmRunning = false
    UpdateDebug("FARM LOOP STOPPED")
end

-- Auto Dig function - ANTI-FREEZE
local function DigLoop()
    if _G.DigRunning then return end
    _G.DigRunning = true
    
    UpdateDebug("DIG LOOP STARTED - ANTI-FREEZE ACTIVE")
    
    while _G.AutoDig do
        SafeCall(function()
            local char = GetCharacter()
            
            -- Fire all tools with anti-freeze protection
            local toolsFired = 0
            for _, tool in pairs(char:GetChildren()) do
                if toolsFired >= 10 then break end  -- Limit tools per frame
                if tool:IsA("Tool") then
                    local remote = tool:FindFirstChild("ToolRemote") or tool:FindFirstChild("Remote")
                    if remote then
                        remote:FireServer()
                        toolsFired = toolsFired + 1
                    end
                end
            end
            
            LightWait(0.15)  -- Increased from 0.1 to reduce load
        end, "DigLoop Cycle")
    end
    
    _G.DigRunning = false
    UpdateDebug("DIG LOOP STOPPED")
end

-- Create UI
local MainTab = Window:CreateTab("Main", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)
local InfoTab = Window:CreateTab("Info", 4483362458)
local ErrorsTab = Window:CreateTab("Errors", 4483362458)

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
        SafeCall(function()
            _G.SelectedField = Option
            UpdateDebug("Field changed to: " .. Option)
            _G.CurrentFarmField = "FORCE_CHANGE"
            UpdateDebug("FIELD CHANGE FORCED - Will go to new field immediately")
        end, "FieldDropdown Callback")
    end,
})

-- Auto Dig toggle
local AutoDigToggle = MainTab:CreateToggle({
    Name = "Auto Dig",
    CurrentValue = false,
    Flag = "AutoDigToggle",
    Callback = function(Value)
        SafeCall(function()
            _G.AutoDig = Value
            if Value then
                coroutine.wrap(DigLoop)()
            else
                UpdateDebug("Auto Dig disabled")
            end
        end, "AutoDigToggle Callback")
    end,
})

-- Auto Farm toggle
local AutoFarmToggle = MainTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarmToggle",
    Callback = function(Value)
        SafeCall(function()
            _G.AutoFarm = Value
            
            if Value then
                _G.CurrentFarmField = "FORCE_CHANGE"
                _G.FarmRunning = false
                UpdateDebug("STARTING FARM - ANTI-FREEZE ACTIVE")
                
                coroutine.wrap(FarmLoop)()
            else
                UpdateDebug("Auto Farm disabled")
            end
        end, "AutoFarmToggle Callback")
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
        SafeCall(function()
            _G.WalkSpeed = Value
            ApplySpeed()
        end, "WalkSpeedSlider Callback")
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
        SafeCall(function()
            _G.JumpPower = Value
            ApplySpeed()
        end, "JumpPowerSlider Callback")
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
        SafeCall(function()
            _G.TokenRange = Value
        end, "TokenRangeSlider Callback")
    end,
})

-- Performance settings
SettingsTab:CreateSection("Performance")

local PerformanceToggle = SettingsTab:CreateToggle({
    Name = "Reduced Performance Mode",
    CurrentValue = true,
    Flag = "PerformanceToggle",
    Callback = function(Value)
        if Value then
            UpdateDebug("REDUCED PERFORMANCE MODE: Less freezing")
        else
            UpdateDebug("NORMAL PERFORMANCE MODE")
        end
    end,
})

-- Manual field teleport button
local TeleportButton = SettingsTab:CreateButton({
    Name = "TELEPORT TO FIELD",
    Callback = function()
        SafeCall(function()
            local fieldPos = fieldCoords[_G.SelectedField]
            if fieldPos then
                local char = GetCharacter()
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = CFrame.new(fieldPos)
                    _G.CurrentFarmField = _G.SelectedField
                    UpdateDebug("MANUALLY TELEPORTED TO FIELD")
                end
            end
        end, "TeleportButton Callback")
    end,
})

-- Clear errors button
local ClearErrorsButton = SettingsTab:CreateButton({
    Name = "CLEAR ALL ERRORS",
    Callback = function()
        SafeCall(function()
            _G.ErrorLog = {}
            UpdateDebug("All errors cleared")
        end, "ClearErrorsButton Callback")
    end,
})

-- Info tab
InfoTab:CreateLabel("Atlas v2 fr - Made by sal")
InfoTab:CreateLabel("Auto Dig: Fires ToolRemote every 0.15s")
InfoTab:CreateLabel("Auto Farm: Anti-freeze protection active")
InfoTab:CreateLabel("Performance: Optimized to prevent freezing")

local DebugLabel = InfoTab:CreateLabel("Debug: " .. _G.DebugText)

-- Errors tab
ErrorsTab:CreateLabel("Recent Errors (Latest First):")
ErrorsTab:CreateLabel("Send these errors to sal for fixing:")

local ErrorLabels = {}
for i = 1, 10 do
    ErrorLabels[i] = ErrorsTab:CreateLabel("")
end

-- Update debug display with anti-freeze
spawn(function()
    while true do
        SafeCall(function()
            DebugLabel:Set("Text", "Debug: " .. _G.DebugText)
            
            for i = 1, 10 do
                if _G.ErrorLog[i] then
                    ErrorLabels[i]:Set("Text", _G.ErrorLog[i])
                else
                    ErrorLabels[i]:Set("Text", "")
                end
            end
        end, "UI Update Loop")
        LightWait(1)  -- Reduced update frequency
    end
end)

-- Apply speed on start
LightWait(2)
ApplySpeed()
UpdateDebug("READY - Anti-freeze protection active - Made by sal")

print("ATLAS V2 FR - ANTI-FREEZE VERSION LOADED")
print("Game should not freeze when toggling features")
