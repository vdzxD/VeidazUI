local addonName, MyAddon = ...

-- Initialize the CombatAlert module if it doesn't exist
MyAddon.CombatAlert = MyAddon.CombatAlert or {}

-- Configuration
local CONFIG = {
    -- Text settings
    enterText = "Entering Combat",
    leaveText = "Leaving Combat",
    dispelText = "Dispelled %s", -- %s will be replaced with the dispelled spell name
    queueText = "Time in Queue: %ss", -- Will be formatted with elapsed seconds
    mmrText = "MMR Info", -- Placeholder (actual text is built dynamically)
    enterColor = {r = 1.0, g = 0.3, b = 0.3},   -- Red
    leaveColor = {r = 0.3, g = 1.0, b = 0.3},   -- Green
    dispelColor = {r = 1.0, g = 1.0, b = 1.0},    -- white (should be)
    queueColor = {r = 1.0, g = 1.0, b = 0.0},     -- Yellow (for the queue timer)
    
    -- Display settings
    displayTime = 1.5,   -- For combat/dispel alerts
    mmrDisplayTime = 10, -- How long the MMR info stays visible (in seconds)
    
    -- Position settings
    combatPosition = {
        point = "CENTER",
        relativeTo = "UIParent",
        relativePoint = "CENTER",
        xOffset = 0,
        yOffset = -175
    },
    dispelPosition = {
        point = "CENTER",
        relativeTo = "UIParent",
        relativePoint = "CENTER",
        xOffset = 0,
        yOffset = 180
    },
    queuePosition = {
        point = "CENTER",
        relativeTo = "UIParent",
        relativePoint = "CENTER",
        xOffset = 0,
        yOffset = 250
    },
    mmrPosition = {
        point = "CENTER",
        relativeTo = "UIParent",
        relativePoint = "CENTER",
        xOffset = 0,
        yOffset = 300
    },
    
    font = "Fonts\\FRIZQT__.TTF",
    fontSize = 15,
    fontFlags = "OUTLINE",
}

-----------------------------------------------------
-- Combat Alert (Existing Functionality)
-----------------------------------------------------

local combatFrame = nil
local function SetupCombatFrame()
    if combatFrame then 
        return combatFrame 
    end
    
    combatFrame = CreateFrame("Frame", "MyCombatAlertFrame", UIParent)
    combatFrame:SetSize(400, 50)
    combatFrame:SetPoint(
        CONFIG.combatPosition.point, 
        CONFIG.combatPosition.relativeTo, 
        CONFIG.combatPosition.relativePoint, 
        CONFIG.combatPosition.xOffset, 
        CONFIG.combatPosition.yOffset
    )
    combatFrame:SetFrameStrata("HIGH")
    combatFrame:Hide()
    
    combatFrame.text = combatFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    combatFrame.text:SetPoint("CENTER", combatFrame, "CENTER")
    combatFrame.text:SetFont(CONFIG.font, CONFIG.fontSize, CONFIG.fontFlags)
    
    return combatFrame
end

local function ShowCombatAlert(text, color)
    local frame = SetupCombatFrame()
    frame.text:SetText(text)
    frame.text:SetTextColor(color.r, color.g, color.b)
    frame:Show()
    C_Timer.After(CONFIG.displayTime, function()
        frame:Hide()
    end)
end

-----------------------------------------------------
-- Dispel Alert (Existing Functionality)
-----------------------------------------------------

local activeDispelAlerts = {}

