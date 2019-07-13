local addon = Unboxer
local class = addon:Namespace("rules.hidden")
local knownIds
local debug = false

-- Excluded 3
class.Excluded3 = addon.classes.Rule:Subclass()
function class.Excluded3:New()
    return addon.classes.Rule.New(
        self, 
        {
            name = "excluded3",
            dependencies  = { "excluded2", "festival", "fishing", "materials", "outfitstyles", "runeboxes", "telvar", "transmutation", "trial", "vendorgear" },
            hidden = true,
            knownIds = knownIds,
        })
end

function class.Excluded3:Match(data)
    if data.quality == ITEM_QUALITY_LEGENDARY -- gold-quality
       or data.bindType == BIND_TYPE_ON_PICKUP_BACKPACK -- character-bound
       or data.bindType == BIND_TYPE_ON_EQUIP -- boe
       or string.find(data.name, "[0-9]") -- numbers in name
    then
        return true
    end
end

knownIds = {
  [54853]=1,[55832]=1,[55837]=1,[55838]=1,[55839]=1,[55840]=1,
  [55841]=1,[55842]=1,[55843]=1,[55844]=1,[59916]=1,[59917]=1,
  [63603]=1,[63604]=1,[63605]=1,[63606]=1,[63607]=1,[63608]=1,
  [63609]=1,[63610]=1,[63611]=1,[63612]=1,[63613]=1,[69517]=1,
  [69518]=1,[69519]=1,[69520]=1,[69521]=1,[69522]=1,[69523]=1,
  [69524]=1,[69525]=1,[71051]=1,[71052]=1,[71053]=1,[71540]=1,
  [81181]=1,[81182]=1,[81184]=1,[81185]=1,[81186]=1,[81988]=1,
  [81993]=1,[114109]=1,[114115]=1,[114118]=1,[114121]=1,[114124]=1,
  [114205]=1,[114275]=1,[114276]=1,[121251]=1,[121252]=1,[121253]=1,
  [121255]=1,[121256]=1,[121258]=1,[121259]=1,[121260]=1,[121261]=1,
  [121262]=1,[121263]=1,[121264]=1,[121380]=1,[121402]=1,[125296]=1,
  [127132]=1,[127135]=1,[127138]=1,[127141]=1,[133577]=1,[133592]=1,
  [134560]=1,[134561]=1,[134628]=1,[134630]=1,[134633]=1,[134636]=1,
  [134639]=1,[134642]=1,[134645]=1,[134649]=1,[134652]=1,[134655]=1,
  [134658]=1,[134661]=1,[134663]=1,[134668]=1,[134669]=1,[134670]=1,
  [134847]=1,[135007]=1,[135008]=1,[138710]=1,[139421]=1,[139445]=1,
  [140222]=1,[140227]=1,[140253]=1,[140254]=1,[140255]=1,[140256]=1,
  [140257]=1,[140258]=1,[140259]=1,[140260]=1,[140261]=1,[140262]=1,
  [140263]=1,[140264]=1,[140265]=1,[140266]=1,[141859]=1,[141860]=1,
  [141861]=1,[141862]=1,[141863]=1,[141864]=1,[141865]=1,[141866]=1,
  [141867]=1,[141868]=1,[141871]=1,[141872]=1,[141873]=1,[141874]=1,
  [142122]=1,[145507]=1,[145508]=1,[145509]=1,[145511]=1,[145517]=1,
  [145518]=1,[145519]=1,[145520]=1,[145521]=1,[145522]=1,[145523]=1,
  [145524]=1,[145525]=1,[145526]=1,[145527]=1,[145528]=1,[145529]=1,
  [145530]=1,[145917]=1,[145925]=1,[147488]=1,[147489]=1,[147490]=1,
  [147491]=1,[147500]=1,[147501]=1,[147502]=1,[147503]=1,[147504]=1,
  [147508]=1,[147509]=1,[147510]=1,[147511]=1,[147759]=1,[150684]=1,
  [150687]=1,[150694]=1,[151955]=1,[152236]=1,[153635]=1,[153608]=1,
  [153609]=1,[153610]=1,[153611]=1,[153612]=1,[153613]=1,[153614]=1,
  [153615]=1,
}