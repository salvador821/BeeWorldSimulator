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
_G.TweenSpeed = 50
_G.WalkSpeed = 16
_G.JumpPower = 50
_G.DebugText = "Waiting..."

-- Main Tab
local MainTab = Window:CreateTab("Main Features", 4483362458)

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- Tween Speed Slider
local TweenSpeedSlider = SettingsTab:CreateSlider({
    Name = "Tween Speed",
    Range = {10, 250},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = 50,
    Flag = "TweenSpeedSlider",
    Callback = function(Value)
        _G.TweenSpeed = Value
    end,
})

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
    wait(1) -- Wait for humanoid to load
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
           
           -- Store the field when we start farming
           local currentFarmField = _G.SelectedField
           
           -- Function to tween to field
           local function tweenToField()
               if _G.SelectedField and fieldCoords[_G.SelectedField] then
                   local player = game.Players.LocalPlayer
                   local character = player.Character
                   if not character then
                       character = player.CharacterAdded:Wait()
                   end
                   local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
                   
                   -- Calculate duration based on distance and speed
                   local distance = (humanoidRootPart.Position - fieldCoords[_G.SelectedField]).Magnitude
                   local duration = distance / _G.TweenSpeed
                   
                   _G.DebugText = "Tweening to " .. _G.SelectedField .. " (" .. math.floor(duration) .. "s)"
                   
                   local TweenService = game:GetService("TweenService")
                   local tweenInfo = TweenInfo.new(
                       duration,
                       Enum.EasingStyle.Linear,
                       Enum.EasingDirection.Out,
                       0,
                       false,
                       0
                   )
                   
                   local tween = TweenService:Create(
                       humanoidRootPart,
                       tweenInfo,
                       {CFrame = CFrame.new(fieldCoords[_G.SelectedField])}
                   )
                   
                   tween:Play()
                   tween.Completed:Wait()
                   _G.DebugText = "Arrived at " .. _G.SelectedField
                   return true
               end
               return false
           end
           
           -- Tween to field first
           tweenToField()
           
           -- After tween completes, start pathfinding
           local Players = game:GetService("Players")
           local PathfindingService = game:GetService("PathfindingService")
           local RunService = game:GetService("RunService")

           local player = Players.LocalPlayer
           local character = player.Character or player.CharacterAdded:Wait()
           local humanoid = character:WaitForChild("Humanoid")
           local hrp = character:WaitForChild("HumanoidRootPart")

           local pathParams = {
               AgentRadius = 2,
               AgentHeight = 5,
               AgentCanJump = true,
               AgentCanClimb = true,
               WaypointSpacing = 3,
               Costs = {
                   Water = 20,
               }
           }

           local function getNearestToken()
               local closestToken = nil
               local shortestDistance = math.huge

               local tokensFolder = workspace:FindFirstChild("Debris") and workspace.Debris:FindFirstChild("Tokens")
               if not tokensFolder then 
                   _G.DebugText = "No Tokens folder found"
                   return nil 
               end

               for _, token in pairs(tokensFolder:GetChildren()) do
                   if token:IsA("BasePart") and token:FindFirstChild("Token") and token:FindFirstChild("Collecting") and not token.Collecting.Value then
                       local distance = (token.Position - hrp.Position).Magnitude
                       if distance < shortestDistance then
                           shortestDistance = distance
                           closestToken = token
                       end
                   end
               end

               return closestToken, shortestDistance
           end

           local function moveToTarget(target)
               local path = PathfindingService:CreatePath(pathParams)
               path:ComputeAsync(hrp.Position, target.Position)
               
               if path.Status == Enum.PathStatus.Success then
                   local waypoints = path:GetWaypoints()
                   
                   local blockedConnection
                   blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
                       blockedConnection:Disconnect()
                       moveToTarget(target)
                   end)
                   
                   for i, waypoint in ipairs(waypoints) do
                       humanoid:MoveTo(waypoint.Position)
                       if waypoint.Action == Enum.PathWaypointAction.Jump then
                           humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                       end
                       
                       local reached = humanoid.MoveToFinished:Wait(8)
                       if not reached then
                           blockedConnection:Disconnect()
                           moveToTarget(target)
                           return
                       end
                   end
                   blockedConnection:Disconnect()
               else
                   _G.DebugText = "No path found, using direct MoveTo"
                   humanoid:MoveTo(target.Position)
                   humanoid.MoveToFinished:Wait()
               end
           end

           task.spawn(function()
               while _G.AutoFarm do
                   pcall(function()
                       -- Check if field changed mid-farming
                       if _G.SelectedField ~= currentFarmField then
                           _G.DebugText = "Field changed! Tweening to new field..."
                           currentFarmField = _G.SelectedField
                           tweenToField()
                       end
                       
                       local token, dist = getNearestToken()
                       if token then
                           _G.DebugText = "Moving to token (" .. math.floor(dist) .. " studs away)"
                           if dist > 5 then
                               moveToTarget(token)
                           else
                               _G.DebugText = "Collecting token..."
                           end
                       else
                           _G.DebugText = "No tokens found"
                       end
                       task.wait(0.1)
                   end)
               end
           end)
       else
           _G.AutoFarm = false
           _G.DebugText = "Auto Farm Stopped"
       end
   end,
})

-- Info Tab
local InfoTab = Window:CreateTab("Information", 4483362458)

InfoTab:CreateLabel("Auto Dig: Fires ToolRemote every 0.1 seconds")
InfoTab:CreateLabel("Auto Farm: Tweens to selected field then collects tokens")
InfoTab:CreateLabel("Debug: " .. _G.DebugText)

-- Update debug label every second
task.spawn(function()
    while task.wait(1) do
        if InfoTab then
            -- Refresh the debug label
            for i, v in pairs(InfoTab:GetChildren()) do
                if v.Name == "TextLabel" and string.find(v.Text, "Debug:") then
                    v:Set("Text", "Debug: " .. _G.DebugText)
                end
            end
        end
    end
end)

Rayfield:LoadConfiguration()
