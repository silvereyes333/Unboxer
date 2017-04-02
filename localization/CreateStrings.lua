for stringId, value in pairs(UNBOXER_STRINGS) do
    ZO_CreateStringId(stringId, value)
end
UNBOXER_STRINGS = nil