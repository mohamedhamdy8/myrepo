-- ====== HWID CHECK ======
local HttpService = game:GetService("HttpService")

-- Require executor to support gethwid()
if not gethwid then
    error("❌ HWID function not supported by this executor.")
end

local hwid = gethwid()

-- GitHub raw whitelist link
local whitelistUrl = "https://raw.githubusercontent.com/mohamedhamdy8/myrepo/refs/heads/main/whitelist.json"

-- Fetch whitelist
local success, response = pcall(function()
    return game:HttpGet(whitelistUrl)
end)

if not success then
    error("❌ Could not fetch whitelist.")
end

-- Decode JSON
local data = HttpService:JSONDecode(response)

-- Check authorization
local authorized = false
for _, id in ipairs(data.HWIDs) do
    if id == hwid then
        authorized = true
        break
    end
end

if not authorized then
    error("❌ HWID not authorized: " .. tostring(hwid))
end

print("✅ Authorized HWID: " .. tostring(hwid))
-- ====== END HWID CHECK ======

-- load mobile-friendly Venyx

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Pstrw/Reuploaded-Librarys/main/Venyx/source.lua"))()

local venyx = library.new("Valkyrie.ware", 5013109572) -- icon id

-- ========= HOUSEKEEPING: delete unwanted objects =========
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function safeNil(inst)
if inst and inst.Parent then
inst.Parent = nil
end
end

pcall(function()
-- ReplicatedFirst.Static
local static = ReplicatedFirst:FindFirstChild("Static")
if static then
safeNil(static:FindFirstChild("TeleportIndicator"))
safeNil(static:FindFirstChild("Superman"))
safeNil(static:FindFirstChild("UIScaleHandler"))
end

-- ReplicatedFirst.Prod
local prod = ReplicatedFirst:FindFirstChild("Prod")
if prod then
safeNil(prod:FindFirstChild("Stats"))
end

-- ReplicatedStorage.Remotes
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
safeNil(remotes:FindFirstChild("EditCurrentSetting"))
end
end)

local ftiEnabled = false
local trueActive = true
local dmgEnabled = true
local visualizerEnabled = false
local reachType = "sphere" -- "sphere" | "box" | "wide"

-- unified config
local CONFIG_FTI = {
sphereRadius = 3.5,
boxVector = Vector3.new(4,4,4),
wideScale = Vector3.new(1.8, 0.5, 1.3),
}

-- visualizer part
local visualizer = Instance.new("Part")
visualizer.Color = Color3.fromRGB(255, 0, 0)
visualizer.Transparency = 0.6
visualizer.Anchored = true
visualizer.CanCollide = false
visualizer.CanTouch = false
visualizer.CanQuery = false
visualizer.BottomSurface = Enum.SurfaceType.Smooth
visualizer.TopSurface = Enum.SurfaceType.Smooth
visualizer.Name = "ReachVisualizer"

-- ✅ Create UI page & section
local mainPage = venyx:addPage("Combat", 7485051715 )
local reachSec = mainPage:addSection("FTI Settings")

-- Toggles & controls
reachSec:addToggle("Reach Enabled", ftiEnabled, function(on)
ftiEnabled = on
if not on then visualizer.Parent = nil end
end)

reachSec:addDropdown("Reach Type", { "sphere", "box", "wide" }, function(choice)
reachType = choice
end)

-- one textbox for all types
reachSec:addTextbox("Reach Size", tostring(CONFIG_FTI.sphereRadius), function(text)
if not text or #text:gsub("%s","") == 0 then return end
if reachType == "sphere" then
local r = tonumber(text)
if r and r > 0 then CONFIG_FTI.sphereRadius = r end
else
local x,y,z = text:match("^%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*$")
x,y,z = tonumber(x), tonumber(y), tonumber(z)
if x and y and z then CONFIG_FTI.boxVector = Vector3.new(x,y,z) end
end
end)

reachSec:addToggle("Visualizer", visualizerEnabled, function(on)
visualizerEnabled = on
if not on then visualizer.Parent = nil end
end)

reachSec:addToggle("Damage", dmgEnabled, function(on)
dmgEnabled = on
end)

-- Margin toggle + textbox
local useMargin = false
local marginValue = 0.1

reachSec:addToggle("Use Margin Fix", useMargin, function(on)
    useMargin = on
end)

reachSec:addTextbox("Margin Value", tostring(marginValue), function(text)
    local n = tonumber(text)
    if n and n >= 0 then
        marginValue = n
    end
end)


-- core logic
local plr = game.Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local function getWhiteList()
local wl = {}
for _,v in pairs(game.Players:GetPlayers()) do
if v ~= plr then
local char = v.Character
if char then
for _,q in pairs(char:GetChildren()) do
if q:IsA("BasePart") then
table.insert(wl,q)
end
end
end
end
end
return wl
end

local function onHit(hit, handle)
local victim = hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid")
if victim and victim.Parent and victim.Parent.Name ~= plr.Name then
if dmgEnabled then
-- fire multiple bursts to ensure hit registers
for _,v in pairs(hit.Parent:GetChildren()) do
if v:IsA("BasePart") and (v.Name == "HumanoidRootPart" or v.Name:match("Arm") or v.Name:match("Leg")) then

for i=1,3 do
firetouchinterest(v,handle,0)
firetouchinterest(v,handle,1)
end
end
end
else
-- minimal touch if damage disabled
firetouchinterest(hit,handle,0)
firetouchinterest(hit,handle,1)
end
end
end

