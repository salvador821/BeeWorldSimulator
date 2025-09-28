-- Atlas v2 fr - Complete Rewrite
-- Made by sal

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Global Variables
_G.AutoDig = false
_G.AutoFarm = false
_G.SelectedField = "mango field"
_G.WalkSpeed = 16
_G.JumpPower = 50
_G.TokenRange = 100
_G.DebugText = "Script Loaded - Waiting for input..."
_G.CurrentFarmField = nil
_G.FarmTask = nil
_G.DigTask = nil
_G.IsMovingToField = false
_G.FieldCheckCounter = 0
_G.TokenCheckCounter = 0
_G.LastFieldPosition = nil
_G.PathfindingAttempts = 0
_G.MaxPathfindingAttempts = 5

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
   LoadingTitle = "Atlas v2 fr - Loading...",
   LoadingSubtitle = "made by sal",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "AtlasConfig",
      FileName = "Atlasv2"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false,
})

-- Services
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Player reference
local Player = Players.LocalPlayer

-- Debug logging function
local function UpdateDebug(message)
    _G.DebugText = message
    print("[Atlas Debug]: " .. message)
end

-- Safe wait function
local function SafeWait(seconds)
    local start = tick()
    while tick() - start < seconds do
        if not _G.AutoFarm and not _G.AutoDig then
            return false
        end
        RunService.Heartbeat:Wait()
    end
    return true
end

-- Character safety function
local function GetCharacter()
    local character = Player.Character
    if not character then
        UpdateDebug("Waiting for character to spawn...")
        character = Player.CharacterAdded:Wait()
        SafeWait(2) -- Wait for character to fully load
    end
    
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        
        if humanoid and hrp and humanoid.Health > 0 then
            return character, humanoid, hrp
        else
            UpdateDebug("Character not ready or dead, waiting...")
            SafeWait(3)
            return GetCharacter()
        end
    end
    
    return nil
end

-- Apply speed and jump power
local function ApplyCharacterStats()
    local success, result = pcall(function()
        local character, humanoid, hrp = GetCharacter()
        if character and humanoid then
            humanoid.WalkSpeed = _G.WalkSpeed
            humanoid.JumpPower = _G.JumpPower
            return true
        end
        return false
    end)
    
    if not success then
        UpdateDebug("Error applying character stats: " .. tostring(result))
    end
end

-- Auto-apply stats on character spawn
Player.CharacterAdded:Connect(function(character)
    SafeWait(2)
    ApplyCharacterStats()
end)

-- Apply on script start
task.spawn(function()
    SafeWait(3)
    ApplyCharacterStats()
end)

