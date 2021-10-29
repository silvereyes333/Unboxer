local addon = Unboxer
local class = addon:Namespace("rules.hidden")
local knownIds
local debug = false

-- Hardcoded exclusions
class.Excluded = addon.classes.Rule:Subclass()
function class.Excluded:New()
    return addon.classes.Rule.New(
        self, 
        {
            name = "excluded",
            hidden = true,
            knownIds = knownIds,
        })
end

function class.Excluded:Match(data)
    if data.itemType == ITEMTYPE_COLLECTIBLE and (not data.collectibleId or data.collectibleId == 0)
       and not addon.classes.rules.collectibles.StylePages.Match(nil, data)
    then
        return true
    end
end

knownIds = {
  [42879]=1,[42880]=1,[42881]=1,[42882]=1,[42883]=1,[42884]=1,
  [42885]=1,[42886]=1,[42887]=1,[42888]=1,[42889]=1,[42890]=1,
  [42891]=1,[42892]=1,[42893]=1,[42894]=1,[42895]=1,[42896]=1,
  [42897]=1,[42898]=1,[42899]=1,[42900]=1,[42901]=1,[42902]=1,
  [42903]=1,[42904]=1,[42905]=1,[42906]=1,[42907]=1,[42908]=1,
  [42909]=1,[42910]=1,[42911]=1,[42912]=1,[42913]=1,[42914]=1,
  [42915]=1,[42916]=1,[42917]=1,[42918]=1,[42919]=1,[42920]=1,
  [42921]=1,[42922]=1,[42923]=1,[42924]=1,[42925]=1,[42926]=1,
  [42927]=1,[42928]=1,[42929]=1,[42930]=1,[42931]=1,[42932]=1,
  [42933]=1,[42934]=1,[42935]=1,[42936]=1,[42937]=1,[42938]=1,
  [42939]=1,[42940]=1,[42941]=1,[42942]=1,[42943]=1,[42944]=1,
  [42945]=1,[42946]=1,[42947]=1,[42948]=1,[42949]=1,[45368]=1,
  [45369]=1,[45370]=1,[45371]=1,[45372]=1,[45373]=1,[45374]=1,
  [45375]=1,[45378]=1,[45379]=1,[45380]=1,[45381]=1,[45382]=1,
  [45383]=1,[45384]=1,[45385]=1,[45386]=1,[45388]=1,[45389]=1,
  [45390]=1,[45391]=1,[45392]=1,[45393]=1,[45394]=1,[45395]=1,
  [45396]=1,[45397]=1,[45398]=1,[45399]=1,[45400]=1,[45401]=1,
  [45402]=1,[45403]=1,[45406]=1,[45407]=1,[45408]=1,[45409]=1,
  [45410]=1,[45411]=1,[45412]=1,[45413]=1,[45414]=1,[45416]=1,
  [45417]=1,[45418]=1,[45419]=1,[45420]=1,[45421]=1,[45422]=1,
  [45423]=1,[45424]=1,[45425]=1,[45426]=1,[45427]=1,[45428]=1,
  [45429]=1,[45430]=1,[45431]=1,[45432]=1,[45433]=1,[45434]=1,
  [45435]=1,[45436]=1,[45437]=1,[45438]=1,[45439]=1,[45440]=1,
  [45441]=1,[45444]=1,[45445]=1,[45446]=1,[45447]=1,[45448]=1,
  [45449]=1,[45450]=1,[45451]=1,[45454]=1,[45455]=1,[45456]=1,
  [45457]=1,[45458]=1,[45459]=1,[45460]=1,[45461]=1,[45462]=1,
  [45463]=1,[45464]=1,[45465]=1,[45466]=1,[45467]=1,[45468]=1,
  [45469]=1,[45470]=1,[45471]=1,[45472]=1,[45474]=1,[45475]=1,
  [45476]=1,[45477]=1,[45478]=1,[45480]=1,[45482]=1,[45483]=1,
  [45484]=1,[45485]=1,[45486]=1,[45487]=1,[45488]=1,[45489]=1,
  [45492]=1,[45493]=1,[45494]=1,[45495]=1,[45496]=1,[45497]=1,
  [45498]=1,[45499]=1,[45500]=1,[45501]=1,[45502]=1,[45503]=1,
  [45504]=1,[45505]=1,[45506]=1,[45507]=1,[45508]=1,[45509]=1,
  [45510]=1,[45511]=1,[45512]=1,[45513]=1,[45514]=1,[45515]=1,
  [45516]=1,[45517]=1,[54184]=1,[54185]=1,[54186]=1,[54187]=1,
  [54188]=1,[54189]=1,[54190]=1,[54195]=1,[54196]=1,[54197]=1,
  [54198]=1,[54199]=1,[54200]=1,[54201]=1,[54202]=1,[54203]=1,
  [54204]=1,[54205]=1,[54206]=1,[54207]=1,[54208]=1,[54209]=1,
  [54210]=1,[54211]=1,[54212]=1,[54213]=1,[54214]=1,[54215]=1,
  [54216]=1,[54217]=1,[54218]=1,[54219]=1,[54220]=1,[54221]=1,
  [54222]=1,[54223]=1,[54224]=1,[54225]=1,[54226]=1,[54227]=1,
  [54228]=1,[54229]=1,[54230]=1,[54231]=1,[54232]=1,[54233]=1,
  [54234]=1,[54235]=1,[54236]=1,[54237]=1,[54338]=1,[54368]=1,
  [55264]=1,[55265]=1,[55266]=1,[55267]=1,[55268]=1,[55269]=1,
  [55270]=1,[55271]=1,[55272]=1,[55273]=1,[55274]=1,[55275]=1,
  [68144]=1,[68145]=1,[68146]=1,[68147]=1,[68148]=1,[68149]=1,
  [68150]=1,[68151]=1,[68152]=1,[68153]=1,[68154]=1,[68155]=1,
  [68156]=1,[68157]=1,[68158]=1,[68159]=1,[68160]=1,[68161]=1,
  [68162]=1,[68163]=1,[68164]=1,[68165]=1,[68166]=1,[68167]=1,
  [71099]=1,[71767]=1,[71768]=1,[71769]=1,[71770]=1,[71771]=1,
  [71772]=1,[71773]=1,[71774]=1,[71775]=1,[71776]=1,[71777]=1,
  [71778]=1,[79678]=1,[79679]=1,[79680]=1,[79681]=1,[79682]=1,
  [79683]=1,[79684]=1,[79685]=1,[79686]=1,[79687]=1,[79688]=1,
  [79689]=1,[100393]=1,[100394]=1,[100395]=1,[126081]=1,[126082]=1,
  [126083]=1,[126084]=1,[126085]=1,[126086]=1,[126087]=1,[126088]=1,
  [126089]=1,[126090]=1,[126091]=1,[126092]=1,[133564]=1,[133565]=1,
  [133566]=1,[133567]=1,[133568]=1,[133569]=1,[133570]=1,[133571]=1,
  [133572]=1,[133573]=1,[133574]=1,[133575]=1,[138828]=1,[138829]=1,
  [138830]=1,[138831]=1,[138832]=1,[138833]=1,[138834]=1,[138835]=1,
  [138836]=1,[138837]=1,[138838]=1,[138839]=1,[139013]=1,[139014]=1,
  [139015]=1,[145582]=1,[145583]=1,[145584]=1,[145585]=1,[145586]=1,
  [145587]=1,[145588]=1,[145589]=1,[145590]=1,[145591]=1,[145592]=1,
  [145593]=1,[147936]=1,[147937]=1,[147938]=1,[147939]=1,[147940]=1,
  [147941]=1,[147942]=1,[147943]=1,[147944]=1,[147945]=1,[147946]=1,
  [147947]=1,[153755]=1,[153756]=1,[153815]=1,[153816]=1,[153817]=1,
  [153818]=1,[153819]=1,[153820]=1,[153821]=1,[153822]=1,[153823]=1,
  [153824]=1,[153825]=1,[153826]=1,[161192]=1,[161193]=1,[161194]=1,
  [161195]=1,[161196]=1,[161197]=1,[161198]=1,[161199]=1,[161200]=1,
  [161201]=1,[161202]=1,[161203]=1,[171264]=1,[171265]=1,[171269]=1,
  [171270]=1,[171314]=1,[171315]=1,[171316]=1,[171317]=1,[171318]=1,
  [171319]=1,[171320]=1,[171321]=1,[173575]=1,[173576]=1,[173578]=1,
  [173579]=1,[173580]=1,[173582]=1,[173583]=1,[173584]=1,[173586]=1,
  [173587]=1,[173588]=1,[173590]=1,[181439]=1,[181440]=1,[181441]=1,
  [181442]=1,[181443]=1,[181444]=1,[181445]=1,[181446]=1,[181447]=1,
  [181448]=1,[181449]=1,[181450]=1,
}