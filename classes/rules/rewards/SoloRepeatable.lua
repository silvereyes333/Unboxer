
-- Repeatable activites (e.g. dailies, Rewards for the Worthy, etc.)

local addon = Unboxer
local class = addon:Namespace("rules.rewards")
local rules = addon.classes.rules
local knownIds
local debug = false
local staticDlcs, skillLineNameStrings
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
            knownIds      = knownIds
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

skillLineNameStrings = {
    SI_UNBOXER_UNDAUNTED_LOWER,
    SI_UNBOXER_DARK_BROTHERHOOD_LOWER,
    SI_UNBOXER_THIEVES_GUILD_LOWER,
    SI_UNBOXER_MAGES_GUILD_LOWER,
    SI_UNBOXER_FIGHTERS_GUILD_LOWER,
    SI_UNBOXER_PSIJIC_ORDER_LOWER,
}

knownIds = {
  [133560] = true, -- Slag Town Coffer. "Coffer" isn't used for this item in ruESO, unfortunately.
  [151936] = true, -- Wax-Sealed Heavy Sack, dropped from Elsweyr dragon attacks?
  [55452]=1,[56865]=1,[71312]=1,[74679]=1,[74680]=1,[77526]=1,[77556]=1,[79674]=1,[81561]=1,
  [81601]=1,[94087]=1,[94088]=1,[94121]=1,[94122]=1,[95826]=1,[95827]=1,[96385]=1,[96386]=1,
  [96387]=1,[119550]=1,[119551]=1,[119552]=1,[119553]=1,[119554]=1,[121220]=1,[126030]=1,
  [126031]=1,[126032]=1,[126033]=1,[133225]=1,[133559]=1,[134619]=1,[135004]=1,[135006]=1,
  [135023]=1,[135136]=1,[138800]=1,[138812]=1,[140252]=1,[140425]=1,[140426]=1,[141741]=1,
  [145577]=1,[147287]=1,[147649]=1,[147650]=1,[150700]=1,[150721]=1,[151620]=1,[151623]=1,
  [151941]=1
}