-- ========= FTI RENDER LOOP =========
RunService.RenderStepped:Connect(function()
    if not ftiEnabled or not trueActive then
        visualizer.Parent = nil
        return
    end

    local tool = plr.Character and plr.Character:FindFirstChildOfClass("Tool")
    local handle = tool and (tool:FindFirstChild("Handle") or tool:FindFirstChildOfClass("BasePart"))
    if not handle then
        visualizer.Parent = nil
        return
    end

    -- Visualizer management
    if visualizerEnabled then
        visualizer.Parent = Workspace
    else
        visualizer.Parent = nil
    end

    -- Sphere reach
    if reachType == "sphere" then
        local r = CONFIG_FTI.sphereRadius
        visualizer.Shape = Enum.PartType.Ball
        visualizer.Material = Enum.Material.ForceField
        visualizer.Color = Color3.fromRGB(255, 255, 255)
        visualizer.Size = Vector3.new(r*2, r*2, r*2)
        visualizer.CFrame = handle.CFrame

 for _,v in pairs(game.Players:GetPlayers()) do
    local hrp = v.Character and v.Character:FindFirstChild("HumanoidRootPart")
    local dist = (hrp.Position - handle.Position).Magnitude
    if useMargin then
        if dist <= r + marginValue then
            onHit(hrp, handle)
        end
    else
        if dist <= r then
            onHit(hrp, handle)
        end
    end   -- ✅ closes the if useMargin … else … end
end       -- ✅ closes the for loop



    elseif reachType == "box" or reachType == "wide" then
        local size = CONFIG_FTI.boxVector
        if reachType == "wide" then
            local s = CONFIG_FTI.wideScale
            size = Vector3.new(size.X*s.X, size.Y*s.Y, size.Z*s.Z)
        end

        visualizer.Shape = Enum.PartType.Block
        visualizer.Material = Enum.Material.ForceField -- same glowing outline
        visualizer.Color = Color3.fromRGB(255, 255, 255)
        visualizer.Transparency = 0.6
        visualizer.Size = size
        visualizer.CFrame = handle.CFrame

        local params = OverlapParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {plr.Character}

        local parts = Workspace:GetPartBoundsInBox(handle.CFrame, size, params)
        for _,p in ipairs(parts) do
            local hum = p.Parent and p.Parent:FindFirstChildOfClass("Humanoid")
            if hum and hum.Parent ~= plr.Character then
                onHit(p, handle)
            end
        end
    end
end) -- ✅ this closes the RenderStepped function

local function getWhiteList()

local wl = {}

for _, v in pairs(game.Players:GetPlayers()) do

if v ~= plr then

local char = v.Character

if char then

for _, q in pairs(char:GetChildren()) do

if q:IsA("Part") then

table.insert(wl, q)

end

end

end

end

end

return wl

end



-- ================================

-- Cbring reach — section on mainPage (converted)

-- ================================

local CONFIG_CBR = {

enabled = false, -- start OFF

hitboxShape = "wide", -- "box" | "sphere" | "wide"

reachVector = Vector3.new(2, 2, 4), -- for box/wide (X,Y,Z)

sphereRadius = 8, -- for sphere

wideScale = Vector3.new(1.8, 0.5, 1.3),

showHitbox = false, -- start OFF

farCFrame = CFrame.new(1e4, -1e4, 1e4)

}



local cbringSec = mainPage:addSection("Cbring reach")



-- Reach Enabled (CBR)

cbringSec:addToggle("Reach Enabled", CONFIG_CBR.enabled, function(on)

CONFIG_CBR.enabled = on

if not on then

CBR_DestroyViz()

if next(CBR_ActiveRigs) then

for rig,_ in pairs(CBR_ActiveRigs) do CBR_ParkRig(rig) end

CBR_ActiveRigs = {}

end

end

end)



-- Hitbox Shape dropdown

cbringSec:addDropdown("Hitbox Shape", { "box", "sphere", "wide" }, function(choice)

CONFIG_CBR.hitboxShape = choice

end)



-- Size textbox (sphere -> radius, box/wide -> x,y,z)

cbringSec:addTextbox("Size", "", function(text, focusLost)

if not text or #text:gsub("%s","") == 0 then return end

if CONFIG_CBR.hitboxShape == "sphere" then

local r = tonumber(text)

if r and r > 0 then CONFIG_CBR.sphereRadius = r end

else

local x,y,z = text:match("^%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*$")

x,y,z = tonumber(x), tonumber(y), tonumber(z)

if x and y and z then CONFIG_CBR.reachVector = Vector3.new(x,y,z) end

end

end)



-- Hitbox Visualizer toggle

cbringSec:addToggle("Hitbox Visualizer", CONFIG_CBR.showHitbox, function(on)

CONFIG_CBR.showHitbox = on

if not on then CBR_DestroyViz() end

end)



-- ========= Services / state (namespaced) =========

local Players = game:GetService("Players")

local RunService = game:GetService("RunService")

local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer



local CBR_Character, CBR_CurrentTool, CBR_Handle

local CBR_VizPart

local CBR_RenderConn, CBR_CharAddedConn, CBR_ToolAddedConn, CBR_ToolRemConn

local CBR_ActiveRigs = {}



-- ========= Helpers =========

local function CBR_WaitForCharacter()

local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

task.wait(0.05)

return char

end



function CBR_DestroyViz()

if CBR_VizPart then CBR_VizPart:Destroy() CBR_VizPart = nil end

end



local function CBR_EnsureViz()

if not (CONFIG_CBR.showHitbox and CBR_Handle) then return end

if CBR_VizPart and CBR_VizPart.Parent then return end

local p = Instance.new("Part")

p.Name = "ReachViz_CBR"

p.Anchored = true

p.CanCollide = false

p.CanTouch = false

p.CanQuery = false

p.Transparency = 0.8

p.Color = Color3.fromRGB(255, 255, 255)


p.Material = Enum.Material.ForceField

p.Parent = Workspace

CBR_VizPart = p

end



local function CBR_ComputeHitbox()

if CONFIG_CBR.hitboxShape == "sphere" then

local r = math.max(0, CONFIG_CBR.sphereRadius or 0)

return "sphere", CBR_Handle.CFrame, nil, r