-- Enhanced pathfinding function
local function MoveToPosition(targetPosition, options)
    options = options or {}
    local maxRetries = options.maxRetries or 3
    local timeout = options.timeout or 8
    local purpose = options.purpose or "unknown"
    
    return pcall(function()
        local character, humanoid, hrp = GetCharacter()
        if not character then
            error("No character found")
        end
        
        UpdateDebug("Pathfinding to " .. purpose .. "...")
        
        local pathParams = {
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = true,
            AgentCanClimb = true,
            WaypointSpacing = 4,
        }
        
        local path = PathfindingService:CreatePath(pathParams)
        local computeSuccess = pcall(function()
            path:ComputeAsync(hrp.Position, targetPosition)
        end)
        
        if not computeSuccess then
            UpdateDebug("Path computation failed, using direct movement")
            humanoid:MoveTo(targetPosition)
            local reached = humanoid.MoveToFinished:Wait(timeout)
            return reached
        end
        
        if path.Status == Enum.PathStatus.Success then
            local waypoints = path:GetWaypoints()
            UpdateDebug("Path found with " .. #waypoints .. " waypoints for " .. purpose)
            
            for i, waypoint in ipairs(waypoints) do
                if not _G.AutoFarm then break end
                
                -- Jump if needed
                if waypoint.Action == Enum.PathWaypointAction.Jump then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    SafeWait(0.2)
                end
                
                -- Move to waypoint with retries
                local reached = false
                local tries = 0
                
                while not reached and tries < maxRetries do
                    humanoid:MoveTo(waypoint.Position)
                    reached = humanoid.MoveToFinished:Wait(timeout)
                    
                    if not reached then
                        tries = tries + 1
                        UpdateDebug("Stuck at waypoint " .. i .. ", retry " .. tries .. "/" .. maxRetries)
                        
                        -- Try to unstuck
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        SafeWait(0.5)
                        
                        -- Small random movement to unstuck
                        local randomOffset = Vector3.new(
                            math.random(-2, 2),
                            0,
                            math.random(-2, 2)
                        )
                        humanoid:MoveTo(hrp.Position + randomOffset)
                        humanoid.MoveToFinished:Wait(1)
                    end
                end
                
                if not reached then
                    UpdateDebug("Failed to reach waypoint " .. i .. ", continuing to next")
                end
            end
            
            return true
        else
            UpdateDebug("No path found for " .. purpose .. ", using direct movement")
            humanoid:MoveTo(targetPosition)
            local reached = humanoid.MoveToFinished:Wait(timeout)
            return reached
        end
    end)
end

-- Check if at field
local function IsAtField()
    local character, humanoid, hrp = GetCharacter()
    if not character then return false end
    
    local fieldPos = fieldCoords[_G.SelectedField]
    if not fieldPos then return false end
    
    local distance = (hrp.Position - fieldPos).Magnitude
    return distance <= 50
end

-- Get nearest token with improved logic
local function GetNearestToken()
    return pcall(function()
        local character, humanoid, hrp = GetCharacter()
        if not character then return nil end
        
        local tokensFolder = workspace:FindFirstChild("Debris")
        if not tokensFolder then
            tokensFolder = workspace:FindFirstChild("Tokens")
        end
        
        if tokensFolder then
            tokensFolder = tokensFolder:FindFirstChild("Tokens") or tokensFolder
        end
        
        if not tokensFolder then
            UpdateDebug("No tokens folder found in workspace")
            return nil
        end
        
        local nearestToken = nil
        local shortestDistance = math.huge
        
        for _, token in pairs(tokensFolder:GetChildren()) do
            if not _G.AutoFarm then break end
            
            if token:IsA("Part") or token:IsA("MeshPart") then
                local hasToken = token:FindFirstChild("Token") or token.Name:lower():find("token")
                local collecting = token:FindFirstChild("Collecting")
                
                if hasToken and (not collecting or not collecting.Value) then
                    local distance = (token.Position - hrp.Position).Magnitude
                    
                    if distance < _G.TokenRange and distance < shortestDistance then
                        shortestDistance = distance
                        nearestToken = token
                    end
                end
            end
        end
        
        if nearestToken then
            UpdateDebug("Found token " .. math.floor(shortestDistance) .. " studs away")
            return nearestToken
        else
            UpdateDebug("No collectible tokens found in range")
            return nil
        end
    end)
end

-- Field navigation system
local function NavigateToField()
    return pcall(function()
        _G.IsMovingToField = true
        _G.PathfindingAttempts = 0
        
        local fieldPos = fieldCoords[_G.SelectedField]
        if not fieldPos then
            UpdateDebug("Invalid field selected")
            return false
        end
        
        UpdateDebug("Starting navigation to " .. _G.SelectedField)
        
        while _G.AutoFarm and _G.PathfindingAttempts < _G.MaxPathfindingAttempts do
            if IsAtField() then
                UpdateDebug("Already at " .. _G.SelectedField)
                _G.CurrentFarmField = _G.SelectedField
                _G.IsMovingToField = false
                return true
            end
            
            _G.PathfindingAttempts = _G.PathfindingAttempts + 1
            UpdateDebug("Pathfinding attempt " .. _G.PathfindingAttempts .. "/" .. _G.MaxPathfindingAttempts)
            
            local success, reached = MoveToPosition(fieldPos, {
                purpose = _G.SelectedField,
                maxRetries = 3,
                timeout = 10
            })
            
            if success and reached then
                UpdateDebug("Successfully reached " .. _G.SelectedField)
                _G.CurrentFarmField = _G.SelectedField
                _G.IsMovingToField = false
                return true
            else
                UpdateDebug("Failed to reach field, retrying...")
                SafeWait(2)
            end
        end
        
        _G.IsMovingToField = false
        UpdateDebug("Failed to navigate to field after " .. _G.MaxPathfindingAttempts .. " attempts")
        return false
    end)
end
-- Token collection system
local function CollectTokens()
    return pcall(function()
        UpdateDebug("Starting token collection in " .. _G.SelectedField)
        
        local tokensCollected = 0
        local maxTokensPerCycle = 10
        
        while _G.AutoFarm and tokensCollected < maxTokensPerCycle do
            -- Check if we're still at the correct field
            if _G.CurrentFarmField ~= _G.SelectedField or not IsAtField() then
                UpdateDebug("Field changed or moved away, stopping token collection")
                break
            end
            
            local success, token = GetNearestToken()
            
            if success and token then
                UpdateDebug("Moving to collect token...")
                
                local collectSuccess, reached = MoveToPosition(token.Position, {
                    purpose = "token collection",
                    maxRetries = 2,
                    timeout = 5
                })
                
                if collectSuccess and reached then
                    tokensCollected = tokensCollected + 1
                    UpdateDebug("Collected token " .. tokensCollected .. "/" .. maxTokensPerCycle)
                    SafeWait(0.5) -- Small delay between token collections
                else
                    UpdateDebug("Failed to reach token, searching for next...")
                end
            else
                UpdateDebug("No tokens found, waiting...")
                if not SafeWait(2) then break end
            end
            
            if not SafeWait(0.5) then break end
        end
        
        UpdateDebug("Token collection cycle completed")
        return true
    end)
end

-- Main farming loop
local function StartFarming()
    if _G.FarmTask then
        task.cancel(_G.FarmTask)
        _G.FarmTask = nil
    end
    
    _G.FarmTask = task.spawn(function()
        UpdateDebug("Auto Farm started")
        
        while _G.AutoFarm do
            local farmingCycleSuccess = pcall(function()
                -- Phase 1: Navigate to selected field
                if _G.CurrentFarmField ~= _G.SelectedField or not IsAtField() then
                    UpdateDebug("Need to navigate to field: " .. _G.SelectedField)
                    local navSuccess = NavigateToField()
                    
                    if not navSuccess then
                        UpdateDebug("Field navigation failed, retrying in 5 seconds...")
                        if not SafeWait(5) then return end
                    end
                end
                
                -- Phase 2: Collect tokens at field
                if IsAtField() and _G.CurrentFarmField == _G.SelectedField then
                    UpdateDebug("At field, starting token collection...")
                    CollectTokens()
                else
                    UpdateDebug("Not at field, cannot collect tokens")
                end
                
                -- Phase 3: Field maintenance check
                _G.FieldCheckCounter = _G.FieldCheckCounter + 1
                if _G.FieldCheckCounter >= 10 then
                    _G.FieldCheckCounter = 0
                    UpdateDebug("Field maintenance check completed")
                end
                
                -- Small delay between farming cycles
                if not SafeWait(1) then return end
            end)
            
            if not farmingCycleSuccess then
                UpdateDebug("Error in farming cycle, continuing...")
                SafeWait(3)
            end
        end
        
        UpdateDebug("Auto Farm stopped")
        _G.FarmTask = nil
    end)
end

-- Auto Dig system
local function StartAutoDig()
    if _G.DigTask then
        task.cancel(_G.DigTask)
        _G.DigTask = nil
    end
    
    _G.DigTask = task.spawn(function()
        UpdateDebug("Auto Dig started")
        
        while _G.AutoDig do
            local digSuccess = pcall(function()
                local character = GetCharacter()
                if not character then return end
                
                local toolsFired = 0
                
                for _, item in ipairs(character:GetChildren()) do
                    if not _G.AutoDig then break end
                    
                    if item:IsA("Tool") then
                        local toolRemote = item:FindFirstChild("ToolRemote") or 
                                         item:FindFirstChild("Remote") or
                                         item:FindFirstChild("Activate")
                        
                        if toolRemote and toolRemote:IsA("RemoteEvent") then
                            local fireSuccess = pcall(function()
                                toolRemote:FireServer()
                            end)
                            
                            if fireSuccess then
                                toolsFired = toolsFired + 1
                            end
                        end
                    end
                end
                
                if toolsFired > 0 then
                    UpdateDebug("Fired " .. toolsFired .. " tool remotes")
                end
                
                if not SafeWait(0.1) then return end
            end)
            
            if not digSuccess then
                UpdateDebug("Error in auto dig, continuing...")
                SafeWait(1)
            end
        end
        
        UpdateDebug("Auto Dig stopped")
        _G.DigTask = nil
    end)
end

-- Create UI Tabs
local MainTab = Window:CreateTab("Main Features", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)
local InfoTab = Window:CreateTab("Information", 4483362458)

-- Field Selector Dropdown
local FieldDropdown = MainTab:CreateDropdown({
    Name = "Select Farming Field",
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
        UpdateDebug("Field changed to: " .. Option)
    end,
})

-- Auto Dig Toggle
local AutoDigToggle = MainTab:CreateToggle({
    Name = "Auto Dig",
    CurrentValue = false,
    Flag = "AutoDigToggle",
    Callback = function(Value)
        _G.AutoDig = Value
        if Value then
            StartAutoDig()
        else
            if _G.DigTask then
                task.cancel(_G.DigTask)
                _G.DigTask = nil
            end
            UpdateDebug("Auto Dig disabled")
        end
    end,
})

-- Auto Farm Toggle
local AutoFarmToggle = MainTab:CreateToggle({
    Name = "Auto Farm Tokens",
    CurrentValue = false,
    Flag = "AutoFarmToggle",
    Callback = function(Value)
        _G.AutoFarm = Value
        if Value then
            -- Reset field state to force navigation
            _G.CurrentFarmField = nil
            _G.PathfindingAttempts = 0
            StartFarming()
        else
            if _G.FarmTask then
                task.cancel(_G.FarmTask)
                _G.FarmTask = nil
            end
            _G.IsMovingToField = false
            UpdateDebug("Auto Farm disabled")
        end
    end,
})

-- Settings Section
SettingsTab:CreateSection("Character Settings")

-- Walk Speed Slider
local WalkSpeedSlider = SettingsTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 120},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 16,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        _G.WalkSpeed = Value
        ApplyCharacterStats()
        UpdateDebug("Walk speed set to: " .. Value)
    end,
})

