
-- Repeatable activites (e.g. dailies, Rewards for the Worthy, etc.)

local addon = Unboxer
local class = addon:Namespace("rules.rewards")
local rules = addon.classes.rules
local knownIds, excludedIds
local debug = false
local staticDlcs, skillLineNameStrings
local submenu = GetString(SI_UNBOXER_QUEST_REWARDS)

class.SoloRepeatable = addon.classes.Rule:Subclass()
function class.SoloRepeatable:New()
    return addon.classes.Rule.New(
        self, 
        {
            name          = "solorepeatable",
            exampleItemIds = {
                96387,  -- [Undaunted Merits]
                151620, -- [Elsweyr Daily Merit Coffer]
                121220, -- [Yokudan Coffer of Distinction]
            },
            dependencies  = { "crafting", "colon", "excluded", "excluded2", "festival", "furnisher", "materials", "legerdemain", "pvp", "trial", "vendorgear", "telvar" },
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_REPEATABLE),
            knownIds      = knownIds
        })
end

function class.SoloRepeatable:Match(data)
    
    if string.find(data.icon, "justice_stolen_case_001") -- strong boxes
       or data.bindType ~= BIND_TYPE_ON_PICKUP 
       or excludedIds[data.itemId]
    then 
        return
    end
    
    if self:MatchDailyQuestText(data.name) -- Daily reward containers
       or self:MatchDailyQuestText(data.flavorText)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_COFFER_LOWER) -- "coffer"
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_COFFER2_LOWER)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_GIFT_FROM_LOWER) -- "gift from" boxes
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_GIFT_FROM2_LOWER)
       or self:MatchGuildSkillLineName(data.name) -- Matches "Merit" for guild skill tree lines
    then
        return true
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

excludedIds = {
  [56865] = 1, -- [Nirnhoned Coffer], awarded from Craglorn story quest, not repeatable
  [81601] = 1, -- [Nirnhoned Coffer], awarded from Craglorn story quest, not repeatable
}

knownIds = {
  [133560] = 1, -- [Slag Town Coffer] "Coffer" isn't used for this item in ruESO, unfortunately.
  [55452]=1,[71312]=1,[74679]=1,[74680]=1,[77526]=1,[77556]=1,
  [79669]=1,[79674]=1,[81561]=1,[94087]=1,[94088]=1,[94121]=1,
  [94122]=1,[95826]=1,[95827]=1,[96385]=1,[96386]=1,[96387]=1,
  [121220]=1,[126030]=1,[126031]=1,[126032]=1,[126033]=1,[133225]=1,
  [133559]=1,[138800]=1,[141741]=1,[147287]=1,[151620]=1,
  [151623]=1
}