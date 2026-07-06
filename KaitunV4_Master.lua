-- [ PHẦN 2: KHỞI TẠO DỊCH VỤ VÀ TỌA ĐỘ ] -----------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CommF = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
local Player = Players.LocalPlayer

local V4_CFrames = {
    ["Lever"] = CFrame.new(28282.5, 14896.8, 105.1),
    ["AncientClock"] = CFrame.new(28482.7, 14896.8, 105),
    ["Doors"] = {
        ["Human"]   = CFrame.new(28230.1, 14896.8, -21.4),
        ["Mink"]    = CFrame.new(28407.5, 14896.8, 20.3),
        ["Fishman"] = CFrame.new(28265.1, 14896.8, -73.6), 
        ["Skypiea"] = CFrame.new(28375.2, 14896.8, 76.5), 
        ["Cyborg"]  = CFrame.new(28330.1, 14896.8, -76.8),
        ["Ghoul"]   = CFrame.new(28392.6, 14896.8, -44.5)
    }
}

-- [ PHẦN 3: CÁC HÀM TIỆN ÍCH ] ---------------------------------------------
local function GetRole()
    local myName = Player.Name
    if getgenv().ConfigV4 and getgenv().ConfigV4["Account Up Gear"] then
        if myName == getgenv().ConfigV4["Account Up Gear"][1] then return "MAIN" end
    end
    if getgenv().ConfigV4 and getgenv().ConfigV4["Account Help"] then
        for _, name in pairs(getgenv().ConfigV4["Account Help"]) do
            if myName == name then return "SUB" end
        end
    end
    return nil
end

local function TweenTo(targetCFrame)
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame = targetCFrame
    end
end

local function EquipWeapon()
    for _, v in pairs(Player.Backpack:GetChildren()) do
        if v.ClassName == "Tool" and (v.ToolTip == "Melee" or v.ToolTip == "Sword") then
            Player.Character.Humanoid:EquipTool(v)
            break
        end
    end
end

local function CheckFullMoon()
    if game:GetService("Lighting"):FindFirstChild("Sky") and game:GetService("Lighting").Sky:GetAttribute("MoonPhase") == 5 then
        return true
    end
    return false
end

-- [ PHẦN 4: HỆ THỐNG FAST ATTACK ] -----------------------------------------
getgenv().FastAttack = false
local CombatFramework = nil

pcall(function()
    CombatFramework = require(Player:WaitForChild("PlayerScripts"):WaitForChild("CombatFramework"))
end)

local function ExecuteFastAttack()
    if not CombatFramework then return end
    local ac = CombatFramework.activeController
    if ac and ac.equipped then
        ac.timeToNextAttack = 0
        ac.timeToNextBlock = 0
        ac.timeToNextCombo = 0
        ac.increment = 3
        ac.hitboxMagnitude = 60 
        ac.blocking = false
        pcall(function()
            local blade = ac.blades[1] or ac.activeComboList[1]
            if blade then
                ReplicatedStorage:WaitForChild("RigControllerEvent"):FireServer("weaponChange", tostring(blade))
            end
            ac:attack()
        end)
    end
end

RunService.Heartbeat:Connect(function()
    if getgenv().FastAttack then 
        pcall(ExecuteFastAttack) 
    end
end)

-- [ PHẦN 5: AUTO ĐỔI TỘC & SERVER ] ---------------------------------------
local function AutoRerollNormalRace(targetRace)
    if Player.Data.Race.Value == targetRace then return end
    task.spawn(function()
        while getgenv().AutoRerollRace and task.wait(1) do
            if Player.Data.Race.Value == targetRace then break end
            CommF:InvokeServer("Tort", "Hunt") -- Dùng Fragments
        end
    end)
end

local function HandleHopAndJoin(TargetJobID)
    if GetRole() == "MAIN" and not CheckFullMoon() then
        -- Logic Hop Full Moon
        local Api = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        local req = HttpService:JSONDecode(game:HttpGet(Api))
        for _, v in pairs(req.data) do
            if v.playing < v.maxPlayers and v.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id, Player)
                task.wait(5)
            end
        end
    elseif GetRole() == "SUB" and getgenv().ConfigV4 and getgenv().ConfigV4["Auto Join"] and TargetJobID ~= "" then
        if game.JobId ~= TargetJobID then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, TargetJobID, Player)
        end
    end
end

-- [ PHẦN 6: LOGIC TRIAL V4 CHÍNH ] -----------------------------------------
local function HandleTrialMissions()
    local myRace = Player.Data.Race.Value
    local Root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not Root then return end

    if myRace == "Human" or myRace == "Fishman" or myRace == "Cyborg" or myRace == "Ghoul" then
        local target = nil
        for _, v in pairs(workspace.Enemies:GetChildren()) do
            if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                target = v 
                break
            end
        end
        if target then
            EquipWeapon()
            TweenTo(target.HumanoidRootPart.CFrame * CFrame.new(0, 15, 0)) -- Treo trên đầu né dame
            getgenv().FastAttack = true
        else
            getgenv().FastAttack = false
        end
    elseif myRace == "Mink" then
        TweenTo(CFrame.new(28295, 14896, 105)) -- Tọa độ đích mê cung
    elseif myRace == "Skypiea" then
        TweenTo(CFrame.new(28375, 15500, 76)) -- Tọa độ đích trên mây
    end
