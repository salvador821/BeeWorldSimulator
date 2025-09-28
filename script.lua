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

-- Main Tab
local MainTab = Window:CreateTab("Main Features", 4483362458)

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

InfoTab:CreateLabel("Auto Dig: auto digs/auto uses ur collector")
InfoTab:CreateLabel("Auto Farm: collects tokens and goes to convert(IN THE WORKS)")

-- Initialize global variables
_G.AutoDig = false
_G.AutoFarm = false

Rayfield:LoadConfiguration()
