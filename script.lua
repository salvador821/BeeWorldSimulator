-- Rayfield Interface Setup
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Atlas v2 fr",
   LoadingTitle = "Atlas v2 fr",
   LoadingSubtitle = "made by sal",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "Atlasv2"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false,
})

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

-- Global variables
_G.AutoDig = false
_G.AutoFarm = false
_G.SelectedField = "mango field"
_G.WalkSpeed = 16
_G.JumpPower = 50
_G.TokenRange = 100
_G.DebugText = "Waiting..."
_G.CurrentFarmField = nil

-- Main Tab
local MainTab = Window:CreateTab("Main Features", 4483362458)

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", 4483362458)

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
        applySpeed()
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
        applySpeed()
    end,
})

-- Token Range Slider
local TokenRangeSlider = SettingsTab:CreateSlider({
    Name = "Token Range Limit",
    Range = {50, 500},
    Increment = 10,
    Suffix = "Studs",
    CurrentValue = 100,
    Flag = "TokenRangeSlider",
    Callback = function(Value)
        _G.TokenRange = Value
    end,
})

-- Function to apply speed and jump power
function applySpeed()
    local player = game.Players.LocalPlayer
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = _G.WalkSpeed
            humanoid.JumpPower = _G.JumpPower
        end
    end
end

-- Apply speed on character spawn
game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    wait(1)
    applySpeed()
end)

-- Apply speed on startup
if game.Players.LocalPlayer.Character then
    applySpeed()
end

-- Field Selector Dropdown
local FieldDropdown = MainTab:CreateDropdown({
    Name = "Select Field",
    Options = {
        "mango field",
        "blueberry field", 
        "daisy field",
        "cactus field",
        "strawberry field",
        "apple field",
        "lemon field",
        "grape field",
        "watermelon field",
        "forest field",
        "pear field",
        "mushroom field",
        "clover field",
        "bamboo field",
        "glitch field",
        "cave field",
        "mountain field"
    },
    CurrentOption = "mango field",
    Flag = "FieldDropdown",
    Callback = function(Option)
        _G.SelectedField = Option
        _G.DebugText = "Field changed to: " .. Option
    end,
})

-- Pathfinding function to move to a position
local function moveToPosition(targetPosition)
    local PathfindingService = game:GetService("PathfindingService")
    local player = game.Players.LocalPlayer
    local character = player.Character
    if not character then
        character = player.CharacterAdded:Wait()
    end
    local humanoid = character:WaitForChild("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")
    
    local pathParams = {
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = true,
        WaypointSpacing = 4,
    }
    
    local path = PathfindingService:CreatePath(pathParams)
    path:ComputeAsync(hrp.Position, targetPosition)
    
    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        _G.DebugText = "Path found with " .. #waypoints .. " waypoints"
        
        for i, waypoint in ipairs(waypoints) do
            if not _G.AutoFarm then break end
            
            humanoid:MoveTo(waypoint.Position)
            
            if waypoint.Action == Enum.PathWaypointAction.Jump then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
            
            local reached = humanoid.MoveToFinished:Wait(5)
            if not reached then
                _G.DebugText = "Stuck, recomputing path..."
                return moveToPosition(targetPosition)
            end
        end
        return true
    else
        _G.DebugText = "No path found, using direct movement"
        humanoid:MoveTo(targetPosition)
        humanoid.MoveToFinished:Wait(5)
        return true
    end
end

-- Auto Dig Section
local AutoDigToggle = MainTab:CreateToggle({
   Name = "Auto Dig",
   CurrentValue = false,
   Flag = "AutoDigToggle",
   Callback = function(Value)
       if Value then
           _G.AutoDig = true
           _G.DebugText = "Auto Dig Started"
           while _G.AutoDig and task.wait(0.1) do
               pcall(function()
                   local player = game:GetService("Players").LocalPlayer
                   local character = player.Character or player.CharacterAdded:Wait()
                   
                   for _, item in ipairs(character:GetChildren()) do
                       if item:IsA("Tool") and item:FindFirstChild("ToolRemote") then
                           item.ToolRemote:FireServer()
                       end
                   end
               end)
           end
           _G.DebugText = "Auto Dig Stopped"
       else
           _G.AutoDig = false
       end
   end,
})

