-- ============================================
--    KAITUN GOD - MAIN.LUA
--    Đặt file này lên GitHub
--    Version: 2.0 | Sea 3 Edition
-- ============================================

-- ══════════════════════════════════════════
-- ĐỌC CONFIG
-- ══════════════════════════════════════════
local Cfg = getgenv().KaitunConfig
if not Cfg then
    error("❌ Không tìm thấy Config! Hãy chạy Loader.lua trước!")
    return
end

-- Shortcut config
local CFG_ACC      = Cfg["Account"]
local CFG_BOSS     = Cfg["Boss"]
local CFG_COMBO    = Cfg["Combo"]
local CFG_MIRAGE   = Cfg["Mirage"]
local CFG_HOP      = Cfg["ServerHop"]
local CFG_WEBHOOK  = Cfg["Webhook"]
local CFG_SETTINGS = Cfg["Settings"]

-- ══════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- ══════════════════════════════════════════
-- VARIABLES
-- ══════════════════════════════════════════
local LP    = Players.LocalPlayer
local Char  = LP.Character or LP.CharacterAdded:Wait()
local HRP   = Char:WaitForChild("HumanoidRootPart")
local Hum   = Char:WaitForChild("Humanoid")

LP.CharacterAdded:Connect(function(c)
    Char = c
    HRP  = c:WaitForChild("HumanoidRootPart")
    Hum  = c:WaitForChild("Humanoid")
    task.wait(2)
end)

-- STATE
local State = {
    FarmBoss    = CFG_BOSS["Enabled"],
    FindMirage  = CFG_MIRAGE["AutoFind"],
    AutoParry   = CFG_COMBO["AutoParry"],
    AutoCombo   = CFG_COMBO["AutoCombo"],
    ServerHop   = CFG_HOP["Enabled"],
    CurrentBoss = CFG_BOSS["Target"],
    WaitTimer   = 0,
    KillCount   = { ["Rip_Indra"] = 0, ["DoughKing"] = 0 },
}

-- ══════════════════════════════════════════
-- UTILS
-- ══════════════════════════════════════════
local function IsAlive()
    return Char and Hum and Hum.Health > 0
end

local function TeleTo(pos, off)
    off = off or Vector3.new(0, 4, 0)
    if HRP then HRP.CFrame = CFrame.new(pos + off) end
end

local function Dist(a, b)
    return (a - b).Magnitude
end

local function FindModel(name)
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v.Name == name then
            local h   = v:FindFirstChild("Humanoid")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if h and hrp and h.Health > 0 then
                return v, hrp, h
            end
        end
    end
    return nil, nil, nil
end

-- ══════════════════════════════════════════
-- DISCORD WEBHOOK
-- ══════════════════════════════════════════
local function SendWebhook(title, message, color)
    if not CFG_WEBHOOK["Enabled"] or CFG_WEBHOOK["URL"] == "" then return end
    color = color or 9442302 -- màu tím mặc định

    local data = HttpService:JSONEncode({
        embeds = {{
            title       = title,
            description = message,
            color       = color,
            footer      = { text = "Kaitun God v2.0 | " .. os.date("%H:%M:%S") },
        }}
    })

    local ok, err = pcall(function()
        game:HttpPost(CFG_WEBHOOK["URL"], data, false, "application/json")
    end)
    if not ok then warn("❌ Webhook lỗi: " .. tostring(err)) end
end

-- ══════════════════════════════════════════
-- EQUIP TOOL
-- ══════════════════════════════════════════
local function EquipTool(name)
    local t = Char:FindFirstChild(name) or LP.Backpack:FindFirstChild(name)
    if t then
        if not Char:FindFirstChild(t.Name) then
            Hum:EquipTool(t); task.wait(0.15)
        end
        return t
    end
    -- Equip bất kỳ tool nào nếu không tìm thấy
    local any = Char:FindFirstChildWhichIsA("Tool")
             or LP.Backpack:FindFirstChildWhichIsA("Tool")
    if any then
        if not Char:FindFirstChild(any.Name) then
            Hum:EquipTool(any); task.wait(0.15)
        end
        return any
    end
    return nil
