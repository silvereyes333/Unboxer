
-- Repeatable activites (e.g. dailies, Rewards for the Worthy, etc.)

local addon = Unboxer
local class = addon:Namespace("rules.rewards")
local rules = addon.classes.rules
local debug = false
local staticDlcs, skillLineNameStrings, knownIds
local submenu = GetString(SI_UNBOXER_QUEST_REWARDS)

class.SoloRepeatable = addon.classes.Rule:Subclass()
function class.SoloRepeatable:New()
    local instance = addon.classes.Rule.New(
        self, 
        {
            name          = "solorepeatable",
            exampleItemId = 134619, -- Rewards for the Worthy
            dependencies  = { "crafting", "festival", "furnisher", "materials", "legerdemain", "trial", "vendorgear", "telvar" },
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_REPEATABLE),
            -- knownIds      = knownIds
        })
    instance.pts = rules.Pts:New()
    return instance
end

function class.SoloRepeatable:Match(data)
  
    -- Match preloaded ids
    if knownIds[data.itemId] then
        return self:IsUnboxableMatch()
    end
  
    if addon:StringContainsPunctuationColon(data.name)
       or data.quality == ITEM_QUALITY_LEGENDARY
       or string.find(data.icon, "justice_stolen_case_001") -- strong boxes
    then
        return
    end
    
    -- Match champion caches
    if string.find(data.icon, "mail_armor_container") then
        return self:IsUnboxableMatch()
    end
    
    -- Match dragon attack drops
    if string.find(data.icon, "digested") then
        return self:IsUnboxableMatch()
    end
    
    if data.bindType == BIND_TYPE_ON_PICKUP then
      
        -- Daily reward containers
        if self:MatchDailyQuestText(data.name)
           or self:MatchDailyQuestText(data.flavorText)
        then
            return self:IsUnboxableMatch()
        end
    
        if addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_COFFER_LOWER) -- "coffer"
           or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_COFFER2_LOWER)
           or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_GIFT_FROM_LOWER) -- "gift from" boxes
           or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_GIFT_FROM2_LOWER)
        then
            return self:IsUnboxableMatch()
        end
    end
    
    
    
    --[[ EVERYTHING BELOW HERE SHOULD EXCLUDE SPECIFICALLY-MATCHED PTS GEAR ]]--
    if self.pts:MatchExceptIcon(data) then return end
    
    
    
    
    if self:MatchGuildSkillLineName(data.name) -- Matches "Merit" for guild skill tree lines
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_CYRODIIL_LOWER) -- cyrodiil in name
    then
        return self:IsUnboxableMatch()
    end
end

function class.SoloRepeatable:MatchGuildSkillLineName(text)
    for _, stringId in ipairs(skillLineNameStrings) do
        if addon:StringContainsStringIdOrDefault(text, stringId) then
            return true
        end
    end
end

function class.SoloRepeatable:MatchDailyQuestText(text)
    return addon:StringContainsStringIdOrDefault(text, SI_UNBOXER_REWARD_LOWER)
           or addon:StringContainsStringIdOrDefault(text, SI_UNBOXER_DAILY_LOWER)
           or addon:StringContainsStringIdOrDefault(text, SI_UNBOXER_DAILY2_LOWER)
           or addon:StringContainsStringIdOrDefault(text, SI_UNBOXER_JOB_LOWER)
           or addon:StringContainsStringIdOrDefault(text, SI_UNBOXER_JOB2_LOWER)
end

knownIds = {
  [133560] = true, -- Slag Town Coffer. "Coffer" isn't used for this item in ruESO, unfortunately.
  [151936] = true, -- Wax-Sealed Heavy Sack, dropped from Elsweyr dragon attacks?
}

skillLineNameStrings = {
    SI_UNBOXER_UNDAUNTED_LOWER,
    SI_UNBOXER_DARK_BROTHERHOOD_LOWER,
    SI_UNBOXER_THIEVES_GUILD_LOWER,
    SI_UNBOXER_MAGES_GUILD_LOWER,
    SI_UNBOXER_FIGHTERS_GUILD_LOWER,
    SI_UNBOXER_PSIJIC_ORDER_LOWER,
}