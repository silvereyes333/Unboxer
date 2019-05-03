
-- Repeatable activites (e.g. dailies, Rewards for the Worthy, etc.)

local addon = Unboxer
local class = addon.classes
local debug = false
local staticDlcs
local knownIds
local submenu = GetString(SI_UNBOXER_QUEST_REWARDS)

class.Repeatable = class.Rule:Subclass()
function class.Repeatable:New()
    local instance = class.Rule.New(
        self, 
        {
            name          = "solorepeatable",
            exampleItemId = 134619, -- Rewards for the Worthy
            dependencies  = { "crafting", "festival", "furnisher", "materials", "legerdemain", "trial", "vendorgear" },
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_REPEATABLE),
            -- knownIds      = knownIds
        })
    instance.pts = class.Pts:New()
    return instance
end

function class.Repeatable:Match(data)
  
    if knownIds[data.itemId] then
        return self:IsUnboxableMatch()
    end
  
    if string.find(data.name, ":") 
       or data.quality == ITEM_QUALITY_LEGENDARY
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
    
    -- Matches daily reward containers
    if data.bindType == BIND_TYPE_ON_PICKUP
       and (self:MatchDailyQuestText(data.name)
            or self:MatchDailyQuestText(data.flavorText))
    then
        return self:IsUnboxableMatch()
    end
    
    
    if addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_COFFER_LOWER) -- "coffer"
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_GIFT_FROM_LOWER) -- "gift from" boxes
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_GIFT_FROM2_LOWER)
    then
        return self:IsUnboxableMatch()
    end
    
    
    
    --[[ EVERYTHING BELOW HERE SHOULD EXCLUDE SPECIFICALLY-MATCHED PTS GEAR ]]--
    if self.pts:MatchExceptIcon(data) then return end
    
    
    
    
    if self:MatchGuildSkillLineName(data.name) -- Matches "Merit" for guild skill tree lines
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_CYRODIIL_LOWER) -- cyrodiil in name
    then
        return self:IsUnboxableMatch()
    end
end



local defaultGuildSkillLineNames = {
    "mages guild",
    "fighters guild",
    "thieves guild",
    "dark brotherhood",
    "undaunted",
    "psijic order",
}
function class.Repeatable:MatchGuildSkillLineName(text)
  
    local skillType = SKILL_TYPE_GUILD
    for skillLineIndex=1, GetNumSkillLines(skillType) do
        local skillLineName = LocaleAwareToLower(GetSkillLineName(skillType, skillLineIndex))
        if string.find(text, skillLineName) then
            return true
        end
    end
    if addon:IsDefaultLanguageSelected() then
        return
    end
    -- Fallback to default language when running on an incomplete translation, like ruESO
    for _, skillLineName in ipairs(defaultGuildSkillLineNames) do
        if string.find(text, skillLineName) then
            return true
        end
    end
end
function class.Repeatable:MatchDailyQuestText(text)
    return addon:StringContainsStringIdOrDefault(text, SI_UNBOXER_REWARD_LOWER)
           or addon:StringContainsStringIdOrDefault(text, SI_UNBOXER_DAILY_LOWER)
           or addon:StringContainsStringIdOrDefault(text, SI_UNBOXER_DAILY2_LOWER)
           or addon:StringContainsStringIdOrDefault(text, SI_UNBOXER_JOB_LOWER)
           or addon:StringContainsStringIdOrDefault(dext, SI_UNBOXER_CONTRACT_LOWER)
    
end

knownIds = {
  [151936] = true, -- Wax-Sealed Heavy Sack, dropped from Elsweyr dragon attacks?
}

  