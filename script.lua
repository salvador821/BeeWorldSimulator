-- Atlas v2 fr - SECURE MODE ADDED
-- Made by sal

-- Enable Secure Mode to prevent UI freezing
getgenv().SecureMode = true
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Global Variables
_G.AutoDig = false
_G.AutoFarm = false
_G.SelectedField = "mango field"
_G.WalkSpeed = 16
_G.JumpPower = 50
_G.TokenRange = 100
_G.DebugText = "Script Loaded - Secure Mode Enabled"
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
   LoadingTitle = "Atlas v2 fr - Secure Mode",
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

-- Error logging function
local function LogError(errorMsg)
    local timestamp = os.date("%X")
    local errorEntry = "[" .. timestamp .. "] " .. errorMsg
    table.insert(_G.ErrorLog, 1, errorEntry) -- Add to beginning of table
    
    -- Keep only last 20 errors
    if #_G.ErrorLog > 20 then
        table.remove(_G.ErrorLog, 21)
    end
    
    print("[ERROR]: " .. errorMsg)
end

-- Safe pcall wrapper
local function SafeCall(func, errorContext)
    local success, result = pcall(func)
    if not success then
        LogError(errorContext .. ": " .. tostring(result))
    end
    return success, result
end

-- Simple heartbeat wait
local function Wait(seconds)
    local start = tick()
    while tick() - start < seconds do
        RunService.Heartbeat:Wait()
    end
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
            Wait(1)
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
    Wait(1)
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

-- Simple movement
local function MoveToPosition(target)
    return SafeCall(function()
        local char = GetCharacter()
        local humanoid = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        
        if not humanoid or not hrp then return false end
        
        humanoid:MoveTo(target)
        
        local startTime = tick()
        while tick() - startTime < 15 do
            if not _G.AutoFarm then return false end
            
            local distance = (hrp.Position - target).Magnitude
            if distance < 10 then
                return true
            end
            
            -- Check if stuck and jump
            if tick() - startTime > 5 and distance > 20 then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
            
            RunService.Heartbeat:Wait()
        end
        
        return false
    end, "MoveToPosition")
end

-- Get nearest token
local function GetNearestToken()
    return SafeCall(function()
        local char = GetCharacter()
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        
        local tokens = {}
        
        -- Search in common locations
        local debris = workspace:FindFirstChild("Debris")
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
            if obj:IsA("Part") and obj.Name:lower():find("token") then
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
    end, "GetNearestToken")
end

-- Go to field - SIMPLE AND RELIABLE
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
-- Token collection
local function CollectTokens()
    return SafeCall(function()
        UpdateDebug("COLLECTING TOKENS...")
        
        local tokensCollected = 0
        while _G.AutoFarm and tokensCollected < 10 do
            -- CHECK FOR FIELD CHANGE DURING TOKEN COLLECTION
            if _G.CurrentFarmField ~= _G.SelectedField then
                UpdateDebug("FIELD CHANGED - STOPPING TOKEN COLLECTION")
                return
            end
            
            local token = GetNearestToken()
            if token then
                UpdateDebug("Found token, moving to it")
                MoveToPosition(token.Position)
                Wait(0.5)
                tokensCollected = tokensCollected + 1
            else
                UpdateDebug("No tokens found")
                break
            end
        end
    end, "CollectTokens")
end

-- MAIN FARMING FUNCTION - FIXED FIELD SWITCHING
local function FarmLoop()
    if _G.FarmRunning then return end
    _G.FarmRunning = true
    
    UpdateDebug("FARM LOOP STARTED")
    
    while _G.AutoFarm do
        SafeCall(function()
            -- CHECK FOR FIELD CHANGE AT START OF EVERY CYCLE
            if _G.CurrentFarmField ~= _G.SelectedField then
                UpdateDebug("FIELD CHANGED DETECTED - GOING TO NEW FIELD")
            end
            
            -- ALWAYS go to field first if we're not at the correct field
            if _G.CurrentFarmField ~= _G.SelectedField or not IsAtField() then
                UpdateDebug("STEP 1: Going to field...")
                if not GoToField() then
                    UpdateDebug("Failed to go to field, retrying...")
                    Wait(2)
                    return
                end
            else
                UpdateDebug("Already at correct field, collecting tokens...")
            end
            
            -- Wait a moment to ensure we're at field
            Wait(1)
            
            -- Collect tokens (but check for field change during collection)
            UpdateDebug("STEP 2: Collecting tokens...")
            CollectTokens()
            
            -- Small delay before next cycle
            Wait(1)
        end, "FarmLoop Cycle")
    end
    
    _G.FarmRunning = false
    UpdateDebug("FARM LOOP STOPPED")
