function loaded = load()
persistent isLoaded;

if isempty(isLoaded) || ~isLoaded
    model = 'vdp';
    try
        load_system(model);
        bdclose(model);
        isLoaded = true;
    catch ME
    end
end

loaded = isLoaded;
end