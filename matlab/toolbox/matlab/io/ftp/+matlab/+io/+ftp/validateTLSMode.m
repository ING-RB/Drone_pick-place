function tlsMode = validateTLSMode(tlsMode)
    tlsMode = validatestring(tlsMode, ["none" "opportunistic" "strict"]);
end