end

-- Auto Dig function
local function DigLoop()
    if _G.DigRunning then return end
    _G.DigRunning = true
    
    UpdateDebug("DIG LOOP STARTED")
    
    while _G.AutoDig do
        SafeCall(function()
            local char = GetCharacter()
            
            -- Fire all tools
            for _, tool in pairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    local remote = tool:FindFirstChild("ToolRemote") or tool:FindFirstChild("Remote")
                    if remote then
                        remote:FireServer()
                    end
                end
            end
            
            Wait(0.1)
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

-- Field dropdown - FIXED CALLBACK
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
            -- FORCE FIELD CHANGE - This is the key fix
            _G.CurrentFarmField = "FORCE_CHANGE"
            UpdateDebug("FIELD CHANGE FORCED - Will go to new field immediately")
        end, "FieldDropdown Callback")
    end,
})

-- Auto Dig toggle - FIXED CALLBACK
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

-- Auto Farm toggle - FIXED CALLBACK
local AutoFarmToggle = MainTab:CreateToggle({
    Name = "Auto Farm",
    CurrentValue = false,
    Flag = "AutoFarmToggle",
    Callback = function(Value)
        SafeCall(function()
            _G.AutoFarm = Value
            
            if Value then
                -- RESET FIELD STATE - THIS IS THE KEY FIX
                _G.CurrentFarmField = "FORCE_CHANGE"
                _G.FarmRunning = false
                UpdateDebug("STARTING FARM - FIELD RESET")
                
                -- Start farm loop
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

-- Force field change button
local ForceFieldButton = SettingsTab:CreateButton({
    Name = "FORCE FIELD CHANGE",
    Callback = function()
        SafeCall(function()
            _G.CurrentFarmField = "FORCE_CHANGE"
            UpdateDebug("FIELD CHANGE FORCED - Will go to new field immediately")
        end, "ForceFieldButton Callback")
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
InfoTab:CreateLabel("Auto Dig: Fires ToolRemote every 0.1s")
InfoTab:CreateLabel("Auto Farm: Goes to field and collects tokens")
InfoTab:CreateLabel("Current Field: " .. _G.SelectedField)
InfoTab:CreateLabel("Secure Mode: Enabled - Anti-freeze protection")

local DebugLabel = InfoTab:CreateLabel("Debug: " .. _G.DebugText)

-- Errors tab
ErrorsTab:CreateLabel("Recent Errors (Latest First):")
ErrorsTab:CreateLabel("Send these errors to sal for fixing:")

local ErrorLabels = {}
for i = 1, 10 do
    ErrorLabels[i] = ErrorsTab:CreateLabel("")
end

-- Update debug display
spawn(function()
    while true do
        SafeCall(function()
            DebugLabel:Set("Text", "Debug: " .. _G.DebugText)
            
            -- Update error labels
            for i = 1, 10 do
                if _G.ErrorLog[i] then
                    ErrorLabels[i]:Set("Text", _G.ErrorLog[i])
                else
                    ErrorLabels[i]:Set("Text", "")
                end
            end
        end, "UI Update Loop")
        Wait(0.5)
    end
end)

-- Apply speed on start
Wait(2)
ApplySpeed()
UpdateDebug("READY - Secure Mode Enabled - Made by sal")

print("ATLAS V2 FR - SECURE MODE ENABLED")
print("UI freezing should be fixed now")
