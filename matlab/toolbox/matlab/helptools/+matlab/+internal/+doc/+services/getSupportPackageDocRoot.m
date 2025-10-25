function spkgDocroot = getSupportPackageDocRoot
    spkgRoot = getSupportPackageRoot;
    if ~isempty(spkgRoot)
        spkgDocroot = fullfile(string(spkgRoot),"help");
        if ~isfolder(spkgDocroot)
            spkgDocroot = string.empty;
        end
    else
        spkgDocroot = string.empty;
    end
end

function spkgRoot = getSupportPackageRoot
    try
        spkgRoot = matlabshared.supportpkg.getSupportPackageRoot;
    catch
        spkgRoot = '';
    end
end