local function ShowDispelAlert(text, color)
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(400, 50)
    
    local offset = (#activeDispelAlerts) * 24
    frame:SetPoint(
        CONFIG.dispelPosition.point, 
        CONFIG.dispelPosition.relativeTo, 
        CONFIG.dispelPosition.relativePoint, 
        CONFIG.dispelPosition.xOffset, 
        CONFIG.dispelPosition.yOffset - offset
    )
    frame:SetFrameStrata("HIGH")
    
    local textObj = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    textObj:SetPoint("CENTER", frame, "CENTER")
    textObj:SetFont(CONFIG.font, CONFIG.fontSize, CONFIG.fontFlags)
    textObj:SetText(text)
    textObj:SetTextColor(color.r, color.g, color.b)
    
    frame:Show()
    table.insert(activeDispelAlerts, frame)
    
    C_Timer.After(CONFIG.displayTime, function()
        frame:Hide()
        for i, f in ipairs(activeDispelAlerts) do
            if f == frame then
                table.remove(activeDispelAlerts, i)
                break
            end
        end
    end)
end

-----------------------------------------------------
-- Queue Timer Alert (Translated from WeakAura)
-----------------------------------------------------

local queueFrame = nil
local queueStartTime = nil

local function SetupQueueFrame()
    if queueFrame then 
        return queueFrame 
    end
    
    queueFrame = CreateFrame("Frame", "MyQueueAlertFrame", UIParent)
    queueFrame:SetSize(400, 50)
    queueFrame:SetPoint(
        CONFIG.queuePosition.point,
        CONFIG.queuePosition.relativeTo,
        CONFIG.queuePosition.relativePoint,
        CONFIG.queuePosition.xOffset,
        CONFIG.queuePosition.yOffset
    )
    queueFrame:SetFrameStrata("HIGH")
    queueFrame:Hide()
    
    queueFrame.text = queueFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    queueFrame.text:SetPoint("CENTER", queueFrame, "CENTER")
    queueFrame.text:SetFont(CONFIG.font, CONFIG.fontSize, CONFIG.fontFlags)
    
    return queueFrame
end

local function StartQueueTimer()
    queueStartTime = GetTime()
    local frame = SetupQueueFrame()
    frame:Show()
    frame:SetScript("OnUpdate", function(self, elapsed)
        local elapsedTime = GetTime() - queueStartTime
        -- To show whole seconds without tenths, use math.floor or %d formatting:
        self.text:SetText("Time in Queue: " .. math.floor(elapsedTime) .. "s")
    end)
end

local function StopQueueTimer()
    local frame = SetupQueueFrame()
    frame:Hide()
    frame:SetScript("OnUpdate", nil)
    queueStartTime = nil
end

-----------------------------------------------------
-- MMR Display Alert (Translated from WeakAura)
-----------------------------------------------------

local mmrFrame = nil
local function SetupMMRFrame()
    if mmrFrame then 
        return mmrFrame 
    end
    
    mmrFrame = CreateFrame("Frame", "MyMMRAlertFrame", UIParent)
    mmrFrame:SetSize(400, 50)
    mmrFrame:SetPoint(
        CONFIG.mmrPosition.point,
        CONFIG.mmrPosition.relativeTo,
        CONFIG.mmrPosition.relativePoint,
        CONFIG.mmrPosition.xOffset,
        CONFIG.mmrPosition.yOffset
    )
    mmrFrame:SetFrameStrata("HIGH")
    mmrFrame:Hide()
    
    mmrFrame.text = mmrFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mmrFrame.text:SetPoint("CENTER", mmrFrame, "CENTER")
    mmrFrame.text:SetFont(CONFIG.font, CONFIG.fontSize, CONFIG.fontFlags)
    
    return mmrFrame
end

local function UpdateMMRAlert()
    local frame = SetupMMRFrame()
    local displayString = ""
    
    for i = 0, 1 do
        local teamName, teamRating, newTeamRating, teamMMR, numPlayers = GetBattlefieldTeamInfo(i)
        if teamMMR and teamMMR > 0 then
            local currentTeamDisplayString = string.format('"%s" MMR: %d', teamName, teamMMR)
            local teamColor = 'ffbd67ff'
            if i == 1 then 
                teamColor = 'ffffd500'
            end
            displayString = displayString .. string.format("|c%s%s|r\n", teamColor, currentTeamDisplayString)
        end
    end
    
    if displayString ~= "" then
        frame.text:SetText(displayString)
        frame:Show()
        C_Timer.After(CONFIG.mmrDisplayTime, function()
            frame:Hide()
        end)
    end
end

-----------------------------------------------------
-- Event Handlers
-----------------------------------------------------

-- Primary events frame (for combat, dispel, etc.)
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entering combat
events:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Leaving combat
events:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") -- For dispel detection

events:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_REGEN_DISABLED" then
        ShowCombatAlert(CONFIG.enterText, CONFIG.enterColor)
    elseif event == "PLAYER_REGEN_ENABLED" then
        ShowCombatAlert(CONFIG.leaveText, CONFIG.leaveColor)
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local playerGUID = UnitGUID("player")
        local petGUID = UnitGUID("pet")  -- Get the player's pet GUID
        
        if CombatLogGetCurrentEventInfo then
            local timestamp, eventType, hideCaster, sourceGUID, sourceName, sourceFlags, 
                  sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, 
                  spellID, spellName, spellSchool, extraSpellID, extraSpellName = CombatLogGetCurrentEventInfo()
            
            -- Check if the source is player OR player's pet
            local isPlayerDispel = sourceGUID == playerGUID
            local isPetDispel = petGUID and sourceGUID == petGUID
            
            if (eventType == "SPELL_DISPEL" or eventType == "SPELL_STOLEN") and (isPlayerDispel or isPetDispel) then
                local sourceName = isPlayerDispel and "You" or "Pet"
                local dispelledSpellName = extraSpellName or "Unknown"
                local dispelText = string.format(CONFIG.dispelText, dispelledSpellName)
                
                -- Optional: Add the source to the text if desired
                -- local dispelText = string.format("%s %s", sourceName, string.format(CONFIG.dispelText, dispelledSpellName))
                
                ShowDispelAlert(dispelText, CONFIG.dispelColor)
            end
        else
            -- For older client versions
            local eventType = select(2, ...)
            local sourceGUID = select(4, ...)
            local extraSpellName = select(16, ...) or "Unknown"
            
            -- Check if the source is player OR player's pet
            local isPlayerDispel = sourceGUID == playerGUID
            local isPetDispel = petGUID and sourceGUID == petGUID
            
            if (eventType == "SPELL_DISPEL" or eventType == "SPELL_STOLEN") and (isPlayerDispel or isPetDispel) then
                local sourceName = isPlayerDispel and "You" or "Pet"
                local dispelText = string.format(CONFIG.dispelText, extraSpellName)
                
                -- Optional: Add the source to the text if desired
                -- local dispelText = string.format("%s %s", sourceName, string.format(CONFIG.dispelText, extraSpellName))
                
                ShowDispelAlert(dispelText, CONFIG.dispelColor)
            end
        end
    end
end)