end

local function TrialFlowManager()
    local role = GetRole()
    if not role then return end

    -- Vị trí Đền Thờ
    if CheckFullMoon() then
        -- Nếu ở PVP Room:
        if role == "SUB" then
            if Player.Character and Player.Character:FindFirstChild("Humanoid") then
                Player.Character.Humanoid.Health = 0 -- Reset nhường Win
            end
        elseif role == "MAIN" then
            -- Mua Gear
            -- CommF:InvokeServer("TrialMachine", "Interact")
            -- CommF:InvokeServer("TrialMachine", "Upgrade", getgenv().ConfigV4["Gear Color"] == "Red" and "Path1" or "Path2")
        end
    end
end

-- [ PHẦN 7: GIAO DIỆN UI (ORION LIB) ] -------------------------------------
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Rayfield/main/source')))()
local Window = OrionLib:MakeWindow({Name = "Kaitun V4 Hub", HidePremium = false, SaveConfig = true, ConfigFolder = "KaitunV4_Config"})

-- TAB: HOME
local HomeTab = Window:MakeTab({Name = "HOME", Icon = "rbxassetid://4483345998", PremiumOnly = false})
HomeTab:AddSection({Name = "Information"})
local StatusLabel = HomeTab:AddLabel("Status: Waiting...")
local TierLabel = HomeTab:AddLabel("Tiers - V4 : 0")
local RaceLabel = HomeTab:AddLabel("Race: Loading...")
local JobIdLabel = HomeTab:AddLabel("JobID : " .. game.JobId)

HomeTab:AddSection({Name = "Server Management"})
local TargetJobIDUI = ""
HomeTab:AddTextbox({Name = "Enter Job ID here...", Default = "", TextDisappear = false, Callback = function(V) TargetJobIDUI = V end})
HomeTab:AddButton({Name = "Join Job", Callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, TargetJobIDUI, Player) end})

-- Khởi tạo biến Auto Join mặc định nếu chưa có trong Config
local defaultAutoJoin = false
if getgenv().ConfigV4 and getgenv().ConfigV4["Auto Join"] ~= nil then
    defaultAutoJoin = getgenv().ConfigV4["Auto Join"]
end

HomeTab:AddToggle({Name = "Auto Join (Acc Phụ)", Default = defaultAutoJoin, Callback = function(V) 
    if getgenv().ConfigV4 then getgenv().ConfigV4["Auto Join"] = V end 
end})

local defaultAutoTrial = false
if getgenv().ConfigV4 and getgenv().ConfigV4["Auto Trial"] ~= nil then
    defaultAutoTrial = getgenv().ConfigV4["Auto Trial"]
end

HomeTab:AddToggle({Name = "Bật Auto Trial (V4)", Default = defaultAutoTrial, Callback = function(V) 
    if getgenv().ConfigV4 then getgenv().ConfigV4["Auto Trial"] = V end 
end})
HomeTab:AddButton({Name = "Copy JobID", Callback = function() if setclipboard then setclipboard(game.JobId) end end})

-- TAB: RACE
local RaceTab = Window:MakeTab({Name = "RACE", Icon = "rbxassetid://4483345998", PremiumOnly = false})
RaceTab:AddSection({Name = "4 Tộc Cơ Bản (3000 F)"})
RaceTab:AddDropdown({Name = "Chọn Tộc", Default = "Human", Options = {"Human", "Mink", "Skypiea", "Fishman"}, Callback = function(V) getgenv().TargetRaceUI = V end})
RaceTab:AddToggle({Name = "Auto Reroll Tộc", Default = false, Callback = function(V) 
    getgenv().AutoRerollRace = V 
    if V and getgenv().TargetRaceUI then AutoRerollNormalRace(getgenv().TargetRaceUI) end
end})
RaceTab:AddSection({Name = "Tộc Đặc Biệt"})
RaceTab:AddButton({Name = "Mua Ghoul (Ectoplasm)", Callback = function() CommF:InvokeServer("Experimic", "Buy") end})
RaceTab:AddButton({Name = "Mua Cyborg (Fragments)", Callback = function() CommF:InvokeServer("CyborgTrainer", "Buy") end})

OrionLib:Init()

-- [ PHẦN 8: VÒNG LẶP CẬP NHẬT CHÍNH ] --------------------------------------
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            -- Cập nhật UI
            RaceLabel:Set("Race: " .. tostring(Player.Data.Race.Value))
            local tier = (Player.Data:FindFirstChild("Race") and Player.Data.Race:FindFirstChild("Awakening")) and Player.Data.Race.Awakening.Value or 0
            TierLabel:Set("Tiers - V4 : " .. tostring(tier))
            StatusLabel:Set(CheckFullMoon() and "Status: Full Moon Is Active!" or "Status: Waiting Full Moon...")
            
            -- Chạy Logic Auto
            if getgenv().ConfigV4 and getgenv().ConfigV4["Auto Trial"] then
                HandleHopAndJoin(TargetJobIDUI)
                TrialFlowManager()
                -- Nếu đang làm nhiệm vụ:
                -- HandleTrialMissions() 
            end
        end)
    end
end)
