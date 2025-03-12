-- ChatFade.lua - Simplified implementation
-- A module that fades chat elements after periods of inactivity

local addonName, addon = ...
addon.ChatFade = {}
local ChatFade = addon.ChatFade

-- Configuration
ChatFade.config = {
    -- Elements to fade
    elements = {
        "FriendsMicroButton",
        "ChatFrameChannelButton",
        "ChatFrameMenuButton", 
        "ChatFrame1ButtonFrameUpButton",
        "ChatFrame1ButtonFrameDownButton",
        "ChatFrame1ButtonFrameBottomButton"
    },
    
    -- Timing settings
    buttonFadeDelay = 2,      -- Seconds before buttons start fading
    buttonFadeDuration = 2,   -- Seconds for button fade animation
    textFadeDelay = 8,        -- Seconds before text fades
    textFadeDuration = 2      -- Seconds for text fade animation
}

-- State variables
local buttonTimer = 0
local lastMessageTime = 0
local mouseOver = false
local initialized = false

-- Initialize module
function ChatFade:Init()
    if initialized then return end
    
    -- Create frame for OnUpdate
    self.updateFrame = CreateFrame("Frame")
    self.updateFrame:SetScript("OnUpdate", self.OnUpdate)
    
    -- Create message event frame
    self.messageFrame = CreateFrame("Frame")
    self.messageFrame:RegisterEvent("CHAT_MSG_CHANNEL")
    self.messageFrame:RegisterEvent("CHAT_MSG_SAY")
    self.messageFrame:RegisterEvent("CHAT_MSG_YELL")
    self.messageFrame:RegisterEvent("CHAT_MSG_WHISPER")
    self.messageFrame:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
    self.messageFrame:RegisterEvent("CHAT_MSG_PARTY")
    self.messageFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
    self.messageFrame:RegisterEvent("CHAT_MSG_RAID")
    self.messageFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
    self.messageFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
    self.messageFrame:RegisterEvent("CHAT_MSG_GUILD")
    self.messageFrame:RegisterEvent("CHAT_MSG_OFFICER")
    self.messageFrame:RegisterEvent("CHAT_MSG_BN_WHISPER")
    self.messageFrame:RegisterEvent("CHAT_MSG_BN_WHISPER_INFORM")
    self.messageFrame:RegisterEvent("CHAT_MSG_SYSTEM")
    self.messageFrame:SetScript("OnEvent", self.OnChatMessage)
    
    -- Set up mouse tracking for ChatFrame1
    if ChatFrame1 then
        local oldOnEnter = ChatFrame1:GetScript("OnEnter")
        local oldOnLeave = ChatFrame1:GetScript("OnLeave")
        
        ChatFrame1:SetScript("OnEnter", function(self, ...)
            mouseOver = true
            ChatFade:ShowElements()
            ChatFade:ShowText()
            
            if oldOnEnter then
                oldOnEnter(self, ...)
            end
        end)
        
        ChatFrame1:SetScript("OnLeave", function(self, ...)
            mouseOver = false
            buttonTimer = 0 -- Reset the timer
            
            if oldOnLeave then
                oldOnLeave(self, ...)
            end
        end)
    end
    
    -- Set up mouse tracking for buttons
    for _, elementName in ipairs(self.config.elements) do
        local element = _G[elementName]
        if element then
            local oldOnEnter = element:GetScript("OnEnter")
            local oldOnLeave = element:GetScript("OnLeave")
            
            element:SetScript("OnEnter", function(self, ...)
                mouseOver = true
                ChatFade:ShowElements()
                
                if oldOnEnter then
                    oldOnEnter(self, ...)
                end
            end)
            
            element:SetScript("OnLeave", function(self, ...)
                mouseOver = false
                buttonTimer = 0 -- Reset the timer
                
                if oldOnLeave then
                    oldOnLeave(self, ...)
                end
            end)
        end
    end
    
    -- Create invisible frame over chat text to detect mouse events
    if ChatFrame1 and ChatFrame1.FontStringContainer then
        local fontOverlay = CreateFrame("Frame", nil, ChatFrame1)
        fontOverlay:SetAllPoints(ChatFrame1.FontStringContainer)
        fontOverlay:EnableMouse(true)
        
        fontOverlay:SetScript("OnEnter", function()
            mouseOver = true
            ChatFade:ShowText()
        end)
        
        fontOverlay:SetScript("OnLeave", function()
            mouseOver = false
        end)
    end
    
    -- Record current time for initial values
    lastMessageTime = GetTime()
    
    -- Initialize button and text to visible
    self:ShowElements()
    self:ShowText()
    
    initialized = true
   -- print("ChatFade module initialized.")
