function system = validateSystem(system)
    system = validatestring(system, ["unix" "Windows"]);
end