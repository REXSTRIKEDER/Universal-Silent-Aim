local CORE = "https://raw.githubusercontent.com/xUnanimous/es/main/"
local VERSION_DATA = game:GetService("HttpService"):JSONDecode(game:HttpGet(CORE.."versions.json"));

local CURRENT_VERSION = "2287859"
local IS_OUTDATED_VERSION = VERSION_DATA["Universal Silent Aim"] ~= CURRENT_VERSION
local DISCORD_SERVER = VERSION_DATA["DISCORD"]

-- Create UI


local CallCounter = {
    RC = 0,
    FPOR = 0,
    FPORWIL = 0,
    FPORWWL = 0
}

local UserInputService = game:GetService("UserInputService")

local Library = loadstring(game:HttpGet('https://raw.githubusercontent.com/Rain-Design/PPHUD/main/Library.lua'))()
local Flags = Library.Flags do -- draw ui
    local function REG_A(X) Flags["Silent_Aim_HitPart"]=X end
    local function REG_B(X) Flags["Silent_Aim_Method"]=X end

    -- Preload flags (poopy ui lib doesn't do it as soon as a component is created)
    Flags["Silent_Aim_Enabled"] = false
    Flags["Silent_Aim_Team_Check"] = false
    Flags["Silent_Aim_HitPart"] = "Head"
    Flags["Silent_Aim_Method"] = "UNKNOWN"

    Flags["Hit_Chance_Enabled"] = false
    Flags["Hit_Chance_Percentage"] = 100

    Flags["Field_Of_View_Enabled"] = false
    Flags["Field_Of_View_Radius"] = 180

    -- Create the entire window
    local Window = Library:Window({Text = "Universal Silent Aim by xUnanimous " .. (IS_OUTDATED_VERSION and "[RUNNING OUTDATED VERSION]" or "") .. (" | discord.gg/%s"):format(DISCORD_SERVER) .. " | [Right Shift]"}) do
        UserInputService.InputBegan:Connect(function(Input, Processed)
            if Input.KeyCode == Enum.KeyCode.RightShift and not Processed then
                Window:Toggle()
            end
        end)

        local MainTab = Window:Tab({Text = "Main"}) do
            local SilentAimSection = MainTab:Section({Text = "Silent Aim"}) do
                SilentAimSection:Check({Text = "Enabled", Flag = "Silent_Aim_Enabled"})
                SilentAimSection:Check({Text = "Team Check", Flag = "Silent_Aim_Team_Check"})
                SilentAimSection:Dropdown({Text = "Hit Part", List = {"Head", "HumanoidRootPart"}, Default = "Head", Flag = "Silent_Aim_HitPart", Callback=REG_A})
                SilentAimSection:Dropdown({Text = "Hit Method", List = {"RC", "FPOR", "FPORWIL", "FPORWWL"}, Flag = "Silent_Aim_Method", Callback=REG_B})
            end
            local HitChanceSection = MainTab:Section({Text = "Hit Chance"}) do
                HitChanceSection:Check({Text = "Enabled", Flag = "Hit_Chance_Enabled"})
                HitChanceSection:Slider({Text = "Hit Percentage", Minimum = 0, Default = 100, Maximum = 100, Postfix = "%", Flag = "Hit_Chance_Percentage"})
            end
            local FieldOfViewSection = MainTab:Section({Text = "Field Of View", Side = "Right"}) do
                FieldOfViewSection:Check({Text = "Enabled", Flag = "Field_Of_View_Enabled"})
                FieldOfViewSection:Slider({Text = "Radius", Minimum = 0, Default = 360, Maximum = 720, Flag = "Field_Of_View_Radius"})
            end
        end
        local InformationTab = Window:Tab({Text = "Information"}) do
            local MethodLogger = InformationTab:Section({Text = "Method Logger"}) do
                local RC = MethodLogger:Label({Text = "RC CALLS: 0"})
                local FPOR = MethodLogger:Label({Text = "FPOR CALLS: 0"})
                local FPORWIL = MethodLogger:Label({Text = "FPORWIL CALLS: 0"})
                local FPORWWL = MethodLogger:Label({Text = "FPORWWL CALLS: 0"})

                task.spawn(function()
                    while task.wait(1) do
                        RC:Set("RC CALLS:"..CallCounter.RC)
                        FPOR:Set("FPOR CALLS:"..CallCounter.FPOR)
                        FPORWIL:Set("FPORWIL CALLS:"..CallCounter.FPORWIL)
                        FPORWWL:Set("FPORWWL CALLS:"..CallCounter.FPORWWL)
                    end
                end)
            end
            local DebugSection = InformationTab:Section({Text = "Flag Status"}) do
                for _, v in next, Flags do
                    local dbg = DebugSection:Label({Text = ("%s: %s"):format(_, tostring(v))})
                    task.spawn(function()
                        while task.wait(1) do
                            dbg:Set(("%s: %s"):format(_, tostring(Flags[_])))
                        end
                    end)
                end
            end
            local ScriptDetails = InformationTab:Section({Text = "Script Details", Side = "Right"}) do
                ScriptDetails:Label({Text = "Running Version: " .. CURRENT_VERSION})
                ScriptDetails:Label({Text = ("New Version Available: %s"):format(IS_OUTDATED_VERSION and ("YES (version: %s)"):format(VERSION_DATA["Universal Silent Aim"]) or "NO")})
                ScriptDetails:Label({Text = ("Discord Server: discord.gg/%s"):format(DISCORD_SERVER)})
                ScriptDetails:Label({Text = "Developed by: xUnanimous"})
                ScriptDetails:Label({Text = "GitHub: xUnanimous/es/uni-sa0"})
            end
        end

        MainTab:Select()
    end
end

-- Flag list

-- Silent_Aim_Enabled
-- Silent_Aim_Team_Check
-- Silent_Aim_Method
-- Hit_Chance_Enabled
-- Hit_Chance_Percentage
-- Field_Of_View_Enabled
-- Field_Of_View_Radius

-- Main Script

local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera

local function weighted_random(weights) -- from stackoverflow
    local summ = 0
    for i, weight in pairs (weights) do
        summ = summ + weight
    end
    if summ == 0 then return end
    local value = summ*math.random ()
    summ = 0
    for i, weight in pairs (weights) do
        summ = summ + weight
        if value <= summ then
            return i, weight
        end
    end
end

local function CanHit()
    -- Hit_Chance_Enabled
    -- Hit_Chance_Percentage
    if Flags["Hit_Chance_Enabled"] then
        local Data = {
            CantHit = 100 - Flags["Hit_Chance_Percentage"],
            CanHit = Flags["Hit_Chance_Percentage"]
        }

        return weighted_random(Data) == "CanHit"
    end

    return true
end

local function v2_v3(v3) return Vector2.new(v3.X, v3.Y) end

local function GetClosestTargetToCursor()
    local Cursor_Location = UserInputService.GetMouseLocation(UserInputService)
    local ClosestTarget, ClosestDistance = nil, math.huge

    for _, Player in next, Players.GetPlayers(Players) do
        if Player ~= Players.LocalPlayer and (Flags["Silent_Aim_Team_Check"] and Player.Team ~= Players.LocalPlayer.Team or not Flags["Silent_Aim_Team_Check"]) then
            local Character = Player.Character
            local Humanoid = Character and Character.FindFirstChild(Character, "Humanoid")
            if Humanoid and Humanoid.Health > 0 then
                local HitTarget = Character.FindFirstChild(Character, Flags["Silent_Aim_HitPart"])
                if HitTarget then
                    local v3, vis = Camera.WorldToScreenPoint(Camera, HitTarget.Position)
                    if vis then
                        local DistanceToMouse = (Cursor_Location - v2_v3(v3)).Magnitude
                        if Flags["Field_Of_View_Enabled"] and DistanceToMouse < Flags["Field_Of_View_Radius"] and DistanceToMouse < ClosestDistance
                            or not Flags["Field_Of_View_Enabled"] and DistanceToMouse < ClosestDistance then
                            ClosestTarget = HitTarget
                            ClosestDistance = DistanceToMouse
                        end
                    end
                end
            end
        end
    end

    return ClosestTarget, ClosestDistance
end

local function GetDirection(O, D) return (D-O).Unit*(D-O).Magnitude end

local ncMethodHelper = {
    ["RC"] = "Raycast",
    ["FPOR"] = "FindPartOnRay",
    ["FPORWIL"] = "FindPartOnRayWithIgnoreList",
    ["FPORWWL"] = "FindPartOnRayWithWhitelist"
}

local function RegisterCall(X)
    if X == "Raycast" then
        CallCounter.RC = CallCounter.RC + 1
    elseif X == "FindPartOnRay" then
        CallCounter.FPOR = CallCounter.FPOR + 1
    elseif X == "FindPartOnRayWithIgnoreList" then
        CallCounter.FPORWIL = CallCounter.FPORWIL + 1
    elseif X == "FindPartOnRayWithWhitelist" then
        CallCounter.FPORWWL = CallCounter.FPORWWL + 1
    end
end

local OldNamecall OldNamecall = hookmetamethod(game, "__namecall", function(...)
    local Method = ncMethodHelper[Flags["Silent_Aim_Method"]]
    RegisterCall(getnamecallmethod())
    if Flags["Silent_Aim_Enabled"] then
        if getnamecallmethod() == Method then
            -- Raycast(origin: Vector3, direction: Vector3, raycastParams: RaycastParams)
            if Method == "Raycast" then
                local Target = GetClosestTargetToCursor()
                if Target and CanHit() then
                    local PackedArguments = {...}
                    local Origin = PackedArguments[2]
                    PackedArguments[3] = GetDirection(Origin, Target.Position) -- Direction
                    return OldNamecall(unpack(PackedArguments))
                end
            -- FindPartOnRay(ray: Ray, ignoreDescendantsInstance: Instance, terrainCellsAreCubes: boolean, ignoreWater: boolean)
            elseif Method == "FindPartOnRay" then
                local Target = GetClosestTargetToCursor()
                if Target and CanHit() then
                    local PackedArguments = {...}
                    local BaseRay = PackedArguments[2]
                    PackedArguments[2] = Ray.new(BaseRay.Origin, GetDirection(BaseRay.Origin, Target.Position))
                    return OldNamecall(unpack(PackedArguments))
                end
            -- FindPartOnRayWithIgnoreList(ray: Ray, ignoreDescendantsTable: Objects, terrainCellsAreCubes: boolean, ignoreWater: boolean)
            elseif Method == "FindPartOnRayWithIgnoreList" then
                local Target = GetClosestTargetToCursor()
                if Target and CanHit() then
                    local PackedArguments = {...}
                    local BaseRay = PackedArguments[2]
                    PackedArguments[2] = Ray.new(BaseRay.Origin, GetDirection(BaseRay.Origin, Target.Position))
                    return OldNamecall(unpack(PackedArguments))
                end
            -- FindPartOnRayWithWhitelist(ray: Ray, whitelistDescendantsTable: Objects, ignoreWater: boolean)
            elseif Method == "FindPartOnRayWithWhitelist" then
                local Target = GetClosestTargetToCursor()
                if Target and CanHit() then
                    local PackedArguments = {...}
                    local BaseRay = PackedArguments[2]
                    PackedArguments[2] = Ray.new(BaseRay.Origin, GetDirection(BaseRay.Origin, Target.Position))
                    return OldNamecall(unpack(PackedArguments))
                end
            end
        end
    end
    return OldNamecall(...)
end)