elseif CONFIG_CBR.hitboxShape == "wide" then

local s = CONFIG_CBR.wideScale or Vector3.new(1.5,1,1.2)

local b = CONFIG_CBR.reachVector

return "box", CBR_Handle.CFrame, Vector3.new(b.X*s.X, b.Y*s.Y, b.Z*s.Z), nil

else

return "box", CBR_Handle.CFrame, CONFIG_CBR.reachVector, nil

end

end



local function CBR_UpdateViz()

if not (CONFIG_CBR.showHitbox and CBR_Handle) then

CBR_DestroyViz()

return

end

CBR_EnsureViz()

if not CBR_VizPart then return end

local shape, cf, sizeVec, radius = CBR_ComputeHitbox()

if shape == "sphere" then

CBR_VizPart.Shape = Enum.PartType.Ball

local d = (radius or 0) * 2

CBR_VizPart.Size = Vector3.new(d,d,d)

CBR_VizPart.CFrame = cf

else

CBR_VizPart.Shape = Enum.PartType.Block

CBR_VizPart.Size = sizeVec

CBR_VizPart.CFrame = cf

end

end



local function CBR_GetHumanoidFromPart(part)

if not part then return nil end

local model = part:FindFirstAncestorOfClass("Model")

return model and model:FindFirstChildOfClass("Humanoid") or nil

end



-- R6 clone-swap

local function CBR_SwapInCloneForLimb(rig, limbName, motorName)

local torso = rig:FindFirstChild("Torso")

local limb = rig:FindFirstChild(limbName)

local motor = torso and torso:FindFirstChild(motorName)

if not (torso and limb and motor) then return end



limb.Parent = Workspace

limb.CanCollide = false

limb.Anchored = true

pcall(function() limb:BreakJoints() end)



local fake = limb:Clone()

fake.Parent = rig

fake.Anchored = false



local newMotor = motor:Clone()

newMotor.Part1 = fake

newMotor.Parent = torso



limb:ClearAllChildren()

limb.Transparency = 1

limb.Name = "B " .. limbName

limb.Parent = rig

end



local function CBR_EnsureBClones(rig)

if rig:FindFirstChild("B") then return end

Instance.new("StringValue", rig).Name = "B"

CBR_SwapInCloneForLimb(rig, "Left Arm", "Left Shoulder")

CBR_SwapInCloneForLimb(rig, "Left Leg", "Left Hip")

CBR_SwapInCloneForLimb(rig, "Right Leg", "Right Hip")

end



local function CBR_GetBLimb(rig, limbName)

return rig:FindFirstChild("B " .. limbName)

end



local function CBR_ParkRig(rig)

local bLA = CBR_GetBLimb(rig, "Left Arm")

local bLL = CBR_GetBLimb(rig, "Left Leg")

local bRL = CBR_GetBLimb(rig, "Right Leg")

if bLA then bLA.CFrame = CONFIG_CBR.farCFrame end

if bLL then bLL.CFrame = CONFIG_CBR.farCFrame end

if bRL then bRL.CFrame = CONFIG_CBR.farCFrame end

end



-- Render loop (properly wrapped in a function)

local function CBR_StartRenderLoop()

if CBR_RenderConn then CBR_RenderConn:Disconnect() end

CBR_RenderConn = RunService.RenderStepped:Connect(function()

-- Disabled: kill viz + release rigs and exit

if not CONFIG_CBR.enabled then

CBR_DestroyViz()

if next(CBR_ActiveRigs) then

for rig,_ in pairs(CBR_ActiveRigs) do CBR_ParkRig(rig) end

CBR_ActiveRigs = {}

end

return

end



if not CBR_Character or not CBR_Character.Parent then return end

if not (CBR_CurrentTool and CBR_CurrentTool.Parent and CBR_Handle and CBR_Handle.Parent) then

for rig,_ in pairs(CBR_ActiveRigs) do CBR_ParkRig(rig) end

CBR_ActiveRigs = {}

CBR_DestroyViz()

return

end



-- Enabled: update/create viz

CBR_UpdateViz()



local params = OverlapParams.new()

params.FilterType = Enum.RaycastFilterType.Exclude

params.FilterDescendantsInstances = { CBR_Character }



local shape, cf, sizeVec, radius = CBR_ComputeHitbox()

local parts = (shape == "sphere")

and Workspace:GetPartBoundsInRadius(cf.Position, radius, params)

or Workspace:GetPartBoundsInBox(cf, sizeVec, params)

parts = parts or {}



local rigsThisFrame = {}

for _, p in ipairs(parts) do

local hum = CBR_GetHumanoidFromPart(p)

if hum and hum.Parent and hum.Parent ~= CBR_Character then

local rig = hum.Parent

if rig:FindFirstChild("Torso")

and rig:FindFirstChild("Left Arm")

and rig:FindFirstChild("Left Leg")

and rig:FindFirstChild("Right Leg") then



CBR_EnsureBClones(rig)

local targetCF = CBR_Handle.CFrame

local bLA = CBR_GetBLimb(rig, "Left Arm")

local bLL = CBR_GetBLimb(rig, "Left Leg")

local bRL = CBR_GetBLimb(rig, "Right Leg")

if bLA then bLA.CFrame = targetCF end

if bLL then bLL.CFrame = targetCF end

if bRL then bRL.CFrame = targetCF end



rigsThisFrame[rig] = true

end

end

end



for rig,_ in pairs(CBR_ActiveRigs) do

if not rigsThisFrame[rig] then CBR_ParkRig(rig) end

end

CBR_ActiveRigs = rigsThisFrame

end)

end



-- Tool binding

local function CBR_BindTool(tool)

CBR_CurrentTool = tool

CBR_Handle = tool and tool:FindFirstChild("Handle")

CBR_DestroyViz() -- only loop creates viz when enabled

if CBR_ToolRemConn then CBR_ToolRemConn:Disconnect() end

