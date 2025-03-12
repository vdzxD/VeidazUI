-- Create a parent frame for your addon
local addonName, addon = ...  -- Get addon namespace

local MyAddonFrame = CreateFrame("Frame", "MyAddonFrame", UIParent)
MyAddonFrame:SetSize(300, 300)  -- Adjust overall frame size as needed
MyAddonFrame:SetPoint("CENTER", UIParent, "CENTER")  -- Center on screen
MyAddonFrame:SetFrameStrata("DIALOG")
MyAddonFrame:SetFrameLevel(5)

-- Define adjustable values for texture size, original offsets, and spacing
local textureWidth = 100
local textureHeight = 120
local xOffset = 0    -- Original horizontal offset for the entire group
local yOffset = -366.5    -- Original vertical offset for the entire group
local spacing = 357    -- Horizontal spacing between the two textures

-- Create a container frame to hold both textures with higher strata
local groupFrame = CreateFrame("Frame", "GroupFrame", MyAddonFrame)
groupFrame:SetSize((textureWidth * 2) + spacing, textureHeight)
groupFrame:SetPoint("CENTER", MyAddonFrame, "CENTER", xOffset, yOffset)
groupFrame:SetFrameStrata("DIALOG")
groupFrame:SetFrameLevel(5)

-- Create holder frames for each texture at a higher level
local holder1 = CreateFrame("Frame", nil, groupFrame)
holder1:SetFrameStrata("DIALOG")
holder1:SetFrameLevel(5)
holder1:SetSize(textureWidth, textureHeight)
holder1:SetPoint("LEFT", groupFrame, "LEFT", 0, 0)

local holder2 = CreateFrame("Frame", nil, groupFrame)
holder2:SetFrameStrata("DIALOG")
holder2:SetFrameLevel(5)
holder2:SetSize(textureWidth, textureHeight)
holder2:SetPoint("LEFT", holder1, "RIGHT", spacing, 0)

-- Path to your custom gryphon texture
local gryphonTexturePath = "Interface\\AddOns\\MyAddon\\Textures\\Gryphon.blp"

-- Create the first texture (normal) anchored to its holder
local texture1 = holder1:CreateTexture(nil, "OVERLAY", nil, 7)
-- Use SetTexture instead of SetAtlas for custom gryphon BLP
texture1:SetTexture(gryphonTexturePath)
texture1:SetSize(textureWidth, textureHeight)
texture1:SetAllPoints(holder1)

-- Create the second texture (mirrored) anchored to its holder
local texture2 = holder2:CreateTexture(nil, "OVERLAY", nil, 7)
-- Use SetTexture instead of SetAtlas for custom gryphon BLP
texture2:SetTexture(gryphonTexturePath)
texture2:SetSize(textureWidth, textureHeight)
texture2:SetAllPoints(holder2)
-- Mirror the texture horizontally by flipping its texture coordinates
texture2:SetTexCoord(1, 0, 0, 1)

-- Adjustable values for the Forge texture
local forgeTextureWidth = 95   -- 
local forgeTextureHeight = 405   -- 
local forgeXOffset = 0       -- Horizontal offset relative to MyAddonFrame
local forgeYOffset = -375       -- Vertical offset relative to MyAddonFrame

-- Create a holder frame for the Forge texture
local forgeHolder = CreateFrame("Frame", nil, MyAddonFrame)
forgeHolder:SetFrameStrata("BACKGROUND")
forgeHolder:SetFrameLevel(5)
forgeHolder:SetSize(forgeTextureWidth, forgeTextureHeight)
forgeHolder:SetPoint("CENTER", MyAddonFrame, "CENTER", forgeXOffset, forgeYOffset)

-- Create the Forge texture (keeping it as atlas texture)
local forgeTexture = forgeHolder:CreateTexture(nil, "OVERLAY", nil, 7)
forgeTexture:SetAtlas("Forge-Background", false)
forgeTexture:SetAllPoints(forgeHolder)

-- Rotate the texture by 90 degrees (90° is math.rad(90) in radians)
if forgeTexture.SetRotation then
    forgeTexture:SetRotation(math.rad(90))
else
    -- Fallback: manually adjust texture coordinates.
    -- Note: This method assumes the texture is square.
    forgeTexture:SetTexCoord(1, 0, 1, 0, 0, 1, 0, 1)
end

-- Add error handling to display a message if gryphon texture is missing
if not texture1:GetTexture() then
    print(addonName..": Could not find custom gryphon texture: Gryphon.blp")
    -- Fallback to the default atlas texture if the custom one is missing
    texture1:SetAtlas("hud-MainMenuBar-gryphon", false)
    texture2:SetAtlas("hud-MainMenuBar-gryphon", false)
    texture2:SetTexCoord(1, 0, 0, 1)  -- Re-apply mirroring
end