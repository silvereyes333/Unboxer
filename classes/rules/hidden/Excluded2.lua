local addon = Unboxer
local class = addon:Namespace("rules.hidden")
local knownIds
local debug = false

-- Excluded
-- Most of these will be PTS containers that can be absolutely identified without reference to other rules.
-- Some, however, are special classes of container, such as the Shadowy Supplier drop "Unmarked Sack", which
-- can cause infinite loops if a Monk's Disguise is already in your inventory.
class.Excluded2 = addon.classes.Rule:Subclass()
function class.Excluded2:New()
    return addon.classes.Rule.New(
        self, 
        {
            name = "excluded2",
            dependencies = { "runeboxes", "festival", "outfitstyles", "dragons", "reprints" },
            hidden = true,
            knownIds = knownIds,
        })
end

function class.Excluded2:Match(data)
    if GetItemLinkOnUseAbilityInfo(data.itemLink) -- only PTS boxes grant abilities
       or addon:StringContainsPunctuationColon(data.name) -- Name contains a colon (:)
       or self:MatchItemSetsText(data.name)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_ALL_LOWER) -- Contains the word " all " surrounded by spaces (if supported by locale)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_ALL2_LOWER) 
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_FOUND_LOWER) -- Contains the phrase " found in " surrounded by spaces (if supported by locale)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_FOUND2_LOWER)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_FULL_SUITE_LOWER) -- Contains the phrase "full set" or "full suite"
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_FULL_SUITE2_LOWER)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_FULL_SUITE3_LOWER)
       or addon:StringContainsStringIdOrDefault(data.flavorText, SI_UNBOXER_TO_BE_INTRODUCED) -- Contains the phrase "to be introduced"
       or string.find(data.flavorText, " pts ")
       or string.find(data.flavorText, "^pts ")
       or string.find(data.name, "^qa ")
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_INFINITE_LOWER)
       or addon:StringContainsStringIdOrDefault(data.name, SI_UNBOXER_TESTER_LOWER)
    then
        return true
    end
end

function class.Excluded2:MatchItemSetsText(text)
  
    -- Need to exclude matches for Summerset (which, translated, also matches translated 'sets')
    local summerset = LocaleAwareToLower(GetZoneNameById(1011))
    if string.find(text, summerset) then return end
    
    local startIndex, endIndex = addon:StringContainsStringIdOrDefault(text, SI_UNBOXER_ITEM_SETS_LOWER)
    if startIndex == 1 or endIndex == ZoUTF8StringLength(text) then
        return true
    end
end

