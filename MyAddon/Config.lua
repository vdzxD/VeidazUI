-- Config.lua
local addonName, MyAddon = ...


-- Initialize AuraConfig
MyAddon.AuraConfig = {
    categories = {
        immunities = {
            priority = 1,  -- Highest priority
            auras = {
                ["Blessing of Protection"] = { filter = "immunities", priority = 1 },
                ["Divine Shield"] = { filter = "immunities", priority = 1 },
                ["Ice Block"] = { filter = "immunities", priority = 1 },
                ["Bladestorm"] = { filter = "immunities", priority = 1 },
                ["Anti-Magic Shell"] = { filter = "immunities", priority = 1 },
                ["Grounding Totem Effect"] = { filter = "immunities", priority = 1 },
                ["The Beast Within"] = { filter = "immunities", priority = 1 },
                ["Cloak of Shadows"] = { filter = "immunities", priority = 1 },
                ["Spell Reflection"] = { filter = "immunities", priority = 1 },
                ["Dispersion"] = { filter = "immunities", priority = 1 }
            }
        },
        cc = {
            priority = 2,  -- Second highest priority
            auras = {
                ["Strangulate"] = { filter = "cc", priority = 1 },
                ["Gnaw"] = { filter = "cc", priority = 1 },
                ["Hungering Cold"] = { filter = "cc", priority = 1 },
                ["Psychic Horror"] = { filter = "cc", priority = 1 },
                ["Mind Control"] = { filter = "cc", priority = 1 },
                ["Psychic Scream"] = { filter = "cc", priority = 1 },
                ["Silence"] = { filter = "cc", priority = 1 },
                ["Seduction"] = { filter = "cc", priority = 1 },
                ["Fear"] = { filter = "cc", priority = 1 },
                ["Howl of Terror"] = { filter = "cc", priority = 1 },
                ["Banish"] = { filter = "cc", priority = 1 },
                ["Death Coil"] = { filter = "cc", priority = 1 },
                ["Shadowfury"] = { filter = "cc", priority = 1 },
                ["Hex"] = { filter = "cc", priority = 1 },
                ["Hammer of Justice"] = { filter = "cc", priority = 1 },
                ["Repentance"] = { filter = "cc", priority = 1 },
                ["Turn Evil"] = { filter = "cc", priority = 1 },
                ["Polymorph"] = { filter = "cc", priority = 1 },
                ["Dragon's Breath"] = { filter = "cc", priority = 1 },
                ["Deep Freeze"] = { filter = "cc", priority = 1 },
                ["Cyclone"] = { filter = "cc", priority = 1 },
                ["Hibernate"] = { filter = "cc", priority = 1 },
                ["Freezing Trap"] = { filter = "cc", priority = 1 },
                ["Wyvern Sting"] = { filter = "cc", priority = 1 },
                ["Scatter Shot"] = { filter = "cc", priority = 1 },
                ["Blind"] = { filter = "cc", priority = 1 },
                ["Sap"] = { filter = "cc", priority = 1 },
                ["Gouge"] = { filter = "cc", priority = 1 },
                ["Kidney Shot"] = { filter = "cc", priority = 1 },
                ["Cheap Shot"] = { filter = "cc", priority = 1 }
            }
        },
        roots = {
            priority = 3,  -- Third priority
            auras = {
                ["Entangling Roots"] = { filter = "roots", priority = 1 },
                ["Frost Nova"] = { filter = "roots", priority = 1 },
                ["Freeze"] = { filter = "roots", priority = 1 },
                ["Feral Charge Effect"] = { filter = "roots", priority = 1 },
                ["Earthgrab"] = { filter = "roots", priority = 1 },
                ["Frost Shock"] = { filter = "roots", priority = 1 }
            }
        },
        buffs_defensive = {
            priority = 4,  -- Fourth priority
            auras = {
                ["Pain Suppression"] = { filter = "buffs_defensive", priority = 1 },
                ["Guardian Spirit"] = { filter = "buffs_defensive", priority = 1 },
                ["Divine Protection"] = { filter = "buffs_defensive", priority = 1 },
                ["Barkskin"] = { filter = "buffs_defensive", priority = 1 },
                ["Survival Instincts"] = { filter = "buffs_defensive", priority = 1 },
                ["Icebound Fortitude"] = { filter = "buffs_defensive", priority = 1 },
                ["Anti-Magic Zone"] = { filter = "buffs_defensive", priority = 1 },
                ["Nature's Swiftness"] = { filter = "buffs_defensive", priority = 1 },
                ["Shamanistic Rage"] = { filter = "buffs_defensive", priority = 1 },
                ["Aura Mastery"] = { filter = "buffs_defensive", priority = 1 },
                ["Divine Sacrifice"] = { filter = "buffs_defensive", priority = 1 },
                ["Blessing of Sacrifice"] = { filter = "buffs_defensive", priority = 1 },
                ["Frenzied Regeneration"] = { filter = "buffs_defensive", priority = 1 },
                ["Evasion"] = { filter = "buffs_defensive", priority = 1 },
                ["Combat Readiness"] = { filter = "buffs_defensive", priority = 1 },
                ["Cheating Death"] = { filter = "buffs_defensive", priority = 1 },
                ["Inner Focus"] = { filter = "buffs_defensive", priority = 1 }
            }
        },
        buffs_offensive = {
            priority = 5,  -- Lowest priority
            auras = {
                ["Bloodlust"] = { filter = "buffs_offensive", priority = 1 },
                ["Heroism"] = { filter = "buffs_offensive", priority = 1 },
                ["Avenging Wrath"] = { filter = "buffs_offensive", priority = 1 },
                ["Metamorphosis"] = { filter = "buffs_offensive", priority = 1 },
                ["Berserk"] = { filter = "buffs_offensive", priority = 1 },
                ["Arcane Power"] = { filter = "buffs_offensive", priority = 1 },
                ["Power Infusion"] = { filter = "buffs_offensive", priority = 1 },
                ["Rapid Fire"] = { filter = "buffs_offensive", priority = 1 },
                ["Bestial Wrath"] = { filter = "buffs_offensive", priority = 1 },
                ["Recklessness"] = { filter = "buffs_offensive", priority = 1 },
                ["Death Wish"] = { filter = "buffs_offensive", priority = 1 },
                ["Unholy Frenzy"] = { filter = "buffs_offensive", priority = 1 },
                ["Shadow Dance"] = { filter = "buffs_offensive", priority = 1 },
                ["Killing Spree"] = { filter = "buffs_offensive", priority = 1 },
                ["Adrenaline Rush"] = { filter = "buffs_offensive", priority = 1 },
                ["Divine Plea"] = { filter = "buffs_offensive", priority = 1 },
                ["Zealotry"] = { filter = "buffs_offensive", priority = 1 },
                ["Combustion"] = { filter = "buffs_offensive", priority = 1 }
            }
        }
    }
}

-- GetTrackedAuras function with detailed debugging
function MyAddon.AuraConfig.GetTrackedAuras()
    local trackedAuras = {}
    print("Building tracked auras list...")
    
    if not MyAddon.SpellData then
        print("ERROR: MyAddon.SpellData is nil!")
        return trackedAuras
    end
    
    print("Found SpellData with", pairs(MyAddon.SpellData))
    
    for categoryName, categoryData in pairs(MyAddon.AuraConfig.categories) do
        print("Checking category:", categoryName)
        for auraName, auraData in pairs(categoryData.auras) do
            print("  Checking aura:", auraName)
            if MyAddon.SpellData[auraName] then
                local spellData = MyAddon.SpellData[auraName]
                print("    Found spell data. ID:", spellData.spellID)
                trackedAuras[spellData.spellID] = {
                    iconID = spellData.iconID,
                    priority = categoryData.priority
                }
            else
                print("    No spell data found for:", auraName)
            end
        end
    end
    
    local count = 0
    for _ in pairs(trackedAuras) do count = count + 1 end
    print("Total tracked auras:", count)
    return trackedAuras
end

-- Debug print to verify loading
print("Config.lua loaded - MyAddon.AuraConfig initialized")