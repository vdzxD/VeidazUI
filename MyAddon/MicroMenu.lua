local addonName, MyAddon = ...

-- Create the parent frame
local myMicroMenu = CreateFrame("Frame", "MyMicroMenu", UIParent)
myMicroMenu:SetSize(400, 40)
myMicroMenu:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 4)

-- Create animation group for fading
local fadeGroup = myMicroMenu:CreateAnimationGroup()
local fadeOut = fadeGroup:CreateAnimation("Alpha")
fadeOut:SetFromAlpha(1)
fadeOut:SetToAlpha(0)
fadeOut:SetDuration(4)
fadeOut:SetSmoothing("OUT")
fadeGroup:SetScript("OnFinished", function() myMicroMenu:SetAlpha(0) end)

-- Create animation group for fading out after mouseover
local mouseOutFadeGroup = myMicroMenu:CreateAnimationGroup()
local mouseOutFade = mouseOutFadeGroup:CreateAnimation("Alpha")
mouseOutFade:SetFromAlpha(1)
mouseOutFade:SetToAlpha(0)
mouseOutFade:SetDuration(2)
mouseOutFade:SetSmoothing("OUT")
mouseOutFadeGroup:SetScript("OnFinished", function() myMicroMenu:SetAlpha(0) end)

-- Configuration table for all micro buttons
local microButtons = {
    {
        name = "Character",
        atlas = {up = "hud-microbutton-Character-Up", down = "hud-microbutton-Character-Down"},
        tooltip = "Character Info",
        func = function() ToggleCharacter("PaperDollFrame") end
    },
    {
        name = "Spellbook",
        atlas = {up = "hud-microbutton-Spellbook-Up", down = "hud-microbutton-Spellbook-Down"},
        tooltip = "Spellbook & Abilities",
        func = function() ToggleSpellBook(BOOKTYPE_SPELL) end
    },
    {
        name = "Talent",
        atlas = {up = "hud-microbutton-Talents-Up", down = "hud-microbutton-Talents-Down"},
        tooltip = "Talents",
        func = function() 
            if PlayerTalentFrame_Toggle then
                PlayerTalentFrame_Toggle()
            else
                ToggleTalentFrame() 
            end
        end
    },
    {
        name = "Achievement",
        atlas = {up = "hud-microbutton-Achievement-Up", down = "hud-microbutton-Achievement-Down"},
        tooltip = "Achievements",
        func = function() ToggleAchievementFrame() end
    },
    {
        name = "Quest",
        atlas = {up = "hud-microbutton-Quest-Up", down = "hud-microbutton-Quest-Down"},
        tooltip = "Quest Log",
        func = function() ToggleQuestLog() end
    },
    {
        name = "Guild",
        atlas = {up = "hud-microbutton-Guild-Up", down = "hud-microbutton-Guild-Down"},
        tooltip = "Guild",
        func = function() 
            if IsInGuild() then
                if GuildFrame_Toggle then
                    GuildFrame_Toggle() 
                else
                    ToggleGuildFrame()
                end
            else
                if GuildFrame_Toggle then
                    GuildFrame_Toggle() 
                else
                    ToggleGuildFrame()
                end
            end
        end
    },
    {
        name = "Collections",
        atlas = {up = "hud-microbutton-Mounts-Up", down = "hud-microbutton-Mounts-Down"},
        tooltip = "Collections",
        func = function()
            if CollectionsJournal_LoadUI then
                CollectionsJournal_LoadUI()
            end
            if ToggleCollectionsJournal then
                ToggleCollectionsJournal()
            else
                -- Cataclysm fallback for mounts/pets
                TogglePetJournal()
            end
        end
    },
    {
        name = "LFG",
        atlas = {up = "hud-microbutton-LFG-Up", down = "hud-microbutton-LFG-Down"},
        tooltip = "Dungeon Finder",
        func = function() 
            PVEFrame_ToggleFrame("GroupFinderFrame", LFDParentFrame)
        end
    },
    {
        name = "EJ",
        atlas = {up = "hud-microbutton-EJ-Up", down = "hud-microbutton-EJ-Down"},
        tooltip = "Encounter Journal",
        func = function()
            if EncounterJournal_LoadUI then
                EncounterJournal_LoadUI()
            end
            if ToggleEncounterJournal then
                ToggleEncounterJournal()
            end
        end
    },
    {
        name = "MainMenu",
        atlas = {up = "hud-microbutton-MainMenu-Up", down = "hud-microbutton-MainMenu-Down"},
        tooltip = "Game Menu",
        func = function() ToggleGameMenu() end
    },
    {
        name = "Help",
        atlas = {up = "hud-microbutton-Help-Up", down = "hud-microbutton-Help-Down"},
        tooltip = "Help",
        func = function() ToggleHelpFrame() end
    }
}

-- Create the buttons
local buttons = {}
local BUTTON_SIZE = 32
local BUTTON_SPACING = 2

-- Function to create a micro button
local function CreateMicroButton(buttonInfo, index)
    local button = CreateFrame("Button", "My"..buttonInfo.name.."MicroButton", myMicroMenu, "SecureActionButtonTemplate")
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    
    -- Position button
    if index == 1 then
        button:SetPoint("LEFT", myMicroMenu, "LEFT", 5, 0)
    else
        button:SetPoint("LEFT", buttons[index-1], "RIGHT", BUTTON_SPACING, 0)
    end
    
    -- Set up the atlas textures
    button:SetNormalAtlas(buttonInfo.atlas.up)
    button:SetPushedAtlas(buttonInfo.atlas.down)
    button:SetHighlightAtlas(buttonInfo.atlas.up)
    button:SetDisabledAtlas(buttonInfo.atlas.up)
    
    -- Add tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(buttonInfo.tooltip)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Set click handler
    button:SetScript("OnClick", function(self, mouseButton)
        if mouseButton == "LeftButton" then
            buttonInfo.func()
        end
    end)
    
    return button