CBR_ToolRemConn = tool and tool.AncestryChanged:Connect(function(_, parent)

if not parent then

for rig,_ in pairs(CBR_ActiveRigs) do CBR_ParkRig(rig) end

CBR_ActiveRigs = {}

CBR_CurrentTool = nil

CBR_Handle = nil

CBR_DestroyViz()

end

end)

end



local function CBR_FindEquippedTool(char)

for _, child in ipairs(char:GetChildren()) do

if child:IsA("Tool") and child:FindFirstChild("Handle") then

return child

end

end

end



local function CBR_WatchTools(char)

if CBR_ToolAddedConn then CBR_ToolAddedConn:Disconnect() end

CBR_ToolAddedConn = char.ChildAdded:Connect(function(obj)

if obj:IsA("Tool") and obj:FindFirstChild("Handle") then

CBR_BindTool(obj)

end

end)

char.ChildRemoved:Connect(function(obj)

if obj == CBR_CurrentTool then

for rig,_ in pairs(CBR_ActiveRigs) do CBR_ParkRig(rig) end

CBR_ActiveRigs = {}

CBR_CurrentTool = nil

CBR_Handle = nil

CBR_DestroyViz()

end

end)



local t = CBR_FindEquippedTool(char)

if t then CBR_BindTool(t) end

end



local function CBR_OnCharacterReady(char)

CBR_Character = char

for rig,_ in pairs(CBR_ActiveRigs) do CBR_ParkRig(rig) end

CBR_ActiveRigs = {}

CBR_WatchTools(char)

CBR_StartRenderLoop()

end



task.defer(function()

CBR_OnCharacterReady(CBR_WaitForCharacter())

if CBR_CharAddedConn then CBR_CharAddedConn:Disconnect() end

CBR_CharAddedConn = LocalPlayer.CharacterAdded:Connect(function(newChar)

task.wait(0.2)

CBR_OnCharacterReady(newChar)

end)

end)
-- assume you already created the venyx library + mainPage
-- local library = loadstring(game:HttpGet("https://.../Venyx/source.lua"))()
-- local venyx = library.new("YourHub", 123456789)
-- local mainPage = venyx:addPage("Combat", 7485051715)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ========= STATE =========
local lungeEnabled = false
local MAX_RANGE = 5
local CHECK_INTERVAL = 0.12
local AUTO_EQUIP = true
local TEAM_CHECK = false
local DEBUG = false

local char, hum, root
local lastFire = 0

local function bindCharacter(c)
char = c
hum = c:WaitForChild("Humanoid", 5)
root = c:WaitForChild("HumanoidRootPart", 5)
end

if LocalPlayer.Character then bindCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(bindCharacter)

local function isEnemy(plr)
if plr == LocalPlayer then return false end
if TEAM_CHECK and plr.Team ~= nil and LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team then
return false
end
local c = plr.Character
if not c then return false end
local eHum = c:FindFirstChildOfClass("Humanoid")
local eRoot = c:FindFirstChild("HumanoidRootPart")
if not eHum or not eRoot or eHum.Health <= 0 then return false end
return true
end

local function nearestEnemyWithin(maxDist)
if not root then return nil, math.huge end
local best, bestDist = nil, maxDist
for _, plr in ipairs(Players:GetPlayers()) do
if isEnemy(plr) then
local eRoot = plr.Character.HumanoidRootPart
local d = (root.Position - eRoot.Position).Magnitude
if d <= bestDist then
best, bestDist = plr, d
end
end
end
return best, bestDist
end

local function equippedTool()
return char and char:FindFirstChildOfClass("Tool") or nil
end

local function anyBackpackTool()
local bp = LocalPlayer:FindFirstChild("Backpack")
if not bp then return nil end
for _, it in ipairs(bp:GetChildren()) do
if it:IsA("Tool") then return it end
end
return nil
end

-- ========= AUTO TOOL ACTIVATE =========
local autoToolEnabled = false
local autoToolRange = 10 -- default studs

