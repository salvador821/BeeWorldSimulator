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

-- Main Tab
local MainTab = Window:CreateTab("Main Features", 4483362458)

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
    end,
})

-- Go to Field Button
local GoToFieldButton = MainTab:CreateButton({
    Name = "Go to Selected Field",
    Callback = function()
        if _G.SelectedField and fieldCoords[_G.SelectedField] then
            local player = game.Players.LocalPlayer
            local character = player.Character or player.CharacterAdded:Wait()
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            
            -- Tween to the field coordinates
            local tweenInfo = TweenInfo.new(10, Enum.EasingStyle.Linear)
            local tween = game:GetService("TweenService"):Create(humanoidRootPart, tweenInfo, {Position = fieldCoords[_G.SelectedField]})
            tween:Play()
        end
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
               if not tokensFolder then return nil end

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
                   warn("No path found, using direct MoveTo.")
                   humanoid:MoveTo(target.Position)
                   humanoid.MoveToFinished:Wait()
               end
           end

           task.spawn(function()
               while _G.AutoFarm do
                   pcall(function()
                       local token, dist = getNearestToken()
                       if token then
                           if dist > 5 then
                               moveToTarget(token)
                           end
                       end
                       task.wait(0.1)
                   end)
               end
           end)
       else
           _G.AutoFarm = false
       end
   end,
})

-- Info Tab
local InfoTab = Window:CreateTab("Information", 4483362458)

InfoTab:CreateLabel("Auto Dig: Fires ToolRemote every 0.1 seconds")
InfoTab:CreateLabel("Auto Farm: collects tokens and goes to convert(IN THE WORKS)")
InfoTab:CreateLabel("Field Selector: Choose a field and click 'Go to Selected Field'")

-- Initialize global variables
_G.AutoDig = false
_G.AutoFarm = false
_G.SelectedField = "mango field"

Rayfield:LoadConfiguration()