end

-- Create all buttons
for i, buttonInfo in ipairs(microButtons) do
    buttons[i] = CreateMicroButton(buttonInfo, i)
end

-- Adjust parent frame width based on number of buttons
myMicroMenu:SetWidth((BUTTON_SIZE * #buttons) + (BUTTON_SPACING * (#buttons - 1)) + 10)

-- Helper function to reposition the frame
function MyAddon.RepositionMicroMenu(point, relativeTo, relativePoint, x, y)
    myMicroMenu:ClearAllPoints()
    myMicroMenu:SetPoint(point, relativeTo or UIParent, relativePoint, x, y)
end

-- Add the repositioning function and animation controls to MyAddon table
MyAddon.MicroMenu = {
    Frame = myMicroMenu,
    Buttons = buttons,
    Reposition = MyAddon.RepositionMicroMenu,
    FadeIn = function()
        mouseOutFadeGroup:Stop()
        myMicroMenu:SetAlpha(1)
    end,
    FadeOut = function(immediate)
        if immediate then
            myMicroMenu:SetAlpha(0)
        else
            fadeGroup:Play()
        end
    end,
    MouseOutFade = function()
        mouseOutFadeGroup:Play()
    end
}

-- Slash command to reposition the micro menu
SLASH_MICROMENU1 = "/mmpos"
SlashCmdList["MICROMENU"] = function(msg)
    local args = {}
    for arg in msg:gmatch("%S+") do
        table.insert(args, arg)
    end
    
    if #args >= 4 then
        local point = args[1]:upper()
        local relativePoint = args[2]:upper()
        local x = tonumber(args[3])
        local y = tonumber(args[4])
        
        if point and relativePoint and x and y then
            MyAddon.RepositionMicroMenu(point, UIParent, relativePoint, x, y)
            print("MicroMenu position updated to:", point, relativePoint, x, y)
        else
            print("Invalid arguments. Usage: /mmpos POINT RELPOINT X Y")
        end
    else
        print("Usage: /mmpos POINT RELPOINT X Y")
        print("Example: /mmpos BOTTOMRIGHT BOTTOMRIGHT -10 10")
    end
end

-- Command to toggle visibility
SLASH_TOGGLEMM1 = "/togglemm"
SlashCmdList["TOGGLEMM"] = function(msg)
    if myMicroMenu:IsShown() then
        myMicroMenu:Hide()
        print("MicroMenu hidden")
    else
        myMicroMenu:Show()
        print("MicroMenu shown")
    end
end

-- Fix for potentially missing PVEFrame_ToggleFrame function in Cataclysm
if not PVEFrame_ToggleFrame then
    PVEFrame_ToggleFrame = function(frame, self)
        if LFDParentFrame:IsShown() then
            HideUIPanel(LFDParentFrame)
        else
            ShowUIPanel(LFDParentFrame)
        end
    end
end

-- Setup mouse over detection area (making it larger than the actual menu for easier discovery)
local mouseOverFrame = CreateFrame("Frame", nil, UIParent)
mouseOverFrame:SetSize(myMicroMenu:GetWidth() + 20, myMicroMenu:GetHeight() + 20)
mouseOverFrame:SetPoint("CENTER", myMicroMenu, "CENTER")
mouseOverFrame:SetFrameStrata("BACKGROUND")
mouseOverFrame:EnableMouse(false) -- We're just using this for hit detection, not to capture mouse events

-- Variable to track if mouse is over the menu
local isMouseOver = false

-- Setup mouse tracking
myMicroMenu:SetScript("OnEnter", function()
    isMouseOver = true
    MyAddon.MicroMenu.FadeIn()
end)

myMicroMenu:SetScript("OnLeave", function()
    isMouseOver = false
    C_Timer.After(0.2, function() -- Small delay before checking if we should fade out
        if not isMouseOver then
            MyAddon.MicroMenu.MouseOutFade()
        end
    end)
end)

-- Make each button also trigger the mouse over state
for _, button in pairs(buttons) do
    button:HookScript("OnEnter", function()
        isMouseOver = true
        MyAddon.MicroMenu.FadeIn()
    end)
    
    button:HookScript("OnLeave", function()
        isMouseOver = false
        C_Timer.After(0.2, function()
            if not isMouseOver then
                MyAddon.MicroMenu.MouseOutFade()
            end
        end)
    end)
end

-- Run initial fade out on login
C_Timer.After(1, function() 
    MyAddon.MicroMenu.FadeOut()
end)

-- Create a detect frame for mouse movement
local mouseMoveDetector = CreateFrame("Frame")
mouseMoveDetector:SetScript("OnUpdate", function(self, elapsed)
    -- Use direct cursor position check instead of GetMouseFocus
    local mouseX, mouseY = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    mouseX, mouseY = mouseX / scale, mouseY / scale
    
    local left, bottom, width, height = mouseOverFrame:GetRect()
    if not left then return end
    
    if mouseX >= left and mouseX <= (left + width) and 
       mouseY >= bottom and mouseY <= (bottom + height) then
        if not isMouseOver then
            isMouseOver = true
            MyAddon.MicroMenu.FadeIn()
        end
    else
        if isMouseOver then
            isMouseOver = false
            C_Timer.After(0.2, function()
                if not isMouseOver then
                    MyAddon.MicroMenu.MouseOutFade()
                end
            end)
        end
    end
end)