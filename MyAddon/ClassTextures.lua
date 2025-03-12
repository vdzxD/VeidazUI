local frame = CreateFrame("Frame")



-- Class atlas mapping
-- local classAtlasMap = {
--     DEATHKNIGHT = "ClassHall-Circle-DeathKnight",
--     DRUID = "ClassHall-Circle-Druid",
--     HUNTER = "ClassHall-Circle-Hunter",
--     MAGE = "ClassHall-Circle-Mage",
--     PALADIN = "ClassHall-Circle-Paladin",
--     PRIEST = "ClassHall-Circle-Priest",
--     ROGUE = "ClassHall-Circle-Rogue",
--     SHAMAN = "ClassHall-Circle-Shaman",
--     WARLOCK = "ClassHall-Circle-Warlock",
--     WARRIOR = "ClassHall-Circle-Warrior"
-- }

-- -- Class texture function
-- local function ShowClassTexture()
--     local _, class = UnitClass("player")
--     local atlasName = classAtlasMap[class]
--     if not atlasName then return end
    
--     local classFrame = CreateFrame("Frame", "ClassFrame", PlayerFrame)
--     classFrame:SetSize(27.5, 27.5)
--     classFrame:SetPoint("CENTER", PlayerFrame, "CENTER", -63, -16)
--     classFrame:SetFrameStrata("MEDIUM")
--     local texture = classFrame:CreateTexture(nil, "OVERLAY")
--     texture:SetAllPoints(classFrame)
--     texture:SetAtlas(atlasName)
-- end

-- frame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- frame:SetScript("OnEvent", function(self, event, arg1)
--     if event == "PLAYER_ENTERING_WORLD" then
--         ShowClassTexture()
--     end
-- end)




local frame = CreateFrame("Frame")

-- Class color mapping
local classColors = {
    DEATHKNIGHT = {r = 0.77, g = 0.12, b = 0.23},
    DRUID = {r = 1.00, g = 0.49, b = 0.04},
    HUNTER = {r = 0.67, g = 0.83, b = 0.45},
    MAGE = {r = 0.41, g = 0.80, b = 0.94},
    PALADIN = {r = 0.96, g = 0.55, b = 0.73},
    PRIEST = {r = 1.00, g = 1.00, b = 1.00},
    ROGUE = {r = 1.00, g = 0.96, b = 0.41},
    SHAMAN = {r = 0.00, g = 0.44, b = 0.87},
    WARLOCK = {r = 0.58, g = 0.51, b = 0.79},
    WARRIOR = {r = 0.78, g = 0.61, b = 0.43}
}

-- Function to set status bar colors for a specific unit
local function UpdateUnitColors(unit)
    if not UnitExists(unit) then return end
    
    local _, class = UnitClass(unit)
    local color = classColors[class]
    
    if color then
        if unit == "player" then
            PlayerFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b)
        elseif unit == "target" then
            TargetFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b)
        elseif unit == "focus" then
            FocusFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b)
        elseif unit == "targettarget" then
            TargetFrameToTHealthBar:SetStatusBarColor(color.r, color.g, color.b)
        elseif unit == "focustarget" then
            FocusFrameToTHealthBar:SetStatusBarColor(color.r, color.g, color.b)
        end
    end
end

-- Hook the StatusBar SetValue method to maintain colors
local function HookStatusBar(statusBar, unit)
    local oldSetValue = statusBar.SetValue
    statusBar.SetValue = function(self, ...)
        oldSetValue(self, ...)
        UpdateUnitColors(unit)
    end
end

-- Initialize hooks and events
local function Initialize()
    -- Hook all frames
    HookStatusBar(PlayerFrameHealthBar, "player")
    HookStatusBar(TargetFrameHealthBar, "target")
    HookStatusBar(FocusFrameHealthBar, "focus")
    HookStatusBar(TargetFrameToTHealthBar, "targettarget")
    HookStatusBar(FocusFrameToTHealthBar, "focustarget")
end

-- Register events
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterEvent("UNIT_HEALTH_FREQUENT")

frame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_ENTERING_WORLD" then
        Initialize()
        UpdateUnitColors("player")
    elseif event == "PLAYER_TARGET_CHANGED" then
        UpdateUnitColors("target")
        UpdateUnitColors("targettarget")
    elseif event == "PLAYER_FOCUS_CHANGED" then
        UpdateUnitColors("focus")
        UpdateUnitColors("focustarget")
    elseif event == "UNIT_HEALTH" or event == "UNIT_HEALTH_FREQUENT" then
        if unit == "player" or unit == "target" or unit == "focus" or 
           unit == "targettarget" or unit == "focustarget" then
            UpdateUnitColors(unit)
        end
    end
end)


