-- LibramSwap.lua

local LibramMap = {
    ["Consecration"]         = "Libram of the Faithful",
    ["Holy Shield"]          = "Libram of the Dreamguard",
    ["Holy Light"]           = "Libram of Radiance",
    ["Flash of Light"]       = "Libram of Light",
    ["Cleanse"]              = "Libram of Grace",
    ["Hammer of Justice"]    = "Libram of the Justicar",
    ["Hand of Freedom"]      = "Libram of the Resolute",
    ["Crusader Strike"]      = "Libram of the Eternal Tower",
    ["Holy Strike"]          = "Libram of the Eternal Tower",
    ["Seal of Wisdom"]       = "Libram of Hope",
    ["Seal of Light"]        = "Libram of Hope",
    ["Seal of Justice"]      = "Libram of Hope",
    ["Seal of Command"]      = "Libram of Hope",
    ["Seal of the Crusader"] = "Libram of Hope",
    ["Seal of Righteousness"] = "Libram of Hope",
}

local function EquipLibram(itemName)
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link and string.find(link, itemName) then
                UseContainerItem(bag, slot)
                DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAAFF[LibramSwap]: Equipped|r " .. itemName)
                return true
            end
        end
    end
    return false
end

-- Disabled cooldown check for now to allow spells like Cleanse or Holy Shield to proceed
-- Can be restored later with better handling for spells that actually have cooldowns
--[[
local function IsSpellReady(spell)
    local start, duration, enabled = GetSpellCooldown(spell)
    return enabled == 1 and (start + duration - GetTime()) <= 0
end
]]

local function CastWithLibram(spellName)
    local libram = LibramMap[spellName]

    if libram then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAAFF[LibramSwap]: Trying to cast|r " .. spellName .. " with |cFFFFFF00" .. libram)
        local equipped = EquipLibram(libram)
        if not equipped then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8800[LibramSwap]: Libram not found, casting anyway:|r " .. spellName)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAAFF[LibramSwap]: No libram mapped for|r " .. spellName .. ", casting normally.")
    end

    CastSpellByName(spellName)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[LibramSwap]: Casting|r " .. spellName)
    return true
end

SLASH_LIBRAMCAST1 = "/libramcast"
SlashCmdList["LIBRAMCAST"] = function(msg)
    if not msg or msg == "" then
        DEFAULT_CHAT_FRAME:AddMessage("Usage: /libramcast Spell Name")
        return
    end
    CastWithLibram(msg)
end