end

-- Show all UI elements instantly
function ChatFade:ShowElements()
    for _, elementName in ipairs(self.config.elements) do
        local element = _G[elementName]
        if element then
            -- Stop any running animations
            if element.fadeAnim then
                element.fadeAnim:Stop()
            end
            
            -- Set to full visibility
            element:SetAlpha(1.0)
        end
    end
    
    -- Reset button timer
    buttonTimer = 0
end

-- Fade out UI elements smoothly
function ChatFade:FadeElements()
    for _, elementName in ipairs(self.config.elements) do
        local element = _G[elementName]
        if element and element:GetAlpha() > 0 then
            -- Create animation if it doesn't exist
            if not element.fadeAnim then
                element.fadeAnim = element:CreateAnimationGroup()
                local anim = element.fadeAnim:CreateAnimation("Alpha")
                anim:SetFromAlpha(1.0)
                anim:SetToAlpha(0.0)
                anim:SetDuration(self.config.buttonFadeDuration)
                anim:SetSmoothing("OUT")
                
                element.fadeAnim:SetScript("OnFinished", function()
                    element:SetAlpha(0)
                end)
            end
            
            -- Set starting alpha and play
            element:SetAlpha(1.0)
            element.fadeAnim:Play()
        end
    end
end

-- Show chat text instantly
function ChatFade:ShowText()
    local textFrame = ChatFrame1 and ChatFrame1.FontStringContainer
    if textFrame then
        -- Stop any running animations
        if textFrame.fadeAnim then
            textFrame.fadeAnim:Stop()
        end
        
        -- Set to full visibility
        textFrame:SetAlpha(1.0)
        
        -- Reset message timer
        lastMessageTime = GetTime()
    end
end

-- Fade out chat text smoothly
function ChatFade:FadeText()
    local textFrame = ChatFrame1 and ChatFrame1.FontStringContainer
    if textFrame and textFrame:GetAlpha() > 0 then
        -- Create animation if it doesn't exist
        if not textFrame.fadeAnim then
            textFrame.fadeAnim = textFrame:CreateAnimationGroup()
            local anim = textFrame.fadeAnim:CreateAnimation("Alpha")
            anim:SetFromAlpha(1.0)
            anim:SetToAlpha(0.0)
            anim:SetDuration(self.config.textFadeDuration)
            anim:SetSmoothing("OUT")
            
            textFrame.fadeAnim:SetScript("OnFinished", function()
                textFrame:SetAlpha(0)
            end)
        end
        
        -- Set starting alpha and play
        textFrame:SetAlpha(1.0)
        textFrame.fadeAnim:Play()
    end
end

-- OnUpdate handler
function ChatFade.OnUpdate(frame, elapsed)
    if not initialized then return end
    
    -- Handle button fading
    if not mouseOver then
        buttonTimer = buttonTimer + elapsed
        
        if buttonTimer >= ChatFade.config.buttonFadeDelay then
            ChatFade:FadeElements()
            buttonTimer = ChatFade.config.buttonFadeDelay -- Cap the timer
        end
    end
    
    -- Handle text fading
    if not mouseOver and lastMessageTime > 0 then
        local timeSinceLastMessage = GetTime() - lastMessageTime
        
        if timeSinceLastMessage >= ChatFade.config.textFadeDelay then
            ChatFade:FadeText()
            -- Don't reset lastMessageTime to prevent constant fading
        end
    end
end

-- Chat message event handler
function ChatFade.OnChatMessage(frame, event, ...)
    if not initialized then return end
    
    -- Update message time and show text
    lastMessageTime = GetTime()
    ChatFade:ShowText()
end


-- Initialize when addon loads
local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(1, function()
            ChatFade:Init()
        end)
    end
end)