-- Jump Power Slider
local JumpPowerSlider = SettingsTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 120},
    Increment = 1,
    Suffix = "Power",
    CurrentValue = 50,
    Flag = "JumpPowerSlider",
    Callback = function(Value)
        _G.JumpPower = Value
        ApplyCharacterStats()
        UpdateDebug("Jump power set to: " .. Value)
    end,
})

SettingsTab:CreateSection("Farming Settings")

-- Token Range Slider
local TokenRangeSlider = SettingsTab:CreateSlider({
    Name = "Token Detection Range",
    Range = {50, 500},
    Increment = 10,
    Suffix = "Studs",
    CurrentValue = 100,
    Flag = "TokenRangeSlider",
    Callback = function(Value)
        _G.TokenRange = Value
        UpdateDebug("Token range set to: " .. Value .. " studs")
    end,
})

-- Emergency Stop Button
local EmergencyStop = SettingsTab:CreateButton({
    Name = "EMERGENCY STOP",
    Callback = function()
        _G.AutoDig = false
        _G.AutoFarm = false
        
        if _G.DigTask then
            task.cancel(_G.DigTask)
            _G.DigTask = nil
        end
        
        if _G.FarmTask then
            task.cancel(_G.FarmTask)
            _G.FarmTask = nil
        end
        
        _G.IsMovingToField = false
        UpdateDebug("EMERGENCY STOP - All functions disabled")
        
        -- Reset character speed
        _G.WalkSpeed = 16
        _G.JumpPower = 50
        ApplyCharacterStats()
    end,
})