-- Separate events frame for the queue timer
local queueEvents = CreateFrame("Frame")
queueEvents:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
queueEvents:RegisterEvent("SOCIAL_QUEUE_UPDATE")
queueEvents:RegisterEvent("UI_INFO_MESSAGE")

queueEvents:SetScript("OnEvent", function(self, event, ...)
    local status = GetBattlefieldStatus(1)
    if status == "queued" then
        if not queueStartTime then
            StartQueueTimer()
        end
    else
        if queueStartTime then
            StopQueueTimer()
        end
    end
end)

-- Separate events frame for the MMR display
local mmrEvents = CreateFrame("Frame")
mmrEvents:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")
mmrEvents:SetScript("OnEvent", function(self, event, ...)
    if event == "UPDATE_BATTLEFIELD_SCORE" then
        UpdateMMRAlert()
    end
end)

-----------------------------------------------------
-- API Functions for Customization
-----------------------------------------------------

function MyAddon.CombatAlert:SetEnterText(text)
    CONFIG.enterText = text
end

function MyAddon.CombatAlert:SetLeaveText(text)
    CONFIG.leaveText = text
end

function MyAddon.CombatAlert:SetDispelText(format)
    CONFIG.dispelText = format
end

function MyAddon.CombatAlert:SetQueueText(format)
    CONFIG.queueText = format
end

function MyAddon.CombatAlert:SetMMRText(format)
    CONFIG.mmrText = format
end

function MyAddon.CombatAlert:SetFontSize(size)
    CONFIG.fontSize = size
    if combatFrame and combatFrame.text then
        local font, _, flags = combatFrame.text:GetFont()
        combatFrame.text:SetFont(font, size, flags)
    end
    if queueFrame and queueFrame.text then
        local font, _, flags = queueFrame.text:GetFont()
        queueFrame.text:SetFont(font, size, flags)
    end
    if mmrFrame and mmrFrame.text then
        local font, _, flags = mmrFrame.text:GetFont()
        mmrFrame.text:SetFont(font, size, flags)
    end
    -- Note: Dispel alerts are created on the fly using CONFIG.font.
end

function MyAddon.CombatAlert:SetCombatPosition(point, relativePoint, x, y)
    CONFIG.combatPosition.point = point
    CONFIG.combatPosition.relativePoint = relativePoint
    CONFIG.combatPosition.xOffset = x
    CONFIG.combatPosition.yOffset = y
    if combatFrame then
        combatFrame:ClearAllPoints()
        combatFrame:SetPoint(point, UIParent, relativePoint, x, y)
    end
end