knownIds = {
  [55833]=1,[55834]=1,[55835]=1,[55836]=1,[59918]=1,[59919]=1,
  [59920]=1,[71025]=1,[71026]=1,[71027]=1,[71028]=1,[71029]=1,
  [71030]=1,[71031]=1,[71032]=1,[71033]=1,[71034]=1,[71035]=1,
  [71036]=1,[71037]=1,[71038]=1,[71039]=1,[71040]=1,[71041]=1,
  [71042]=1,[71043]=1,[71044]=1,[71045]=1,[71046]=1,[71047]=1,
  [71048]=1,[71049]=1,[71050]=1,[71482]=1,[71483]=1,[71484]=1,
  [71485]=1,[71486]=1,[71487]=1,[71488]=1,[71489]=1,[71490]=1,
  [71491]=1,[71492]=1,[71493]=1,[71494]=1,[71495]=1,[71496]=1,
  [71497]=1,[71498]=1,[71499]=1,[71500]=1,[71501]=1,[71502]=1,
  [71503]=1,[71504]=1,[71505]=1,[71506]=1,[71507]=1,[74684]=1,
  [74685]=1,[74687]=1,[74688]=1,[74689]=1,[74690]=1,[74691]=1,
  [74692]=1,[74693]=1,[74694]=1,[74695]=1,[74696]=1,[74697]=1,
  [74698]=1,[74699]=1,[74700]=1,[74701]=1,[74702]=1,[74703]=1,
  [74704]=1,[74705]=1,[74706]=1,[74707]=1,[74708]=1,[75225]=1,
  [81183]=1,[94218]=1,[94219]=1,[94220]=1,[94221]=1,[94222]=1,
  [94223]=1,[94224]=1,[94225]=1,[94226]=1,[94227]=1,[94228]=1,
  [94229]=1,[94230]=1,[94231]=1,[94233]=1,[94234]=1,[94235]=1,
  [94236]=1,[94237]=1,[94238]=1,[94239]=1,[94240]=1,[94241]=1,
  [94242]=1,[114127]=1,[114128]=1,[114129]=1,[114130]=1,[114131]=1,
  [114132]=1,[114133]=1,[114134]=1,[114135]=1,[114136]=1,[114137]=1,
  [114138]=1,[114139]=1,[114140]=1,[114141]=1,[114142]=1,[114143]=1,
  [114144]=1,[114145]=1,[114147]=1,[114148]=1,[114149]=1,[114150]=1,
  [114151]=1,[114152]=1,[114153]=1,[114154]=1,[114155]=1,[114156]=1,
  [114157]=1,[114158]=1,[114159]=1,[114160]=1,[114161]=1,[114162]=1,
  [114163]=1,[114164]=1,[114165]=1,[114166]=1,[114167]=1,[114168]=1,
  [114169]=1,[114170]=1,[114171]=1,[114172]=1,[114173]=1,[114174]=1,
  [114175]=1,[114176]=1,[114177]=1,[114178]=1,[114179]=1,[114180]=1,
  [114181]=1,[114182]=1,[114183]=1,[114184]=1,[114185]=1,[114186]=1,
  [114187]=1,[114188]=1,[114189]=1,[114190]=1,[114191]=1,[114192]=1,
  [114193]=1,[114194]=1,[114195]=1,[114196]=1,[114197]=1,[114198]=1,
  [114199]=1,[114200]=1,[114201]=1,[114202]=1,[114203]=1,[114204]=1,
  [114208]=1,[114209]=1,[114210]=1,[114211]=1,[114212]=1,[114213]=1,
  [114214]=1,[114215]=1,[114216]=1,[114217]=1,[114218]=1,[114219]=1,
  [114220]=1,[114221]=1,[114222]=1,[114223]=1,[114224]=1,[114225]=1,
  [114226]=1,[114227]=1,[114228]=1,[114229]=1,[114230]=1,[114231]=1,
  [114232]=1,[114233]=1,[114234]=1,[114235]=1,[114236]=1,[114237]=1,
  [114238]=1,[114239]=1,[114240]=1,[114241]=1,[114242]=1,[114243]=1,
  [114244]=1,[114245]=1,[114246]=1,[114247]=1,[114248]=1,[114249]=1,
  [114250]=1,[114251]=1,[114252]=1,[114253]=1,[114254]=1,[114255]=1,
  [114256]=1,[114257]=1,[114258]=1,[114259]=1,[114260]=1,[114261]=1,
  [114262]=1,[114263]=1,[114264]=1,[114265]=1,[114266]=1,[114267]=1,
  [114268]=1,[114269]=1,[114270]=1,[114271]=1,[114272]=1,[114273]=1,
  [114274]=1,[114277]=1,[114278]=1,[114279]=1,[114280]=1,[114896]=1,
  [114897]=1,[114898]=1,[114899]=1,[114900]=1,[114901]=1,[114902]=1,
  [114903]=1,[114904]=1,[114905]=1,[114906]=1,[114907]=1,[114908]=1,
  [114909]=1,[114910]=1,[114911]=1,[114912]=1,[114913]=1,[114914]=1,
  [114915]=1,[114916]=1,[114917]=1,[114918]=1,[114919]=1,[114920]=1,
  [114921]=1,[119566]=1,[121257]=1,[127110]=1,[127111]=1,[127112]=1,
  [127113]=1,[127114]=1,[127115]=1,[127116]=1,[127117]=1,[127118]=1,
  [127119]=1,[127120]=1,[127121]=1,[127122]=1,[127123]=1,[127124]=1,
  [127125]=1,[127126]=1,[127127]=1,[127128]=1,[127129]=1,[127130]=1,
  [127131]=1,[127133]=1,[127134]=1,[127136]=1,[127137]=1,[127139]=1,
  [127140]=1,[127142]=1,[127143]=1,[127144]=1,[127145]=1,[127146]=1,
  [132325]=1,[132326]=1,[132327]=1,[132328]=1,[132329]=1,[132330]=1,
  [132331]=1,[132332]=1,[132333]=1,[132334]=1,[132335]=1,[132336]=1,
  [132337]=1,[132338]=1,[133578]=1,[133579]=1,[133581]=1,[133582]=1,
  [133583]=1,[133584]=1,[133586]=1,[133587]=1,[133588]=1,[133589]=1,
  [133590]=1,[133591]=1,[133933]=1,[133934]=1,[133935]=1,[133936]=1,
  [133937]=1,[133938]=1,[133939]=1,[133940]=1,[133941]=1,[133942]=1,
  [133943]=1,[133944]=1,[133945]=1,[133947]=1,[133948]=1,[133949]=1,
  [133950]=1,[133951]=1,[133952]=1,[133953]=1,[133954]=1,[133955]=1,
  [133956]=1,[133957]=1,[133958]=1,[133959]=1,[133960]=1,[133961]=1,
  [133962]=1,[133963]=1,[133964]=1,[133965]=1,[133966]=1,[133967]=1,
  [133968]=1,[133969]=1,[133970]=1,[133971]=1,[133972]=1,[133973]=1,
  [133974]=1,[133975]=1,[133976]=1,[133977]=1,[133978]=1,[133979]=1,
  [133980]=1,[133981]=1,[133982]=1,[133984]=1,[133985]=1,[133986]=1,
  [133987]=1,[133988]=1,[133989]=1,[133990]=1,[133991]=1,[133992]=1,
  [133993]=1,[133994]=1,[133995]=1,[133996]=1,[133997]=1,[133998]=1,
  [133999]=1,[134000]=1,[134001]=1,[134002]=1,[134003]=1,[134004]=1,
  [134005]=1,[134006]=1,[134007]=1,[134008]=1,[134009]=1,[134010]=1,
  [134011]=1,[134012]=1,[134013]=1,[134014]=1,[134015]=1,[134016]=1,
  [134017]=1,[134018]=1,[134019]=1,[134020]=1,[134021]=1,[134022]=1,
  [134023]=1,[134024]=1,[134025]=1,[134026]=1,[134027]=1,[134028]=1,
  [134029]=1,[134030]=1,[134031]=1,[134032]=1,[134033]=1,[134034]=1,
  [134035]=1,[134036]=1,[134037]=1,[134038]=1,[134039]=1,[134040]=1,
  [134041]=1,[134042]=1,[134043]=1,[134044]=1,[134045]=1,[134046]=1,
  [134047]=1,[134048]=1,[134049]=1,[134050]=1,[134051]=1,[134052]=1,
  [134053]=1,[134054]=1,[134055]=1,[134056]=1,[134057]=1,[134058]=1,
  [134059]=1,[134060]=1,[134061]=1,[134062]=1,[134063]=1,[134064]=1,
  [134065]=1,[134066]=1,[134067]=1,[134068]=1,[134069]=1,[134070]=1,
  [134072]=1,[134073]=1,[134074]=1,[134075]=1,[134076]=1,[134077]=1,
  [134078]=1,[134079]=1,[134080]=1,[134081]=1,[134082]=1,[134083]=1,
  [134084]=1,[134085]=1,[134086]=1,[134087]=1,[134088]=1,[134089]=1,
  [134090]=1,[134091]=1,[134092]=1,[134093]=1,[134094]=1,[134095]=1,
  [134096]=1,[134097]=1,[134098]=1,[134099]=1,[134100]=1,[134101]=1,
  [134102]=1,[134103]=1,[134104]=1,[134105]=1,[134106]=1,[134107]=1,
  [134108]=1,[134109]=1,[134110]=1,[134111]=1,[134112]=1,[134113]=1,
  [134114]=1,[134115]=1,[134116]=1,[134117]=1,[134118]=1,[134119]=1,
  [134120]=1,[134121]=1,[134122]=1,[134123]=1,[134124]=1,[134125]=1,
  [134126]=1,[134127]=1,[134128]=1,[134129]=1,[134130]=1,[134131]=1,
  [134132]=1,[134133]=1,[134134]=1,[134135]=1,[134136]=1,[134137]=1,
  [134138]=1,[134139]=1,[134140]=1,[134141]=1,[134142]=1,[134143]=1,
  [134144]=1,[134145]=1,[134146]=1,[134147]=1,[134148]=1,[134149]=1,
  [134150]=1,[134151]=1,[134152]=1,[134153]=1,[134154]=1,[134155]=1,
  [134156]=1,[134157]=1,[134158]=1,[134159]=1,[134160]=1,[134161]=1,
  [134162]=1,[134163]=1,[134164]=1,[134165]=1,[134166]=1,[134167]=1,
  [134168]=1,[134169]=1,[134170]=1,[134171]=1,[134172]=1,[134173]=1,
  [134174]=1,[134175]=1,[134176]=1,[134177]=1,[134178]=1,[134179]=1,
  [134180]=1,[134181]=1,[134182]=1,[134183]=1,[134184]=1,[134185]=1,
  [134186]=1,[134187]=1,[134188]=1,[134189]=1,[134190]=1,[134191]=1,
  [134192]=1,[134193]=1,[134194]=1,[134195]=1,[134196]=1,[134197]=1,
  [134198]=1,[134199]=1,[134200]=1,[134201]=1,[134202]=1,[134203]=1,
  [134204]=1,[134205]=1,[134206]=1,[134207]=1,[134208]=1,[134209]=1,
  [134210]=1,[134211]=1,[134212]=1,[134213]=1,[134214]=1,[134215]=1,
  [134216]=1,[134217]=1,[134218]=1,[134219]=1,[134220]=1,[134221]=1,
  [134222]=1,[134223]=1,[134224]=1,[134225]=1,[134226]=1,[134227]=1,
  [134228]=1,[134229]=1,[134230]=1,[134231]=1,[134232]=1,[134233]=1,
  [134234]=1,[134235]=1,[134236]=1,[134237]=1,[134238]=1,[134239]=1,
  [134240]=1,[134241]=1,[134242]=1,[134560]=1,[134561]=1,[134595]=1,
  [134596]=1,[134597]=1,[134598]=1,[134599]=1,[134600]=1,[134601]=1,
  [134602]=1,[134603]=1,[134604]=1,[134605]=1,[134606]=1,[134607]=1,
  [134608]=1,[134609]=1,[134610]=1,[134611]=1,[134612]=1,[134613]=1,
  [134614]=1,[134615]=1,[134616]=1,[134625]=1,[134626]=1,[134627]=1,
  [134629]=1,[134631]=1,[134632]=1,[134634]=1,[134635]=1,[134637]=1,
  [134638]=1,[134640]=1,[134641]=1,[134643]=1,[134644]=1,[134646]=1,
  [134647]=1,[134650]=1,[134651]=1,[134653]=1,[134654]=1,[134656]=1,
  [134657]=1,[134659]=1,[134660]=1,[134662]=1,[134664]=1,[134671]=1,
  [134802]=1,[134803]=1,[134804]=1,[134805]=1,[134806]=1,[134807]=1,
  [134808]=1,[134809]=1,[134810]=1,[134811]=1,[134812]=1,[134813]=1,
  [134814]=1,[134815]=1,[134816]=1,[134817]=1,[134818]=1,[134819]=1,
  [134820]=1,[134821]=1,[134822]=1,[134850]=1,[134851]=1,[134852]=1,
  [138749]=1,[138750]=1,[138751]=1,[138752]=1,[138753]=1,[138754]=1,
  [138755]=1,[138756]=1,[138757]=1,[138758]=1,[138759]=1,[138760]=1,
  [138761]=1,[138762]=1,[138763]=1,[138764]=1,[138765]=1,[138766]=1,
  [138767]=1,[138768]=1,[138769]=1,[138770]=1,[138771]=1,[138772]=1,
  [138773]=1,[138774]=1,[138775]=1,[138776]=1,[138777]=1,[138778]=1,
  [138779]=1,[139021]=1,[139022]=1,[139023]=1,[139024]=1,[139025]=1,
  [139026]=1,[139027]=1,[139028]=1,[139029]=1,[139030]=1,[139031]=1,
  [139032]=1,[139033]=1,[139034]=1,[139035]=1,[139037]=1,[139038]=1,
  [139039]=1,[139040]=1,[139041]=1,[139042]=1,[139043]=1,[139044]=1,
  [139045]=1,[139046]=1,[139047]=1,[139048]=1,[139049]=1,[139050]=1,
  [139051]=1,[139052]=1,[139053]=1,[139054]=1,[141876]=1,[141877]=1,
  [141878]=1,[141879]=1,[141880]=1,[141881]=1,[141882]=1,[141883]=1,
  [141884]=1,[141885]=1,[141886]=1,[141887]=1,[141888]=1,[141889]=1,
  [141890]=1,[141891]=1,[141892]=1,[141893]=1,[141894]=1,[141895]=1,
  [141956]=1,[145916]=1,[145918]=1,[145919]=1,[145920]=1,[145921]=1,
  [145922]=1,[145924]=1,[145929]=1,[145930]=1,[145931]=1,[145932]=1,
  [145933]=1,[145934]=1,[145935]=1,[145936]=1,[145937]=1,[145938]=1,
  [145939]=1,[145940]=1,[145941]=1,[145942]=1,[145943]=1,[146019]=1,
  [146020]=1,[146021]=1,[146022]=1,[146023]=1,[146024]=1,[146025]=1,
  [146026]=1,[146027]=1,[146028]=1,[146029]=1,[146030]=1,[146031]=1,
  [146032]=1,[146033]=1,[146034]=1,[146035]=1,[146036]=1,[146066]=1,
  [147435]=1,[147604]=1,[147605]=1,[147606]=1,[147617]=1,[147618]=1,
  [147619]=1,[147620]=1,[147621]=1,[147622]=1,[147623]=1,[147624]=1,
  [147625]=1,[147626]=1,[147627]=1,[147628]=1,[147629]=1,[147630]=1,
  [147632]=1,[147633]=1,[147634]=1,[150420]=1,[150421]=1,[150422]=1,
  [150423]=1,[150424]=1,[150425]=1,[150426]=1,[150427]=1,[150428]=1,
  [150429]=1,[150430]=1,[150431]=1,[150432]=1,[150433]=1,[150434]=1,
  [150435]=1,[150436]=1,[150437]=1,[150438]=1,[150439]=1,[150440]=1,
  [150618]=1,[150619]=1,[150620]=1,[150621]=1,[150622]=1,[150623]=1,
  [150624]=1,[150625]=1,[150626]=1,[150627]=1,[150628]=1,[150629]=1,
  [150630]=1,[150631]=1,[150632]=1,[150633]=1,[150634]=1,[150635]=1,
  [150636]=1,[150637]=1,[150638]=1,[150639]=1,[150640]=1,[150641]=1,
  [150642]=1,[150643]=1,[150644]=1,[150645]=1,[150646]=1,[150647]=1,
  [150648]=1,[150649]=1,[150650]=1,[150651]=1,[150652]=1,[150653]=1,
  [150654]=1,[150655]=1,[150656]=1,[150657]=1,[150658]=1,[150659]=1,
  [150660]=1,[150661]=1,[150662]=1,[150663]=1,[150664]=1,[150665]=1,
  [150666]=1,[150674]=1,[150675]=1,[150676]=1,[150677]=1,[150678]=1,
  [150679]=1,[150680]=1,[150681]=1,[150682]=1,[150683]=1,[150685]=1,
  [150686]=1,[150688]=1,[150689]=1,[150690]=1,[150691]=1,[150692]=1,
  [150693]=1,[150695]=1,[150697]=1,[150698]=1,[150699]=1,[150701]=1,
  [150702]=1,[150703]=1,[150704]=1,[150705]=1,[150706]=1,[150707]=1,
  [150708]=1,[150709]=1,[150710]=1,[150711]=1,[150712]=1,[150713]=1,
  [150714]=1,[150715]=1,[150716]=1,[150717]=1,[150718]=1,[150719]=1,
  [150720]=1,[151956]=1,[151957]=1,[151958]=1,[151959]=1,[151960]=1,
  [151961]=1,[151962]=1,[151963]=1,[151964]=1,[151965]=1,[151966]=1,
  [151967]=1,[153752]=1,[153753]=1,[153754]=1,[153757]=1,[153758]=1,
  [153759]=1,[153760]=1,[153761]=1,[153762]=1,[153763]=1,[153764]=1,
  [153765]=1,[153766]=1,[153767]=1,[153768]=1,[153769]=1,[153770]=1,
  [153771]=1,[153772]=1,[153773]=1,[153774]=1,[153792]=1,[155018]=1,
  [155019]=1,[155020]=1,[155212]=1,[155213]=1,[155214]=1,[155397]=1,
  [155398]=1,[155399]=1,[156524]=1,[156525]=1,[156526]=1,[156527]=1,
  [156528]=1,[156529]=1,[156530]=1,[156531]=1,[156532]=1,[157040]=1,
  [157041]=1,[157042]=1,[157225]=1,[157226]=1,[157227]=1,[157410]=1,
  [157411]=1,[157412]=1,[157726]=1,[157727]=1,[157728]=1,[157911]=1,
  [157912]=1,[157913]=1,[158096]=1,[158097]=1,[158098]=1,[158211]=1,
  [158214]=1,[158215]=1,[158216]=1,[158217]=1,[158218]=1,[158219]=1,
  [158258]=1,[158273]=1,[158274]=1,[158275]=1,[158276]=1,[158277]=1,
  [158278]=1,[158280]=1,[159515]=1,[159516]=1,[159521]=1,[159522]=1,
  [159524]=1,[159525]=1,[159627]=1,[159927]=1,[159928]=1,[160112]=1,
  [160113]=1,[160297]=1,[160298]=1,[160491]=1,[160492]=1,[160818]=1,
  [160819]=1,[160820]=1,[161003]=1,[161004]=1,[161005]=1,[161188]=1,
  [161189]=1,[161190]=1,[162097]=1,[162098]=1,[162099]=1,[162226]=1,
  [162227]=1,[162228]=1,[162371]=1,[162372]=1,[162373]=1,[162505]=1,
  [162506]=1,[162507]=1,[162640]=1,[162641]=1,[162642]=1,[162769]=1,
  [162770]=1,[162771]=1,[162914]=1,[162915]=1,[162916]=1,[163048]=1,
  [163050]=1,[163435]=1,[163436]=1,[163437]=1,[163438]=1,[163439]=1,
  [163440]=1,[163441]=1,[163442]=1,[163443]=1,[164484]=1,[164485]=1,
  [164486]=1,[164669]=1,[164670]=1,[164671]=1,[164854]=1,[164855]=1,
  [164856]=1,[165049]=1,[165050]=1,[165234]=1,[165235]=1,[165419]=1,
  [165420]=1,[165881]=1,[166455]=1,[166457]=1,[166458]=1,[166470]=1,
  [166708]=1,[166709]=1,[166710]=1,[166711]=1,[166712]=1,[166714]=1,
  [166715]=1,[166716]=1,[166718]=1,[166719]=1,[166720]=1,[166721]=1,
  [166723]=1,[166724]=1,[166725]=1,[166726]=1,[166964]=1,[166969]=1,
  [166970]=1,[167071]=1,[167086]=1,[167087]=1,[167088]=1,[167089]=1,
  [167090]=1,[167091]=1,[167092]=1,[167147]=1,[167162]=1,[167163]=1,
  [167164]=1,[167165]=1,[167166]=1,[167167]=1,[167168]=1,[167307]=1,
  [167308]=1,[167309]=1,[167385]=1,[167388]=1,[167592]=1,[167593]=1,
  [167594]=1,[167765]=1,[167766]=1,[167767]=1,[167930]=1,[167931]=1,
  [167932]=1,[167936]=1,[169288]=1,[169289]=1,[169290]=1,[169453]=1,
  [169454]=1,[169455]=1,[169618]=1,[169619]=1,[169620]=1,[170401]=1,
  [170402]=1,[170403]=1,[170566]=1,[170567]=1,[170568]=1,[170731]=1,
  [170732]=1,[170733]=1,[170904]=1,[170905]=1,[170906]=1,[171069]=1,
  [171070]=1,[171071]=1,[171234]=1,[171235]=1,[171236]=1,[171438]=1,
  [171449]=1,[171451]=1,[171452]=1,[171453]=1,[171454]=1,[171455]=1,
  [171456]=1,[171457]=1,[171458]=1,[171459]=1,[171460]=1,[171461]=1,
  [171462]=1,[171536]=1,[171540]=1,[171638]=1,[171651]=1,[171652]=1,
  [171653]=1,[171654]=1,[171655]=1,[171656]=1,[171657]=1,[171694]=1,
  [171707]=1,[171708]=1,[171709]=1,[171710]=1,[171711]=1,[171712]=1,
  [171713]=1,[171837]=1,[171838]=1,[171939]=1,[172118]=1,[172119]=1,
  [172120]=1,[172283]=1,[172284]=1,[172285]=1,[172448]=1,[172449]=1,
  [172450]=1,[173725]=1,[173726]=1,[173727]=1,[173854]=1,[173855]=1,
  [173856]=1,[173999]=1,[174000]=1,[174001]=1,[174127]=1,[174128]=1,
  [174129]=1,[174836]=1,[174837]=1,[174838]=1,[175075]=1,[175076]=1,
  [175077]=1,[175078]=1,[175079]=1,[175080]=1,[175081]=1,[175082]=1,
  [175083]=1,[175084]=1,[175085]=1,[175086]=1,[175087]=1,[175088]=1,
  [175089]=1,[175090]=1,[175091]=1,[175092]=1,[175093]=1,[175094]=1,
  [175095]=1,[175096]=1,[175097]=1,[175098]=1,[175099]=1,[175100]=1,
  [175101]=1,[175102]=1,[175103]=1,[175104]=1,[175105]=1,[175106]=1,
  [175107]=1,[175108]=1,[175109]=1,[175110]=1,[175111]=1,[175112]=1,
  [175113]=1,[175114]=1,[175115]=1,[175116]=1,[175117]=1,[175118]=1,
  [175119]=1,[175120]=1,[175121]=1,[175122]=1,[175123]=1,[175124]=1,
  [175125]=1,[175126]=1,[175127]=1,[175128]=1,[175129]=1,[175130]=1,
  [175131]=1,[175132]=1,[175133]=1,[175134]=1,[175136]=1,[175137]=1,
  [175138]=1,[175139]=1,[175140]=1,[175141]=1,[175142]=1,[175143]=1,
  [175144]=1,[175145]=1,[175146]=1,[175147]=1,[175148]=1,[175149]=1,
  [175150]=1,[175151]=1,[175152]=1,[175153]=1,[175154]=1,[175155]=1,
  [175156]=1,[175157]=1,[175158]=1,[175159]=1,[175160]=1,[175161]=1,
  [175162]=1,[175163]=1,[175164]=1,[175165]=1,[175166]=1,[175167]=1,
  [175168]=1,[175169]=1,[175170]=1,[175171]=1,[175172]=1,[175173]=1,
  [175174]=1,[175175]=1,[175176]=1,[175177]=1,[175178]=1,[175179]=1,
  [175180]=1,[175181]=1,[175182]=1,[175183]=1,[175184]=1,[175185]=1,
  [175186]=1,[175187]=1,[175188]=1,[175189]=1,[175190]=1,[175191]=1,
  [175192]=1,[175193]=1,[175194]=1,[175195]=1,[175232]=1,[175245]=1,
  [175246]=1,[175247]=1,[175248]=1,[175249]=1,[175250]=1,[175251]=1,
  [175288]=1,[175301]=1,[175302]=1,[175303]=1,[175304]=1,[175305]=1,
  [175306]=1,[175307]=1,[175344]=1,[175357]=1,[175358]=1,[175359]=1,
  [175360]=1,[175361]=1,[175362]=1,[175363]=1,[175364]=1,[175365]=1,
  [175366]=1,[175367]=1,[175368]=1,[175369]=1,[175370]=1,[175371]=1,
  [175372]=1,[175373]=1,[175374]=1,[175375]=1,[175376]=1,[175377]=1,
  [175378]=1,[175379]=1,[175380]=1,[175381]=1,[175382]=1,[175383]=1,
  [175384]=1,[175385]=1,[175386]=1,[175387]=1,[175388]=1,[175389]=1,
  [175390]=1,[175391]=1,[175392]=1,[175393]=1,[175394]=1,[175395]=1,
  [175396]=1,[175397]=1,[175398]=1,[175399]=1,[175400]=1,[175401]=1,
  [175402]=1,[175403]=1,[175404]=1,[175405]=1,[175406]=1,[175407]=1,
  [175408]=1,[175409]=1,[175410]=1,[175411]=1,[175412]=1,[175413]=1,
  [175414]=1,[175415]=1,[175416]=1,[175417]=1,[175418]=1,[175419]=1,
  [175420]=1,[175421]=1,[175422]=1,[175423]=1,[175424]=1,[175425]=1,
  [175426]=1,[175427]=1,[175428]=1,[175429]=1,[175430]=1,[175431]=1,
  [175432]=1,[175433]=1,[175434]=1,[175435]=1,[175436]=1,[175437]=1,
  [175438]=1,[175439]=1,[175440]=1,[175441]=1,[175442]=1,[175443]=1,
  [175444]=1,[175445]=1,[175446]=1,[175447]=1,[175448]=1,[175449]=1,
  [175450]=1,[175451]=1,[175452]=1,[175453]=1,[175454]=1,[175455]=1,
  [175456]=1,[175457]=1,[175458]=1,[175459]=1,[175460]=1,[175461]=1,
  [175462]=1,[175463]=1,[175464]=1,[175465]=1,[175466]=1,[175467]=1,
  [175468]=1,[175469]=1,[175470]=1,[175471]=1,[175472]=1,[175473]=1,
  [175474]=1,[175475]=1,[175476]=1,[175477]=1,[175478]=1,[175479]=1,
  [175480]=1,[175481]=1,[175482]=1,[175483]=1,[175484]=1,[175485]=1,
  [175486]=1,[175523]=1,[175529]=1,[175530]=1,[175531]=1,[175534]=1,
  [175535]=1,[175536]=1,[175553]=1,[175554]=1,[175555]=1,[175556]=1,
  [177554]=1,[177555]=1,[177556]=1,[177727]=1,[177728]=1,[177729]=1,
  [177892]=1,[177893]=1,[177894]=1,[178057]=1,[178058]=1,[178059]=1,
  [178230]=1,[178231]=1,[178232]=1,[178395]=1,[178396]=1,[178397]=1,
  [178478]=1,[178481]=1,[178482]=1,[178483]=1,[178484]=1,[178485]=1,
  [178486]=1,[178487]=1,[178488]=1,[178489]=1,[178490]=1,[178491]=1,
  [178492]=1,[178494]=1,[178503]=1,[178607]=1,[178620]=1,[178621]=1,
  [178622]=1,[178623]=1,[178624]=1,[178625]=1,[178626]=1,[178663]=1,
  [178676]=1,[178677]=1,[178678]=1,[178679]=1,[178680]=1,[178681]=1,
  [178682]=1,[180094]=1,[180095]=1,[180096]=1,[180259]=1,[180260]=1,
  [180261]=1,[180424]=1,[180425]=1,[180426]=1,[180597]=1,[180598]=1,
  [180599]=1,[180762]=1,[180763]=1,[180764]=1,[180927]=1,[180928]=1,
  [180929]=1,[181620]=1,[181621]=1,[181632]=1,[181633]=1,[181634]=1,
  [181635]=1,[182326]=1,[182334]=1,[182335]=1,[182336]=1,[182349]=1,
  [182455]=1,[182456]=1,[182458]=1,[182459]=1,[182460]=1,[182463]=1,
  [182465]=1,[182468]=1,[182471]=1,[182472]=1,[182480]=1,[183007]=1,
  [183197]=1,[183851]=1,
}