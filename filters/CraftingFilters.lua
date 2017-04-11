local alchemy = {
    [59705] = true,
    [59706] = true,
    [59707] = true,
    [59708] = true,
    [59709] = true,
    [59710] = true,
    [71238] = true,
    [79675] = true,
    [115712] = true,
    [121302] = true,
}
local blacksmithing = {
    [30335] = true,
    [57851] = true,
    [58131] = true,
    [58503] = true,
    [58504] = true,
    [58505] = true,
    [58506] = true,
    [58507] = true,
    [58508] = true,
    [58509] = true,
    [58510] = true,
    [71234] = true,
    [99246] = true,
    [99247] = true,
    [99248] = true,
    [99249] = true,
    [99250] = true,
    [99251] = true,
    [99252] = true,
    [99253] = true,
    [99254] = true,
    [121298] = true,
}
local clothier = {
    [30338] = true,
    [58519] = true,
    [58520] = true,
    [58521] = true,
    [58522] = true,
    [58523] = true,
    [58524] = true,
    [58525] = true,
    [58526] = true,
    [58527] = true,
    [71233] = true,
    [99256] = true,
    [99257] = true,
    [99258] = true,
    [99259] = true,
    [99260] = true,
    [99261] = true,
    [99262] = true,
    [99263] = true,
    [99264] = true,
    [99265] = true,
    [99266] = true,
    [99267] = true,
    [99268] = true,
    [99269] = true,
    [99270] = true,
    [99271] = true,
    [99272] = true,
    [99273] = true,
    [121297] = true,
}
local enchanting = {
    [30337] = true,
    [58528] = true,
    [58529] = true,
    [58530] = true,
    [58531] = true,
    [58532] = true,
    [58533] = true,
    [58534] = true,
    [59735] = true,
    [59736] = true,
    [71236] = true,
    [121300] = true,
}
local provisioning = {
    [30333] = true,
    [55827] = true,
    [59714] = true,
    [59715] = true,
    [59716] = true,
    [59717] = true,
    [59718] = true,
    [59719] = true,
    [59720] = true,
    [59721] = true,
    [59723] = true,
    [59724] = true,
    [59725] = true,
    [71237] = true,
    [121301] = true,
}
local woodworking = {
    [30339] = true,
    [58511] = true,
    [58512] = true,
    [58513] = true,
    [58514] = true,
    [58515] = true,
    [58516] = true,
    [58517] = true,
    [58518] = true,
    [71235] = true,
    [99274] = true,
    [99275] = true,
    [99276] = true,
    [99277] = true,
    [99278] = true,
    [99279] = true,
    [99280] = true,
    [99281] = true,
    [99282] = true,
    [121299] = true,
}
Unboxer.filters.crafting = {
    ["alchemy"]       = alchemy,
    ["blacksmithing"] = blacksmithing,
    ["clothier"]      = clothier,
    ["enchanting"]    = enchanting,
    ["provisioning"]  = provisioning,
    ["woodworking"]   = woodworking,
}
Unboxer.filtersToSettingsMap.crafting = {
    ["alchemy"]       = "alchemist",
    ["blacksmithing"] = "blacksmith",
    ["enchanting"]    = "enchanter",
    ["provisioning"]  = "provisioner",
    ["woodworking"]   = "woodworker",
}