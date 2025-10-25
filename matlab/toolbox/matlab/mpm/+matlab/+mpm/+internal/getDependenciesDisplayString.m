function out = getDependenciesDisplayString(deps, showResolvedFormat)
%

%   Copyright 2024 The MathWorks, Inc.

    arguments
        deps (1,:) matlab.mpm.Dependency
        showResolvedFormat = false;
    end

    if(numel(deps) == 0)
        out = "";
        return;
    end
        
    names = [deps.Name]; 
    if showResolvedFormat
        versionRanges = string([deps.ResolvedVersion]);
        out = string(strcat(names, '@', versionRanges));
    else
        versionRanges = [deps.VersionRange];
        nonEmptyIndices = (versionRanges ~= "");
        versionRanges(nonEmptyIndices) = "@" + versionRanges(nonEmptyIndices);
        out = string(strcat(names, versionRanges));
    end
end