end

-- ══════════════════════════════════════════
-- AUTO HEAL
-- ══════════════════════════════════════════
local function AutoHeal()
    if not IsAlive() then return end
    local threshold = (CFG_SETTINGS["HealAt"] / 100) * Hum.MaxHealth
    if Hum.Health < threshold then
        for _, item in pairs(LP.Backpack:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find("food") then
                Hum:EquipTool(item)
                task.wait(0.3)
                item:Activate()
                task.wait(0.3)
                break
            end
        end
    end
end

-- ══════════════════════════════════════════
-- CDK COMBO
-- ══════════════════════════════════════════
local function UseCDK(targetHRP)
    if not CFG_COMBO["CDK"] or not targetHRP or not IsAlive() then return end
    if Dist(HRP.Position, targetHRP.Position) > CFG_SETTINGS["AttackRange"] then
        TeleTo(targetHRP.Position, Vector3.new(0,3,2))
        task.wait(0.1)
    end
    local tool = EquipTool("Cursed Dual Katana") or EquipTool("CDK")
    if not tool then return end
    -- Dùng từng skill Z X C
    for _, sName in ipairs({"Ender","Red Tornado","Shockwave","Z","X","C"}) do
        local skill = tool:FindFirstChild(sName)
        if skill and skill:IsA("RemoteEvent") then
            skill:FireServer(targetHRP.CFrame)
            task.wait(0.25)
        end
    end
    tool:Activate()
end

-- ══════════════════════════════════════════
-- GOD HUMAN COMBO
-- ══════════════════════════════════════════
local function UseGodHuman(targetHRP)
    if not CFG_COMBO["GodHuman"] or not targetHRP or not IsAlive() then return end
    if Dist(HRP.Position, targetHRP.Position) > CFG_SETTINGS["AttackRange"] then
        TeleTo(targetHRP.Position, Vector3.new(0,3,2))
        task.wait(0.1)
    end
    local tool = EquipTool("God Human") or EquipTool("Superhuman")
    if not tool then return end
    for _, sName in ipairs({"Z","X","C","V"}) do
        local skill = tool:FindFirstChild(sName)
        if skill and skill:IsA("RemoteEvent") then
            skill:FireServer(targetHRP.CFrame, targetHRP.Position)
            task.wait(0.2)
        end
    end
    tool:Activate()
end

-- ══════════════════════════════════════════
-- AUTO PARRY
-- ══════════════════════════════════════════
local parryCooldown = false
local function TryParry()
    if parryCooldown then return end
    local tool = Char:FindFirstChildWhichIsA("Tool")
    if not tool then return end
    local parry = tool:FindFirstChild("Parry")
               or tool:FindFirstChild("Block")
               or tool:FindFirstChild("Guard")
    if parry then
        parryCooldown = true
        if parry:IsA("RemoteEvent") then parry:FireServer()
        elseif parry:IsA("RemoteFunction") then parry:InvokeServer() end
        task.wait(0.8)
        parryCooldown = false
    end
end

RunService.Heartbeat:Connect(function()
    if not State.AutoParry or not IsAlive() then return end
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if (n:find("bullet") or n:find("slash") or n:find("hit"))
                and Dist(HRP.Position, obj.Position) < 18 then
                TryParry(); break
            end
        end
    end
end)

-- ══════════════════════════════════════════
-- ATTACK BOSS
-- ══════════════════════════════════════════
local function AttackBoss(bossHRP)
    if not IsAlive() then return end
    AutoHeal()
    if State.AutoCombo then
        UseCDK(bossHRP)
        task.wait(0.1)
        UseGodHuman(bossHRP)
    else
        if Dist(HRP.Position, bossHRP.Position) > CFG_SETTINGS["AttackRange"] then
            TeleTo(bossHRP.Position); task.wait(0.05)
        end
        local tool = Char:FindFirstChildWhichIsA("Tool")
                  or LP.Backpack:FindFirstChildWhichIsA("Tool")
        if tool then
            if not Char:FindFirstChild(tool.Name) then
                Hum:EquipTool(tool); task.wait(0.1)
            end
            tool:Activate()
        end
    end
end

-- ══════════════════════════════════════════
-- SERVER HOP
-- ══════════════════════════════════════════
local function GetServers()
    local list = {}
    local ok, res = pcall(function()
        return game:HttpGet(
            "https://games.roblox.com/v1/games/"
            .. game.PlaceId
            .. "/servers/Public?sortOrder=Asc&limit=100"
        )
    end)
    if not ok then return list end
    local ok2, data = pcall(function()
        return HttpService:JSONDecode(res)
    end)
    if not ok2 or not data or not data.data then return list end
    for _, s in pairs(data.data) do
        if s.id ~= game.JobId and s.playing < s.maxPlayers then
            table.insert(list, s.id)
        end
    end
    return list
end

local function HopServer(statusLbl)
    if statusLbl then
        statusLbl.Text      = "🔄 Đang tìm server mới..."
        statusLbl.TextColor3= Color3.fromRGB(100,180,255)
    end
    local servers = GetServers()
    if #servers == 0 then
        if statusLbl then
            statusLbl.Text = "⚠️ Không tìm thấy server!"
        end
        return
    end
    local s = servers[math.random(1, #servers)]
    print("🔄 Hop → " .. s)
    TeleportService:TeleportToPlaceInstance(game.PlaceId, s, LP)
end

-- ══════════════════════════════════════════
-- FARM BOSS LOOP
-- ══════════════════════════════════════════
local function FarmBossLoop(statusLbl)
    State.WaitTimer = 0

    while State.FarmBoss do
        if not IsAlive() then
            if statusLbl then
                statusLbl.Text      = "💀 Đã chết, chờ respawn..."
                statusLbl.TextColor3= Color3.fromRGB(255,80,80)
            end
            task.wait(3); continue
        end

        local _, bossHRP, bossHum = FindModel(State.CurrentBoss)

        if bossHRP then
            -- Tìm thấy boss
            State.WaitTimer = 0
            local prevHP = bossHum.Health
            AttackBoss(bossHRP)

            -- Kiểm tra boss vừa chết không
            task.wait(0.1)
            local _, _, newHum = FindModel(State.CurrentBoss)
            if prevHP > 0 and (not newHum or newHum.Health <= 0) then
                State.KillCount[State.CurrentBoss] =
                    (State.KillCount[State.CurrentBoss] or 0) + 1
                print("💀 Kill #" 
                    .. State.KillCount[State.CurrentBoss]
                    .. " — " .. State.CurrentBoss)
                -- Gửi webhook
                if CFG_WEBHOOK["OnKillBoss"] then
                    SendWebhook(
                        "💀 KILL BOSS",
                        "**Boss:** " .. State.CurrentBoss
                        .. "\n**Kill #" .. State.KillCount[State.CurrentBoss] .. "**"
                        .. "\n**Server:** " .. game.JobId,
                        3066993
                    )
                end
            end

        else
            -- Không thấy boss
            State.WaitTimer = State.WaitTimer + CFG_SETTINGS["FarmDelay"]
            local remain = math.max(0,
                CFG_HOP["WaitTime"] - math.floor(State.WaitTimer))

            if statusLbl then
                statusLbl.Text = "⏳ Chờ " .. State.CurrentBoss
                    .. " spawn... Hop sau: " .. remain .. "s"
                statusLbl.TextColor3 = Color3.fromRGB(255,200,50)
            end

            -- Đủ thời gian → hop
            if State.ServerHop
                and State.WaitTimer >= CFG_HOP["WaitTime"] then
                State.WaitTimer = 0
                HopServer(statusLbl)
                task.wait(8)
            end
        end

        task.wait(CFG_SETTINGS["FarmDelay"])
    end
end

-- ══════════════════════════════════════════
-- TÌM MIRAGE ISLAND
-- ══════════════════════════════════════════
local MIRAGE_NAMES = {
    "MirageIsland","Mirage","Mirage Island","SecretIsland"
}

local function FindMirage()
    for _, name in ipairs(MIRAGE_NAMES) do
        local obj = workspace:FindFirstChild(name)
                 or workspace:FindFirstDescendant(name)
        if obj then return obj end
    end
    for _, obj in pairs(workspace:GetChildren()) do
        if (obj:IsA("Model") or obj:IsA("BasePart"))
            and obj.Name:lower():find("mirage") then
            return obj
        end
    end
    return nil
end

local function MirageLoop(statusLbl, mirageLbl)
    while State.FindMirage do
        local island = FindMirage()
        if island then
            local pos
            if island:IsA("Model") then
                pos = island:GetModelCFrame().Position
            elseif island:IsA("BasePart") then
                pos = island.Position
            end
            if pos then
                if CFG_MIRAGE["TeleportTo"] then
                    TeleTo(pos, Vector3.new(0,10,0))
                end
                if mirageLbl then
                    mirageLbl.Text      = "✅ Đã đến Mirage Island!"
                    mirageLbl.TextColor3= Color3.fromRGB(100,255,100)
                end
                if statusLbl then
                    statusLbl.Text      = "🏝️ Mirage Island Found!"
                    statusLbl.TextColor3= Color3.fromRGB(100,255,100)
                end
                -- Webhook
                if CFG_WEBHOOK["OnMirage"] then
                    SendWebhook(
                        "🏝️ MIRAGE ISLAND",
                        "Tìm thấy Mirage Island!\n**Server:** " .. game.JobId,
                        16776960
                    )
                end
                State.FindMirage = false
                break
            end
        else
            if mirageLbl then
                mirageLbl.Text      = "🔍 Đang quét Mirage Island..."
                mirageLbl.TextColor3= Color3.fromRGB(255,200,50)
            end
        end
        task.wait(1)
    end
end

-- ══════════════════════════════════════════
-- GUI
-- ══════════════════════════════════════════
if LP.PlayerGui:FindFirstChild("KaitunGodGUI") then
    LP.PlayerGui.KaitunGodGUI:Destroy()
end

local SG = Instance.new("ScreenGui")
SG.Name = "KaitunGodGUI"
SG.ResetOnSpawn = false
SG.Parent = LP.PlayerGui

local function Frame(p,sz,ps,bg,r)
    local f=Instance.new("Frame")
    f.Size=sz; f.Position=ps
    f.BackgroundColor3=bg; f.BorderSizePixel=0; f.Parent=p
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 10); c.Parent=f
    return f
end
local function Label(p,txt,sz,ps,tc,ts,f2,xa)
    local l=Instance.new("TextLabel")
    l.Size=sz; l.Position=ps; l.BackgroundTransparency=1
    l.Text=txt; l.TextColor3=tc or Color3.new(1,1,1)
    l.TextSize=ts or 12; l.Font=f2 or Enum.Font.Gotham
    l.TextXAlignment=xa or Enum.TextXAlignment.Left; l.Parent=p
    return l
end
local function Btn(p,txt,sz,ps,bg)
    local b=Instance.new("TextButton")
    b.Size=sz; b.Position=ps; b.BackgroundColor3=bg
    b.Text=txt; b.TextColor3=Color3.new(1,1,1)
    b.TextSize=12; b.Font=Enum.Font.GothamBold
    b.BorderSizePixel=0; b.Parent=p
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,8); c.Parent=b
    return b
end

-- Main Frame
local MF = Frame(SG,
    UDim2.new(0,340,0,500),
    UDim2.new(0.5,-170,0.5,-250),
    Color3.fromRGB(12,12,20))
MF.Active=true; MF.Draggable=true
local st=Instance.new("UIStroke")
st.Color=Color3.fromRGB(150,50,255); st.Thickness=1.5; st.Parent=MF

-- Header
local H=Frame(MF,UDim2.new(1,0,0,50),UDim2.new(0,0,0,0),Color3.fromRGB(90,15,190))
Frame(H,UDim2.new(1,0,0.5,0),UDim2.new(0,0,0.5,0),Color3.fromRGB(90,15,190),0)
Label(H,"⚔️  KAITUN GOD  v2.0",
    UDim2.new(1,-50,1,0),UDim2.new(0,14,0,0),
    Color3.new(1,1,1),15,Enum.Font.GothamBold)
local XBtn=Btn(H,"✕",UDim2.new(0,28,0,28),UDim2.new(1,-36,0.5,-14),Color3.fromRGB(200,40,40))
XBtn.MouseButton1Click:Connect(function()
    State.FarmBoss=false; State.FindMirage=false
    State.AutoParry=false; State.AutoCombo=false
    SG:Destroy()
end)

-- Status
local SF=Frame(MF,UDim2.new(1,-20,0,32),UDim2.new(0,10,0,58),Color3.fromRGB(20,20,36),8)
local SL=Label(SF,"⭕  Sẵn sàng",UDim2.new(1,-10,1,0),UDim2.new(0,10,0,0),Color3.fromRGB(180,180,220))

-- Kill count
local KF=Frame(MF,UDim2.new(1,-20,0,26),UDim2.new(0,10,0,96),Color3.fromRGB(18,18,32),8)
local KL=Label(KF,"💀 Rip Indra: 0  |  🍩 Dough King: 0",
    UDim2.new(1,-10,1,0),UDim2.new(0,10,0,0),Color3.fromRGB(255,180,80),11)
task.spawn(function()
    while task.wait(1) do
        KL.Text="💀 Rip Indra: "..State.KillCount["Rip_Indra"]
            .."  |  🍩 Dough King: "..State.KillCount["DoughKing"]
    end
end)

-- ── BOSS SECTION ──
Label(MF,"👑  BOSS FARM",UDim2.new(1,-20,0,16),UDim2.new(0,12,0,130),
    Color3.fromRGB(200,100,255),11,Enum.Font.GothamBold)

local RipBtn=Btn(MF,"👑 Rip Indra",
    UDim2.new(0.46,0,0,32),UDim2.new(0,10,0,148),
    Color3.fromRGB(130,20,200))
local DoughBtn=Btn(MF,"🍩 Dough King",
    UDim2.new(0.46,0,0,32),UDim2.new(0.52,2,0,148),
    Color3.fromRGB(50,50,80))

local function UpdateBossBtn()
    if State.CurrentBoss=="Rip_Indra" then
        RipBtn.BackgroundColor3=Color3.fromRGB(130,20,200)
        DoughBtn.BackgroundColor3=Color3.fromRGB(50,50,80)
    else
        DoughBtn.BackgroundColor3=Color3.fromRGB(130,20,200)
        RipBtn.BackgroundColor3=Color3.fromRGB(50,50,80)
    end
end
UpdateBossBtn()

RipBtn.MouseButton1Click:Connect(function()
    State.CurrentBoss="Rip_Indra"; UpdateBossBtn()
    SL.Text="🎯 Chọn: Rip Indra"; SL.TextColor3=Color3.fromRGB(200,100,255)
end)
DoughBtn.MouseButton1Click:Connect(function()
    State.CurrentBoss="DoughKing"; UpdateBossBtn()
    SL.Text="🎯 Chọn: Dough King"; SL.TextColor3=Color3.fromRGB(200,100,255)
end)

local FarmBtn=Btn(MF,"▶  START FARM BOSS",
    UDim2.new(1,-20,0,36),UDim2.new(0,10,0,188),Color3.fromRGB(50,190,80))
FarmBtn.MouseButton1Click:Connect(function()
    State.FarmBoss=not State.FarmBoss
    if State.FarmBoss then
        FarmBtn.Text="⏹  STOP FARM"; FarmBtn.BackgroundColor3=Color3.fromRGB(190,40,40)
        SL.Text="⚔️ Đang farm: "..State.CurrentBoss; SL.TextColor3=Color3.fromRGB(100,255,100)
        coroutine.wrap(function() FarmBossLoop(SL) end)()
    else
        FarmBtn.Text="▶  START FARM BOSS"; FarmBtn.BackgroundColor3=Color3.fromRGB(50,190,80)
        SL.Text="⛔ Đã dừng farm"; SL.TextColor3=Color3.fromRGB(255,80,80)
    end
end)

-- ── COMBO SECTION ──
Label(MF,"🗡️  COMBO & PARRY",UDim2.new(1,-20,0,16),UDim2.new(0,12,0,234),
    Color3.fromRGB(200,100,255),11,Enum.Font.GothamBold)

local ComboBtn=Btn(MF,"🗡️ Auto Combo: TẮT",
    UDim2.new(0.46,0,0,32),UDim2.new(0,10,0,252),Color3.fromRGB(50,50,80))
local ParryBtn=Btn(MF,"🛡️ Auto Gạt: TẮT",
    UDim2.new(0.46,0,0,32),UDim2.new(0.52,2,0,252),Color3.fromRGB(50,50,80))

ComboBtn.MouseButton1Click:Connect(function()
    State.AutoCombo=not State.AutoCombo
    if State.AutoCombo then
        ComboBtn.Text="🗡️ Auto Combo: BẬT"; ComboBtn.BackgroundColor3=Color3.fromRGB(220,120,0)
    else
        ComboBtn.Text="🗡️ Auto Combo: TẮT"; ComboBtn.BackgroundColor3=Color3.fromRGB(50,50,80)
    end
end)
ParryBtn.MouseButton1Click:Connect(function()
    State.AutoParry=not State.AutoParry
    if State.AutoParry then
        ParryBtn.Text="🛡️ Auto Gạt: BẬT"; ParryBtn.BackgroundColor3=Color3.fromRGB(0,160,240)
    else
        ParryBtn.Text="🛡️ Auto Gạt: TẮT"; ParryBtn.BackgroundColor3=Color3.fromRGB(50,50,80)
    end
end)

-- ── SERVER HOP ──
Label(MF,"🔄  SERVER HOP",UDim2.new(1,-20,0,16),UDim2.new(0,12,0,294),
    Color3.fromRGB(200,100,255),11,Enum.Font.GothamBold)

local HopBtn=Btn(MF,"🔄 Server Hop: TẮT",
    UDim2.new(1,-20,0,32),UDim2.new(0,10,0,312),Color3.fromRGB(50,50,80))
HopBtn.MouseButton1Click:Connect(function()
    State.ServerHop=not State.ServerHop
    if State.ServerHop then
        HopBtn.Text="🔄 Server Hop: BẬT ("..CFG_HOP["WaitTime"].."s)"
        HopBtn.BackgroundColor3=Color3.fromRGB(30,120,220)
    else
        HopBtn.Text="🔄 Server Hop: TẮT"
        HopBtn.BackgroundColor3=Color3.fromRGB(50,50,80)
    end
end)

-- ── MIRAGE SECTION ──
Label(MF,"🏝️  MIRAGE ISLAND",UDim2.new(1,-20,0,16),UDim2.new(0,12,0,354),
    Color3.fromRGB(200,100,255),11,Enum.Font.GothamBold)

local MF2=Frame(MF,UDim2.new(1,-20,0,26),UDim2.new(0,10,0,372),Color3.fromRGB(18,18,32),8)
local ML=Label(MF2,"⭕  Chưa tìm",UDim2.new(1,-10,1,0),UDim2.new(0,10,0,0),Color3.fromRGB(150,150,180),11)

local MirageBtn=Btn(MF,"🔍  TÌM MIRAGE ISLAND",
    UDim2.new(1,-20,0,32),UDim2.new(0,10,0,404),Color3.fromRGB(0,150,240))
MirageBtn.MouseButton1Click:Connect(function()
    State.FindMirage=not State.FindMirage
    if State.FindMirage then
        MirageBtn.Text="⏹  DỪNG TÌM"; MirageBtn.BackgroundColor3=Color3.fromRGB(190,40,40)
        ML.Text="🔍 Đang quét..."; ML.TextColor3=Color3.fromRGB(255,200,50)
        coroutine.wrap(function()
            MirageLoop(SL, ML)
            MirageBtn.Text="🔍  TÌM MIRAGE ISLAND"
            MirageBtn.BackgroundColor3=Color3.fromRGB(0,150,240)
        end)()
    else
        MirageBtn.Text="🔍  TÌM MIRAGE ISLAND"; MirageBtn.BackgroundColor3=Color3.fromRGB(0,150,240)
        ML.Text="⛔ Đã dừng"; ML.TextColor3=Color3.fromRGB(255,80,80)
    end
end)

-- ── STOP ALL ──
local StopBtn=Btn(MF,"⛔  STOP ALL",
    UDim2.new(1,-20,0,32),UDim2.new(0,10,0,446),Color3.fromRGB(180,30,30))
StopBtn.MouseButton1Click:Connect(function()
    State.FarmBoss=false; State.FindMirage=false
    State.AutoParry=false; State.AutoCombo=false; State.ServerHop=false
    FarmBtn.Text="▶  START FARM BOSS"; FarmBtn.BackgroundColor3=Color3.fromRGB(50,190,80)
    MirageBtn.Text="🔍  TÌM MIRAGE ISLAND"; MirageBtn.BackgroundColor3=Color3.fromRGB(0,150,240)
    ComboBtn.Text="🗡️ Auto Combo: TẮT"; ComboBtn.BackgroundColor3=Color3.fromRGB(50,50,80)
    ParryBtn.Text="🛡️ Auto Gạt: TẮT"; ParryBtn.BackgroundColor3=Color3.fromRGB(50,50,80)
    HopBtn.Text="🔄 Server Hop: TẮT"; HopBtn.BackgroundColor3=Color3.fromRGB(50,50,80)
    SL.Text="⛔ Đã dừng tất cả"; SL.TextColor3=Color3.fromRGB(255,80,80)
end)

Label(MF,"Kaitun God v2.0  •  Sea 3 Edition",
    UDim2.new(1,0,0,16),UDim2.new(0,0,1,-18),
    Color3.fromRGB(70,70,90),10,Enum.Font.Gotham,Enum.TextXAlignment.Center)

-- ══════════════════════════════════════════
-- KHỞI ĐỘNG TỰ ĐỘNG TỪ CONFIG
-- ══════════════════════════════════════════
if State.FarmBoss then
    task.wait(1)
    FarmBtn.Text="⏹  STOP FARM"; FarmBtn.BackgroundColor3=Color3.fromRGB(190,40,40)
    SL.Text="⚔️ Đang farm: "..State.CurrentBoss
    SL.TextColor3=Color3.fromRGB(100,255,100)
    coroutine.wrap(function() FarmBossLoop(SL) end)()
end

if State.FindMirage then
    task.wait(1)
    MirageBtn.Text="⏹  DỪNG TÌM"; MirageBtn.BackgroundColor3=Color3.fromRGB(190,40,40)
    coroutine.wrap(function() MirageLoop(SL,ML) end)()
end

if State.AutoCombo then
    ComboBtn.Text="🗡️ Auto Combo: BẬT"; ComboBtn.BackgroundColor3=Color3.fromRGB(220,120,0)
end
if State.AutoParry then
    ParryBtn.Text="🛡️ Auto Gạt: BẬT"; ParryBtn.BackgroundColor3=Color3.fromRGB(0,160,240)
end
if State.ServerHop then
    HopBtn.Text="🔄 Server Hop: BẬT ("..CFG_HOP["WaitTime"].."s)"
    HopBtn.BackgroundColor3=Color3.fromRGB(30,120,220)
end

print("✅ KAITUN GOD v2.0 — LOADED!")
SendWebhook("✅ Script Khởi Động",
    "Kaitun God v2.0 đã load!\n**Boss:** "..State.CurrentBoss, 9442302)