-- Information Tab
InfoTab:CreateSection("Script Information")
InfoTab:CreateLabel("Atlas v2 fr - Made by sal")
InfoTab:CreateLabel("Auto Dig: Fires all ToolRemotes every 0.1s")
InfoTab:CreateLabel("Auto Farm: Pathfinds to field then collects tokens")
InfoTab:CreateLabel("Field Selector: Choose where to farm")
InfoTab:CreateLabel("Token Range: How far to look for tokens")

-- Debug Section
InfoTab:CreateSection("Live Debug Information")
local DebugLabel = InfoTab:CreateLabel("Debug: " .. _G.DebugText)

-- Status monitor
InfoTab:CreateSection("Current Status")
local StatusLabel = InfoTab:CreateLabel("Status: Idle")
local FieldLabel = InfoTab:CreateLabel("Current Field: None")
local TokenLabel = InfoTab:CreateLabel("Token Range: " .. _G.TokenRange .. " studs")

-- Real-time status updates
task.spawn(function()
    while true do
        -- Update debug label
        DebugLabel:Set("Text", "Debug: " .. _G.DebugText)
        
        -- Update status
        local status = "Idle"
        if _G.AutoFarm and _G.IsMovingToField then
            status = "Moving to Field"
        elseif _G.AutoFarm then
            status = "Farming"
        elseif _G.AutoDig then
            status = "Auto Digging"
        end
        StatusLabel:Set("Text", "Status: " .. status)
        
        -- Update field info
        FieldLabel:Set("Text", "Current Field: " .. _G.SelectedField)
        
        -- Update token range
        TokenLabel:Set("Text", "Token Range: " .. _G.TokenRange .. " studs")
        
        SafeWait(0.5)
    end
end)

-- Auto-save configuration
task.spawn(function()
    while true do
        SafeWait(30)
        Rayfield:LoadConfiguration()
        UpdateDebug("Configuration auto-saved")
    end
end)

-- Initial setup complete
UpdateDebug("Atlas v2 fr loaded successfully!")
UpdateDebug("Select a field and enable Auto Farm to start")

-- Load saved configuration
Rayfield:LoadConfiguration()

-- Final initialization
task.spawn(function()
    SafeWait(2)
    ApplyCharacterStats()
    UpdateDebug("Ready to use - Made by sal")
end)

return "Atlas v2 fr - Script loaded successfully!"