-- Auto Farm Section
local AutoFarmToggle = MainTab:CreateToggle({
   Name = "Auto Farm Tokens",
   CurrentValue = false,
   Flag = "AutoFarmToggle",
   Callback = function(Value)
       if Value then
           _G.AutoFarm = true
           _G.DebugText = "Auto Farm Started"
           
           -- Start the main farming loop
           task.spawn(function()
               while _G.AutoFarm do
                   pcall(function()
                       local player = game.Players.LocalPlayer
                       local character = player.Character
                       if not character then
                           character = player.CharacterAdded:Wait()
                       end
                       local hrp = character:WaitForChild("HumanoidRootPart")
                       local humanoid = character:WaitForChild("Humanoid")
                       
                       -- Check if we need to pathfind to field
                       if _G.CurrentFarmField ~= _G.SelectedField then
                           _G.DebugText = "Pathfinding to " .. _G.SelectedField
                           local fieldPos = fieldCoords[_G.SelectedField]
                           
                           if moveToPosition(fieldPos) then
                               _G.CurrentFarmField = _G.SelectedField
                               _G.DebugText = "Arrived at " .. _G.SelectedField
                           end
                       end
                       
                       -- Check if we're at the field (close enough)
                       local fieldPos = fieldCoords[_G.SelectedField]
                       local distanceToField = (hrp.Position - fieldPos).Magnitude
                       
                       if distanceToField > 50 then
                           _G.DebugText = "Too far from field, pathfinding again..."
                           if moveToPosition(fieldPos) then
                               _G.DebugText = "Back at field, searching for tokens..."
                           end
                       else
                           _G.DebugText = "At field, searching for tokens..."
                           
                           -- Token collection logic
                           local tokensFolder = workspace:FindFirstChild("Debris") and workspace.Debris:FindFirstChild("Tokens")
                           if tokensFolder then
                               local nearestToken = nil
                               local shortestDistance = math.huge
                               
                               for _, token in pairs(tokensFolder:GetChildren()) do
                                   if token:IsA("BasePart") and token:FindFirstChild("Token") then
                                       local collecting = token:FindFirstChild("Collecting")
                                       if collecting and not collecting.Value then
                                           local distance = (token.Position - hrp.Position).Magnitude
                                           
                                           -- Only consider tokens within range
                                           if distance < _G.TokenRange and distance < shortestDistance then
                                               shortestDistance = distance
                                               nearestToken = token
                                           end
                                       end
                                   end
                               end
                               
                               if nearestToken then
                                   _G.DebugText = "Moving to token (" .. math.floor(shortestDistance) .. " studs)"
                                   
                                   -- Use pathfinding to move to token
                                   if moveToPosition(nearestToken.Position) then
                                       _G.DebugText = "Reached token position"
                                   end
                               else
                                   _G.DebugText = "No tokens found in range (" .. _G.TokenRange .. " studs)"
                                   task.wait(1)
                               end
                           else
                               _G.DebugText = "No Tokens folder found"
                               task.wait(1)
                           end
                       end
                   end)
                   task.wait(0.5)
               end
           end)
       else
           _G.AutoFarm = false
           _G.CurrentFarmField = nil
           _G.DebugText = "Auto Farm Stopped"
       end
   end,
})

-- Info Tab
local InfoTab = Window:CreateTab("Information", 4483362458)

local DebugLabel = InfoTab:CreateLabel("Debug: " .. _G.DebugText)
InfoTab:CreateLabel("Auto Dig: Fires ToolRemote every 0.1 seconds")
InfoTab:CreateLabel("Auto Farm: Pathfinds to field then collects tokens")

-- Update debug label every second
task.spawn(function()
    while task.wait(0.5) do
        DebugLabel:Set("Text", "Debug: " .. _G.DebugText)
    end
end)

Rayfield:LoadConfiguration()