-- Find nearest player
local function getNearestPlayer()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end

    local hrp = LocalPlayer.Character.HumanoidRootPart
    local nearest, nearestDist = nil, math.huge

    for _, pl in pairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") and pl.Character:FindFirstChild("Humanoid") then
            if pl.Character.Humanoid.Health > 0 then
                local dist = (pl.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
                if dist < nearestDist and dist <= autoToolRange then
                    nearest = pl
                    nearestDist = dist
                end
            end
        end
    end
    return nearest
end

-- Get a tool (equipped or in backpack)
local function getTool()
    if LocalPlayer.Character then
        for _, obj in pairs(LocalPlayer.Character:GetChildren()) do
            if obj:IsA("Tool") then return obj end
        end
    end
    if LocalPlayer:FindFirstChild("Backpack") then
        for _, obj in pairs(LocalPlayer.Backpack:GetChildren()) do
            if obj:IsA("Tool") then return obj end
        end
    end
end

-- Equip if not already
local function equipTool(tool)
    if not tool or not LocalPlayer.Character then return end
    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid and tool.Parent ~= LocalPlayer.Character then
        humanoid:EquipTool(tool)
    end
end

-- Loop
RunService.RenderStepped:Connect(function()
    if not autoToolEnabled then return end
    local target = getNearestPlayer()
    if target then
        local tool = getTool()
        if tool then
            equipTool(tool)
            pcall(function() tool:Activate() end)
        end
    end
end)

-- ========= VENYX UI =========
local autoToolSec = mainPage:addSection("Auto Tool Activate")

autoToolSec:addToggle("Enable Auto Tool", autoToolEnabled, function(on)
    autoToolEnabled = on
end)

autoToolSec:addTextbox("Activation Range (Studs)", tostring(autoToolRange), function(text)
    local n = tonumber(text)
    if n and n > 0 then
        autoToolRange = n
    end
end)

-- ========= DAMAGE AMPLIFICATION =========
local dmgEnabled = false
local currentHandle
local SETTINGS = {
    Multiplier = 3, -- how many extra hits per second (default 3x)
    Debug = true,
}

-- find tool handle
local function getHandle(tool)
    if not tool then return nil end
    return tool:FindFirstChild("Handle") or tool:FindFirstChildOfClass("BasePart")
end

-- track equip/unequip
local function onEquipped(tool)
    currentHandle = getHandle(tool)
    if SETTINGS.Debug then
        if currentHandle then
            print("[DamageAmp] Equipped:", tool.Name, "Handle:", currentHandle.Name)
        else
            print("[DamageAmp] Equipped:", tool.Name, "but no handle found")
        end
    end
end

local function onUnequipped()
    currentHandle = nil
    if SETTINGS.Debug then print("[DamageAmp] Unequipped tool") end
end

local function hookCharacter(char)
    char.ChildAdded:Connect(function(obj)
        if obj:IsA("Tool") then
            obj.Equipped:Connect(function() onEquipped(obj) end)
            obj.Unequipped:Connect(onUnequipped)
        end
    end)
end

if LocalPlayer.Character then hookCharacter(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(hookCharacter)

-- loop: spam hits on touching parts
task.spawn(function()
    while task.wait() do
        if dmgEnabled and currentHandle and currentHandle:IsA("BasePart") then
            local touching = currentHandle:GetTouchingParts()
            for _, part in pairs(touching) do
                local hum = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")
                if hum and hum.Parent ~= LocalPlayer.Character then
                    -- spam touches based on multiplier
                    for i = 1, SETTINGS.Multiplier do
                        firetouchinterest(part, currentHandle, 0)
                        firetouchinterest(part, currentHandle, 1)
                    end
                    if SETTINGS.Debug then
                        print(string.format("[DamageAmp] %dx hit on %s", SETTINGS.Multiplier, hum.Parent.Name))
                    end
                end
            end
        end
    end
end)

-- ========= VENYX UI =========
local dmgSec = mainPage:addSection("Damage Amplification")

dmgSec:addToggle("Enable Damage Amp", dmgEnabled, function(on)
    dmgEnabled = on
end)

dmgSec:addTextbox("Damage Multiplier", tostring(SETTINGS.Multiplier), function(text)
    local n = tonumber(text)
    if n and n > 0 then
        SETTINGS.Multiplier = math.floor(n)
        if SETTINGS.Debug then warn("[DamageAmp] Multiplier set to:", SETTINGS.Multiplier) end
    end
end)

-- ========= RESIZING =========
local resizingEnabled = false
local resizeSize = 5
local showVisualizer = true
local vizTransparency = 0.7

local resizeSec = mainPage:addSection("Resizing")

resizeSec:addToggle("Enable Resizing", resizingEnabled, function(on)
    resizingEnabled = on
end)

resizeSec:addTextbox("Resize Size", tostring(resizeSize), function(text)
    local n = tonumber(text)
    if n and n > 0 then
        resizeSize = n
    end
end)

resizeSec:addToggle("Show Visualizer", showVisualizer, function(on)
    showVisualizer = on
end)

resizeSec:addTextbox("Visualizer Transparency", tostring(vizTransparency), function(text)
    local n = tonumber(text)
    if n and n >= 0 and n <= 1 then
        vizTransparency = n
    end
end)
-- Resize loop
RunService.RenderStepped:Connect(function()
    for _, pl in pairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = pl.Character.HumanoidRootPart
            if resizingEnabled then
                pcall(function()
                    hrp.Size = Vector3.new(resizeSize, resizeSize, resizeSize)
                    if showVisualizer then
                        hrp.Transparency = vizTransparency
                        hrp.BrickColor = BrickColor.new("Really blue")
                        hrp.Material = Enum.Material.Neon
                    else
                        hrp.Transparency = 1
                    end
                    hrp.CanCollide = false
                end)
            else
                -- reset to default Roblox size
                pcall(function()
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                    hrp.Material = Enum.Material.Plastic
                end)
            end
        end
    end
end)




-- ========= TELEPORT VARIABLES =========
local tpEnabled = false
local TELEPORT_TIME = 0.2
local selectedPlayer = nil

local highlight = Instance.new("Highlight")
highlight.FillColor = Color3.fromRGB(255, 0, 0)
highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
highlight.FillTransparency = 0.5
highlight.Enabled = false
highlight.Parent = workspace

-- ========= TELEPORT LOGIC =========
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local plr = Players.LocalPlayer
local mouse = plr:GetMouse()
local isBlinking = false

local function setSelectedPlayer(target)
selectedPlayer = target
if target and target.Character and tpEnabled then
highlight.Adornee = target.Character
highlight.Enabled = true
else
highlight.Adornee = nil
highlight.Enabled = false
end
end

local function getRootCF(character)
if character and character.PrimaryPart then
return character:GetPivot()
else
local hrp = character:FindFirstChild("HumanoidRootPart")
if hrp then return hrp.CFrame end
end
end

local function pivotCharacter(character, cf)
if character and character.PrimaryPart then
character:PivotTo(cf)
else
local hrp = character and character:FindFirstChild("HumanoidRootPart")
if hrp then hrp.CFrame = cf end
end
end

local function blinkToSelected()
if not tpEnabled or isBlinking or not selectedPlayer then return end
local myChar = plr.Character
local targetChar = selectedPlayer.Character
if not myChar or not targetChar then return end

local startCF = getRootCF(myChar)
local targetCF = getRootCF(targetChar)
if not startCF or not targetCF then return end

isBlinking = true
pivotCharacter(myChar, targetCF * CFrame.new(0,3,0)) -- teleport on top
task.wait(TELEPORT_TIME)
if myChar and myChar.Parent then
pivotCharacter(myChar, startCF)
end
isBlinking = false
end

-- click to select player
mouse.Button1Down:Connect(function()
if not tpEnabled then return end
local target = mouse.Target and Players:GetPlayerFromCharacter(mouse.Target:FindFirstAncestorOfClass("Model"))
if target and target ~= plr then
setSelectedPlayer(target)
else
setSelectedPlayer(nil)
end
end)

-- press T to teleport
UserInputService.InputBegan:Connect(function(input,gp)
if not gp and input.KeyCode == Enum.KeyCode.T then
blinkToSelected()
end
end)

Players.PlayerRemoving:Connect(function(p)
if p == selectedPlayer then
setSelectedPlayer(nil)
end
end)
-- ========= VENYX TELEPORT PAGE =========
local tpPage = venyx:addPage("Teleport", 13321848320 )
local tpSec = tpPage:addSection("Teleport")

tpSec:addToggle("Teleport Enabled", tpEnabled, function(on)
tpEnabled = on
if not on then
highlight.Enabled = false
else
if selectedPlayer and selectedPlayer.Character then
highlight.Adornee = selectedPlayer.Character
highlight.Enabled = true
end
end
end)

tpSec:addColorPicker("Highlight Color", highlight.FillColor, function(c)
highlight.FillColor = c
highlight.OutlineColor = c
end)

tpSec:addTextbox("Return Time (seconds)", tostring(TELEPORT_TIME), function(text)
local n = tonumber(text)
if n and n > 0 then
TELEPORT_TIME = n
end
end)
-- ========= AUTO TELEPORT (Teleport Page Section) =========
local autoTPEnabled = false
local autoTPMinTime = 1 -- default minimum time (leaderstats.Time)
local autoTPMaxStuds = 20 -- default max distance
local autoTPConn

-- safe zone boundaries
local autoTP_minX, autoTP_maxX = -33.55, 33.55
local autoTP_minY, autoTP_maxY = 0, 100
local autoTP_minZ, autoTP_maxZ = -33.55, 33.55

local function AT_IsOutsideSafeZone(pos)
return pos.X < autoTP_minX or pos.X > autoTP_maxX
or pos.Y < autoTP_minY or pos.Y > autoTP_maxY
or pos.Z < autoTP_minZ or pos.Z > autoTP_maxZ
end

local function AT_CanTeleport(p)
local ls = p:FindFirstChild("leaderstats")
local t = ls and ls:FindFirstChild("Time")
return t and tonumber(t.Value) and t.Value >= autoTPMinTime
end

local function AT_GetFirstValidTarget()
local myHRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
if not myHRP then return nil end
for _, other in ipairs(Players:GetPlayers()) do
if other ~= plr and other.Character then
local thrp = other.Character:FindFirstChild("HumanoidRootPart")
local hum = other.Character:FindFirstChildOfClass("Humanoid")
if thrp and hum and hum.Health > 0 then
local dist = (myHRP.Position - thrp.Position).Magnitude
if dist <= autoTPMaxStuds
and AT_CanTeleport(other)
and AT_IsOutsideSafeZone(thrp.Position) then
return thrp.CFrame
end
end
end
end
end

local function AT_PivotTo(cf)
if plr.Character and plr.Character.PrimaryPart then
plr.Character:PivotTo(cf)
else
local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
if hrp then hrp.CFrame = cf end
end
end

local function AT_Start()
if autoTPConn then autoTPConn:Disconnect() end
autoTPConn = RunService.Heartbeat:Connect(function()
if not autoTPEnabled then return end
local targetCF = AT_GetFirstValidTarget()
if targetCF then
AT_PivotTo(targetCF * CFrame.new(0,3,0)) -- float slightly above target
end
end)
end

local function AT_Stop()
if autoTPConn then autoTPConn:Disconnect(); autoTPConn = nil end
end

-- ========= Venyx Section =========
local autoTPSec = tpPage:addSection("Auto Teleport")

autoTPSec:addToggle("Auto Teleport Enabled", autoTPEnabled, function(on)
autoTPEnabled = on
if on then AT_Start() else AT_Stop() end
end)

autoTPSec:addTextbox("Minimum Time", tostring(autoTPMinTime), function(text)
local n = tonumber(text)
if n and n >= 0 then
autoTPMinTime = n
end
end)

autoTPSec:addTextbox("Max Studs", tostring(autoTPMaxStuds), function(text)
local n = tonumber(text)
if n and n > 0 then
autoTPMaxStuds = n
end
end)
-- ========= CHARACTER PAGE =========
local charPage = venyx:addPage("Character", 13285102351 )

-- ========= TP WALK =========
local charSec = charPage:addSection("TP Walk")

local tpwalkEnabled = false
local tpwalkSpeed = 5

charSec:addToggle("TP Walk Enabled", tpwalkEnabled, function(on)
tpwalkEnabled = on
end)

charSec:addTextbox("TP Walk Speed", tostring(tpwalkSpeed), function(text)
local n = tonumber(text)
if n and n > 0 then
tpwalkSpeed = n
end
end)

RunService.RenderStepped:Connect(function()
if tpwalkEnabled and tpwalkSpeed > 0 then
local character = plr.Character
if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
local root = character.HumanoidRootPart
local moveDirection = character.Humanoid.MoveDirection
if moveDirection.Magnitude > 0 then
root.CFrame = root.CFrame + moveDirection * tpwalkSpeed * 0.01
end
end
end
end)

plr.CharacterAdded:Connect(function()
tpwalkEnabled = false
end)

-- ========= TANK =========
local tankSec = charPage:addSection("Tank")

local tankEnabled = false

local function setTankMode(enabled)
tankEnabled = enabled
local character = plr.Character
if not character then return end
for _, part in pairs(character:GetChildren()) do
if part:IsA("BasePart") then
part.CanTouch = enabled
end
end
end

tankSec:addToggle("Tank Enabled", tankEnabled, function(on)
setTankMode(on)
end)

plr.CharacterAdded:Connect(function(char)
if tankEnabled then
char:WaitForChild("HumanoidRootPart")
setTankMode(true)
end
end)

-- ========= FLY =========
local FlyEnabled = false
local FlyMethod = "ControlModule"
local FlySpeed = 0.2
local FlyConnection1, FlyConnection2

local function Fly(toggle)
local Player = game.Players.LocalPlayer
local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
local Humanoid = Player.Character and Player.Character:FindFirstChild("Humanoid")
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

if not toggle then
FlyEnabled = false
if Root then
if Root:FindFirstChild("F_BodyVelocity") then Root.F_BodyVelocity:Destroy() end
if Root:FindFirstChild("F_BodyGyro") then Root.F_BodyGyro:Destroy() end
end
if Humanoid then Humanoid.PlatformStand = false end
if FlyConnection1 then FlyConnection1:Disconnect() FlyConnection1 = nil end
if FlyConnection2 then FlyConnection2:Disconnect() FlyConnection2 = nil end
return
end

FlyEnabled = true
if not Root then return end

local BodyVelocity = Instance.new("BodyVelocity", Root)
BodyVelocity.Name = "F_BodyVelocity"
BodyVelocity.MaxForce = Vector3.new()
BodyVelocity.Velocity = Vector3.new()

local BodyGyro = Instance.new("BodyGyro", Root)
BodyGyro.Name = "F_BodyGyro"
BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
BodyGyro.P, BodyGyro.D = 1000, 50

FlyConnection1 = Player.CharacterAdded:Connect(function(char)
local NewRoot = char:WaitForChild("HumanoidRootPart")
local BV = Instance.new("BodyVelocity", NewRoot)
BV.Name = "F_BodyVelocity"
BV.MaxForce = Vector3.new()
BV.Velocity = Vector3.new()
local BG = Instance.new("BodyGyro", NewRoot)
BG.Name = "F_BodyGyro"
BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
BG.P, BG.D = 1000, 50
end)

FlyConnection2 = RunService.RenderStepped:Connect(function()
Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
Humanoid = Player.Character and Player.Character:FindFirstChild("Humanoid")
if not Root or not Humanoid then return end
local BV, BG = Root:FindFirstChild("F_BodyVelocity"), Root:FindFirstChild("F_BodyGyro")
if not BV or not BG then return end

BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
Humanoid.PlatformStand = true
BG.CFrame = Camera.CFrame

local Direction
if FlyMethod == "ControlModule" then
local ControlModule = require(Player.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
Direction = ControlModule:GetMoveVector()
else
Direction = Humanoid.MoveDirection
end

local speed = FlySpeed * 50
BV.Velocity = (Camera.CFrame.RightVector * (Direction.X * speed))
- (Camera.CFrame.LookVector * (Direction.Z * speed))
end)
end

-- ========= ADD TO YOUR EXISTING CHAR PAGE =========
local flySec = charPage:addSection("Fly")

flySec:addToggle("Fly Enabled", FlyEnabled, function(on)
Fly(on)
end)

flySec:addDropdown("Fly Method", {"ControlModule", "MoveDirection"}, function(choice)
FlyMethod = choice
end)

flySec:addSlider("Fly Speed", FlySpeed, 0, 2, function(val)
FlySpeed = val
end)

-- EDIT PAGE
local editPage = venyx:addPage("Edit", 5012544693)
local editWorld = editPage:addSection("Edit World")

-- Baseplate color picker
editWorld:addColorPicker("Pick Baseplate Color", Color3.fromRGB(255, 255, 255), function(c)
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate and baseplate:IsA("BasePart") then
baseplate.Color = c
end
end)

-- Fog toggle
local fogEnabled = false
editWorld:addToggle("Enable Fog", false, function(v)
fogEnabled = v
if v then
game.Lighting.FogStart = 0
game.Lighting.FogEnd = 100
else
game.Lighting.FogStart = 100000
game.Lighting.FogEnd = 100000
end
end)

-- Fog color picker
editWorld:addColorPicker("Fog Color", Color3.fromRGB(255, 255, 255), function(c)
game.Lighting.FogColor = c
end)

-- Fog end distance
editWorld:addTextbox("Fog End Distance", "100", function(v)
local n = tonumber(v)
if n then
game.Lighting.FogEnd = n
end
end)

-- Ambient lighting
editWorld:addColorPicker("Lighting Ambient", Color3.fromRGB(128, 128, 128), function(c)
game.Lighting.Ambient = c
end)

-- Outdoor ambient
editWorld:addColorPicker("Outdoor Ambient", Color3.fromRGB(128, 128, 128), function(c)
game.Lighting.OutdoorAmbient = c
end)

-- Leaderstats Editor
local selectedTarget = "Yourself"
local leaderstatsList = {"Time", "Best Time", "XP", "Tokens", "Kills", "Streak"}

local function getPlayerList()
local list = {"Yourself", "Everyone"}
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= LocalPlayer then
table.insert(list, plr.Name)
end
end
return list
end

editWorld:addDropdown("Target Player", getPlayerList(), function(v)
selectedTarget = v
end)

for _, statName in ipairs(leaderstatsList) do
editWorld:addTextbox("Set " .. statName, "", function(value)
local num = tonumber(value)
if not num then return end

local function setStat(plr)
local stats = plr:FindFirstChild("leaderstats")
local stat = stats and stats:FindFirstChild(statName)
if stat and stat:IsA("ValueBase") then
stat.Value = num
end
end

if selectedTarget == "Yourself" then
setStat(LocalPlayer)
elseif selectedTarget == "Everyone" then
for _, plr in ipairs(Players:GetPlayers()) do
setStat(plr)
end
else
local target = Players:FindFirstChild(selectedTarget)
if target then setStat(target) end
end
end)
end
-- TROLL PAGE
local trollPage = venyx:addPage("Misc", 6594776225 )

-- Floating Platform
local trollSection = trollPage:addSection("Floating Platform")
local trollEnabled = false
local trollPlatformHeight = 10
local trollPlatform = nil

trollSection:addTextbox("Platform Height (Max 13)", "10", function(v)
local num = tonumber(v)
if num and num <= 13 then
trollPlatformHeight = num
else
venyx:Notify("Invalid Input", "Don't type more than 13 or you will get kicked.")
end
end)

trollSection:addToggle("Enable Floating Platform", false, function(v)
trollEnabled = v
local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")

if trollPlatform and trollPlatform.Parent then
trollPlatform:Destroy()
trollPlatform = nil
end

if v then
trollPlatform = Instance.new("Part")
trollPlatform.Size = Vector3.new(100, 1, 100)
trollPlatform.Anchored = true
trollPlatform.CanCollide = true
trollPlatform.Transparency = 1
trollPlatform.Position = hrp.Position + Vector3.new(0, trollPlatformHeight, 0)
trollPlatform.Name = "InvisiblePlatform"
trollPlatform.Parent = workspace

task.wait(0.1)
hrp.CFrame = CFrame.new(trollPlatform.Position + Vector3.new(0, trollPlatform.Size.Y / 2 + 3, 0))
end
end)



-- Tool Grip Modifier
local gripSection = trollPage:addSection("Tool Grip Modifier")
local gripEnabled = false
local gripOffset = Vector3.new(0, 0, 0)
local gripRotation = Vector3.new(0, 0, 0)

gripSection:addToggle("Enable Grip Edit", false, function(v)
gripEnabled = v
end)

gripSection:addTextbox("Grip Offset (X,Y,Z)", "0,0,0", function(v)
local x,y,z = string.match(v, "(-?%d+%.?%d*),?%s*(-?%d+%.?%d*),?%s*(-?%d+%.?%d*)")
if x and y and z then
gripOffset = Vector3.new(tonumber(x), tonumber(y), tonumber(z))
end
end)

gripSection:addTextbox("Grip Rotation (X,Y,Z in deg)", "0,0,0", function(v)
local x,y,z = string.match(v, "(-?%d+%.?%d*),?%s*(-?%d+%.?%d*),?%s*(-?%d+%.?%d*)")
if x and y and z then
gripRotation = Vector3.new(math.rad(tonumber(x)), math.rad(tonumber(y)), math.rad(tonumber(z)))
end
end)

-- Auto Look
local lookSection = trollPage:addSection("Auto Look at Enemy")
local autoLookEnabled = false
local autoLookRange = 30

lookSection:addTextbox("Look Range", "30", function(v)
autoLookRange = tonumber(v) or 30
end)

lookSection:addToggle("Enable Auto Look", false, function(v)
autoLookEnabled = v
end)

-- Spinbot
local spinSection = trollPage:addSection("Spinbot")
local spinbotEnabled = false
local spinSpeed = 5

spinSection:addTextbox("Spin Speed", "5", function(v)
spinSpeed = tonumber(v) or 5
end)

spinSection:addToggle("Enable Spinbot", false, function(v)
spinbotEnabled = v
end)

-- Jumpbot
local jumpSection = trollPage:addSection("Jumpbot")
local jumpbotEnabled = false
local jumpRange = 20

jumpSection:addTextbox("Jump Range", "20", function(v)
jumpRange = tonumber(v) or 20
end)

jumpSection:addToggle("Enable Jumpbot", false, function(v)
jumpbotEnabled = v
end)
-- ========= DEVICE SPOOFER =========
local spoofSec = trollPage:addSection("Device Spoofer")

spoofSec:addDropdown("Device Spoof", {
"Controller",
"Mobile",
"Computer"
}, function(choice)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
if choice == "Controller" then
ReplicatedStorage.Remotes.SetPlatform:FireServer(false, true)
elseif choice == "Mobile" then
ReplicatedStorage.Remotes.SetPlatform:FireServer(true, true)
elseif choice == "Computer" then
ReplicatedStorage.Remotes.SetPlatform:FireServer(false, false)
end

-- force respawn so spoof applies
local plr = game.Players.LocalPlayer
if plr.Character then
plr.Character:BreakJoints()
end
end)

-- ========= TROLL LOGIC RUNNER =========
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")

    -- Tool Grip Modifier
    if gripEnabled then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            tool.Grip = CFrame.new(gripOffset) * CFrame.Angles(
                gripRotation.X,
                gripRotation.Y,
                gripRotation.Z
            )
        end -- closes "if tool"
    end -- closes "if gripEnabled"

    -- Auto Look at closest enemy
    if autoLookEnabled and root then
        local closest, shortest = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (root.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if dist < autoLookRange and dist < shortest then
                    closest, shortest = p, dist
                end -- closes "if dist"
            end -- closes "if p ~= LocalPlayer ..."
        end -- closes "for _, p in ipairs"
       
        if closest and closest.Character and closest.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = closest.Character.HumanoidRootPart.Position
            root.CFrame = CFrame.new(
                root.Position,
                Vector3.new(targetPos.X, root.Position.Y, targetPos.Z)
            )
        end -- closes "if closest"
    end -- closes "if autoLookEnabled"

    -- Spinbot
    if spinbotEnabled and root then
        root.CFrame *= CFrame.Angles(0, math.rad(spinSpeed), 0)
    end -- closes "if spinbotEnabled"

    -- Jumpbot
    if jumpbotEnabled and hum and root and hum.FloorMaterial ~= Enum.Material.Air then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (root.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if dist < jumpRange then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    break
                end -- closes "if dist < jumpRange"
            end -- closes "if p ~= LocalPlayer ..."
        end -- closes "for _, p in ipairs"
    end -- closes "if jumpbotEnabled"
end) -- ✅ closes RenderStepped function

-- select first page
venyx:SelectPage(venyx.pages[1], true)
