
-- Lore Book Reprints

local addon = Unboxer
local class = addon.classes
local debug = false
local submenu = GetString(SI_GAMEPAD_VENDOR_CATEGORY_HEADER)

class.LorebookReprints  = class.Rule:Subclass()
function class.LorebookReprints:New()
    local instance = class.Rule.New(self, 
      "reprints",
      120384 -- [Guild Reprint: Daedric Princes]
    )
    instance.pts = addon.classes.Pts:New()
    return instance
end

function class.LorebookReprints:Match(data)
  
    -- Mages Guild reprints
    if string.find(data.icon, 'housing.*book') then
        return self:IsUnboxableMatch()
    end
    
    -- Match any non-PTS containers that have an icon with "book" in the name
    if string.find(data.icon, 'book') and not self.pts:MatchExceptColonAndIcon(data) then
        return self:IsUnboxableMatch()
    end
end