function MyAddon.CombatAlert:SetDispelPosition(point, relativePoint, x, y)
    CONFIG.dispelPosition.point = point
    CONFIG.dispelPosition.relativePoint = relativePoint
    CONFIG.dispelPosition.xOffset = x
    CONFIG.dispelPosition.yOffset = y
end

function MyAddon.CombatAlert:SetQueuePosition(point, relativePoint, x, y)
    CONFIG.queuePosition.point = point
    CONFIG.queuePosition.relativePoint = relativePoint
    CONFIG.queuePosition.xOffset = x
    CONFIG.queuePosition.yOffset = y
    if queueFrame then
        queueFrame:ClearAllPoints()
        queueFrame:SetPoint(point, UIParent, relativePoint, x, y)
    end
end

function MyAddon.CombatAlert:SetMMRPosition(point, relativePoint, x, y)
    CONFIG.mmrPosition.point = point
    CONFIG.mmrPosition.relativePoint = relativePoint
    CONFIG.mmrPosition.xOffset = x
    CONFIG.mmrPosition.yOffset = y
    if mmrFrame then
        mmrFrame:ClearAllPoints()
        mmrFrame:SetPoint(point, UIParent, relativePoint, x, y)
    end
end

-----------------------------------------------------
-- Slash Commands for Easy Configuration
-----------------------------------------------------

SLASH_COMBATALERT1 = "/combatalert"
SlashCmdList["COMBATALERT"] = function(msg)
    local args = {}
    for arg in msg:gmatch("%S+") do
        table.insert(args, arg)
    end
    
    if args[1] == "combat" and args[2] == "pos" and #args >= 6 then
        local point = args[3]
        local relPoint = args[4]
        local x = tonumber(args[5])
        local y = tonumber(args[6])
        if point and relPoint and x and y then
            MyAddon.CombatAlert:SetCombatPosition(point, relPoint, x, y)
            print("Combat alert position updated")
        else
            print("Invalid arguments. Usage: /combatalert combat pos POINT RELPOINT X Y")
        end
    elseif args[1] == "dispel" and args[2] == "pos" and #args >= 6 then
        local point = args[3]
        local relPoint = args[4]
        local x = tonumber(args[5])
        local y = tonumber(args[6])
        if point and relPoint and x and y then
            MyAddon.CombatAlert:SetDispelPosition(point, relPoint, x, y)
            print("Dispel alert position updated")
        else
            print("Invalid arguments. Usage: /combatalert dispel pos POINT RELPOINT X Y")
        end
    elseif args[1] == "queue" and args[2] == "pos" and #args >= 6 then
        local point = args[3]
        local relPoint = args[4]
        local x = tonumber(args[5])
        local y = tonumber(args[6])
        if point and relPoint and x and y then
            MyAddon.CombatAlert:SetQueuePosition(point, relPoint, x, y)
            print("Queue alert position updated")
        else
            print("Invalid arguments. Usage: /combatalert queue pos POINT RELPOINT X Y")
        end
    elseif args[1] == "mmr" and args[2] == "pos" and #args >= 6 then
        local point = args[3]
        local relPoint = args[4]
        local x = tonumber(args[5])
        local y = tonumber(args[6])
        if point and relPoint and x and y then
            MyAddon.CombatAlert:SetMMRPosition(point, relPoint, x, y)
            print("MMR alert position updated")
        else
            print("Invalid arguments. Usage: /combatalert mmr pos POINT RELPOINT X Y")
        end
    else
        print("Combat Alert Commands:")
        print("  /combatalert combat pos POINT RELPOINT X Y - Set combat alert position")
        print("  /combatalert dispel pos POINT RELPOINT X Y - Set dispel alert position")
        print("  /combatalert queue pos POINT RELPOINT X Y - Set queue alert position")
        print("  /combatalert mmr pos POINT RELPOINT X Y - Set MMR alert position")
        print("Example: /combatalert combat pos CENTER CENTER 0 50")
    end
end

-----------------------------------------------------
-- C_Timer Fallback for Classic WoW
-----------------------------------------------------

if not C_Timer then
    C_Timer = {}
    C_Timer.After = function(duration, callback)
        local timer = CreateFrame("Frame")
        timer.start = GetTime()
        timer.duration = duration
        timer.callback = callback
        timer:SetScript("OnUpdate", function(self)
            if GetTime() >= self.start + self.duration then
                self.callback()
                self:SetScript("OnUpdate", nil)
            end
        end)
        return timer
    end
end
