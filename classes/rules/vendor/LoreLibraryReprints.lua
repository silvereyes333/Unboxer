
-- Lore Book Reprints

local addon = Unboxer
local class = addon:Namespace("rules.vendor")
local rules = addon.classes.rules
local debug = false
local submenu = GetString(SI_GAMEPAD_VENDOR_CATEGORY_HEADER)

class.LoreLibraryReprints  = addon.classes.Rule:Subclass()
function class.LoreLibraryReprints:New()
    local instance = addon.classes.Rule.New(
        self, 
        {
            name          = "reprints",
            exampleItemId = 120384, -- [Guild Reprint: Daedric Princes]
            submenu       = submenu,
            title         = GetString(SI_UNBOXER_REPRINTS),
        })
    instance.pts = rules.Pts:New()
    return instance
end

function class.LoreLibraryReprints:Match(data)
  
    -- Mages Guild reprints
    if string.find(data.icon, 'housing.*book') then
        return self:IsUnboxableMatch()
    end
    
    -- Match any non-PTS containers that have an icon with "book" in the name
    if string.find(data.icon, 'book') and not self.pts:MatchExceptColonAndIcon(data) then
        return self:IsUnboxableMatch()
    end
end