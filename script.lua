-- Rayfield Interface Setup
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Autofarm Script",
   LoadingTitle = "Autofarm System",
   LoadingSubtitle = "by DeepSeek",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "AutoFarm"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = false,
})

-- Main Tab
local MainTab = Window:CreateTab("Main Features", 4483362458)

-- Auto Dig Section
local AutoDigToggle = MainTab:CreateToggle({
   Name = "Auto Dig",
   CurrentValue = false,
   Flag = "AutoDigToggle",
   Callback = function(Value)
       if Value then
           -- Start auto dig loop
           _G.AutoDig = true
           while _G.AutoDig and task.wait(0.1) do
               pcall(function()
                   local player = game:GetService("Players").LocalPlayer
                   local character = player.Character or player.CharacterAdded:Wait()
                   
                   -- Loop through all tools and fire ToolRemote
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
           -- Start auto farm
           _G.AutoFarm = true
           
           -- Load pathfinding services
           local Players = game:GetService("Players")
           local PathfindingService = game:GetService("PathfindingService")
           local RunService = game:GetService("RunService")

           local player = Players.LocalPlayer
           local character = player.Character or player.CharacterAdded:Wait()
           local humanoid = character:WaitForChild("Humanoid")
           local hrp = character:WaitForChild("HumanoidRootPart")

           -- Pathfinding parameters
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

           -- Function to move to target
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

           -- Main farm loop
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

-- Settings Tab
local SettingsTab = Window:CreateTab("Settings", 4483362458)

local Section = SettingsTab:CreateSection("Configuration")

-- Auto Farm Distance Setting
local DistanceSlider = SettingsTab:CreateSlider({
   Name = "Farm Distance Threshold",
   Range = {5, 50},
   Increment = 1,
   Suffix = "Studs",
   CurrentValue = 5,
   Flag = "DistanceSlider",
   Callback = function(Value)
       _G.FarmDistance = Value
   end,
})

-- Performance Settings
local PerformanceSection = SettingsTab:CreateSection("Performance")

local WaitTimeSlider = SettingsTab:CreateSlider({
   Name = "Loop Wait Time",
   Range = {0.05, 1},
   Increment = 0.05,
   Suffix = "Seconds",
   CurrentValue = 0.1,
   Flag = "WaitTimeSlider",
   Callback = function(Value)
       _G.LoopWaitTime = Value
   end,
})

-- Info Tab
local InfoTab = Window:CreateTab("Information", 4483362458)

InfoTab:CreateLabel("Auto Dig: Fires ToolRemote every 0.1 seconds")
InfoTab:CreateLabel("Auto Farm: Collects tokens using pathfinding")
InfoTab:CreateLabel("Make sure you have tools equipped for Auto Dig")
InfoTab:CreateLabel("Game must have 'Debris/Tokens' folder structure")

-- Initialize global variables
_G.AutoDig = false
_G.AutoFarm = false
_G.FarmDistance = 5
_G.LoopWaitTime = 0.1

Rayfield:LoadConfiguration()
