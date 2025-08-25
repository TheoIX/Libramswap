-- LibramSwap.lua (Turtle WoW 1.12)
-- Swaps librams for specific spells, but ONLY when the spell is ready (no CD/GCD).
-- Uses a 1.12-safe IsSpellReady() and avoids retail-era APIs.

-- =====================
-- Locals / Aliases
-- =====================
local GetContainerNumSlots  = GetContainerNumSlots
local GetContainerItemLink  = GetContainerItemLink
local UseContainerItem      = UseContainerItem
local GetInventoryItemLink  = GetInventoryItemLink
local GetSpellName          = GetSpellName
local GetSpellCooldown      = GetSpellCooldown
local GetTime               = GetTime
local string_find           = string.find
local BOOKTYPE_SPELL        = BOOKTYPE_SPELL or "spell"

-- Toggle
local LibramSwapEnabled = false
local lastEquippedLibram = nil
local lastSwapTime = 0

-- =====================
-- Config
-- =====================
-- If you still notice micro stutter in 40-mans, try raising to 1.4–1.6
local SWAP_THROTTLE = 1.48

-- Map spells -> preferred libram name (bag/equipped link substring match)
local LibramMap = {
    ["Consecration"]                  = "Libram of the Faithful",
    ["Holy Shield"]                   = "Libram of the Dreamguard",
    ["Holy Light"]                    = "Libram of Radiance",
    ["Flash of Light"]                = "Libram of Light",
    ["Cleanse"]                       = "Libram of Grace",
    ["Hammer of Justice"]             = "Libram of the Justicar",
    ["Hand of Freedom"]               = "Libram of the Resolute",
    ["Crusader Strike"]               = "Libram of the Eternal Tower",
    ["Holy Strike"]                   = "Libram of the Eternal Tower",
    ["Seal of Wisdom"]                = "Libram of Hope",
    ["Seal of Light"]                 = "Libram of Hope",
    ["Seal of Justice"]               = "Libram of Hope",
    ["Seal of Command"]               = "Libram of Hope",
    ["Seal of the Crusader"]          = "Libram of Fervor",
    ["Seal of Righteousness"]         = "Libram of Hope",
    ["Devotion Aura"]                 = "Libram of Truth",
    ["Blessing of Might"]             = "Libram of Veracity",
    ["Blessing of Wisdom"]            = "Libram of Veracity",
    ["Blessing of Kings"]             = "Libram of Veracity",
    ["Blessing of Sanctuary"]         = "Libram of Veracity",
    ["Blessing of Light"]             = "Libram of Veracity",
    ["Blessing of Salvation"]         = "Libram of Veracity",
    ["Greater Blessing of Might"]     = "Libram of Veracity",
    ["Greater Blessing of Wisdom"]    = "Libram of Veracity",
    ["Greater Blessing of Kings"]     = "Libram of Veracity",
    ["Greater Blessing of Sanctuary"] = "Libram of Veracity",
    ["Greater Blessing of Light"]     = "Libram of Veracity",
    ["Greater Blessing of Salvation"] = "Libram of Veracity",
}

-- =====================
-- Spell Readiness (1.12-safe)
-- =====================
-- Returns: ready:boolean, start:number, duration:number
local function IsSpellReady(spellName)
    for i = 1, 300 do
        local name, rank = GetSpellName(i, BOOKTYPE_SPELL)
        if not name then break end
        if spellName == name or (rank and spellName == (name .. "(" .. rank .. ")")) then
            local start, duration, enabled = GetSpellCooldown(i, BOOKTYPE_SPELL)
            return enabled == 1 and (start == 0 or duration == 0), start or 0, duration or 0
        end
    end
    return false, 0, 0
end

-- =====================
-- Helpers
-- =====================

-- Add this near your other locals/helpers:
local function IsInteractionBusy()
    -- Block swaps when any UI that reinterprets right-clicks is open
    return (MerchantFrame and MerchantFrame:IsVisible())
        or (BankFrame and BankFrame:IsVisible())
        or (AuctionFrame and AuctionFrame:IsVisible())
        or (TradeFrame and TradeFrame:IsVisible())
        or (MailFrame and MailFrame:IsVisible())
        or (QuestFrame and QuestFrame:IsVisible())
        or (GossipFrame and GossipFrame:IsVisible())
end


local function HasItemInBags(itemName)
    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag)
        if slots and slots > 0 then
            for slot = 1, slots do
                local link = GetContainerItemLink(bag, slot)
                if link and string_find(link, itemName, 1, true) then
                    return bag, slot
                end
            end
        end
    end
    return nil
end

local function EquipLibram(itemName)
    -- Already equipped?
    local equipped = GetInventoryItemLink("player", 17)
    if equipped and string_find(equipped, itemName, 1, true) then
        lastEquippedLibram = itemName
        return false
    end

    -- NEW: Safety guard — never swap while vendor/bank/auction/etc. is open
    if IsInteractionBusy() then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF5555[LibramSwap]: Swap blocked (vendor/bank/auction/trade/mail/quest window open).|r")
        return false
    end

    -- Throttle swaps
    local now = GetTime()
    if (now - lastSwapTime) < SWAP_THROTTLE then
        return false
    end

    local bag, slot = HasItemInBags(itemName)
    if bag and slot then
        UseContainerItem(bag, slot)
        lastEquippedLibram = itemName
        lastSwapTime = now
        -- Reduce spam if desired by commenting this out
        DEFAULT_CHAT_FRAME:AddMessage("|cFFAAAAFF[LibramSwap]: Equipped|r " .. itemName)
        return true
    end
    return false
end

local function ResolveLibramForSpell(spellName)
    local libram = LibramMap[spellName]
    if not libram then return nil end

    -- Fallbacks if best pick isn't present
    if spellName == "Flash of Light" then
        if not HasItemInBags("Libram of Light") and HasItemInBags("Libram of Divinity") then
            libram = "Libram of Divinity"
        end
    elseif spellName == "Holy Strike" then
        if not HasItemInBags("Libram of the Eternal Tower") and HasItemInBags("Libram of Radiance") then
            libram = "Libram of Radiance"
        end
    end
    return libram
end

-- =====================
-- Hooks (CastSpellByName / CastSpell)
-- =====================
local Original_CastSpellByName = CastSpellByName
function CastSpellByName(spellName, bookType)
    if LibramSwapEnabled then
        local libram = ResolveLibramForSpell(spellName)
        if libram then
            local ready = IsSpellReady(spellName)
            if ready then
                EquipLibram(libram)
            end
        end
    end
    return Original_CastSpellByName(spellName, bookType)
end

local Original_CastSpell = CastSpell
function CastSpell(spellIndex, bookType)
    if LibramSwapEnabled then
        local sName = GetSpellName(spellIndex, bookType)
        local libram = ResolveLibramForSpell(sName)
        if libram then
            local ready = IsSpellReady(sName)
            if ready then
                EquipLibram(libram)
            end
        end
    end
    return Original_CastSpell(spellIndex, bookType)
end

-- =====================
-- Slash Command
-- =====================
SLASH_LIBRAMSWAP1 = "/libramswap"
SlashCmdList["LIBRAMSWAP"] = function()
    LibramSwapEnabled = not LibramSwapEnabled
    if LibramSwapEnabled then
        DEFAULT_CHAT_FRAME:AddMessage("LibramSwap ENABLED", 0, 1, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("LibramSwap DISABLED", 1, 0, 0)
    end
end

